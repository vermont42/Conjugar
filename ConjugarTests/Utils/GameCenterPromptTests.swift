//
//  GameCenterPromptTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Pins the Game Center opt-in gating: a fresh install is asked, a user who said No is
//  never prompted or authenticated, and an inverted guard would fail these cases. The
//  suite is nonisolated (the decision is pure `nonisolated` logic), so it runs in parallel.
//

import Testing
@testable import Conjugar

@Suite("GameCenterPrompt")
struct GameCenterPromptTests {
  @Test func alreadyAuthenticatedDoesNothing() {
    #expect(GameCenterPrompt.decision(isAuthenticated: true, userRejected: false, didShowDialog: false) == .doNothing)
    #expect(GameCenterPrompt.decision(isAuthenticated: true, userRejected: false, didShowDialog: true) == .doNothing)
  }

  @Test func rejectedUserIsNeverTouched() {
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: true, didShowDialog: false) == .doNothing)
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: true, didShowDialog: true) == .doNothing)
  }

  @Test func freshInstallShowsDialog() {
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: false, didShowDialog: false) == .showDialog)
  }

  @Test func priorOptInAuthenticatesSilently() {
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: false, didShowDialog: true) == .authenticate)
  }
}
