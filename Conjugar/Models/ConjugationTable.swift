//
//  ConjugationTable.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// One card of the verb page's conjugations: a tense, with its other names and its Info article.
///
/// The verb page's order lives here and nowhere else. The simple tenses come first and the compound
/// ones after them, and each block is ordered by how often its tense occurs in the corpus, weighing
/// official prose (the government and technology folders) and literature equally, with one
/// deliberate exception: the two imperatives stay together at the end of the simple block.
/// docs/tense_frequency.md gives the counts, and scripts/count_tenses.py reproduces them. Change
/// the order there before changing it here.
///
/// Only the verb page uses this order. Info, the quiz, the Models grid, the widgets, and the
/// conjugation map keep `DisplayTense.conjugatedTenses`, whose order the map's file format depends
/// on.
nonisolated struct ConjugationTable: Hashable, Identifiable, Sendable {
  let tense: DisplayTense

  var id: String { tense.rawValue }

  /// The page's cards, top to bottom.
  static let all: [ConjugationTable] = (simpleOrder + compoundOrder).map(ConjugationTable.init)

  private static let simpleOrder: [DisplayTense] = [
    .presenteDeIndicativo,
    .imperfectoDeIndicativo,
    .pretérito,
    .presenteDeSubjuntivo,
    .futuroDeIndicativo,
    .condicional,
    .imperfectoDeSubjuntivo1,
    .imperfectoDeSubjuntivo2,
    .futuroDeSubjuntivo,
    .imperativoPositivo,
    .imperativoNegativo
  ]

  private static let compoundOrder: [DisplayTense] = [
    .perfectoDeIndicativo,
    .pluscuamperfectoDeIndicativo,
    .perfectoDeSubjuntivo,
    .pluscuamperfectoDeSubjuntivo1,
    .condicionalCompuesto,
    .pluscuamperfectoDeSubjuntivo2,
    .futuroPerfecto,
    .pretéritoAnterior,
    .futuroPerfectoDeSubjuntivo
  ]

  /// The first simple card and the first compound card, whose arrival on screen `leaveVerbView`
  /// reports as `simple` and `compound`.
  static let firstSimple = simpleOrder[0]
  static let firstCompound = compoundOrder[0]

  var isCompound: Bool {
    tense.isCompound
  }

  /// The `Info.stableKey` of the article about this tense.
  var articleKey: String {
    switch tense {
    case .presenteDeIndicativo:
      return "presente_de_indicativo"
    case .pretérito:
      return "preterito"
    case .imperfectoDeIndicativo:
      return "imperfecto_de_indicativo"
    case .futuroDeIndicativo:
      return "futuro_de_indicativo"
    case .condicional:
      return "condicional"
    case .presenteDeSubjuntivo:
      return "presente_de_subjuntivo"
    case .imperfectoDeSubjuntivo1:
      return "imperfecto_de_subjuntivo_1"
    case .imperfectoDeSubjuntivo2:
      return "imperfecto_de_subjuntivo_2"
    case .futuroDeSubjuntivo:
      return "futuro_de_subjuntivo"
    case .imperativoPositivo:
      return "imperativo_positivo"
    case .imperativoNegativo:
      return "imperativo_negativo"
    case .perfectoDeIndicativo:
      return "perfecto_de_indicativo"
    case .pretéritoAnterior:
      return "preterito_anterior"
    case .pluscuamperfectoDeIndicativo:
      return "pluscuamperfecto_de_indicativo"
    case .futuroPerfecto:
      return "futuro_perfecto"
    case .condicionalCompuesto:
      return "condicional_compuesto"
    case .perfectoDeSubjuntivo:
      return "perfecto_de_subjuntivo"
    case .pluscuamperfectoDeSubjuntivo1:
      return "pluscuamperfecto_de_subjuntivo_1"
    case .pluscuamperfectoDeSubjuntivo2:
      return "pluscuamperfecto_de_subjuntivo_2"
    case .futuroPerfectoDeSubjuntivo:
      return "futuro_perfecto_de_subjuntivo"
    case .infinitivo, .translation, .gerundio, .participio, .raízFutura:
      return ""
    }
  }

  /// A name the tense also goes by, for the line under its heading.
  struct SecondName: Equatable, Sendable {
    let text: String

    /// Whether VoiceOver should speak it with a Spanish voice: pretérito perfecto simple is
    /// Spanish even in the English interface.
    let isSpanish: Bool
  }

  /// The names a learner will meet elsewhere, shown under the heading after "also". The headings
  /// are Spanish in either interface, so the lists follow the interface instead. An English
  /// interface gets the English textbook name, then the RAE's name where it differs from the
  /// heading. A Spanish interface gets the RAE's name, then Andrés Bello's, which Mexican and other
  /// Latin American schools teach. Empty where every system agrees with the heading.
  func secondNames(spanishInterface: Bool) -> [SecondName] {
    spanishInterface ? spanishNames.map { SecondName(text: $0, isSpanish: true) } : englishNames
  }

  private var englishNames: [SecondName] {
    let (english, rae): (String, String?) = {
      switch tense {
      case .presenteDeIndicativo:
        return ("present", nil)
      case .pretérito:
        return ("preterite", "pretérito perfecto simple")
      case .imperfectoDeIndicativo:
        return ("imperfect", "pretérito imperfecto")
      case .futuroDeIndicativo:
        return ("future", "futuro simple")
      case .condicional:
        return ("conditional", "condicional simple")
      case .presenteDeSubjuntivo:
        return ("present subjunctive", nil)
      case .imperfectoDeSubjuntivo1:
        return ("imperfect subjunctive, -ra form", nil)
      case .imperfectoDeSubjuntivo2:
        return ("imperfect subjunctive, -se form", nil)
      case .futuroDeSubjuntivo:
        return ("future subjunctive", nil)
      case .imperativoPositivo:
        return ("affirmative command", nil)
      case .imperativoNegativo:
        return ("negative command", nil)
      case .perfectoDeIndicativo:
        return ("present perfect", "pretérito perfecto compuesto")
      case .pretéritoAnterior:
        return ("past anterior", nil)
      case .pluscuamperfectoDeIndicativo:
        return ("past perfect", "pretérito pluscuamperfecto")
      case .futuroPerfecto:
        return ("future perfect", "futuro compuesto")
      case .condicionalCompuesto:
        return ("conditional perfect", nil)
      case .perfectoDeSubjuntivo:
        return ("present perfect subjunctive", nil)
      case .pluscuamperfectoDeSubjuntivo1:
        return ("past perfect subjunctive, -ra form", nil)
      case .pluscuamperfectoDeSubjuntivo2:
        return ("past perfect subjunctive, -se form", nil)
      case .futuroPerfectoDeSubjuntivo:
        return ("future perfect subjunctive", nil)
      case .infinitivo, .translation, .gerundio, .participio, .raízFutura:
        return ("", nil)
      }
    }()
    var names = [SecondName(text: english, isSpanish: false)]
    if let rae {
      names.append(SecondName(text: rae, isSpanish: true))
    }
    return names.filter { !$0.text.isEmpty }
  }

  private var spanishNames: [String] {
    switch tense {
    case .presenteDeIndicativo, .presenteDeSubjuntivo:
      return []
    case .pretérito:
      return ["pretérito perfecto simple", "pretérito indefinido"]
    case .imperfectoDeIndicativo:
      return ["pretérito imperfecto", "copretérito"]
    case .futuroDeIndicativo:
      return ["futuro simple"]
    case .condicional:
      return ["condicional simple", "pospretérito"]
    case .imperfectoDeSubjuntivo1:
      return ["pretérito imperfecto, en -ra"]
    case .imperfectoDeSubjuntivo2:
      return ["pretérito imperfecto, en -se"]
    case .futuroDeSubjuntivo:
      return ["futuro simple"]
    case .imperativoPositivo:
      return ["imperativo afirmativo"]
    case .imperativoNegativo:
      return ["no + presente de subjuntivo"]
    case .perfectoDeIndicativo:
      return ["pretérito perfecto compuesto", "antepresente"]
    case .pretéritoAnterior:
      return ["antepretérito"]
    case .pluscuamperfectoDeIndicativo:
      return ["pretérito pluscuamperfecto", "antecopretérito"]
    case .futuroPerfecto:
      return ["futuro compuesto", "antefuturo"]
    case .condicionalCompuesto:
      return ["antepospretérito"]
    case .perfectoDeSubjuntivo:
      return ["pretérito perfecto", "antepresente"]
    case .pluscuamperfectoDeSubjuntivo1:
      return ["pretérito pluscuamperfecto, en -ra", "antepretérito"]
    case .pluscuamperfectoDeSubjuntivo2:
      return ["pretérito pluscuamperfecto, en -se"]
    case .futuroPerfectoDeSubjuntivo:
      return ["futuro compuesto", "antefuturo"]
    case .infinitivo, .translation, .gerundio, .participio, .raízFutura:
      return []
    }
  }
}

extension ConjugationTable {
  /// The Info article about this tense, which the ⓘ button beside its heading opens.
  var article: Info? {
    Info.infos.first { $0.stableKey == articleKey }
  }
}
