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
    GlobalContainer.registerUnitTestingDependencies()
    GlobalContainer.registerAnalytics(TestAnalyticsService(fire: { fired in analytic = fired }))

    let rvc = ResultsVC()
    UIApplication.shared.keyWindow?.rootViewController = rvc

    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(rvc)
    XCTAssertNotNil(rvc.resultsView)
    rvc.viewWillAppear(true)
    XCTAssertEqual(analytic, "visited viewController: \(ResultsVC.self) ")

    GlobalContainer.quiz.start()
    let expectedQuestionCount = 50
    (0 ..< expectedQuestionCount).forEach { _ in
      let wrongAnswer = "🥥"
      _ = GlobalContainer.quiz.process(proposedAnswer: wrongAnswer)
    }

    XCTAssertEqual(rvc.tableView(rvc.resultsView.table, numberOfRowsInSection: 0), expectedQuestionCount)

    let cell = rvc.tableView(rvc.resultsView.table, cellForRowAt: IndexPath(row: 0, section: 0))
    XCTAssert(cell is ResultCell)
  }
}
