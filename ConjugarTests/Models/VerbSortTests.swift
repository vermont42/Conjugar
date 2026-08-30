//
//  VerbSortTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

@MainActor
struct VerbSortTests {
  private func entry(_ infinitive: String, rank: Int) -> VerbMapEntry {
    VerbMapEntry(
      infinitive: infinitive,
      classNumbers: ["1"],
      glosses: ["gloss"],
      isReflexive: false,
      hits: 0,
      bookHits: nil,
      hitsAreProvisional: false,
      frequencyRank: rank
    )
  }

  @Test func frequencySortOrdersByRank() {
    let entries = [
      entry("zurcir", rank: 4811), entry("hablar", rank: 2), entry("amar", rank: 300),
      entry("ser", rank: 1), entry("comer", rank: 10)
    ]
    let sorted = VerbSort.frequency.sorted(entries).map(\.infinitive)
    #expect(sorted == ["ser", "hablar", "comer", "amar", "zurcir"])
  }

  @Test func alphabeticalSortUsesSpanishCollation() {
    // In Spanish collation, ñ is a distinct letter between n and o; a plain
    // code-point compare would put "ñoñear" after "obrar".
    let entries = [entry("obrar", rank: 1), entry("ñoñear", rank: 2), entry("nadar", rank: 3)]
    let sorted = VerbSort.alphabetical.sorted(entries).map(\.infinitive)
    #expect(sorted == ["nadar", "ñoñear", "obrar"])
  }

  @Test func frequencySortOfVerbMapStartsWithSer() {
    let sorted = VerbSort.frequency.sorted(VerbMap.shared.entries.values)
    #expect(sorted.count == VerbMap.shared.count)
    #expect(sorted.first?.infinitive == "ser")
    #expect(sorted.first?.frequencyRank == 1)
    // Every verb is ranked now, so the sort runs the whole map end to end.
    #expect(sorted.last?.frequencyRank == VerbMap.shared.rankCount)
  }
}
