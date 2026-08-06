//
//  QuizActivityAttributes.swift
//  Conjugar
//
//  The Live Activity contract shared by the app (which drives the activity from
//  Quiz.swift via LiveActivityManager) and the widget (which renders the Lock Screen
//  + Dynamic Island presentations in QuizLiveActivity).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import ActivityKit
import Foundation

nonisolated struct QuizActivityAttributes: ActivityAttributes {
  /// Static for the life of the activity.
  let difficulty: String
  let totalQuestions: Int

  nonisolated struct ContentState: Codable, Hashable, Sendable {
    /// 1-based index of the question currently on screen.
    let currentQuestion: Int
    let score: Int
    let correctCount: Int
    /// Pre-formatted mm:ss elapsed time.
    let elapsedTime: String
    let isFinished: Bool
  }
}
