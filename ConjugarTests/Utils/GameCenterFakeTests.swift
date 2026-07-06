//
//  GameCenterFakeTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Testing
import UIKit
@testable import Conjugar

// Swift Testing (not XCTest) — see SettingsTests for the isolated-deinit rationale.
@Suite("GameCenterFake")
@MainActor
struct GameCenterFakeTests {
  // Deliberately not installed into Current: a fire-and-forget authenticate
  // Task lingering from an earlier test (QuizVC/SettingsView spawn them) could
  // otherwise consume this fake's one "first authenticate" and flake the test.
  @Test func authenticate() async {
    let tgc = GameCenterFake()
    let dummyVC = UIViewController()

    let didAuthenticate = await tgc.authenticate(onViewController: dummyVC)
    #expect(didAuthenticate)

    let didAuthenticateAgain = await tgc.authenticate(onViewController: dummyVC)
    #expect(!didAuthenticateAgain)
  }

  @Test func reportScore() async {
    // Nothing to test. Exercising for coverage.
    let tgc = GameCenterFake()
    await tgc.reportScore(42)
  }

  @Test func showLeaderboard() {
    // Nothing to test. Exercising for coverage.
    let tgc = GameCenterFake()
    tgc.showLeaderboard()
  }
}
