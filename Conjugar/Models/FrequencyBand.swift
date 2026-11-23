//
//  FrequencyBand.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The frequency bands, defined once: the 100, 300, and 1,000 most frequent verbs. The verb of the
/// day and random verbs draw from the widest. Narrowest band first.
nonisolated enum FrequencyBand: Int, CaseIterable, Sendable {
  case top100 = 100
  case top300 = 300
  case top1000 = 1000

  var verbCount: Int {
    rawValue
  }
}

nonisolated extension VerbMapEntry {
  /// `frequencyRank` has no ties (`VerbMap.rankCount`), so a band holds exactly `verbCount` verbs.
  func isIn(_ band: FrequencyBand) -> Bool {
    frequencyRank <= band.verbCount
  }
}

nonisolated extension VerbMap {
  /// The band's verbs, the most frequent first.
  func entries(in band: FrequencyBand) -> [VerbMapEntry] {
    entries.values
      .filter { $0.isIn(band) }
      .sorted { $0.frequencyRank < $1.frequencyRank }
  }
}
