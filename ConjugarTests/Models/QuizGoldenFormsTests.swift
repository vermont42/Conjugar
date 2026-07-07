//
//  QuizGoldenFormsTests.swift
//  ConjugarTests
//
//  Golden-form coverage for the quiz (item 19). `QuizTests` proves the quiz is
//  self-consistent — it scores a run by comparing each answer to the *same* engine
//  output the quiz asked for — but it cannot prove that output is correct Spanish.
//  `VerbFamiliesTests` pins the quiz lists to the verb map (every entry resolves and
//  sits in the right class), but not the actual conjugated forms.
//
//  This suite closes that gap: for verbs drawn from every `VerbFamilies` list, paired
//  with the tense that list is quizzed at, it pins the conjugated form to a
//  hand-written, independently-known Spanish answer. To keep the assertion about
//  *linguistic truth* rather than the engine's UPPERCASE irregularity-marking, the
//  engine output is lowercased (which strips the `IrregularityMarker` encoding,
//  leaving the plain letters) before comparison. A failure means either the engine
//  conjugates the verb wrong or a bad list entry slipped past the guard-rail — exactly
//  the "quiz teaches wrong Spanish" class of bug (item 2).
//
//  Nonisolated, like the engine it exercises, so it runs in parallel.
//

import Testing
@testable import Conjugar

@Suite("Quiz golden forms (quiz-list verbs → known Spanish)")
struct QuizGoldenFormsTests {
  /// (verb, tense the verb's family is quizzed at, person, expected plain Spanish).
  /// Every verb is a member of a `VerbFamilies` list; the tense is that list's intent.
  static let goldens: [(verb: String, tense: DisplayTense, person: DisplayPersonNumber, expected: String)] = [
    // regularArVerbs / regularErVerbs / regularIrVerbs — plain regular drills across tenses
    ("hablar", .presenteDeIndicativo, .firstSingular, "hablo"),
    ("hablar", .pretérito, .firstSingular, "hablé"),
    ("hablar", .imperativoPositivo, .secondSingularVos, "hablá"),
    ("escuchar", .condicional, .thirdSingular, "escucharía"),
    ("comer", .presenteDeIndicativo, .thirdPlural, "comen"),
    ("comer", .imperfectoDeIndicativo, .thirdPlural, "comían"),
    ("beber", .futuroDeIndicativo, .firstSingular, "beberé"),
    ("vivir", .presenteDeIndicativo, .firstPlural, "vivimos"),
    ("vivir", .pretérito, .thirdSingular, "vivió"),

    // irregularPresenteDeIndicativoVerbs → presente de indicativo
    ("ser", .presenteDeIndicativo, .firstSingular, "soy"),
    ("ir", .presenteDeIndicativo, .firstSingular, "voy"),
    ("hacer", .presenteDeIndicativo, .firstSingular, "hago"),
    ("poder", .presenteDeIndicativo, .firstSingular, "puedo"),
    ("dormir", .presenteDeIndicativo, .thirdSingular, "duerme"),
    ("oír", .presenteDeIndicativo, .firstSingular, "oigo"),

    // irregularImperfectivoVerbs → imperfecto de indicativo (only three verbs are irregular here)
    ("ser", .imperfectoDeIndicativo, .firstSingular, "era"),
    ("ir", .imperfectoDeIndicativo, .firstPlural, "íbamos"),
    ("ver", .imperfectoDeIndicativo, .thirdPlural, "veían"),

    // irregularPreteritoVerbs → pretérito (strong preterites, incl. j-stems)
    ("tener", .pretérito, .firstSingular, "tuve"),
    ("estar", .pretérito, .thirdSingular, "estuvo"),
    ("hacer", .pretérito, .thirdSingular, "hizo"),
    ("poder", .pretérito, .firstSingular, "pude"),
    ("decir", .pretérito, .thirdPlural, "dijeron"),
    ("conducir", .pretérito, .thirdPlural, "condujeron"),

    // irregularRaizFuturaVerbs → futuro / condicional (irregular future stem)
    ("tener", .futuroDeIndicativo, .firstSingular, "tendré"),
    ("hacer", .futuroDeIndicativo, .thirdSingular, "hará"),
    ("salir", .futuroDeIndicativo, .firstPlural, "saldremos"),
    ("poder", .futuroDeIndicativo, .thirdPlural, "podrán"),
    ("decir", .condicional, .firstSingular, "diría"),

    // irregularPresenteDeSubjuntivoVerbs → presente de subjuntivo
    ("ser", .presenteDeSubjuntivo, .firstSingular, "sea"),
    ("ir", .presenteDeSubjuntivo, .firstPlural, "vayamos"),
    ("haber", .presenteDeSubjuntivo, .thirdSingular, "haya"),
    ("saber", .presenteDeSubjuntivo, .firstSingular, "sepa"),
    ("pensar", .presenteDeSubjuntivo, .firstSingular, "piense"),
    ("dormir", .presenteDeSubjuntivo, .firstPlural, "durmamos"),
    ("pedir", .presenteDeSubjuntivo, .thirdSingular, "pida"),
    ("conocer", .presenteDeSubjuntivo, .firstSingular, "conozca"),

    // irregularTuImperativoVerbs → imperativo positivo (tú), the short irregular forms
    ("ser", .imperativoPositivo, .secondSingularTú, "sé"),
    ("hacer", .imperativoPositivo, .secondSingularTú, "haz"),
    ("decir", .imperativoPositivo, .secondSingularTú, "di"),
    ("tener", .imperativoPositivo, .secondSingularTú, "ten"),
    ("poner", .imperativoPositivo, .secondSingularTú, "pon"),
    ("salir", .imperativoPositivo, .secondSingularTú, "sal"),
    ("venir", .imperativoPositivo, .secondSingularTú, "ven"),
    ("ir", .imperativoPositivo, .secondSingularTú, "ve"),

    // irregularParticipioVerbs → participio
    ("hacer", .participio, DisplayPersonNumber.none, "hecho"),
    ("ver", .participio, .none, "visto"),
    ("escribir", .participio, .none, "escrito"),
    ("volver", .participio, .none, "vuelto"),
    ("morir", .participio, .none, "muerto"),
    ("abrir", .participio, .none, "abierto"),

    // irregularGerundioVerbs → gerundio
    ("poder", .gerundio, .none, "pudiendo"),
    ("dormir", .gerundio, .none, "durmiendo"),
    ("medir", .gerundio, .none, "midiendo"),
    ("leer", .gerundio, .none, "leyendo"),
    ("oír", .gerundio, .none, "oyendo"),
    ("construir", .gerundio, .none, "construyendo"),
    ("ir", .gerundio, .none, "yendo")
  ]

  @Test("quiz-list verbs conjugate to their known Spanish forms", arguments: goldens)
  func goldenForm(golden: (verb: String, tense: DisplayTense, person: DisplayPersonNumber, expected: String)) {
    guard case .success(let marked) = TenseBridge.conjugate(infinitive: golden.verb, tense: golden.tense, personNumber: golden.person) else {
      Issue.record("conjugation failed for \(golden.verb) \(golden.tense.displayName) \(golden.person.shortDisplayName)")
      return
    }
    // Lowercasing strips the UPPERCASE irregularity-marking, leaving the plain letters
    // to compare against the known Spanish answer.
    #expect(marked.lowercased() == golden.expected, "\(golden.verb) \(golden.tense.displayName) \(golden.person.shortDisplayName): got \(marked.lowercased()), expected \(golden.expected)")
  }
}
