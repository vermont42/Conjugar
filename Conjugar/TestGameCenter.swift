//
//  TestGameCenter.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/27/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation

class TestGameCenter: GameCenterable {
  var isAuthenticated: Bool

  init(isAuthenticated: Bool = false) {
    self.isAuthenticated = isAuthenticated
  }

  func authenticate(analyticsService: AnalyticsServiceable?, completion: ((Bool) -> Void)?) {
    if !isAuthenticated {
      isAuthenticated = true
      completion?(true)
    } else {
      completion?(false)
    }
  }

  func reportScore(_ score: Int) {
    print("Pretending to report score \(score).")
  }

  func showLeaderboard() {
    print("Pretending to show leaderboard.")
  }
}
