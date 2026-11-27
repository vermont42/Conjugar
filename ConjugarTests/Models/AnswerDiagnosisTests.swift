//
//  AnswerDiagnosisTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Naming the error: each kind of diagnosis for real verbs, the answers that get none, the
//  lines in English, and a diagnosed error's one more attempt in a quiz. The quizzes here are
//  Test Me's, which start no Live Activity.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct AnswerDiagnosisTests {
  private typealias Case = (question: QuizQuestion, answer: String, diagnosis: AnswerDiagnosis)

  private func expect(_ cases: [Case]) {
    for (question, answer, diagnosis) in cases {
      #expect(question.diagnosis(of: answer) == diagnosis, "\(question.verb) \(question.tense) \(question.personNumber): \(answer)")
    }
  }

  @Test func negativeCommandsWrittenAsAffirmativeOrIndicative() {
    expect([
      (QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú), "no habla", .negativeCommand),
      (QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú), "no hablas", .negativeCommand),
      (QuizQuestion("hablar", .imperativoNegativo, .secondPlural), "no hablad", .negativeCommand),
      (QuizQuestion("tener", .imperativoNegativo, .secondSingularTú), "no ten", .negativeCommand),
      (QuizQuestion("hablar", .imperativoNegativo, .secondSingularVos), "no hablá", .negativeCommand)
    ])
  }

  @Test func spellingChangesLeftOut() {
    expect([
      (QuizQuestion("buscar", .pretérito, .firstSingular), "buscé", .consonantSpelling(infinitive: "buscar", from: "c", to: "qu", beforeE: true)),
      (QuizQuestion("buscar", .presenteDeSubjuntivo, .thirdSingular), "busce", .consonantSpelling(infinitive: "buscar", from: "c", to: "qu", beforeE: true)),
      (QuizQuestion("llegar", .pretérito, .firstSingular), "llegé", .consonantSpelling(infinitive: "llegar", from: "g", to: "gu", beforeE: true)),
      (QuizQuestion("empezar", .pretérito, .firstSingular), "empezé", .consonantSpelling(infinitive: "empezar", from: "z", to: "c", beforeE: true)),
      (QuizQuestion("escoger", .presenteDeIndicativo, .firstSingular), "escogo", .consonantSpelling(infinitive: "escoger", from: "g", to: "j", beforeE: false)),
      (QuizQuestion("vencer", .presenteDeIndicativo, .firstSingular), "venco", .consonantSpelling(infinitive: "vencer", from: "c", to: "z", beforeE: false)),
      (QuizQuestion("leer", .pretérito, .thirdSingular), "leió", .endingIBecomesY(infinitive: "leer")),
      (QuizQuestion("construir", .pretérito, .thirdPlural), "construieron", .endingIBecomesY(infinitive: "construir")),
      (QuizQuestion("bullir", .pretérito, .thirdSingular), "bullió", .endingLosesI(infinitive: "bullir", after: "ll")),
      (QuizQuestion("tañer", .pretérito, .thirdPlural), "tañieron", .endingLosesI(infinitive: "tañer", after: "ñ")),
      (QuizQuestion("enviar", .presenteDeIndicativo, .firstSingular), "envio", .stemAccent(infinitive: "enviar", vowel: "i")),
      (QuizQuestion("actuar", .presenteDeIndicativo, .thirdSingular), "actua", .stemAccent(infinitive: "actuar", vowel: "u"))
    ])
  }

  @Test func stemChangesMissingOrMisplaced() {
    expect([
      (QuizQuestion("pensar", .presenteDeIndicativo, .firstSingular), "penso", .stemChangeMissing(infinitive: "pensar", from: "e", to: "ie")),
      (QuizQuestion("dormir", .presenteDeIndicativo, .firstSingular), "dormo", .stemChangeMissing(infinitive: "dormir", from: "o", to: "ue")),
      (QuizQuestion("sentir", .pretérito, .thirdSingular), "sentió", .stemChangeMissing(infinitive: "sentir", from: "e", to: "i")),
      (QuizQuestion("jugar", .presenteDeIndicativo, .secondSingularTú), "jugas", .stemChangeMissing(infinitive: "jugar", from: "u", to: "ue")),
      (QuizQuestion("pedir", .presenteDeIndicativo, .firstSingular), "pedo", .stemChangeMissing(infinitive: "pedir", from: "e", to: "i")),
      (QuizQuestion("tener", .presenteDeIndicativo, .secondSingularTú), "tenes", .stemChangeMissing(infinitive: "tener", from: "e", to: "ie")),
      (QuizQuestion("pensar", .presenteDeIndicativo, .firstPlural), "piensamos", .stemChangeMisplaced(infinitive: "pensar")),
      (QuizQuestion("dormir", .presenteDeIndicativo, .firstPlural), "duermimos", .stemChangeMisplaced(infinitive: "dormir")),
      (QuizQuestion("sentir", .pretérito, .firstSingular), "sintí", .stemChangeMisplaced(infinitive: "sentir"))
    ])
  }

  /// sientamos for sintamos is wrong, but the stem does change there, so "does not change here"
  /// would be false.
  @Test func aStemThatChangesOtherwiseIsNotCalledUnchanged() {
    let diagnosis = QuizQuestion("sentir", .presenteDeSubjuntivo, .firstPlural).diagnosis(of: "sientamos")
    #expect(diagnosis != .stemChangeMisplaced(infinitive: "sentir"))
  }

  @Test func regularFormsOfIrregularVerbs() {
    expect([
      (QuizQuestion("tener", .pretérito, .firstSingular), "tení", .regularForm(infinitive: "tener", tense: .pretérito)),
      (QuizQuestion("saber", .presenteDeIndicativo, .firstSingular), "sabo", .regularForm(infinitive: "saber", tense: .presenteDeIndicativo)),
      (QuizQuestion("poner", .pretérito, .firstSingular), "poní", .regularForm(infinitive: "poner", tense: .pretérito)),
      (QuizQuestion("tener", .futuroDeIndicativo, .firstSingular), "teneré", .regularForm(infinitive: "tener", tense: .futuroDeIndicativo)),
      (QuizQuestion("hacer", .participio, .none), "hacido", .regularForm(infinitive: "hacer", tense: .participio)),
      (QuizQuestion("escribir", .participio, .none), "escribido", .regularForm(infinitive: "escribir", tense: .participio)),
      (QuizQuestion("hacer", .perfectoDeIndicativo, .firstSingular), "he hacido", .regularForm(infinitive: "hacer", tense: .participio)),
      (QuizQuestion("detener", .pretérito, .firstSingular), "detení", .regularForm(infinitive: "detener", tense: .pretérito)),
      (QuizQuestion("tener", .presenteDeIndicativo, .firstSingular), "yo teno", .regularForm(infinitive: "tener", tense: .presenteDeIndicativo))
    ])
  }

  @Test func theOtherImperfectSubjunctive() {
    expect([
      (QuizQuestion("hablar", .imperfectoDeSubjuntivo2, .firstSingular), "hablara", .otherImperfectSubjunctive(givenIsRa: true)),
      (QuizQuestion("hablar", .imperfectoDeSubjuntivo1, .firstPlural), "hablásemos", .otherImperfectSubjunctive(givenIsRa: false)),
      (QuizQuestion("tener", .pluscuamperfectoDeSubjuntivo2, .thirdSingular), "hubiera tenido", .otherImperfectSubjunctive(givenIsRa: true))
    ])
  }

  @Test func anotherPersonOfTheAskedTense() {
    expect([
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "hablas", .otherPerson(tense: .presenteDeIndicativo, persons: [.secondSingularTú])),
      (QuizQuestion("hablar", .perfectoDeIndicativo, .firstSingular), "ha hablado", .otherPerson(tense: .perfectoDeIndicativo, persons: [.thirdSingular])),
      (QuizQuestion("hablar", .presenteDeIndicativo, .secondSingularTú), "hablás", .otherPerson(tense: .presenteDeIndicativo, persons: [.secondSingularVos])),
      (QuizQuestion("hablar", .presenteDeIndicativo, .secondSingularVos), "hablas", .otherPerson(tense: .presenteDeIndicativo, persons: [.secondSingularTú])),
      (QuizQuestion("hablar", .presenteDeSubjuntivo, .secondSingularTú), "hable", .otherPerson(tense: .presenteDeSubjuntivo, persons: [.firstSingular, .thirdSingular])),
      (QuizQuestion("hablar", .imperativoPositivo, .secondSingularTú), "hable", .otherPerson(tense: .imperativoPositivo, persons: [.thirdSingular]))
    ])
  }

  @Test func anotherTense() {
    expect([
      (QuizQuestion("hablar", .pretérito, .thirdSingular), "hablo", .otherTense(.presenteDeIndicativo, persons: [.firstSingular])),
      (QuizQuestion("hablar", .pretérito, .firstSingular), "hablaba", .otherTense(.imperfectoDeIndicativo, persons: [])),
      (QuizQuestion("hablar", .presenteDeSubjuntivo, .thirdSingular), "hablé", .otherTense(.pretérito, persons: [.firstSingular])),
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "hablé", .otherTense(.pretérito, persons: [])),
      (QuizQuestion("hablar", .perfectoDeIndicativo, .firstSingular), "había hablado", .otherTense(.pluscuamperfectoDeIndicativo, persons: [])),
      (QuizQuestion("comer", .presenteDeIndicativo, .firstSingular), "comer", .otherTense(.infinitivo, persons: []))
    ])
  }

  @Test func answersThatGetNoDiagnosis() {
    let cases: [(QuizQuestion, String)] = [
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "hablo"),
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "yo hablo"),
      (QuizQuestion("reír", .pretérito, .thirdSingular), "rió"),
      (QuizQuestion("freír", .participio, .none), "frito"),
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "hablox"),
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), "zzzz"),
      (QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), ""),
      (QuizQuestion("comer", .pretérito, .firstSingular), "comio"),
      // leer's accent is spelling, not irregularity, so leiste is not the form of a regular verb.
      (QuizQuestion("leer", .pretérito, .secondSingularTú), "leiste")
    ]
    for (question, answer) in cases {
      #expect(question.diagnosis(of: answer) == nil, "\(question.verb): \(answer)")
    }
  }

  @Test func linesInEnglish() {
    #expect(AnswerDiagnosis.negativeCommand.line == "Negative commands use the subjunctive.")
    #expect(AnswerDiagnosis.consonantSpelling(infinitive: "buscar", from: "c", to: "qu", beforeE: true).line == "In buscar, c becomes qu before e.")
    #expect(AnswerDiagnosis.consonantSpelling(infinitive: "vencer", from: "c", to: "z", beforeE: false).line == "In vencer, c becomes z before a or o.")
    #expect(AnswerDiagnosis.stemChangeMissing(infinitive: "pensar", from: "e", to: "ie").line == "In pensar, the stem’s e becomes ie here.")
    #expect(AnswerDiagnosis.regularForm(infinitive: "tener", tense: .pretérito).line == "That is the regular form, but tener is irregular in the Pretérito.")
    #expect(AnswerDiagnosis.otherImperfectSubjunctive(givenIsRa: true).line == "That is the -ra form. The -se form was asked.")
    #expect(AnswerDiagnosis.otherPerson(tense: .presenteDeSubjuntivo, persons: [.firstSingular, .thirdSingular]).line == "That is the form for yo and él.")
    #expect(AnswerDiagnosis.otherPerson(tense: .imperativoPositivo, persons: [.thirdSingular]).line == "That is the form for usted.")
    #expect(AnswerDiagnosis.otherTense(.presenteDeIndicativo, persons: [.firstSingular]).line == "That is the form of the Presente de Indicativo (yo).")
    #expect(AnswerDiagnosis.otherTense(.imperfectoDeIndicativo, persons: []).line == "That is the form of the Imperfecto de Indicativo.")
    #expect(AnswerDiagnosis.otherTense(.infinitivo, persons: []).line == "That is the Infinitivo.")
  }

  @Test func theDiagnosesFixtureBehavesAsItsCommentsSay() {
    let answers = [
      "habla", "buscé", "escogo", "leió", "bullió", "envio", "penso", "piensamos", "tení", "he hacido", "hablara", "hablás",
      "ha hablado", "hablo", "comer"
    ]
    #expect(Quiz.diagnosesFixture.count == answers.count)
    for (question, typed) in zip(Quiz.diagnosesFixture, answers) {
      #expect(question.diagnosis(of: question.answer(filling: typed)) != nil, "\(question.verb): \(typed)")
    }
  }

  /// The older fixtures' wrong answers that are now named rather than corrected at once or called
  /// slips.
  @Test func theOlderFixturesDiagnosedAnswers() {
    expect([
      (QuizQuestion("hablar", .pretérito, .thirdSingular), "hablo", .otherTense(.presenteDeIndicativo, persons: [.firstSingular])),
      (QuizQuestion("tener", .presenteDeIndicativo, .firstSingular), "teno", .regularForm(infinitive: "tener", tense: .presenteDeIndicativo)),
      (QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú), "no hablas", .negativeCommand),
      (QuizQuestion("decir", .perfectoDeIndicativo, .thirdPlural), "han decido", .regularForm(infinitive: "decir", tense: .participio)),
      (QuizQuestion("hablar", .presenteDeSubjuntivo, .firstSingular), "hablé", .otherTense(.pretérito, persons: []))
    ])
    #expect(QuizQuestion("freír", .participio, .none).diagnosis(of: "freido") == nil)
    #expect(QuizQuestion("ser", .presenteDeIndicativo, .firstSingular).diagnosis(of: "sot") == nil)
  }

  private func startedQuiz() -> Quiz {
    let quiz = Quiz(settings: Settings(getterSetter: GetterSetterFake()), gameCenter: GameCenterFake(), shouldShuffle: false, practice: PracticeStore(getterSetter: GetterSetterFake()))
    #expect(quiz.start(scope: .verbPage("hablar")))
    #expect(quiz.questionCount > 1)
    return quiz
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  /// The infinitive, which no question asks, and which every question names.
  private let infinitive = "hablar"
  private let infinitiveDiagnosis = AnswerDiagnosis.otherTense(.infinitivo, persons: [])

  @Test func aDiagnosedErrorWaitsOnItsQuestionWithItsLine() {
    let quiz = startedQuiz()
    #expect(quiz.process(proposedAnswer: infinitive) == nil)
    #expect(quiz.isAwaitingSecondAttempt)
    #expect(quiz.firstAttempt == infinitive)
    #expect(quiz.firstAttemptDiagnosis == infinitiveDiagnosis)
    #expect(quiz.secondAttemptPrompt == infinitiveDiagnosis.line + " " + L.Quiz.tryOnceMore)
    #expect(quiz.isClockRunning)
    #expect(quiz.results.isEmpty)
    quiz.quit()
  }

  @Test func aRightRepairEarnsHalfPoints() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: infinitive)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .secondAttemptMatch)
    #expect(quiz.secondAttemptCount == 1)
    #expect(quiz.firstAttempts == [infinitive])
    #expect(quiz.firstAttemptDiagnosis == nil)
    quiz.quit()
  }

  @Test func aWrongRepairShowsItsOwnDiagnosis() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: infinitive)
    #expect(quiz.process(proposedAnswer: infinitive) == .noMatch)
    #expect(quiz.correction?.diagnosis == infinitiveDiagnosis)

    quiz.continueAfterCorrection()
    quiz.process(proposedAnswer: infinitive)
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    #expect(quiz.correction?.diagnosis == nil)
    quiz.quit()
  }

  @Test func aSlipAfterADiagnosisGoesToTheCorrection() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: infinitive)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz) + "x") == .noMatch)
    #expect(quiz.isHeld)
    quiz.quit()
  }

  @Test func aSlipStillSaysAlmost() {
    let quiz = startedQuiz()
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz) + "x") == nil)
    #expect(quiz.firstAttemptDiagnosis == nil)
    #expect(quiz.secondAttemptPrompt == L.Quiz.almost)
    quiz.quit()
  }
}
