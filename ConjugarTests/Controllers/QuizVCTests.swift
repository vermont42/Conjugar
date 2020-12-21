//
//  QuizVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class QuizVCTests: XCTestCase {
  func testQuizVC() {
    var analytic = ""
    let settings = Settings(getterSetter: DictionaryGetterSetter())
    settings.userRejectedGameCenter = true
    let gameCenter = TestGameCenter(isAuthenticated: false)
    let analytics = TestAnalyticsService(fire: { fired in analytic = fired })
    let quiz = Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false)
    let fakeRatingsCount = 42

    Current = World(
      analytics: analytics,
      reviewPrompter: TestReviewPrompter(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: quiz,
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: StubCommunGetter(),
      locale: StubLocale(languageCode: "en", regionCode: "US")
    )

    let qvc = QuizVC()

    XCTAssertNotNil(qvc)
    XCTAssertNotNil(qvc.quizView)
    qvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(QuizVC.self) ")
    let quizView = qvc.quizView
    XCTAssertEqual(quizView.startRestartButton.titleLabel?.text, "Start")
    qvc.startRestart()
    XCTAssertEqual(quizView.startRestartButton.titleLabel?.text, "Restart")
    qvc.viewWillAppear(true)
    XCTAssertEqual(quizView.startRestartButton.titleLabel?.text, "Restart")

    XCTAssertEqual(quizView.score.text, "0")
    XCTAssertEqual(quizView.progress.text, "1 / 50")
    quizView.conjugationField.text = "caminas"
    XCTAssert(qvc.textFieldShouldReturn(quizView.conjugationField))
    [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
      XCTAssert($0.isHidden)
    }

    let wrongAnswer = "🥥"
    let correctAnswer = "anda"
    XCTAssertEqual(quizView.score.text, "10")
    XCTAssertEqual(quizView.progress.text, "2 / 50")
    quizView.conjugationField.text = wrongAnswer
    XCTAssert(qvc.textFieldShouldReturn(quizView.conjugationField))
    [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
      XCTAssertFalse($0.isHidden)
    }
    XCTAssertEqual(quizView.last.text, wrongAnswer)
    XCTAssertEqual(quizView.correct.text, correctAnswer)

    let remainingQuestionCount = 48
    for _ in 0 ..< remainingQuestionCount {
      quizView.conjugationField.text = wrongAnswer
      XCTAssert(qvc.textFieldShouldReturn(quizView.conjugationField))
    }
    let expectedCompletionAnalytic = "quizCompletion score: 4 "
    XCTAssertEqual(analytic, expectedCompletionAnalytic)

    XCTAssert(quizView.score.isHidden)
    qvc.startRestart()
    XCTAssertFalse(quizView.score.isHidden)
    qvc.quit()
    XCTAssert(quizView.score.isHidden)
  }
}
