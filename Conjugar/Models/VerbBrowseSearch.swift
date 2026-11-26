//
//  VerbBrowseSearch.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Observation

/// The Verbs tab's search, and what its list shows: the recent verbs, My Verbs, a search's
/// results, or every verb. It owns the text, the results, the guess, the `SearchTracker`, and the
/// keyboard selection, and it sends `finishSearch`. `VerbBrowseView` keeps the focus, the
/// navigation, and the UIKit workarounds, and tells this model what they decide.
@Observable
final class VerbBrowseSearch {
  /// What the list shows.
  enum Shown: Equatable {
    /// Every verb in the sort order.
    case everyVerb
    /// The verbs last opened, while the field is focused and empty.
    case recents
    /// The picker's My Verbs, with nothing typed.
    case myVerbs
    /// A search's results, which may be none.
    case results
  }

  /// One row of the list, with everything its opening needs, settled when the row is drawn. On
  /// iPad a tap can take the focus from the field, and with it the recents, before the row's
  /// action runs, so the action must not look the row up again.
  struct Row: Identifiable, Equatable {
    enum Origin: Equatable {
      case everyVerb
      case recent
      /// A search's match, its place in the results counting from zero, and how many there were.
      case result(VerbSearch.Match, position: Int, resultCount: Int)
    }

    let entry: VerbMapEntry
    let origin: Origin

    var id: String {
      entry.infinitive
    }

    var match: VerbSearch.Match? {
      guard case let .result(match, _, _) = origin else {
        return nil
      }
      return match
    }
  }

  /// The field's text, as typed. Set it with `setText(_:)`.
  private(set) var text = ""
  /// The picker's choice: a sort order, or My Verbs.
  private(set) var listMode: VerbListMode
  /// The order of the full list. It survives a visit to My Verbs.
  private(set) var sort: VerbSort
  /// Whether the field is focused, as `VerbBrowseView` reports it: a moment after the focus goes,
  /// for the reason that view's `searchFocusChanged` gives.
  private(set) var isEngaged = false
  /// The search's rows, best first. Empty when nothing is typed.
  private(set) var results: [Row] = []
  /// The closest verb to a query that found nothing, or nil. See `VerbSearch.guess`.
  private(set) var guess: VerbSearch.Guess?
  /// The infinitive of the row, or the guess, that Return opens and the arrow keys move, on a
  /// hardware keyboard. Nil until an arrow is pressed, and cleared whenever the shown list changes.
  private(set) var selection: String?
  /// The conjugation index, once the warm-up has built it. Until then a search matches infinitives
  /// and glosses only, so that typing never waits for the index on the main actor.
  private(set) var index: ConjugationIndex?

  @ObservationIgnored private var tracker = SearchTracker()
  /// Letters tapped on the letter row that wait, in order, for the search to finish going away.
  @ObservationIgnored private var waitingLetters = ""
  /// A failed search made before the index existed, whose sad trombone waits for the index to
  /// say whether a form matches.
  @ObservationIgnored private var failureAwaitsIndex = false
  @ObservationIgnored private let learnerVerbs: LearnerVerbStore
  @ObservationIgnored private let settings: Settings
  @ObservationIgnored private let analytics: Analytics
  @ObservationIgnored private let searchFailed: () -> Void

  /// Every verb in each order, as rows, built once.
  private static let everyVerbRows: [VerbSort: [Row]] = VerbSort.mapLists.mapValues { entries in
    entries.map { Row(entry: $0, origin: .everyVerb) }
  }

