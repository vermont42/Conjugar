//
//  AnswerQuizIntent.swift
//  ConjugarWidget
//
//  The interactive App Intent behind the Quiz widget's answer buttons. Records the
//  result in the shared defaults suite (keyed to the current question) and reloads the
//  Quiz widget's timeline so it flips to the answered state. Ported from Conjuguer.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import WidgetKit

struct AnswerQuizIntent: AppIntent {
  // Inline literals, not WidgetL — AppIntent metadata is extracted at compile time.
  static let title = LocalizedStringResource("Widget.intentAnswerQuiz", defaultValue: "Answer Quiz")

  @Parameter(title: "Selected Answer") var selectedAnswer: String
  @Parameter(title: "Question ID") var questionID: String

  init() {}

  init(selectedAnswer: String, questionID: String) {
    self.selectedAnswer = selectedAnswer
    self.questionID = questionID
  }

  func perform() async throws -> some IntentResult {
    guard
      let defaults = WidgetConstants.sharedDefaults,
      let snapshot = SnapshotReader.read()
    else {
      return .result()
    }

    let isCorrect = selectedAnswer == snapshot.quizQuestion.correctAnswer
    defaults.set(true, forKey: WidgetConstants.quizAnsweredKey)
    defaults.set(isCorrect, forKey: WidgetConstants.quizCorrectKey)
    defaults.set(questionID, forKey: WidgetConstants.quizQuestionIDKey)

    WidgetCenter.shared.reloadTimelines(ofKind: "QuizWidget")
    return .result()
  }
}
