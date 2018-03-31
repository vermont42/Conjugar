//
//  GameCenterManager.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/26/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import GameKit

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
  static let shared = GameCenterManager()
  let localPlayer = GKLocalPlayer.localPlayer()
  var isAuthenticated = false
  var leaderboardIdentifier = ""
  
  private override init() {}
  
  func authenticate(completion: ((Bool) -> Void)? = nil) {
    localPlayer.authenticateHandler = { viewController, error in
      if let viewController = viewController, let topController = UIApplication.topViewController() {
        topController.present(viewController, animated: true, completion: nil)
      }
      else if self.localPlayer.isAuthenticated {
        print("AUTHENTICATED displayName: \(self.localPlayer.displayName!) alias: \(self.localPlayer.alias!) playerID: \(self.localPlayer.playerID!)")
        
        self.isAuthenticated = true
        SoundManager.play(.applause1)
        self.localPlayer.loadDefaultLeaderboardIdentifier { identifier, error in
          self.leaderboardIdentifier = identifier ?? "ERROR"
          print("identifier: \(self.leaderboardIdentifier)")
        }
        completion?(true)
      }
      else {
        SoundManager.play(.sadTrombone)
        UIAlertController.showMessage("Game Center authentication failed. This can happen if you cancel authentication or if your iPhone is not already signed into Game Center. Try launching the Settings app, tapping Game Center, signing in, and relaunching Conjugar.", title: "😰", okTitle: "Got It")
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
    if let topController = UIApplication.topViewController() {
      topController.present(gcViewController, animated: true, completion: nil)
    }
  }
  
  func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
    gameCenterViewController.dismiss(animated: true, completion: nil)
  }
}
