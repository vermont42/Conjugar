//
//  QuizTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/3/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//
//  Drives the @Observable quiz by answering the current question correctly in a loop
//  and asserting the maxed-out final score.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct QuizTests {
  /// A perfect run (every answer a total match) scores 10 a question, 300 for thirty, at every
  /// level and in every region.
  @Test func perfectRunScoresTheMaximum() {
    let cases: [(region: Region, level: QuizLevel)] = Region.allCases.flatMap { region in
      QuizLevel.allCases.map { (region, $0) }
    }

    // Iterate both shuffle modes: `false` gives a deterministic, reproducible
    // run (the same verbs every time, so a regression can't hide behind randomness —
    // exactly how `manecer` dodged CI); `true` also exercises the shuffle path. Both
    // must score the maximum for a perfect run.
    for shouldShuffle in [false, true] {
      for testCase in cases {
        let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
          Settings.quizLevelKey: testCase.level.rawValue,
          Settings.regionKey: testCase.region.rawValue
        ]))
        let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: shouldShuffle)
        quiz.start()

        let questionCount = quiz.questionCount
        #expect(questionCount == 30)

        while quiz.quizState == .inProgress {
          #expect(quiz.currentQuestionIndex >= 0 && quiz.currentQuestionIndex < questionCount)
          let result = TenseBridge.conjugate(infinitive: quiz.verb, tense: quiz.tense, personNumber: quiz.currentPersonNumber)
          guard case .success(let correct) = result else {
            Issue.record("Conjugation failed for \(quiz.verb) in \(testCase.region)/\(testCase.level) (shuffle \(shouldShuffle)).")
            break
          }
          _ = quiz.process(proposedAnswer: correct)
          #expect(quiz.score >= 0 && quiz.score <= 300)
        }

        #expect(quiz.quizState == .finished)
        #expect(quiz.score == 300, "Wrong max for \(testCase.region)/\(testCase.level) (shuffle \(shouldShuffle)).")
        #expect(quiz.proposedAnswers.count == questionCount)
        #expect(quiz.correctAnswers.count == questionCount)
      }
    }
  }
}
