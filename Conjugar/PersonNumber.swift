//
//  PersonNumber.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

enum PersonNumber: String {
  case firstSingular = "fs"
  case firstPlural = "fp"
  case secondSingular = "ss"
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

  func endingForSubjuntivo(tense: Tense) -> String {
    switch self {
    case .firstSingular:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ra"
      case .imperfectoDeSubjuntivo2:
        return "se"
      case .futuroDeSubjuntivo:
        return "re"
      default:
        return ""
      }
    case .secondSingular:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ras"
      case .imperfectoDeSubjuntivo2:
        return "ses"
      case .futuroDeSubjuntivo:
        return "res"
      default:
        return ""
      }
    case .thirdSingular:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ra"
      case .imperfectoDeSubjuntivo2:
        return "se"
      case .futuroDeSubjuntivo:
        return "re"
      default:
        return ""
      }
    case .firstPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ramos"
      case .imperfectoDeSubjuntivo2:
        return "semos"
      case .futuroDeSubjuntivo:
        return "remos"
      default:
        return ""
      }
    case .secondPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "rais"
      case .imperfectoDeSubjuntivo2:
        return "seis"
      case .futuroDeSubjuntivo:
        return "reis"
      default:
        return ""
      }
    case .thirdPlural:
      switch tense {
      case .imperfectoDeSubjuntivo1:
        return "ran"
      case .imperfectoDeSubjuntivo2:
        return "sen"
      case .futuroDeSubjuntivo:
        return "ren"
      default:
        return ""
      }
    case .none:
      return ""
    }
  }
}
