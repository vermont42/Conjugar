//
//  ReviewPrompterTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/21/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ReviewPrompterTests: XCTestCase {
    func testPromptableActionHappened() {
      let now = Date()
      let smallAmountOfTime: TimeInterval = 5.0
      let recentPromptDate = now.addingTimeInterval(-1.0 * smallAmountOfTime)

      let formatter = DateFormatter()
      let format = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
      formatter.dateFormat = format

      var settingsDictionary1: [String: String] = [:]
      settingsDictionary1[Settings.lastReviewPromptDateKey] = formatter.string(from: recentPromptDate)
      let settings1 = Settings(getterSetter: DictionaryGetterSetter(dictionary: settingsDictionary1))
      var didRequestReview = false
      let prompter1 = ReviewPrompter(settings: settings1, now: now, requestReview: { didRequestReview = true })

      prompter1.promptableActionHappened()
      XCTAssertFalse(didRequestReview)

      settings1.promptActionCount = ReviewPrompter.promptModulo - 1
      XCTAssertFalse(didRequestReview)

      let longAgoDate = recentPromptDate.addingTimeInterval(-1.0 * ReviewPrompter.promptInterval)
      settings1.lastReviewPromptDate = longAgoDate
      settings1.promptActionCount = ReviewPrompter.promptModulo - 2
      prompter1.promptableActionHappened()
      XCTAssertFalse(didRequestReview)

      settings1.promptActionCount = ReviewPrompter.promptModulo - 1
      prompter1.promptableActionHappened()
      XCTAssert(didRequestReview)

      var settingsDictionary2: [String: String] = [:]
      settingsDictionary2[Settings.promptActionCountKey] = "\(ReviewPrompter.promptModulo - 1)"
      let settings2 = Settings(getterSetter: DictionaryGetterSetter(dictionary: settingsDictionary2))
      let prompter2 = ReviewPrompter(settings: settings2, now: longAgoDate, requestReview: { didRequestReview = true })

      didRequestReview = false
      prompter2.promptableActionHappened()
      XCTAssert(didRequestReview)

      didRequestReview = false
      prompter2.promptableActionHappened()
      XCTAssertFalse(didRequestReview)
  }
}
