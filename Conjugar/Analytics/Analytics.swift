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
  case deepestSection
  case difficulty
  case dwell
  case elapsedTime
  case matchKind
  case outcome
  case queryLength
  case questionNumber
  case resultCount
  case resultPosition
  case score
  case source
  case stage
  /// `tapStarVerb`'s state after the tap, `true` or `false` (browse plan, Phase 12).
  case starred
}

nonisolated enum AnalyticsName: String {
  case completeQuiz
  case completeStage
  case enterBossFight
  case finishSearch
  case gameCenterAuthSucceeded
  case leaveVerbView
  case quitQuiz
  case startGame
  case startQuiz
  case tapPlayGame
  case tapRateOrReview
  case tapSendTutorMessage
  /// The share button in a verb page's navigation bar (browse plan, Phase 9). No parameters, and
  /// it does not say which verb. Copying a form sends nothing.
  case tapShareVerb
  case tapShowOnboarding
  /// The star in a verb page's navigation bar (browse plan, Phase 12). Carries `starred`, the
  /// state after the tap, and does not say which verb.
  case tapStarVerb
  /// The ⓘ beside a tense's heading on a verb page (browse plan, Phase 6). No parameters.
  case tapTenseArticle
  case viewInfoBrowseView
  case viewInfoView
  case viewModelBrowseView
  case viewModelView
  case viewOnboardingView
  case viewQuizView
  case viewResultsView
  case viewSettingsView
  case viewTutorView
  case viewVerbBrowseView
  case viewVerbView
  case winBossFight
}

/// How the learner reached a verb page or, once later phases send it, began a search or a quiz.
/// One vocabulary for every signal that carries `source`, so that a verb page, a search, and a
/// quiz reached from the same surface carry the same value. It holds the values that later phases
/// of `plans/browse_and_verb_implementation.md` will send, too; `docs/feature_architecture.md`
/// § Analytics says which are sent today. A raw value is a wire name.
nonisolated enum AnalyticsSource: String, CaseIterable, Sendable {
  /// A row of the verb list with the search field empty.
  case browse
  /// The Random Verb control in Control Center.
  case control
  /// A `conjugar://` link with no recognized `source` query item.
  case deeplink
  case infoLink
  case list
  case lookup
  /// A verb row on a model's page.
  case model
  case myVerbs
  case quickAction
  case recent
  case related
  /// The page came back after another tab, a pushed page, or the background. See `VerbVisit`.
  case resume
  case reviewCard
  /// A result of a search that found something.
  case search
  /// The closest verb offered by a search that found nothing.
  case searchGuess
  case sharedLink
  /// An App Intent run from the Shortcuts app or Siri, as `OpenRandomVerbIntent` can be.
  case shortcut
  case spotlight
  case tab
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
/// for "hablo" (browse plan, Phase 5). A guess made from a form is still `guess`.
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
