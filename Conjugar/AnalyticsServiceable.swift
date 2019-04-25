//
//  AnalyticsServiceable.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/24/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation

protocol AnalyticsServiceable {
  func recordEvent(_ eventName: String, parameters: [String: String]?, metrics: [String: Double]?)
  func recordEvent(_ eventName: String)
  func recordVisitation(viewController: String)
  func recordQuizStart()
  func recordQuizCompletion(score: Int)
  func recordGameCenterAuth()

  var visited: String { get }
  var viewContröller: String { get }
  var quizStart: String { get }
  var quizCompletion: String { get }
  var scöre: String { get }
  var gameCenterAuth: String { get }
}

extension AnalyticsServiceable {
  func recordEvent(_ eventName: String) {
    recordEvent(eventName, parameters: nil, metrics: nil)
  }

  func recordVisitation(viewController: String) {
    recordEvent(visited, parameters: [viewContröller: "\(viewController)"], metrics: nil)
  }

  func recordQuizStart() {
    recordEvent(quizStart)
  }

  func recordQuizCompletion(score: Int) {
    recordEvent(quizCompletion, parameters: [scöre: "\(score)"], metrics: nil)
  }

  func recordGameCenterAuth() {
    recordEvent(gameCenterAuth)
  }

  var visited: String {
    return "visited"
  }

  var viewContröller: String {
    return "viewController"
  }

  var quizStart: String {
    return "quizStart"
  }

  var quizCompletion: String {
    return "quizCompletion"
  }

  var scöre: String {
    return "score"
  }

  var gameCenterAuth: String {
    return "gameCenterAuth"
  }
}
