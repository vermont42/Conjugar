//
//  Analytics.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/24/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

// `nonisolated` throughout, like the engine: analytics is pure plumbing with no UI
// state, and AnalyticsReal deliberately does its work off the main actor. Without
// this, the module's default MainActor isolation would make the protocol — and, by
// witness inference, every conformer's methods — MainActor-isolated, which both
// contradicts AnalyticsReal's design and makes the spy unusable from a nonisolated
// test suite. MainActor call sites can call into it synchronously either way.
nonisolated enum ParameterKey: String {
  /// A collection's key, such as `top100` or `model-31`, on `viewCollection`, `tapShareCollection`,
  /// and a collection's `startQuiz`. A list, never a verb.
  case collection
  /// What kind of choice a custom quiz's `startQuiz` was over: `tenses`, `verbs`, or `both`
  /// (`CustomQuiz.choiceParameter`). Never which tenses or verbs.
  case customChoice
  case deepestSection
  /// The band of time from a quiz's start to its quit or to a round's results
  /// (`AnalyticsBand.quizDuration`), on `quitQuiz` and `completeQuiz`.
  case duration
  case dwell
  /// `tapDailyReminder`'s choice: `true`, `false`, or `denied`, when the learner turned the
  /// reminder on and refused notifications.
  case enabled
  /// The quiz's `QuizLevel`, by its raw value, on `startQuiz`, `quitQuiz`, and `completeQuiz`.
  case level
  case matchKind
  /// How a practice set was shared, on `tapSharePracticeSet`: `link` or `qrCode`.
  case method
  /// `finishSearch`'s `SearchOutcome`, or `viewPracticeSet`'s `opened` or `invalid`.
  case outcome
  case queryLength
  /// The questions a session has asked at a round's results, re-asks not counted (10, 20, …),
  /// on `completeQuiz`.
  case questionCount
  /// The question reached, re-asks not counted, on `quitQuiz` and `abandonQuiz`.
  case questionNumber
  case resultCount
  case resultPosition
  /// The score of a ranked session's first round, on that round's `completeQuiz` and on a quit
  /// during it. No other quiz sends it.
  case score
  case source
  case stage
  /// The streak a daily session leaves, or the one at stake while a repair waits, in bands
  /// (`AnalyticsBand.streak`), on a daily session's `completeQuiz`.
  case streak
  /// `tapStarVerb`'s state after the tap, `true` or `false`.
  case starred
}

