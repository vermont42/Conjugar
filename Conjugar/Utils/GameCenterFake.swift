//
//  GameCenterFake.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/27/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

class GameCenterFake: GameCenter {
  private(set) var isAuthenticated: Bool

  init(isAuthenticated: Bool = false) {
    self.isAuthenticated = isAuthenticated
  }

  func authenticate() {
    isAuthenticated = true
  }

  func reportScore(_ score: Int) async {}

  func showLeaderboard() {}
}
