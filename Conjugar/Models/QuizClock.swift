//
//  QuizClock.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Whether the quiz, its results, and the Live Activity show the time spent answering. Hidden by
/// default, since a clock turns practice into a race. The raw values are the persisted
/// `Settings.quizClock` value; keep them stable.
enum QuizClock: String, CaseIterable {
  case hide
  case show

  var localizedQuizClock: String {
    switch self {
    case .hide:
      return L.QuizClock.hide
    case .show:
      return L.QuizClock.show
    }
  }
}
