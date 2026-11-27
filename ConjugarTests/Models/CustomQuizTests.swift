//
//  CustomQuizTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The Quiz tab's Custom segment: the stored choice, the scope it makes, and the sessions it asks.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct CustomQuizTests {
  private func makeQuiz(level: QuizLevel, region: Region = .spain, gameCenter: GameCenter = GameCenterFake()) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: region.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false, practice: PracticeStore(getterSetter: GetterSetterFake()))
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  private func finishRight(_ quiz: Quiz) {
    while quiz.quizState == .inProgress {
      #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    }
  }

  /// A choice is kept between launches in this form, so its keys never change.
  @Test func theStoredFormIsPinned() {
    let custom = CustomQuiz(tenses: [.pretérito, .presenteDeIndicativo], verbSet: .collection(.goVerbs))
    #expect(custom.rawValue == "tenses=presente_de_indicativo,preterito&verbs=goVerbs")
    #expect(CustomQuiz(rawValue: custom.rawValue) == custom)
    #expect(CustomQuiz().rawValue == "")
    #expect(CustomQuiz(rawValue: "") == CustomQuiz())
    #expect(CustomQuiz(tenses: [.gerundio]).rawValue == "tenses=gerundio")
    #expect(CustomQuiz(verbSet: .collection(.model("3-1"))).rawValue == "verbs=model-3-1")
  }

  @Test func everyTenseKeyReadsBack() {
    #expect(CustomQuiz.choosableTenses.count == QuizLevel.advanced.pool.count)
    let keys = CustomQuiz.choosableTenses.map(CustomQuiz.key(for:))
    #expect(Set(keys).count == keys.count)
    #expect(!keys.contains(""))
    for tense in CustomQuiz.choosableTenses {
      #expect(CustomQuiz.tense(forKey: CustomQuiz.key(for: tense)) == tense)
      let custom = CustomQuiz(tenses: [tense])
      #expect(CustomQuiz(rawValue: custom.rawValue) == custom)
    }
  }

  @Test func everyVerbSetKeyReadsBack() {
    var verbSets: [QuizVerbSet] = FrequencyBand.allCases.map(QuizVerbSet.band) + [.all, .myVerbs]
    verbSets += QuizVerbSet.patternCollections.map(QuizVerbSet.collection)
    verbSets += ModelInfo.all.map { QuizVerbSet.collection(.model($0.classNumber)) }
    for verbSet in verbSets {
      #expect(QuizVerbSet(key: verbSet.key) == verbSet)
    }
    #expect(Set(verbSets.map(\.key)).count == verbSets.count)
    // The top-100 collection holds the band's verbs and shares its key.
    #expect(QuizVerbSet(key: VerbCollection.top100.key) == .band(.top100))
    #expect(!QuizVerbSet.patternCollections.contains(.top100))
  }

  @Test func anUnknownKeyIsDroppedAlone() {
    let custom = CustomQuiz(rawValue: "tenses=presente_de_indicativo,aoristo&verbs=model-999")
    #expect(custom == CustomQuiz(tenses: [.presenteDeIndicativo]))
    #expect(CustomQuiz(rawValue: "verbs=top1000&tenses=nada") == CustomQuiz(verbSet: .band(.top1000)))
  }

  @Test func theChoiceIsKeptBetweenLaunches() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    #expect(settings.customQuiz.isEmpty)
    settings.customQuiz.tenses = [.condicional]
    settings.customQuiz.verbSet = .myVerbs
    #expect(getterSetter.dictionary[Settings.customQuizKey] == "tenses=condicional&verbs=myVerbs")
    #expect(Settings(getterSetter: getterSetter).customQuiz == CustomQuiz(tenses: [.condicional], verbSet: .myVerbs))
  }

  @Test func theChoiceParameterSaysWhatKindOnly() {
    #expect(CustomQuiz(tenses: [.pretérito]).choiceParameter == "tenses")
    #expect(CustomQuiz(verbSet: .band(.top300)).choiceParameter == "verbs")
    #expect(CustomQuiz(tenses: [.pretérito], verbSet: .all).choiceParameter == "both")
  }

  @Test func aPartLeftUnchosenIsTheLevels() {
    for level in QuizLevel.allCases {
      #expect(CustomQuiz(verbSet: .collection(.goVerbs)).pool(level: level) == level.pool)
      #expect(CustomQuiz(tenses: [.pretérito]).band(level: level) == level.band)
    }
    #expect(CustomQuiz(verbSet: .band(.top1000)).band(level: .beginner) == .top1000)
    #expect(CustomQuiz(verbSet: .all).band(level: .beginner) == nil)
  }

  /// A chosen tense is asked as Advanced asks it, whatever the level.
  @Test func aChosenTenseIsAskedOfEveryPerson() {
    let pool = CustomQuiz(tenses: [.imperativoPositivo, .futuroDeSubjuntivo]).pool(level: .beginner)
    #expect(pool.map(\.tense) == [.imperativoPositivo, .futuroDeSubjuntivo])
    #expect(pool.allSatisfy { $0.excludedPersons.isEmpty })
  }

  @Test func aCustomQuizNeverRanks() {
    let choices = [
      CustomQuiz(tenses: [.presenteDeIndicativo]),
      CustomQuiz(verbSet: .all),
      CustomQuiz(verbSet: .collection(.irregularFuture)),
      CustomQuiz(tenses: [.pretérito], verbSet: .myVerbs)
    ]
    for custom in choices {
      let scope = QuizScope.custom(custom, myVerbs: ["tener"])
      #expect(!scope.isRanked)
      #expect(scope.continues)
      #expect(scope.startsLiveActivity)
      #expect(scope.source == .custom)
      #expect(scope.questionCount == QuizScope.roundLength)
    }
    #expect(QuizScope.custom(CustomQuiz(verbSet: .all), myVerbs: []).verbs == nil)
    #expect(QuizScope.custom(CustomQuiz(verbSet: .myVerbs), myVerbs: ["tener", "ir"]).verbs == ["tener", "ir"])
    #expect(QuizScope.custom(CustomQuiz(verbSet: .collection(.goVerbs)), myVerbs: []).collectionKey == "goVerbs")
    #expect(QuizScope.custom(CustomQuiz(verbSet: .band(.top100)), myVerbs: []).collectionKey == nil)
  }

  @Test func chosenTensesAloneAskTheLevelsBand() {
    let spy = GameCenterSpy()
    let quiz = makeQuiz(level: .beginner, gameCenter: spy)
    #expect(quiz.start(scope: .custom(CustomQuiz(tenses: [.pluscuamperfectoDeSubjuntivo1]), myVerbs: [])))
    #expect(quiz.questionCount == QuizScope.roundLength)
    #expect(quiz.questions.allSatisfy { $0.tense == .pluscuamperfectoDeSubjuntivo1 })
    #expect(quiz.questions.allSatisfy { VerbMap.shared.entry(for: $0.verb)?.isIn(.top100) == true })
    finishRight(quiz)
    #expect(spy.submissions.isEmpty)
  }

  @Test func aChosenVerbSetAloneAsksTheLevelsTenses() {
    let collection = VerbCollection.goVerbs
    let quiz = makeQuiz(level: .elementary)
    #expect(quiz.start(scope: .custom(CustomQuiz(verbSet: .collection(collection)), myVerbs: [])))
    let tenses = Set(QuizLevel.elementary.pool.map(\.tense))
    #expect(quiz.questionCount == QuizScope.roundLength)
    #expect(quiz.questions.allSatisfy { collection.infinitives.contains($0.verb) && tenses.contains($0.tense) })
  }

  @Test func bothAskOnlyTheChoice() {
    let quiz = makeQuiz(level: .beginner)
    let custom = CustomQuiz(tenses: [.futuroDeIndicativo, .condicional], verbSet: .collection(.model("31")))
    #expect(quiz.start(scope: .custom(custom, myVerbs: [])))
    let verbs = Set(VerbCollection.model("31").infinitives)
    #expect(quiz.questions.allSatisfy { verbs.contains($0.verb) && custom.tenses.contains($0.tense) })
    // Ten More keeps the choice.
    finishRight(quiz)
    #expect(quiz.continueSession())
    #expect(quiz.questionCount == 2 * QuizScope.roundLength)
    #expect(quiz.questions.allSatisfy { verbs.contains($0.verb) && custom.tenses.contains($0.tense) })
  }

  /// A band is mixed as the default quiz is: half its questions irregular, and the core verbs.
  @Test func aChosenBandIsMixedAsTheDefaultQuizIs() {
    let quiz = makeQuiz(level: .beginner)
    #expect(quiz.start(scope: .custom(CustomQuiz(verbSet: .band(.top1000)), myVerbs: [])))
    let questions = quiz.questions
    #expect(questions.allSatisfy { VerbMap.shared.entry(for: $0.verb)?.isIn(.top1000) == true })
    #expect(questions.allSatisfy { QuizLevel.beginner.entry(for: $0.tense) != nil })
    let irregular = questions.filter { QuizDraw.isIrregular($0.verb, in: ConjugationCell(tense: $0.tense, personNumber: $0.personNumber)) == true }
    #expect(irregular.count == QuizScope.roundLength / 2)
    #expect(questions.filter { QuizDraw.isCore($0.verb) }.count >= QuizDraw.minimumCoreQuestions)
  }

  /// Any one tense, alone, fills a round from any band, so no choice in the editor starts an
  /// empty or short quiz.
  @Test func everyTenseAloneFillsARoundFromEveryBand() {
    let verbSets: [QuizVerbSet] = FrequencyBand.allCases.map(QuizVerbSet.band) + [.all]
    for verbSet in verbSets {
      for tense in CustomQuiz.choosableTenses {
        let quiz = makeQuiz(level: .beginner, region: .latinAmerica)
        #expect(quiz.start(scope: .custom(CustomQuiz(tenses: [tense], verbSet: verbSet), myVerbs: [])))
        #expect(quiz.questionCount == QuizScope.roundLength, "\(tense) from \(verbSet.key)")
        #expect(quiz.questions.allSatisfy { $0.tense == tense && $0.personNumber != .secondPlural })
      }
    }
  }

  @Test func myVerbsWithNoneStartsNothing() {
    let quiz = makeQuiz(level: .intermediate)
    #expect(!quiz.start(scope: .custom(CustomQuiz(verbSet: .myVerbs), myVerbs: [])))
    #expect(quiz.quizState == .notStarted)
  }
}
