//
//  TestGameCenter.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/27/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

class TestGameCenter: GameCenterable {
  var isAuthenticated: Bool

  init(isAuthenticated: Bool = false) {
    self.isAuthenticated = isAuthenticated
  }

  func authenticate(onViewController: UIViewController) async -> Bool {
    if !isAuthenticated {
      isAuthenticated = true
      return true
    } else {
      return false
    }
  }

  func reportScore(_ score: Int) async {
    print("Pretending to report score \(score).")
  }

  func showLeaderboard() {
    print("Pretending to show leaderboard.")
  }
}
