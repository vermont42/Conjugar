//
//  Tense.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

enum Tense: String {
  static let auxiliary = "haber"
  
  case infinitivo = "in"
  case translation = "tn"
  case gerundio = "ge"
  case participio = "po"
  case raizFutura = "rf"

  case imperativoPositivo = "io"
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

  var conjugationCount: Int {
    var extraConjugation = 0
    if SettingsManager.getSecondSingularBrowse() == .both {
      extraConjugation = 1
    }
    switch self {
    case .infinitivo, .translation, .gerundio, .participio, .raizFutura:
      return 0
    case .imperativoPositivo, .imperativoNegativo:
      return 5 + extraConjugation
    case .presenteDeIndicativo, .preterito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo,
         .perfectoDeIndicativo, .preteritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      return 6 + extraConjugation
    }
  }

  var hasYoForm: Bool {
    switch self {
    case .imperativoPositivo, .imperativoNegativo,
         .infinitivo, .translation, .gerundio, .participio, .raizFutura:
      return false
    case .presenteDeIndicativo, .preterito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo,
         .perfectoDeIndicativo, .preteritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      return true
    }
  }

  var displayName: String {
    switch self {
    case .infinitivo:
      return "infinitivo"
    case .translation:
      return "translation"
    case .gerundio:
      return "gerundio"
    case .participio:
      return "participio"
    case .raizFutura:
      return "raíz futura"
    case .imperativoPositivo:
      return "imperativo positivo"
    case .imperativoNegativo:
      return "imperativo negativo"
    case .presenteDeIndicativo:
      return "presente de indicativo"
    case .preterito:
      return "pretérito"
    case .imperfectoDeIndicativo:
      return "imperfecto de indicativo"
    case .futuroDeIndicativo:
      return "futuro de indicativo"
    case .condicional:
      return "condicional"
    case .presenteDeSubjuntivo:
      return "presente de subjuntivo"
    case .imperfectoDeSubjuntivo1:
      return "imperfecto de subjuntivo 1"
    case .imperfectoDeSubjuntivo2:
      return "imperfecto de subjuntivo 2"
    case .futuroDeSubjuntivo:
      return "futuro de subjuntivo"
    case .perfectoDeIndicativo:
      return "perfecto de indicativo"
    case .preteritoAnterior:
      return "préterito anterior"
    case .pluscuamperfectoDeIndicativo:
      return "pluscuamperfecto de indicativo"
    case .futuroPerfecto:
      return "futuro perfecto"
    case .condicionalCompuesto:
      return "condicional compuesto"
    case .perfectoDeSubjuntivo:
      return "perfecto de subjuntivo"
    case .pluscuamperfectoDeSubjuntivo1:
      return "pluscuamperfecto de subjuntivo 1"
    case .pluscuamperfectoDeSubjuntivo2:
      return "pluscuamperfecto de subjuntivo 2"
    case .futuroPerfectoDeSubjuntivo:
      return "futuro perfecto de subjuntivo"
    }
  }
  
  var titleCaseName: String {
    switch self {
    case .infinitivo:
      return "Infinitivo"
    case .translation:
      return "Translation"
    case .gerundio:
      return "Gerundio"
    case .participio:
      return "Participio"
    case .raizFutura:
      return "Raíz Futura"
    case .imperativoPositivo:
      return "Imperativo Positivo"
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

  static let conjugatedTenses: [Tense] = [.presenteDeIndicativo, .preterito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional, .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo, .imperativoPositivo, .imperativoNegativo, .perfectoDeIndicativo, .preteritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo]
}
