//
//  ResultsVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ResultsVCTests: XCTestCase {
  func testResultsVC() {
    var analytic = ""
    let settings = Settings(getterSetter: GetterSetterFake())
    settings.userRejectedGameCenter = true
    let gameCenter = GameCenterFake(isAuthenticated: true)
    let analytics = AnalyticsServiceSpy(fire: { fired in analytic = fired })
    let quiz = Quiz(settings: settings, gameCenter: gameCenter, shouldShuffle: false)
    let fakeRatingsCount = 42

    Current = World(
      analytics: analytics,
      reviewPrompter: ReviewPrompterStub(),
      gameCenter: gameCenter,
      settings: settings,
      quiz: quiz,
      session: URLSession.stubSession(ratingsCount: fakeRatingsCount),
      communGetter: CommunGetterStub(),
      locale: AnalyticsLocaleStub(languageCode: "en", regionCode: "US")
    )

    let rvc = ResultsVC()

    XCTAssertNotNil(rvc)
    XCTAssertNotNil(rvc.resultsView)
    rvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(ResultsVC.self) ")

    quiz.start()
    let expectedQuestionCount = 50
    (0 ..< expectedQuestionCount).forEach { _ in
      let wrongAnswer = "🥥"
      _ = quiz.process(proposedAnswer: wrongAnswer)
    }

    XCTAssertEqual(rvc.tableView(rvc.resultsView.table, numberOfRowsInSection: 0), expectedQuestionCount)

    let cell = rvc.tableView(rvc.resultsView.table, cellForRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(cell is ResultCell)
  }
}
