//
//  AppRouter.swift
//  Conjugar
//
//  Tab selection + deeplink routing for the widgets, the Control Center controls, the Home
//  Screen quick action, and Command-F. A `conjugar://` URL (from a widget tap, a quick action,
//  or `simctl openurl`) or a drained control-widget deeplink is turned into a tab switch plus a
//  pending navigation the destination screen consumes.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

enum AppTab: Hashable {
  case browseVerbs
  case models
  case quiz
  case info
  case settings
}

@Observable
final class AppRouter {
  /// The router the app runs on. `ConjugarApp` hands it to its views; the quick action's scene
  /// delegate, which SwiftUI creates and cannot hand a value, reaches it here. Tests make their own.
  static let shared = AppRouter()

  var selectedTab: AppTab = .browseVerbs
  /// A verb the Verbs tab should push, with the surface that asked for it. `VerbBrowseView`
  /// consumes and clears it.
  var pendingVerb: VerbDestination?
  /// A one-shot request for the Verbs tab to pop to its list and show its search field, set by
  /// Command-F, the Find a Verb control and quick action, and a `search` link.
  /// `VerbBrowseView` consumes and clears it.
  var pendingSearch: SearchRequest?
  /// An article the Info tab should push, from an `info` link. `InfoBrowseView` consumes and
  /// clears it.
  var pendingInfo: Info?
  /// A collection the Models tab should push, from a `list` link. `ModelBrowseView` consumes and
  /// clears it.
  var pendingCollection: CollectionRequest?
  /// A one-shot request for the Quiz tab to start a quiz, with the link's `source` (`deeplink` when
  /// it names none), which the quiz signals carry. `QuizView` consumes it.
  var pendingQuizStart: AnalyticsSource?
  /// A one-shot request for the Quiz tab to start a daily session, from a `quiz/daily` link, which
  /// a tapped reminder opens, with the link's `source`. `QuizView` consumes it.
  var pendingDailySession: AnalyticsSource?
  /// A one-shot request for the Quiz tab to start a daily challenge, from a `quiz/challenge` link,
  /// which shared text and the quiz widget open. `QuizView` consumes it.
  var pendingChallenge: DailyChallengeRequest?
  /// A practice set from a `quiz/set` link, which `MainTabView` shows in a sheet over whatever tab
  /// is open. Any other link replaces it with nil, so that what the link opens is not hidden.
  var pendingPracticeSet: PracticeSetRequest?
  /// Drives a full-screen `GameView` cover from `MainTabView`, tab-independent so a
  /// `conjugar://game` deeplink jumps straight to the game from any screen. (The
  /// Settings tab's Play button presents the game via its own state; both are fine.)
  var showGame = false
  /// A one-shot request to start the game at the boss fight, set by the
  /// `conjugar://game/boss` debug deeplink. `GameView` consumes it after configure.
  var pendingBossEntry = false
  /// A one-shot request to jump straight to the boss's end scene, set by the
  /// `conjugar://game/end` debug deeplink. `GameView` consumes it after configure.
  var pendingEndScene = false
  /// Drives the first-launch onboarding cover from `MainTabView`. Tripped once at
  /// launch when `Settings.hasSeenOnboarding` is false (and the kill switch is on).
  var showOnboarding = false
  /// A one-shot request for the Info tab to push the conjugation tutor, set by the
  /// onboarding "Meet the Tutor" CTA. `InfoBrowseView` consumes and clears it.
  var pendingTutor = false
  /// Records that an onboarding game-preview CTA was tapped, so the presenting cover's
  /// `onDismiss` launches the game rather than the CTA itself — the game cover must
  /// never open over the still-dismissing onboarding cover (two covers can't share the
  /// anchor at once). Both onboarding presenters (`MainTabView`, `SettingsView`) route
  /// through this one flag + helper.
  var pendingGameAfterOnboarding = false

  /// The practice set `MainTabView`'s sheet shows: none while the tour or the game covers the
  /// tabs, since a sheet cannot present beneath a cover. The set waits, and shows once the cover
  /// is gone.
  var presentablePracticeSet: PracticeSetRequest? {
    get {
      showOnboarding || showGame || pendingGameAfterOnboarding ? nil : pendingPracticeSet
    }
    set {
      pendingPracticeSet = newValue
    }
  }

  /// Called by an onboarding game CTA just before it dismisses the tour.
  func requestGameAfterOnboarding() {
    pendingGameAfterOnboarding = true
  }

  /// Run from the onboarding cover's `onDismiss`: presents the game if a CTA requested it.
  func launchGameAfterOnboardingIfRequested() {
    guard pendingGameAfterOnboarding else { return }
    pendingGameAfterOnboarding = false
    showGame = true
  }

