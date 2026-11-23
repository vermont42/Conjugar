//
//  QuizScope.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// What a quiz asks about, how many questions it asks, and where it was begun.
/// `Quiz.start(scope:)` defaults to `allVerbs`, the Quiz tab's quiz. Collections add
/// `collection(_:title:)` (`VerbCollection+Text.swift`).
nonisolated struct QuizScope: Equatable, Sendable {
  /// Nil asks about every verb, drawn from the level's frequency band (`QuizDraw`). Otherwise
  /// the bare infinitives the verb map uses (arrepentir, not arrepentirse).
  let verbs: [String]?
  let questionCount: Int
  /// `startQuiz`, `quitQuiz`, and `completeQuiz` carry it.
  let source: AnalyticsSource
  /// What the quiz sheet shows as its title: a collection's name. Nil elsewhere, where Test Me's
  /// sheet shows its verb.
  let title: String?
  /// The collection the quiz is over, which `startQuiz` carries as `collection`.
  let collectionKey: String?

  init(verbs: [String]?, questionCount: Int, source: AnalyticsSource, title: String? = nil, collectionKey: String? = nil) {
    self.verbs = verbs
    self.questionCount = questionCount
    self.source = source
    self.title = title
    self.collectionKey = collectionKey
  }

  /// The length of the Quiz tab's quiz, whatever its scope.
  static let fullLength = 30

  /// Test Me's length on a verb's page.
  static let verbPageQuestionCount = 3

  /// Only a full quiz over every verb posts to the Game Center leaderboard and shows it at the
  /// end: a score over a learner's own verbs, or over three questions, compares with nothing.
  var isRanked: Bool {
    verbs == nil && questionCount == QuizScope.fullLength
  }

  /// Whether the quiz starts the Live Activity, which is one for the whole app and belongs to the
  /// Quiz tab's quiz. A three-question quiz in a verb page's sheet is over before one would be
  /// noticed, and a collection's quiz runs in the same sheet, beside a quiz the tab may hold, so
  /// neither starts one, though a collection's is full length.
  var startsLiveActivity: Bool {
    questionCount >= QuizScope.fullLength && collectionKey == nil
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
