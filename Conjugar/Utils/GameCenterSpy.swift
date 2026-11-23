//
//  GameCenterSpy.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Records each score submitted and each leaderboard shown, for tests of which sessions rank.
final class GameCenterSpy: GameCenter {
  struct Submission: Equatable {
    let score: Int
    let level: QuizLevel
  }

  private(set) var submissions: [Submission] = []
  private(set) var shownLeaderboardLevels: [QuizLevel] = []
  private(set) var leaderboardListShowCount = 0

  var isAuthenticated: Bool { true }

  func authenticate() {}

  func submitScore(_ score: Int, level: QuizLevel) {
    submissions.append(Submission(score: score, level: level))
  }

  func showLeaderboard(level: QuizLevel) {
    shownLeaderboardLevels.append(level)
  }

  func showLeaderboards() {
    leaderboardListShowCount += 1
  }
}
