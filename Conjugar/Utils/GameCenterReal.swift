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
    }
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
