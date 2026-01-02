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
  func testAuthenticate() async {
    let tgc = TestGameCenter()
    Current = World.unitTest
    Current.gameCenter = tgc
    let dummyVC = UIViewController()

    let didAuthenticate = await tgc.authenticate(onViewController: dummyVC)
    XCTAssert(didAuthenticate)

    let didAuthenticateAgain = await tgc.authenticate(onViewController: dummyVC)
    XCTAssertFalse(didAuthenticateAgain)
  }

  func testReportScore() async {
    // Nothing to test. Exercising for coverage.
    let tgc = TestGameCenter()
    await tgc.reportScore(42)
  }

  func testShowLeaderboard() {
    // Nothing to test. Exercising for coverage.
    let tgc = TestGameCenter()
    tgc.showLeaderboard()
  }
}
