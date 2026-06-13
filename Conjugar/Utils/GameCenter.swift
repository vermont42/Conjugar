//
//  GameCenter.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/26/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import GameKit

class GameCenter: NSObject, GameCenterable, GKGameCenterControllerDelegate {
  static let shared = GameCenter()
  var isAuthenticated = false
  private let localPlayer = GKLocalPlayer.local
  private var leaderboardIdentifier = ""
  private var onViewController: UIViewController?

  private override init() {}

  func authenticate(onViewController: UIViewController) async -> Bool {
    self.onViewController = onViewController

    return await withCheckedContinuation { continuation in
      localPlayer.authenticateHandler = { [weak self] viewController, _ in
        guard let self = self else {
          continuation.resume(returning: false)
          return
        }

        if let viewController {
          Task { @MainActor in
            onViewController.present(viewController, animated: true)
          }
        } else if self.localPlayer.isAuthenticated {
          Current.analytics.recordGameCenterAuth()
          self.isAuthenticated = true
          SoundPlayer.playRandomApplause()

          Task {
            do {
              self.leaderboardIdentifier = try await self.localPlayer.loadDefaultLeaderboardIdentifier()
            } catch {
              self.leaderboardIdentifier = "ERROR"
            }
          }
          continuation.resume(returning: true)
        } else {
          SoundPlayer.play(.sadTrombone)
          Task { @MainActor in
            UIAlertController.showMessage(
              Localizations.gameCenterFailure,
              title: "😰", okTitle: Localizations.gotIt,
              onViewController: onViewController
            )
          }
          self.isAuthenticated = false
          continuation.resume(returning: false)
        }
      }
    }
  }

  func reportScore(_ score: Int) async {
    guard isAuthenticated else {
      return
    }

    do {
      try await GKLeaderboard.submitScore(score, context: 0, player: localPlayer, leaderboardIDs: [leaderboardIdentifier])
    } catch {}
  }

  func showLeaderboard() {
    guard isAuthenticated else {
      return
    }
    let gcViewController = GKGameCenterViewController(leaderboardID: leaderboardIdentifier, playerScope: .global, timeScope: .allTime)
    gcViewController.gameCenterDelegate = self
    onViewController?.present(gcViewController, animated: true, completion: nil)
  }

  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }
}
