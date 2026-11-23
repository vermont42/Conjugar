//
//  QuizActivityAttributes.swift
//  Conjugar
//
//  The Live Activity contract shared by the app (which drives the activity from
//  Quiz.swift via LiveActivitiesReal) and the widget (which renders the Lock Screen
//  + Dynamic Island presentations in QuizLiveActivity).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import ActivityKit
import Foundation

nonisolated struct QuizActivityAttributes: ActivityAttributes {
  /// Static for the life of the activity, which is one round. `level` is a `QuizLevel`'s raw
  /// value.
  let level: String

  nonisolated struct ContentState: Codable, Hashable, Sendable {
    /// 1-based index of the question currently on screen, counting the session's earlier rounds.
    let currentQuestion: Int
    /// The session's questions so far, re-asks included, which a wrong answer grows.
    let totalQuestions: Int
    let score: Int
    let correctCount: Int
    /// Pre-formatted m:ss elapsed time, or nil while the quiz clock is hidden.
    let elapsedTime: String?
    let isFinished: Bool
  }
}
