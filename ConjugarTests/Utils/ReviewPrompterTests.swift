//
//  ReviewPrompterTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/21/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest
import Foundation
@testable import Conjugar

class ReviewPrompterTests: XCTestCase {
    func testPromptableActionHappened() {
      var customDefaults: [String: Any] = [:]
      customDefaults[Settings.promptActionCountKey] = ReviewPrompter.promptModulo - 1
      let settings = Settings(customDefaults: customDefaults)
      let now = Date()
      let smallAmountOfTime: TimeInterval = -5.0
      let recentPromptDate = now.addingTimeInterval(smallAmountOfTime)
      settings.lastReviewPromptDate = recentPromptDate
      var didRequestReview = false
      let prompter = ReviewPrompter(settings: settings, now: now, requestReview: { didRequestReview = true })
      prompter.promptableActionHappened()
      XCTAssertFalse(didRequestReview)
      let longAgoPromptDate = recentPromptDate.addingTimeInterval(-1.0 * ReviewPrompter.promptInterval)
      settings.lastReviewPromptDate = longAgoPromptDate
      settings.promptActionCount = ReviewPrompter.promptModulo - 2
      prompter.promptableActionHappened()
      XCTAssert(!didRequestReview)
      settings.promptActionCount = ReviewPrompter.promptModulo - 1
      prompter.promptableActionHappened()
      XCTAssert(didRequestReview)
  }
}
