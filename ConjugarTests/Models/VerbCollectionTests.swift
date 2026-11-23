//
//  VerbCollectionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The verb collections: their keys, their membership as the engine derives it, `VerbFamilies`'
//  hand-made lists as an oracle for that derivation, progress, the quiz, the share text, and the
//  signals' wire names. MainActor because titles, the store, and the quiz are.
//

import Foundation
import Testing
import UIKit
@testable import Conjugar

@MainActor
@Suite struct VerbCollectionTests {
  private static func infinitives(_ collection: VerbCollection) -> [String] {
    collection.infinitives
  }

  @Test func featuredKeysRoundTrip() {
    #expect(VerbCollection.featured.map(\.key) == ["top100", "goVerbs", "strongPreterite", "irregularFuture", "irregularParticiple"])
    for collection in VerbCollection.featured {
      #expect(VerbCollection(key: collection.key) == collection)
    }
  }

  /// Every row of the Models tab is a collection, its class number's hyphens and letters included.
  @Test func everyModelRowRoundTripsByItsKey() {
    #expect(ModelInfo.all.count == 102)
    for model in ModelInfo.all {
      let collection = VerbCollection.model(model.classNumber)
      #expect(VerbCollection(key: collection.key) == collection, "\(collection.key)")
    }
    #expect(VerbCollection.model("31").key == "model-31")
    #expect(VerbCollection(key: "model-3-1") == .model("3-1"))
    #expect(VerbCollection(key: "model-4B") == .model("4B"))
  }

  /// An alias class rides its parent's row, so it is no collection; nor is a class that does not
  /// exist or a key that names nothing.
  @Test(arguments: ["model-31-1", "model-29-2", "model-99", "model-", "model", "modals", "", "Top100"])
  func unknownKeysNameNoCollection(key: String) {
    #expect(VerbCollection(key: key) == nil)
  }

  @Test func theTop100IsTheBand() {
    let verbs = VerbCollection.top100.verbs
    #expect(verbs.count == 100)
    #expect(verbs.map(\.frequencyRank) == Array(1...100))
  }

  /// The derivation's answer today, pinned so that a change to the engine or the map that moves a
  /// verb in or out is seen. Most frequent first.
  @Test func patternListsAreTheirBandsBaseVerbs() {
    #expect(Self.infinitives(.goVerbs) == ["tener", "hacer", "decir", "poner", "salir", "venir", "caer", "oír", "traer", "valer", "satisfacer"])
    #expect(Self.infinitives(.irregularFuture) == ["tener", "hacer", "poder", "decir", "haber", "saber", "querer", "poner", "salir", "venir", "valer", "caber", "satisfacer"])
    #expect(VerbCollection.strongPreterite.verbs.count == 22)
    #expect(VerbCollection.irregularParticiple.verbs.count == 17)
    for collection in VerbCollection.featured where collection != .top100 {
      for entry in collection.verbs {
        #expect(entry.isIn(.top1000), "\(entry.infinitive)")
        #expect(!VerbDraw.isCompound(entry), "\(entry.infinitive) is a compound")
      }
      let ranks = collection.verbs.map(\.frequencyRank)
      #expect(ranks == ranks.sorted())
    }
  }

  /// `VerbFamilies`' list for the quiz, as an oracle: the derivation finds each.
  @Test func irregularFutureFindsVerbFamiliesList() {
    let derived = Set(Self.infinitives(.irregularFuture))
    for verb in VerbFamilies.irregularRaizFuturaVerbs {
      #expect(derived.contains(verb), "\(verb)")
    }
  }

  /// `VerbFamilies.irregularPreteritoVerbs` also holds ser, ir, and dar, whose pretéritos (fui, di)
  /// are irregular but not strong.
  @Test func strongPreteriteFindsVerbFamiliesList() {
    let notStrong: Set = ["ser", "ir", "dar"]
    let derived = Set(Self.infinitives(.strongPreterite))
    for verb in VerbFamilies.irregularPreteritoVerbs {
      #expect(derived.contains(verb) == !notStrong.contains(verb), "\(verb)")
      #expect(VerbCollection.hasStrongPreterite(verb) == !notStrong.contains(verb), "\(verb)")
    }
  }

  /// pudrir (podrido) is beyond the band, so the test asks it of the pattern, not of the list.
  @Test func irregularParticipleFindsVerbFamiliesList() {
    let derived = Set(Self.infinitives(.irregularParticiple))
    for verb in VerbFamilies.irregularParticipioVerbs {
      #expect(VerbCollection.hasIrregularParticiple(verb), "\(verb)")
      if let entry = VerbMap.shared.entry(for: verb), entry.isIn(.top1000) {
        #expect(derived.contains(verb), "\(verb)")
      }
    }
  }

  @Test(arguments: ["tener", "poner", "salir", "hacer", "decir", "venir", "traer", "caer", "oír", "valer"])
  func goVerbsAreFound(verb: String) {
    #expect(VerbCollection.hasGoPresent(verb))
    #expect(Self.infinitives(.goVerbs).contains(verb))
  }

