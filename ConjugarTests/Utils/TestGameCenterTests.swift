//
//  TestGameCenterTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class TestGameCenterTests: XCTestCase {
  private let analytics = TestAnalyticsService()

  func testAuthenticate() {
    let tgc = TestGameCenter(isAuthenticated: false)

    tgc.authenticate(analyticsService: analytics, completion: { didAuthenticate in
      XCTAssert(didAuthenticate)

      tgc.authenticate(analyticsService: self.analytics, completion: { didAuthenticate in
        XCTAssertFalse(didAuthenticate)
      })
    })
  }

  func testReportScore() {
    // Nothing to test. Exercising for coverage.
    let tgc = TestGameCenter()
    tgc.reportScore(42)
  }

  func testShowLeaderboard() {
    // Nothing to test. Exercising for coverage.
    let tgc = TestGameCenter()
    tgc.showLeaderboard()
  }
}
