//
//  Conjugator2Tests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// The composition-engine tests, in idiomatic Swift Testing. Full six-person
// paradigms are parameterized over `zip(PersonNumber2.oracleOrder, [forms])`;
// clusters of single slots for one verb are parameterized over `(Tense2, String)`
// pairs; multi-verb / non-finite / failure checks stay plain `@Test`s. Expected
// forms are the verified oracle (docs/spanish_models.md) and are unchanged from
// the XCTest version — only the test *structure* changed.
@Suite("Conjugator2 (new engine)")
struct Conjugator2Tests {
  // MARK: - Shared models — the catalog under test (Phase 6A)

  // The ~95 oracle-verified model exemplars now live in the app target's
  // `ModelCatalog2`, keyed by book class number. These `static let`s alias the
  // catalog, so every assertion below exercises the catalog (the single source
  // of truth). `model(forClass:)` is force-unwrapped on purpose: a nil here is a
  // real regression (a class number that stopped resolving), surfaced loudly.
  static let tocar = ModelCatalog2.model(forClass: "1-1")!
  static let pagar = ModelCatalog2.model(forClass: "1-2")!
  static let averiguar = ModelCatalog2.model(forClass: "1-3")!
  static let cazar = ModelCatalog2.model(forClass: "1-4")!
  static let aislar = ModelCatalog2.model(forClass: "1-5")!
  static let aullar = ModelCatalog2.model(forClass: "1-6")!
  static let descafeinar = ModelCatalog2.model(forClass: "1-7")!
  static let rehusar = ModelCatalog2.model(forClass: "1-8")!
  static let amohinar = ModelCatalog2.model(forClass: "1-9")!
  static let ahincar = ModelCatalog2.model(forClass: "1-10")!
  static let cabrahigar = ModelCatalog2.model(forClass: "1-11")!
  static let enraizar = ModelCatalog2.model(forClass: "1-12")!
  static let europeizar = ModelCatalog2.model(forClass: "1-13")!
  static let actuar = ModelCatalog2.model(forClass: "1-14")!
  static let enviar = ModelCatalog2.model(forClass: "1-15")!
  static let vencer = ModelCatalog2.model(forClass: "2-1")!
  static let coger = ModelCatalog2.model(forClass: "2-2")!
  static let leer = ModelCatalog2.model(forClass: "2-3")!
  static let empeller = ModelCatalog2.model(forClass: "2-4")!
  static let tañer = ModelCatalog2.model(forClass: "2-5")!
  static let romper = ModelCatalog2.model(forClass: "2-6")!
  static let fruncir = ModelCatalog2.model(forClass: "3-1")!
  static let dirigir = ModelCatalog2.model(forClass: "3-2")!
  static let distinguir = ModelCatalog2.model(forClass: "3-3")!
  static let delinquir = ModelCatalog2.model(forClass: "3-4")!
  static let bullir = ModelCatalog2.model(forClass: "3-5")!
  static let bruñir = ModelCatalog2.model(forClass: "3-6")!
  static let reunir = ModelCatalog2.model(forClass: "3-7")!
  static let prohibir = ModelCatalog2.model(forClass: "3-8")!
  static let abrir = ModelCatalog2.model(forClass: "3-9")!
  static let cubrir = ModelCatalog2.model(forClass: "3-10")!
  static let escribir = ModelCatalog2.model(forClass: "3-11")!
  static let imprimir = ModelCatalog2.model(forClass: "3-12")!
  static let pudrir = ModelCatalog2.model(forClass: "3-13")!
  static let abolir = ModelCatalog2.model(forClass: "3-14")!
  static let pensar = ModelCatalog2.model(forClass: "4A")!
  static let negar = ModelCatalog2.model(forClass: "4A-1")!
  static let empezar = ModelCatalog2.model(forClass: "4A-2")!
  static let errar = ModelCatalog2.model(forClass: "4A-3")!
  static let mostrar = ModelCatalog2.model(forClass: "4B")!
  static let colgar = ModelCatalog2.model(forClass: "4B-2")!
  static let forzar = ModelCatalog2.model(forClass: "4B-3")!
  static let agorar = ModelCatalog2.model(forClass: "4B-4")!
  static let perder = ModelCatalog2.model(forClass: "5A")!
  static let mover = ModelCatalog2.model(forClass: "5B")!
  static let cocer = ModelCatalog2.model(forClass: "5B-1")!
  static let oler = ModelCatalog2.model(forClass: "5B-2")!
  static let resolver = ModelCatalog2.model(forClass: "5B-3")!
  static let volver = ModelCatalog2.model(forClass: "5B-4")!
  static let sentir = ModelCatalog2.model(forClass: "6A")!
  static let erguir = ModelCatalog2.model(forClass: "6A-1")!
  static let pedir = ModelCatalog2.model(forClass: "6B")!
  static let elegir = ModelCatalog2.model(forClass: "6B-1")!
  static let seguir = ModelCatalog2.model(forClass: "6B-2")!
  static let ceñir = ModelCatalog2.model(forClass: "6B-3")!
  static let reir = ModelCatalog2.model(forClass: "6B-4")!
  static let dormir = ModelCatalog2.model(forClass: "6C")!
  static let morir = ModelCatalog2.model(forClass: "6C-1")!
  static let conocer = ModelCatalog2.model(forClass: "7A")!
  static let yacer = ModelCatalog2.model(forClass: "7A-1")!
  static let placer = ModelCatalog2.model(forClass: "7A-2")!
  static let lucir = ModelCatalog2.model(forClass: "7B")!
  static let construir = ModelCatalog2.model(forClass: "8")!
  static let caer = ModelCatalog2.model(forClass: "9")!
  static let raer = ModelCatalog2.model(forClass: "9-1")!
  static let roer = ModelCatalog2.model(forClass: "9-2")!
  static let salir = ModelCatalog2.model(forClass: "11")!
  static let valer = ModelCatalog2.model(forClass: "12")!
  static let asir = ModelCatalog2.model(forClass: "13")!
  static let ver = ModelCatalog2.model(forClass: "14")!
  static let prever = ModelCatalog2.model(forClass: "14-1")!
  static let discernir = ModelCatalog2.model(forClass: "15")!
  static let jugar = ModelCatalog2.model(forClass: "16")!
  static let adquirir = ModelCatalog2.model(forClass: "17")!
  static let arguir = ModelCatalog2.model(forClass: "18")!
  static let ser = ModelCatalog2.model(forClass: "19")!
  static let estar = ModelCatalog2.model(forClass: "20")!
  static let haber = ModelCatalog2.model(forClass: "21")!
  static let saber = ModelCatalog2.model(forClass: "22")!
  static let caber = ModelCatalog2.model(forClass: "23")!
  static let ir = ModelCatalog2.model(forClass: "24")!
  static let dar = ModelCatalog2.model(forClass: "25")!
  static let poder = ModelCatalog2.model(forClass: "26")!
  static let querer = ModelCatalog2.model(forClass: "27")!
  static let decir = ModelCatalog2.model(forClass: "28")!
  static let predecir = ModelCatalog2.model(forClass: "28-1")!
  static let bendecir = ModelCatalog2.model(forClass: "28-2")!
  static let hacer = ModelCatalog2.model(forClass: "29")!
  static let rehacer = ModelCatalog2.model(forClass: "29-1")!
  static let poner = ModelCatalog2.model(forClass: "30")!
  static let tener = ModelCatalog2.model(forClass: "31")!
  static let venir = ModelCatalog2.model(forClass: "32")!
  static let traer = ModelCatalog2.model(forClass: "33")!
  static let conducirFull = ModelCatalog2.model(forClass: "34")!
  static let andarFull = ModelCatalog2.model(forClass: "35")!

  // Phase-4 *scaffold* models that isolate one tense system in a test — not
  // catalog classes (the full builds their verbs follow are 31/34/35/28). Kept
  // local; they prove the §4.6/§4.7 machinery on its own.
  static let andar = VerbModel2(base: .ar, features: [StemFeature2.strongPreterite(from: "and", to: "anduv"), PreteriteEndings2.spEnd])
  static let tenerSpEnd = VerbModel2(base: .er, features: [StemFeature2.strongPreterite(from: "ten", to: "tuv"), PreteriteEndings2.spEnd])
  static let conducir = VerbModel2(base: .ir, features: [
    StemFeature2.zc,
    StemFeature2.strongPreterite(from: "conduc", to: "conduj"),
    PreteriteEndings2.spJend
  ])
  static let decirSpJend = VerbModel2(base: .ir, features: [StemFeature2.strongPreterite(from: "dec", to: "dij"), PreteriteEndings2.spJend])
  static let tenerFDr = VerbModel2(base: .er, features: [FutureEndings2.fDr])
  static let decirFContract = VerbModel2(base: .ir, features: [StemFeature2.contractedFuture(from: "dec", to: "di"), FutureEndings2.fContract])

