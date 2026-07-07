//
//  QuizTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/3/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//
//  Rewritten as Swift Testing during the SwiftUI migration (Step 4): the quiz is
//  now a delegate-free @Observable model, so the test drives it by answering the
//  current question correctly in a loop and asserting the maxed-out final score.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizTests {
  /// A perfect run (every answer a total match) yields the maximum score, which
  /// is `50 questions × 10 × region modifier × difficulty modifier`.
  @Test func perfectRunScoresTheMaximum() {
    let cases: [(region: Region, difficulty: Difficulty, maxScore: Int)] = [
      (.spain, .difficult, 750),
      (.latinAmerica, .difficult, 624),
      (.spain, .moderate, 500),
      (.latinAmerica, .moderate, 416),
      (.spain, .easy, 250),
      (.latinAmerica, .easy, 208)
    ]

    for testCase in cases {
      let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
        Settings.difficultyKey: testCase.difficulty.rawValue,
        Settings.regionKey: testCase.region.rawValue
      ]))
      let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: true)
      quiz.start()

      let questionCount = quiz.questionCount
      #expect(questionCount == 50)

      while quiz.quizState == .inProgress {
        #expect(quiz.currentQuestionIndex >= 0 && quiz.currentQuestionIndex < questionCount)
        let result = TenseBridge.conjugate(infinitive: quiz.verb, tense: quiz.tense, personNumber: quiz.currentPersonNumber)
        guard case .success(let correct) = result else {
          Issue.record("Conjugation failed for \(quiz.verb) in \(testCase.region)/\(testCase.difficulty).")
          break
        }
        _ = quiz.process(proposedAnswer: correct)
        #expect(quiz.score >= 0 && quiz.score <= 750)
      }

      #expect(quiz.quizState == .finished)
      #expect(quiz.score == testCase.maxScore, "Wrong max for \(testCase.region)/\(testCase.difficulty).")
      #expect(quiz.proposedAnswers.count == questionCount)
      #expect(quiz.correctAnswers.count == questionCount)
    }
  }
}
