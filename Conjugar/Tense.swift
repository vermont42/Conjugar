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
  case raizFutura = "rf"

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
  
  func shortDisplayName() -> String {
    switch self {
    case .gerundio:
      return "Ger."
    case .participio:
      return "PP"
    case .raizFutura:
      return "Raíz Fut."
    default:
      return ""
    }
  }
  
  func displayName() -> String {
    switch self {
    case .infinitivo:
      return "Infinitivo"
    case .gerundio:
      return "Gerundio"
    case .participio:
      return "Participio"
    case .raizFutura:
      return "Raíz Futura"
    case .imperativo:
      return "Imperativo"
    case .imperativoNegativo:
      return "Imperativo Negativo"
    case .presenteDeIndicativo:
      return "Presente de Indicativo"
    case .preterito:
      return "Pretérito"
    case .imperfectoDeIndicativo:
      return "Imperfecto de Indicativo"
    case .futuroDeIndicativo:
      return "Futuro de Indicativo"
    case .condicional:
      return "Condicional"
    case .presenteDeSubjuntivo:
      return "Presente de Subjuntivo"
    case .imperfectoDeSubjuntivo1:
      return "Imperfecto de Subjuntivo 1"
    case .imperfectoDeSubjuntivo2:
      return "Imperfecto de Subjuntivo 2"
    case .futuroDeSubjuntivo:
      return "Futuro de Subjuntivo"
    case .perfectoDeIndicativo:
      return "Perfecto de Indicativo"
    case .preteritoAnterior:
      return "Préterito Anterior"
    case .pluscuamperfectoDeIndicativo:
      return "Pluscuamperfecto de Indicativo"
    case .futuroPerfecto:
      return "Futuro Perfecto"
    case .condicionalCompuesto:
      return "Condicional Compuesto"
    case .perfectoDeSubjuntivo:
      return "Perfecto de Subjuntivo"
    case .pluscuamperfectoDeSubjuntivo1:
      return "Pluscuamperfecto de Subjuntivo 1"
    case .pluscuamperfectoDeSubjuntivo2:
      return "Pluscuamperfecto de Subjuntivo 2"
    case .futuroPerfectoDeSubjuntivo:
      return "Futuro Perfecto de Subjuntivo"
    }
  }
  
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
