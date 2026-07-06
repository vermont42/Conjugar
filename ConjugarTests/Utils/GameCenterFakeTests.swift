//
//  GameCenterFakeTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class GameCenterFakeTests: XCTestCase {
  // Deliberately not installed into Current: a fire-and-forget authenticate
  // Task lingering from an earlier test (QuizVC/SettingsView spawn them) could
  // otherwise consume this fake's one "first authenticate" and flake the test.
  func testAuthenticate() async {
    let tgc = GameCenterFake()
    let dummyVC = UIViewController()

    let didAuthenticate = await tgc.authenticate(onViewController: dummyVC)
    XCTAssert(didAuthenticate)

    let didAuthenticateAgain = await tgc.authenticate(onViewController: dummyVC)
    XCTAssertFalse(didAuthenticateAgain)
  }

  func testReportScore() async {
    // Nothing to test. Exercising for coverage.
    let tgc = GameCenterFake()
    await tgc.reportScore(42)
  }

  func testShowLeaderboard() {
    // Nothing to test. Exercising for coverage.
    let tgc = GameCenterFake()
    tgc.showLeaderboard()
  }
}