  // Phase-5b two-form-participle exemplars. freír/inscribir follow classes
  // 6B-4/3-11 but carry a richer participle (frito/freído, inscrito/inscripto);
  // kept local to exercise the alternate-PP path without overstating the catalog.
  static func residue(_ pairs: [(Tense2, String)]) -> LiteralSlotOverride2 {
    LiteralSlotOverride2(overrides: pairs.map { (slot: $0.0, form: $0.1) })
  }
  static let freir = VerbModel2(base: .ir, features: [
    StemVowel2.rEiStr, StemVowel2.rEiWk, CollapseDoubleI2.collapse,
    IrregularParticiple2("fre", "frito", alternate: "freído"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "frío"), (.presenteDeIndicativo(.secondSingular), "fríes"),
      (.presenteDeIndicativo(.thirdSingular), "fríe"), (.presenteDeIndicativo(.firstPlural), "freímos"),
      (.presenteDeIndicativo(.thirdPlural), "fríen"),
      (.pretérito(.secondSingular), "freíste"), (.pretérito(.firstPlural), "freímos"),
      (.pretérito(.secondPlural), "freísteis"),
      (.presenteDeSubjuntivo(.firstSingular), "fría"), (.presenteDeSubjuntivo(.secondSingular), "frías"),
      (.presenteDeSubjuntivo(.thirdSingular), "fría"), (.presenteDeSubjuntivo(.thirdPlural), "frían"),
      (.imperativoAfirmativo(.secondSingular), "fríe"), (.imperativoAfirmativo(.secondPlural), "freíd"),
    ]),
  ])
  static let inscribir = VerbModel2(base: .ir, features: [IrregularParticiple2("scrib", "scrito", alternate: "scripto")])

  // MARK: - Phase 6A: catalog new builds, aliases & completeness

  // The four classes never built as test exemplars before, and the prefix-accent
  // aliases — all resolved through the catalog, conjugated against the oracle.
  static let trocar = ModelCatalog2.model(forClass: "4B-1")!
  static let desosar = ModelCatalog2.model(forClass: "4B-5")!
  static let avergonzar = ModelCatalog2.model(forClass: "4B-6")!
  static let oir = ModelCatalog2.model(forClass: "10")!

  // 4B-1 trocar = mostrar (d-ue) + o-car (c→qu).
  @Test("trocar (4B-1) — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["trueco", "truecas", "trueca", "trocamos", "trocáis", "truecan"]))
  func trocarPresent(person: PersonNumber2, expected: String) {
    expectForm("trocar", model: Self.trocar, .presenteDeIndicativo(person), expected)
  }

  @Test("trocar (4B-1) — diphthong + c→qu edges", arguments: [
    (Tense2.presenteDeSubjuntivo(.firstSingular), "trueque"),
    (.presenteDeSubjuntivo(.firstPlural), "troquemos"),
    (.pretérito(.firstSingular), "troqué"),
    (.imperativoAfirmativo(.secondSingular), "trueca"),
    (.imperativoAfirmativo(.secondPlural), "trocad"),
  ])
  func trocarEdges(tense: Tense2, expected: String) {
    expectForm("trocar", model: Self.trocar, tense, expected)
  }

  // 4B-5 desosar = d-ue-hue on an -ar base (deshueso).
  @Test("desosar (4B-5) — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["deshueso", "deshuesas", "deshuesa", "desosamos", "desosáis", "deshuesan"]))
  func desosarPresent(person: PersonNumber2, expected: String) {
    expectForm("desosar", model: Self.desosar, .presenteDeIndicativo(person), expected)
  }

  @Test("desosar (4B-5) — subjunctive + imperative + regular preterite", arguments: [
    (Tense2.presenteDeSubjuntivo(.firstSingular), "deshuese"),
    (.presenteDeSubjuntivo(.firstPlural), "desosemos"),
    (.imperativoAfirmativo(.secondSingular), "deshuesa"),
    (.imperativoAfirmativo(.secondPlural), "desosad"),
    (.pretérito(.firstSingular), "desosé"),
  ])
  func desosarEdges(tense: Tense2, expected: String) {
    expectForm("desosar", model: Self.desosar, tense, expected)
  }

  // 4B-6 avergonzar = d-ue-gue (GO→GÜE) + o-zar (Z→C).
  @Test("avergonzar (4B-6) — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["avergüenzo", "avergüenzas", "avergüenza", "avergonzamos", "avergonzáis", "avergüenzan"]))
  func avergonzarPresent(person: PersonNumber2, expected: String) {
    expectForm("avergonzar", model: Self.avergonzar, .presenteDeIndicativo(person), expected)
  }

  @Test("avergonzar (4B-6) — subjunctive (üe + z→c)", arguments: zip(PersonNumber2.oracleOrder,
    ["avergüence", "avergüences", "avergüence", "avergoncemos", "avergoncéis", "avergüencen"]))
  func avergonzarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("avergonzar", model: Self.avergonzar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("avergonzar (4B-6) — preterite 1s (z→c) + imperative", arguments: [
    (Tense2.pretérito(.firstSingular), "avergoncé"),
    (.pretérito(.thirdSingular), "avergonzó"),
    (.imperativoAfirmativo(.secondSingular), "avergüenza"),
  ])
  func avergonzarEdges(tense: Tense2, expected: String) {
    expectForm("avergonzar", model: Self.avergonzar, tense, expected)
  }

  // 10 oír — full paradigm against the oracle (the never-exemplar'd -go/-y/hiatus mix).
  @Test("oír (10) — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["oigo", "oyes", "oye", "oímos", "oís", "oyen"]))
  func oirPresent(person: PersonNumber2, expected: String) {
    expectForm("oír", model: Self.oir, .presenteDeIndicativo(person), expected)
  }

  @Test("oír (10) — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["oí", "oíste", "oyó", "oímos", "oísteis", "oyeron"]))
  func oirPreterite(person: PersonNumber2, expected: String) {
    expectForm("oír", model: Self.oir, .pretérito(person), expected)
  }

  @Test("oír (10) — presente de subjuntivo (oig-)", arguments: zip(PersonNumber2.oracleOrder,
    ["oiga", "oigas", "oiga", "oigamos", "oigáis", "oigan"]))
  func oirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("oír", model: Self.oir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("oír (10) — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["oyera", "oyeras", "oyera", "oyéramos", "oyerais", "oyeran"]))
  func oirImperfectSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("oír", model: Self.oir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("oír (10) — future, imperative & non-finite", arguments: [
    (Tense2.futuro(.firstSingular), "oiré"),
    (.condicional(.firstPlural), "oiríamos"),
    (.imperfectoDeIndicativo(.firstSingular), "oía"),
    (.imperativoAfirmativo(.secondSingular), "oye"),
    (.imperativoAfirmativo(.secondPlural), "oíd"),
    (.imperativoAfirmativo(.firstPlural), "oigamos"),   // derived from PS
    (.participioPasado, "oído"),
    (.gerundio, "oyendo"),
  ])
  func oirMixed(tense: Tense2, expected: String) {
    expectForm("oír", model: Self.oir, tense, expected)
  }

  // The prefix-accent aliases (29-2/30-1/31-1/32-1) resolve to the parent model and
  // ride free on the compound stem — proving no distinct model is needed (§1).
  @Test("prefix-accent aliases conjugate on their own stem", arguments: [
    ("satisfacer", "29-2", Tense2.presenteDeIndicativo(.firstSingular), "satisfago"),
    ("satisfacer", "29-2", .pretérito(.thirdSingular), "satisfizo"),
    ("satisfacer", "29-2", .participioPasado, "satisfecho"),
    ("satisfacer", "29-2", .imperativoAfirmativo(.secondSingular), "satisfaz"),
    ("suponer", "30-1", .presenteDeIndicativo(.firstSingular), "supongo"),
    ("suponer", "30-1", .participioPasado, "supuesto"),
    ("suponer", "30-1", .imperativoAfirmativo(.secondSingular), "supón"),
    ("obtener", "31-1", .pretérito(.firstSingular), "obtuve"),
    ("obtener", "31-1", .futuro(.firstSingular), "obtendré"),
    ("obtener", "31-1", .imperativoAfirmativo(.secondSingular), "obtén"),
    ("convenir", "32-1", .presenteDeIndicativo(.firstSingular), "convengo"),
    ("convenir", "32-1", .imperativoAfirmativo(.secondSingular), "convén"),
    ("convenir", "32-1", .gerundio, "conviniendo"),
  ])
  func prefixAccentAliases(infinitive: String, classNumber: String, tense: Tense2, expected: String) {
    guard let model = ModelCatalog2.model(forClass: classNumber) else {
      Issue.record("alias class \(classNumber) must resolve")
      return
    }
    expectForm(infinitive, model: model, tense, expected)
  }

  // Completeness invariant (crux 2): every distinct Model # in Annex B resolves to
  // a catalog entry, so no verb can map to a missing model. The 106 numbers are
  // generated from `docs/annex_b_verb_models.md` (Phase 6B replaces this literal
  // with the resource-derived set once the map ships); the count guards the list.
  static let annexBModelNumbers: [String] = [
    "1", "1-1", "1-2", "1-3", "1-4", "1-5", "1-6", "1-7", "1-8", "1-9",
    "1-10", "1-11", "1-12", "1-13", "1-14", "1-15",
    "2", "2-1", "2-2", "2-3", "2-4", "2-5", "2-6",
    "3", "3-1", "3-2", "3-3", "3-4", "3-5", "3-6", "3-7", "3-8", "3-9",
    "3-10", "3-11", "3-12", "3-13", "3-14",
    "4A", "4A-1", "4A-2", "4A-3", "4B", "4B-1", "4B-2", "4B-3", "4B-4", "4B-5", "4B-6",
    "5A", "5B", "5B-1", "5B-2", "5B-3", "5B-4",
    "6A", "6A-1", "6B", "6B-1", "6B-2", "6B-3", "6B-4", "6C", "6C-1",
    "7A", "7A-1", "7A-2", "7B", "8", "9", "9-1", "9-2", "10", "11", "12", "13",
    "14", "14-1", "15", "16", "17", "18",
    "19", "20", "21", "22", "23", "24", "25", "26", "27",
    "28", "28-1", "28-2", "29", "29-1", "29-2", "30", "30-1", "31", "31-1",
    "32", "32-1", "33", "34", "35",
  ]

  @Test("catalog completeness — Annex B has exactly 106 distinct model numbers")
  func annexBCount() {
    #expect(Set(Self.annexBModelNumbers).count == 106, "Annex B distinct model numbers")
  }

  @Test("catalog completeness — every Annex B model number resolves", arguments: annexBModelNumbers)
  func everyAnnexBNumberResolves(classNumber: String) {
    #expect(ModelCatalog2.model(forClass: classNumber) != nil, "no catalog entry for class \(classNumber)")
  }

  // MARK: - cantar (regular -ar)

  @Test("cantar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["canto", "cantas", "canta", "cantamos", "cantáis", "cantan"]))
  func cantarPresent(person: PersonNumber2, expected: String) {
    expectForm("cantar", .presenteDeIndicativo(person), expected)
  }

  @Test("cantar — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["canté", "cantaste", "cantó", "cantamos", "cantasteis", "cantaron"]))
  func cantarPreterite(person: PersonNumber2, expected: String) {
    expectForm("cantar", .pretérito(person), expected)
  }

  @Test("cantar — imperfecto de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["cantaba", "cantabas", "cantaba", "cantábamos", "cantabais", "cantaban"]))
  func cantarImperfect(person: PersonNumber2, expected: String) {
    expectForm("cantar", .imperfectoDeIndicativo(person), expected)
  }

  @Test("cantar — futuro", arguments: zip(PersonNumber2.oracleOrder,
    ["cantaré", "cantarás", "cantará", "cantaremos", "cantaréis", "cantarán"]))
  func cantarFuture(person: PersonNumber2, expected: String) {
    expectForm("cantar", .futuro(person), expected)
  }

  @Test("cantar — condicional", arguments: zip(PersonNumber2.oracleOrder,
    ["cantaría", "cantarías", "cantaría", "cantaríamos", "cantaríais", "cantarían"]))
  func cantarConditional(person: PersonNumber2, expected: String) {
    expectForm("cantar", .condicional(person), expected)
  }

  @Test("cantar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["cante", "cantes", "cante", "cantemos", "cantéis", "canten"]))
  func cantarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("cantar", .presenteDeSubjuntivo(person), expected)
  }

  @Test("cantar — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["cantara", "cantaras", "cantara", "cantáramos", "cantarais", "cantaran"]))
  func cantarImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("cantar", .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("cantar — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["cantase", "cantases", "cantase", "cantásemos", "cantaseis", "cantasen"]))
  func cantarImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("cantar", .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("cantar — imperative & non-finite")
  func cantarImperativeAndNonFinite() {
    expectForm("cantar", .imperativoAfirmativo(.secondSingular), "canta")
    expectForm("cantar", .imperativoAfirmativo(.secondPlural), "cantad")
    expectForm("cantar", .participioPasado, "cantado")
    expectForm("cantar", .gerundio, "cantando")
  }

  // MARK: - comer (regular -er)

  @Test("comer — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["como", "comes", "come", "comemos", "coméis", "comen"]))
  func comerPresent(person: PersonNumber2, expected: String) {
    expectForm("comer", .presenteDeIndicativo(person), expected)
  }

  @Test("comer — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["comí", "comiste", "comió", "comimos", "comisteis", "comieron"]))
  func comerPreterite(person: PersonNumber2, expected: String) {
    expectForm("comer", .pretérito(person), expected)
  }

  @Test("comer — imperfecto de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["comía", "comías", "comía", "comíamos", "comíais", "comían"]))
  func comerImperfect(person: PersonNumber2, expected: String) {
    expectForm("comer", .imperfectoDeIndicativo(person), expected)
  }

  @Test("comer — futuro", arguments: zip(PersonNumber2.oracleOrder,
    ["comeré", "comerás", "comerá", "comeremos", "comeréis", "comerán"]))
  func comerFuture(person: PersonNumber2, expected: String) {
    expectForm("comer", .futuro(person), expected)
  }

  @Test("comer — condicional", arguments: zip(PersonNumber2.oracleOrder,
    ["comería", "comerías", "comería", "comeríamos", "comeríais", "comerían"]))
  func comerConditional(person: PersonNumber2, expected: String) {
    expectForm("comer", .condicional(person), expected)
  }

  @Test("comer — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["coma", "comas", "coma", "comamos", "comáis", "coman"]))
  func comerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("comer", .presenteDeSubjuntivo(person), expected)
  }

  @Test("comer — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["comiera", "comieras", "comiera", "comiéramos", "comierais", "comieran"]))
  func comerImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("comer", .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("comer — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["comiese", "comieses", "comiese", "comiésemos", "comieseis", "comiesen"]))
  func comerImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("comer", .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("comer — imperative & non-finite")
  func comerImperativeAndNonFinite() {
    expectForm("comer", .imperativoAfirmativo(.secondSingular), "come")
    expectForm("comer", .imperativoAfirmativo(.secondPlural), "comed")
    expectForm("comer", .participioPasado, "comido")
    expectForm("comer", .gerundio, "comiendo")
  }

  // MARK: - subir (regular -ir)

  @Test("subir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["subo", "subes", "sube", "subimos", "subís", "suben"]))
  func subirPresent(person: PersonNumber2, expected: String) {
    expectForm("subir", .presenteDeIndicativo(person), expected)
  }

  @Test("subir — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["subí", "subiste", "subió", "subimos", "subisteis", "subieron"]))
  func subirPreterite(person: PersonNumber2, expected: String) {
    expectForm("subir", .pretérito(person), expected)
  }

  @Test("subir — imperfecto de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["subía", "subías", "subía", "subíamos", "subíais", "subían"]))
  func subirImperfect(person: PersonNumber2, expected: String) {
    expectForm("subir", .imperfectoDeIndicativo(person), expected)
  }

  @Test("subir — futuro", arguments: zip(PersonNumber2.oracleOrder,
    ["subiré", "subirás", "subirá", "subiremos", "subiréis", "subirán"]))
  func subirFuture(person: PersonNumber2, expected: String) {
    expectForm("subir", .futuro(person), expected)
  }

  @Test("subir — condicional", arguments: zip(PersonNumber2.oracleOrder,
    ["subiría", "subirías", "subiría", "subiríamos", "subiríais", "subirían"]))
  func subirConditional(person: PersonNumber2, expected: String) {
    expectForm("subir", .condicional(person), expected)
  }

  @Test("subir — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["suba", "subas", "suba", "subamos", "subáis", "suban"]))
  func subirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("subir", .presenteDeSubjuntivo(person), expected)
  }

  @Test("subir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["subiera", "subieras", "subiera", "subiéramos", "subierais", "subieran"]))
  func subirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("subir", .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("subir — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["subiese", "subieses", "subiese", "subiésemos", "subieseis", "subiesen"]))
  func subirImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("subir", .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("subir — imperative & non-finite")
  func subirImperativeAndNonFinite() {
    expectForm("subir", .imperativoAfirmativo(.secondSingular), "sube")
    expectForm("subir", .imperativoAfirmativo(.secondPlural), "subid")
    expectForm("subir", .participioPasado, "subido")
    expectForm("subir", .gerundio, "subiendo")
  }

  // MARK: - Voseo (supplement)

  // Present 2s and affirmative imperative 2s are the only slots that differ from
  // tú; everything else falls back to the tú form.
  @Test("voseo (supplement)")
  func voseo() {
    expectForm("cantar", .presenteDeIndicativo(.secondSingularVos), "cantás")
    expectForm("comer", .presenteDeIndicativo(.secondSingularVos), "comés")
    expectForm("subir", .presenteDeIndicativo(.secondSingularVos), "subís")
    expectForm("cantar", .imperativoAfirmativo(.secondSingularVos), "cantá")
    expectForm("comer", .imperativoAfirmativo(.secondSingularVos), "comé")
    expectForm("subir", .imperativoAfirmativo(.secondSingularVos), "subí")
    // Falls back to tú elsewhere.
    expectForm("cantar", .pretérito(.secondSingularVos), "cantaste")
    expectForm("comer", .presenteDeSubjuntivo(.secondSingularVos), "comas")
  }

  // MARK: - Genericity & validation

  @Test("arbitrary regular verbs conjugate")
  func arbitraryRegularVerbsConjugate() {
    expectForm("hablar", .presenteDeIndicativo(.firstSingular), "hablo")
    expectForm("tomar", .pretérito(.thirdSingular), "tomó")
    expectForm("vivir", .presenteDeIndicativo(.firstSingular), "vivo")
    expectForm("aprender", .gerundio, "aprendiendo")
  }

  @Test("invalid input")
  func invalidInput() {
    assertFailure(Conjugator2.conjugate(infinitive: "a", tense: .gerundio), .infinitiveTooShort)
    if case .success = Conjugator2.conjugate(infinitive: "hello", tense: .gerundio) {
      Issue.record("Infinitive not ending in -ar/-er/-ir should fail.")
    }
  }

  // The non-2nd-person imperatives are now **derived** from the present
  // subjunctive (Phase 5), so they succeed where Phase 1–4 returned a failure.
  @Test("non-second-person imperative derives from the present subjunctive", arguments: [
    (Tense2.imperativoAfirmativo(.thirdSingular), "cante"),
    (.imperativoAfirmativo(.firstPlural), "cantemos"),
    (.imperativoAfirmativo(.thirdPlural), "canten"),
  ])
  func nonSecondPersonImperativeDerives(tense: Tense2, expected: String) {
    expectForm("cantar", tense, expected)
  }

  // MARK: - Phase 2: orthographic features (§4.1)

  // -ar consonant swaps fire before -e: PR 1s + PS{all}. PI/other PR stay regular.
  @Test("tocar — presente de subjuntivo (c→qu)", arguments: zip(PersonNumber2.oracleOrder,
    ["toque", "toques", "toque", "toquemos", "toquéis", "toquen"]))
  func tocarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("tocar", model: Self.tocar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("tocar — swap fires only before -e", arguments: [
    (Tense2.pretérito(.firstSingular), "toqué"),
    (.presenteDeIndicativo(.firstSingular), "toco"),
    (.pretérito(.thirdSingular), "tocó"),
  ])
  func tocarSwapEdges(tense: Tense2, expected: String) {
    expectForm("tocar", model: Self.tocar, tense, expected)
  }

  @Test("pagar — pretérito 1s (g→gu)")
  func pagarPreterite() {
    expectForm("pagar", model: Self.pagar, .pretérito(.firstSingular), "pagué")
  }

  @Test("pagar — presente de subjuntivo (g→gu)", arguments: zip(PersonNumber2.oracleOrder,
    ["pague", "pagues", "pague", "paguemos", "paguéis", "paguen"]))
  func pagarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("pagar", model: Self.pagar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("averiguar — pretérito 1s (gu→gü)")
  func averiguarPreterite() {
    expectForm("averiguar", model: Self.averiguar, .pretérito(.firstSingular), "averigüé")
  }

  @Test("averiguar — presente de subjuntivo (gu→gü)", arguments: zip(PersonNumber2.oracleOrder,
    ["averigüe", "averigües", "averigüe", "averigüemos", "averigüéis", "averigüen"]))
  func averiguarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("averiguar", model: Self.averiguar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("cazar — pretérito 1s (z→c)")
  func cazarPreterite() {
    expectForm("cazar", model: Self.cazar, .pretérito(.firstSingular), "cacé")
  }

  @Test("cazar — presente de subjuntivo (z→c)", arguments: zip(PersonNumber2.oracleOrder,
    ["cace", "caces", "cace", "cacemos", "cacéis", "cacen"]))
  func cazarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("cazar", model: Self.cazar, .presenteDeSubjuntivo(person), expected)
  }

  // -er/-ir consonant swaps fire before -a/-o: PI 1s + PS{all}.
  @Test("vencer — presente de subjuntivo (c→z)", arguments: zip(PersonNumber2.oracleOrder,
    ["venza", "venzas", "venza", "venzamos", "venzáis", "venzan"]))
  func vencerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("vencer", model: Self.vencer, .presenteDeSubjuntivo(person), expected)
  }

  @Test("vencer — swap fires only before -a/-o", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "venzo"),
    (.presenteDeIndicativo(.secondSingular), "vences"),
  ])
  func vencerSwapEdges(tense: Tense2, expected: String) {
    expectForm("vencer", model: Self.vencer, tense, expected)
  }

  @Test("fruncir — presente de indicativo 1s (c→z)")
  func fruncirPresentFirstSingular() {
    expectForm("fruncir", model: Self.fruncir, .presenteDeIndicativo(.firstSingular), "frunzo")
  }

  @Test("fruncir — presente de subjuntivo (c→z)", arguments: zip(PersonNumber2.oracleOrder,
    ["frunza", "frunzas", "frunza", "frunzamos", "frunzáis", "frunzan"]))
  func fruncirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("fruncir", model: Self.fruncir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("coger — presente de indicativo 1s (g→j)")
  func cogerPresentFirstSingular() {
    expectForm("coger", model: Self.coger, .presenteDeIndicativo(.firstSingular), "cojo")
  }

  @Test("coger — presente de subjuntivo (g→j)", arguments: zip(PersonNumber2.oracleOrder,
    ["coja", "cojas", "coja", "cojamos", "cojáis", "cojan"]))
  func cogerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("coger", model: Self.coger, .presenteDeSubjuntivo(person), expected)
  }

  @Test("dirigir — presente de indicativo 1s (g→j)")
  func dirigirPresentFirstSingular() {
    expectForm("dirigir", model: Self.dirigir, .presenteDeIndicativo(.firstSingular), "dirijo")
  }

  @Test("dirigir — presente de subjuntivo (g→j)", arguments: zip(PersonNumber2.oracleOrder,
    ["dirija", "dirijas", "dirija", "dirijamos", "dirijáis", "dirijan"]))
  func dirigirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("dirigir", model: Self.dirigir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("distinguir — presente de indicativo 1s (gu→g)")
  func distinguirPresentFirstSingular() {
    expectForm("distinguir", model: Self.distinguir, .presenteDeIndicativo(.firstSingular), "distingo")
  }

  @Test("distinguir — presente de subjuntivo (gu→g)", arguments: zip(PersonNumber2.oracleOrder,
    ["distinga", "distingas", "distinga", "distingamos", "distingáis", "distingan"]))
  func distinguirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("distinguir", model: Self.distinguir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("delinquir — presente de indicativo 1s (qu→c)")
  func delinquirPresentFirstSingular() {
    expectForm("delinquir", model: Self.delinquir, .presenteDeIndicativo(.firstSingular), "delinco")
  }

  @Test("delinquir — presente de subjuntivo (qu→c)", arguments: zip(PersonNumber2.oracleOrder,
    ["delinca", "delincas", "delinca", "delincamos", "delincáis", "delincan"]))
  func delinquirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("delinquir", model: Self.delinquir, .presenteDeSubjuntivo(person), expected)
  }

  // o-yhiatus: i→y in PR{3s,3p}+GER+IS{all}, plus written accents on the regular
  // -i- forms (PR{2s,1p,2p}, PP). Full paradigm against leer (2-3).
  @Test("leer — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["leo", "lees", "lee", "leemos", "leéis", "leen"]))
  func leerPresent(person: PersonNumber2, expected: String) {
    expectForm("leer", model: Self.leer, .presenteDeIndicativo(person), expected)
  }

  @Test("leer — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["leí", "leíste", "leyó", "leímos", "leísteis", "leyeron"]))
  func leerPreterite(person: PersonNumber2, expected: String) {
    expectForm("leer", model: Self.leer, .pretérito(person), expected)
  }

  @Test("leer — imperfecto de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["leía", "leías", "leía", "leíamos", "leíais", "leían"]))
  func leerImperfect(person: PersonNumber2, expected: String) {
    expectForm("leer", model: Self.leer, .imperfectoDeIndicativo(person), expected)
  }

  @Test("leer — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["leyera", "leyeras", "leyera", "leyéramos", "leyerais", "leyeran"]))
  func leerImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("leer", model: Self.leer, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("leer — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["leyese", "leyeses", "leyese", "leyésemos", "leyeseis", "leyesen"]))
  func leerImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("leer", model: Self.leer, .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("leer — non-finite (y glide + accents)")
  func leerNonFinite() {
    expectForm("leer", model: Self.leer, .gerundio, "leyendo")
    expectForm("leer", model: Self.leer, .participioPasado, "leído")
  }

  // o-llñ: -i- absorbed after ll/ñ (-ió→-ó, -ieron→-eron, -iendo→-endo), no accents.
  @Test("empeller — pretérito (-i- absorbed after ll)", arguments: zip(PersonNumber2.oracleOrder,
    ["empellí", "empelliste", "empelló", "empellimos", "empellisteis", "empelleron"]))
  func empellerPreterite(person: PersonNumber2, expected: String) {
    expectForm("empeller", model: Self.empeller, .pretérito(person), expected)
  }

  @Test("empeller — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["empellera", "empelleras", "empellera", "empelléramos", "empellerais", "empelleran"]))
  func empellerImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("empeller", model: Self.empeller, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("tañer — pretérito (-i- absorbed after ñ)", arguments: zip(PersonNumber2.oracleOrder,
    ["tañí", "tañiste", "tañó", "tañimos", "tañisteis", "tañeron"]))
  func tanerPreterite(person: PersonNumber2, expected: String) {
    expectForm("tañer", model: Self.tañer, .pretérito(person), expected)
  }

  @Test("bullir — pretérito (-i- absorbed after ll)", arguments: zip(PersonNumber2.oracleOrder,
    ["bullí", "bulliste", "bulló", "bullimos", "bullisteis", "bulleron"]))
  func bullirPreterite(person: PersonNumber2, expected: String) {
    expectForm("bullir", model: Self.bullir, .pretérito(person), expected)
  }

  @Test("bruñir — pretérito (-i- absorbed after ñ)", arguments: zip(PersonNumber2.oracleOrder,
    ["bruñí", "bruñiste", "bruñó", "bruñimos", "bruñisteis", "bruñeron"]))
  func brunirPreterite(person: PersonNumber2, expected: String) {
    expectForm("bruñir", model: Self.bruñir, .pretérito(person), expected)
  }

  @Test("o-llñ — gerunds (-iendo → -endo after ll/ñ)")
  func oLlnGerunds() {
    expectForm("empeller", model: Self.empeller, .gerundio, "empellendo")
    expectForm("tañer", model: Self.tañer, .gerundio, "tañendo")
    expectForm("bullir", model: Self.bullir, .gerundio, "bullendo")
    expectForm("bruñir", model: Self.bruñir, .gerundio, "bruñendo")
  }

  // MARK: - Phase 2: accent features (§4.2)

  @Test("enviar — presente de indicativo (i→í in STR)", arguments: zip(PersonNumber2.oracleOrder,
    ["envío", "envías", "envía", "enviamos", "enviáis", "envían"]))
  func enviarPresent(person: PersonNumber2, expected: String) {
    expectForm("enviar", model: Self.enviar, .presenteDeIndicativo(person), expected)
  }

  @Test("enviar — presente de subjuntivo (i→í in STR)", arguments: zip(PersonNumber2.oracleOrder,
    ["envíe", "envíes", "envíe", "enviemos", "enviéis", "envíen"]))
  func enviarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("enviar", model: Self.enviar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("enviar — imperative 2s")
  func enviarImperative() {
    expectForm("enviar", model: Self.enviar, .imperativoAfirmativo(.secondSingular), "envía")
  }

  @Test("actuar — presente de indicativo (u→ú in STR)", arguments: zip(PersonNumber2.oracleOrder,
    ["actúo", "actúas", "actúa", "actuamos", "actuáis", "actúan"]))
  func actuarPresent(person: PersonNumber2, expected: String) {
    expectForm("actuar", model: Self.actuar, .presenteDeIndicativo(person), expected)
  }

  @Test("actuar — presente de subjuntivo (u→ú in STR)", arguments: zip(PersonNumber2.oracleOrder,
    ["actúe", "actúes", "actúe", "actuemos", "actuéis", "actúen"]))
  func actuarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("actuar", model: Self.actuar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("actuar — imperative 2s")
  func actuarImperative() {
    expectForm("actuar", model: Self.actuar, .imperativoAfirmativo(.secondSingular), "actúa")
  }

  // a-stem family (1-5…1-9, 3-7, 3-8): accent on the stem vowel in STR only.
  @Test("aislar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["aíslo", "aíslas", "aísla", "aislamos", "aisláis", "aíslan"]))
  func aislarPresent(person: PersonNumber2, expected: String) {
    expectForm("aislar", model: Self.aislar, .presenteDeIndicativo(person), expected)
  }

  @Test("aislar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["aísle", "aísles", "aísle", "aislemos", "aisléis", "aíslen"]))
  func aislarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("aislar", model: Self.aislar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("aullar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["aúllo", "aúllas", "aúlla", "aullamos", "aulláis", "aúllan"]))
  func aullarPresent(person: PersonNumber2, expected: String) {
    expectForm("aullar", model: Self.aullar, .presenteDeIndicativo(person), expected)
  }

  @Test("descafeinar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["descafeíno", "descafeínas", "descafeína", "descafeinamos", "descafeináis", "descafeínan"]))
  func descafeinarPresent(person: PersonNumber2, expected: String) {
    expectForm("descafeinar", model: Self.descafeinar, .presenteDeIndicativo(person), expected)
  }

  @Test("rehusar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["rehúso", "rehúsas", "rehúsa", "rehusamos", "rehusáis", "rehúsan"]))
  func rehusarPresent(person: PersonNumber2, expected: String) {
    expectForm("rehusar", model: Self.rehusar, .presenteDeIndicativo(person), expected)
  }

  @Test("amohinar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["amohíno", "amohínas", "amohína", "amohinamos", "amohináis", "amohínan"]))
  func amohinarPresent(person: PersonNumber2, expected: String) {
    expectForm("amohinar", model: Self.amohinar, .presenteDeIndicativo(person), expected)
  }

  @Test("reunir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["reúno", "reúnes", "reúne", "reunimos", "reunís", "reúnen"]))
  func reunirPresent(person: PersonNumber2, expected: String) {
    expectForm("reunir", model: Self.reunir, .presenteDeIndicativo(person), expected)
  }

  @Test("prohibir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["prohíbo", "prohíbes", "prohíbe", "prohibimos", "prohibís", "prohíben"]))
  func prohibirPresent(person: PersonNumber2, expected: String) {
    expectForm("prohibir", model: Self.prohibir, .presenteDeIndicativo(person), expected)
  }

  @Test("prohibir — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["prohíba", "prohíbas", "prohíba", "prohibamos", "prohibáis", "prohíban"]))
  func prohibirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("prohibir", model: Self.prohibir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("a-stem family — imperatives")
  func aStemFamilyImperatives() {
    expectForm("aislar", model: Self.aislar, .imperativoAfirmativo(.secondSingular), "aísla")
    expectForm("aislar", model: Self.aislar, .imperativoAfirmativo(.secondPlural), "aislad")
    expectForm("reunir", model: Self.reunir, .imperativoAfirmativo(.secondSingular), "reúne")
  }

  // MARK: - Phase 2: composition (multiple features, last-wins)

  // a-stem touches STR; the orthographic swap touches PR 1s / PS{all}. They overlap
  // on PS (both apply, stacking) and diverge on PR 1s (swap only) and PI 1s (accent
  // only).
  @Test("ahincar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["ahínco", "ahíncas", "ahínca", "ahincamos", "ahincáis", "ahíncan"]))
  func ahincarPresent(person: PersonNumber2, expected: String) {
    expectForm("ahincar", model: Self.ahincar, .presenteDeIndicativo(person), expected)
  }

  @Test("ahincar — presente de subjuntivo (accent + c→qu stack)", arguments: zip(PersonNumber2.oracleOrder,
    ["ahínque", "ahínques", "ahínque", "ahinquemos", "ahinquéis", "ahínquen"]))
  func ahincarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("ahincar", model: Self.ahincar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("ahincar — pretérito (swap only, no accent)", arguments: zip(PersonNumber2.oracleOrder,
    ["ahinqué", "ahincaste", "ahincó", "ahincamos", "ahincasteis", "ahincaron"]))
  func ahincarPreterite(person: PersonNumber2, expected: String) {
    expectForm("ahincar", model: Self.ahincar, .pretérito(person), expected)
  }

  @Test("cabrahigar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["cabrahígo", "cabrahígas", "cabrahíga", "cabrahigamos", "cabrahigáis", "cabrahígan"]))
  func cabrahigarPresent(person: PersonNumber2, expected: String) {
    expectForm("cabrahigar", model: Self.cabrahigar, .presenteDeIndicativo(person), expected)
  }

  @Test("cabrahigar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["cabrahígue", "cabrahígues", "cabrahígue", "cabrahiguemos", "cabrahiguéis", "cabrahíguen"]))
  func cabrahigarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("cabrahigar", model: Self.cabrahigar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("enraizar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["enraízo", "enraízas", "enraíza", "enraizamos", "enraizáis", "enraízan"]))
  func enraizarPresent(person: PersonNumber2, expected: String) {
    expectForm("enraizar", model: Self.enraizar, .presenteDeIndicativo(person), expected)
  }

  @Test("enraizar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["enraíce", "enraíces", "enraíce", "enraicemos", "enraicéis", "enraícen"]))
  func enraizarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("enraizar", model: Self.enraizar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("europeizar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["europeízo", "europeízas", "europeíza", "europeizamos", "europeizáis", "europeízan"]))
  func europeizarPresent(person: PersonNumber2, expected: String) {
    expectForm("europeizar", model: Self.europeizar, .presenteDeIndicativo(person), expected)
  }

  @Test("europeizar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["europeíce", "europeíces", "europeíce", "europeicemos", "europeicéis", "europeícen"]))
  func europeizarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("europeizar", model: Self.europeizar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("composition (a-stem + orthographic) — singletons")
  func compositionAStemPlusOrthographicSingletons() {
    expectForm("ahincar", model: Self.ahincar, .imperativoAfirmativo(.secondSingular), "ahínca")
    expectForm("cabrahigar", model: Self.cabrahigar, .pretérito(.firstSingular), "cabrahigué")
    expectForm("enraizar", model: Self.enraizar, .pretérito(.firstSingular), "enraicé")
    expectForm("europeizar", model: Self.europeizar, .pretérito(.firstSingular), "europeicé")
  }

  // MARK: - Phase 2: prefix-invariance (the end-anchored rule)

  // A prefixed verb whose stem isn't a listed model rides on its base's features
  // for free, because every feature operation is anchored to the end of the stem.
  @Test("prefix invariance — orthographic & accent (end-anchored)")
  func prefixInvarianceOrthographic() {
    expectForm("releer", model: Self.leer, .pretérito(.thirdSingular), "releyó")
    expectForm("releer", model: Self.leer, .pretérito(.thirdPlural), "releyeron")
    expectForm("releer", model: Self.leer, .gerundio, "releyendo")
    expectForm("releer", model: Self.leer, .pretérito(.firstPlural), "releímos")
    expectForm("reenviar", model: Self.enviar, .presenteDeIndicativo(.firstSingular), "reenvío")
    expectForm("reenviar", model: Self.enviar, .presenteDeIndicativo(.thirdPlural), "reenvían")
  }

  // MARK: - Phase 3: stem-vowel diphthongs (§4.3, STR slots)

  // Diphthong with no raise: the change surfaces only in STR; unstressed forms stay
  // regular.
  @Test("pensar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["pienso", "piensas", "piensa", "pensamos", "pensáis", "piensan"]))
  func pensarPresent(person: PersonNumber2, expected: String) {
    expectForm("pensar", model: Self.pensar, .presenteDeIndicativo(person), expected)
  }

  @Test("pensar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["piense", "pienses", "piense", "pensemos", "penséis", "piensen"]))
  func pensarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("pensar", model: Self.pensar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("pensar — pretérito (no diphthong, unstressed)", arguments: zip(PersonNumber2.oracleOrder,
    ["pensé", "pensaste", "pensó", "pensamos", "pensasteis", "pensaron"]))
  func pensarPreterite(person: PersonNumber2, expected: String) {
    expectForm("pensar", model: Self.pensar, .pretérito(person), expected)
  }

  // imp 2s diphthongs (STR); voseo present-2s / imperative-2s ride the regular stem.
  @Test("pensar — imperative & voseo", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "piensa"),
    (.imperativoAfirmativo(.secondPlural), "pensad"),
    (.presenteDeIndicativo(.secondSingularVos), "pensás"),
    (.imperativoAfirmativo(.secondSingularVos), "pensá"),
  ])
  func pensarImperativeAndVoseo(tense: Tense2, expected: String) {
    expectForm("pensar", model: Self.pensar, tense, expected)
  }

  @Test("mostrar — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["muestro", "muestras", "muestra", "mostramos", "mostráis", "muestran"]))
  func mostrarPresent(person: PersonNumber2, expected: String) {
    expectForm("mostrar", model: Self.mostrar, .presenteDeIndicativo(person), expected)
  }

  @Test("mostrar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["muestre", "muestres", "muestre", "mostremos", "mostréis", "muestren"]))
  func mostrarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("mostrar", model: Self.mostrar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("mostrar — imperative 2s")
  func mostrarImperative() {
    expectForm("mostrar", model: Self.mostrar, .imperativoAfirmativo(.secondSingular), "muestra")
  }

  @Test("perder — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["pierdo", "pierdes", "pierde", "perdemos", "perdéis", "pierden"]))
  func perderPresent(person: PersonNumber2, expected: String) {
    expectForm("perder", model: Self.perder, .presenteDeIndicativo(person), expected)
  }

  @Test("perder — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["pierda", "pierdas", "pierda", "perdamos", "perdáis", "pierdan"]))
  func perderPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("perder", model: Self.perder, .presenteDeSubjuntivo(person), expected)
  }

  @Test("mover — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["muevo", "mueves", "mueve", "movemos", "movéis", "mueven"]))
  func moverPresent(person: PersonNumber2, expected: String) {
    expectForm("mover", model: Self.mover, .presenteDeIndicativo(person), expected)
  }

  @Test("mover — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["mueva", "muevas", "mueva", "movamos", "mováis", "muevan"]))
  func moverPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("mover", model: Self.mover, .presenteDeSubjuntivo(person), expected)
  }

  // Spelled variants — same operation, a different target string.
  @Test("errar — presente de indicativo (e→ye)", arguments: zip(PersonNumber2.oracleOrder,
    ["yerro", "yerras", "yerra", "erramos", "erráis", "yerran"]))
  func errarPresent(person: PersonNumber2, expected: String) {
    expectForm("errar", model: Self.errar, .presenteDeIndicativo(person), expected)
  }

  @Test("errar — presente de subjuntivo (e→ye)", arguments: zip(PersonNumber2.oracleOrder,
    ["yerre", "yerres", "yerre", "erremos", "erréis", "yerren"]))
  func errarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("errar", model: Self.errar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("agorar — presente de indicativo (o→üe)", arguments: zip(PersonNumber2.oracleOrder,
    ["agüero", "agüeras", "agüera", "agoramos", "agoráis", "agüeran"]))
  func agorarPresent(person: PersonNumber2, expected: String) {
    expectForm("agorar", model: Self.agorar, .presenteDeIndicativo(person), expected)
  }

  @Test("agorar — presente de subjuntivo (o→üe)", arguments: zip(PersonNumber2.oracleOrder,
    ["agüere", "agüeres", "agüere", "agoremos", "agoréis", "agüeren"]))
  func agorarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("agorar", model: Self.agorar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("oler — presente de indicativo (o→hue)", arguments: zip(PersonNumber2.oracleOrder,
    ["huelo", "hueles", "huele", "olemos", "oléis", "huelen"]))
  func olerPresent(person: PersonNumber2, expected: String) {
    expectForm("oler", model: Self.oler, .presenteDeIndicativo(person), expected)
  }

  @Test("oler — presente de subjuntivo (o→hue)", arguments: zip(PersonNumber2.oracleOrder,
    ["huela", "huelas", "huela", "olamos", "oláis", "huelan"]))
  func olerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("oler", model: Self.oler, .presenteDeSubjuntivo(person), expected)
  }

  // Rare diphthongs.
  @Test("adquirir — presente de indicativo (i→ie)", arguments: zip(PersonNumber2.oracleOrder,
    ["adquiero", "adquieres", "adquiere", "adquirimos", "adquirís", "adquieren"]))
  func adquirirPresent(person: PersonNumber2, expected: String) {
    expectForm("adquirir", model: Self.adquirir, .presenteDeIndicativo(person), expected)
  }

  @Test("adquirir — presente de subjuntivo (i→ie)", arguments: zip(PersonNumber2.oracleOrder,
    ["adquiera", "adquieras", "adquiera", "adquiramos", "adquiráis", "adquieran"]))
  func adquirirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("adquirir", model: Self.adquirir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("jugar — presente de indicativo (u→ue)", arguments: zip(PersonNumber2.oracleOrder,
    ["juego", "juegas", "juega", "jugamos", "jugáis", "juegan"]))
  func jugarPresent(person: PersonNumber2, expected: String) {
    expectForm("jugar", model: Self.jugar, .presenteDeIndicativo(person), expected)
  }

  @Test("jugar — presente de subjuntivo (u→ue + o-gar)", arguments: zip(PersonNumber2.oracleOrder,
    ["juegue", "juegues", "juegue", "juguemos", "juguéis", "jueguen"]))
  func jugarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("jugar", model: Self.jugar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("jugar — pretérito 1s (o-gar)")
  func jugarPreterite() {
    expectForm("jugar", model: Self.jugar, .pretérito(.firstSingular), "jugué")
  }

  // Control case: discernir (15) diphthongizes in STR but its WK slots stay regular.
  @Test("discernir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["discierno", "disciernes", "discierne", "discernimos", "discernís", "disciernen"]))
  func discernirPresent(person: PersonNumber2, expected: String) {
    expectForm("discernir", model: Self.discernir, .presenteDeIndicativo(person), expected)
  }

  @Test("discernir — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["discierna", "disciernas", "discierna", "discernamos", "discernáis", "disciernan"]))
  func discernirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("discernir", model: Self.discernir, .presenteDeSubjuntivo(person), expected)
  }

  // WK stays regular: no *discirnió / *discirnamos.
  @Test("discernir — weak slots stay regular", arguments: [
    (Tense2.pretérito(.thirdSingular), "discernió"),
    (.pretérito(.thirdPlural), "discernieron"),
    (.gerundio, "discerniendo"),
  ])
  func discernirWeakSlots(tense: Tense2, expected: String) {
    expectForm("discernir", model: Self.discernir, tense, expected)
  }

  // MARK: - Phase 3: -ir weak-slot raising (§4.4) — the STR/WK split

  // sentir (6A) = subir + d-ie + r-ei-wk. PS{1s,2s,3s,3p} diphthong (STR),
  // PS{1p,2p} raise (WK).
  @Test("sentir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["siento", "sientes", "siente", "sentimos", "sentís", "sienten"]))
  func sentirPresent(person: PersonNumber2, expected: String) {
    expectForm("sentir", model: Self.sentir, .presenteDeIndicativo(person), expected)
  }

  @Test("sentir — pretérito (WK raise in 3s/3p)", arguments: zip(PersonNumber2.oracleOrder,
    ["sentí", "sentiste", "sintió", "sentimos", "sentisteis", "sintieron"]))
  func sentirPreterite(person: PersonNumber2, expected: String) {
    expectForm("sentir", model: Self.sentir, .pretérito(person), expected)
  }

  @Test("sentir — presente de subjuntivo (STR/WK split)", arguments: zip(PersonNumber2.oracleOrder,
    ["sienta", "sientas", "sienta", "sintamos", "sintáis", "sientan"]))
  func sentirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("sentir", model: Self.sentir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("sentir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["sintiera", "sintieras", "sintiera", "sintiéramos", "sintierais", "sintieran"]))
  func sentirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("sentir", model: Self.sentir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("sentir — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["sintiese", "sintieses", "sintiese", "sintiésemos", "sintieseis", "sintiesen"]))
  func sentirImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("sentir", model: Self.sentir, .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("sentir — gerund & imperatives", arguments: [
    (Tense2.gerundio, "sintiendo"),
    (.imperativoAfirmativo(.secondSingular), "siente"),
    (.imperativoAfirmativo(.secondPlural), "sentid"),
  ])
  func sentirGerundAndImperatives(tense: Tense2, expected: String) {
    expectForm("sentir", model: Self.sentir, tense, expected)
  }

  // pedir (6B) = subir + r-ei-str + r-ei-wk. Raise everywhere, no diphthong.
  @Test("pedir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["pido", "pides", "pide", "pedimos", "pedís", "piden"]))
  func pedirPresent(person: PersonNumber2, expected: String) {
    expectForm("pedir", model: Self.pedir, .presenteDeIndicativo(person), expected)
  }

  @Test("pedir — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["pedí", "pediste", "pidió", "pedimos", "pedisteis", "pidieron"]))
  func pedirPreterite(person: PersonNumber2, expected: String) {
    expectForm("pedir", model: Self.pedir, .pretérito(person), expected)
  }

  @Test("pedir — presente de subjuntivo (both halves raise)", arguments: zip(PersonNumber2.oracleOrder,
    ["pida", "pidas", "pida", "pidamos", "pidáis", "pidan"]))
  func pedirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("pedir", model: Self.pedir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("pedir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["pidiera", "pidieras", "pidiera", "pidiéramos", "pidierais", "pidieran"]))
  func pedirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("pedir", model: Self.pedir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("pedir — gerund & imperative 2s", arguments: [
    (Tense2.gerundio, "pidiendo"),
    (.imperativoAfirmativo(.secondSingular), "pide"),
  ])
  func pedirGerundAndImperative(tense: Tense2, expected: String) {
    expectForm("pedir", model: Self.pedir, tense, expected)
  }

  // dormir (6C) = subir + d-ue + r-ou-wk. Same STR/WK split as sentir, o → u.
  @Test("dormir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["duermo", "duermes", "duerme", "dormimos", "dormís", "duermen"]))
  func dormirPresent(person: PersonNumber2, expected: String) {
    expectForm("dormir", model: Self.dormir, .presenteDeIndicativo(person), expected)
  }

  @Test("dormir — pretérito", arguments: zip(PersonNumber2.oracleOrder,
    ["dormí", "dormiste", "durmió", "dormimos", "dormisteis", "durmieron"]))
  func dormirPreterite(person: PersonNumber2, expected: String) {
    expectForm("dormir", model: Self.dormir, .pretérito(person), expected)
  }

  @Test("dormir — presente de subjuntivo (STR/WK split)", arguments: zip(PersonNumber2.oracleOrder,
    ["duerma", "duermas", "duerma", "durmamos", "durmáis", "duerman"]))
  func dormirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("dormir", model: Self.dormir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("dormir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["durmiera", "durmieras", "durmiera", "durmiéramos", "durmierais", "durmieran"]))
  func dormirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("dormir", model: Self.dormir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("dormir — gerund (WK raise)")
  func dormirGerund() {
    expectForm("dormir", model: Self.dormir, .gerundio, "durmiendo")
  }

  // MARK: - Phase 3: cross-phase composition (§4.3/§4.4 feature + a §4.1 swap)

  // Watch the preterite/subjunctive divergence: niegue (diphthong + g→gu in PS) vs
  // negué (PR 1s gets the swap only — PR 1s ∉ STR, so no diphthong).
  @Test("negar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["niegue", "niegues", "niegue", "neguemos", "neguéis", "nieguen"]))
  func negarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("negar", model: Self.negar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("negar — diphthong vs swap divergence", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "niego"),
    (.pretérito(.firstSingular), "negué"),
  ])
  func negarDivergence(tense: Tense2, expected: String) {
    expectForm("negar", model: Self.negar, tense, expected)
  }

  @Test("empezar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["empiece", "empieces", "empiece", "empecemos", "empecéis", "empiecen"]))
  func empezarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("empezar", model: Self.empezar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("colgar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["cuelgue", "cuelgues", "cuelgue", "colguemos", "colguéis", "cuelguen"]))
  func colgarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("colgar", model: Self.colgar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("forzar — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["fuerce", "fuerces", "fuerce", "forcemos", "forcéis", "fuercen"]))
  func forzarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("forzar", model: Self.forzar, .presenteDeSubjuntivo(person), expected)
  }

  // PR 1s ∉ STR → the swap fires but the diphthong does not.
  @Test("diphthong + orthographic — pretérito 1s (swap only)")
  func diphthongPlusOrthographicPreterites() {
    expectForm("empezar", model: Self.empezar, .pretérito(.firstSingular), "empecé")
    expectForm("colgar", model: Self.colgar, .pretérito(.firstSingular), "colgué")
    expectForm("forzar", model: Self.forzar, .pretérito(.firstSingular), "forcé")
  }

  @Test("cocer — presente de indicativo (d-ue + c→z)", arguments: zip(PersonNumber2.oracleOrder,
    ["cuezo", "cueces", "cuece", "cocemos", "cocéis", "cuecen"]))
  func cocerPresent(person: PersonNumber2, expected: String) {
    expectForm("cocer", model: Self.cocer, .presenteDeIndicativo(person), expected)
  }

  @Test("cocer — presente de subjuntivo (d-ue + c→z)", arguments: zip(PersonNumber2.oracleOrder,
    ["cueza", "cuezas", "cueza", "cozamos", "cozáis", "cuezan"]))
  func cocerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("cocer", model: Self.cocer, .presenteDeSubjuntivo(person), expected)
  }

  @Test("elegir — presente de indicativo (raise + g→j)", arguments: zip(PersonNumber2.oracleOrder,
    ["elijo", "eliges", "elige", "elegimos", "elegís", "eligen"]))
  func elegirPresent(person: PersonNumber2, expected: String) {
    expectForm("elegir", model: Self.elegir, .presenteDeIndicativo(person), expected)
  }

  @Test("elegir — presente de subjuntivo (raise + g→j)", arguments: zip(PersonNumber2.oracleOrder,
    ["elija", "elijas", "elija", "elijamos", "elijáis", "elijan"]))
  func elegirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("elegir", model: Self.elegir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("elegir — WK raise (no swap before -i-)", arguments: [
    (Tense2.pretérito(.thirdSingular), "eligió"),
    (.gerundio, "eligiendo"),
  ])
  func elegirWeakSlots(tense: Tense2, expected: String) {
    expectForm("elegir", model: Self.elegir, tense, expected)
  }

  @Test("seguir — presente de indicativo (raise + gu→g)", arguments: zip(PersonNumber2.oracleOrder,
    ["sigo", "sigues", "sigue", "seguimos", "seguís", "siguen"]))
  func seguirPresent(person: PersonNumber2, expected: String) {
    expectForm("seguir", model: Self.seguir, .presenteDeIndicativo(person), expected)
  }

  @Test("seguir — presente de subjuntivo (raise + gu→g)", arguments: zip(PersonNumber2.oracleOrder,
    ["siga", "sigas", "siga", "sigamos", "sigáis", "sigan"]))
  func seguirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("seguir", model: Self.seguir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("seguir — WK raise", arguments: [
    (Tense2.pretérito(.thirdSingular), "siguió"),
    (.gerundio, "siguiendo"),
  ])
  func seguirWeakSlots(tense: Tense2, expected: String) {
    expectForm("seguir", model: Self.seguir, tense, expected)
  }

  // ceñir (6B-3) = pedir-raises + o-llñ — the raise feeds the i, the palatal
  // absorbs it (ciñó, ciñendo).
  @Test("ceñir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["ciño", "ciñes", "ciñe", "ceñimos", "ceñís", "ciñen"]))
  func cenirPresent(person: PersonNumber2, expected: String) {
    expectForm("ceñir", model: Self.ceñir, .presenteDeIndicativo(person), expected)
  }

  @Test("ceñir — pretérito (raise + palatal absorb)", arguments: zip(PersonNumber2.oracleOrder,
    ["ceñí", "ceñiste", "ciñó", "ceñimos", "ceñisteis", "ciñeron"]))
  func cenirPreterite(person: PersonNumber2, expected: String) {
    expectForm("ceñir", model: Self.ceñir, .pretérito(person), expected)
  }

  @Test("ceñir — presente de subjuntivo", arguments: zip(PersonNumber2.oracleOrder,
    ["ciña", "ciñas", "ciña", "ciñamos", "ciñáis", "ciñan"]))
  func cenirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("ceñir", model: Self.ceñir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("ceñir — gerund (raise + palatal absorb)")
  func cenirGerund() {
    expectForm("ceñir", model: Self.ceñir, .gerundio, "ciñendo")
  }

  // MARK: - Phase 3: prefix-invariance (the end-anchored rule for stem vowels)

  // A prefixed verb whose stem isn't a listed model gets the diphthong/raise on its
  // own last stem vowel, prefix riding free.
  @Test("stem-vowel prefix invariance (end-anchored)")
  func stemVowelPrefixInvariance() {
    let comprobar = VerbModel2(base: .ar, features: [StemVowel2.dUe])
    expectForm("comprobar", model: comprobar, .presenteDeIndicativo(.firstSingular), "compruebo")
    expectForm("comprobar", model: comprobar, .presenteDeIndicativo(.thirdPlural), "comprueban")
    let repetir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk])
    expectForm("repetir", model: repetir, .presenteDeIndicativo(.firstSingular), "repito")
    expectForm("repetir", model: repetir, .gerundio, "repitiendo")
  }

  // MARK: - Phase 4: irregular 1s + present subjunctive (§4.5)

  // zc: c→zc in PI 1s + PS{all}, built on the regular stem (subj-from-1s bundled).
  @Test("conocer — presente de subjuntivo (c→zc)", arguments: zip(PersonNumber2.oracleOrder,
    ["conozca", "conozcas", "conozca", "conozcamos", "conozcáis", "conozcan"]))
  func conocerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("conocer", model: Self.conocer, .presenteDeSubjuntivo(person), expected)
  }

  // The 1s carries the swap; 2s stays regular; the preterite stays regular too.
  @Test("conocer — 1s swap, other slots regular", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "conozco"),
    (.presenteDeIndicativo(.secondSingular), "conoces"),
    (.pretérito(.firstSingular), "conocí"),
  ])
  func conocerSlots(tense: Tense2, expected: String) {
    expectForm("conocer", model: Self.conocer, tense, expected)
  }

  @Test("lucir — presente de indicativo 1s (c→zc)")
  func lucirPresentFirstSingular() {
    expectForm("lucir", model: Self.lucir, .presenteDeIndicativo(.firstSingular), "luzco")
  }

  @Test("lucir — presente de subjuntivo (c→zc)", arguments: zip(PersonNumber2.oracleOrder,
    ["luzca", "luzcas", "luzca", "luzcamos", "luzcáis", "luzcan"]))
  func lucirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("lucir", model: Self.lucir, .presenteDeSubjuntivo(person), expected)
  }

  // g1-g: append g to the regular stem in PI 1s + PS{all}.
  @Test("asir — presente de subjuntivo (g-add)", arguments: zip(PersonNumber2.oracleOrder,
    ["asga", "asgas", "asga", "asgamos", "asgáis", "asgan"]))
  func asirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("asir", model: Self.asir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("asir — 1s g-add, 2s regular", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "asgo"),
    (.presenteDeIndicativo(.secondSingular), "ases"),
  ])
  func asirSlots(tense: Tense2, expected: String) {
    expectForm("asir", model: Self.asir, tense, expected)
  }

  // g1-ig + o-yhiatus: caigo/caiga AND the hiatus glide/accents (caíste/caído/cayó/
  // cayera) — the accent fires because the -i- follows a strong vowel (a).
  @Test("caer — presente de subjuntivo (ig-add)", arguments: zip(PersonNumber2.oracleOrder,
    ["caiga", "caigas", "caiga", "caigamos", "caigáis", "caigan"]))
  func caerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("caer", model: Self.caer, .presenteDeSubjuntivo(person), expected)
  }

  @Test("caer — pretérito (hiatus glide + accents)", arguments: zip(PersonNumber2.oracleOrder,
    ["caí", "caíste", "cayó", "caímos", "caísteis", "cayeron"]))
  func caerPreterite(person: PersonNumber2, expected: String) {
    expectForm("caer", model: Self.caer, .pretérito(person), expected)
  }

  @Test("caer — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["cayera", "cayeras", "cayera", "cayéramos", "cayerais", "cayeran"]))
  func caerImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("caer", model: Self.caer, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("caer — 1s insert & non-finite", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "caigo"),
    (.participioPasado, "caído"),
    (.gerundio, "cayendo"),
  ])
  func caerSlots(tense: Tense2, expected: String) {
    expectForm("caer", model: Self.caer, tense, expected)
  }

  // y-add + o-yhiatus: the i→y glide everywhere it surfaces BUT the -uir hiatus
  // accents do NOT fire (construiste/construimos/construido) — the -i- follows the
  // weak -u-, not a strong vowel.
  @Test("construir — presente de indicativo (y glide)", arguments: zip(PersonNumber2.oracleOrder,
    ["construyo", "construyes", "construye", "construimos", "construís", "construyen"]))
  func construirPresent(person: PersonNumber2, expected: String) {
    expectForm("construir", model: Self.construir, .presenteDeIndicativo(person), expected)
  }

  @Test("construir — presente de subjuntivo (y glide)", arguments: zip(PersonNumber2.oracleOrder,
    ["construya", "construyas", "construya", "construyamos", "construyáis", "construyan"]))
  func construirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("construir", model: Self.construir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("construir — pretérito (y glide, no accents)", arguments: zip(PersonNumber2.oracleOrder,
    ["construí", "construiste", "construyó", "construimos", "construisteis", "construyeron"]))
  func construirPreterite(person: PersonNumber2, expected: String) {
    expectForm("construir", model: Self.construir, .pretérito(person), expected)
  }

  @Test("construir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["construyera", "construyeras", "construyera", "construyéramos", "construyerais", "construyeran"]))
  func construirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("construir", model: Self.construir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("construir — non-finite (glide but no -uir accents)", arguments: [
    (Tense2.gerundio, "construyendo"),
    (.participioPasado, "construido"),
  ])
  func construirNonFinite(tense: Tense2, expected: String) {
    expectForm("construir", model: Self.construir, tense, expected)
  }

  // §4.5 + §4.7 integration: g1-g for the 1s/subjunctive, f-dr for future/conditional.
  @Test("salir — presente de subjuntivo (g-add)", arguments: zip(PersonNumber2.oracleOrder,
    ["salga", "salgas", "salga", "salgamos", "salgáis", "salgan"]))
  func salirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("salir", model: Self.salir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("salir — futuro (f-dr)", arguments: zip(PersonNumber2.oracleOrder,
    ["saldré", "saldrás", "saldrá", "saldremos", "saldréis", "saldrán"]))
  func salirFuture(person: PersonNumber2, expected: String) {
    expectForm("salir", model: Self.salir, .futuro(person), expected)
  }

  @Test("salir — condicional (f-dr)", arguments: zip(PersonNumber2.oracleOrder,
    ["saldría", "saldrías", "saldría", "saldríamos", "saldríais", "saldrían"]))
  func salirConditional(person: PersonNumber2, expected: String) {
    expectForm("salir", model: Self.salir, .condicional(person), expected)
  }

  @Test("salir — presente de indicativo 1s (g-add)")
  func salirPresentFirstSingular() {
    expectForm("salir", model: Self.salir, .presenteDeIndicativo(.firstSingular), "salgo")
  }

  @Test("valer — futuro (f-dr)", arguments: zip(PersonNumber2.oracleOrder,
    ["valdré", "valdrás", "valdrá", "valdremos", "valdréis", "valdrán"]))
  func valerFuture(person: PersonNumber2, expected: String) {
    expectForm("valer", model: Self.valer, .futuro(person), expected)
  }

  @Test("valer — 1s & subjunctive 1s (g-add)", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "valgo"),
    (.presenteDeSubjuntivo(.firstSingular), "valga"),
  ])
  func valerSlots(tense: Tense2, expected: String) {
    expectForm("valer", model: Self.valer, tense, expected)
  }

  // MARK: - Phase 4: strong / suppletive preterites (§4.6)

  // sp-end is base-independent: andar/estar are -ar verbs yet take the -ie- IS.
  @Test("andar — pretérito (strong stem)", arguments: zip(PersonNumber2.oracleOrder,
    ["anduve", "anduviste", "anduvo", "anduvimos", "anduvisteis", "anduvieron"]))
  func andarPreterite(person: PersonNumber2, expected: String) {
    expectForm("andar", model: Self.andar, .pretérito(person), expected)
  }

  @Test("andar — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["anduviera", "anduvieras", "anduviera", "anduviéramos", "anduvierais", "anduvieran"]))
  func andarImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("andar", model: Self.andar, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("andar — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["anduviese", "anduvieses", "anduviese", "anduviésemos", "anduvieseis", "anduviesen"]))
  func andarImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("andar", model: Self.andar, .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("estar — strong preterite slots", arguments: [
    (Tense2.pretérito(.firstSingular), "estuve"),
    (.imperfectoDeSubjuntivoRa(.firstSingular), "estuviera"),
  ])
  func estarSlots(tense: Tense2, expected: String) {
    let estar = VerbModel2(base: .ar, features: [StemFeature2.strongPreterite(from: "est", to: "estuv"), PreteriteEndings2.spEnd])
    expectForm("estar", model: estar, tense, expected)
  }

  @Test("tener — pretérito (strong stem)", arguments: zip(PersonNumber2.oracleOrder,
    ["tuve", "tuviste", "tuvo", "tuvimos", "tuvisteis", "tuvieron"]))
  func tenerStrongPreterite(person: PersonNumber2, expected: String) {
    expectForm("tener", model: Self.tenerSpEnd, .pretérito(person), expected)
  }

  @Test("tener — imperfecto de subjuntivo 1s (strong stem)")
  func tenerStrongImperfectSubjunctive() {
    expectForm("tener", model: Self.tenerSpEnd, .imperfectoDeSubjuntivoRa(.firstSingular), "tuviera")
  }

  // sp-jend absorbs the i after j: 3p -eron (not -ieron), IS -era (not -iera).
  @Test("conducir — pretérito (j-stem absorbs i)", arguments: zip(PersonNumber2.oracleOrder,
    ["conduje", "condujiste", "condujo", "condujimos", "condujisteis", "condujeron"]))
  func conducirPreterite(person: PersonNumber2, expected: String) {
    expectForm("conducir", model: Self.conducir, .pretérito(person), expected)
  }

  @Test("conducir — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["condujera", "condujeras", "condujera", "condujéramos", "condujerais", "condujeran"]))
  func conducirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("conducir", model: Self.conducir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("conducir — presente de indicativo 1s (zc)")
  func conducirPresentFirstSingular() {
    expectForm("conducir", model: Self.conducir, .presenteDeIndicativo(.firstSingular), "conduzco")
  }

  @Test("decir — pretérito (j-stem absorbs i)", arguments: zip(PersonNumber2.oracleOrder,
    ["dije", "dijiste", "dijo", "dijimos", "dijisteis", "dijeron"]))
  func decirPreterite(person: PersonNumber2, expected: String) {
    expectForm("decir", model: Self.decirSpJend, .pretérito(person), expected)
  }

  @Test("decir — imperfecto de subjuntivo 1s (j-stem)")
  func decirImperfectSubjunctive() {
    expectForm("decir", model: Self.decirSpJend, .imperfectoDeSubjuntivoRa(.firstSingular), "dijera")
  }

  // wp-i: unaccented monosyllables, and -iera forced on an -ar base (dar → diera).
  @Test("dar — pretérito (weak monosyllables)", arguments: zip(PersonNumber2.oracleOrder,
    ["di", "diste", "dio", "dimos", "disteis", "dieron"]))
  func darPreterite(person: PersonNumber2, expected: String) {
    expectForm("dar", model: Self.dar, .pretérito(person), expected)
  }

  @Test("dar — imperfecto de subjuntivo (-ra, -iera on -ar base)", arguments: zip(PersonNumber2.oracleOrder,
    ["diera", "dieras", "diera", "diéramos", "dierais", "dieran"]))
  func darImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("dar", model: Self.dar, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("dar — imperfecto de subjuntivo 1s (-se)")
  func darImperfectSubjunctiveSe() {
    expectForm("dar", model: Self.dar, .imperfectoDeSubjuntivoSe(.firstSingular), "diese")
  }

  @Test("ver — pretérito (weak monosyllables)", arguments: zip(PersonNumber2.oracleOrder,
    ["vi", "viste", "vio", "vimos", "visteis", "vieron"]))
  func verPreterite(person: PersonNumber2, expected: String) {
    expectForm("ver", model: Self.ver, .pretérito(person), expected)
  }

  @Test("ver — imperfecto de subjuntivo 1s")
  func verImperfectSubjunctive() {
    expectForm("ver", model: Self.ver, .imperfectoDeSubjuntivoRa(.firstSingular), "viera")
  }

  // pret-fue: the suppletive fu- stem shared by ser and ir.
  @Test("ser — pretérito (suppletive fu-)", arguments: zip(PersonNumber2.oracleOrder,
    ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"]))
  func serPreterite(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .pretérito(person), expected)
  }

  @Test("ser — imperfecto de subjuntivo (-ra)", arguments: zip(PersonNumber2.oracleOrder,
    ["fuera", "fueras", "fuera", "fuéramos", "fuerais", "fueran"]))
  func serImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("ser — imperfecto de subjuntivo (-se)", arguments: zip(PersonNumber2.oracleOrder,
    ["fuese", "fueses", "fuese", "fuésemos", "fueseis", "fuesen"]))
  func serImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("ir — pretérito (suppletive fu-)", arguments: zip(PersonNumber2.oracleOrder,
    ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"]))
  func irPreterite(person: PersonNumber2, expected: String) {
    expectForm("ir", model: Self.ir, .pretérito(person), expected)
  }

  @Test("ir — imperfecto de subjuntivo 1s (-se)")
  func irImperfectSubjunctive() {
    expectForm("ir", model: Self.ir, .imperfectoDeSubjuntivoSe(.firstSingular), "fuese")
  }

  // MARK: - Phase 4: future / conditional stems (§4.7)

  // f-drope drops the theme -e- (-er → -r); querer's stem ends in r, so the future
  // doubles it (querré).
  @Test("haber — futuro (f-drope)", arguments: zip(PersonNumber2.oracleOrder,
    ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"]))
  func haberFuture(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .futuro(person), expected)
  }

  @Test("haber — condicional (f-drope)", arguments: zip(PersonNumber2.oracleOrder,
    ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"]))
  func haberConditional(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .condicional(person), expected)
  }

  @Test("querer — doubled r (f-drope on r-final stem)", arguments: [
    (Tense2.futuro(.firstSingular), "querré"),
    (.condicional(.thirdPlural), "querrían"),
  ])
  func quererSlots(tense: Tense2, expected: String) {
    let querer = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
    expectForm("querer", model: querer, tense, expected)
  }

  @Test("poder — futuro 1s (f-drope)")
  func poderFuture() {
    let poder = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
    expectForm("poder", model: poder, .futuro(.firstSingular), "podré")
  }

  // f-dr inserts d (drops the theme vowel).
  @Test("tener — futuro (f-dr)", arguments: zip(PersonNumber2.oracleOrder,
    ["tendré", "tendrás", "tendrá", "tendremos", "tendréis", "tendrán"]))
  func tenerFutureDr(person: PersonNumber2, expected: String) {
    expectForm("tener", model: Self.tenerFDr, .futuro(person), expected)
  }

  @Test("tener — condicional (f-dr)", arguments: zip(PersonNumber2.oracleOrder,
    ["tendría", "tendrías", "tendría", "tendríamos", "tendríais", "tendrían"]))
  func tenerConditionalDr(person: PersonNumber2, expected: String) {
    expectForm("tener", model: Self.tenerFDr, .condicional(person), expected)
  }

  @Test("poner — futuro 1s (f-dr)")
  func ponerFuture() {
    let poner = VerbModel2(base: .er, features: [FutureEndings2.fDr])
    expectForm("poner", model: poner, .futuro(.firstSingular), "pondré")
  }

  // f-contract: a per-verb contracted future stem (residue) + the f-drope endings.
  @Test("hacer — futuro (contracted stem)", arguments: zip(PersonNumber2.oracleOrder,
    ["haré", "harás", "hará", "haremos", "haréis", "harán"]))
  func hacerFuture(person: PersonNumber2, expected: String) {
    expectForm("hacer", model: Self.hacer, .futuro(person), expected)
  }

  @Test("hacer — condicional (contracted stem)", arguments: zip(PersonNumber2.oracleOrder,
    ["haría", "harías", "haría", "haríamos", "haríais", "harían"]))
  func hacerConditional(person: PersonNumber2, expected: String) {
    expectForm("hacer", model: Self.hacer, .condicional(person), expected)
  }

  @Test("decir — contracted future stem", arguments: [
    (Tense2.futuro(.firstSingular), "diré"),
    (.condicional(.thirdPlural), "dirían"),
  ])
  func decirFutureSlots(tense: Tense2, expected: String) {
    expectForm("decir", model: Self.decirFContract, tense, expected)
  }

  // MARK: - Phase 4: capstone — the whole phase in one verb (minus IMP residue)

  // tener (31) = comer + d-ie + g1-g + sp-end(tuv) + f-dr. Features are in §1
  // precedence order, so g1-g's subj-from-1s reset wins over the diphthong in PI 1s
  // and all of PS (tengo/tenga, not *tiengo/*tienga) while the diphthong still
  // surfaces in PI{2s,3s,3p} (tienes/tiene/tienen). Every slot is its own case.
  @Test("tener — capstone (whole phase)", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "tengo"),
    (.presenteDeIndicativo(.secondSingular), "tienes"),
    (.presenteDeIndicativo(.thirdSingular), "tiene"),
    (.presenteDeIndicativo(.firstPlural), "tenemos"),
    (.presenteDeIndicativo(.secondPlural), "tenéis"),
    (.presenteDeIndicativo(.thirdPlural), "tienen"),
    (.presenteDeSubjuntivo(.firstSingular), "tenga"),
    (.presenteDeSubjuntivo(.secondSingular), "tengas"),
    (.presenteDeSubjuntivo(.thirdSingular), "tenga"),
    (.presenteDeSubjuntivo(.firstPlural), "tengamos"),
    (.presenteDeSubjuntivo(.secondPlural), "tengáis"),
    (.presenteDeSubjuntivo(.thirdPlural), "tengan"),
    (.pretérito(.firstSingular), "tuve"),
    (.pretérito(.secondSingular), "tuviste"),
    (.pretérito(.thirdSingular), "tuvo"),
    (.pretérito(.firstPlural), "tuvimos"),
    (.pretérito(.secondPlural), "tuvisteis"),
    (.pretérito(.thirdPlural), "tuvieron"),
    (.imperfectoDeSubjuntivoRa(.firstSingular), "tuviera"),
    (.imperfectoDeSubjuntivoRa(.secondSingular), "tuvieras"),
    (.imperfectoDeSubjuntivoRa(.thirdSingular), "tuviera"),
    (.imperfectoDeSubjuntivoRa(.firstPlural), "tuviéramos"),
    (.imperfectoDeSubjuntivoRa(.secondPlural), "tuvierais"),
    (.imperfectoDeSubjuntivoRa(.thirdPlural), "tuvieran"),
    (.futuro(.firstSingular), "tendré"),
    (.futuro(.secondSingular), "tendrás"),
    (.futuro(.thirdSingular), "tendrá"),
    (.futuro(.firstPlural), "tendremos"),
    (.futuro(.secondPlural), "tendréis"),
    (.futuro(.thirdPlural), "tendrán"),
    (.condicional(.firstSingular), "tendría"),
    (.condicional(.secondSingular), "tendrías"),
    (.condicional(.thirdSingular), "tendría"),
    (.condicional(.firstPlural), "tendríamos"),
    (.condicional(.secondPlural), "tendríais"),
    (.condicional(.thirdPlural), "tendrían"),
  ])
  func tenerCapstone(tense: Tense2, expected: String) {
    expectForm("tener", model: Self.tener, tense, expected)
  }

  // venir (32) = subir + d-ie + r-ei-wk + g1-g + sp-end(vin) + f-dr. r-ei-wk would
  // raise PS{1p,2p} (ven→vin), but g1-g resets all of PS to veng- (vengamos, not
  // *vingamos) while the raise still drives the gerund (viniendo).
  @Test("venir — presente de indicativo", arguments: zip(PersonNumber2.oracleOrder,
    ["vengo", "vienes", "viene", "venimos", "venís", "vienen"]))
  func venirPresent(person: PersonNumber2, expected: String) {
    expectForm("venir", model: Self.venir, .presenteDeIndicativo(person), expected)
  }

  @Test("venir — presente de subjuntivo (g1-g reset wins)", arguments: zip(PersonNumber2.oracleOrder,
    ["venga", "vengas", "venga", "vengamos", "vengáis", "vengan"]))
  func venirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("venir", model: Self.venir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("venir — pretérito (strong stem)", arguments: zip(PersonNumber2.oracleOrder,
    ["vine", "viniste", "vino", "vinimos", "vinisteis", "vinieron"]))
  func venirPreterite(person: PersonNumber2, expected: String) {
    expectForm("venir", model: Self.venir, .pretérito(person), expected)
  }

  @Test("venir — gerund (raise) & future (f-dr)", arguments: [
    (Tense2.gerundio, "viniendo"),
    (.futuro(.firstSingular), "vendré"),
  ])
  func venirGerundAndFuture(tense: Tense2, expected: String) {
    expectForm("venir", model: Self.venir, tense, expected)
  }

  // MARK: - Phase 4: prefix-invariance (end-anchored inserts, strong & contracted stems)

  @Test("phase 4 prefix invariance (end-anchored)")
  func phase4PrefixInvariance() {
    expectForm("reconocer", model: Self.conocer, .presenteDeIndicativo(.firstSingular), "reconozco")
    expectForm("reconocer", model: Self.conocer, .presenteDeSubjuntivo(.firstSingular), "reconozca")

    expectForm("detener", model: Self.tener, .presenteDeIndicativo(.firstSingular), "detengo")
    expectForm("detener", model: Self.tener, .pretérito(.firstSingular), "detuve")
    expectForm("detener", model: Self.tener, .futuro(.firstSingular), "detendré")

    let poner = VerbModel2(base: .er, features: [
      StemFeature2.g1g,
      StemFeature2.strongPreterite(from: "pon", to: "pus"),
      PreteriteEndings2.spEnd,
      FutureEndings2.fDr
    ])
    expectForm("componer", model: poner, .pretérito(.firstSingular), "compuse")
    expectForm("componer", model: poner, .futuro(.firstSingular), "compondré")
  }

  // MARK: - Phase 5: imperative derivation (the last derivation rule)

  // usted/nosotros/ustedes derive from the present subjunctive; tú/vosotros stay
  // as the regular root; the irregular tú is scoped to .secondSingular so vos/vosotros
  // remain regular. A regular verb, a stem-changer, an irregular-tú verb, and ir.
  @Test("imperative derivation — regular (cantar)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "canta"),
    (.imperativoAfirmativo(.thirdSingular), "cante"),
    (.imperativoAfirmativo(.firstPlural), "cantemos"),
    (.imperativoAfirmativo(.secondPlural), "cantad"),
    (.imperativoAfirmativo(.thirdPlural), "canten"),
  ])
  func imperativeRegular(tense: Tense2, expected: String) {
    expectForm("cantar", tense, expected)
  }

  @Test("imperative derivation — stem-changer (pensar)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "piensa"),
    (.imperativoAfirmativo(.thirdSingular), "piense"),
    (.imperativoAfirmativo(.firstPlural), "pensemos"),
    (.imperativoAfirmativo(.secondPlural), "pensad"),
    (.imperativoAfirmativo(.thirdPlural), "piensen"),
  ])
  func imperativeStemChanger(tense: Tense2, expected: String) {
    expectForm("pensar", model: Self.pensar, tense, expected)
  }

  @Test("imperative derivation — irregular tú with regular vos/vosotros (tener)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "ten"),
    (.imperativoAfirmativo(.secondSingularVos), "tené"),
    (.imperativoAfirmativo(.thirdSingular), "tenga"),
    (.imperativoAfirmativo(.firstPlural), "tengamos"),
    (.imperativoAfirmativo(.secondPlural), "tened"),
    (.imperativoAfirmativo(.thirdPlural), "tengan"),
  ])
  func imperativeIrregularTu(tense: Tense2, expected: String) {
    expectForm("tener", model: Self.tener, tense, expected)
  }

  @Test("imperative derivation — ir (ve / vamos / id)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "ve"),
    (.imperativoAfirmativo(.thirdSingular), "vaya"),
    (.imperativoAfirmativo(.firstPlural), "vamos"),  // residue overrides the PS-derived vayamos
    (.imperativoAfirmativo(.secondPlural), "id"),
    (.imperativoAfirmativo(.thirdPlural), "vayan"),
  ])
  func imperativeIr(tense: Tense2, expected: String) {
    expectForm("ir", model: Self.ir, tense, expected)
  }

  // MARK: - Phase 5: classes 19–27 (new full builds)

  @Test("ser — presente de indicativo (suppletive, incl. vos sos)", arguments: zip(PersonNumber2.oracleOrder,
    ["soy", "eres", "es", "somos", "sois", "son"]))
  func serPresent(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .presenteDeIndicativo(person), expected)
  }

  @Test("ser — imperfecto de indicativo (era-)", arguments: zip(PersonNumber2.oracleOrder,
    ["era", "eras", "era", "éramos", "erais", "eran"]))
  func serImperfect(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .imperfectoDeIndicativo(person), expected)
  }

  @Test("ser — presente de subjuntivo (sea-)", arguments: zip(PersonNumber2.oracleOrder,
    ["sea", "seas", "sea", "seamos", "seáis", "sean"]))
  func serPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .presenteDeSubjuntivo(person), expected)
  }

  @Test("ser — futuro (regular ser-)", arguments: zip(PersonNumber2.oracleOrder,
    ["seré", "serás", "será", "seremos", "seréis", "serán"]))
  func serFuture(person: PersonNumber2, expected: String) {
    expectForm("ser", model: Self.ser, .futuro(person), expected)
  }

  @Test("ser — imperative, vos & non-finite", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "sé"),
    (.imperativoAfirmativo(.secondSingularVos), "sé"),
    (.imperativoAfirmativo(.secondPlural), "sed"),
    (.imperativoAfirmativo(.thirdSingular), "sea"),
    (.imperativoAfirmativo(.thirdPlural), "sean"),
    (.presenteDeIndicativo(.secondSingularVos), "sos"),
  ])
  func serImperativeVosNonFinite(tense: Tense2, expected: String) {
    expectForm("ser", model: Self.ser, tense, expected)
  }

  @Test("estar — presente de indicativo (estoy + stress shift)", arguments: zip(PersonNumber2.oracleOrder,
    ["estoy", "estás", "está", "estamos", "estáis", "están"]))
  func estarPresent(person: PersonNumber2, expected: String) {
    expectForm("estar", model: Self.estar, .presenteDeIndicativo(person), expected)
  }

  @Test("estar — pretérito (estuv)", arguments: zip(PersonNumber2.oracleOrder,
    ["estuve", "estuviste", "estuvo", "estuvimos", "estuvisteis", "estuvieron"]))
  func estarPreterite(person: PersonNumber2, expected: String) {
    expectForm("estar", model: Self.estar, .pretérito(person), expected)
  }

  @Test("estar — presente de subjuntivo (esté-)", arguments: zip(PersonNumber2.oracleOrder,
    ["esté", "estés", "esté", "estemos", "estéis", "estén"]))
  func estarPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("estar", model: Self.estar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("estar — derived imperatives", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "está"),
    (.imperativoAfirmativo(.thirdSingular), "esté"),
    (.imperativoAfirmativo(.firstPlural), "estemos"),
    (.imperativoAfirmativo(.thirdPlural), "estén"),
  ])
  func estarImperatives(tense: Tense2, expected: String) {
    expectForm("estar", model: Self.estar, tense, expected)
  }

  @Test("haber — presente de indicativo (he/has/ha…)", arguments: zip(PersonNumber2.oracleOrder,
    ["he", "has", "ha", "hemos", "habéis", "han"]))
  func haberPresent(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .presenteDeIndicativo(person), expected)
  }

  @Test("haber — pretérito (hub)", arguments: zip(PersonNumber2.oracleOrder,
    ["hube", "hubiste", "hubo", "hubimos", "hubisteis", "hubieron"]))
  func haberPreterite(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .pretérito(person), expected)
  }

  @Test("haber — futuro (habr-)", arguments: zip(PersonNumber2.oracleOrder,
    ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"]))
  func haberFutureClass(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .futuro(person), expected)
  }

  @Test("haber — presente de subjuntivo (haya-)", arguments: zip(PersonNumber2.oracleOrder,
    ["haya", "hayas", "haya", "hayamos", "hayáis", "hayan"]))
  func haberPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("haber", model: Self.haber, .presenteDeSubjuntivo(person), expected)
  }

  @Test("saber — present, preterite, future, subjunctive", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "sé"),
    (.presenteDeIndicativo(.secondSingular), "sabes"),
    (.pretérito(.firstSingular), "supe"),
    (.pretérito(.thirdPlural), "supieron"),
    (.futuro(.firstSingular), "sabré"),
    (.presenteDeSubjuntivo(.firstSingular), "sepa"),
    (.presenteDeSubjuntivo(.firstPlural), "sepamos"),
    (.imperativoAfirmativo(.thirdSingular), "sepa"),
    (.imperativoAfirmativo(.secondSingular), "sabe"),
  ])
  func saberSlots(tense: Tense2, expected: String) {
    expectForm("saber", model: Self.saber, tense, expected)
  }

  @Test("caber — present, preterite, future, subjunctive", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "quepo"),
    (.presenteDeIndicativo(.secondSingular), "cabes"),
    (.pretérito(.firstSingular), "cupe"),
    (.pretérito(.thirdPlural), "cupieron"),
    (.futuro(.firstSingular), "cabré"),
    (.presenteDeSubjuntivo(.firstSingular), "quepa"),
    (.presenteDeSubjuntivo(.firstPlural), "quepamos"),
  ])
  func caberSlots(tense: Tense2, expected: String) {
    expectForm("caber", model: Self.caber, tense, expected)
  }

  @Test("ir — presente de indicativo (voy/vas…)", arguments: zip(PersonNumber2.oracleOrder,
    ["voy", "vas", "va", "vamos", "vais", "van"]))
  func irPresent(person: PersonNumber2, expected: String) {
    expectForm("ir", model: Self.ir, .presenteDeIndicativo(person), expected)
  }

  @Test("ir — imperfecto de indicativo (iba-)", arguments: zip(PersonNumber2.oracleOrder,
    ["iba", "ibas", "iba", "íbamos", "ibais", "iban"]))
  func irImperfect(person: PersonNumber2, expected: String) {
    expectForm("ir", model: Self.ir, .imperfectoDeIndicativo(person), expected)
  }

  @Test("ir — presente de subjuntivo (vaya-)", arguments: zip(PersonNumber2.oracleOrder,
    ["vaya", "vayas", "vaya", "vayamos", "vayáis", "vayan"]))
  func irPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("ir", model: Self.ir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("ir — futuro & gerund", arguments: [
    (Tense2.futuro(.firstSingular), "iré"),
    (.futuro(.thirdPlural), "irán"),
    (.gerundio, "yendo"),
  ])
  func irFutureGerund(tense: Tense2, expected: String) {
    expectForm("ir", model: Self.ir, tense, expected)
  }

  @Test("dar — presente de indicativo (doy, monosyllable dais)", arguments: zip(PersonNumber2.oracleOrder,
    ["doy", "das", "da", "damos", "dais", "dan"]))
  func darPresent(person: PersonNumber2, expected: String) {
    expectForm("dar", model: Self.dar, .presenteDeIndicativo(person), expected)
  }

  @Test("dar — presente de subjuntivo (dé / des / dé …)", arguments: zip(PersonNumber2.oracleOrder,
    ["dé", "des", "dé", "demos", "deis", "den"]))
  func darPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("dar", model: Self.dar, .presenteDeSubjuntivo(person), expected)
  }

  @Test("dar — derived imperative usted = dé")
  func darImperativeUsted() {
    expectForm("dar", model: Self.dar, .imperativoAfirmativo(.thirdSingular), "dé")
  }

  @Test("poder — present, preterite, future, gerund", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "puedo"),
    (.pretérito(.firstSingular), "pude"),
    (.pretérito(.thirdPlural), "pudieron"),
    (.futuro(.firstSingular), "podré"),
    (.presenteDeSubjuntivo(.firstPlural), "podamos"),
    (.gerundio, "pudiendo"),
  ])
  func poderSlots(tense: Tense2, expected: String) {
    expectForm("poder", model: Self.poder, tense, expected)
  }

  @Test("querer — present, preterite, future", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "quiero"),
    (.pretérito(.firstSingular), "quise"),
    (.pretérito(.thirdSingular), "quiso"),
    (.futuro(.firstSingular), "querré"),
    (.condicional(.thirdPlural), "querrían"),
    (.presenteDeSubjuntivo(.firstPlural), "queramos"),
  ])
  func quererSlotsClass(tense: Tense2, expected: String) {
    expectForm("querer", model: Self.querer, tense, expected)
  }

  // MARK: - Phase 5: classes 28–35 (finish the Phase-4 partials with residue)

  @Test("decir — presente de indicativo (digo/dices…)", arguments: zip(PersonNumber2.oracleOrder,
    ["digo", "dices", "dice", "decimos", "decís", "dicen"]))
  func decirPresent(person: PersonNumber2, expected: String) {
    expectForm("decir", model: Self.decir, .presenteDeIndicativo(person), expected)
  }

  @Test("decir — presente de subjuntivo (dig-)", arguments: zip(PersonNumber2.oracleOrder,
    ["diga", "digas", "diga", "digamos", "digáis", "digan"]))
  func decirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("decir", model: Self.decir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("decir — preterite, future, participle, imperatives", arguments: [
    (Tense2.pretérito(.firstSingular), "dije"),
    (.pretérito(.thirdPlural), "dijeron"),
    (.futuro(.firstSingular), "diré"),
    (.participioPasado, "dicho"),
    (.gerundio, "diciendo"),
    (.imperativoAfirmativo(.secondSingular), "di"),
    (.imperativoAfirmativo(.secondSingularVos), "decí"),
    (.imperativoAfirmativo(.secondPlural), "decid"),
    (.imperativoAfirmativo(.firstPlural), "digamos"),
  ])
  func decirSlots(tense: Tense2, expected: String) {
    expectForm("decir", model: Self.decir, tense, expected)
  }

  @Test("predecir — regular tú, irregular future/participle", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "predice"),
    (.futuro(.firstSingular), "prediré"),
    (.participioPasado, "predicho"),
    (.pretérito(.firstSingular), "predije"),
  ])
  func predecirSlots(tense: Tense2, expected: String) {
    expectForm("predecir", model: Self.predecir, tense, expected)
  }

  @Test("bendecir — regular FU/CO/PP/tú, but irregular dig-/dij-", arguments: [
    (Tense2.futuro(.firstSingular), "bendeciré"),
    (.condicional(.firstSingular), "bendeciría"),
    (.participioPasado, "bendecido"),
    (.imperativoAfirmativo(.secondSingular), "bendice"),
    (.presenteDeIndicativo(.firstSingular), "bendigo"),
    (.pretérito(.firstSingular), "bendije"),
    (.imperfectoDeSubjuntivoRa(.firstSingular), "bendijera"),
  ])
  func bendecirSlots(tense: Tense2, expected: String) {
    expectForm("bendecir", model: Self.bendecir, tense, expected)
  }

  @Test("hacer — presente de indicativo (hago…)", arguments: zip(PersonNumber2.oracleOrder,
    ["hago", "haces", "hace", "hacemos", "hacéis", "hacen"]))
  func hacerPresent(person: PersonNumber2, expected: String) {
    expectForm("hacer", model: Self.hacer, .presenteDeIndicativo(person), expected)
  }

  @Test("hacer — pretérito (hic-, hizo)", arguments: zip(PersonNumber2.oracleOrder,
    ["hice", "hiciste", "hizo", "hicimos", "hicisteis", "hicieron"]))
  func hacerPreterite(person: PersonNumber2, expected: String) {
    expectForm("hacer", model: Self.hacer, .pretérito(person), expected)
  }

  @Test("hacer — future, participle, imperatives", arguments: [
    (Tense2.futuro(.firstSingular), "haré"),
    (.participioPasado, "hecho"),
    (.imperativoAfirmativo(.secondSingular), "haz"),
    (.imperativoAfirmativo(.secondSingularVos), "hacé"),
    (.imperativoAfirmativo(.thirdSingular), "haga"),
    (.imperativoAfirmativo(.firstPlural), "hagamos"),
  ])
  func hacerSlots(tense: Tense2, expected: String) {
    expectForm("hacer", model: Self.hacer, tense, expected)
  }

  @Test("rehacer — accent residue (rehíce / rehízo)", arguments: [
    (Tense2.pretérito(.firstSingular), "rehíce"),
    (.pretérito(.thirdSingular), "rehízo"),
    (.pretérito(.secondSingular), "rehiciste"),
  ])
  func rehacerSlots(tense: Tense2, expected: String) {
    expectForm("rehacer", model: Self.rehacer, tense, expected)
  }

  @Test("satisfacer — rides hacer by prefix-invariance (satisfaz/satisfizo)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "satisfaz"),
    (.pretérito(.firstSingular), "satisfice"),
    (.pretérito(.thirdSingular), "satisfizo"),
    (.presenteDeIndicativo(.firstSingular), "satisfago"),
    (.futuro(.firstSingular), "satisfaré"),
    (.participioPasado, "satisfecho"),
  ])
  func satisfacerSlots(tense: Tense2, expected: String) {
    expectForm("satisfacer", model: Self.hacer, tense, expected)
  }

  @Test("poner — presente de subjuntivo (pong-)", arguments: zip(PersonNumber2.oracleOrder,
    ["ponga", "pongas", "ponga", "pongamos", "pongáis", "pongan"]))
  func ponerPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("poner", model: Self.poner, .presenteDeSubjuntivo(person), expected)
  }

  @Test("poner — preterite, future, participle, imperatives", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "pongo"),
    (.pretérito(.firstSingular), "puse"),
    (.futuro(.firstSingular), "pondré"),
    (.participioPasado, "puesto"),
    (.imperativoAfirmativo(.secondSingular), "pon"),
    (.imperativoAfirmativo(.secondSingularVos), "poné"),
    (.imperativoAfirmativo(.thirdSingular), "ponga"),
    (.imperativoAfirmativo(.firstPlural), "pongamos"),
  ])
  func ponerSlots(tense: Tense2, expected: String) {
    expectForm("poner", model: Self.poner, tense, expected)
  }

  @Test("tener — capstone imperatives (ten/tenga/tengamos/tengan)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "ten"),
    (.imperativoAfirmativo(.thirdSingular), "tenga"),
    (.imperativoAfirmativo(.firstPlural), "tengamos"),
    (.imperativoAfirmativo(.thirdPlural), "tengan"),
  ])
  func tenerImperatives(tense: Tense2, expected: String) {
    expectForm("tener", model: Self.tener, tense, expected)
  }

  @Test("venir — gerund & derived imperatives (ven/venga/vengamos)", arguments: [
    (Tense2.gerundio, "viniendo"),
    (.imperativoAfirmativo(.secondSingular), "ven"),
    (.imperativoAfirmativo(.secondSingularVos), "vení"),
    (.imperativoAfirmativo(.thirdSingular), "venga"),
    (.imperativoAfirmativo(.firstPlural), "vengamos"),
    (.imperativoAfirmativo(.thirdPlural), "vengan"),
  ])
  func venirImperatives(tense: Tense2, expected: String) {
    expectForm("venir", model: Self.venir, tense, expected)
  }

  @Test("traer — presente de indicativo (traig-)", arguments: zip(PersonNumber2.oracleOrder,
    ["traigo", "traes", "trae", "traemos", "traéis", "traen"]))
  func traerPresent(person: PersonNumber2, expected: String) {
    expectForm("traer", model: Self.traer, .presenteDeIndicativo(person), expected)
  }

  @Test("traer — pretérito (traj-)", arguments: zip(PersonNumber2.oracleOrder,
    ["traje", "trajiste", "trajo", "trajimos", "trajisteis", "trajeron"]))
  func traerPreterite(person: PersonNumber2, expected: String) {
    expectForm("traer", model: Self.traer, .pretérito(person), expected)
  }

  @Test("traer — non-finite & derived imperatives", arguments: [
    (Tense2.gerundio, "trayendo"),
    (.participioPasado, "traído"),
    (.imperativoAfirmativo(.thirdSingular), "traiga"),
    (.imperativoAfirmativo(.firstPlural), "traigamos"),
    (.imperativoAfirmativo(.thirdPlural), "traigan"),
  ])
  func traerSlots(tense: Tense2, expected: String) {
    expectForm("traer", model: Self.traer, tense, expected)
  }

  @Test("conducir — derived imperatives (conduzca/conduzcamos/conduzcan)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "conduce"),
    (.imperativoAfirmativo(.thirdSingular), "conduzca"),
    (.imperativoAfirmativo(.firstPlural), "conduzcamos"),
    (.imperativoAfirmativo(.thirdPlural), "conduzcan"),
  ])
  func conducirImperatives(tense: Tense2, expected: String) {
    expectForm("conducir", model: Self.conducirFull, tense, expected)
  }

  @Test("andar — pretérito & derived imperatives", arguments: [
    (Tense2.pretérito(.firstSingular), "anduve"),
    (.imperativoAfirmativo(.secondSingular), "anda"),
    (.imperativoAfirmativo(.thirdSingular), "ande"),
    (.imperativoAfirmativo(.firstPlural), "andemos"),
  ])
  func andarImperatives(tense: Tense2, expected: String) {
    expectForm("andar", model: Self.andarFull, tense, expected)
  }

  // MARK: - Phase 5: derived-model prefix-invariance (the residue must compose)

  @Test("derived-accent compounds (apocopated imperative is prefix-invariant)", arguments: [
    ("obtener", Tense2.imperativoAfirmativo(.secondSingular), "obtén"),
    ("detener", .imperativoAfirmativo(.secondSingular), "detén"),
    ("suponer", .imperativoAfirmativo(.secondSingular), "supón"),
    ("reponer", .imperativoAfirmativo(.secondSingular), "repón"),
    ("convenir", .imperativoAfirmativo(.secondSingular), "convén"),
  ])
  func derivedAccentCompounds(infinitive: String, tense: Tense2, expected: String) {
    let model = infinitive.hasSuffix("poner") ? Self.poner : (infinitive.hasSuffix("venir") ? Self.venir : Self.tener)
    expectForm(infinitive, model: model, tense, expected)
  }

  @Test("residue prefix-invariance — strong/contracted stems & participles", arguments: [
    ("detener", Tense2.pretérito(.firstSingular), "detuve"),
    ("detener", .futuro(.firstSingular), "detendré"),
    ("componer", .participioPasado, "compuesto"),
    ("componer", .pretérito(.firstSingular), "compuse"),
    ("descubrir", .participioPasado, "descubierto"),
    ("describir", .participioPasado, "descrito"),
    ("devolver", .participioPasado, "devuelto"),
    ("deshacer", .participioPasado, "deshecho"),
  ])
  func residuePrefixInvariance(infinitive: String, tense: Tense2, expected: String) {
    let model: VerbModel2
    switch infinitive {
    case "detener": model = Self.tener
    case "componer": model = Self.poner
    case "descubrir": model = Self.cubrir
    case "describir": model = Self.escribir
    case "devolver": model = Self.volver
    case "deshacer": model = Self.hacer
    default: model = Self.tener
    }
    expectForm(infinitive, model: model, tense, expected)
  }

  // MARK: - Phase 5: §4.8 participles & defectives

  @Test("irregular participles", arguments: [
    ("romper", Self.romper, "roto"),
    ("abrir", Self.abrir, "abierto"),
    ("cubrir", Self.cubrir, "cubierto"),
    ("escribir", Self.escribir, "escrito"),
    ("imprimir", Self.imprimir, "impreso"),
    ("pudrir", Self.pudrir, "podrido"),
    ("resolver", Self.resolver, "resuelto"),
    ("volver", Self.volver, "vuelto"),
    ("morir", Self.morir, "muerto"),
  ])
  func irregularParticiples(infinitive: String, model: VerbModel2, expected: String) {
    expectForm(infinitive, model: model, .participioPasado, expected)
  }

  // The rest of the paradigm stays the base's: a PP override doesn't leak.
  @Test("participle classes keep the base paradigm", arguments: [
    ("romper", Self.romper, Tense2.pretérito(.firstSingular), "rompí"),
    ("abrir", Self.abrir, .pretérito(.firstSingular), "abrí"),
    ("resolver", Self.resolver, .presenteDeIndicativo(.firstSingular), "resuelvo"),
    ("morir", Self.morir, .pretérito(.thirdSingular), "murió"),
    ("morir", Self.morir, .gerundio, "muriendo"),
  ])
  func participleClassesKeepParadigm(infinitive: String, model: VerbModel2, tense: Tense2, expected: String) {
    expectForm(infinitive, model: model, tense, expected)
  }

  @Test("morir — presente de indicativo (dormir-features)", arguments: zip(PersonNumber2.oracleOrder,
    ["muero", "mueres", "muere", "morimos", "morís", "mueren"]))
  func morirPresent(person: PersonNumber2, expected: String) {
    expectForm("morir", model: Self.morir, .presenteDeIndicativo(person), expected)
  }

  // abolir (defective): the -i-vowel forms exist; the STR/1s/PS-less slots have none.
  @Test("abolir — the existing forms", arguments: [
    (Tense2.presenteDeIndicativo(.firstPlural), "abolimos"),
    (.presenteDeIndicativo(.secondPlural), "abolís"),
    (.pretérito(.firstSingular), "abolí"),
    (.imperfectoDeIndicativo(.firstSingular), "abolía"),
    (.futuro(.firstSingular), "aboliré"),
    (.imperativoAfirmativo(.secondPlural), "abolid"),
    (.participioPasado, "abolido"),
    (.gerundio, "aboliendo"),
  ])
  func abolirExistingForms(tense: Tense2, expected: String) {
    expectForm("abolir", model: Self.abolir, tense, expected)
  }

  @Test("abolir — the missing forms report .noForm", arguments: [
    Tense2.presenteDeIndicativo(.firstSingular),
    .presenteDeIndicativo(.thirdSingular),
    .presenteDeIndicativo(.thirdPlural),
    .presenteDeSubjuntivo(.firstSingular),
    .imperativoAfirmativo(.secondSingular),
    .imperativoAfirmativo(.firstPlural),
  ])
  func abolirMissingForms(tense: Tense2) {
    assertFailure(
      Conjugator2.conjugate(infinitive: "abolir", tense: tense, model: Self.abolir),
      .noForm(tense))
  }

  // MARK: - Phase 5: ver / reír (the deferred residue stem classes)

  @Test("ver — presente de indicativo (veo/ves…)", arguments: zip(PersonNumber2.oracleOrder,
    ["veo", "ves", "ve", "vemos", "veis", "ven"]))
  func verPresent(person: PersonNumber2, expected: String) {
    expectForm("ver", model: Self.ver, .presenteDeIndicativo(person), expected)
  }

  @Test("ver — imperfecto de indicativo (veía-)", arguments: zip(PersonNumber2.oracleOrder,
    ["veía", "veías", "veía", "veíamos", "veíais", "veían"]))
  func verImperfect(person: PersonNumber2, expected: String) {
    expectForm("ver", model: Self.ver, .imperfectoDeIndicativo(person), expected)
  }

  @Test("ver — presente de subjuntivo (vea-)", arguments: zip(PersonNumber2.oracleOrder,
    ["vea", "veas", "vea", "veamos", "veáis", "vean"]))
  func verPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("ver", model: Self.ver, .presenteDeSubjuntivo(person), expected)
  }

  @Test("ver — preterite, participle, imperative", arguments: [
    (Tense2.pretérito(.firstSingular), "vi"),
    (.pretérito(.thirdSingular), "vio"),
    (.participioPasado, "visto"),
    (.imperativoAfirmativo(.secondSingular), "ve"),
  ])
  func verSlots(tense: Tense2, expected: String) {
    expectForm("ver", model: Self.ver, tense, expected)
  }

  @Test("prever — monosyllable→polysyllable accent residue", arguments: zip(PersonNumber2.oracleOrder,
    ["preveo", "prevés", "prevé", "prevemos", "prevéis", "prevén"]))
  func preverPresent(person: PersonNumber2, expected: String) {
    expectForm("prever", model: Self.prever, .presenteDeIndicativo(person), expected)
  }

  @Test("prever — preterite & participle", arguments: [
    (Tense2.pretérito(.firstSingular), "preví"),
    (.pretérito(.thirdSingular), "previó"),
    (.pretérito(.secondSingular), "previste"),
    (.participioPasado, "previsto"),
    (.imperfectoDeIndicativo(.firstSingular), "preveía"),
  ])
  func preverSlots(tense: Tense2, expected: String) {
    expectForm("prever", model: Self.prever, tense, expected)
  }

  @Test("reír — presente de indicativo (hiatus accents)", arguments: zip(PersonNumber2.oracleOrder,
    ["río", "ríes", "ríe", "reímos", "reís", "ríen"]))
  func reirPresent(person: PersonNumber2, expected: String) {
    expectForm("reír", model: Self.reir, .presenteDeIndicativo(person), expected)
  }

  @Test("reír — pretérito (collapse-ii + accents)", arguments: zip(PersonNumber2.oracleOrder,
    ["reí", "reíste", "rió", "reímos", "reísteis", "rieron"]))
  func reirPreterite(person: PersonNumber2, expected: String) {
    expectForm("reír", model: Self.reir, .pretérito(person), expected)
  }

  @Test("reír — presente de subjuntivo (STR accents, WK clean)", arguments: zip(PersonNumber2.oracleOrder,
    ["ría", "rías", "ría", "riamos", "riáis", "rían"]))
  func reirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("reír", model: Self.reir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("reír — imperfecto de subjuntivo & non-finite (collapse-ii)", arguments: [
    (Tense2.imperfectoDeSubjuntivoRa(.firstSingular), "riera"),
    (.imperfectoDeSubjuntivoRa(.firstPlural), "riéramos"),
    (.gerundio, "riendo"),
    (.participioPasado, "reído"),
    (.futuro(.firstSingular), "reiré"),
  ])
  func reirSlots(tense: Tense2, expected: String) {
    expectForm("reír", model: Self.reir, tense, expected)
  }

  // MARK: - Phase 5b: argüir (class 18 — güy→guy)

  @Test("argüir — presente de indicativo (güy→guy; güi keeps the diaeresis)", arguments: zip(PersonNumber2.oracleOrder,
    ["arguyo", "arguyes", "arguye", "argüimos", "argüís", "arguyen"]))
  func arguirPresent(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .presenteDeIndicativo(person), expected)
  }

  @Test("argüir — pretérito (boundary güy in arguyó/arguyeron; güi keeps it)", arguments: zip(PersonNumber2.oracleOrder,
    ["argüí", "argüiste", "arguyó", "argüimos", "argüisteis", "arguyeron"]))
  func arguirPreterite(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .pretérito(person), expected)
  }

  @Test("argüir — imperfecto de indicativo (all güi)", arguments: zip(PersonNumber2.oracleOrder,
    ["argüía", "argüías", "argüía", "argüíamos", "argüíais", "argüían"]))
  func arguirImperfect(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .imperfectoDeIndicativo(person), expected)
  }

  @Test("argüir — futuro (all güi)", arguments: zip(PersonNumber2.oracleOrder,
    ["argüiré", "argüirás", "argüirá", "argüiremos", "argüiréis", "argüirán"]))
  func arguirFuture(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .futuro(person), expected)
  }

  @Test("argüir — condicional (all güi)", arguments: zip(PersonNumber2.oracleOrder,
    ["argüiría", "argüirías", "argüiría", "argüiríamos", "argüiríais", "argüirían"]))
  func arguirConditional(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .condicional(person), expected)
  }

  @Test("argüir — presente de subjuntivo (güy→guy throughout)", arguments: zip(PersonNumber2.oracleOrder,
    ["arguya", "arguyas", "arguya", "arguyamos", "arguyáis", "arguyan"]))
  func arguirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("argüir — imperfecto de subjuntivo (-ra; boundary güy)", arguments: zip(PersonNumber2.oracleOrder,
    ["arguyera", "arguyeras", "arguyera", "arguyéramos", "arguyerais", "arguyeran"]))
  func arguirImperfectSubjunctiveRa(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .imperfectoDeSubjuntivoRa(person), expected)
  }

  @Test("argüir — imperfecto de subjuntivo (-se; boundary güy)", arguments: zip(PersonNumber2.oracleOrder,
    ["arguyese", "arguyeses", "arguyese", "arguyésemos", "arguyeseis", "arguyesen"]))
  func arguirImperfectSubjunctiveSe(person: PersonNumber2, expected: String) {
    expectForm("argüir", model: Self.arguir, .imperfectoDeSubjuntivoSe(person), expected)
  }

  @Test("argüir — imperative & non-finite", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "arguye"),
    (.imperativoAfirmativo(.secondPlural), "argüid"),
    (.imperativoAfirmativo(.thirdSingular), "arguya"),    // derived from PS arguya
    (.imperativoAfirmativo(.firstPlural), "arguyamos"),
    (.imperativoAfirmativo(.thirdPlural), "arguyan"),
    (.gerundio, "arguyendo"),
    (.participioPasado, "argüido"),
  ])
  func arguirImperativeAndNonFinite(tense: Tense2, expected: String) {
    expectForm("argüir", model: Self.arguir, tense, expected)
  }

  // Prefix-invariance: a hypothetical re-argüir rides the same model untouched.
  @Test("argüir — prefix-invariance (reargüir)", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "rearguyo"),
    (.pretérito(.thirdSingular), "rearguyó"),
    (.presenteDeIndicativo(.firstPlural), "reargüimos"),
    (.gerundio, "rearguyendo"),
  ])
  func arguirPrefixInvariance(tense: Tense2, expected: String) {
    expectForm("reargüir", model: Self.arguir, tense, expected)
  }

  // The tú imperative of a y-add verb equals PI{3s} and keeps the glide. Phase 5b
  // added IMP{2s} to `isYAdd`, so construir's imperative is now `construye` (it
  // was the never-tested `construe` before); voseo/vosotros stay regular.
  @Test("construir — tú imperative keeps the y glide (isYAdd fix)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "construye"),
    (.imperativoAfirmativo(.secondPlural), "construid"),
    (.imperativoAfirmativo(.secondSingularVos), "construí"),
  ])
  func construirImperative(tense: Tense2, expected: String) {
    expectForm("construir", model: Self.construir, tense, expected)
  }

  // MARK: - Phase 5b: erguir (class 6A-1 — two co-equal paradigms)

  // `conjugate` returns the primary (yerg-) paradigm. (PS{1p,2p} are the shared WK
  // raise irgamos/irgáis — the RAE-preferred forms — in both paradigms.)
  @Test("erguir — presente de indicativo (primary, yerg-)", arguments: zip(PersonNumber2.oracleOrder,
    ["yergo", "yergues", "yergue", "erguimos", "erguís", "yerguen"]))
  func erguirPresent(person: PersonNumber2, expected: String) {
    expectForm("erguir", model: Self.erguir, .presenteDeIndicativo(person), expected)
  }

  @Test("erguir — pretérito (unstressed raise irguió/irguieron, shared)", arguments: zip(PersonNumber2.oracleOrder,
    ["erguí", "erguiste", "irguió", "erguimos", "erguisteis", "irguieron"]))
  func erguirPreterite(person: PersonNumber2, expected: String) {
    expectForm("erguir", model: Self.erguir, .pretérito(person), expected)
  }

  @Test("erguir — presente de subjuntivo (primary: STR yerg-, WK irg-)", arguments: zip(PersonNumber2.oracleOrder,
    ["yerga", "yergas", "yerga", "irgamos", "irgáis", "yergan"]))
  func erguirPresentSubjunctive(person: PersonNumber2, expected: String) {
    expectForm("erguir", model: Self.erguir, .presenteDeSubjuntivo(person), expected)
  }

  @Test("erguir — imperative & non-finite (primary)", arguments: [
    (Tense2.imperativoAfirmativo(.secondSingular), "yergue"),
    (.imperativoAfirmativo(.secondPlural), "erguid"),
    (.gerundio, "irguiendo"),
    (.participioPasado, "erguido"),
  ])
  func erguirImperativeAndNonFinite(tense: Tense2, expected: String) {
    expectForm("erguir", model: Self.erguir, tense, expected)
  }

  // conjugateAll surfaces BOTH yerg-/irg- in the stressed slots…
  @Test("erguir — conjugateAll, stressed slots return both paradigms", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), ["yergo", "irgo"]),
    (.presenteDeIndicativo(.secondSingular), ["yergues", "irgues"]),
    (.presenteDeIndicativo(.thirdSingular), ["yergue", "irgue"]),
    (.presenteDeIndicativo(.thirdPlural), ["yerguen", "irguen"]),
    (.presenteDeSubjuntivo(.firstSingular), ["yerga", "irga"]),
    (.presenteDeSubjuntivo(.thirdPlural), ["yergan", "irgan"]),
    (.imperativoAfirmativo(.secondSingular), ["yergue", "irgue"]),
  ])
  func erguirAllStressed(tense: Tense2, expected: [String]) {
    expectForms("erguir", model: Self.erguir, tense, expected)
  }

  // …and a single form in the shared unstressed slots (no duplicate).
  @Test("erguir — conjugateAll, shared unstressed slots collapse to one form", arguments: [
    (Tense2.presenteDeIndicativo(.firstPlural), ["erguimos"]),
    (.pretérito(.firstSingular), ["erguí"]),
    (.pretérito(.thirdSingular), ["irguió"]),
    (.pretérito(.thirdPlural), ["irguieron"]),
    (.presenteDeSubjuntivo(.firstPlural), ["irgamos"]),
    (.presenteDeSubjuntivo(.secondPlural), ["irgáis"]),
    (.gerundio, ["irguiendo"]),
  ])
  func erguirAllShared(tense: Tense2, expected: [String]) {
    expectForms("erguir", model: Self.erguir, tense, expected)
  }

  // MARK: - Phase 5b: raer / roer / yacer (variant -go/-y/-zc paradigms)

  // raer (9-1): PI 2s/3s/… are regular (raes/rae/raen); only 1s + PS branch.
  @Test("raer — presente de indicativo (primary raigo; rest regular)", arguments: zip(PersonNumber2.oracleOrder,
    ["raigo", "raes", "rae", "raemos", "raéis", "raen"]))
  func raerPresent(person: PersonNumber2, expected: String) {
    expectForm("raer", model: Self.raer, .presenteDeIndicativo(person), expected)
  }

  @Test("raer — shared preterite/gerund/participle (single-valued)", arguments: [
    (Tense2.pretérito(.thirdSingular), "rayó"),
    (.pretérito(.secondSingular), "raíste"),
    (.gerundio, "rayendo"),
    (.participioPasado, "raído"),
  ])
  func raerShared(tense: Tense2, expected: String) {
    expectForm("raer", model: Self.raer, tense, expected)
  }

  @Test("raer — conjugateAll variant set (raigo+rayo) and shared singletons", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), ["raigo", "rayo"]),
    (.presenteDeSubjuntivo(.firstSingular), ["raiga", "raya"]),
    (.presenteDeSubjuntivo(.firstPlural), ["raigamos", "rayamos"]),
    (.pretérito(.thirdSingular), ["rayó"]),
    (.gerundio, ["rayendo"]),
    (.participioPasado, ["raído"]),
  ])
  func raerAll(tense: Tense2, expected: [String]) {
    expectForms("raer", model: Self.raer, tense, expected)
  }

  // roer (9-2): THREE variants — the regular roo is primary.
  @Test("roer — primary is the regular roo/roa; shared royó/royendo", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "roo"),
    (.presenteDeSubjuntivo(.firstSingular), "roa"),
    (.pretérito(.thirdSingular), "royó"),
    (.gerundio, "royendo"),
    (.participioPasado, "roído"),
  ])
  func roerPrimary(tense: Tense2, expected: String) {
    expectForm("roer", model: Self.roer, tense, expected)
  }

  @Test("roer — conjugateAll returns all THREE variants (N=3)", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), ["roo", "roigo", "royo"]),
    (.presenteDeSubjuntivo(.firstSingular), ["roa", "roiga", "roya"]),
    (.presenteDeSubjuntivo(.firstPlural), ["roamos", "roigamos", "royamos"]),
    (.pretérito(.thirdSingular), ["royó"]),
    (.gerundio, ["royendo"]),
  ])
  func roerAll(tense: Tense2, expected: [String]) {
    expectForms("roer", model: Self.roer, tense, expected)
  }

  // yacer (7A-1): THREE variants in PI 1s / PS; primary yazco, imperative yace.
  @Test("yacer — primary (yazco/yazca/yace); rest regular", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "yazco"),
    (.presenteDeIndicativo(.secondSingular), "yaces"),
    (.presenteDeSubjuntivo(.firstSingular), "yazca"),
    (.imperativoAfirmativo(.secondSingular), "yace"),
  ])
  func yacerPrimary(tense: Tense2, expected: String) {
    expectForm("yacer", model: Self.yacer, tense, expected)
  }

  @Test("yacer — conjugateAll variant set (yazco/yazgo/yago) + apocopated yaz", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), ["yazco", "yazgo", "yago"]),
    (.presenteDeSubjuntivo(.firstSingular), ["yazca", "yazga", "yaga"]),
    (.presenteDeSubjuntivo(.firstPlural), ["yazcamos", "yazgamos", "yagamos"]),
    (.imperativoAfirmativo(.secondSingular), ["yace", "yaz"]),
  ])
  func yacerAll(tense: Tense2, expected: [String]) {
    expectForms("yacer", model: Self.yacer, tense, expected)
  }

  // placer (7A-2): primary plazco; a representative archaic alternate slice.
  @Test("placer — primary (zc) paradigm", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "plazco"),
    (.presenteDeSubjuntivo(.thirdSingular), "plazca"),
    (.pretérito(.thirdSingular), "plació"),
  ])
  func placerPrimary(tense: Tense2, expected: String) {
    expectForm("placer", model: Self.placer, tense, expected)
  }

  @Test("placer — conjugateAll archaic alternates (N≥2)", arguments: [
    (Tense2.presenteDeSubjuntivo(.thirdSingular), ["plazca", "plegue", "plega"]),
    (.pretérito(.thirdSingular), ["plació", "plugo"]),
  ])
  func placerAll(tense: Tense2, expected: [String]) {
    expectForms("placer", model: Self.placer, tense, expected)
  }

  // MARK: - Phase 5b: two-form participles (§4.8)

  @Test("two-form participles — conjugate returns the book's primary", arguments: [
    ("imprimir", Self.imprimir, "impreso"),
    ("freír", Self.freir, "frito"),
    ("inscribir", Self.inscribir, "inscrito"),
  ])
  func twoFormParticiplePrimary(infinitive: String, model: VerbModel2, expected: String) {
    expectForm(infinitive, model: model, .participioPasado, expected)
  }

  @Test("two-form participles — conjugateAll returns [primary, alternate]", arguments: [
    ("imprimir", Self.imprimir, ["impreso", "imprimido"]),
    ("freír", Self.freir, ["frito", "freído"]),
    ("inscribir", Self.inscribir, ["inscrito", "inscripto"]),
  ])
  func twoFormParticipleAll(infinitive: String, model: VerbModel2, expected: [String]) {
    expectForms(infinitive, model: model, .participioPasado, expected)
  }

  // freír also carries reír's umlaut/collapse machinery (sanity beyond the PP).
  @Test("freír — umlaut/collapse spot-checks", arguments: [
    (Tense2.presenteDeIndicativo(.firstSingular), "frío"),
    (.pretérito(.thirdSingular), "frió"),
    (.gerundio, "friendo"),
    (.presenteDeSubjuntivo(.firstPlural), "friamos"),
  ])
  func freirSpotChecks(tense: Tense2, expected: String) {
    expectForm("freír", model: Self.freir, tense, expected)
  }

  // MARK: - Phase 5b: conjugateAll degenerates correctly (strict superset)

  // A regular verb and a single-form irregular (tener) return exactly [onlyForm]:
  // no spurious alternates, and element 0 == conjugate's result.
  @Test("conjugateAll — regular verb returns exactly [onlyForm]", arguments: [
    Tense2.presenteDeIndicativo(.firstSingular),
    .pretérito(.thirdSingular),
    .gerundio,
    .participioPasado,
    .imperativoAfirmativo(.firstPlural),
  ])
  func conjugateAllRegularDegenerate(tense: Tense2) {
    expectForms("hablar", tense, [conjugatePrimary("hablar", model: nil, tense)])
  }

  @Test("conjugateAll — single-form irregular (tener) returns exactly [onlyForm]", arguments: [
    Tense2.presenteDeIndicativo(.firstSingular),
    .pretérito(.firstSingular),
    .futuro(.firstSingular),
    .imperativoAfirmativo(.secondSingular),
    .participioPasado,
  ])
  func conjugateAllSingleIrregularDegenerate(tense: Tense2) {
    expectForms("tener", model: Self.tener, tense, [conjugatePrimary("tener", model: Self.tener, tense)])
  }

  // MARK: - Helpers

  /// Conjugate one slot (optionally against an explicit model) and assert the form.
  /// Used as the body of every parameterized paradigm/slot test; `sourceLocation`
  /// forwards the failure to the call site.
  private func expectForm(
    _ infinitive: String,
    model: VerbModel2? = nil,
    _ tense: Tense2,
    _ expected: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    let result = model.map { Conjugator2.conjugate(infinitive: infinitive, tense: tense, model: $0) }
      ?? Conjugator2.conjugate(infinitive: infinitive, tense: tense)
    switch result {
    case let .success(form):
      #expect(form == expected, "\(infinitive) \(tense)", sourceLocation: sourceLocation)
    case let .failure(error):
      Issue.record("\(infinitive) \(tense) unexpectedly failed: \(error)", sourceLocation: sourceLocation)
    }
  }

  /// The single-form (`conjugate`) result for a slot, for the degenerate-path
  /// tests that prove `conjugateAll` returns exactly `[that form]`. Records an
  /// issue and returns "" if the single-form path itself fails (so the equality
  /// assertion then surfaces the real problem).
  private func conjugatePrimary(
    _ infinitive: String,
    model: VerbModel2?,
    _ tense: Tense2,
    sourceLocation: SourceLocation = #_sourceLocation
  ) -> String {
    let result = model.map { Conjugator2.conjugate(infinitive: infinitive, tense: tense, model: $0) }
      ?? Conjugator2.conjugate(infinitive: infinitive, tense: tense)
    switch result {
    case let .success(form):
      return form
    case let .failure(error):
      Issue.record("\(infinitive) \(tense) single-form failed: \(error)", sourceLocation: sourceLocation)
      return ""
    }
  }

  /// Conjugate one slot via the **all-forms** entry point and assert the full
  /// ordered list (primary first, alternates in book order, de-duplicated). Order
  /// is significant: the assertion is order-sensitive (taxonomy §5b crux 2).
  private func expectForms(
    _ infinitive: String,
    model: VerbModel2? = nil,
    _ tense: Tense2,
    _ expected: [String],
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    let result = model.map { Conjugator2.conjugateAll(infinitive: infinitive, tense: tense, model: $0) }
      ?? Conjugator2.conjugateAll(infinitive: infinitive, tense: tense)
    switch result {
    case let .success(forms):
      #expect(forms == expected, "\(infinitive) \(tense)", sourceLocation: sourceLocation)
    case let .failure(error):
      Issue.record("\(infinitive) \(tense) unexpectedly failed: \(error)", sourceLocation: sourceLocation)
    }
  }

  private func assertFailure(
    _ result: Result<String, Conjugator2Error>,
    _ expected: Conjugator2Error,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    guard case let .failure(error) = result else {
      Issue.record("Expected failure \(expected).", sourceLocation: sourceLocation)
      return
    }
    #expect(error == expected, sourceLocation: sourceLocation)
  }
}
