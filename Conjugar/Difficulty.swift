//
//  Difficulty.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum Difficulty: String {
  case easy = "Easy"
  case moderate = "Moderate"
  case difficult = "Difficult"
  
  init() {
    self = .easy
  }
  
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
}
