//
//  QuizCorrection.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A wrong answer, held on its question with the clock stopped until the learner continues: how
/// it differs from the nearest right one.
nonisolated struct QuizCorrection: Equatable, Sendable {
  let difference: AnswerDifference
  /// Whether the question comes back later in the round. A re-ask's own correction does not.
  let willBeReasked: Bool
}