  /// A g already in the stem makes no -go verb, nor does a stem change (juego).
  @Test(arguments: ["seguir", "conseguir", "jugar", "pagar", "llegar", "distinguir", "negar", "hablar"])
  func goVerbsLeaveOutAStemsOwnG(verb: String) {
    #expect(!VerbCollection.hasGoPresent(verb))
  }

  /// A written accent that only keeps the stress is no irregular participle.
  @Test(arguments: ["creer", "leer", "oír", "caer", "reír", "hablar", "vivir", "comer"])
  func accentOnlyParticiplesAreRegular(verb: String) {
    #expect(!VerbCollection.hasIrregularParticiple(verb))
  }

  @Test func compoundsAreLeftOutButShowThePattern() {
    for compound in ["detener", "componer", "deshacer", "prevenir"] {
      #expect(VerbCollection.hasIrregularFuture(compound), "\(compound)")
      #expect(!Self.infinitives(.irregularFuture).contains(compound), "\(compound)")
    }
  }

  /// A model's collection holds exactly the verbs its page lists, an alias class's included.
  @Test func everyModelsCollectionIsItsPagesVerbs() {
    for model in ModelInfo.all {
      let collection = VerbCollection.model(model.classNumber)
      #expect(Set(collection.infinitives) == Set(model.verbs), "\(model.classNumber)")
    }
    #expect(VerbCollection.model("31").infinitives.contains("contener"))
  }

  @Test func examplesAreTheMostFrequentVerbsMarkedForms() {
    #expect(VerbCollection.goVerbs.examples == "tenGo · haGo · dIGo")
    #expect(VerbCollection.top100.examples.hasPrefix("ser · "))
    #expect(VerbCollection.model("31").examples.isEmpty)
    for collection in VerbCollection.featured {
      #expect(collection.examples.components(separatedBy: VerbCollection.exampleSeparator).count == VerbCollection.exampleCount)
    }
  }

  @Test func progressCountsOpensNotStarsAndClearResetsIt() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    let verbs = VerbCollection.goVerbs.verbs
    store.recordOpen("tener", source: .list)
    store.recordOpen("hablar", source: .browse)
    store.toggleStar("hacer")
    #expect(store.openedCount(of: verbs) == 1)
    store.clearRecents()
    #expect(store.openedCount(of: verbs) == 0)
  }

  @Test func aCollectionsQuizIsFullLengthUnrankedAndTitled() {
    let scope = QuizScope.collection(.goVerbs, title: "-go Verbs")
    #expect(scope.verbs == Self.infinitives(.goVerbs))
    #expect(scope.questionCount == QuizScope.fullLength)
    #expect(scope.source == .list)
    #expect(scope.title == "-go Verbs")
    #expect(scope.collectionKey == "goVerbs")
    #expect(!scope.isRanked)
    // It runs in a sheet beside the tab's quiz, whose Live Activity is the app's only one.
    #expect(!scope.startsLiveActivity)
    #expect(QuizScope.allVerbs.startsLiveActivity)
    #expect(QuizScope.myVerbs(["tener"]).startsLiveActivity)
    #expect(!QuizScope.verbPage("tener").startsLiveActivity)
  }

  @Test func aCollectionsQuizAsksOnlyItsVerbs() {
    let settings = Settings(getterSetter: GetterSetterFake())
    let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true)
    #expect(quiz.start(scope: .collection(.irregularFuture, title: "")))
    let verbs = Set(Self.infinitives(.irregularFuture))
    #expect(quiz.questions.count == QuizScope.fullLength)
    #expect(quiz.questions.allSatisfy { verbs.contains($0.verb) })
    quiz.quit()
  }

  @Test func shareTextCarriesTheLinkAndTheAppStore() throws {
    let text = VerbCollection.irregularFuture.shareText
    #expect(text.contains("conjugar://list/irregularFuture?source=sharedLink"))
    #expect(text.contains(URL.appStore.absoluteString))
    #expect(text.contains("tener, hacer, poder, decir, haber, saber …"))
    let link = try #require(VerbCollection.model("3-1").deeplink)
    #expect(link.deeplinkTarget == "model-3-1")
    #expect(link.analyticsSource == .sharedLink)
  }

  @Test func everyCollectionsSymbolExists() {
    for collection in VerbCollection.featured + [.model("31")] {
      #expect(UIImage(systemName: collection.systemImageName) != nil, "\(collection.systemImageName)")
    }
  }

  @Test func signalsWireNames() {
    #expect(AnalyticsName.viewCollection.rawValue == "viewCollection")
    #expect(AnalyticsName.tapShareCollection.rawValue == "tapShareCollection")
    #expect(ParameterKey.collection.rawValue == "collection")
    #expect(AnalyticsSource.list.rawValue == "list")
    #expect(AnalyticsSource.sharedLink.rawValue == "sharedLink")
  }
}
