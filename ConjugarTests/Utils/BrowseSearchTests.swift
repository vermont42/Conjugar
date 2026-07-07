//
//  BrowseSearchTests.swift
//  ConjugarTests
//
//  Exercises the shared browse-filter seam: empty-query identity, matching,
//  no-match empties, and the case/diacritic-insensitive predicate the browse
//  screens use. `@MainActor` because BrowseSearch touches the @MainActor
//  SoundPlayer; all no-match cases pass `playSoundIfEmpty: false` to stay silent.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
@Suite struct BrowseSearchTests {
  private let items = ["ser", "estar", "haber", "tener", "está"]

  /// The predicate the browse screens use: case- and diacritic-insensitive substring.
  private func matches(_ item: String, _ query: String) -> Bool {
    item.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
  }

  @Test func emptyQueryReturnsInputUnchanged() {
    let result = BrowseSearch.results(in: items, query: "", playSoundIfEmpty: false, matches: matches)
    #expect(result == items)
  }

  @Test func whitespaceOnlyQueryReturnsInputUnchanged() {
    let result = BrowseSearch.results(in: items, query: "   ", playSoundIfEmpty: false, matches: matches)
    #expect(result == items)
  }

  @Test func matchingQueryReturnsOnlyMatches() {
    let result = BrowseSearch.results(in: items, query: "est", playSoundIfEmpty: false, matches: matches)
    #expect(result == ["estar", "está"])
  }

  @Test func noMatchReturnsEmpty() {
    let result = BrowseSearch.results(in: items, query: "zzz", playSoundIfEmpty: false, matches: matches)
    #expect(result.isEmpty)
  }

  @Test func matchIsCaseInsensitive() {
    let result = BrowseSearch.results(in: items, query: "SER", playSoundIfEmpty: false, matches: matches)
    #expect(result == ["ser"])
  }

  @Test func matchIsDiacriticInsensitive() {
    // `esta` (no accent) should find `está` (accented).
    let result = BrowseSearch.results(in: items, query: "esta", playSoundIfEmpty: false, matches: matches)
    #expect(result.contains("está"))
  }
}
