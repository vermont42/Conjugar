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

  static let spanish = Locale(identifier: "es")

  var localizedDisplayName: String {
    switch self {
    case .frequency:
      return Localizations.VerbSort.frequency
    case .alphabetical:
      return Localizations.VerbSort.alphabetical
    }
  }

  func areInIncreasingOrder(_ lhs: VerbMapEntry2, _ rhs: VerbMapEntry2) -> Bool {
    switch self {
    case .frequency:
      if lhs.frequencyRank == nil && rhs.frequencyRank == nil {
        return VerbSort.alphabetical.areInIncreasingOrder(lhs, rhs)
      } else if lhs.frequencyRank == nil && rhs.frequencyRank != nil {
        return false
      } else if lhs.frequencyRank != nil && rhs.frequencyRank == nil {
        return true
      } else {
        return (lhs.frequencyRank ?? 0) < (rhs.frequencyRank ?? 0)
      }
    case .alphabetical:
      return lhs.infinitive.compare(rhs.infinitive, locale: VerbSort.spanish) == .orderedAscending
    }
  }

  func sorted(_ entries: some Sequence<VerbMapEntry2>) -> [VerbMapEntry2] {
    entries.sorted(by: areInIncreasingOrder)
  }
}
