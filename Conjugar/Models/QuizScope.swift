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
  /// The learner's own choice of tenses and verbs, which the Quiz tab's Custom segment starts.
  /// A custom quiz over a band or every verb has nil `verbs` and draws as the default quiz does,
  /// from the chosen band.
  let custom: CustomQuiz?
  /// A practice set's level, so that everyone who opens the set is asked the same tenses and
  /// verbs. Nil asks at the learner's own level.
  let level: QuizLevel?
  /// A shared practice set, whose quiz runs in a sheet over whatever tab is open.
  let isPracticeSet: Bool
  /// Review or Practice My Mistakes, whose questions come from the practice record.
  let recordSession: QuizRecordSession?

  init(
    verbs: [String]?,
    questionCount: Int,
    source: AnalyticsSource,
    title: String? = nil,
    collectionKey: String? = nil,
    custom: CustomQuiz? = nil,
    level: QuizLevel? = nil,
    isPracticeSet: Bool = false,
    recordSession: QuizRecordSession? = nil
  ) {
    self.verbs = verbs
    self.questionCount = questionCount
    self.source = source
    self.title = title
    self.collectionKey = collectionKey
    self.custom = custom
    self.level = level
    self.isPracticeSet = isPracticeSet
    self.recordSession = recordSession
  }

  /// A round's length. The Quiz tab's quiz, a My Verbs quiz, and a collection's ask one round,
  /// and the results offer another (`continues`).
  static let roundLength = 10

  /// Test Me's length on a verb's page.
  static let verbPageQuestionCount = 3

  /// Only the default quiz over every verb ranks: a score over a learner's own verbs or tenses,
  /// over what the practice record holds, or over three questions, compares with nothing. Of a
  /// ranked session, only the first round's score counts (`Quiz.firstRoundScore`).
  var isRanked: Bool {
    verbs == nil && custom == nil && recordSession == nil && questionCount == QuizScope.roundLength
  }

  /// Whether `completeQuiz`, `quitQuiz`, and `abandonQuiz` say how many questions were asked or
  /// reached. A record session's round is as long as the learner's due or missed items when they
  /// number fewer than ten, so its length would count wrong answers, and no signal says how well
  /// a learner did.
  var sendsQuestionCounts: Bool {
    recordSession == nil
  }

  /// Whether a round's questions are shuffled. A record session asks its items in the record's
  /// order, the most overdue or most recently missed first, with a verb's key conjugations
  /// together.
  var shufflesQuestions: Bool {
    recordSession == nil
  }

  /// Whether each round mixes in items the practice record says are due: only the default quiz,
  /// since a quiz over chosen verbs or tenses should ask what was chosen.
  var mixesDueItems: Bool {
    isRanked
  }

  /// Whether the results offer Ten More, which continues the session with another round. Test
  /// Me's three questions are a check on one verb, not a session to grow.
  var continues: Bool {
    questionCount >= QuizScope.roundLength
  }

  /// Whether the quiz starts the Live Activity, which is one for the whole app and belongs to the
  /// Quiz tab's quiz. A three-question quiz in a verb page's sheet is over before one would be
  /// noticed, and a collection's quiz runs in the same sheet, beside a quiz the tab may hold, so
  /// neither starts one, though a collection's is a full round. A custom quiz over a collection
  /// runs on the tab, and starts one. A practice set's runs in a sheet, and does not.
  var startsLiveActivity: Bool {
    questionCount >= QuizScope.roundLength && !isPracticeSet && (collectionKey == nil || custom != nil)
  }

  /// The tenses the quiz asks at a level: the learner's choice, or the level's.
  func pool(level: QuizLevel) -> [QuizPoolEntry] {
    custom?.pool(level: level) ?? level.pool
  }

  /// The band a quiz with nil `verbs` draws from: a custom quiz's chosen band, or the level's.
  func band(level: QuizLevel) -> FrequencyBand? {
    guard let custom else {
      return level.band
    }
    return custom.band(level: level)
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
