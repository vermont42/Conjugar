//
//  QuizSecondAttemptTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  One more try: a slip waits on its question with the clock running, a right second attempt
//  earns half points and is counted apart, and a wrong one goes to the correction. The quizzes
//  here are Test Me's, which start no Live Activity.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizSecondAttemptTests {
  private func startedQuiz() -> Quiz {
    let quiz = Quiz(settings: Settings(getterSetter: GetterSetterFake()), gameCenter: GameCenterFake(), shouldShuffle: false)
    #expect(quiz.start(scope: .verbPage("hablar")))
    #expect(quiz.questionCount > 1)
    return quiz
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer?.lowercased() ?? ""
  }

  /// The right answer with a letter added, a slip of every hablar cell, none of which ends in x.
  private func slip(_ quiz: Quiz) -> String {
    rightAnswer(quiz) + "x"
  }

  @Test func aSlipWaitsOnItsQuestionWithTheClockRunning() {
    let quiz = startedQuiz()
    let answer = slip(quiz)
    #expect(quiz.process(proposedAnswer: answer) == nil)
    #expect(quiz.isAwaitingSecondAttempt)
    #expect(quiz.firstAttempt == answer)
    #expect(!quiz.isHeld)
    #expect(quiz.isClockRunning)
    #expect(quiz.currentQuestionIndex == 0)
    #expect(quiz.results.isEmpty)
    #expect(quiz.proposedAnswers.isEmpty)
    #expect(quiz.score == 0)
    quiz.quit()
  }

  @Test func aRightSecondAttemptEarnsHalfAndIsCountedApart() {
    let quiz = startedQuiz()
    let first = slip(quiz)
    quiz.process(proposedAnswer: first)
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .secondAttemptMatch)
    #expect(quiz.currentQuestionIndex == 1)
    #expect(!quiz.isAwaitingSecondAttempt)
    #expect(quiz.score == ConjugationResult.secondAttemptMatch.rawValue)
    #expect(quiz.correctCount == 0)
    #expect(quiz.secondAttemptCount == 1)
    #expect(quiz.firstAttempts == [first])
    quiz.quit()
  }

  @Test func aSecondSlipGoesToTheCorrection() {
    let quiz = startedQuiz()
    let answer = slip(quiz)
    quiz.process(proposedAnswer: answer)
    #expect(quiz.process(proposedAnswer: answer) == .noMatch)
    #expect(quiz.isHeld)
    #expect(!quiz.isAwaitingSecondAttempt)
    #expect(!quiz.isClockRunning)
    #expect(quiz.firstAttempts == [answer])
    #expect(quiz.score == 0)
    quiz.quit()
  }

  @Test func aFarWrongAnswerGoesToTheCorrectionAtOnce() {
    let quiz = startedQuiz()
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    #expect(quiz.isHeld)
    #expect(quiz.firstAttempts == [nil])
    quiz.quit()
  }

  @Test func aRightFirstAttemptRecordsNoFirstAttempt() {
    let quiz = startedQuiz()
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    #expect(quiz.firstAttempts == [nil])
    #expect(quiz.correctCount == 1)
    #expect(quiz.secondAttemptCount == 0)
    quiz.quit()
  }

  @Test func quittingOrRestartingClearsTheFirstAttempt() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: slip(quiz))
    quiz.quit()
    #expect(!quiz.isAwaitingSecondAttempt)

    #expect(quiz.start(scope: .verbPage("hablar")))
    quiz.process(proposedAnswer: slip(quiz))
    #expect(quiz.start(scope: .verbPage("hablar")))
    #expect(!quiz.isAwaitingSecondAttempt)
    #expect(quiz.firstAttempts.isEmpty)
    quiz.quit()
  }

  @Test func theSlipsFixtureBehavesAsItsCommentsSay() {
    let slips: [(QuizQuestion, String)] = [
      (QuizQuestion("cantar", .condicional, .firstSingular), "cantaria"),
      (QuizQuestion("tener", .presenteDeIndicativo, .firstSingular), "tengp"),
      (QuizQuestion("ir", .futuroDeIndicativo, .firstSingular), "ire"),
      (QuizQuestion("enseñar", .condicional, .thirdSingular), "ensenaria"),
      (QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú), "no hablez"),
      (QuizQuestion("decir", .perfectoDeIndicativo, .thirdPlural), "han dicjo")
    ]
    let errors: [(QuizQuestion, String)] = [
      (QuizQuestion("hablar", .pretérito, .thirdSingular), "hablo"),
      (QuizQuestion("comer", .pretérito, .firstSingular), "comio"),
      (QuizQuestion("hablar", .presenteDeSubjuntivo, .firstSingular), "hablé"),
      (QuizQuestion("ser", .presenteDeIndicativo, .firstSingular), "sot")
    ]
    #expect(Quiz.slipsFixture == slips.map(\.0) + errors.map(\.0))
    for (question, answer) in slips {
      #expect(question.isSlip(answer), "\(answer)")
    }
    for (question, answer) in errors {
      #expect(!question.isSlip(answer), "\(answer)")
    }
  }
}
