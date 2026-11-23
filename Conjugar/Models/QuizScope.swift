//
//  QuizScope.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// What a quiz asks about, how many questions it asks, and where it was begun (browse plan,
/// Phase 13). `Quiz.start(scope:)` defaults to `allVerbs`, the Quiz tab's quiz as it always was.
/// Later scopes, such as Phase 16's collections, are further constructors.
nonisolated struct QuizScope: Equatable, Sendable {
  /// Nil asks about every verb, through the curated lists in `VerbFamilies`. Otherwise the bare
  /// infinitives the verb map uses (arrepentir, not arrepentirse).
  let verbs: [String]?
  let questionCount: Int
  /// `startQuiz`, `quitQuiz`, and `completeQuiz` carry it.
  let source: AnalyticsSource

  /// The length of the Quiz tab's quiz, whatever its scope.
  static let fullLength = 30

  /// Test Me's length on a verb's page.
  static let verbPageQuestionCount = 3

  /// Only a full quiz over every verb posts to the Game Center leaderboard and shows it at the
  /// end, as Josh decided for Konjugieren on 2026-11-13: a score over a learner's own verbs, or
  /// over three questions, compares with nothing.
  var isRanked: Bool {
    verbs == nil && questionCount == QuizScope.fullLength
  }

  static let allVerbs = allVerbs(source: .tab)

  /// The full quiz over every verb, begun somewhere other than Start: a `quiz` link names its
  /// surface, or `deeplink`. It ranks like the tab's.
  static func allVerbs(source: AnalyticsSource) -> QuizScope {
    QuizScope(verbs: nil, questionCount: fullLength, source: source)
  }

  static func myVerbs(_ verbs: [String]) -> QuizScope {
    QuizScope(verbs: verbs, questionCount: fullLength, source: .myVerbs)
  }

  static func verbPage(_ verb: String) -> QuizScope {
    QuizScope(verbs: [verb], questionCount: verbPageQuestionCount, source: .verbPage)
  }
}
