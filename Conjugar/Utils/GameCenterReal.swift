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
  // re-assigned — re-assigning it while an old handler was pending is what made the
  // continuation-based version crash / hang.
  private var didInstallHandler = false

  // Loaded lazily on first score submission and cached; `nil` until then, so there
  // is no `""`/`"ERROR"` sentinel for an early submit to race against.
  private var leaderboardIdentifier: String?

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
        Current.analytics.recordGameCenterAuth()
        Current.soundPlayer.play(Sound.randomApplause, shouldDebounce: false)
      }
    }
  }

  func reportScore(_ score: Int) async {
    guard isAuthenticated else { return }

    let leaderboardID: String
    if let leaderboardIdentifier {
      leaderboardID = leaderboardIdentifier
    } else {
      do {
        let loaded = try await GKLocalPlayer.local.loadDefaultLeaderboardIdentifier()
        leaderboardIdentifier = loaded
        leaderboardID = loaded
      } catch {
        gameCenterLogger.warning("Failed to load leaderboard identifier: \(error.localizedDescription)")
        return
      }
    }

    do {
      try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID])
    } catch {
      gameCenterLogger.warning("Failed to submit score: \(error.localizedDescription)")
    }
  }

  func showLeaderboard() {
    guard isAuthenticated else { return }
    GKAccessPoint.shared.trigger(state: .leaderboards) {}
  }
}
