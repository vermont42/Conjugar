//
//  PracticeSetTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  A custom quiz shared as a link or a QR code: the link's form, every set's round trip, links
//  that name nothing, My Verbs shared as a list, the level that travels, the scope a set's quiz
//  asks, the share text, the QR code read back, and the route that opens a set.
//

import CoreImage
import Foundation
import Testing
import UIKit
@testable import Conjugar

@MainActor
@Suite struct PracticeSetTests {
  private static let lists: [QuizVerbSet] = [
    .list(["tener", "añadir", "reír", "arrepentir"]),
    .list(["ir"])
  ]

  private static let sets: [PracticeSet] = [
    PracticeSet(custom: CustomQuiz(tenses: [.pretérito]), level: .beginner),
    PracticeSet(custom: CustomQuiz(verbSet: .collection(.goVerbs)), level: .advanced),
    PracticeSet(custom: CustomQuiz(tenses: Set(CustomQuiz.choosableTenses), verbSet: .all), level: nil),
    PracticeSet(custom: CustomQuiz(tenses: [.imperativoPositivo, .futuroDeSubjuntivo], verbSet: .band(.top1000)), level: nil),
    PracticeSet(custom: CustomQuiz(tenses: [.gerundio, .perfectoDeIndicativo], verbSet: lists[0]), level: nil),
    PracticeSet(custom: CustomQuiz(verbSet: lists[1]), level: .intermediate),
    PracticeSet(custom: CustomQuiz(verbSet: .collection(.model("31"))), level: .elementary)
  ]

  private func url(_ string: String) -> URL {
    URL(string: string)!
  }

