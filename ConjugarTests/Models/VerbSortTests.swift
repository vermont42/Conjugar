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

  /// The lists a page keeps so that changing the order sorts nothing: one per order, each the same
  /// verbs as that order's own sort.
  @Test func sortedListsHoldEveryOrderOnce() {
    let entries = [entry("obrar", rank: 3), entry("ñoñear", rank: 1), entry("nadar", rank: 2)]
    let lists = VerbSort.sortedLists(of: entries)
    #expect(Set(lists.keys) == Set(VerbSort.allCases))
    for sort in VerbSort.allCases {
      #expect(lists[sort]?.map(\.infinitive) == sort.sorted(entries).map(\.infinitive))
    }
  }

  /// A long list is filtered out of the map's presorted lists and a short one is sorted, and either
  /// way the lists are those that sorting gives.
  @Test func filteredListsMatchSortedOnes() {
    let all = VerbMap.shared.entriesByFrequency
    let lists = [
      Array(all.prefix(5)),
      all.filter { $0.classNumber == "1" },
      Array(all.prefix(VerbSort.filteringThreshold + 1).reversed()),
      ModelInfo.byClassNumber["31"]?.verbs ?? []
    ]
    for entries in lists {
      let expected = VerbSort.sortedLists(of: entries)
      let derived = VerbSort.sortedLists(ofMapEntries: entries)
      for sort in VerbSort.allCases {
        #expect(derived[sort]?.map(\.infinitive) == expected[sort]?.map(\.infinitive), "\(entries.count) \(sort)")
      }
    }
  }
}
