//
//  ConjugationResult.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/20/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

/// What an answered question earned, in points.
nonisolated enum ConjugationResult: Int {
  case totalMatch = 10
  /// Right on the second attempt, which a slip earns (`QuizQuestion.isSlip(_:)`).
  case secondAttemptMatch = 5
  case noMatch = 0
}
