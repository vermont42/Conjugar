//
//  QuizTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 12/3/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

// swiftlint:disable private_over_fileprivate
fileprivate let difficultSpain = 750
// swiftlint:enable private_over_fileprivate

class QuizTests: XCTestCase {
  func testQuiz() {
    GlobalContainer.registerUnitTestingDependencies()

    let spain = Region.spain.rawValue
    let latinAmerica = Region.latinAmerica.rawValue
    let difficult = Difficulty.difficult.rawValue
    let moderate = Difficulty.moderate.rawValue
    let easy = Difficulty.easy.rawValue

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
      GlobalContainer.registerSettings(Settings(getterSetter: DictionaryGetterSetter(dictionary: [Settings.difficultyKey: difficulty, Settings.regionKey: region])))
      _ = TestQuizDelegate(quiz: GlobalContainer.quiz, onFinish: { score in
        XCTAssertEqual(score, maxScore)
      })
    }
  }
}

class TestQuizDelegate: QuizDelegate {
  let quiz: Quiz
  let onFinish: (Int) -> ()
  private var score = 0

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

  func scoreDidChange(newScore: Int) {
    score = newScore
    XCTAssert(score >= 0 && score <= difficultSpain)
  }

  func timeDidChange(newTime: Int) {
    // Note: The time is always 0, so I'm not going to bother testing it.
    // I could slow down the test so it takes longer than 0 second, but
    // that would be contrary to the quickness goal of unit tests.
  }

  func progressDidChange(current: Int, total: Int) {
    let questionCount = 50
    XCTAssert(current >= 0 && current < questionCount)
    XCTAssertEqual(total, questionCount)
  }
}
