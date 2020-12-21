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

  func authenticate(onViewController: UIViewController, completion: ((Bool) -> Void)? = nil) {
    self.onViewController = onViewController

    localPlayer.authenticateHandler = { viewController, error in
      if let viewController = viewController {
        onViewController.present(viewController, animated: true, completion: nil)
      } else if self.localPlayer.isAuthenticated {
        //print("AUTHENTICATED displayName: \(self.localPlayer.displayName) alias: \(self.localPlayer.alias) playerID: \(self.localPlayer.playerID)")
        Current.analytics.recordGameCenterAuth()
        self.isAuthenticated = true
        SoundPlayer.playRandomApplause()
        self.localPlayer.loadDefaultLeaderboardIdentifier { identifier, _ in
          self.leaderboardIdentifier = identifier ?? "ERROR"
          //print("identifier: \(self.leaderboardIdentifier)")
        }
        completion?(true)
      } else {
        SoundPlayer.play(.sadTrombone)
        UIAlertController.showMessage(Localizations.gameCenterFailure, title: "😰", okTitle: Localizations.gotIt, onViewController: onViewController)
        self.isAuthenticated = false
        completion?(false)
      }
    }
  }

  func reportScore(_ score: Int) {
    if !isAuthenticated {
      return
    }
    let gkScore = GKScore(leaderboardIdentifier: leaderboardIdentifier)
    gkScore.value = Int64(score)
    GKScore.report([gkScore]) { error in
      if error == nil {
        let delay: TimeInterval = 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
          self.showLeaderboard()
        })
      }
    }
  }

  func showLeaderboard() {
    if !isAuthenticated {
      return
    }
    let gcViewController = GKGameCenterViewController()
    gcViewController.gameCenterDelegate = self
    gcViewController.viewState = .leaderboards
    gcViewController.leaderboardIdentifier = leaderboardIdentifier
    onViewController?.present(gcViewController, animated: true, completion: nil)
  }

  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }
}
