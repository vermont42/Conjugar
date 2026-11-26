//
//  VerbSort.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

enum VerbSort: String, ListSort {
  case frequency
  case alphabetical

  /// Spanish collation. Defined on `VerbMap`, which is `nonisolated` and needs it for the
  /// last tie-break in `ranked(_:)`; this enum is `@MainActor` like everything unannotated.
  static let spanish = VerbMap.spanish

  var localizedDisplayName: String {
    switch self {
    case .frequency:
      return L.VerbSort.frequency
    case .alphabetical:
      return L.VerbSort.alphabetical
    }
  }

  func areInIncreasingOrder(_ lhs: VerbMapEntry, _ rhs: VerbMapEntry) -> Bool {
    switch self {
    case .frequency:
      // Every verb has a rank, and ranks are distinct, so this is a total order on its own.
      return lhs.frequencyRank < rhs.frequencyRank
    case .alphabetical:
      return lhs.infinitive.compare(rhs.infinitive, locale: VerbSort.spanish) == .orderedAscending
    }
  }

  func sorted(_ entries: some Sequence<VerbMapEntry>) -> [VerbMapEntry] {
    entries.sorted(by: areInIncreasingOrder)
  }
}

extension VerbSort {
  /// Every verb of the map, in each order, sorted once: the Verbs tab's list, and the lists that
  /// `sortedLists(ofMapEntries:)` filters.
  static let mapLists = sortedLists(of: VerbMap.shared.entriesByFrequency)

  /// Above this many verbs, filtering `mapLists` beats sorting. Measured in a release build on
  /// 2026-11-26: sorting 25 verbs in Spanish collation took 0.13 ms, and 50 took 0.47 ms, while
  /// filtering the whole map took about 0.25 ms at any size; cantar's 3,000 verbs took 37 ms to
  /// sort and 0.5 ms to filter.
  static let filteringThreshold = 32

  /// Verbs of the bundled map in every order, as `sortedLists(of:)` gives them. A long list is
  /// filtered out of `mapLists`, which keeps its order, rather than sorted.
  static func sortedLists(ofMapEntries entries: [VerbMapEntry]) -> [VerbSort: [VerbMapEntry]] {
    guard entries.count > filteringThreshold else {
      return sortedLists(of: entries)
    }
    let infinitives = Set(entries.map(\.infinitive))
    return mapLists.mapValues { list in
      list.filter { infinitives.contains($0.infinitive) }
    }
  }
}
