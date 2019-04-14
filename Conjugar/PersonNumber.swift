//
//  PersonNumber.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum PersonNumber: String, CaseIterable {
  case firstSingular = "fs"
  case firstPlural = "fp"
  case secondSingularTu = "ss"
  case secondSingularVos = "sv"
  case secondPlural = "sp"
  case thirdSingular = "ts"
  case thirdPlural = "tp"
  case none = "no"

  var pronoun: String {
    switch self {
    case .firstSingular:
      return "yo"
    case .secondSingularTu:
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
    case .secondSingularTu:
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
