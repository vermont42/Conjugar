//
//  QuizCorrection.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A wrong answer, held on its question with the clock stopped until the learner continues: what
/// the answer earned and how it differs from the nearest right one.
nonisolated struct QuizCorrection: Equatable, Sendable {
  /// `.noMatch`, or `.partialMatch` for an answer right but for its accents, which earns half.
  let result: ConjugationResult
  let difference: AnswerDifference
}
