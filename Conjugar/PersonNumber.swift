//
//  PersonNumber.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum PersonNumber: String {
  case firstSingular = "fs"
  case firstPlural = "fp"
  case secondSingular = "ss"
  case secondSingularVos = "sv"
  case secondPlural = "sp"
  case thirdSingular = "ts"
  case thirdPlural = "tp"
  case none = "no"
  
  func endingForFuturoDeSubjuntivo() -> String {
    switch self {
    case .firstSingular:
      return "re"
    case .secondSingular:
      return "res"
    case .secondSingularVos:
      return "res"
    case .thirdSingular:
      return "re"
    case .firstPlural:
      return "remos"
    case .secondPlural:
      return "reis"
    case .thirdPlural:
      return "ren"
    case .none:
      return ""
    }
  }
  
  var pronoun: String {
    switch self {
    case .firstSingular:
      return "yo"
    case .secondSingular:
      return "tú"
    case .secondSingularVos:
      return "vos"
    case .thirdSingular:
      return "él"
    case .firstPlural:
      return "nosotros"
    case .secondPlural:
      return "vosotros"
    case .thirdPlural:
      return "ellas"
    case .none:
      return "none"
    }
  }
  
  var shortDisplayName: String {
    switch self {
    case .firstSingular:
      return "1S"
    case .secondSingular:
      return "2S"
    case .secondSingularVos:
      return "2SV"
    case .thirdSingular:
      return "3S"
    case .firstPlural:
      return "1P"
    case .secondPlural:
      return "2P"
    case .thirdPlural:
      return "3P"
    case .none:
      return "none"
    }
  }
}
