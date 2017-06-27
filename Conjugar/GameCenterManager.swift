//
//  GameCenterManager.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/26/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import GameKit

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
  static let shared = GameCenterManager()
  let localPlayer = GKLocalPlayer.localPlayer()
  var isAuthenticated = false
  var leaderboardIdentifier = ""
  
  private override init() {}
  
  func authenticate() {
    localPlayer.authenticateHandler = { viewController, error in
      if let viewController = viewController, let topController = UIApplication.topViewController() {
        topController.present(viewController, animated: true, completion: nil)
      }
      else if self.localPlayer.isAuthenticated {
        print("AUTHENTICATED displayName: \(self.localPlayer.displayName!) alias: \(self.localPlayer.alias!) playerID: \(self.localPlayer.playerID!)")
        self.isAuthenticated = true
        self.localPlayer.loadDefaultLeaderboardIdentifier { identifier, error in
          self.leaderboardIdentifier = identifier ?? "ERROR"
          print("identifier: \(self.leaderboardIdentifier)")
        }
      }
      else {
        print("DISABLING GAME CENTER")
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
        self.showLeaderboard()
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
    if let topController = UIApplication.topViewController() {
      topController.present(gcViewController, animated: true, completion: nil)
    }
  }
  
  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }
}
