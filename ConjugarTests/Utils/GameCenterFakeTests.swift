//
//  GameCenterFakeTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// Swift Testing (not XCTest) — see SettingsTests for the isolated-deinit rationale.
@Suite("GameCenterFake")
@MainActor
struct GameCenterFakeTests {
  @Test func authenticateIsIdempotent() {
    let gameCenter = GameCenterFake()
    #expect(!gameCenter.isAuthenticated)

    gameCenter.authenticate()
    #expect(gameCenter.isAuthenticated)

    // Re-authenticating keeps the player authenticated instead of surprisingly
    // reporting failure.
    gameCenter.authenticate()
    #expect(gameCenter.isAuthenticated)
  }

  @Test func startsAuthenticatedWhenSeeded() {
    let gameCenter = GameCenterFake(isAuthenticated: true)
    #expect(gameCenter.isAuthenticated)
  }

  @Test func reportScore() async {
    // Nothing to assert. Exercising for coverage.
    let gameCenter = GameCenterFake()
    await gameCenter.reportScore(42)
  }

  @Test func showLeaderboard() {
    // Nothing to assert. Exercising for coverage.
    let gameCenter = GameCenterFake()
    gameCenter.showLeaderboard()
  }
}
