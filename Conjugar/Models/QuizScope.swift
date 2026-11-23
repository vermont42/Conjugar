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

  /// A round's length. The Quiz tab's quiz, a My Verbs quiz, and a collection's ask one round,
  /// and the results offer another (`continues`).
  static let roundLength = 10

  /// Test Me's length on a verb's page.
  static let verbPageQuestionCount = 3

  /// Only a quiz over every verb ranks: a score over a learner's own verbs, or over three
  /// questions, compares with nothing. Of a ranked session, only the first round's score counts
  /// (`Quiz.firstRoundScore`).
  var isRanked: Bool {
    verbs == nil && questionCount == QuizScope.roundLength
  }

  /// Whether the results offer Ten More, which continues the session with another round. Test
  /// Me's three questions are a check on one verb, not a session to grow.
  var continues: Bool {
    questionCount >= QuizScope.roundLength
  }

  /// Whether the quiz starts the Live Activity, which is one for the whole app and belongs to the
  /// Quiz tab's quiz. A three-question quiz in a verb page's sheet is over before one would be
  /// noticed, and a collection's quiz runs in the same sheet, beside a quiz the tab may hold, so
  /// neither starts one, though a collection's is a full round.
  var startsLiveActivity: Bool {
    questionCount >= QuizScope.roundLength && collectionKey == nil
  }

  static let allVerbs = allVerbs(source: .tab)

  /// The quiz over every verb, begun somewhere other than Start: a `quiz` link names its
  /// surface, or `deeplink`. It ranks like the tab's.
  static func allVerbs(source: AnalyticsSource) -> QuizScope {
    QuizScope(verbs: nil, questionCount: roundLength, source: source)
  }

  static func myVerbs(_ verbs: [String]) -> QuizScope {
    QuizScope(verbs: verbs, questionCount: roundLength, source: .myVerbs)
  }

  static func verbPage(_ verb: String) -> QuizScope {
    QuizScope(verbs: [verb], questionCount: verbPageQuestionCount, source: .verbPage)
  }
}
