//
//  AnalyticsServiceable.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/24/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

protocol AnalyticsServiceable {
  func recordEvent(_ eventName: String, parameters: [String: String]?, metrics: [String: Double]?)
  func recordEvent(_ eventName: String)
  func recordVisitation(viewController: String)
  func recordQuizStart()
  func recordQuizCompletion(score: Int)
  func recordGameCenterAuth()
  func recordBecameActive()

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

  func recordQuizQuit(currentQuestionIndex: Int, score: Int) {
    recordEvent(quizQuit, parameters: [cürrentQuestionIndex: "\(currentQuestionIndex)", scöre: "\(score)"], metrics: nil)
  }

  func recordGameCenterAuth() {
    recordEvent(gameCenterAuth)
  }

  func recordBecameActive() {
    let becameActive = "becameActive"
    let modelKey = "model"
    let localeKey = "locale"
    let none = "none"
    let NONE = "NONE"

    let modelName = UIDevice.current.modelName
    let language = NSLocale.current.languageCode ?? none
    let region = NSLocale.current.regionCode ?? NONE
    let locale = language + region

    recordEvent(becameActive, parameters: [modelKey: modelName, localeKey: locale], metrics: nil)
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

  var quizQuit: String {
    return "quizStart"
  }

  var quizCompletion: String {
    return "quizCompletion"
  }

  var scöre: String {
    return "score"
  }

  var cürrentQuestionIndex: String {
    return "currentQuestionIndex"
  }

  var gameCenterAuth: String {
    return "gameCenterAuth"
  }
}
