//
//  Difficulty.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

enum Difficulty: String {
  case easy = "Easy"
  case moderate = "Moderate"
  case difficult = "Difficult"
  
  init() {
    self = .moderate
  }
}