nonisolated enum AnalyticsName: String {
  /// Sent at launch for each quiz the last run was left during. Carries `level`, `source`, and
  /// `questionNumber`.
  case abandonQuiz
  case completeQuiz
  case completeStage
  case enterBossFight
  case finishSearch
  case gameCenterAuthSucceeded
  case leaveVerbView
  case quitQuiz
  case startGame
  case startQuiz
  /// Keep as My Custom Quiz on a practice set's sheet. No parameters.
  case tapKeepPracticeSet
  case tapPlayGame
  /// Off or On under Settings' Daily Reminder. Carries `enabled`.
  case tapDailyReminder
  case tapRateOrReview
  /// Reset in Settings' confirmation of Reset Practice. No parameters.
  case tapResetPractice
  /// The first tap on the review card above the verb list, which reveals its key conjugations.
  /// No parameters, and it does not say which verb.
  case tapRevealReviewCard
  case tapSendTutorMessage
  /// The share button in a verb page's navigation bar. No parameters, and it does not say which
  /// verb. Copying a form sends nothing.
  case tapShareVerb
  /// Share Result on a daily challenge's results or its row on the Quiz tab. Carries `level`, never
  /// the result.
  case tapShareChallenge
  /// The share button on a collection's bar. Carries `collection`.
  case tapShareCollection
  /// Share Link or Show QR Code under the Quiz tab's custom quiz. Carries `method` and
  /// `customChoice`, never which tenses or verbs.
  case tapSharePracticeSet
  case tapShowOnboarding
  /// The star in a verb page's navigation bar. Carries `starred`, the state after the tap, and
  /// does not say which verb.
  case tapStarVerb
  /// The ⓘ beside a tense's heading on a verb page. No parameters.
  case tapTenseArticle
  /// A View Achievements button: the Quiz tab's sends `source` `tab`, and Settings' sends nothing.
  /// No signal says that an achievement was earned, which would report how well a learner did.
  case tapViewAchievements
  /// A leaderboard button: the Quiz tab's sends `level`, the board it opens, and `source` `tab`;
  /// Settings', which opens the list of every level's board, sends nothing.
  case tapViewLeaderboard
  /// Once for each opening of a featured collection's page or of a model's page, whose bar makes
  /// it a collection. Carries `collection` and `source`.
  case viewCollection
  case viewInfoBrowseView
  case viewInfoView
  /// Once for each opening of the Mastery page from the Quiz tab. No parameters, and nothing
  /// about the record or the level.
  case viewMastery
  case viewModelBrowseView
  case viewModelView
  case viewOnboardingView
  /// Once for each practice-set sheet a link opens. Carries `outcome`, `opened` or `invalid`
  /// (a link that names nothing this version knows), and `source`.
  case viewPracticeSet
  case viewQuizView
  case viewResultsView
  /// Once for each review card shown above the verb list. No parameters, and it does not say
  /// which verb.
  case viewReviewCard
  case viewSettingsView
  case viewTutorView
  case viewVerbBrowseView
  case viewVerbView
  case winBossFight
}

/// How the learner reached a verb page or began a search or a quiz. One vocabulary for every
/// signal that carries `source`, so that a verb page, a search, and a quiz reached from the same
/// surface carry the same value. Not every value is sent yet; `docs/feature_architecture.md`
/// § Analytics says which are. A raw value is a wire name.
nonisolated enum AnalyticsSource: String, CaseIterable, Sendable {
  /// A row of the verb list with the search field empty.
  case browse
  /// The Quiz tab's Daily Challenge, five questions a day, the same for everyone at a level.
  case challenge
  /// A daily challenge's link, from the text a learner shared.
  case challengeLink
  /// A tap on the quiz widget beside its answers, which opens the day's challenge.
  case challengeWidget
  /// The Random Verb control in Control Center.
  case control
  /// A custom quiz begun from the Quiz tab's Custom segment.
  case custom
  /// The Quiz tab's Daily Session, ten questions a day that build a streak.
  case daily
  /// A `conjugar://` link with no recognized `source` query item.
  case deeplink
  case infoLink
  case list
  case lookup
  /// The Quiz tab's Practice My Mistakes, of the questions last answered wrongly.
  case mistakes
  /// A verb row on a model's page.
  case model
  /// A verb model's practice alone, from its card on the model's page or in the Quiz tab's list.
  case modelAlone
  /// A verb model's practice mixed with the models the learner knows.
  case modelMixed
  /// A row of My Verbs in the verb list, or a quiz over My Verbs begun from the Quiz tab.
  case myVerbs
  /// A practice set's QR code, scanned with the Camera app. A shared link says `sharedLink`.
  case qrCode
  case quickAction
  /// A link on the correction a quiz holds after a wrong answer: to the verb's page or its model's.
  case quizCorrection
  case recent
  /// The Quiz tab's Name the Form, which shows a form and asks for its infinitive, tense, and person.
  case recognition
  case related
  /// A tapped daily reminder, which starts a daily session.
  case reminder
  /// The page came back after another tab, a pushed page, or the background. See `VerbVisit`.
  case resume
  /// The Quiz tab's Review, of the questions the practice record says are due.
  case review
  /// The review card above the verb list, tapped after its reveal.
  case reviewCard
  /// A result of a search that found something.
  case search
  /// The closest verb offered by a search that found nothing.
  case searchGuess
  /// The Quiz tab's Complete the Sentence, which blanks a verb in an authored sentence.
  case sentences
  case sharedLink
  /// An App Intent run from the Shortcuts app or Siri, as `OpenRandomVerbIntent` can be.
  case shortcut
  /// The Quiz tab's Speed Round, sixty seconds on what the practice record says is mastered.
  case speedRound
  case spotlight
  /// A search begun in the Verbs tab, or a quiz over every verb begun with the Quiz tab's Start.
  case tab
  /// The Quiz tab's Verb Essentials, of irregular verbs' key conjugations.
  case verbEssentials
  /// Test Me's three questions on a verb's page.
  case verbPage
  /// A tap on any of the widgets: Verb of the Day, the quiz widget, or a Lock Screen accessory.
  case widget
}

