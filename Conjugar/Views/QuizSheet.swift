//
//  QuizSheet.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A quiz over a scope in a sheet, with a `Quiz` of its own: Test Me on a verb's page, and a
/// collection's Quiz button. The learner closes it onto the page it came from, and a quiz in
/// progress in the Quiz tab is a separate quiz and carries on. While a question waits, the sheet
/// closes only through Quit, so every quiz started here ends with `quitQuiz` or `completeQuiz`. It
/// starts no Live Activity (`QuizScope.startsLiveActivity`) and posts no score
/// (`QuizScope.isRanked`).
struct QuizSheet: View {
  let scope: QuizScope
  @State private var quiz = Quiz(
    settings: Current.settings,
    gameCenter: Current.gameCenter,
    shouldShuffle: Current.quiz.shouldShuffle
  )

  var body: some View {
    QuizView(quiz: quiz, sheetScope: scope)
      .interactiveDismissDisabled(quiz.quizState == .inProgress)
  }
}
