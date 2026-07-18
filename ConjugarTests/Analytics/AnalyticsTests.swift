//
//  AnalyticsTests.swift
//  ConjugarTests
//
//  Replaces AnalyticsServiceTests, which exercised the AWS-Pinpoint-shaped
//  AnalyticsService removed in the July 2026 TelemetryDeck migration. Those tests
//  asserted on a flattened printed string; the spy now records structured signals,
//  so these assert on names and parameters directly. Swift Testing (the suite is
//  nonisolated — Analytics and its spy are nonisolated).
//

import Testing
@testable import Conjugar

@Suite("Analytics")
struct AnalyticsTests {
  @Test func spyRecordsSignalNameWithEmptyParametersByDefault() {
    let spy = AnalyticsSpy()
    spy.signal(name: .startQuiz)
    #expect(spy.signalNames == [.startQuiz])
    #expect(spy.signalParameters == [[:]])
  }

  @Test func spyRecordsParameters() {
    let spy = AnalyticsSpy()
    let parameters = [
      ParameterKey.difficulty.rawValue: "moderate",
      ParameterKey.score.rawValue: "42"
    ]
    spy.signal(name: .completeQuiz, parameters: parameters)
    #expect(spy.signalNames == [.completeQuiz])
    #expect(spy.signalParameters == [parameters])
  }

  @Test func spyPreservesSignalOrder() {
    let spy = AnalyticsSpy()
    spy.signal(name: .startGame)
    spy.signal(name: .enterBossFight)
    spy.signal(name: .winBossFight)
    #expect(spy.signalNames == [.startGame, .enterBossFight, .winBossFight])
  }

  // The dashboard groups by raw value, so a renamed case would silently orphan its
  // history. These pin the wire names of the signals carrying parameters.
  @Test(arguments: [
    (AnalyticsName.completeQuiz, "completeQuiz"),
    (AnalyticsName.quitQuiz, "quitQuiz"),
    (AnalyticsName.completeStage, "completeStage")
  ])
  func analyticsNameRawValuesAreStable(name: AnalyticsName, expected: String) {
    #expect(name.rawValue == expected)
  }

  @Test(arguments: [
    (ParameterKey.difficulty, "difficulty"),
    (ParameterKey.elapsedTime, "elapsedTime"),
    (ParameterKey.questionNumber, "questionNumber"),
    (ParameterKey.score, "score"),
    (ParameterKey.stage, "stage")
  ])
  func parameterKeyRawValuesAreStable(key: ParameterKey, expected: String) {
    #expect(key.rawValue == expected)
  }

  // AnalyticsReal drops every signal when handed an empty app ID rather than
  // crashing, so a clone without Secrets.xcconfig still runs.
  @Test func realIgnoresEmptyAppID() {
    let real = AnalyticsReal()
    real.initialize(appID: "")
    real.signal(name: .startQuiz)
  }
}
