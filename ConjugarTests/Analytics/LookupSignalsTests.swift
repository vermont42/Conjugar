//
//  LookupSignalsTests.swift
//  ConjugarTests
//
//  The lookup signals of the browse plan's Phase 2: `finishSearch`, `source` on `viewVerbView`,
//  and `leaveVerbView`. The bands, the search's lifecycle, each report's parameters, the visit,
//  and the wire names. Nonisolated, like the analytics family.
//

import Foundation
import Testing
@testable import Conjugar

@Suite("LookupSignals")
struct LookupSignalsTests {
  // MARK: - Wire names

  @Test func newSignalAndParameterNamesAreStable() {
    #expect(AnalyticsName.finishSearch.rawValue == "finishSearch")
    #expect(AnalyticsName.leaveVerbView.rawValue == "leaveVerbView")
    #expect(AnalyticsName.viewVerbView.rawValue == "viewVerbView")
    let keys: [ParameterKey] = [.deepestSection, .dwell, .matchKind, .outcome, .queryLength, .resultCount, .resultPosition, .source]
    #expect(keys.map(\.rawValue) == ["deepestSection", "dwell", "matchKind", "outcome", "queryLength", "resultCount", "resultPosition", "source"])
  }

  @Test func sourceValuesAreStable() {
    #expect(AnalyticsSource.allCases.map(\.rawValue) == [
      "browse", "control", "deeplink", "infoLink", "list", "lookup", "model", "myVerbs", "quickAction", "recent",
      "related", "resume", "reviewCard", "search", "searchGuess", "sharedLink", "shortcut", "spotlight", "tab",
      "verbPage", "widget"
    ])
  }

  @Test func sectionValuesAreStableAndOrderedDownThePage() {
    #expect(VerbPageSection.allCases.map(\.rawValue) == ["header", "simple", "compound", "etymology", "example"])
    #expect(VerbPageSection.allCases.sorted() == VerbPageSection.allCases)
  }

  /// The search's kinds go out under their own names, so a dashboard reads as the code does.
  @Test(arguments: VerbSearch.MatchKind.allCases)
  func matchKindIsSentByItsName(kind: VerbSearch.MatchKind) {
    #expect(kind.analyticsValue.rawValue == String(describing: kind))
  }

  @Test func everyMatchKindHasItsOwnValue() {
    let values = VerbSearch.MatchKind.allCases.map(\.analyticsValue)
    #expect(Set(values).count == values.count)
    #expect(!values.contains(.guess))
    #expect(!values.contains(.none))
  }

  // MARK: - Bands

  @Test(arguments: [(1, "1-2"), (2, "1-2"), (3, "3-5"), (5, "3-5"), (6, "6-9"), (9, "6-9"), (10, "10+"), (40, "10+")])
  func queryLengthBands(length: Int, band: String) {
    #expect(AnalyticsBand.queryLength(length) == band)
  }

  @Test(arguments: [(0, "0"), (1, "1"), (2, "2-10"), (10, "2-10"), (11, "11+"), (4811, "11+")])
  func resultCountBands(count: Int, band: String) {
    #expect(AnalyticsBand.resultCount(count) == band)
  }

  @Test(arguments: [(Int?.some(0), "1"), (1, "2-5"), (4, "2-5"), (5, "6+"), (300, "6+"), (nil, "none")])
  func resultPositionBands(index: Int?, band: String) {
    #expect(AnalyticsBand.resultPosition(index) == band)
  }

  @Test(arguments: [(0.0, "0-5s"), (4.9, "0-5s"), (5.0, "5-15s"), (14.9, "5-15s"), (15.0, "15-60s"), (59.9, "15-60s"), (60.0, "60s+"), (3600.0, "60s+")])
  func dwellBands(seconds: Double, band: String) {
    #expect(AnalyticsBand.dwell(seconds) == band)
  }

  // MARK: - The search's lifecycle

  @Test func aSearchBeginsWithTheFirstNonBlankLetter() {
    var tracker = SearchTracker()
    #expect(tracker.textChanged(to: "  ") == nil)
    #expect(tracker.query == nil)
    #expect(tracker.textChanged(to: " h") == nil)
    #expect(tracker.query == "h")
    #expect(tracker.textChanged(to: "hab") == nil)
    #expect(tracker.query == "hab")
  }

  @Test func clearingTheFieldEndsTheSearchOnce() {
    var tracker = SearchTracker()
    _ = tracker.textChanged(to: "hablr")
    #expect(tracker.textChanged(to: "") == SearchTracker.Search(query: "hablr", source: .tab))
    #expect(tracker.textChanged(to: "") == nil)
  }

  @Test func openingEndsTheSearchSoClearingAfterwardSendsNothing() {
    var tracker = SearchTracker()
    _ = tracker.textChanged(to: "tener")
    #expect(tracker.finish()?.query == "tener")
    // Back at the results, a second open is not a second search.
    #expect(tracker.finish() == nil)
    #expect(tracker.textChanged(to: "") == nil)
  }

  @Test func editingAfterAnOpenBeginsANewSearch() {
    var tracker = SearchTracker()
    _ = tracker.textChanged(to: "tener")
    _ = tracker.finish()
    _ = tracker.textChanged(to: "tene")
    #expect(tracker.finish()?.query == "tene")
  }

  // A search's source is the surface that opened the field, until the learner types into it.
  @Test func aSurfaceThatOpensTheFieldOwnsTheNextSearch() {
    var tracker = SearchTracker()
    #expect(tracker.fieldOpened(from: .control) == nil)
    _ = tracker.textChanged(to: "fue")
    _ = tracker.textChanged(to: "fuer")
    #expect(tracker.finish() == SearchTracker.Search(query: "fuer", source: .control))
    // The next search, begun in the tab, is the tab's.
    _ = tracker.textChanged(to: "ir")
    #expect(tracker.finish()?.source == .tab)
  }

  @Test func openingTheFieldEndsTheSearchInProgress() {
    var tracker = SearchTracker()
    _ = tracker.textChanged(to: "hab")
    #expect(tracker.fieldOpened(from: .deeplink) == SearchTracker.Search(query: "hab", source: .tab))
    _ = tracker.textChanged(to: "he hablado")
    #expect(tracker.query == "he hablado")
    #expect(tracker.finish()?.source == .deeplink)
  }

  @Test func aFieldClosedWithNothingTypedForgetsItsSurface() {
    var tracker = SearchTracker()
    _ = tracker.fieldOpened(from: .quickAction)
    tracker.fieldClosed()
    _ = tracker.textChanged(to: "tener")
    #expect(tracker.finish()?.source == .tab)
  }

  @Test func closingTheFieldKeepsATypedSearchsSurface() {
    var tracker = SearchTracker()
    _ = tracker.fieldOpened(from: .quickAction)
    _ = tracker.textChanged(to: "tener")
    tracker.fieldClosed()
    #expect(tracker.finish()?.source == .quickAction)
  }

  // MARK: - Reports

  @Test func anOpenedResultReportsItsKindAndPosition() {
    let report = SearchReport.opened(query: "come", source: .tab, resultCount: 12, kind: .exactGlossSense, position: 1)
    #expect(report.parameters == [
      "source": "tab",
      "outcome": "opened",
      "queryLength": "3-5",
      "resultCount": "11+",
      "matchKind": "exactGlossSense",
      "resultPosition": "2-5"
    ])
  }

  @Test func anOpenedGuessReportsNoResultsAndTheGuessKind() {
    let report = SearchReport.openedGuess(query: "hablr", source: .quickAction)
    #expect(report.parameters == [
      "source": "quickAction",
      "outcome": "opened",
      "queryLength": "3-5",
      "resultCount": "0",
      "matchKind": "guess",
      "resultPosition": "1"
    ])
  }

  @Test func anAbandonedSearchReportsTheTopResultsKind() {
    let matches = VerbSearch.matches(for: "sonar", in: VerbMap.shared.entries.values)
    let report = SearchReport.ended(query: "sonar", source: .tab, matches: matches)
    #expect(report.outcome == .abandoned)
    #expect(report.matchKind == .exactInfinitive)
    #expect(report.parameters["resultPosition"] == "none")
  }

  @Test func aSearchThatFoundNothingReportsNone() {
    let report = SearchReport.ended(query: "xyzzyq", source: .control, matches: [])
    #expect(report.parameters == [
      "source": "control",
      "outcome": "noResult",
      "queryLength": "6-9",
      "resultCount": "0",
      "matchKind": "none",
      "resultPosition": "none"
    ])
  }

  /// The policy promises that nothing typed is sent. Every value must come from a fixed
  /// vocabulary, whatever the query, including a query that is itself one of those values.
  @Test(arguments: ["hablar", "come", "opened", "none", "1-2", "guess", "ñ", "levantarse"])
  func noParameterCanEchoTheQuery(query: String) {
    let matches = VerbSearch.matches(for: query, in: VerbMap.shared.entries.values)
    let reports: [SearchReport] = [
      .ended(query: query, source: .deeplink, matches: matches),
      .openedGuess(query: query, source: .tab),
      .opened(query: query, source: .control, resultCount: matches.count, kind: matches.first?.kind ?? .glossSubstring, position: 0)
    ]
    let vocabulary = Set(SearchOutcome.allCases.map(\.rawValue) + SearchMatchKind.allCases.map(\.rawValue) + AnalyticsSource.allCases.map(\.rawValue))
      .union(["1-2", "3-5", "6-9", "10+", "0", "1", "2-10", "11+", "2-5", "6+", "none"])
    for report in reports {
      #expect(Set(report.parameters.keys) == ["source", "outcome", "queryLength", "resultCount", "matchKind", "resultPosition"])
      for value in report.parameters.values {
        #expect(vocabulary.contains(value))
      }
    }
  }

  // MARK: - Visits

  @Test func aVisitStartsAtTheHeaderAndOnlyGoesDeeper() {
    var visit = VerbVisit(source: .search, start: .now)
    #expect(visit.deepestSection == .header)
    visit.reach(.etymology)
    visit.reach(.simple)
    #expect(visit.deepestSection == .etymology)
  }

  @Test func aResumedVisitStartsFromTheDeepestSectionOnScreen() {
    let visit = VerbVisit(source: .resume, start: .now, visibleSections: [.simple, .compound])
    #expect(visit.deepestSection == .compound)
  }

  @Test func aVisitsParametersCarryItsSourceDepthAndDwell() {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    var visit = VerbVisit(source: .widget, start: start)
    visit.reach(.example)
    #expect(visit.viewParameters == ["source": "widget"])
    #expect(visit.leaveParameters(end: start.addingTimeInterval(20)) == ["deepestSection": "example", "dwell": "15-60s"])
  }

  /// The first card of each block marks its arrival, wherever the blocks sit on the page.
  @Test func theFirstCardOfEachBlockMarksItsSection() {
    #expect(VerbView.section(markedBy: .presenteDeIndicativo) == .simple)
    #expect(VerbView.section(markedBy: .perfectoDeIndicativo) == .compound)
    #expect(VerbView.section(markedBy: .pretérito) == nil)
    #expect(VerbView.section(markedBy: .futuroPerfecto) == nil)
    let marked = DisplayTense.conjugatedTenses.compactMap(VerbView.section(markedBy:))
    #expect(marked == [.simple, .compound])
  }

  @Test func onlyThePerfectTensesAreCompound() {
    let compound = DisplayTense.conjugatedTenses.filter(\.isCompound)
    #expect(compound.count == 9)
    #expect(!DisplayTense.imperativoNegativo.isCompound)
    #expect(!DisplayTense.presenteDeIndicativo.isCompound)
  }

  // MARK: - Sources in links

  @Test(arguments: [
    ("conjugar://verb/hablar?source=widget", AnalyticsSource?.some(.widget)),
    ("conjugar://verb/random?source=control", .control),
    ("conjugar://verb/random?source=shortcut", .shortcut),
    ("conjugar://verb/hablar", nil),
    ("conjugar://verb/hablar?source=nonsense", nil),
    ("conjugar://verb/hablar?other=widget", nil)
  ])
  func aLinkNamesItsSource(link: String, source: AnalyticsSource?) throws {
    #expect(try #require(URL(string: link)).analyticsSource == source)
  }
}
