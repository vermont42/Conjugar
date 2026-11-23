//
//  LiveActivitiesReal.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import ActivityKit
import Foundation

final class LiveActivitiesReal: LiveActivities {
  private var current: Activity<QuizActivityAttributes>?

  func start(difficulty: String, totalQuestions: Int, state: QuizActivityAttributes.ContentState) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      return
    }
    // endAll() lists the activities to end before this request, so the new one is not among them.
    endAll()
    let attributes = QuizActivityAttributes(difficulty: difficulty, totalQuestions: totalQuestions)
    current = try? Activity<QuizActivityAttributes>.request(
      attributes: attributes,
      content: ActivityContent(state: state, staleDate: nil)
    )
  }

  func update(_ state: QuizActivityAttributes.ContentState) {
    guard let current else {
      return
    }
    let content = ActivityContent(state: state, staleDate: nil)
    Task { await current.update(content) }
  }

  func end(_ state: QuizActivityAttributes.ContentState) {
    guard let activity = current else {
      return
    }
    current = nil
    let content = ActivityContent(state: state, staleDate: nil)
    Task { await activity.end(content, dismissalPolicy: .default) }
  }

  func endAll() {
    current = nil
    // Listed now, not in the Task: the Task runs after the caller returns, by which time
    // start() has requested the quiz's activity, which the Task would otherwise end too.
    let activities = Activity<QuizActivityAttributes>.activities
    guard !activities.isEmpty else {
      return
    }
    Task {
      for activity in activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
