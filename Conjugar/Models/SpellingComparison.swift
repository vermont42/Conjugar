//
//  SpellingComparison.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// How far apart two spellings are, for the verb search, the quiz's grading, and its corrections.
/// `AnswerDifference` keeps a distance of its own, since it needs the alignment as well as the
/// count.
nonisolated enum SpellingComparison {
  /// Case and every diacritic folded away, ñ to n included, so that a learner without a Spanish
  /// keyboard finds añadir by typing anadir. For matching only: never render it.
  static func fold(_ text: String) -> String {
    text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
  }

  /// Optimal-string-alignment distance: insertions, deletions, substitutions, and swaps of two
  /// adjacent letters each cost one, because a swap is the commonest slip on a keyboard (hbalar
  /// for hablar).
  static func editDistance<Element: Equatable>(_ lhs: [Element], _ rhs: [Element]) -> Int {
    // No alignment costs more than Int.max, so this never gives up; the fallback is the distance
    // of two strings that share nothing.
    editDistance(lhs, rhs, limit: .max) ?? max(lhs.count, rhs.count)
  }

  /// `editDistance(_:_:)`, giving up once every alignment costs more than `limit`. Nil past the
  /// limit. The search's guess calls this over the bytes of thousands of folded forms per
  /// keystroke, so giving up early matters.
  static func editDistance<Element: Equatable>(_ lhs: [Element], _ rhs: [Element], limit: Int) -> Int? {
    guard abs(lhs.count - rhs.count) <= limit else {
      return nil
    }
    guard !lhs.isEmpty, !rhs.isEmpty else {
      return max(lhs.count, rhs.count)
    }
    var twoRowsBack = [Int](repeating: 0, count: rhs.count + 1)
    var previousRow = Array(0...rhs.count)
    var currentRow = [Int](repeating: 0, count: rhs.count + 1)
    for i in 1...lhs.count {
      currentRow[0] = i
      var rowMinimum = i
      for j in 1...rhs.count {
        let substitutionCost = lhs[i - 1] == rhs[j - 1] ? 0 : 1
        currentRow[j] = min(previousRow[j] + 1, currentRow[j - 1] + 1, previousRow[j - 1] + substitutionCost)
        if i > 1, j > 1, lhs[i - 1] == rhs[j - 2], lhs[i - 2] == rhs[j - 1] {
          currentRow[j] = min(currentRow[j], twoRowsBack[j - 2] + 1)
        }
        rowMinimum = min(rowMinimum, currentRow[j])
      }
      if rowMinimum > limit {
        return nil
      }
      (twoRowsBack, previousRow, currentRow) = (previousRow, currentRow, twoRowsBack)
    }
    let distance = previousRow[rhs.count]
    return distance <= limit ? distance : nil
  }
}
