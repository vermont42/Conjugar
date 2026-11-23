//
//  SearchReport.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Follows one search from its first letter until it ends, so that `finishSearch` is sent once
/// per search. A search ends when a result or the guess is opened, when the field is cleared, or
/// when the app leaves the foreground with text in the field. Returning to the results and opening
/// another verb from the same text is not a new search; editing the text is.
///
/// A search's source is the surface that opened the field for it: the Find a Verb control, the
/// quick action, or a `search` link. A search the learner began in the Verbs tab, Command-F
/// included, is `tab`.
nonisolated struct SearchTracker: Sendable {
  struct Search: Equatable, Sendable {
    /// Trimmed. Kept on the device: only its length, banded, is ever sent.
    let query: String
    let source: AnalyticsSource
  }

  private(set) var search: Search?
  /// The surface that opened the field, until a letter begins its search or the field closes.
  private var nextSource: AnalyticsSource?

  /// The query of the search in progress.
  var query: String? {
    search?.query
  }

  /// The search that this change ended by clearing the field, if it ended one.
  mutating func textChanged(to text: String) -> Search? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty else {
      search = Search(query: trimmed, source: search?.source ?? nextSource ?? .tab)
      nextSource = nil
      return nil
    }
    return finish()
  }

  /// Another surface opened the field, so the next search is that surface's. A search in
  /// progress ends here, because the text it was typed into is about to be replaced.
  mutating func fieldOpened(from source: AnalyticsSource) -> Search? {
    let ended = finish()
    nextSource = source
    return ended
  }

  /// The field closed with nothing typed, so the surface that opened it began no search.
  mutating func fieldClosed() {
    if search == nil {
      nextSource = nil
    }
  }

  /// The search in progress, which this call ends.
  mutating func finish() -> Search? {
    defer {
      search = nil
    }
    return search
  }
}

/// The parameters of one `finishSearch` signal. Every value comes from a fixed vocabulary or a
/// band, so nothing typed leaves the device.
nonisolated struct SearchReport: Equatable, Sendable {
  /// Where the search began. See `SearchTracker`.
  let source: AnalyticsSource
  let outcome: SearchOutcome
  let queryLength: Int
  let resultCount: Int
  let matchKind: SearchMatchKind
  /// Counts from zero, as the list does. Nil when nothing was opened.
  let resultPosition: Int?

  static func opened(query: String, source: AnalyticsSource, resultCount: Int, kind: VerbSearch.MatchKind, position: Int) -> SearchReport {
    SearchReport(source: source, outcome: .opened, queryLength: query.count, resultCount: resultCount, matchKind: kind.analyticsValue, resultPosition: position)
  }

  /// The guess appears only when nothing matched, so its count is zero and its position first.
  static func openedGuess(query: String, source: AnalyticsSource) -> SearchReport {
    SearchReport(source: source, outcome: .opened, queryLength: query.count, resultCount: 0, matchKind: .guess, resultPosition: 0)
  }

  /// A search that ended without a verb opened. Its match kind is the top result's, which says
  /// what the learner saw first and passed over.
  static func ended(query: String, source: AnalyticsSource, matches: [VerbSearch.Match]) -> SearchReport {
    SearchReport(
      source: source,
      outcome: matches.isEmpty ? .noResult : .abandoned,
      queryLength: query.count,
      resultCount: matches.count,
      matchKind: matches.first?.kind.analyticsValue ?? .none,
      resultPosition: nil
    )
  }

  var parameters: [String: String] {
    [
      ParameterKey.source.rawValue: source.rawValue,
      ParameterKey.outcome.rawValue: outcome.rawValue,
      ParameterKey.queryLength.rawValue: AnalyticsBand.queryLength(queryLength),
      ParameterKey.resultCount.rawValue: AnalyticsBand.resultCount(resultCount),
      ParameterKey.matchKind.rawValue: matchKind.rawValue,
      ParameterKey.resultPosition.rawValue: AnalyticsBand.resultPosition(resultPosition)
    ]
  }
}

nonisolated extension VerbSearch.MatchKind {
  /// An exhaustive switch, so that a match kind added to the search cannot go unnamed here.
  var analyticsValue: SearchMatchKind {
    switch self {
    case .exactInfinitive:
      return .exactInfinitive
    case .exactFoldedInfinitive:
      return .exactFoldedInfinitive
    case .exactGlossSense:
      return .exactGlossSense
    case .conjugation:
      return .conjugation
    case .foldedConjugation:
      return .foldedConjugation
    case .infinitivePrefix:
      return .infinitivePrefix
    case .wholeWordGloss:
      return .wholeWordGloss
    case .infinitiveSubstring:
      return .infinitiveSubstring
    case .foldedInfinitivePrefix:
      return .foldedInfinitivePrefix
    case .foldedInfinitiveSubstring:
      return .foldedInfinitiveSubstring
    case .glossSubstring:
      return .glossSubstring
    }
  }
}
