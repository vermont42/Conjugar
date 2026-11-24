//
//  QuizCorrection.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A wrong answer, held on its question with the clock stopped until the learner continues: how
/// it differs from the nearest right one, and what its error is when the engine can say.
nonisolated struct QuizCorrection: Equatable, Sendable {
  let difference: AnswerDifference
  /// The diagnosis of the answer held, which is the second attempt's when there was one, so that
  /// a repair wrong in a way nothing names gets no line.
  let diagnosis: AnswerDiagnosis?
  /// Whether the question comes back later in the round. A re-ask's own correction does not.
  let willBeReasked: Bool
}