  /// Route a `conjugar://` deeplink. `docs/feature_architecture.md` § Deeplinks has the grammar
  /// and every route: `verb/<infinitive>` (bare or with "se", so `verb/arrepentirse` opens
  /// arrepentir, or `verb/random`), with `match`, a form the page marks; `search`, with its text
  /// in `q`; `info/<stableKey>` (or a position); `list/<key>`, a collection; `quiz` (any target
  /// starts a quiz, except `quiz/set`, a practice set, `quiz/daily`, a daily session, and
  /// `quiz/challenge`, a daily challenge); and
  /// `game`.
  /// A link to a verb page, a search, or a quiz may name the surface it came from in `source`
  /// (`?source=widget`); a link that names none reports `deeplink`. Unknown routes, unknown
  /// verbs, and unknown collections are ignored.
  func handle(url: URL) {
    guard url.isDeeplink, let host = url.host() else { return }
    let source = url.analyticsSource ?? .deeplink
    if host == URL.quizHost, url.deeplinkTarget == URL.practiceSetTarget {
      pendingPracticeSet = PracticeSetRequest(practiceSet: PracticeSet(url: url), source: source)
      return
    }
    pendingPracticeSet = nil
    switch host {
    case URL.verbHost:
      guard let target = url.deeplinkTarget else { return }
      if target == URL.randomVerbTarget {
        // From the frequent verbs or My Verbs, as the widget's verb of the day is.
        if let random = VerbDraw.randomVerb(myVerbs: Current.learnerVerbs.myVerbs) {
          open(verb: random.infinitive, source: source)
        }
      } else if let infinitive = Self.infinitive(named: target) {
        let match = url.deeplinkQueryValue(named: URL.matchQueryName)
        let marks = match.map { Self.marks(of: $0, on: infinitive, hiding: Current.settings.secondSingularBrowse.hiddenPersons) } ?? []
        open(verb: infinitive, source: source, marks: marks)
      }
    case URL.searchHost:
      // The search route alone takes no target; its text travels in `q`.
      guard url.hasNoDeeplinkTarget else { return }
      openSearch(text: url.deeplinkQueryValue(named: URL.searchTextQueryName) ?? "", source: source)
    case URL.infoHost:
      guard let target = url.deeplinkTarget, let info = Info.info(deeplinkTarget: target) else { return }
      selectedTab = .info
      pendingInfo = info
    case URL.listHost:
      guard let target = url.deeplinkTarget, let collection = VerbCollection(key: target) else { return }
      selectedTab = .models
      pendingCollection = CollectionRequest(collection: collection, source: source)
    case URL.quizHost:
      selectedTab = .quiz
      if url.deeplinkTarget == URL.dailySessionTarget {
        pendingDailySession = source
      } else if url.deeplinkTarget == URL.challengeTarget {
        pendingChallenge = DailyChallengeRequest(url: url, source: source)
      } else {
        // Any other target, `quiz/start` as the Quick Quiz control sends it, or none, starts a quiz.
        pendingQuizStart = source
      }
    case URL.gameHost:
      // `conjugar://game/boss` is the boss fight's debug entry and
      // `conjugar://game/end` jumps straight to its end scene (same host, one
      // path component); plain `conjugar://game` starts the climb as always.
      // The flags are consumed only by `GameView.onAppear`, so ignore them when the
      // game is already up — otherwise one lingers and hijacks the next plain `game`.
      if !showGame {
        switch url.lastPathComponent {
        case "boss": pendingBossEntry = true
        case "end": pendingEndScene = true
        default: break
        }
      }
      showGame = true
    default:
      break
    }
  }

  /// Shows the Verbs tab's list with its search field. A nil `text` keeps what the field holds,
  /// as Command-F does, and focuses it. Empty text clears the field and focuses it, for typing.
  /// Other text is searched for, with the keyboard down so that the results show.
  func openSearch(text: String?, source: AnalyticsSource) {
    pendingVerb = nil
    selectedTab = .browseVerbs
    pendingSearch = SearchRequest(text: text, source: source)
  }

  /// The infinitive `VerbMap` keys a link's target on: the target itself, or for a pronominal
  /// citation form, arrepentirse, as the widgets name a reflexive-only verb, the bare one.
  private static func infinitive(named target: String) -> String? {
    if VerbMap.shared.entry(for: target) != nil {
      return target
    }
    if let bare = ReflexivePronoun.bareInfinitive(fromCitation: target), VerbMap.shared.entry(for: bare) != nil {
      return bare
    }
    return nil
  }

  /// The cells of `infinitive` that `match` is, as written or else with its accents folded, less
  /// the second-singular person the page hides where the other shares the form. Empty when the
  /// text is no form of the verb.
  static func marks(of match: String, on infinitive: String, hiding hidden: Set<DisplayPersonNumber>) -> Set<ConjugationCell> {
    var cells = ConjugationMatch.cells(of: infinitive, equalTo: match)
    if cells.isEmpty {
      cells = ConjugationMatch.cells(of: infinitive, equalTo: match, accents: .folded)
    }
    guard !cells.isEmpty else {
      return []
    }
    return Set(MatchedForm(text: match, cells: cells, isFolded: false).shownCells(hiding: hidden))
  }

  private func open(verb: String, source: AnalyticsSource, marks: Set<ConjugationCell> = []) {
    pendingSearch = nil
    selectedTab = .browseVerbs
    pendingVerb = VerbDestination(infinitive: verb, source: source, marks: marks)
  }
}

/// A request, from a link, a control, a quick action, or Command-F, that the verb list show its
/// search field.
struct SearchRequest: Equatable {
  /// Nil keeps what the field holds.
  let text: String?
  /// Where the search began, which `finishSearch` reports.
  let source: AnalyticsSource
}

/// A collection to open, from a `list` link or a row of the Models tab, with the surface that asked
/// for it, which `viewCollection` reports. A model's collection opens as the model's page.
struct CollectionRequest: Hashable {
  let collection: VerbCollection
  let source: AnalyticsSource
}
