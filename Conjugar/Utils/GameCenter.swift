//
//  GameCenter.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/26/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

// Authentication is fire-and-forget — GameKit's `authenticateHandler` presents its
// own login sheet against the live window, so no caller has to hand in a view
// controller, and `isAuthenticated` is an observable published state rather than the
// return value of a one-shot call.
protocol GameCenter {
  var isAuthenticated: Bool { get }
  func authenticate()
  func reportScore(_ score: Int) async
  func showLeaderboard()
}

/// The decision the Quiz screen makes on appear about the Game Center opt-in.
///
/// Extracted as a pure, `nonisolated` function so the gating logic is
/// unit-testable without a live GameKit session. The old inline guard was
/// inverted for years — it authenticated *only* users who had said No — so
/// pinning the corrected truth table in a test (see `GameCenterPromptTests`) is
/// the guard-rail that keeps it from silently re-inverting.
nonisolated enum GameCenterPrompt: Equatable {
  /// Already authenticated, or the user opted out — leave them alone.
  case doNothing
  /// First run: ask before touching GameKit.
  case showDialog
  /// The user already opted in on a previous run — authenticate silently.
  case authenticate

  static func decision(isAuthenticated: Bool, userRejected: Bool, didShowDialog: Bool) -> GameCenterPrompt {
    guard !isAuthenticated, !userRejected else { return .doNothing }
    return didShowDialog ? .authenticate : .showDialog
  }
}
