//
//  VerbBrowseSearchTests.swift
//  ConjugarTests
//
//  The Verbs tab's search model: what the list shows, the keyboard's selection and Return, the
//  reports each open and each ended search send, the search before the index is built, a
//  requested search, and the letter row's order.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct VerbBrowseSearchTests {
  private let analytics = AnalyticsSpy()
  private let learnerVerbs = LearnerVerbStore(getterSetter: GetterSetterFake())
  private let failures = FailureCounter()

  /// Counts the sad trombones.
  private final class FailureCounter {
    var count = 0
  }

  private func makeSearch(index: ConjugationIndex? = .bundled, recents: [String] = []) -> VerbBrowseSearch {
    let start = Date(timeIntervalSinceReferenceDate: 0)
    for (offset, infinitive) in recents.reversed().enumerated() {
      learnerVerbs.recordOpen(infinitive, at: start.addingTimeInterval(Double(offset)))
    }
    let failures = failures
    return VerbBrowseSearch(
      sort: .frequency,
      index: index,
      learnerVerbs: learnerVerbs,
      settings: Settings(getterSetter: GetterSetterFake()),
      analytics: analytics,
      searchFailed: { failures.count += 1 }
    )
  }

  private func infinitives(_ rows: [VerbBrowseSearch.Row]) -> [String] {
    rows.map(\.id)
  }

  private var reports: [[String: String]] {
    zip(analytics.signalNames, analytics.signalParameters).filter { $0.0 == .finishSearch }.map(\.1)
  }

  // MARK: - What the list shows

  @Test func nothingTypedShowsEveryVerbInTheSortOrder() {
    let search = makeSearch()
    #expect(search.shown == .everyVerb)
    #expect(infinitives(search.rows) == VerbSort.mapLists[.frequency]?.map(\.infinitive))
    search.setListMode(.alphabetical)
    #expect(search.sort == .alphabetical)
    #expect(infinitives(search.rows) == VerbSort.mapLists[.alphabetical]?.map(\.infinitive))
  }

  @Test func typingShowsTheRankedResults() {
    let search = makeSearch()
    search.setText("hablo")
    #expect(search.shown == .results)
    #expect(search.rows.first?.id == "hablar")
    #expect(search.matchLines(of: search.rows[0]).first?.hasPrefix("hablo:") == true)
    #expect(failures.count == 0)
  }

  @Test func clearingTheFieldEndsTheSearchAndShowsEveryVerb() {
    let search = makeSearch()
    search.setText("hablo")
    let shownMatches = search.results.compactMap(\.match)
    search.setText("")
    #expect(search.shown == .everyVerb)
    #expect(search.results.isEmpty)
    #expect(reports == [SearchReport.ended(query: "hablo", source: .tab, matches: shownMatches).parameters])
  }

  /// A space alone hides nothing and filters nothing: the tip, the card, and the full list stay.
  @Test func aSpaceAloneIsNotASearch() {
    let search = makeSearch()
    search.setText(" ")
    #expect(!search.isSearching)
    #expect(search.shown == .everyVerb)
    #expect(search.rows.count == VerbMap.shared.entries.count)
    #expect(failures.count == 0)
  }

  @Test func aFailedSearchOffersAGuessAndPlaysTheTromboneOnce() {
    let search = makeSearch()
    search.setText("hablr")
    #expect(search.hasFailed)
    #expect(!search.awaitsIndex)
    #expect(search.guess?.entry.infinitive == "hablar")
    #expect(failures.count == 1)
    search.setListMode(.alphabetical)
    search.setListMode(.myVerbs)
    #expect(failures.count == 1)
    search.setText("xyzzyq")
    #expect(search.guess == nil)
    #expect(failures.count == 2)
    search.setText("")
    #expect(reports.last?[ParameterKey.outcome.rawValue] == SearchOutcome.noResult.rawValue)
  }

  @Test func theFocusedEmptyFieldShowsTheRecents() {
    let search = makeSearch(recents: ["tener", "hablar"])
    search.setEngaged(true)
    #expect(search.shown == .recents)
    #expect(infinitives(search.rows) == ["tener", "hablar"])
    search.setText("ven")
    #expect(search.shown == .results)
  }

  @Test func withNoRecentsTheFocusedFieldKeepsTheList() {
    let search = makeSearch()
    search.setEngaged(true)
    #expect(search.shown == .everyVerb)
  }

  @Test func myVerbsShowsWithNothingTypedAndHasNoKeyboardTargets() {
    let search = makeSearch()
    search.setListMode(.myVerbs)
    #expect(search.shown == .myVerbs)
    #expect(search.rows.isEmpty)
    search.setEngaged(true)
    #expect(search.shown == .myVerbs)
    #expect(search.keyboardTargets.isEmpty)
    search.moveSelection(by: 1)
    #expect(search.selection == nil)
    #expect(search.submit(opensFirstResult: true) == nil)
    search.setText("tener")
    #expect(search.shown == .results)
  }

  @Test func theRecentsShowOverMyVerbsWhileTheFieldIsFocused() {
    let search = makeSearch(recents: ["tener"])
    search.setListMode(.myVerbs)
    search.setEngaged(true)
    #expect(search.shown == .recents)
    search.setEngaged(false)
    #expect(search.shown == .myVerbs)
  }

  // MARK: - The keyboard

  @Test func theFirstDownLandsOnTheFirstResult() {
    #expect(VerbBrowseSearch.keyboardSelection(after: nil, moving: 1, count: 5) == 0)
  }

  @Test func theFirstUpSelectsNothing() {
    #expect(VerbBrowseSearch.keyboardSelection(after: nil, moving: -1, count: 5) == nil)
  }

  @Test func theSelectionStopsAtEitherEnd() {
    #expect(VerbBrowseSearch.keyboardSelection(after: 4, moving: 1, count: 5) == 4)
    #expect(VerbBrowseSearch.keyboardSelection(after: 0, moving: -1, count: 5) == 0)
    #expect(VerbBrowseSearch.keyboardSelection(after: 2, moving: 1, count: 5) == 3)
  }

  @Test func noResultsMeansNoSelection() {
    #expect(VerbBrowseSearch.keyboardSelection(after: nil, moving: 1, count: 0) == nil)
    #expect(VerbBrowseSearch.keyboardSelection(after: 3, moving: 1, count: 0) == nil)
  }

  @Test func theSelectionIsAVerbThatMovesThroughTheShownRows() {
    let search = makeSearch(recents: ["tener", "hablar", "ir"])
    search.setEngaged(true)
    search.moveSelection(by: 1)
    #expect(search.selection == "tener")
    search.moveSelection(by: 1)
    #expect(search.selection == "hablar")
    search.moveSelection(by: -1)
    #expect(search.selection == "tener")
  }

  /// Esc lets the recents go 700 ms later; the highlight must not land on the full list's second verb.
  @Test func theSelectionClearsWhenTheRecentsGo() {
    let search = makeSearch(recents: ["tener", "hablar"])
    search.setEngaged(true)
    search.moveSelection(by: 1)
    search.moveSelection(by: 1)
    search.setEngaged(false)
    #expect(search.selection == nil)
  }

  @Test func theSelectionClearsOnASortChange() {
    let search = makeSearch()
    search.moveSelection(by: 1)
    search.moveSelection(by: 1)
    #expect(search.selection == VerbSort.mapLists[.frequency]?[1].infinitive)
    search.setListMode(.alphabetical)
    #expect(search.selection == nil)
  }

  @Test func theSelectionClearsWhenTheTextChanges() {
    let search = makeSearch()
    search.setText("ten")
    search.moveSelection(by: 1)
    #expect(search.selection != nil)
    search.setText("tene")
    #expect(search.selection == nil)
  }

  @Test func theSelectionClearsWhenTheIndexArrives() {
    let search = makeSearch(index: nil)
    search.setText("ten")
    search.moveSelection(by: 1)
    #expect(search.selection != nil)
    search.indexIsReady(.bundled)
    #expect(search.selection == nil)
  }

  @Test func theSelectionStaysWhenTheEngagementLeavesTheListAlone() {
    let search = makeSearch()
    search.moveSelection(by: 1)
    search.setEngaged(true)
    #expect(search.selection == VerbSort.mapLists[.frequency]?.first?.infinitive)
  }

  /// On any keyboard, the iPhone's included, Return opens a highlighted row.
  @Test func returnOpensTheHighlightedRowOnAnyKeyboard() {
    let search = makeSearch()
    search.setText("ten")
    search.moveSelection(by: 1)
    search.moveSelection(by: 1)
    let second = search.rows[1].id
    #expect(search.submit(opensFirstResult: false)?.infinitive == second)
  }

  @Test func returnWithNothingHighlightedOpensTheFirstResultOnlyOnTheIPad() {
    let search = makeSearch()
    search.setText("ten")
    #expect(search.submit(opensFirstResult: false) == nil)
    #expect(search.submit(opensFirstResult: true)?.infinitive == search.rows[0].id)
  }

  @Test func returnWithNothingTypedOpensOnlyAHighlightedRow() {
    let search = makeSearch()
    #expect(search.submit(opensFirstResult: true) == nil)
    search.moveSelection(by: 1)
    #expect(search.submit(opensFirstResult: true) == VerbDestination(infinitive: "ser", source: .browse))
  }

  @Test func returnOpensTheGuessWhenNothingMatched() {
    let search = makeSearch()
    search.setText("hablr")
    #expect(search.keyboardTargets == ["hablar"])
    #expect(search.submit(opensFirstResult: true)?.source == .searchGuess)
    let other = makeSearch()
    other.setText("hablr")
    other.moveSelection(by: 1)
    #expect(other.selection == "hablar")
    #expect(other.submit(opensFirstResult: false)?.infinitive == "hablar")
  }

  // MARK: - Opening

  @Test func openingAResultReportsItsPlaceAndMarksItsForms() throws {
    let search = makeSearch()
    search.setText("hablo")
    let row = search.rows[0]
    let destination = search.open(row)
    #expect(destination.source == .search)
    #expect(destination.infinitive == "hablar")
    #expect(!destination.marks.isEmpty)
    let match = try #require(row.match)
    #expect(reports == [SearchReport.opened(query: "hablo", source: .tab, resultCount: search.results.count, kind: match.kind, position: 0).parameters])
  }

  /// The row carries what it was drawn with, so a tap whose text has since changed opens it anyway.
  @Test func aRowOpensAsItWasDrawn() {
    let search = makeSearch(recents: ["tener"])
    search.setEngaged(true)
    let recent = search.rows[0]
    search.setEngaged(false)
    #expect(search.open(recent) == VerbDestination(infinitive: "tener", source: .recent))
  }

  @Test func openingTheGuessReportsIt() throws {
    let search = makeSearch()
    search.setText("hablr")
    let destination = search.openGuess(try #require(search.guess))
    #expect(destination.source == .searchGuess)
    #expect(reports == [SearchReport.openedGuess(query: "hablr", source: .tab).parameters])
  }

  @Test func aSearchIsReportedOnce() {
    let search = makeSearch()
    search.setText("hablo")
    _ = search.open(search.rows[0])
    _ = search.open(search.rows[0])
    search.setText("")
    #expect(reports.count == 1)
  }

  @Test func theBackgroundEndsASearch() {
    let search = makeSearch()
    search.setText("xyzzyq")
    search.appEnteredBackground()
    #expect(reports == [SearchReport.ended(query: "xyzzyq", source: .tab, matches: []).parameters])
  }

  // MARK: - Before the index

  @Test func aSearchBeforeTheIndexFindsInfinitivesAndGlossesThenForms() {
    let search = makeSearch(index: nil)
    search.setText("fue")
    #expect(!infinitives(search.results).contains("ser"))
    search.setText("hablar")
    #expect(search.rows.first?.id == "hablar")
    search.setText("speak")
    #expect(search.rows.first?.id == "hablar")
    search.setText("fue")
    search.indexIsReady(.bundled)
    #expect(Array(infinitives(search.results).prefix(2)) == ["ser", "ir"])
  }

  /// A failure before the index may be a form, so the trombone waits for the index to say.
  @Test func aFailureBeforeTheIndexPlaysTheTromboneOnlyIfItStaysAFailure() {
    let failing = makeSearch(index: nil)
    failing.setText("xyzzyq")
    #expect(failing.awaitsIndex)
    #expect(failures.count == 0)
    failing.indexIsReady(.bundled)
    #expect(!failing.awaitsIndex)
    #expect(failing.hasFailed)
    #expect(failures.count == 1)
  }

  @Test func aFormFoundOnceTheIndexArrivesPlaysNoTrombone() {
    let search = makeSearch(index: nil)
    search.setText("fuimos")
    #expect(search.awaitsIndex)
    search.indexIsReady(.bundled)
    #expect(!search.hasFailed)
    #expect(failures.count == 0)
  }

  // MARK: - A requested search

  @Test func aRequestWithTextShowsResultsWithTheKeyboardDown() {
    let search = makeSearch()
    let wantsKeyboard = search.request(SearchRequest(text: "fue", source: .deeplink))
    #expect(!wantsKeyboard)
    #expect(search.text == "fue")
    #expect(Array(infinitives(search.rows).prefix(2)) == ["ser", "ir"])
    _ = search.open(search.rows[0])
    #expect(reports.first?[ParameterKey.source.rawValue] == AnalyticsSource.deeplink.rawValue)
  }

  @Test func aRequestWithoutTextIsForTyping() {
    let search = makeSearch()
    search.setText("ten")
    #expect(search.request(SearchRequest(text: nil, source: .tab)))
    #expect(search.text == "ten")
    #expect(reports.isEmpty)
    #expect(search.request(SearchRequest(text: "", source: .control)))
    #expect(search.text.isEmpty)
  }

  @Test func aRequestEndsTheSearchItReplaces() {
    let search = makeSearch()
    search.setText("hablo")
    let shownMatches = search.results.compactMap(\.match)
    _ = search.request(SearchRequest(text: "fue", source: .quickAction))
    #expect(reports == [SearchReport.ended(query: "hablo", source: .tab, matches: shownMatches).parameters])
  }

  /// The same text again still begins a search from the request's source.
  @Test func aRequestForTheSameTextTakesTheRequestsSource() {
    let search = makeSearch()
    _ = search.request(SearchRequest(text: "fue", source: .deeplink))
    search.setText("")
    _ = search.request(SearchRequest(text: "fue", source: .control))
    _ = search.request(SearchRequest(text: "fue", source: .quickAction))
    _ = search.open(search.rows[0])
    #expect(reports.last?[ParameterKey.source.rawValue] == AnalyticsSource.quickAction.rawValue)
  }

  // MARK: - The letter row

  @Test func aLetterTypedIntoTheFocusedFieldArrivesAtOnce() {
    let search = makeSearch()
    #expect(!search.typeLetter("ñ", fieldIsFocused: true))
    #expect(search.text == "ñ")
  }

  /// On iPad two quick taps used to arrive reversed, or one was lost.
  @Test func lettersThatWaitArriveInTheOrderTapped() {
    let search = makeSearch()
    #expect(search.typeLetter("á", fieldIsFocused: false))
    #expect(!search.typeLetter("é", fieldIsFocused: false))
    #expect(!search.typeLetter("í", fieldIsFocused: true))
    #expect(search.text.isEmpty)
    search.releaseWaitingLetters()
    #expect(search.text == "áéí")
    #expect(!search.typeLetter("ñ", fieldIsFocused: true))
    #expect(search.text == "áéíñ")
  }
}
