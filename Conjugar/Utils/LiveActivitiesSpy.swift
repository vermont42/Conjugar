//
//  LiveActivitiesSpy.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Records the quiz Live Activity's lifecycle under unit tests, where ActivityKit would grant
/// real activities until it refused them. `Current` is shared with suites running in parallel,
/// so a test compares the counts before and after its own synchronous steps.
final class LiveActivitiesSpy: LiveActivities {
  private(set) var startCount = 0
  private(set) var updateCount = 0
  private(set) var endCount = 0
  private(set) var endAllCount = 0
  private(set) var lastLevel: String?
  private(set) var lastState: QuizActivityAttributes.ContentState?

  func start(level: String, state: QuizActivityAttributes.ContentState) {
    startCount += 1
    lastLevel = level
    lastState = state
  }

  func update(_ state: QuizActivityAttributes.ContentState) {
    updateCount += 1
    lastState = state
  }

  func end(_ state: QuizActivityAttributes.ContentState) {
    endCount += 1
  }

  func endAll() {
    endAllCount += 1
  }
}
