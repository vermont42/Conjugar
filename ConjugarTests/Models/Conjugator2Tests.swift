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
  // MARK: - Shared models (the §1 "model = base + ordered features" catalog)

  // Phase 2: orthographic (§4.1)
  static let tocar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oCar])
  static let pagar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGar])
  static let averiguar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGuar])
  static let cazar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oZar])
  static let vencer = VerbModel2(base: .er, features: [StemFinalConsonant2.oCz])
  static let fruncir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oCz])
  static let coger = VerbModel2(base: .er, features: [StemFinalConsonant2.oGj])
  static let dirigir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGj])
  static let distinguir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGug])
  static let delinquir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oQuc])
  static let leer = VerbModel2(base: .er, features: [IYHiatus2.oYhiatus])
  static let empeller = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
  static let tañer = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
  static let bullir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])
  static let bruñir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])

  // Phase 2: accent (§4.2)
  static let enviar = VerbModel2(base: .ar, features: [AccentStem2.aI])
  static let actuar = VerbModel2(base: .ar, features: [AccentStem2.aU])
  static let aislar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let aullar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
  static let descafeinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let rehusar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
  static let amohinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let reunir = VerbModel2(base: .ir, features: [AccentStem2.aStemU])
  static let prohibir = VerbModel2(base: .ir, features: [AccentStem2.aStemI])

  // Phase 2: composition (a-stem + orthographic swap)
  static let ahincar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oCar])
  static let cabrahigar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oGar])
  static let enraizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar])
  static let europeizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar])

  // Phase 3: stem-vowel diphthongs (§4.3)
  static let pensar = VerbModel2(base: .ar, features: [StemVowel2.dIe])
  static let mostrar = VerbModel2(base: .ar, features: [StemVowel2.dUe])
  static let perder = VerbModel2(base: .er, features: [StemVowel2.dIe])
  static let mover = VerbModel2(base: .er, features: [StemVowel2.dUe])
  static let errar = VerbModel2(base: .ar, features: [StemVowel2.dIeYe])
  static let agorar = VerbModel2(base: .ar, features: [StemVowel2.dUeGue])
  static let oler = VerbModel2(base: .er, features: [StemVowel2.dUeHue])
  static let adquirir = VerbModel2(base: .ir, features: [StemVowel2.dIIe])
  static let jugar = VerbModel2(base: .ar, features: [StemVowel2.dUUe, StemFinalConsonant2.oGar])
  static let discernir = VerbModel2(base: .ir, features: [StemVowel2.dIe])

  // Phase 3: -ir weak-slot raising (§4.4)
  static let sentir = VerbModel2(base: .ir, features: [StemVowel2.dIe, StemVowel2.rEiWk])
  static let pedir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk])
  static let dormir = VerbModel2(base: .ir, features: [StemVowel2.dUe, StemVowel2.rOuWk])

  // Phase 3: cross-phase composition (§4.3/§4.4 feature + a §4.1 swap)
  static let negar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oGar])
  static let empezar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oZar])
  static let colgar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oGar])
  static let forzar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oZar])
  static let cocer = VerbModel2(base: .er, features: [StemVowel2.dUe, StemFinalConsonant2.oCz])
  static let elegir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGj])
  static let seguir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGug])
  static let ceñir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, AbsorbIAfterPalatal2.oLlñ])

  // Phase 4: irregular 1s + present subjunctive (§4.5)
  static let conocer = VerbModel2(base: .er, features: [StemFeature2.zc])
  static let lucir = VerbModel2(base: .ir, features: [StemFeature2.zc])
  static let asir = VerbModel2(base: .ir, features: [StemFeature2.g1g])
  static let caer = VerbModel2(base: .er, features: [StemFeature2.g1ig, IYHiatus2.oYhiatus])
  static let construir = VerbModel2(base: .ir, features: [StemFeature2.yAdd, IYHiatus2.oYhiatus])
  static let salir = VerbModel2(base: .ir, features: [StemFeature2.g1g, FutureEndings2.fDr])
  static let valer = VerbModel2(base: .er, features: [StemFeature2.g1g, FutureEndings2.fDr])

  // Phase 4: strong / suppletive preterites (§4.6)
  static let andar = VerbModel2(base: .ar, features: [StemFeature2.strongPreterite(from: "and", to: "anduv"), PreteriteEndings2.spEnd])
  static let tenerSpEnd = VerbModel2(base: .er, features: [StemFeature2.strongPreterite(from: "ten", to: "tuv"), PreteriteEndings2.spEnd])
  static let conducir = VerbModel2(base: .ir, features: [
    StemFeature2.zc,
    StemFeature2.strongPreterite(from: "conduc", to: "conduj"),
    PreteriteEndings2.spJend
  ])
  static let decirSpJend = VerbModel2(base: .ir, features: [StemFeature2.strongPreterite(from: "dec", to: "dij"), PreteriteEndings2.spJend])
  static let dar = VerbModel2(base: .ar, features: [PreteriteEndings2.wpI])
  static let ver = VerbModel2(base: .er, features: [PreteriteEndings2.wpI])
  static let ser = VerbModel2(base: .er, features: [SuppletivePreterite2.fue])
  static let ir = VerbModel2(base: .ir, features: [SuppletivePreterite2.fue])

  // Phase 4: future / conditional stems (§4.7)
  static let haber = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
  static let tenerFDr = VerbModel2(base: .er, features: [FutureEndings2.fDr])
  static let hacer = VerbModel2(base: .er, features: [StemFeature2.contractedFuture(from: "hac", to: "ha"), FutureEndings2.fContract])
  static let decirFContract = VerbModel2(base: .ir, features: [StemFeature2.contractedFuture(from: "dec", to: "di"), FutureEndings2.fContract])

  // Phase 4: capstones (whole phase in one verb)
  static let tener = VerbModel2(base: .er, features: [
    StemVowel2.dIe,
    StemFeature2.g1g,
    StemFeature2.strongPreterite(from: "ten", to: "tuv"),
    PreteriteEndings2.spEnd,
    FutureEndings2.fDr
  ])
  static let venir = VerbModel2(base: .ir, features: [
    StemVowel2.dIe,
    StemVowel2.rEiWk,
    StemFeature2.g1g,
    StemFeature2.strongPreterite(from: "ven", to: "vin"),
    PreteriteEndings2.spEnd,
    FutureEndings2.fDr
  ])

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

  @Test("non-second-person imperative is unavailable")
  func nonSecondPersonImperativeIsUnavailable() {
    assertFailure(
      Conjugator2.conjugate(infinitive: "cantar", tense: .imperativoAfirmativo(.firstPlural)),
      .imperativeNotAvailable(.firstPlural))
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
