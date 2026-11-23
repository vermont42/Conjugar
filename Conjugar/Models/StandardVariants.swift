//
//  StandardVariants.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// Standard forms of a cell beside the one the engine gives, which the quiz accepts and the verb
/// page does not show. Each is one the RAE's *Diccionario panhispánico de dudas* or *Diccionario
/// de la lengua española* admits.
nonisolated enum StandardVariants {
  /// The variants of one cell, lowercased, without the engine's own form.
  static func forms(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> [String] {
    let engineForm = (try? TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber).get())?.lowercased()
    var variants: [String] = []
    for form in allForms(infinitive: infinitive, tense: tense, personNumber: personNumber) where form != engineForm && !variants.contains(form) {
      variants.append(form)
    }
    return variants
  }

  /// Every accepted form of a cell, the engine's first.
  private static func allForms(infinitive: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> [String] {
    switch tense {
    case .infinitivo, .translation, .raízFutura:
      return []
    case .gerundio:
      return words(infinitive: infinitive, tense: .gerundio)
    case .participio:
      return words(infinitive: infinitive, tense: .participioPasado)
    case .futuroDeSubjuntivo:
      return (try? TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber).get()).map { [$0.lowercased()] } ?? []
    case .imperativoNegativo:
      return allForms(infinitive: infinitive, tense: .presenteDeSubjuntivo, personNumber: personNumber).map { "no " + $0 }
    case .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      guard case let .success(haberTense) = tense.haberTenseForCompoundTense() else {
        return []
      }
      let auxiliaries = allForms(infinitive: DisplayTense.auxiliary, tense: haberTense, personNumber: personNumber)
      let participles = words(infinitive: infinitive, tense: .participioPasado)
      return auxiliaries.flatMap { auxiliary in participles.map { auxiliary + " " + $0 } }
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .imperativoPositivo:
      guard
        let enginePersonNumber = TenseBridge.enginePersonNumber(for: personNumber),
        let engineTense = TenseBridge.simpleEngineTense(for: tense, personNumber: enginePersonNumber)
      else {
        return []
      }
      var forms = words(infinitive: infinitive, tense: engineTense)
      if personNumber == .secondSingularVos, tense == .presenteDeSubjuntivo {
        forms += words(infinitive: infinitive, tense: .presenteDeSubjuntivo(.secondPlural)).compactMap(voseoSubjunctive(fromVosotros:))
      }
      return forms
    }
  }

  /// Every accepted one-word form of an engine slot, lowercased, the engine's first: the forms
  /// the engine models (`Conjugator.conjugateAll`, which carries the alternate paradigms and the
  /// spelling the 2010 *Ortografía* retired) and the ones below.
  private static func words(infinitive: String, tense: EngineTense) -> [String] {
    guard case let .success(modeled) = Conjugator.conjugateAll(infinitive: infinitive, tense: tense) else {
      return []
    }
    var forms = modeled
    if tense == .participioPasado, let participle = participles[infinitive] {
      forms.append(participle)
    }
    if let model = stressModels[infinitive], case let .success(form) = Conjugator.conjugate(infinitive: infinitive, tense: tense, model: model) {
      forms.append(form)
    }
    if regularFutures.contains(infinitive), tense.isFutureOrConditional,
       case let .success(form) = Conjugator.conjugate(infinitive: infinitive, tense: tense, model: ModelCatalog.subir) {
      forms.append(form)
    }
    if infinitive == "satisfacer", tense == .imperativoAfirmativo(.secondSingular) {
      forms.append("satisface")
    }
    return forms.map { $0.lowercased() }
  }

  /// The Río de la Plata's vos subjunctive, stressed on its ending (vos hablés, tengás), which
  /// the DPD's entry on voseo says alternates there with the tuteo form the engine gives. It is
  /// the vosotros form without its i: habléis, hablés; deis, des.
  static func voseoSubjunctive(fromVosotros form: String) -> String? {
    guard form.hasSuffix("is") else {
      return nil
    }
    var letters = Array(form)
    letters.remove(at: letters.count - 2)
    return String(letters)
  }

  /// The second participle of the three verbs whose two participles both serve in compound tenses
  /// (freír, imprimir, proveer, and their derivatives; the engine itself carries imprimido), and
  /// the -scripto participles of Argentina, Paraguay, and Uruguay.
  private static let participles: [String: String] = [
    "freír": "frito", "sofreír": "sofrito", "refreír": "refrito",
    "proveer": "provisto", "desproveer": "desprovisto",
    "inscribir": "inscripto", "suscribir": "suscripto", "describir": "descripto", "prescribir": "prescripto",
    "circunscribir": "circunscripto", "proscribir": "proscripto", "transcribir": "transcripto", "adscribir": "adscripto"
  ]

  /// Verbs that may be stressed either way, each with the model the engine does not use for it:
  /// adecuar as averiguar or as actuar (adecuo, adecúo), agriar as enviar or as anunciar (agrío,
  /// agrio).
  private static let stressModels: [String: VerbModel] = [
    "adecuar": ModelCatalog.actuar, "evacuar": ModelCatalog.actuar, "licuar": ModelCatalog.actuar,
    "agriar": ModelCatalog.cantar, "expatriar": ModelCatalog.cantar, "repatriar": ModelCatalog.cantar,
    "paliar": ModelCatalog.enviar, "historiar": ModelCatalog.enviar, "vidriar": ModelCatalog.enviar
  ]

  /// Compounds of decir whose futuro and condicional may also be regular: predeciré beside
  /// prediré.
  private static let regularFutures: Set<String> = ["predecir", "contradecir", "desdecir"]
}

private extension EngineTense {
  nonisolated var isFutureOrConditional: Bool {
    switch self {
    case .futuro, .condicional:
      return true
    default:
      return false
    }
  }
}
