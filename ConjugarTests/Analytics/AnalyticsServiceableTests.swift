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
  private let nilServiceMessage = "TestAnalyticsService was nil."
  private let nilAnalyticsMessage = "analytics array was nil."

  func testRecordEvent() {
    var analytics: [String] = []
    let service = TestAnalyticsService(fire: { event in
      analytics.append(event)
    })

    let 🥥 = "🥥"
    XCTAssertFalse(analytics.contains(🥥))
    service.recordEvent(🥥)
    XCTAssert(analytics.contains(🥥))
  }

  func testRecordVisitation() {
    var analytics: [String] = []
    let service = TestAnalyticsService(fire: { event in
      analytics.append(event)
    })

    let pizzaViewController = "PizzaViewController"
    XCTAssertFalse(analytics.contains("\(service.visited) \(pizzaViewController)"))
    service.recordVisitation(viewController: pizzaViewController)
    XCTAssert(analytics.contains("\(service.visited) \(service.viewContröller): \(pizzaViewController) "))
  }

  func testRecordQuizStart() {
    var analytics: [String] = []
    let service = TestAnalyticsService(fire: { event in
      analytics.append(event)
    })

    XCTAssertFalse(analytics.contains(service.quizStart))
    service.recordQuizStart()
    XCTAssert(analytics.contains(service.quizStart))
  }

  func testRecordQuizCompletion() {
    var analytics: [String] = []
    let service = TestAnalyticsService(fire: { event in
      analytics.append(event)
    })

    let score = 42
    XCTAssertFalse(analytics.contains("\(service.quizCompletion) \(service.scöre): \(score) "))
    service.recordQuizCompletion(score: score)
    XCTAssert(analytics.contains("\(service.quizCompletion) \(service.scöre): \(score) "))
  }

  func testRecordGameCenterAuth() {
    var analytics: [String] = []
    let service = TestAnalyticsService(fire: { event in
      analytics.append(event)
    })

    XCTAssertFalse(analytics.contains("\(service.gameCenterAuth)"))
    service.recordGameCenterAuth()
    XCTAssert(analytics.contains("\(service.gameCenterAuth)"))
  }
}
