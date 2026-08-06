//
//  BrowseSearchTests.swift
//  ConjugarTests
//
//  Exercises the shared browse-filter seam: empty-query identity, matching,
//  no-match empties, and the case/diacritic-insensitive predicate the browse
//  screens use. Because `BrowseSearch.results` is a pure function (the
//  no-results sound moved to the callers' `.onChange` handlers), this suite is
//  nonisolated and needs no `playSoundIfEmpty` argument.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct BrowseSearchTests {
  private let items = ["ser", "estar", "haber", "tener", "está"]

  /// The predicate the browse screens use: case- and diacritic-insensitive substring.
  private func matches(_ item: String, _ query: String) -> Bool {
    item.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
  }

  @Test func emptyQueryReturnsInputUnchanged() {
    let result = BrowseSearch.results(in: items, query: "", matches: matches)
    #expect(result == items)
  }

  @Test func whitespaceOnlyQueryReturnsInputUnchanged() {
    let result = BrowseSearch.results(in: items, query: "   ", matches: matches)
    #expect(result == items)
  }

  @Test func matchingQueryReturnsOnlyMatches() {
    let result = BrowseSearch.results(in: items, query: "est", matches: matches)
    #expect(result == ["estar", "está"])
  }

  @Test func noMatchReturnsEmpty() {
    let result = BrowseSearch.results(in: items, query: "zzz", matches: matches)
    #expect(result.isEmpty)
  }

  @Test func matchIsCaseInsensitive() {
    let result = BrowseSearch.results(in: items, query: "SER", matches: matches)
    #expect(result == ["ser"])
  }

  @Test func matchIsDiacriticInsensitive() {
    // `esta` (no accent) should find `está` (accented).
    let result = BrowseSearch.results(in: items, query: "esta", matches: matches)
    #expect(result.contains("está"))
  }
}
