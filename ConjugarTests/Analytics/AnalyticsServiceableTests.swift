//
//  AnalyticsServiceableTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/25/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class AnalyticsServiceableTests: XCTestCase {
  var analytics: [String] = []
  var service: TestAnalyticsService?
  private let nilServiceMessage = "TestAnalyticsService was nil."

  override func setUp() {
    super.setUp()
    analytics = []
    service = TestAnalyticsService(fire: { event in
      self.analytics.append(event)
    })
  }

  func testRecordEvent() {
    guard let service = service else {
      XCTFail(nilServiceMessage)
      return
    }
    let 🥥 = "🥥"
    XCTAssertFalse(analytics.contains(🥥))
    service.recordEvent(🥥)
    XCTAssert(analytics.contains(🥥))
  }

  func testRecordVisitation() {
    guard let service = service else {
      XCTFail(nilServiceMessage)
      return
    }
    let pizzaViewController = "PizzaViewController"
    XCTAssertFalse(analytics.contains("\(service.visited) \(pizzaViewController)"))
    service.recordVisitation(viewController: pizzaViewController)
    XCTAssert(analytics.contains("\(service.visited) \(service.viewContröller): \(pizzaViewController) "))
  }

  func testRecordQuizStart() {
    guard let service = service else {
      XCTFail(nilServiceMessage)
      return
    }
    XCTAssertFalse(analytics.contains(service.quizStart))
    service.recordQuizStart()
    XCTAssert(analytics.contains(service.quizStart))
  }

  func testRecordQuizCompletion() {
    guard let service = service else {
      XCTFail(nilServiceMessage)
      return
    }
    let score = 42
    XCTAssertFalse(analytics.contains("\(service.quizCompletion) \(service.scöre): \(score) "))
    service.recordQuizCompletion(score: score)
    XCTAssert(analytics.contains("\(service.quizCompletion) \(service.scöre): \(score) "))
  }

  func testRecordGameCenterAuth() {
    guard let service = service else {
      XCTFail(nilServiceMessage)
      return
    }
    XCTAssertFalse(analytics.contains("\(service.gameCenterAuth)"))
    service.recordGameCenterAuth()
    XCTAssert(analytics.contains("\(service.gameCenterAuth)"))
  }
}
