//
//  VerbSortTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

struct VerbSortTests {
  private func entry(_ infinitive: String, rank: Int? = nil) -> VerbMapEntry2 {
    VerbMapEntry2(infinitive: infinitive, classNumbers: ["1"], glosses: ["gloss"], isReflexive: false, frequencyRank: rank)
  }

  @Test func frequencySortPutsRankedVerbsFirstInRankOrder() {
    let entries = [entry("zurcir"), entry("hablar", rank: 2), entry("amar"), entry("ser", rank: 1), entry("comer", rank: 10)]
    let sorted = VerbSort.frequency.sorted(entries).map(\.infinitive)
    #expect(sorted == ["ser", "hablar", "comer", "amar", "zurcir"])
  }

  @Test func frequencySortAlphabetizesUnrankedVerbsAmongThemselves() {
    let entries = [entry("zurcir"), entry("amar"), entry("nadar")]
    let sorted = VerbSort.frequency.sorted(entries).map(\.infinitive)
    #expect(sorted == ["amar", "nadar", "zurcir"])
  }

  @Test func alphabeticalSortUsesSpanishCollation() {
    // In Spanish collation, ñ is a distinct letter between n and o; a plain
    // code-point compare would put "ñoñear" after "obrar".
    let entries = [entry("obrar"), entry("ñoñear"), entry("nadar")]
    let sorted = VerbSort.alphabetical.sorted(entries).map(\.infinitive)
    #expect(sorted == ["nadar", "ñoñear", "obrar"])
  }

  @Test func frequencySortOfVerbMapStartsWithSer() {
    let sorted = VerbSort.frequency.sorted(VerbMap2.shared.entries.values)
    #expect(sorted.count == VerbMap2.shared.count)
    #expect(sorted.first?.infinitive == "ser")
    #expect(sorted.first?.frequencyRank == 1)
    #expect(sorted.last?.frequencyRank == nil)
  }
}
