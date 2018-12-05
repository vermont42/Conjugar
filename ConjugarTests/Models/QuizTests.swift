//
//  QuizTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/3/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class QuizTests: XCTestCase {
  private let testGameCenter = TestGameCenter()

  func testDifficultSpainQuiz() {
    let spain = Region.spain.rawValue
    let latinAmerica = Region.latinAmerica.rawValue
    let difficult = Difficulty.difficult.rawValue
    let moderate = Difficulty.moderate.rawValue
    let easy = Difficulty.easy.rawValue

    let difficultSpain = 750
    let difficultLatinAmerica = 624
    let moderateSpain = 500
    let moderateLatinAmerica = 416
    let easySpain = 250
    let easyLatinAmerica = 208

    [(spain, difficult, difficultSpain),
     (latinAmerica, difficult, difficultLatinAmerica),
     (spain, moderate, moderateSpain),
     (latinAmerica, moderate, moderateLatinAmerica),
     (spain, easy, easySpain),
     (latinAmerica, easy, easyLatinAmerica)
    ].forEach { region, difficulty, maxScore in
      let settings = Settings(customDefaults: [Settings.difficultyKey: difficulty, Settings.regionKey: region])
      let quiz = Quiz(settings: settings, gameCenter: testGameCenter, shouldShuffle: true)
      _ = TestQuizDelegate(quiz: quiz, onFinish: { score in
        XCTAssertEqual(score, maxScore)
      })
    }
  }
}

class TestQuizDelegate: QuizDelegate {
  let quiz: Quiz
  let onFinish: (Int) -> ()

  init(quiz: Quiz, onFinish: @escaping (Int) -> ()) {
    self.quiz = quiz
    self.onFinish = onFinish
    quiz.delegate = self
    quiz.start()
  }

  func questionDidChange(verb: String, tense: Tense, personNumber: PersonNumber) {
    let conjugationResult = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
    switch conjugationResult {
    case let .success(value):
      _ = quiz.process(proposedAnswer: value)
    default:
      fatalError("Conjugation failed during unit test.")
    }
  }

  func quizDidFinish() {
    onFinish(quiz.score)
  }

  func scoreDidChange(newScore: Int) {}

  func timeDidChange(newTime: Int) {}

  func progressDidChange(current: Int, total: Int) {}
}
