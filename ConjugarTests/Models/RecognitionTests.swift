//
//  RecognitionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Name the Form: the cells a prompt is, ambiguous prompts included; grading by part; the lines a
//  second attempt shows; the correction's lines; and a round in the quiz.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct RecognitionTests {
  private func makeQuiz(level: QuizLevel = .beginner, practice: PracticeStore = PracticeStore(getterSetter: GetterSetterFake()), seed: UInt64 = 5) -> Quiz {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.quizLevelKey: level.rawValue,
      Settings.regionKey: Region.spain.rawValue
    ]))
    return Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true, randomSource: SplitMix64(seed: seed), practice: practice)
  }

  /// Advanced's tenses in the tú setting and Spain, as a quiz offers them.
  private var advanced: [RecognitionChoice] {
    makeQuiz(level: .advanced).recognitionChoices(pool: QuizLevel.advanced.pool)
  }

  private func question(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber, choices: [RecognitionChoice]? = nil) throws -> RecognitionQuestion {
    try #require(RecognitionQuestion(verb: verb, cell: ConjugationCell(tense: tense, personNumber: personNumber), choices: choices ?? advanced))
  }

  private func cells(_ question: RecognitionQuestion) -> Set<String> {
    Set(question.cells.map { "\($0.verb) \($0.cell.code)" })
  }

  private func answer(_ infinitive: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber = .none) -> RecognitionAnswer {
    RecognitionAnswer(infinitive: infinitive, tense: tense, personNumber: personNumber)
  }

  /// The first right answer to the question on screen.
  private func rightAnswer(_ quiz: Quiz) throws -> RecognitionAnswer {
    let cell = try #require(quiz.currentQuestion?.recognition?.cells.first)
    return answer(cell.verb, cell.cell.tense, cell.cell.personNumber)
  }

  // The cells a prompt is

  @Test func fueraIsSersAndIrsRaFormForYoAndEl() throws {
    let fuera = try question("ser", .imperfectoDeSubjuntivo1, .firstSingular)
    #expect(fuera.prompt.lowercased() == "fuera")
    #expect(cells(fuera) == ["ser i1fs", "ser i1ts", "ir i1fs", "ir i1ts"])
    #expect(fuera.cells.first?.verb == "ser")
  }

  @Test func hablamosIsThePresenteAndThePreterito() throws {
    #expect(cells(try question("hablar", .presenteDeIndicativo, .firstPlural)) == ["hablar prfp", "hablar ptfp"])
  }

  @Test func hableIsTheSubjunctiveOfYoAndElAndUstedsCommand() throws {
    #expect(cells(try question("hablar", .presenteDeSubjuntivo, .thirdSingular)) == ["hablar pbfs", "hablar pbts", "hablar iots"])
  }

  @Test func accentsMakeDifferentPrompts() throws {
    #expect(cells(try question("hablar", .pretérito, .thirdSingular)) == ["hablar ptts"])
    #expect(cells(try question("hablar", .presenteDeIndicativo, .firstSingular)) == ["hablar prfs"])
  }

  @Test func seIsSabersYoAndSersCommand() throws {
    let se = cells(try question("saber", .presenteDeIndicativo, .firstSingular))
    #expect(se == ["saber prfs", "ser ioss"], "\(se)")
  }

  @Test func veIsVersAndIrs() throws {
    #expect(cells(try question("ir", .imperativoPositivo, .secondSingularTú)) == ["ir ioss", "ver prts", "ver ioss"])
  }

  @Test func aCompoundANegativeCommandAndAGerundio() throws {
    let compound = try question("hacer", .perfectoDeIndicativo, .thirdSingular)
    #expect(compound.prompt.lowercased() == "ha hecho")
    #expect(cells(compound) == ["hacer pits"])
    let command = try question("hacer", .imperativoNegativo, .secondSingularTú)
    #expect(command.prompt.lowercased() == "no hagas")
    #expect(cells(command) == ["hacer niss"])
    #expect(cells(try question("decir", .gerundio, .none)) == ["decir geno"])
  }

  @Test func aReflexiveOnlyVerbsPromptHasItsPronoun() throws {
    let prompt = try question("arrepentir", .presenteDeIndicativo, .firstSingular)
    #expect(prompt.prompt.lowercased() == "me arrepiento")
    #expect(cells(prompt) == ["arrepentir prfs"])
  }

  @Test func onlyTheChoicesCellsCount() throws {
    let beginner = makeQuiz(level: .beginner).recognitionChoices(pool: QuizLevel.beginner.pool)
    #expect(beginner.map(\.tense) == [.presenteDeIndicativo, .imperativoPositivo])
    #expect(beginner.last?.personNumbers == [.secondSingularTú, .thirdSingular, .thirdPlural])
    #expect(cells(try question("hablar", .imperativoPositivo, .thirdSingular, choices: beginner)) == ["hablar iots"])
  }

  @Test func theChoicesFollowTheMoodsAndTheSettings() {
    let choices = advanced
    #expect(choices.map(\.tense) == RecognitionMood.tenseOrder.filter { QuizLevel.advanced.entry(for: $0) != nil })
    #expect(choices.first { $0.tense == .gerundio }?.personNumbers == [])
    #expect(choices.first { $0.tense == .imperativoNegativo }?.personNumbers.contains(.firstSingular) == false)
    #expect(choices.first { $0.tense == .presenteDeIndicativo }?.personNumbers.contains(.secondSingularVos) == false)
    #expect(choices.first { $0.tense == .presenteDeIndicativo }?.personNumbers.contains(.secondPlural) == true)
  }

  // Grading

  @Test func everyRightReadingIsRight() throws {
    let fuera = try question("ser", .imperfectoDeSubjuntivo1, .firstSingular)
    #expect(fuera.grade(answer("ser", .imperfectoDeSubjuntivo1, .firstSingular)).isCorrect)
    #expect(fuera.grade(answer("ir", .imperfectoDeSubjuntivo1, .thirdSingular)).isCorrect)
    #expect(fuera.grade(answer("  IR ", .imperfectoDeSubjuntivo1, .firstSingular)).isCorrect)
    let hable = try question("hablar", .presenteDeSubjuntivo, .thirdSingular)
    #expect(hable.grade(answer("hablar", .imperativoPositivo, .thirdSingular)).isCorrect)
  }

  @Test func aReflexiveOnlyVerbIsRightWithItsPronounOrWithout() throws {
    let prompt = try question("arrepentir", .presenteDeIndicativo, .firstSingular)
    #expect(prompt.grade(answer("arrepentirse", .presenteDeIndicativo, .firstSingular)).isCorrect)
    #expect(prompt.grade(answer("arrepentir", .presenteDeIndicativo, .firstSingular)).isCorrect)
  }

  @Test func aPartIsWrongOnlyWhenChangingItCanMakeTheAnswerRight() throws {
    let fuera = try question("ser", .imperfectoDeSubjuntivo1, .firstSingular)
    let hablamos = try question("hablar", .presenteDeIndicativo, .firstPlural)
    let hablo = try question("hablar", .pretérito, .thirdSingular)
    let diciendo = try question("decir", .gerundio, .none)
    let reir = try question("reír", .presenteDeIndicativo, .firstSingular)
    let cases: [(RecognitionQuestion, RecognitionAnswer, Set<RecognitionPart>, Bool)] = [
      (fuera, answer("ser", .pretérito, .firstSingular), [.tense], true),
      (hablamos, answer("hablar", .presenteDeIndicativo, .firstSingular), [.person], true),
      (hablo, answer("hablar", .presenteDeIndicativo, .firstSingular), [.tense, .person], true),
      (hablo, answer("comer", .pretérito, .thirdSingular), [.infinitive], true),
      (hablo, answer("comer", .pretérito, .firstSingular), [.infinitive, .person], true),
      (hablo, answer("comer", .presenteDeIndicativo, .thirdSingular), [.infinitive, .tense], true),
      (hablo, answer("comer", .presenteDeIndicativo, .firstSingular), [.infinitive, .tense, .person], false),
      // The gerundio has no person, so only its tense is wrong.
      (diciendo, answer("decir", .presenteDeIndicativo, .firstSingular), [.tense], true),
      (hablo, answer("hablar", .gerundio), [.tense], true),
      // Accents count in the infinitive.
      (reir, answer("reir", .presenteDeIndicativo, .firstSingular), [.infinitive], true)
    ]
    for (question, answer, wrong, hasRightPart) in cases {
      let grade = question.grade(answer)
      #expect(grade.wrongParts == wrong, "\(question.prompt): \(answer.summary)")
      #expect(grade.hasRightPart == hasRightPart, "\(question.prompt): \(answer.summary)")
      #expect(grade.earnsSecondAttempt == hasRightPart)
    }
  }

  @Test func theTypedVerbsOwnCellsJudgeTheOtherParts() throws {
    // ve is ver's presente (él), but ir's only as tú's command: ir · Presente (él) is the tense
    // and person to check, not the verb.
    let ve = try question("ir", .imperativoPositivo, .secondSingularTú)
    #expect(ve.grade(answer("ir", .presenteDeIndicativo, .thirdSingular)).wrongParts == [.tense, .person])
    #expect(ve.grade(answer("ver", .presenteDeIndicativo, .thirdSingular)).isCorrect)
  }

  @Test func theLinesNameWhatToCheck() {
    let lines: [(Set<RecognitionPart>, String)] = [
      ([.infinitive], "Check the infinitive."),
      ([.tense], "Check the tense."),
      ([.person], "Check the person."),
      ([.infinitive, .tense], "Check the infinitive and the tense."),
      ([.infinitive, .person], "Check the infinitive and the person."),
      ([.tense, .person], "Check the tense and the person.")
    ]
    for (wrong, line) in lines {
      #expect(RecognitionGrade(wrongParts: wrong, hasRightPart: true).line == line)
    }
  }

  // What the screen shows

  @Test func theCorrectionListsEveryRightAnswerOneLinePerVerb() throws {
    #expect(try question("hablar", .presenteDeSubjuntivo, .thirdSingular).answerLines == [
      "hablar · Presente de Subjuntivo (yo, él) · Imperativo Positivo (usted)"
    ])
    #expect(try question("ser", .imperfectoDeSubjuntivo1, .firstSingular).answerLines == [
      "ser · Imperfecto de Subjuntivo 1 (yo, él)",
      "ir · Imperfecto de Subjuntivo 1 (yo, él)"
    ])
    #expect(try question("decir", .gerundio, .none).answerLines == ["decir · Gerundio"])
    #expect(try question("arrepentir", .presenteDeIndicativo, .firstSingular).answerLines == ["arrepentirse · Presente de Indicativo (yo)"])
  }

  @Test func anAnswersSummaryAndTheChipsLabels() {
    #expect(answer(" Ser", .pretérito, .firstSingular).summary == "ser · Pretérito (yo)")
    #expect(answer("hablar", .imperativoPositivo, .thirdPlural).summary == "hablar · Imperativo Positivo (ustedes)")
    #expect(answer("decir", .gerundio).summary == "decir · Gerundio")
    #expect(RecognitionQuestion.personLabel(.thirdSingular, in: .presenteDeIndicativo) == "él, ella, usted")
    #expect(RecognitionQuestion.personLabel(.thirdSingular, in: .imperativoNegativo) == "usted")
    #expect(RecognitionQuestion.personLabel(.thirdPlural, in: .pretérito) == "ellos, ellas, ustedes")
    #expect(RecognitionQuestion.personLabel(.secondSingularVos, in: .pretérito) == "vos")
    #expect(DisplayTense.imperfectoDeSubjuntivo1.recognitionChipName == "imperfecto 1")
    #expect(DisplayTense.condicionalCompuesto.recognitionChipName == "condicional compuesto")
  }

  @Test func everyTenseHasAMood() {
    let asked = Set(QuizLevel.allCases.flatMap { $0.pool.map(\.tense) })
    #expect(asked.isSubset(of: Set(RecognitionMood.tenseOrder)))
    #expect(RecognitionMood.tenseOrder.count == Set(RecognitionMood.tenseOrder).count)
  }

  // The scope

  @Test func theScopeIsUnrankedAndContinues() {
    let scope = QuizScope.recognition()
    #expect(scope.isRecognition)
    #expect(scope.source == .recognition)
    #expect(scope.questionCount == 10)
    #expect(!scope.isRanked)
    #expect(!scope.mixesDueItems)
    #expect(scope.continues)
    #expect(scope.sendsQuestionCounts)
    #expect(scope.startsLiveActivity)
    #expect(LastQuizResult.Kind(scope: scope) == .recognition)
  }

  // A round

  @Test func aBeginnerRoundAsksTenDistinctFormsOfTheBandAndTenses() {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .recognition()))
    #expect(quiz.questions.count == 10)
    let tenses = Set(QuizLevel.beginner.pool.map(\.tense))
    for question in quiz.questions {
      #expect(question.recognition != nil)
      #expect(tenses.contains(question.tense))
      #expect(VerbMap.shared.entry(for: question.verb)?.isIn(.top100) == true)
      #expect(question.recognition?.cells.contains(RecognitionCell(verb: question.verb, cell: ConjugationCell(tense: question.tense, personNumber: question.personNumber))) == true)
    }
    #expect(Set(quiz.questions.compactMap { $0.recognition?.prompt.lowercased() }).count == 10)
  }

  @Test func aRightAnswerScoresAndRecordsNothing() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .recognition()))
    #expect(quiz.processRecognition(try rightAnswer(quiz)) == .totalMatch)
    #expect(quiz.score == 10)
    #expect(quiz.currentQuestionIndex == 1)
    #expect(practice.record.isEmpty)
  }

  @Test func anAnswerWithARightPartGetsOneMoreTryForHalfPoints() throws {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .recognition()))
    let right = try rightAnswer(quiz)
    let wrongTense: DisplayTense = right.tense == .presenteDeIndicativo ? .imperativoPositivo : .presenteDeIndicativo
    let personNumber: DisplayPersonNumber = wrongTense == .imperativoPositivo ? .thirdPlural : .firstSingular
    // Unless the other tense happens to write the prompt too.
    let wrong = answer(right.infinitive, wrongTense, personNumber)
    try #require(quiz.currentQuestion?.recognition?.grade(wrong).isCorrect == false)

    #expect(quiz.processRecognition(wrong) == nil)
    #expect(quiz.isAwaitingSecondAttempt)
    #expect(quiz.secondAttemptPrompt.hasPrefix("Check the"))
    #expect(quiz.secondAttemptPrompt.hasSuffix("Try once more."))
    #expect(quiz.processRecognition(right) == .secondAttemptMatch)
    #expect(quiz.score == 5)
    #expect(quiz.firstAttempts.first == wrong.summary)
    #expect(!quiz.isAwaitingSecondAttempt)
  }

  @Test func aWrongAnswerHoldsItsCorrectionAndIsAskedAgain() throws {
    let quiz = makeQuiz()
    #expect(quiz.start(scope: .recognition()))
    let asked = try #require(quiz.currentQuestion)
    let recognition = try #require(asked.recognition)
    // A tense and a person that no right answer has, so that no part is right.
    let wrongCell = try #require(recognition.choices.flatMap(\.cells).first { cell in
      !recognition.cells.contains { $0.cell.tense == cell.tense || $0.cell.personNumber == cell.personNumber }
    })
    let wrong = answer("zzzz", wrongCell.tense, wrongCell.personNumber)
    try #require(recognition.grade(wrong).hasRightPart == false)

    #expect(quiz.processRecognition(wrong) == .noMatch)
    #expect(quiz.isHeld)
    #expect(quiz.correction?.recognitionAnswer == wrong)
    #expect(quiz.correction?.recognitionGrade?.wrongParts.contains(.infinitive) == true)
    #expect(quiz.correction?.willBeReasked == true)
    #expect(quiz.questions.count == 11)
    let reask = try #require(quiz.questions.first { $0.isReask })
    #expect(reask.recognition == asked.recognition)
    #expect(quiz.proposedAnswers == [wrong.summary])
    #expect(quiz.correctAnswers == [asked.recognition?.prompt ?? ""])

    quiz.continueAfterCorrection()
    #expect(!quiz.isHeld)
    #expect(quiz.currentQuestionIndex == 1)
  }

  @Test func aFinishedRoundKeepsItsResultAndTenMoreShowsNewForms() throws {
    let practice = PracticeStore(getterSetter: GetterSetterFake())
    let quiz = makeQuiz(practice: practice)
    #expect(quiz.start(scope: .recognition()))
    while quiz.quizState == .inProgress {
      quiz.processRecognition(try rightAnswer(quiz))
    }
    #expect(quiz.score == 100)
    #expect(practice.lastResult?.kind == .recognition)
    #expect(practice.lastResult?.level == .beginner)
    #expect(practice.lastResult?.title == "Name the Form")
    #expect(practice.record.isEmpty)

    #expect(quiz.canContinue)
    #expect(quiz.continueSession())
    #expect(quiz.questions.count == 20)
    #expect(Set(quiz.questions.compactMap { $0.recognition?.prompt.lowercased() }).count == 20)
  }
}
