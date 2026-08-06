//
//  GameCenterPromptTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  Pins the corrected Game Center opt-in gating. The
//  inline guard this replaced was inverted for years — it authenticated *only*
//  users who had said No, and never prompted a fresh install — so these cases are
//  the guard-rail against a silent re-inversion. The suite is nonisolated (the
//  decision is pure `nonisolated` logic), so it runs in parallel.
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
    // The years-old inverted guard authenticated ONLY rejecters; the corrected
    // logic must never prompt or authenticate a user who opted out.
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: true, didShowDialog: false) == .doNothing)
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: true, didShowDialog: true) == .doNothing)
  }

  @Test func freshInstallShowsDialog() {
    // The exact case the old guard could never reach: a brand-new user is asked.
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: false, didShowDialog: false) == .showDialog)
  }

  @Test func priorOptInAuthenticatesSilently() {
    #expect(GameCenterPrompt.decision(isAuthenticated: false, userRejected: false, didShowDialog: true) == .authenticate)
  }
}
