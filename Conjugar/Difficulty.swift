//
//  Difficulty.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum Difficulty: String, CaseIterable {
  case easy = "Easy"
  case moderate = "Moderate"
  case difficult = "Difficult"

  var scoreModifier: Double {
    switch self {
    case .easy:
      return 0.5
    case .moderate:
      return 1.0
    case .difficult:
      return 1.5
    }
  }

  var localizedDifficulty: String {
    switch self {
    case .easy:
      return Localizations.easy
    case .moderate:
      return Localizations.moderate
    case .difficult:
      return Localizations.difficult
    }
  }
}