  private func makeQuiz(level: QuizLevel, gameCenter: GameCenter = GameCenterFake()) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [Settings.quizLevelKey: level.rawValue]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false, practice: PracticeStore(getterSetter: GetterSetterFake()))
  }

  /// Shared links outlive the version that made them, so their form is permanent.
  @Test func theLinkIsPinned() {
    let set = PracticeSet(custom: CustomQuiz(tenses: [.pretérito, .presenteDeIndicativo], verbSet: .collection(.goVerbs)), level: nil)
    #expect(set.deeplink(source: .sharedLink)?.absoluteString == "conjugar://quiz/set?tenses=presente_de_indicativo,preterito&verbs=goVerbs&source=sharedLink")
    let list = PracticeSet(custom: CustomQuiz(verbSet: .list(["tener", "añadir"])), level: .beginner)
    #expect(list.deeplink(source: .qrCode)?.absoluteString == "conjugar://quiz/set?infinitives=tener,a%C3%B1adir&level=beginner&source=qrCode")
  }

  @Test func everySetSurvivesItsLink() throws {
    for set in Self.sets {
      for source in [AnalyticsSource.sharedLink, .qrCode] {
        let link = try #require(set.deeplink(source: source))
        #expect(PracticeSet(url: link) == set)
        #expect(link.analyticsSource == source)
      }
    }
  }

  @Test func everyTenseSurvivesALink() throws {
    for tense in CustomQuiz.choosableTenses {
      let set = PracticeSet(custom: CustomQuiz(tenses: [tense]), level: .advanced)
      #expect(PracticeSet(url: try #require(set.deeplink(source: .sharedLink)))?.custom.tenses == [tense])
    }
  }

  @Test func everyVerbSetSurvivesALink() throws {
    var verbSets: [QuizVerbSet] = FrequencyBand.allCases.map(QuizVerbSet.band) + [.all] + Self.lists
    verbSets += QuizVerbSet.patternCollections.map(QuizVerbSet.collection)
    verbSets += ModelInfo.all.map { QuizVerbSet.collection(.model($0.classNumber)) }
    for verbSet in verbSets {
      let set = PracticeSet(custom: CustomQuiz(verbSet: verbSet), level: .beginner)
      #expect(PracticeSet(url: try #require(set.deeplink(source: .sharedLink)))?.custom.verbSet == verbSet)
    }
  }

  @Test func aListIsStoredApartFromTheSetKeys() {
    let custom = CustomQuiz(tenses: [.presenteDeIndicativo], verbSet: .list(["ir", "tener"]))
    #expect(custom.rawValue == "tenses=presente_de_indicativo&infinitives=ir,tener")
    #expect(CustomQuiz(rawValue: custom.rawValue) == custom)
    #expect(CustomQuiz(rawValue: "verbs=goVerbs")?.verbSet == .collection(.goVerbs))
    #expect(CustomQuiz(rawValue: "infinitives=goVerbs")?.verbSet == nil)
    #expect(CustomQuiz(rawValue: "verbs=list")?.verbSet == nil)
  }

  @Test func aListDropsUnknownAndRepeatedVerbs() {
    #expect(QuizVerbSet(infinitives: ["tener", "xyzzy", "tener", "ir"]) == .list(["tener", "ir"]))
    #expect(QuizVerbSet(infinitives: ["xyzzy"]) == nil)
    #expect(QuizVerbSet(infinitives: []) == nil)
  }

  @Test func aListAsksItsVerbsInOrder() {
    let verbSet = QuizVerbSet.list(["ir", "tener"])
    #expect(verbSet.infinitives(myVerbs: ["hablar"]) == ["ir", "tener"])
    #expect(!verbSet.mixesVerbs)
    #expect(verbSet.collectionKey == nil)
    #expect(verbSet.title == "\(L.CustomQuiz.verbList) · \(L.BrowseVerbs.verbCount(count: 2))")
  }

  @Test func sharingMyVerbsCarriesTheVerbs() {
    let set = PracticeSet(sharing: CustomQuiz(tenses: [.imperativoPositivo], verbSet: .myVerbs), level: .beginner, myVerbs: ["hablar", "ir"])
    #expect(set.custom.verbSet == .list(["hablar", "ir"]))
    #expect(set.level == nil)
  }

  @Test func aSharedListIsCapped() {
    let many = VerbMap.shared.entries.keys.sorted().prefix(150)
    let set = PracticeSet(sharing: CustomQuiz(verbSet: .myVerbs), level: .beginner, myVerbs: Array(many))
    guard case .list(let infinitives) = set.custom.verbSet else {
      Issue.record("Expected a list")
      return
    }
    #expect(infinitives.count == PracticeSet.maximumListCount)
    #expect(infinitives == Array(many.prefix(PracticeSet.maximumListCount)))
  }

  @Test func sharingAnEmptyMyVerbsLeavesTheVerbsToTheLevel() {
    let set = PracticeSet(sharing: CustomQuiz(tenses: [.imperativoPositivo], verbSet: .myVerbs), level: .intermediate, myVerbs: [])
    #expect(set.custom.verbSet == nil)
    #expect(set.level == .intermediate)
  }

  @Test func theLevelTravelsOnlyWhileAPartIsLeftToIt() {
    let both = PracticeSet(sharing: CustomQuiz(tenses: [.condicional], verbSet: .all), level: .beginner, myVerbs: [])
    let tenses = PracticeSet(sharing: CustomQuiz(tenses: [.condicional]), level: .beginner, myVerbs: [])
    let verbSet = PracticeSet(sharing: CustomQuiz(verbSet: .all), level: .beginner, myVerbs: [])
    #expect(both.level == nil)
    #expect(tenses.level == .beginner)
    #expect(verbSet.level == .beginner)
  }

  @Test func aLinkThatNamesNothingIsNoSet() {
    let links = [
      "conjugar://quiz/set",
      "conjugar://quiz/set?source=sharedLink",
      "conjugar://quiz/set?tenses=aoristo&verbs=nada",
      "conjugar://quiz/set?verbs=myVerbs",
      "conjugar://quiz/set?infinitives=xyzzy,plugh",
      "conjugar://quiz/start?tenses=preterito",
      "conjugar://verb/set?tenses=preterito",
      "conjugar://quiz/set/extra?tenses=preterito",
      "https://example.com/quiz/set?tenses=preterito"
    ]
    for link in links {
      #expect(PracticeSet(url: url(link)) == nil, "\(link)")
    }
  }

  @Test func aLinkKeepsWhatItCanRead() {
    let set = PracticeSet(url: url("conjugar://quiz/set?tenses=preterito,aoristo&verbs=model-999&level=expert"))
    #expect(set == PracticeSet(custom: CustomQuiz(tenses: [.pretérito]), level: nil))
  }

  @Test func aLinkNamingMyVerbsDropsThatPart() {
    let set = PracticeSet(url: url("conjugar://quiz/set?tenses=preterito&verbs=myVerbs"))
    #expect(set == PracticeSet(custom: CustomQuiz(tenses: [.pretérito]), level: nil))
  }

  @Test func aSetsScopeIsUnrankedAndCarriesItsLevel() {
    for set in Self.sets {
      let scope = set.scope(source: .qrCode)
      #expect(!scope.isRanked)
      #expect(scope.continues)
      #expect(!scope.startsLiveActivity)
      #expect(scope.isPracticeSet)
      #expect(scope.questionCount == QuizScope.roundLength)
      #expect(scope.source == .qrCode)
      #expect(scope.level == set.level)
      #expect(scope.custom == set.custom)
      #expect(scope.collectionKey == set.custom.verbSet?.collectionKey)
    }
    #expect(PracticeSet(custom: CustomQuiz(verbSet: .list(["ir", "tener"])), level: nil).scope(source: .sharedLink).verbs == ["ir", "tener"])
    #expect(PracticeSet(custom: CustomQuiz(verbSet: .band(.top300)), level: nil).scope(source: .sharedLink).verbs == nil)
  }

  @Test func theShareTextCarriesBothLinks() throws {
    let set = PracticeSet(custom: CustomQuiz(tenses: [.pretérito], verbSet: .collection(.goVerbs)), level: nil)
    let text = set.shareText(levelFallback: .beginner)
    let link = try #require(set.deeplink(source: .sharedLink))
    #expect(text.contains(link.absoluteString))
    #expect(text.contains(URL.appStore.absoluteString))
    #expect(text.contains(VerbCollection.goVerbs.title))
    #expect(text.contains(DisplayTense.pretérito.titleCaseName))
  }

  @Test func theSummaryNamesTheSetsLevelOverTheLearners() {
    let set = PracticeSet(custom: CustomQuiz(verbSet: .collection(.goVerbs)), level: .advanced)
    #expect(set.tensesSummary(levelFallback: .beginner).contains(QuizLevel.advanced.localizedName))
    let unset = PracticeSet(custom: CustomQuiz(tenses: [.condicional]), level: nil)
    #expect(unset.verbsSummary(levelFallback: .elementary) == "\(L.PracticeSet.byLevel): \(CustomQuiz.levelVerbsDescription(.elementary))")
  }

  @Test func theQRCodeReadsBackAsTheLink() throws {
    let set = PracticeSet(custom: CustomQuiz(tenses: [.imperativoPositivo], verbSet: .list(["tener", "añadir", "reír"])), level: nil)
    let link = try #require(set.deeplink(source: .qrCode)).absoluteString
    let image = try #require(QRCode.image(for: link))
    let ciImage = try #require(CIImage(image: image))
    let detector = try #require(CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]))
    let messages = detector.features(in: ciImage).compactMap { ($0 as? CIQRCodeFeature)?.messageString }
    #expect(messages == [link])
  }

  /// A hundred of the longest infinitives, the most a shared list carries, with every tense, still
  /// fit a code.
  @Test func theLongestListFitsACode() {
    let longest = VerbMap.shared.entries.keys.sorted { $0.utf8.count > $1.utf8.count }.prefix(PracticeSet.maximumListCount)
    let set = PracticeSet(custom: CustomQuiz(tenses: Set(CustomQuiz.choosableTenses), verbSet: .list(Array(longest))), level: nil)
    let link = set.deeplink(source: .qrCode)?.absoluteString ?? ""
    #expect(QRCode.image(for: link) != nil)
  }

  @Test func aKeptListIsKeptBetweenLaunches() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    let custom = CustomQuiz(tenses: [.perfectoDeIndicativo], verbSet: .list(["tener", "añadir"]))
    settings.customQuiz = custom
    #expect(Settings(getterSetter: getterSetter).customQuiz == custom)
  }

  @Test func aSessionAsksAtTheSetsLevel() {
    let set = PracticeSet(custom: CustomQuiz(verbSet: .collection(.goVerbs)), level: .beginner)
    let quiz = makeQuiz(level: .advanced)
    #expect(quiz.start(scope: set.scope(source: .sharedLink)))
    #expect(quiz.lastLevel == .beginner)
    let tenses = Set(QuizLevel.beginner.pool.map(\.tense))
    #expect(quiz.questions.allSatisfy { tenses.contains($0.tense) && VerbCollection.goVerbs.infinitives.contains($0.verb) })
  }

  @Test func aSetsSessionPostsNoScoreAndContinues() {
    let spy = GameCenterSpy()
    let set = PracticeSet(custom: CustomQuiz(tenses: [.presenteDeIndicativo]), level: .beginner)
    let quiz = makeQuiz(level: .beginner, gameCenter: spy)
    #expect(quiz.start(scope: set.scope(source: .qrCode)))
    while quiz.quizState == .inProgress {
      _ = quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
    }
    #expect(spy.submissions.isEmpty)
    #expect(quiz.continueSession())
    #expect(quiz.questions.allSatisfy { $0.tense == .presenteDeIndicativo })
  }
}

