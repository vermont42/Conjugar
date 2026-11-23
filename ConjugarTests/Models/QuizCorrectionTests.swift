//
//  QuizCorrectionTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  The held correction: a wrong answer holds its question with the clock stopped until the learner
//  continues, and a right one advances at once. The quizzes here are Test Me's, which start no
//  Live Activity.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizCorrectionTests {
  private func startedQuiz() -> Quiz {
    let quiz = Quiz(settings: Settings(getterSetter: GetterSetterFake()), gameCenter: GameCenterFake(), shouldShuffle: false)
    #expect(quiz.start(scope: .verbPage("hablar")))
    #expect(quiz.questionCount > 1)
    return quiz
  }

  private func rightAnswer(_ quiz: Quiz) -> String {
    quiz.currentQuestion?.writtenAnswer ?? ""
  }

  @Test func aRightAnswerAdvancesAtOnce() {
    let quiz = startedQuiz()
    #expect(quiz.process(proposedAnswer: rightAnswer(quiz)) == .totalMatch)
    #expect(quiz.currentQuestionIndex == 1)
    #expect(!quiz.isHeld)
    #expect(quiz.isClockRunning)
    quiz.quit()
  }

  @Test func aWrongAnswerHoldsItsQuestionWithTheClockStopped() {
    let quiz = startedQuiz()
    let question = quiz.currentQuestion
    #expect(quiz.process(proposedAnswer: "zzzz") == .noMatch)
    #expect(quiz.currentQuestionIndex == 0)
    #expect(quiz.currentQuestion == question)
    #expect(quiz.isHeld)
    #expect(quiz.correction?.difference.given == "zzzz")
    #expect(quiz.correction?.difference.expected == question?.writtenAnswer)
    #expect(!quiz.isClockRunning)
    #expect(quiz.score == 0)
    #expect(quiz.results == [.noMatch])
    quiz.quit()
  }

  @Test func continuingAdvancesAndRestartsTheClock() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: "zzzz")
    quiz.continueAfterCorrection()
    #expect(!quiz.isHeld)
    #expect(quiz.correction == nil)
    #expect(quiz.currentQuestionIndex == 1)
    #expect(quiz.isClockRunning)
    quiz.quit()
  }

  @Test func continuingWithNothingHeldDoesNothing() {
    let quiz = startedQuiz()
    quiz.continueAfterCorrection()
    #expect(quiz.currentQuestionIndex == 0)
    quiz.quit()
  }

  @Test func aWrongLastAnswerShowsItsCorrectionBeforeTheResults() {
    let quiz = startedQuiz()
    while quiz.currentQuestionIndex < quiz.questionCount - 1 {
      quiz.process(proposedAnswer: rightAnswer(quiz))
    }
    quiz.process(proposedAnswer: "zzzz")
    #expect(quiz.quizState == .inProgress)
    #expect(quiz.isHeld)
    quiz.continueAfterCorrection()
    #expect(quiz.quizState == .finished)
    #expect(!quiz.isHeld)
    #expect(!quiz.isClockRunning)
    #expect(quiz.results.count == quiz.questionCount)
  }

  @Test func quittingOrRestartingClearsTheCorrection() {
    let quiz = startedQuiz()
    quiz.process(proposedAnswer: "zzzz")
    quiz.quit()
    #expect(!quiz.isHeld)

    #expect(quiz.start(scope: .verbPage("hablar")))
    quiz.process(proposedAnswer: "zzzz")
    #expect(quiz.start(scope: .verbPage("tener")))
    #expect(!quiz.isHeld)
    #expect(quiz.currentQuestionIndex == 0)
    quiz.quit()
  }
}
