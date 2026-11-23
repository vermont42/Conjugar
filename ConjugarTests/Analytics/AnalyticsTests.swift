//
//  AnalyticsTests.swift
//  ConjugarTests
//
//  The spy records structured signals, so these assert on names and parameters
//  directly. The suite is nonisolated, as Analytics and its spy are.
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
      ParameterKey.level.rawValue: "intermediate",
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
    (AnalyticsName.abandonQuiz, "abandonQuiz"),
    (AnalyticsName.completeQuiz, "completeQuiz"),
    (AnalyticsName.quitQuiz, "quitQuiz"),
    (AnalyticsName.completeStage, "completeStage"),
    (AnalyticsName.tapViewLeaderboard, "tapViewLeaderboard")
  ])
  func analyticsNameRawValuesAreStable(name: AnalyticsName, expected: String) {
    #expect(name.rawValue == expected)
  }

  @Test(arguments: [
    (ParameterKey.duration, "duration"),
    (ParameterKey.level, "level"),
    (ParameterKey.questionCount, "questionCount"),
    (ParameterKey.questionNumber, "questionNumber"),
    (ParameterKey.score, "score"),
    (ParameterKey.stage, "stage")
  ])
  func parameterKeyRawValuesAreStable(key: ParameterKey, expected: String) {
    #expect(key.rawValue == expected)
  }

  @Test(arguments: [
    (0.0, "0-3s"), (2.9, "0-3s"), (3.0, "3-15s"), (14.9, "3-15s"), (15.0, "15-40s"),
    (39.9, "15-40s"), (40.0, "40s-2m"), (119.9, "40s-2m"), (120.0, "2m+"), (3600.0, "2m+")
  ])
  func quizDurationBands(seconds: Double, band: String) {
    #expect(AnalyticsBand.quizDuration(seconds) == band)
  }

  // AnalyticsReal drops every signal when handed an empty app ID rather than
  // crashing, so a clone without Secrets.xcconfig still runs.
  @Test func realIgnoresEmptyAppID() {
    let real = AnalyticsReal()
    real.initialize(appID: "")
    real.signal(name: .startQuiz)
  }
}
