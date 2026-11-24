//
//  ModelPracticeTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  A verb model's practice: which models offer it and with which verbs, when a model counts as
//  known, how a mixed round is drawn, the scopes, and whole sessions in a quiz.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct ModelPracticeTests {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)

  private func makeQuiz(practice: PracticeStore, seed: UInt64 = 3) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: QuizLevel.intermediate.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  private func answerRight(_ quiz: Quiz) {
    quiz.process(proposedAnswer: quiz.currentQuestion?.writtenAnswer?.lowercased() ?? "")
  }

  private func answerWrong(_ quiz: Quiz) {
    quiz.process(proposedAnswer: "zzzz")
    quiz.continueAfterCorrection()
  }

  /// A record in which every item of the models was answered right once, which moves a new item
  /// past the first box.
  private func record(knowing classNumbers: [String]) -> PracticeRecord {
    var record = PracticeRecord()
    for classNumber in classNumbers {
      for item in ModelPracticeGroup.group(classNumber)?.items ?? [] {
        record.recordAnswer(item, isCorrect: true, at: now)
      }
    }
    return record
  }

  private func verbs(of quiz: Quiz) -> [String] {
    quiz.questions.map(\.verb).reduce(into: [String]()) { if $0.last != $1 { $0.append($1) } }
  }

  private static var generator = SplitMix64(seed: 11)

  // Which models, with which verbs

  @Test func aModelIsItsTenMostFrequentVerbsWithAnIrregularKeyConjugation() throws {
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(pensar.exemplar == "pensar")
    #expect(pensar.verbs.count == ModelPracticeGroup.verbLimit)
    #expect(pensar.verbs.first == "pensar")
    let ranks = pensar.verbs.compactMap { VerbMap.shared.entry(for: $0)?.frequencyRank }
    #expect(ranks == ranks.sorted())
    #expect(pensar.verbs.allSatisfy(VerbEssentials.hasIrregularKeyConjugation))
  }

  @Test func aSmallModelIsWhole() throws {
    let salir = try #require(ModelPracticeGroup.group("11"))
    #expect(salir.verbs.count == 2)
    #expect(salir.verbs.contains("salir"))
    #expect(salir.offersPracticeAlone)
  }

  @Test func aModelHoldsOnlyVerbsWhoseDefaultSenseFollowsIt() {
    for group in ModelPracticeGroup.all {
      for verb in group.verbs {
        #expect(ModelInfo.row(for: verb)?.classNumber == group.classNumber, "\(verb) in \(group.classNumber)")
      }
    }
  }

  @Test func everyAskableModelOffersPracticeAndTheRestNone() {
    #expect(ModelPracticeGroup.all.count == 94)
    #expect(ModelPracticeGroup.practicedAloneByUse.count == 65)
    for classNumber in ["1", "2", "3", "3-5", "2-5", "3-6", "2-4", "3-14"] {
      #expect(ModelPracticeGroup.group(classNumber) == nil, "\(classNumber)")
    }
    // Spelling changes, accent shifts, and irregular participles show in the key conjugations.
    for classNumber in ["1-1", "1-2", "2-2", "1-15", "1-14", "3-9", "3-11"] {
      #expect(ModelPracticeGroup.group(classNumber)?.offersPracticeAlone == true, "\(classNumber)")
    }
  }

  @Test func aSingleVerbModelIsNotPracticedAlone() throws {
    for classNumber in ["19", "24", "6C", "25"] {
      let group = try #require(ModelPracticeGroup.group(classNumber))
      #expect(group.verbs.count == 1)
      #expect(!group.offersPracticeAlone)
      #expect(!ModelPracticeGroup.practicedAloneByUse.contains { $0.classNumber == classNumber })
    }
  }

  @Test func theListPutsTheMostUsedModelsFirst() {
    #expect(ModelPracticeGroup.practicedAloneByUse.prefix(3).map(\.exemplar) == ["tener", "hacer", "pagar"])
  }

  @Test func aModelsItemsAreItsVerbsIrregularKeyConjugations() throws {
    let tener = try #require(ModelPracticeGroup.group("31"))
    // tenido is regular, so tener's verbs have three items each.
    #expect(tener.items.count == 3 * tener.verbs.count)
    #expect(tener.items.contains(.keyConjugation(infinitive: "tener", key: .yoFuturo)))
    #expect(!tener.items.contains(.keyConjugation(infinitive: "tener", key: .participio)))
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(pensar.items == pensar.verbs.map { .keyConjugation(infinitive: $0, key: .yoPresente) })
  }

  // Known

  @Test func aModelIsKnownOnceHalfItsItemsHaveClimbed() throws {
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(!pensar.isKnown(in: PracticeRecord()))
    var record = PracticeRecord()
    for item in pensar.items.prefix(4) {
      record.recordAnswer(item, isCorrect: true, at: now)
    }
    #expect(!pensar.isKnown(in: record))
    record.recordAnswer(pensar.items[4], isCorrect: true, at: now)
    #expect(pensar.isKnown(in: record))
  }

  @Test func aWrongAnswerOrALookupDoesNotCountAndCanUnknowAModel() throws {
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    var record = PracticeRecord()
    for item in pensar.items.prefix(4) {
      record.recordAnswer(item, isCorrect: true, at: now)
    }
    record.recordAnswer(pensar.items[4], isCorrect: false, at: now)
    record.recordLookup([pensar.items[5]], at: now)
    #expect(!pensar.isKnown(in: record))

    record.recordAnswer(pensar.items[6], isCorrect: true, at: now)
    #expect(pensar.isKnown(in: record))
    record.recordAnswer(pensar.items[0], isCorrect: false, at: now)
    #expect(!pensar.isKnown(in: record))
  }

  @Test func aSingleVerbModelIsKnownThroughItsVerb() throws {
    let ser = try #require(ModelPracticeGroup.group("19"))
    var record = PracticeRecord()
    record.recordAnswer(ser.items[0], isCorrect: true, at: now)
    #expect(ser.items.count == 2)
    #expect(ser.isKnown(in: record))
  }

  @Test func aModelsMixPartnersAreTheOtherKnownModelsTheMostUsedFirst() throws {
    let record = record(knowing: ["4A", "31", "19"])
    #expect(ModelPracticeGroup.known(in: record).map(\.classNumber) == ["19", "31", "4A"])
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(pensar.mixPartners(in: record).map(\.classNumber) == ["19", "31"])
    let volver = try #require(ModelPracticeGroup.group("5B-4"))
    #expect(volver.mixPartners(in: record).count == 3)
    #expect(volver.mixPartners(in: PracticeRecord()).isEmpty)
  }

  // The draws

  private let group = ModelPracticeGroup(classNumber: "g", exemplar: "g", verbs: ["g1", "g2", "g3", "g4", "g5", "g6"])
  private let large = ModelPracticeGroup(classNumber: "l", exemplar: "l", verbs: (1...10).map { "l\($0)" })
  private let single = ModelPracticeGroup(classNumber: "s", exemplar: "s", verbs: ["s1"])

  @Test func aMixedRoundIsThreeOfTheModelsAndTwoOfTheKnown() {
    for _ in 0..<20 {
      let verbs = ModelPractice.mixedVerbs(group: group, partners: [large], count: 5, groupCount: 3, using: &Self.generator)
      #expect(verbs.count == 5)
      #expect(Set(verbs).count == 5)
      #expect(verbs.filter { $0.hasPrefix("g") }.count == 3)
      #expect(verbs.filter { $0.hasPrefix("l") }.count == 2)
    }
  }

  @Test func partnersGiveOneVerbAtATime() {
    for _ in 0..<20 {
      let verbs = ModelPractice.mixedVerbs(group: group, partners: [large, single], count: 5, groupCount: 3, using: &Self.generator)
      #expect(verbs.contains("s1"))
      #expect(verbs.filter { $0.hasPrefix("l") }.count == 1)
    }
  }

  @Test func aShortSideLeavesTheRestToTheOther() {
    let two = ModelPracticeGroup(classNumber: "t", exemplar: "t", verbs: ["t1", "t2"])
    let fromShortGroup = ModelPractice.mixedVerbs(group: two, partners: [large], count: 5, groupCount: 3, using: &Self.generator)
    #expect(fromShortGroup.filter { $0.hasPrefix("t") }.count == 2)
    #expect(fromShortGroup.filter { $0.hasPrefix("l") }.count == 3)

    let fromShortPartners = ModelPractice.mixedVerbs(group: group, partners: [single], count: 5, groupCount: 3, using: &Self.generator)
    #expect(fromShortPartners.filter { $0.hasPrefix("g") }.count == 4)
    #expect(fromShortPartners.contains("s1"))
  }

  @Test func verbsAlreadyAskedComeLastOnEachSide() {
    let asked: Set = ["g1", "g2", "g3", "l1", "l2", "l3", "l4", "l5", "l6", "l7", "l8"]
    for _ in 0..<20 {
      let verbs = ModelPractice.mixedVerbs(group: group, partners: [large], count: 5, groupCount: 3, asked: asked, using: &Self.generator)
      #expect(Set(verbs.filter { $0.hasPrefix("g") }) == ["g4", "g5", "g6"])
      #expect(Set(verbs.filter { $0.hasPrefix("l") }) == ["l9", "l10"])
    }
  }

  @Test func aloneDrawsFiveOfTheModelsVerbs() throws {
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    let session = ModelPracticeSession(classNumber: "4A", mode: .alone)
    let verbs = ModelPractice.verbs(for: session, record: PracticeRecord(), using: &Self.generator)
    #expect(verbs.count == 5)
    #expect(Set(verbs).isSubset(of: pensar.verbs))
    let more = ModelPractice.verbs(for: session, record: PracticeRecord(), asked: Set(verbs), using: &Self.generator)
    #expect(Set(more).isDisjoint(with: verbs))
  }

  // The scopes

  @Test func theScopesAreVerbEssentialsUnrankedAndInASheet() throws {
    let alone = QuizScope.modelPractice(ModelPracticeSession(classNumber: "4A", mode: .alone))
    #expect(alone.isVerbEssentials)
    #expect(alone.source == .modelAlone)
    #expect(alone.collectionKey == "model-4A")
    #expect(alone.title == L.VerbCollection.modelTitle(exemplar: "pensar"))
    #expect(alone.questionCount == 20)
    #expect(!alone.isRanked)
    #expect(!alone.mixesDueItems)
    #expect(!alone.shufflesQuestions)
    #expect(alone.continues)
    #expect(!alone.startsLiveActivity)
    #expect(alone.sendsQuestionCounts)

    let mixed = QuizScope.modelPractice(ModelPracticeSession(classNumber: "4A", mode: .mixed))
    #expect(mixed.source == .modelMixed)
    #expect(mixed.title == L.ModelPractice.mixedTitle(exemplar: "pensar"))
    #expect(!mixed.isRanked)
    // Which models are known comes from the learner's answers.
    #expect(!mixed.sendsQuestionCounts)
  }

  // Sessions

  @Test func aRoundAloneMakesTheModelKnownAndJoinsAnotherModelsMix() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(quiz.start(scope: .modelPractice(ModelPracticeSession(classNumber: "4A", mode: .alone))))
    #expect(verbs(of: quiz).count == 5)
    #expect(Set(verbs(of: quiz)).isSubset(of: pensar.verbs))
    while quiz.quizState == .inProgress {
      answerRight(quiz)
    }
    #expect(pensar.isKnown(in: practice.record))

    let volver = try #require(ModelPracticeGroup.group("5B-4"))
    #expect(volver.mixPartners(in: practice.record).map(\.classNumber) == ["4A"])
    let mixed = makeQuiz(practice: practice)
    #expect(mixed.start(scope: .modelPractice(ModelPracticeSession(classNumber: "5B-4", mode: .mixed))))
    let asked = verbs(of: mixed)
    #expect(asked.count == 5)
    #expect(asked.filter { volver.verbs.contains($0) }.count == 3)
    #expect(asked.filter { pensar.verbs.contains($0) }.count == 2)
  }

  @Test func aWrongRoundLeavesTheModelUnknown() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .modelPractice(ModelPracticeSession(classNumber: "4A", mode: .alone))))
    while quiz.quizState == .inProgress {
      answerWrong(quiz)
    }
    let pensar = try #require(ModelPracticeGroup.group("4A"))
    #expect(!pensar.isKnown(in: practice.record))
  }

  @Test func anotherRoundAsksTheModelsOtherVerbs() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .modelPractice(ModelPracticeSession(classNumber: "4A", mode: .alone))))
    while quiz.quizState == .inProgress {
      answerRight(quiz)
    }
    let first = Set(verbs(of: quiz))
    let firstCount = quiz.questions.count
    #expect(quiz.canContinue)
    #expect(quiz.continueSession())
    let more = Set(quiz.questions.dropFirst(firstCount).map(\.verb))
    #expect(more.count == 5)
    #expect(more.isDisjoint(with: first))
  }

  @Test func aSessionIsKeptAsTheLastResultWithItsModelAndNoLevel() {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    for (mode, kind, title) in [
      (ModelPracticeSession.Mode.alone, LastQuizResult.Kind.modelAlone, L.VerbCollection.modelTitle(exemplar: "salir")),
      (.mixed, .modelMixed, L.ModelPractice.mixedTitle(exemplar: "salir"))
    ] {
      let quiz = makeQuiz(practice: practice)
      #expect(quiz.start(scope: .modelPractice(ModelPracticeSession(classNumber: "11", mode: mode))))
      while quiz.quizState == .inProgress {
        answerRight(quiz)
      }
      #expect(!quiz.isRankedRound)
      #expect(practice.lastResult?.kind == kind)
      #expect(practice.lastResult?.subject == "11")
      #expect(practice.lastResult?.level == nil)
      #expect(practice.lastResult?.title == title)
    }
  }

  @Test func aRoundOfASmallModelIsAsLongAsTheModel() {
    let quiz = makeQuiz(practice: PracticeStore(getterSetter: GetterSetterFake()))
    #expect(quiz.start(scope: .modelPractice(ModelPracticeSession(classNumber: "11", mode: .alone))))
    #expect(Set(verbs(of: quiz)).count == 2)
  }
}