nonisolated enum SearchOutcome: String, CaseIterable, Sendable {
  case abandoned
  case noResult
  case opened
}

/// `VerbSearch.MatchKind`'s cases by name, plus `guess` (the empty state's closest verb) and
/// `none`. `conjugation` and `foldedConjugation` are a form of the verb, such as fue or habló
/// for "hablo". A guess made from a form is still `guess`.
nonisolated enum SearchMatchKind: String, CaseIterable, Sendable {
  case conjugation
  case exactFoldedInfinitive
  case exactGlossSense
  case exactInfinitive
  case foldedConjugation
  case foldedInfinitivePrefix
  case foldedInfinitiveSubstring
  case glossSubstring
  case guess
  case infinitivePrefix
  case infinitiveSubstring
  case none
  case wholeWordGloss
}

/// The parts of a verb page, top to bottom, for `leaveVerbView`'s `deepestSection`.
nonisolated enum VerbPageSection: String, CaseIterable, Comparable, Sendable {
  case header
  case simple
  case compound
  case etymology
  case example

  static func < (lhs: VerbPageSection, rhs: VerbPageSection) -> Bool {
    let order = allCases
    return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
  }
}

/// Coarse bands for counts and durations. The privacy policy promises that nothing typed is sent,
/// and an exact query length or dwell time would come closer to identifying what was typed or
/// read than a band does.
nonisolated enum AnalyticsBand {
  static let noPosition = "none"

  static func queryLength(_ length: Int) -> String {
    switch length {
    case ...2:
      return "1-2"
    case 3...5:
      return "3-5"
    case 6...9:
      return "6-9"
    default:
      return "10+"
    }
  }

  static func resultCount(_ count: Int) -> String {
    switch count {
    case ...0:
      return "0"
    case 1:
      return "1"
    case 2...10:
      return "2-10"
    default:
      return "11+"
    }
  }

  /// `index` counts from zero, as the list does. The band counts from one, as a reader does.
  static func resultPosition(_ index: Int?) -> String {
    guard let index else {
      return noPosition
    }
    switch index {
    case ...0:
      return "1"
    case 1...4:
      return "2-5"
    default:
      return "6+"
    }
  }

  /// From a quiz's start to its quit or its results. A quit within three seconds reads as
  /// exploring and one after forty as struggling; the longer bands split a round of ten, which
  /// often runs one to three minutes.
  static func quizDuration(_ seconds: Double) -> String {
    switch seconds {
    case ..<3:
      return "0-3s"
    case ..<15:
      return "3-15s"
    case ..<40:
      return "15-40s"
    case ..<120:
      return "40s-2m"
    default:
      return "2m+"
    }
  }

  static func dwell(_ seconds: Double) -> String {
    switch seconds {
    case ..<5:
      return "0-5s"
    case ..<15:
      return "5-15s"
    case ..<60:
      return "15-60s"
    default:
      return "60s+"
    }
  }
}

nonisolated protocol Analytics {
  func initialize(appID: String)
  func signal(name: AnalyticsName, parameters: [String: String])
}

nonisolated extension Analytics {
  func signal(name: AnalyticsName) {
    signal(name: name, parameters: [:])
  }
}
