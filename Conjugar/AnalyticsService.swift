//
//  AnalyticsService.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/24/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation

protocol AnalyticsService {
  func recordEvent(_ eventName: String, parameters: [String: String]?, metrics: [String: Double]?)
  func recordEvent(_ eventName: String)
  func recordVisitation(viewController: String)
  func recordQuizStart()
  func recordQuizCompletion(score: Int)
  func recordGameCenterAuth()
}

extension AnalyticsService {
  func recordEvent(_ eventName: String) {
    recordEvent(eventName, parameters: nil, metrics: nil)
  }

  func recordVisitation(viewController: String) {
    let visited = "visited"
    recordEvent(visited, parameters: ["viewController": "\(viewController)"], metrics: nil)
  }

  func recordQuizStart() {
    let quizStart = "quizStart"
    recordEvent(quizStart)
  }

  func recordQuizCompletion(score: Int) {
    let quizCompletion = "quizCompletion"
    recordEvent(quizCompletion, parameters: ["score": "\(score)"], metrics: nil)
  }

  func recordGameCenterAuth() {
    let gameCenterAuth = "gameCenterAuth"
    recordEvent(gameCenterAuth)
  }
}
