//
//  ConjugationTable.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// One card of the verb page's conjugations: a tense, with its Info article and the names that
/// article lists.
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

  /// A name the tense goes by, which its article lists under the heading.
  struct TenseName: Equatable, Sendable {
    let text: String

    /// Whether VoiceOver should speak it with a Spanish voice: pretérito perfecto simple is
    /// Spanish even in the English interface.
    let isSpanish: Bool
  }

  /// The names a learner will meet elsewhere, which the tense's article lists under its heading.
  /// The headings are Spanish in either interface, so the lists follow the interface instead. An
  /// English interface gets the English textbook name, then the RAE's name where it differs from
  /// the heading, then Andrés Bello's, which Mexican and other Latin American schools teach. A
  /// Spanish interface gets the same Spanish names and never an English one.
  func articleNames(spanishInterface: Bool) -> [TenseName] {
    let spanish = spanishNames.map { TenseName(text: $0, isSpanish: true) }
    if spanishInterface || englishName.isEmpty {
      return spanish
    }
    return [TenseName(text: englishName, isSpanish: false)] + spanish
  }

  /// The table whose tense an Info article is about, or nil for an article that no card opens.
  static func table(forArticle stableKey: String) -> ConjugationTable? {
    all.first { $0.articleKey == stableKey }
  }

  private var englishName: String {
    switch tense {
    case .presenteDeIndicativo:
      return "present"
    case .pretérito:
      return "preterite"
    case .imperfectoDeIndicativo:
      return "imperfect"
    case .futuroDeIndicativo:
      return "future"
    case .condicional:
      return "conditional"
    case .presenteDeSubjuntivo:
      return "present subjunctive"
    case .imperfectoDeSubjuntivo1:
      return "imperfect subjunctive, -ra form"
    case .imperfectoDeSubjuntivo2:
      return "imperfect subjunctive, -se form"
    case .futuroDeSubjuntivo:
      return "future subjunctive"
    case .imperativoPositivo:
      return "affirmative command"
    case .imperativoNegativo:
      return "negative command"
    case .perfectoDeIndicativo:
      return "present perfect"
    case .pretéritoAnterior:
      return "past anterior"
    case .pluscuamperfectoDeIndicativo:
      return "past perfect"
    case .futuroPerfecto:
      return "future perfect"
    case .condicionalCompuesto:
      return "conditional perfect"
    case .perfectoDeSubjuntivo:
      return "present perfect subjunctive"
    case .pluscuamperfectoDeSubjuntivo1:
      return "past perfect subjunctive, -ra form"
    case .pluscuamperfectoDeSubjuntivo2:
      return "past perfect subjunctive, -se form"
    case .futuroPerfectoDeSubjuntivo:
      return "future perfect subjunctive"
    case .infinitivo, .translation, .gerundio, .participio, .raízFutura:
      return ""
    }
  }

  /// The RAE's name where it differs from the heading, then Bello's where there is one.
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