extension AppRouterTests {
  @Test func aPracticeSetLinkShowsTheSetWithoutChangingTab() throws {
    let router = AppRouter()
    router.selectedTab = .settings
    let set = PracticeSet(custom: CustomQuiz(tenses: [.imperativoPositivo], verbSet: .collection(.goVerbs)), level: nil)
    router.handle(url: try #require(set.deeplink(source: .qrCode)))
    #expect(router.pendingPracticeSet?.practiceSet == set)
    #expect(router.pendingPracticeSet?.source == .qrCode)
    #expect(router.selectedTab == .settings)
    #expect(router.pendingQuizStart == nil)
  }

  @Test func aPracticeSetLinkThatNamesNothingShowsTheFailure() {
    let router = AppRouter()
    router.handle(url: URL(string: "conjugar://quiz/set?tenses=aoristo")!)
    #expect(router.pendingPracticeSet != nil)
    #expect(router.pendingPracticeSet?.practiceSet == nil)
    #expect(router.pendingPracticeSet?.source == .deeplink)
  }

  @Test func aLaterLinkReplacesAPracticeSet() {
    let router = AppRouter()
    router.handle(url: URL(string: "conjugar://quiz/set?tenses=preterito")!)
    router.handle(url: URL(string: "conjugar://verb/tener")!)
    #expect(router.pendingPracticeSet == nil)
    #expect(router.pendingVerb?.infinitive == "tener")
  }

  @Test func aPracticeSetWaitsForACover() {
    let router = AppRouter()
    router.showOnboarding = true
    router.handle(url: URL(string: "conjugar://quiz/set?tenses=preterito")!)
    #expect(router.presentablePracticeSet == nil)
    router.showOnboarding = false
    #expect(router.presentablePracticeSet?.practiceSet?.custom.tenses == [.pretérito])
    router.presentablePracticeSet = nil
    #expect(router.pendingPracticeSet == nil)
  }
}
