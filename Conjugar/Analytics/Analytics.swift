//
//  Analytics.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/24/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

// `nonisolated` throughout, like the engine: analytics is pure plumbing with no UI
// state, and AnalyticsReal deliberately does its work off the main actor. Without
// this, the module's default MainActor isolation would make the protocol — and, by
// witness inference, every conformer's methods — MainActor-isolated, which both
// contradicts AnalyticsReal's design and makes the spy unusable from a nonisolated
// test suite. MainActor call sites can call into it synchronously either way.
nonisolated enum ParameterKey: String {
  case difficulty
  case elapsedTime
  case questionNumber
  case score
  case stage
}

nonisolated enum AnalyticsName: String {
  case completeQuiz
  case completeStage
  case enterBossFight
  case gameCenterAuthSucceeded
  case quitQuiz
  case startGame
  case startQuiz
  case tapPlayGame
  case tapRateOrReview
  case tapSendTutorMessage
  case tapShowOnboarding
  case viewInfoBrowseView
  case viewInfoView
  case viewModelBrowseView
  case viewModelView
  case viewOnboardingView
  case viewQuizView
  case viewResultsView
  case viewSettingsView
  case viewTutorView
  case viewVerbBrowseView
  case viewVerbView
  case winBossFight
}

nonisolated protocol Analytics {
  func initialize(appID: String)
  func signal(name: AnalyticsName, parameters: [String: String])
}

nonisolated extension Analytics {
  func signal(name: AnalyticsName) {
    signal(name: name, parameters: [:])
  }
}
