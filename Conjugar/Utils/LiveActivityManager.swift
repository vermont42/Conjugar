//
//  LiveActivityManager.swift
//  Conjugar
//
//  Starts / updates / ends the quiz Live Activity, driven from Quiz.swift. The widget
//  extension only renders QuizActivityAttributes (see QuizLiveActivity); all lifecycle
//  lives here. Ported from Conjuguer.
//
//  Live Activities are unavailable in the simulator and when the user has disabled them,
//  so every entry point is a guarded no-op in those cases — safe to call from tests.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import ActivityKit
import Foundation

@MainActor
enum LiveActivityManager {
  private static var current: Activity<QuizActivityAttributes>?

  static func start(difficulty: String, totalQuestions: Int, state: QuizActivityAttributes.ContentState) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    endAll()
    let attributes = QuizActivityAttributes(difficulty: difficulty, totalQuestions: totalQuestions)
    current = try? Activity<QuizActivityAttributes>.request(
      attributes: attributes,
      content: ActivityContent(state: state, staleDate: nil)
    )
  }

  static func update(_ state: QuizActivityAttributes.ContentState) {
    guard let current else { return }
    let content = ActivityContent(state: state, staleDate: nil)
    Task { await current.update(content) }
  }

  static func end(_ state: QuizActivityAttributes.ContentState) {
    guard let activity = current else { return }
    current = nil
    let content = ActivityContent(state: state, staleDate: nil)
    Task { await activity.end(content, dismissalPolicy: .default) }
  }

  /// End any stray quiz activities (e.g. left over from a previous launch).
  static func endAll() {
    current = nil
    Task {
      for activity in Activity<QuizActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
