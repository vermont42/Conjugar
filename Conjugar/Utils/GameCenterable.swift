//
//  GameCenterable.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/26/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

protocol GameCenterable {
  var isAuthenticated: Bool { get set }
  func authenticate(onViewController: UIViewController) async -> Bool
  func reportScore(_ score: Int) async
  func showLeaderboard()
}
