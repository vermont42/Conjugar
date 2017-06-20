//
//  ConjugationResult.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/20/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

enum ConjugationResult: Int {
  case totalMatch = 10
  case partialMatch = 5
  case noMatch = 0
  
  static func compare(lhs: String, rhs: String) -> ConjugationResult {
    let lhsCount = lhs.characters.count
    let rhsCount = rhs.characters.count
    if lhsCount != rhsCount || lhsCount == 0 {
      return .noMatch
    }
    var lhsClean = lhs.lowercased()
    var rhsClean = rhs.lowercased()
    if lhsClean == rhsClean {
      return .totalMatch
    }
    _ = [("á", "a"), ("é", "e"), ("í", "i"), ("ó", "o"), ("ú", "u")].map {
      lhsClean = lhsClean.replacingOccurrences(of: $0.0, with: $0.1)
      rhsClean = rhsClean.replacingOccurrences(of: $0.0, with: $0.1)
    }
    if lhsClean == rhsClean {
      return .partialMatch
    }
    else {
      return .noMatch
    }
  }
}
