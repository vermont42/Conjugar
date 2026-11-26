//
//  AnswerSlip.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A wrong answer near enough to a right one to earn one more attempt: a typing slip, not a
/// grammatical error.
nonisolated enum AnswerSlip {
  /// In a shorter answer, one letter off is too large a share of it to call a slip: sot for soy
  /// may be a typo, and may be a guess.
  static let minimumLetterCount = 4

  /// Whether a normalized answer is one slip from an accepted spelling: only accents, the
  /// diaeresis, and ñ's tilde, however many and in an answer of any length (cantaria for
  /// cantaría, ire for iré), or, in an answer of four letters or more, one insertion, deletion,
  /// substitution, or swap of two adjacent letters. The letters are counted in `target`, spaces
  /// excluded, so a compound tense never falls under the limit.
  static func isSlip(_ answer: String, of target: String) -> Bool {
    guard answer != target else {
      return false
    }
    if ConjugationMatch.bareSpelling(answer) == ConjugationMatch.bareSpelling(target) {
      return true
    }
    guard target.filter({ !$0.isWhitespace }).count >= minimumLetterCount else {
      return false
    }
    return SpellingComparison.editDistance(Array(answer), Array(target)) <= 1
  }
}

nonisolated extension QuizQuestion {
  /// Whether a wrong answer is a slip that earns a second attempt. An answer that is itself
  /// another cell of the verb is never one, however near, because the accent is often the tense:
  /// hablo for habló is the presente, and hable for hablé the presente de subjuntivo. Nor is one
  /// that is another cell but for its accents and tildes, such as comio for comí, which is comió
  /// without its accent and so the wrong person.
  func isSlip(_ answer: String) -> Bool {
    guard grade(answer) != .totalMatch else {
      return false
    }
    let candidates = AnswerSpelling.candidates(for: answer, tense: tense, personNumber: personNumber)
    let accepted = acceptedAnswers
    let isNear = candidates.contains { candidate in
      accepted.contains { AnswerSlip.isSlip(candidate, of: $0) }
    }
    guard isNear else {
      return false
    }
    return !candidates.contains(where: isAnotherCell)
  }

  /// Whether a text is, but for accents and tildes, a cell of the verb that this question does
  /// not ask. The cells whose forms are right answers here are left out, since esté is both yo's
  /// and él's presente de subjuntivo, and este for esté is a slip of either.
  private func isAnotherCell(_ text: String) -> Bool {
    let matches = Set(ConjugationMatch.cells(of: verb, equalTo: text, accents: .bare))
    guard !matches.isEmpty else {
      return false
    }
    let ownCells = Set(acceptedAnswers.flatMap { ConjugationMatch.cells(of: verb, equalTo: $0) })
    return !matches.subtracting(ownCells).isEmpty
  }
}
