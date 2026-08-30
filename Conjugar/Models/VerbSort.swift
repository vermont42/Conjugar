//
//  VerbSort.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

enum VerbSort: String, CaseIterable {
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
