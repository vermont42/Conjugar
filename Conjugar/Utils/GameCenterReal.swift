//
//  GameCenterReal.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/26/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import GameKit
import Observation
import UIKit
import os

private let gameCenterLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Conjugar", category: "GameCenter")

@MainActor
@Observable
final class GameCenterReal: GameCenter {
  static let shared = GameCenterReal()

  private(set) var isAuthenticated = false

  // GameKit invokes `authenticateHandler` repeatedly for the life of the process
  // (foregrounding, sign-in/out), so it is installed exactly once and never
  // re-assigned; re-assigning it while a handler is pending can crash or hang.
  private var didInstallHandler = false

  private init() {}

  func authenticate() {
    guard !didInstallHandler else { return }
    didInstallHandler = true

    GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
      guard let self else { return }

      if let error {
        gameCenterLogger.warning("Unable to authenticate Game Center: \(error.localizedDescription)")
        return
      }

      if let viewController {
        UIApplication.topViewController()?.present(viewController, animated: true)
        return
      }

      let becameAuthenticated = GKLocalPlayer.local.isAuthenticated && !self.isAuthenticated
      self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
      if becameAuthenticated {
        Current.analytics.signal(name: .gameCenterAuthSucceeded)
        Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
      }
      if GKLocalPlayer.local.isAuthenticated, GKLocalPlayer.local.gamePlayerID != self.loadedPlayerID {
        self.loadReportedAchievements()
      }
    }
  }

  /// What Game Center holds for the signed-in player, by achievement ID, once loaded. Until then,
  /// reports wait in `pendingAchievements`, so that progress reported before sign-in finished is
  /// not sent blind.
  private var reportedAchievements: [String: Double]?
  private var pendingAchievements: [Achievement: Double] = [:]
  /// The player whose achievements `reportedAchievements` holds. The handler runs again on every
  /// return to the foreground, and may run for another player, so a load happens only for a new one.
  private var loadedPlayerID: String?

  private func loadReportedAchievements() {
    let playerID = GKLocalPlayer.local.gamePlayerID
    loadedPlayerID = playerID
    reportedAchievements = nil
    GKAchievement.loadAchievements { [weak self] achievements, error in
      let failure = error?.localizedDescription
      let loaded = Dictionary((achievements ?? []).map { ($0.identifier, $0.percentComplete) }, uniquingKeysWith: max)
      Task { @MainActor in
        guard let self, self.loadedPlayerID == playerID else {
          return
        }
        if let failure {
          gameCenterLogger.warning("Unable to load achievements: \(failure)")
        }
        self.reportedAchievements = loaded
        // The record may have risen while the player was signed out.
        Current.reportAchievements()
        self.sendPendingAchievements()
      }
    }
  }

  func reportAchievementProgress(_ percentComplete: [Achievement: Double]) {
    pendingAchievements.merge(percentComplete, uniquingKeysWith: max)
    sendPendingAchievements()
  }

  /// Sends only progress that has risen. The practice record can fall, a wrong answer sending an
  /// item down the ladder, but an achievement once earned stays earned, so a fall is never sent.
  private func sendPendingAchievements() {
    guard isAuthenticated, let reported = reportedAchievements else {
      return
    }

    let risen = pendingAchievements.filter { achievement, percent in
      percent > (reported[achievement.identifier] ?? 0)
    }
    pendingAchievements = [:]
    guard !risen.isEmpty else {
      return
    }

    let achievements = risen.map { achievement, percent in
      let gkAchievement = GKAchievement(identifier: achievement.identifier)
      gkAchievement.percentComplete = percent
      gkAchievement.showsCompletionBanner = true
      return gkAchievement
    }
    let sent = Dictionary(uniqueKeysWithValues: risen.map { ($0.key.identifier, $0.value) })
    GKAchievement.report(achievements) { [weak self] error in
      let failure = error?.localizedDescription
      Task { @MainActor in
        if let failure {
          gameCenterLogger.warning("Failed to report achievements: \(failure)")
          return
        }
        self?.reportedAchievements?.merge(sent, uniquingKeysWith: max)
      }
    }
  }

  func showAchievements() {
    guard isAuthenticated else { return }
    GKAccessPoint.shared.trigger(state: .achievements) {}
  }

  func submitScore(_ score: Int, level: QuizLevel) {
    guard isAuthenticated else { return }

    let leaderboardID = level.leaderboardID
    Task {
      do {
        try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID])
      } catch {
        gameCenterLogger.warning("Failed to submit score to \(leaderboardID): \(error.localizedDescription)")
      }
    }
  }

  func showLeaderboard(level: QuizLevel) {
    guard isAuthenticated else { return }
    GKAccessPoint.shared.trigger(leaderboardID: level.leaderboardID, playerScope: .global, timeScope: .allTime) {}
  }

  func showLeaderboards() {
    guard isAuthenticated else { return }
    GKAccessPoint.shared.trigger(state: .leaderboards) {}
  }
}
