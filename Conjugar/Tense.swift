//
//  Tense.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

enum Tense: String {
  static let auxiliary = "haber"
  
  case infinitivo = "in"
  case gerundio = "ge"
  case participio = "po"
  case talloFuturo = "tf"

  case imperativo = "io"
  case imperativoNegativo = "ni"
  
  case presenteDeIndicativo = "pr"
  case preterito = "pt"
  case imperfectoDeIndicativo = "ii"
  case futuroDeIndicativo = "fu"
  case condicional = "co"
  case presenteDeSubjuntivo = "pb"
  case imperfectoDeSubjuntivo1 = "i1"
  case imperfectoDeSubjuntivo2 = "i2"
  case futuroDeSubjuntivo = "fv"
  
  case perfectoDeIndicativo = "pi"
  case preteritoAnterior = "pa"
  case pluscuamperfectoDeIndicativo = "fi"
  case futuroPerfecto = "fp"
  case condicionalCompuesto = "cc"
  case perfectoDeSubjuntivo = "cp"
  case pluscuamperfectoDeSubjuntivo1 = "p1"
  case pluscuamperfectoDeSubjuntivo2 = "p2"
  case futuroPerfectoDeSubjuntivo = "fo"
  
  func haberTenseForCompoundTense() -> Result<Tense, AuxiliaryError> {
    switch self {
    case .perfectoDeIndicativo:
      return .success(.presenteDeIndicativo)
    case .preteritoAnterior:
      return .success(.preterito)
    case .pluscuamperfectoDeIndicativo:
      return .success(.imperfectoDeIndicativo)
    case .futuroPerfecto:
      return .success(.futuroDeIndicativo)
    case .condicionalCompuesto:
      return .success(.condicional)
    case .perfectoDeSubjuntivo:
      return .success(.presenteDeSubjuntivo)
    case .pluscuamperfectoDeSubjuntivo1:
      return .success(.imperfectoDeSubjuntivo1)
    case .pluscuamperfectoDeSubjuntivo2:
      return .success(.imperfectoDeSubjuntivo2)
    case .futuroPerfectoDeSubjuntivo:
      return .success(.futuroDeSubjuntivo)
    default:
      return .failure(.noHaberForm(self))
    }
  }
}