  init(
    sort: VerbSort = Current.settings.verbSort,
    index: ConjugationIndex? = nil,
    learnerVerbs: LearnerVerbStore = Current.learnerVerbs,
    settings: Settings = Current.settings,
    analytics: Analytics = Current.analytics,
    searchFailed: @escaping () -> Void = { Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true) }
  ) {
    self.sort = sort
    listMode = VerbListMode(sort: sort)
    self.index = index
    self.learnerVerbs = learnerVerbs
    self.settings = settings
    self.analytics = analytics
    self.searchFailed = searchFailed
  }

  // MARK: - What the list shows

  var trimmedText: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// The one test of whether a search is under way, which the tip, the review card, the list, and
  /// the picker all read. A space alone is not a search.
  var isSearching: Bool {
    !trimmedText.isEmpty
  }

  var shown: Shown {
    if isSearching {
      return .results
    }
    if isEngaged, !learnerVerbs.recentVerbs.isEmpty {
      return .recents
    }
    return listMode == .myVerbs ? .myVerbs : .everyVerb
  }

  /// The rows of the scrolling list. Empty while My Verbs shows, since My Verbs is a list of its own.
  var rows: [Row] {
    switch shown {
    case .everyVerb:
      return Self.everyVerbRows[sort] ?? []
    case .recents:
      return learnerVerbs.recentVerbs.map { Row(entry: $0, origin: .recent) }
    case .myVerbs:
      return []
    case .results:
      return results
    }
  }

  /// A search that found nothing, which shows "No verbs found" and the failed search's help.
  var hasFailed: Bool {
    isSearching && results.isEmpty
  }

  /// A search that found nothing before the index was built, which may yet find a form.
  var awaitsIndex: Bool {
    hasFailed && index == nil
  }

  /// "hablo: Presente de Indicativo (yo)", one line per form a row matched. Empty for a match on
  /// the infinitive or a gloss, and for a row not from a search.
  func matchLines(of row: Row) -> [String] {
    guard let match = row.match else {
      return []
    }
    return MatchedForm.shown(match.forms, hiding: hiddenPersons).map { $0.line(hiding: hiddenPersons) }
  }

  /// The guess's line, naming the form it was guessed from, if any.
  func matchLines(of guess: VerbSearch.Guess) -> [String] {
    guess.form.map { [$0.line(hiding: hiddenPersons)] } ?? []
  }

  // MARK: - Changes

  /// The field's text changed. A cleared field ends the search in progress, and a query that finds
  /// nothing plays the sad trombone, once per change of text.
  func setText(_ newText: String) {
    guard newText != text else {
      return
    }
    // The results still hold the ended search's matches, which its report reads.
    if let ended = tracker.textChanged(to: newText) {
      signalEnded(ended)
    }
    text = newText
    runSearch(textChanged: true)
  }

  /// The picker's choice. A sort is the full list's order; My Verbs keeps the last sort for later.
  func setListMode(_ mode: VerbListMode) {
    changingShown {
      listMode = mode
      if let newSort = mode.sort, newSort != sort {
        sort = newSort
        selection = nil
      }
    }
  }

  func setEngaged(_ engaged: Bool) {
    changingShown {
      isEngaged = engaged
    }
  }

  /// The field lost its focus with nothing typed, so a surface that opened it began no search.
  func fieldLostFocus() {
    tracker.fieldClosed()
  }

  /// The app went to the background, which ends a search left with text in the field.
  func appEnteredBackground() {
    if let ended = tracker.finish() {
      signalEnded(ended)
    }
  }

  /// The warm-up built the index. A search already shown runs again, now finding forms too, and
  /// a failure that was waiting for it plays the sad trombone if it is still a failure.
  func indexIsReady(_ index: ConjugationIndex) {
    guard self.index == nil else {
      return
    }
    self.index = index
    if isSearching {
      runSearch(textChanged: false)
    }
  }

  /// Command-F, the Find a Verb control and quick action, or a `search` link. Text that arrives with
  /// the request replaces the field's and begins a search from the request's source. Returns
  /// whether the field should take the keyboard: a request with no text, or blank text, is for
  /// typing; one with a query is for showing results, with the keyboard down.
  func request(_ request: SearchRequest) -> Bool {
    guard let requestedText = request.text else {
      return true
    }
    if let ended = tracker.fieldOpened(from: request.source) {
      signalEnded(ended)
    }
    let textChanged = requestedText != text
    text = requestedText
    // Unchanged text still begins a search from the request's source.
    _ = tracker.textChanged(to: requestedText)
    if textChanged {
      runSearch(textChanged: true)
    }
    return requestedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// A letter key's tap. On iPad a tap outside an empty search field ends the search, which clears
  /// its text as it goes, so a letter tapped while the field lacks focus must wait for the search to
  /// be gone. Returns true when this letter starts that wait; the caller then waits and calls
  /// `releaseWaitingLetters()`. Letters tapped during the wait join it, so that they arrive in the
  /// order they were tapped.
  func typeLetter(_ letter: String, fieldIsFocused: Bool) -> Bool {
    guard fieldIsFocused, waitingLetters.isEmpty else {
      let startsWait = waitingLetters.isEmpty
      waitingLetters += letter
      return startsWait
    }
    setText(text + letter)
    return false
  }

  func releaseWaitingLetters() {
    let letters = waitingLetters
    waitingLetters = ""
    setText(text + letters)
  }

  // MARK: - The keyboard

  /// The rows that Return and the arrow keys move through: the rows as listed, or the guess when a
  /// search found nothing. None while My Verbs shows, which has no highlight.
  var keyboardTargets: [String] {
    switch shown {
    case .myVerbs:
      return []
    case .results where results.isEmpty:
      return guess.map { [$0.entry.infinitive] } ?? []
    default:
      return rows.map(\.id)
    }
  }

  func moveSelection(by offset: Int) {
    let targets = keyboardTargets
    let current = selection.flatMap { targets.firstIndex(of: $0) }
    selection = Self.keyboardSelection(after: current, moving: offset, count: targets.count).map { targets[$0] }
  }

  /// The first arrow press lands on the first target, and the selection stops at either end rather
  /// than wrapping. Down moves in reading order, in the iPad's grid too.
  nonisolated static func keyboardSelection(after current: Int?, moving offset: Int, count: Int) -> Int? {
    guard count > 0 else {
      return nil
    }
    guard let current else {
      return offset > 0 ? 0 : nil
    }
    return min(max(current + offset, 0), count - 1)
  }

  /// What Return opens: the highlighted row or guess, on any keyboard. With nothing highlighted,
  /// `opensFirstResult` opens the first result, else the guess, as the iPad and the Mac do; the
  /// iPhone's Search key leaves it false and only lowers the keyboard, as it always has.
  func submit(opensFirstResult: Bool) -> VerbDestination? {
    let targets = keyboardTargets
    let target = selection.flatMap { targets.contains($0) ? $0 : nil } ?? (opensFirstResult && isSearching ? targets.first : nil)
    guard let target else {
      return nil
    }
    if let guess, results.isEmpty, guess.entry.infinitive == target {
      return openGuess(guess)
    }
    return rows.first { $0.id == target }.map(open)
  }

  // MARK: - Opening

  /// The page a row opens. A search's row reports the search, which this ends.
  func open(_ row: Row) -> VerbDestination {
    switch row.origin {
    case .everyVerb:
      return VerbDestination(infinitive: row.entry.infinitive, source: .browse)
    case .recent:
      return VerbDestination(infinitive: row.entry.infinitive, source: .recent)
    case let .result(match, position, resultCount):
      if let search = tracker.finish() {
        signal(.opened(query: search.query, source: search.source, resultCount: resultCount, kind: match.kind, position: position))
      }
      return VerbDestination(infinitive: row.entry.infinitive, source: .search, marks: marks(of: match.forms))
    }
  }

  func openGuess(_ guess: VerbSearch.Guess) -> VerbDestination {
    if let search = tracker.finish() {
      signal(.openedGuess(query: search.query, source: search.source))
    }
    return VerbDestination(infinitive: guess.entry.infinitive, source: .searchGuess, marks: marks(of: guess.form.map { [$0] } ?? []))
  }

  // MARK: - Private

  private var hiddenPersons: Set<DisplayPersonNumber> {
    settings.secondSingularBrowse.hiddenPersons
  }

  private func marks(of forms: [MatchedForm]) -> Set<ConjugationCell> {
    Set(MatchedForm.shown(forms, hiding: hiddenPersons).flatMap { $0.shownCells(hiding: hiddenPersons) })
  }

  /// Runs `change`, then clears the selection if what the list shows changed.
  private func changingShown(_ change: () -> Void) {
    let before = shown
    change()
    if shown != before {
      selection = nil
    }
  }

  /// Ranks the matches for the text. Search ignores the sort order, so the map's own order serves.
  private func runSearch(textChanged: Bool) {
    selection = nil
    guess = nil
    guard isSearching else {
      results = []
      failureAwaitsIndex = false
      return
    }
    let entries = VerbMap.shared.entriesByFrequency
    let matches = VerbSearch.matches(for: text, in: entries, index: index)
    results = matches.enumerated().map { position, match in
      Row(entry: match.entry, origin: .result(match, position: position, resultCount: matches.count))
    }
    guard matches.isEmpty else {
      failureAwaitsIndex = false
      return
    }
    guess = VerbSearch.guess(for: text, in: entries, index: index)
    if index == nil {
      failureAwaitsIndex = true
    } else if textChanged || failureAwaitsIndex {
      failureAwaitsIndex = false
      searchFailed()
    }
  }

  /// A search that ended with nothing opened: cleared, replaced, or left in the background. The
  /// results are still the ended search's.
  private func signalEnded(_ search: SearchTracker.Search) {
    signal(.ended(query: search.query, source: search.source, matches: results.compactMap(\.match)))
  }

  private func signal(_ report: SearchReport) {
    analytics.signal(name: .finishSearch, parameters: report.parameters)
  }
}
