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
  /// Which of the app's quizzes this is. Every scope names one, so that a new mode is a new case,
  /// and the switches below make it decide, rather than a flag it might forget to add itself to.
  /// Only `allVerbs` ranks.
  enum Kind: Equatable, Sendable {
    /// The quiz over every verb at the learner's level: the Quiz tab's Start, or a `quiz` link.
    case allVerbs
    /// The Quiz tab's quiz over the learner's My Verbs.
    case myVerbs
    /// Test Me, three questions on a verb's page.
    case verbPage
    /// A collection's Quiz button.
    case collection
    /// The Quiz tab's Custom segment.
    case custom
    /// A shared practice set, opened from a link or a QR code.
    case practiceSet
    /// Review or Practice My Mistakes, whose questions come from the practice record.
    case recordSession(QuizRecordSession)
    /// Verb Essentials, which asks each verb's key conjugations together (`VerbEssentials.swift`).
    case verbEssentials
    /// A verb model's practice, alone or mixed with the known models (`ModelPractice.swift`), which
    /// is Verb Essentials over the model's verbs.
    case modelPractice(ModelPracticeSession)
    /// Name the Form, which shows a form and asks for its infinitive, tense, and person
    /// (`Recognition.swift`).
    case recognition
    /// Complete the Sentence, which asks authored sentences with their verb blanked
    /// (`GapSentence.swift`).
    case sentences
    /// The Speed Round, sixty seconds on what the practice record says is mastered
    /// (`SpeedRound.swift`).
    case speedRound
    /// The daily session, whose finish extends the streak (`DailySession.swift`).
    case daily
    /// A day's challenge, the same five questions on every device (`DailyChallenge.swift`).
    case challenge(DailyChallenge.Key)

    /// Whether the quiz runs in `QuizSheet`, over whatever page or tab is open, rather than on the
    /// Quiz tab. A custom quiz over a collection runs on the tab.
    var runsInSheet: Bool {
      switch self {
      case .verbPage, .collection, .practiceSet, .modelPractice:
        return true
      case .allVerbs, .myVerbs, .custom, .recordSession, .verbEssentials, .recognition, .sentences, .speedRound, .daily, .challenge:
        return false
      }
    }
  }

  let kind: Kind
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
  /// The learner's own choice of tenses and verbs, which the Quiz tab's Custom segment starts and
  /// a practice set carries. A custom quiz over a band or every verb has nil `verbs` and draws as
  /// the default quiz does, from the chosen band.
  let custom: CustomQuiz?
  /// A practice set's level, so that everyone who opens the set is asked the same tenses and
  /// verbs, or a challenge's. Nil asks at the learner's own level.
  let level: QuizLevel?

  init(
    kind: Kind,
    verbs: [String]?,
    questionCount: Int,
    source: AnalyticsSource,
    title: String? = nil,
    collectionKey: String? = nil,
    custom: CustomQuiz? = nil,
    level: QuizLevel? = nil
  ) {
    self.kind = kind
    self.verbs = verbs
    self.questionCount = questionCount
    self.source = source
    self.title = title
    self.collectionKey = collectionKey
    self.custom = custom
    self.level = level
  }

  var isPracticeSet: Bool {
    kind == .practiceSet
  }

  var recordSession: QuizRecordSession? {
    if case .recordSession(let session) = kind {
      return session
    }
    return nil
  }

  /// Verb Essentials, or a model's practice, which asks the same questions over the model's verbs.
  var isVerbEssentials: Bool {
    kind == .verbEssentials || modelPractice != nil
  }

  var modelPractice: ModelPracticeSession? {
    if case .modelPractice(let session) = kind {
      return session
    }
    return nil
  }

  var isRecognition: Bool {
    kind == .recognition
  }

  var isSentences: Bool {
    kind == .sentences
  }

  var isSpeedRound: Bool {
    kind == .speedRound
  }

  var isDaily: Bool {
    kind == .daily
  }

  var challenge: DailyChallenge.Key? {
    if case .challenge(let key) = kind {
      return key
    }
    return nil
  }

  var isChallenge: Bool {
    challenge != nil
  }

  /// A round's length. The Quiz tab's quiz, a My Verbs quiz, and a collection's ask one round,
  /// and the results offer another (`continues`).
  static let roundLength = 10

  /// Test Me's length on a verb's page.
  static let verbPageQuestionCount = 3

  /// Only the default quiz over every verb, a round long, ranks: a score over a learner's own
  /// verbs or tenses, over what the practice record holds, over another kind of question, against
  /// the clock, or over another number of questions, compares with nothing, and a daily session is
  /// filled from the record. Of a ranked session, only the first round's score counts
  /// (`Quiz.firstRoundScore`).
  var isRanked: Bool {
    kind == .allVerbs && questionCount == QuizScope.roundLength
  }

  /// Whether `completeQuiz`, `quitQuiz`, and `abandonQuiz` say how many questions were asked or
  /// reached. A record session's round is as long as the learner's due or missed items when they
  /// number fewer than ten, so its length would count wrong answers, and no signal says how well
  /// a learner did. A mixed model practice's round can be short when the known models hold few
  /// verbs, and which models are known comes from the learner's answers. A Speed Round's length is
  /// how many questions were answered in a minute, which measures the answers themselves.
  var sendsQuestionCounts: Bool {
    recordSession == nil && modelPractice?.mode != .mixed && !isSpeedRound
  }

  /// Whether a round's questions are shuffled. A record session asks its items in the record's
  /// order, the most overdue or most recently missed first, with a verb's key conjugations
  /// together. Verb Essentials asks a verb's key conjugations together, in the verb page's order. A
  /// Speed Round's draw orders its own questions, so that no item is asked twice running. A
  /// challenge asks its questions in the order every device draws them.
  var shufflesQuestions: Bool {
    recordSession == nil && !isVerbEssentials && !isSpeedRound && !isChallenge
  }

  /// Whether each round mixes in items the practice record says are due: only the default quiz,
  /// since a quiz over chosen verbs or tenses should ask what was chosen.
  var mixesDueItems: Bool {
    isRanked
  }

  /// Whether each round asks one choice between two sentences, from the second level up: only
  /// the default quiz, so that every ranked round of a level asks the same mix.
  var mixesChoiceQuestions: Bool {
    isRanked
  }

  /// Whether the results offer Ten More, or for Verb Essentials five more verbs, which continue the
  /// session with another round. Test Me's three questions are a check on one verb, not a session
  /// to grow. A Speed Round's results offer a new round instead. A daily session's next is a
  /// session of its own, which a repair counts.
  var continues: Bool {
    questionCount >= QuizScope.roundLength && !isSpeedRound && !isDaily && !isChallenge
  }

  /// Whether the quiz starts the Live Activity, which is one for the whole app and belongs to the
  /// Quiz tab's quiz. A quiz in a sheet runs beside a quiz the tab may hold, so it starts none,
  /// though a collection's is a full round. A quiz shorter than a round, such as a challenge, is
  /// over before one would be noticed. A Speed Round's minute has no number of questions for the
  /// activity to count toward.
  var startsLiveActivity: Bool {
    !kind.runsInSheet && questionCount >= QuizScope.roundLength && !isSpeedRound
  }

  /// Whether a correction links to its verb's page. Test Me runs on that page, under its sheet.
  var showsVerbLink: Bool {
    kind != .verbPage
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
    QuizScope(kind: .allVerbs, verbs: nil, questionCount: roundLength, source: source)
  }

  static func myVerbs(_ verbs: [String]) -> QuizScope {
    QuizScope(kind: .myVerbs, verbs: verbs, questionCount: roundLength, source: .myVerbs)
  }

  static func verbPage(_ verb: String) -> QuizScope {
    QuizScope(kind: .verbPage, verbs: [verb], questionCount: verbPageQuestionCount, source: .verbPage)
  }

  /// A round of an unranked quiz over a collection, in the same sheet as Test Me, titled with the
  /// collection's name. Its `startQuiz` carries the collection's key.
  static func collection(_ collection: VerbCollection, title: String) -> QuizScope {
    QuizScope(
      kind: .collection,
      verbs: collection.infinitives,
      questionCount: roundLength,
      source: .list,
      title: title,
      collectionKey: collection.key
    )
  }
}
