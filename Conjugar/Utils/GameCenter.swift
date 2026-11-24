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
  /// Posts a ranked session's score to its level's leaderboard.
  func submitScore(_ score: Int, level: QuizLevel)
  func showLeaderboard(level: QuizLevel)
  /// Game Center's list of the app's leaderboards, one a level.
  func showLeaderboards()
  /// Each achievement's progress, 0 to 100, as the practice record now stands.
  func reportAchievementProgress(_ percentComplete: [Achievement: Double])
  func showAchievements()
}

extension QuizLevel {
  // App Store Connect makes a leaderboard's ID permanent, so these must match
  // docs/game_center_setup.md and never change, even if a level is renamed.
  nonisolated var leaderboardID: String {
    switch self {
    case .beginner:
      return "conjugar.level.beginner"
    case .elementary:
      return "conjugar.level.elementary"
    case .intermediate:
      return "conjugar.level.intermediate"
    case .advanced:
      return "conjugar.level.advanced"
    }
  }
}

/// The decision the Quiz screen makes on appear about the Game Center opt-in.
///
/// Extracted as a pure, `nonisolated` function so the gating logic is
/// unit-testable without a live GameKit session. `GameCenterPromptTests` pins the
/// truth table, so an inverted guard (one that authenticates only users who said No)
/// cannot slip in silently.
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
