//
//  GameCenterSpy.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Records each score submitted, each leaderboard shown, and each achievement report, for tests of
/// which sessions rank and what reaches Game Center.
final class GameCenterSpy: GameCenter {
  struct Submission: Equatable {
    let score: Int
    let level: QuizLevel
  }

  private(set) var submissions: [Submission] = []
  private(set) var shownLeaderboardLevels: [QuizLevel] = []
  private(set) var leaderboardListShowCount = 0
  private(set) var achievementReports: [[Achievement: Double]] = []
  private(set) var achievementsShowCount = 0

  let isAuthenticated: Bool

  init(isAuthenticated: Bool = true) {
    self.isAuthenticated = isAuthenticated
  }

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

  func reportAchievementProgress(_ percentComplete: [Achievement: Double]) {
    achievementReports.append(percentComplete)
  }

  func showAchievements() {
    achievementsShowCount += 1
  }
}
