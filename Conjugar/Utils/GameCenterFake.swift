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

  // Straightened per item 19: authenticating is idempotent — it authenticates the
  // player. The old fake's "return false when already authenticated" semantics were
  // a surprising artifact of the removed `-> Bool` return value.
  func authenticate() {
    isAuthenticated = true
  }

  func reportScore(_ score: Int) async {}

  func showLeaderboard() {}
}
