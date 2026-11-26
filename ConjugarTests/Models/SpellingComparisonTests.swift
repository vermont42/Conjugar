//
//  SpellingComparisonTests.swift
//  ConjugarTests
//
//  Pins folding and the edit distance that the verb search and the quiz share.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct SpellingComparisonTests {
  @Test func foldingDropsCaseAccentsAndTilde() {
    #expect(SpellingComparison.fold("Añadir") == "anadir")
    #expect(SpellingComparison.fold("REÍR") == "reir")
    #expect(SpellingComparison.fold("argüir") == "arguir")
  }

  @Test(arguments: [
    ("hablar", "hablar", 0),
    ("hablr", "hablar", 1),
    ("hbalar", "hablar", 1),
    ("kitten", "sitting", 3),
    ("", "abc", 3),
    ("abc", "", 3)
  ])
  func editDistanceCountsASwapAsOneEdit(lhs: String, rhs: String, expected: Int) {
    #expect(SpellingComparison.editDistance(Array(lhs), Array(rhs)) == expected)
  }

  /// The limited distance is the unlimited one wherever that is within the limit, over characters
  /// and over a folded form's bytes alike, and nil wherever it is not.
  @Test func theLimitedDistanceAgreesWithTheUnlimitedOne() {
    let words = ["hablar", "hablr", "hbalar", "haber", "tener", "tenjo", "tengo", "añadir", "anadir", "", "a", "ir", "oír", "reír", "kitten", "sitting"]
    for lhs in words {
      for rhs in words {
        let distance = SpellingComparison.editDistance(Array(lhs), Array(rhs))
        for limit in 0...4 {
          let limited = SpellingComparison.editDistance(Array(lhs), Array(rhs), limit: limit)
          #expect(limited == (distance <= limit ? distance : nil), "\(lhs) \(rhs) \(limit)")
          let folded = (Array(SpellingComparison.fold(lhs).utf8), Array(SpellingComparison.fold(rhs).utf8))
          let foldedDistance = SpellingComparison.editDistance(folded.0, folded.1)
          #expect(SpellingComparison.editDistance(folded.0, folded.1, limit: limit) == (foldedDistance <= limit ? foldedDistance : nil), "\(lhs) \(rhs) \(limit)")
        }
      }
    }
  }
}
