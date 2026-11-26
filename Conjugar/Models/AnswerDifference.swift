//
//  AnswerDifference.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Where a wrong answer differs from the right one, letter by letter: the letters of the
/// learner's answer that are wrong or extra, and the letters of the right answer that were
/// missing or wrong. A missing letter has nothing in the learner's answer to mark, so it is
/// marked only in the right answer. An accent is a letter of its own here, so hablo against habló
/// marks the o.
nonisolated struct AnswerDifference: Equatable, Sendable {
  /// The learner's answer, as the quiz records it.
  let given: String
  /// One flag per `Character` of `given`.
  let givenMarks: [Bool]
  /// The right answer, irregularity-marked, so that its red letters can still be drawn.
  let expected: String
  /// One flag per `Character` of `expected`.
  let expectedMarks: [Bool]

  /// The letters of the right answer that the learner must change or add, in order, lowercased.
  var expectedMarkedLetters: [String] {
    zip(Array(expected), expectedMarks).compactMap { character, isMarked in
      isMarked && !character.isWhitespace ? character.lowercased() : nil
    }
  }

  /// Aligns the two answers and marks every letter that the cheapest alignment does not match.
  /// Case is ignored, so a red letter of `expected` (written in capitals) matches its lowercase.
  /// Insertions, deletions, substitutions, and swaps of two adjacent letters each cost one, as in
  /// `SpellingComparison.editDistance`, and a swap marks both letters on both sides.
  static func between(given: String, expected: String) -> AnswerDifference {
    let lhs = Array(given).map(folded)
    let rhs = Array(expected).map(folded)
    var givenMarks = [Bool](repeating: false, count: lhs.count)
    var expectedMarks = [Bool](repeating: false, count: rhs.count)

    var cost = [[Int]](repeating: [Int](repeating: 0, count: rhs.count + 1), count: lhs.count + 1)
    for i in 0...lhs.count {
      cost[i][0] = i
    }
    for j in 0...rhs.count {
      cost[0][j] = j
    }
    if !lhs.isEmpty, !rhs.isEmpty {
      for i in 1...lhs.count {
        for j in 1...rhs.count {
          let substitution = lhs[i - 1] == rhs[j - 1] ? 0 : 1
          cost[i][j] = min(cost[i - 1][j] + 1, cost[i][j - 1] + 1, cost[i - 1][j - 1] + substitution)
          if isSwap(lhs, rhs, i, j) {
            cost[i][j] = min(cost[i][j], cost[i - 2][j - 2] + 1)
          }
        }
      }
    }

    // Walks back from the end, preferring a match, then a substitution, then a swap, so that a
    // letter is marked only when no alignment of the same cost would leave it unmarked there.
    var i = lhs.count
    var j = rhs.count
    while i > 0 || j > 0 {
      if i > 0, j > 0, lhs[i - 1] == rhs[j - 1], cost[i][j] == cost[i - 1][j - 1] {
        i -= 1
        j -= 1
      } else if i > 0, j > 0, cost[i][j] == cost[i - 1][j - 1] + 1 {
        givenMarks[i - 1] = true
        expectedMarks[j - 1] = true
        i -= 1
        j -= 1
      } else if isSwap(lhs, rhs, i, j), cost[i][j] == cost[i - 2][j - 2] + 1 {
        givenMarks[i - 2] = true
        givenMarks[i - 1] = true
        expectedMarks[j - 2] = true
        expectedMarks[j - 1] = true
        i -= 2
        j -= 2
      } else if i > 0, cost[i][j] == cost[i - 1][j] + 1 {
        givenMarks[i - 1] = true
        i -= 1
      } else {
        expectedMarks[j - 1] = true
        j -= 1
      }
    }

    return AnswerDifference(given: given, givenMarks: givenMarks, expected: expected, expectedMarks: expectedMarks)
  }

  private static func isSwap(_ lhs: [Character], _ rhs: [Character], _ i: Int, _ j: Int) -> Bool {
    i > 1 && j > 1 && lhs[i - 1] == rhs[j - 2] && lhs[i - 2] == rhs[j - 1] && lhs[i - 1] != lhs[i - 2]
  }

  /// One character for one character, so that the marks line up with the text as written. Every
  /// Spanish capital, accented or not, lowercases to a single letter.
  private static func folded(_ character: Character) -> Character {
    character.lowercased().first ?? character
  }
}

nonisolated extension QuizQuestion {
  /// How a wrong answer differs from the nearest way to write this cell right, for the held
  /// correction. A learner who typed freido is shown frito's neighbor freído, and one who typed
  /// arepiento is shown arrepiento rather than me arrepiento, with the written answer winning a
  /// tie. A leading subject pronoun of the asked person is dropped, as grading drops it.
  func difference(from answer: String) -> AnswerDifference {
    let givenOptions = AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber)
    let targets = shownSpellings
    var best: (distance: Int, given: String, expected: String)?
    for given in givenOptions {
      for expected in targets {
        let distance = SpellingComparison.editDistance(Array(given), Array(expected.lowercased()))
        if best.map({ distance < $0.distance }) ?? true {
          best = (distance, given, expected)
        }
      }
    }
    let normalized = AnswerSpelling.normalized(answer)
    return AnswerDifference.between(given: best?.given ?? normalized, expected: best?.expected ?? writtenAnswer ?? "")
  }
}
