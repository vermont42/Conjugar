//
//  ReviewPrompterRealTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/21/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

// Swift Testing (not XCTest) — see SettingsTests for the isolated-deinit rationale.
@Suite("ReviewPrompterReal")
@MainActor
struct ReviewPrompterRealTests {
  @Test func promptableActionHappened() {
    let now = Date()
    let smallAmountOfTime: TimeInterval = 5.0
    let recentPromptDate = now.addingTimeInterval(-1.0 * smallAmountOfTime)

    var settingsDictionary1: [String: String] = [:]
    settingsDictionary1[Settings.lastReviewPromptDateKey] = "\(recentPromptDate.timeIntervalSince1970)"
    let settings1 = Settings(getterSetter: GetterSetterFake(dictionary: settingsDictionary1))
    var didRequestReview = false
    let prompter1 = ReviewPrompterReal(settings: settings1, now: { now }, requestReview: { didRequestReview = true })

    prompter1.promptableActionHappened()
    #expect(!didRequestReview)

    settings1.promptActionCount = ReviewPrompterReal.promptModulo - 1
    #expect(!didRequestReview)

    let longAgoDate = recentPromptDate.addingTimeInterval(-1.0 * ReviewPrompterReal.promptInterval)
    settings1.lastReviewPromptDate = longAgoDate
    settings1.promptActionCount = ReviewPrompterReal.promptModulo - 2
    prompter1.promptableActionHappened()
    #expect(!didRequestReview)

    settings1.promptActionCount = ReviewPrompterReal.promptModulo - 1
    prompter1.promptableActionHappened()
    #expect(didRequestReview)

    var settingsDictionary2: [String: String] = [:]
    settingsDictionary2[Settings.promptActionCountKey] = "\(ReviewPrompterReal.promptModulo - 1)"
    let settings2 = Settings(getterSetter: GetterSetterFake(dictionary: settingsDictionary2))
    let prompter2 = ReviewPrompterReal(settings: settings2, now: { longAgoDate }, requestReview: { didRequestReview = true })

    didRequestReview = false
    prompter2.promptableActionHappened()
    #expect(didRequestReview)

    didRequestReview = false
    prompter2.promptableActionHappened()
    #expect(!didRequestReview)
  }
}
