//
//  Conjugator2Tests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

// Phase 1 gate: the three regular roots (cantar/comer/subir) conjugate correctly
// for every simple/non-finite tense. Expected forms are taken from the verified
// oracle (docs/spanish_models.md classes 1, 2, 3, plus the voseo supplement).
final class Conjugator2Tests: XCTestCase {
  // Oracle row order: yo, tú, él, nosotros, vosotros, ellos.
  private let persons = PersonNumber2.oracleOrder

  // MARK: - cantar (regular -ar)

  func testCantarIndicative() {
    assertParadigm("cantar", { .presenteDeIndicativo($0) },
                   ["canto", "cantas", "canta", "cantamos", "cantáis", "cantan"])
    assertParadigm("cantar", { .pretérito($0) },
                   ["canté", "cantaste", "cantó", "cantamos", "cantasteis", "cantaron"])
    assertParadigm("cantar", { .imperfectoDeIndicativo($0) },
                   ["cantaba", "cantabas", "cantaba", "cantábamos", "cantabais", "cantaban"])
    assertParadigm("cantar", { .futuro($0) },
                   ["cantaré", "cantarás", "cantará", "cantaremos", "cantaréis", "cantarán"])
    assertParadigm("cantar", { .condicional($0) },
                   ["cantaría", "cantarías", "cantaría", "cantaríamos", "cantaríais", "cantarían"])
  }

  func testCantarSubjunctive() {
    assertParadigm("cantar", { .presenteDeSubjuntivo($0) },
                   ["cante", "cantes", "cante", "cantemos", "cantéis", "canten"])
    assertParadigm("cantar", { .imperfectoDeSubjuntivoRa($0) },
                   ["cantara", "cantaras", "cantara", "cantáramos", "cantarais", "cantaran"])
    assertParadigm("cantar", { .imperfectoDeSubjuntivoSe($0) },
                   ["cantase", "cantases", "cantase", "cantásemos", "cantaseis", "cantasen"])
  }

  func testCantarImperativeAndNonFinite() {
    assertEqual("cantar", .imperativoAfirmativo(.secondSingular), "canta")
    assertEqual("cantar", .imperativoAfirmativo(.secondPlural), "cantad")
    assertEqual("cantar", .participioPasado, "cantado")
    assertEqual("cantar", .gerundio, "cantando")
  }

  // MARK: - comer (regular -er)

  func testComerIndicative() {
    assertParadigm("comer", { .presenteDeIndicativo($0) },
                   ["como", "comes", "come", "comemos", "coméis", "comen"])
    assertParadigm("comer", { .pretérito($0) },
                   ["comí", "comiste", "comió", "comimos", "comisteis", "comieron"])
    assertParadigm("comer", { .imperfectoDeIndicativo($0) },
                   ["comía", "comías", "comía", "comíamos", "comíais", "comían"])
    assertParadigm("comer", { .futuro($0) },
                   ["comeré", "comerás", "comerá", "comeremos", "comeréis", "comerán"])
    assertParadigm("comer", { .condicional($0) },
                   ["comería", "comerías", "comería", "comeríamos", "comeríais", "comerían"])
  }

  func testComerSubjunctive() {
    assertParadigm("comer", { .presenteDeSubjuntivo($0) },
                   ["coma", "comas", "coma", "comamos", "comáis", "coman"])
    assertParadigm("comer", { .imperfectoDeSubjuntivoRa($0) },
                   ["comiera", "comieras", "comiera", "comiéramos", "comierais", "comieran"])
    assertParadigm("comer", { .imperfectoDeSubjuntivoSe($0) },
                   ["comiese", "comieses", "comiese", "comiésemos", "comieseis", "comiesen"])
  }

  func testComerImperativeAndNonFinite() {
    assertEqual("comer", .imperativoAfirmativo(.secondSingular), "come")
    assertEqual("comer", .imperativoAfirmativo(.secondPlural), "comed")
    assertEqual("comer", .participioPasado, "comido")
    assertEqual("comer", .gerundio, "comiendo")
  }

  // MARK: - subir (regular -ir)

  func testSubirIndicative() {
    assertParadigm("subir", { .presenteDeIndicativo($0) },
                   ["subo", "subes", "sube", "subimos", "subís", "suben"])
    assertParadigm("subir", { .pretérito($0) },
                   ["subí", "subiste", "subió", "subimos", "subisteis", "subieron"])
    assertParadigm("subir", { .imperfectoDeIndicativo($0) },
                   ["subía", "subías", "subía", "subíamos", "subíais", "subían"])
    assertParadigm("subir", { .futuro($0) },
                   ["subiré", "subirás", "subirá", "subiremos", "subiréis", "subirán"])
    assertParadigm("subir", { .condicional($0) },
                   ["subiría", "subirías", "subiría", "subiríamos", "subiríais", "subirían"])
  }

  func testSubirSubjunctive() {
    assertParadigm("subir", { .presenteDeSubjuntivo($0) },
                   ["suba", "subas", "suba", "subamos", "subáis", "suban"])
    assertParadigm("subir", { .imperfectoDeSubjuntivoRa($0) },
                   ["subiera", "subieras", "subiera", "subiéramos", "subierais", "subieran"])
    assertParadigm("subir", { .imperfectoDeSubjuntivoSe($0) },
                   ["subiese", "subieses", "subiese", "subiésemos", "subieseis", "subiesen"])
  }

  func testSubirImperativeAndNonFinite() {
    assertEqual("subir", .imperativoAfirmativo(.secondSingular), "sube")
    assertEqual("subir", .imperativoAfirmativo(.secondPlural), "subid")
    assertEqual("subir", .participioPasado, "subido")
    assertEqual("subir", .gerundio, "subiendo")
  }

  // MARK: - Voseo (supplement)

  func testVoseo() {
    // Present 2s and affirmative imperative 2s are the only slots that differ
    // from tú; everything else uses the tú form.
    assertEqual("cantar", .presenteDeIndicativo(.secondSingularVos), "cantás")
    assertEqual("comer", .presenteDeIndicativo(.secondSingularVos), "comés")
    assertEqual("subir", .presenteDeIndicativo(.secondSingularVos), "subís")
    assertEqual("cantar", .imperativoAfirmativo(.secondSingularVos), "cantá")
    assertEqual("comer", .imperativoAfirmativo(.secondSingularVos), "comé")
    assertEqual("subir", .imperativoAfirmativo(.secondSingularVos), "subí")
    // Falls back to tú elsewhere.
    assertEqual("cantar", .pretérito(.secondSingularVos), "cantaste")
    assertEqual("comer", .presenteDeSubjuntivo(.secondSingularVos), "comas")
  }

  // MARK: - Genericity & validation

  func testArbitraryRegularVerbsConjugate() {
    assertEqual("hablar", .presenteDeIndicativo(.firstSingular), "hablo")
    assertEqual("tomar", .pretérito(.thirdSingular), "tomó")
    assertEqual("vivir", .presenteDeIndicativo(.firstSingular), "vivo")
    assertEqual("aprender", .gerundio, "aprendiendo")
  }

  func testInvalidInput() {
    assertFailure(Conjugator2.conjugate(infinitive: "a", tense: .gerundio), .infinitiveTooShort)
    if case .success = Conjugator2.conjugate(infinitive: "hello", tense: .gerundio) {
      XCTFail("Infinitive not ending in -ar/-er/-ir should fail.")
    }
  }

  func testNonSecondPersonImperativeIsUnavailable() {
    assertFailure(Conjugator2.conjugate(infinitive: "cantar", tense: .imperativoAfirmativo(.firstPlural)),
                  .imperativeNotAvailable(.firstPlural))
  }

  // MARK: - Phase 2: orthographic features (§4.1)

  // -ar consonant swaps fire before -e: PR 1s + PS{all}. PI/other PR stay regular.
  func testOCar() { // tocar (1-1)
    let m = VerbModel2(base: .ar, features: [StemFinalConsonant2.oCar])
    assertEqual("tocar", m, .pretérito(.firstSingular), "toqué")
    assertParadigm("tocar", m, { .presenteDeSubjuntivo($0) },
                   ["toque", "toques", "toque", "toquemos", "toquéis", "toquen"])
    assertEqual("tocar", m, .presenteDeIndicativo(.firstSingular), "toco")
    assertEqual("tocar", m, .pretérito(.thirdSingular), "tocó")
  }

  func testOGar() { // pagar (1-2)
    let m = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGar])
    assertEqual("pagar", m, .pretérito(.firstSingular), "pagué")
    assertParadigm("pagar", m, { .presenteDeSubjuntivo($0) },
                   ["pague", "pagues", "pague", "paguemos", "paguéis", "paguen"])
  }

  func testOGuar() { // averiguar (1-3)
    let m = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGuar])
    assertEqual("averiguar", m, .pretérito(.firstSingular), "averigüé")
    assertParadigm("averiguar", m, { .presenteDeSubjuntivo($0) },
                   ["averigüe", "averigües", "averigüe", "averigüemos", "averigüéis", "averigüen"])
  }

  func testOZar() { // cazar (1-4)
    let m = VerbModel2(base: .ar, features: [StemFinalConsonant2.oZar])
    assertEqual("cazar", m, .pretérito(.firstSingular), "cacé")
    assertParadigm("cazar", m, { .presenteDeSubjuntivo($0) },
                   ["cace", "caces", "cace", "cacemos", "cacéis", "cacen"])
  }

  // -er/-ir consonant swaps fire before -a/-o: PI 1s + PS{all}.
  func testOCz() { // vencer (2-1) + fruncir (3-1)
    let vencer = VerbModel2(base: .er, features: [StemFinalConsonant2.oCz])
    assertEqual("vencer", vencer, .presenteDeIndicativo(.firstSingular), "venzo")
    assertEqual("vencer", vencer, .presenteDeIndicativo(.secondSingular), "vences")
    assertParadigm("vencer", vencer, { .presenteDeSubjuntivo($0) },
                   ["venza", "venzas", "venza", "venzamos", "venzáis", "venzan"])
    let fruncir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oCz])
    assertEqual("fruncir", fruncir, .presenteDeIndicativo(.firstSingular), "frunzo")
    assertParadigm("fruncir", fruncir, { .presenteDeSubjuntivo($0) },
                   ["frunza", "frunzas", "frunza", "frunzamos", "frunzáis", "frunzan"])
  }

  func testOGj() { // coger (2-2) + dirigir (3-2)
    let coger = VerbModel2(base: .er, features: [StemFinalConsonant2.oGj])
    assertEqual("coger", coger, .presenteDeIndicativo(.firstSingular), "cojo")
    assertParadigm("coger", coger, { .presenteDeSubjuntivo($0) },
                   ["coja", "cojas", "coja", "cojamos", "cojáis", "cojan"])
    let dirigir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGj])
    assertEqual("dirigir", dirigir, .presenteDeIndicativo(.firstSingular), "dirijo")
    assertParadigm("dirigir", dirigir, { .presenteDeSubjuntivo($0) },
                   ["dirija", "dirijas", "dirija", "dirijamos", "dirijáis", "dirijan"])
  }

  func testOGug() { // distinguir (3-3)
    let m = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGug])
    assertEqual("distinguir", m, .presenteDeIndicativo(.firstSingular), "distingo")
    assertParadigm("distinguir", m, { .presenteDeSubjuntivo($0) },
                   ["distinga", "distingas", "distinga", "distingamos", "distingáis", "distingan"])
  }

  func testOQuc() { // delinquir (3-4)
    let m = VerbModel2(base: .ir, features: [StemFinalConsonant2.oQuc])
    assertEqual("delinquir", m, .presenteDeIndicativo(.firstSingular), "delinco")
    assertParadigm("delinquir", m, { .presenteDeSubjuntivo($0) },
                   ["delinca", "delincas", "delinca", "delincamos", "delincáis", "delincan"])
  }

  // o-yhiatus: i→y in PR{3s,3p}+GER+IS{all}, plus written accents on the regular
  // -i- forms (PR{2s,1p,2p}, PP). Full paradigm against leer (2-3).
  func testOYhiatusLeer() {
    let m = VerbModel2(base: .er, features: [IYHiatus2.oYhiatus])
    assertParadigm("leer", m, { .presenteDeIndicativo($0) },
                   ["leo", "lees", "lee", "leemos", "leéis", "leen"])
    assertParadigm("leer", m, { .pretérito($0) },
                   ["leí", "leíste", "leyó", "leímos", "leísteis", "leyeron"])
    assertParadigm("leer", m, { .imperfectoDeIndicativo($0) },
                   ["leía", "leías", "leía", "leíamos", "leíais", "leían"])
    assertParadigm("leer", m, { .imperfectoDeSubjuntivoRa($0) },
                   ["leyera", "leyeras", "leyera", "leyéramos", "leyerais", "leyeran"])
    assertParadigm("leer", m, { .imperfectoDeSubjuntivoSe($0) },
                   ["leyese", "leyeses", "leyese", "leyésemos", "leyeseis", "leyesen"])
    assertEqual("leer", m, .gerundio, "leyendo")
    assertEqual("leer", m, .participioPasado, "leído")
  }

  // o-llñ: -i- absorbed after ll/ñ (-ió→-ó, -ieron→-eron, -iendo→-endo), no accents.
  func testOLlñ() { // empeller (2-4) / tañer (2-5) / bullir (3-5) / bruñir (3-6)
    let empeller = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
    assertParadigm("empeller", empeller, { .pretérito($0) },
                   ["empellí", "empelliste", "empelló", "empellimos", "empellisteis", "empelleron"])
    assertParadigm("empeller", empeller, { .imperfectoDeSubjuntivoRa($0) },
                   ["empellera", "empelleras", "empellera", "empelléramos", "empellerais", "empelleran"])
    assertEqual("empeller", empeller, .gerundio, "empellendo")

    let tañer = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
    assertParadigm("tañer", tañer, { .pretérito($0) },
                   ["tañí", "tañiste", "tañó", "tañimos", "tañisteis", "tañeron"])
    assertEqual("tañer", tañer, .gerundio, "tañendo")

    let bullir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])
    assertParadigm("bullir", bullir, { .pretérito($0) },
                   ["bullí", "bulliste", "bulló", "bullimos", "bullisteis", "bulleron"])
    assertEqual("bullir", bullir, .gerundio, "bullendo")

    let bruñir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])
    assertParadigm("bruñir", bruñir, { .pretérito($0) },
                   ["bruñí", "bruñiste", "bruñó", "bruñimos", "bruñisteis", "bruñeron"])
    assertEqual("bruñir", bruñir, .gerundio, "bruñendo")
  }

  // MARK: - Phase 2: accent features (§4.2)

  func testAccentI() { // enviar (1-15)
    let m = VerbModel2(base: .ar, features: [AccentStem2.aI])
    assertParadigm("enviar", m, { .presenteDeIndicativo($0) },
                   ["envío", "envías", "envía", "enviamos", "enviáis", "envían"])
    assertParadigm("enviar", m, { .presenteDeSubjuntivo($0) },
                   ["envíe", "envíes", "envíe", "enviemos", "enviéis", "envíen"])
    assertEqual("enviar", m, .imperativoAfirmativo(.secondSingular), "envía")
  }

  func testAccentU() { // actuar (1-14)
    let m = VerbModel2(base: .ar, features: [AccentStem2.aU])
    assertParadigm("actuar", m, { .presenteDeIndicativo($0) },
                   ["actúo", "actúas", "actúa", "actuamos", "actuáis", "actúan"])
    assertParadigm("actuar", m, { .presenteDeSubjuntivo($0) },
                   ["actúe", "actúes", "actúe", "actuemos", "actuéis", "actúen"])
    assertEqual("actuar", m, .imperativoAfirmativo(.secondSingular), "actúa")
  }

  // a-stem family (1-5…1-9, 3-7, 3-8): accent on the stem vowel in STR only.
  func testAStemFamily() {
    let aislar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
    assertParadigm("aislar", aislar, { .presenteDeIndicativo($0) },
                   ["aíslo", "aíslas", "aísla", "aislamos", "aisláis", "aíslan"])
    assertParadigm("aislar", aislar, { .presenteDeSubjuntivo($0) },
                   ["aísle", "aísles", "aísle", "aislemos", "aisléis", "aíslen"])
    assertEqual("aislar", aislar, .imperativoAfirmativo(.secondSingular), "aísla")
    assertEqual("aislar", aislar, .imperativoAfirmativo(.secondPlural), "aislad")

    let aullar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
    assertParadigm("aullar", aullar, { .presenteDeIndicativo($0) },
                   ["aúllo", "aúllas", "aúlla", "aullamos", "aulláis", "aúllan"])

    let descafeinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
    assertParadigm("descafeinar", descafeinar, { .presenteDeIndicativo($0) },
                   ["descafeíno", "descafeínas", "descafeína", "descafeinamos", "descafeináis", "descafeínan"])

    let rehusar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
    assertParadigm("rehusar", rehusar, { .presenteDeIndicativo($0) },
                   ["rehúso", "rehúsas", "rehúsa", "rehusamos", "rehusáis", "rehúsan"])

    let amohinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
    assertParadigm("amohinar", amohinar, { .presenteDeIndicativo($0) },
                   ["amohíno", "amohínas", "amohína", "amohinamos", "amohináis", "amohínan"])

    let reunir = VerbModel2(base: .ir, features: [AccentStem2.aStemU])
    assertParadigm("reunir", reunir, { .presenteDeIndicativo($0) },
                   ["reúno", "reúnes", "reúne", "reunimos", "reunís", "reúnen"])
    assertEqual("reunir", reunir, .imperativoAfirmativo(.secondSingular), "reúne")

    let prohibir = VerbModel2(base: .ir, features: [AccentStem2.aStemI])
    assertParadigm("prohibir", prohibir, { .presenteDeIndicativo($0) },
                   ["prohíbo", "prohíbes", "prohíbe", "prohibimos", "prohibís", "prohíben"])
    assertParadigm("prohibir", prohibir, { .presenteDeSubjuntivo($0) },
                   ["prohíba", "prohíbas", "prohíba", "prohibamos", "prohibáis", "prohíban"])
  }

  // MARK: - Phase 2: composition (multiple features, last-wins)

  // a-stem touches STR; the orthographic swap touches PR 1s / PS{all}. They
  // overlap on PS (both apply, stacking) and diverge on PR 1s (swap only, no
  // accent — PR 1s ∉ STR) and PI 1s (accent only).
  func testCompositionAStemPlusOrthographic() {
    let ahincar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oCar]) // 1-10
    assertParadigm("ahincar", ahincar, { .presenteDeIndicativo($0) },
                   ["ahínco", "ahíncas", "ahínca", "ahincamos", "ahincáis", "ahíncan"])
    assertParadigm("ahincar", ahincar, { .presenteDeSubjuntivo($0) },
                   ["ahínque", "ahínques", "ahínque", "ahinquemos", "ahinquéis", "ahínquen"])
    assertParadigm("ahincar", ahincar, { .pretérito($0) },
                   ["ahinqué", "ahincaste", "ahincó", "ahincamos", "ahincasteis", "ahincaron"])
    assertEqual("ahincar", ahincar, .imperativoAfirmativo(.secondSingular), "ahínca")

    let cabrahigar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oGar]) // 1-11
    assertParadigm("cabrahigar", cabrahigar, { .presenteDeIndicativo($0) },
                   ["cabrahígo", "cabrahígas", "cabrahíga", "cabrahigamos", "cabrahigáis", "cabrahígan"])
    assertParadigm("cabrahigar", cabrahigar, { .presenteDeSubjuntivo($0) },
                   ["cabrahígue", "cabrahígues", "cabrahígue", "cabrahiguemos", "cabrahiguéis", "cabrahíguen"])
    assertEqual("cabrahigar", cabrahigar, .pretérito(.firstSingular), "cabrahigué")

    let enraizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar]) // 1-12
    assertParadigm("enraizar", enraizar, { .presenteDeIndicativo($0) },
                   ["enraízo", "enraízas", "enraíza", "enraizamos", "enraizáis", "enraízan"])
    assertParadigm("enraizar", enraizar, { .presenteDeSubjuntivo($0) },
                   ["enraíce", "enraíces", "enraíce", "enraicemos", "enraicéis", "enraícen"])
    assertEqual("enraizar", enraizar, .pretérito(.firstSingular), "enraicé")

    let europeizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar]) // 1-13
    assertParadigm("europeizar", europeizar, { .presenteDeIndicativo($0) },
                   ["europeízo", "europeízas", "europeíza", "europeizamos", "europeizáis", "europeízan"])
    assertParadigm("europeizar", europeizar, { .presenteDeSubjuntivo($0) },
                   ["europeíce", "europeíces", "europeíce", "europeicemos", "europeicéis", "europeícen"])
    assertEqual("europeizar", europeizar, .pretérito(.firstSingular), "europeicé")
  }

  // MARK: - Phase 2: prefix-invariance (the end-anchored rule)

  // A prefixed verb whose stem isn't a listed model rides on its base's features
  // for free, because every feature operation is anchored to the end of the stem.
  func testPrefixInvariance() {
    let leer = VerbModel2(base: .er, features: [IYHiatus2.oYhiatus])
    assertEqual("releer", leer, .pretérito(.thirdSingular), "releyó")
    assertEqual("releer", leer, .pretérito(.thirdPlural), "releyeron")
    assertEqual("releer", leer, .gerundio, "releyendo")
    assertEqual("releer", leer, .pretérito(.firstPlural), "releímos")

    let enviar = VerbModel2(base: .ar, features: [AccentStem2.aI])
    assertEqual("reenviar", enviar, .presenteDeIndicativo(.firstSingular), "reenvío")
    assertEqual("reenviar", enviar, .presenteDeIndicativo(.thirdPlural), "reenvían")
  }

  // MARK: - Phase 3: stem-vowel diphthongs (§4.3, STR slots)

  // Diphthong with no raise: the change surfaces only in STR (PI/PS{1s,2s,3s,3p},
  // IMP 2s); unstressed forms (1p/2p, the whole preterite/imperfect) stay regular.
  func testDIeAr() { // pensar (4A)
    let m = VerbModel2(base: .ar, features: [StemVowel2.dIe])
    assertParadigm("pensar", m, { .presenteDeIndicativo($0) },
                   ["pienso", "piensas", "piensa", "pensamos", "pensáis", "piensan"])
    assertParadigm("pensar", m, { .presenteDeSubjuntivo($0) },
                   ["piense", "pienses", "piense", "pensemos", "penséis", "piensen"])
    assertParadigm("pensar", m, { .pretérito($0) },
                   ["pensé", "pensaste", "pensó", "pensamos", "pensasteis", "pensaron"])
    assertEqual("pensar", m, .imperativoAfirmativo(.secondSingular), "piensa")
    assertEqual("pensar", m, .imperativoAfirmativo(.secondPlural), "pensad")
    // Voseo present-2s / imperative-2s ride the regular stem — no diphthong.
    assertEqual("pensar", m, .presenteDeIndicativo(.secondSingularVos), "pensás")
    assertEqual("pensar", m, .imperativoAfirmativo(.secondSingularVos), "pensá")
  }

  func testDUeAr() { // mostrar (4B)
    let m = VerbModel2(base: .ar, features: [StemVowel2.dUe])
    assertParadigm("mostrar", m, { .presenteDeIndicativo($0) },
                   ["muestro", "muestras", "muestra", "mostramos", "mostráis", "muestran"])
    assertParadigm("mostrar", m, { .presenteDeSubjuntivo($0) },
                   ["muestre", "muestres", "muestre", "mostremos", "mostréis", "muestren"])
    assertEqual("mostrar", m, .imperativoAfirmativo(.secondSingular), "muestra")
  }

  func testDIeEr() { // perder (5A)
    let m = VerbModel2(base: .er, features: [StemVowel2.dIe])
    assertParadigm("perder", m, { .presenteDeIndicativo($0) },
                   ["pierdo", "pierdes", "pierde", "perdemos", "perdéis", "pierden"])
    assertParadigm("perder", m, { .presenteDeSubjuntivo($0) },
                   ["pierda", "pierdas", "pierda", "perdamos", "perdáis", "pierdan"])
  }

  func testDUeEr() { // mover (5B)
    let m = VerbModel2(base: .er, features: [StemVowel2.dUe])
    assertParadigm("mover", m, { .presenteDeIndicativo($0) },
                   ["muevo", "mueves", "mueve", "movemos", "movéis", "mueven"])
    assertParadigm("mover", m, { .presenteDeSubjuntivo($0) },
                   ["mueva", "muevas", "mueva", "movamos", "mováis", "muevan"])
  }

  // Spelled variants — same operation, a different target string.
  func testSpelledDiphthongs() {
    let errar = VerbModel2(base: .ar, features: [StemVowel2.dIeYe]) // 4A-3, e → ye
    assertParadigm("errar", errar, { .presenteDeIndicativo($0) },
                   ["yerro", "yerras", "yerra", "erramos", "erráis", "yerran"])
    assertParadigm("errar", errar, { .presenteDeSubjuntivo($0) },
                   ["yerre", "yerres", "yerre", "erremos", "erréis", "yerren"])

    let agorar = VerbModel2(base: .ar, features: [StemVowel2.dUeGue]) // 4B-4, o → üe
    assertParadigm("agorar", agorar, { .presenteDeIndicativo($0) },
                   ["agüero", "agüeras", "agüera", "agoramos", "agoráis", "agüeran"])
    assertParadigm("agorar", agorar, { .presenteDeSubjuntivo($0) },
                   ["agüere", "agüeres", "agüere", "agoremos", "agoréis", "agüeren"])

    let oler = VerbModel2(base: .er, features: [StemVowel2.dUeHue]) // 5B-2, o → hue
    assertParadigm("oler", oler, { .presenteDeIndicativo($0) },
                   ["huelo", "hueles", "huele", "olemos", "oléis", "huelen"])
    assertParadigm("oler", oler, { .presenteDeSubjuntivo($0) },
                   ["huela", "huelas", "huela", "olamos", "oláis", "huelan"])
  }

  // Rare diphthongs.
  func testRareDiphthongs() {
    let adquirir = VerbModel2(base: .ir, features: [StemVowel2.dIIe]) // 17, i → ie
    assertParadigm("adquirir", adquirir, { .presenteDeIndicativo($0) },
                   ["adquiero", "adquieres", "adquiere", "adquirimos", "adquirís", "adquieren"])
    assertParadigm("adquirir", adquirir, { .presenteDeSubjuntivo($0) },
                   ["adquiera", "adquieras", "adquiera", "adquiramos", "adquiráis", "adquieran"])

    let jugar = VerbModel2(base: .ar, features: [StemVowel2.dUUe, StemFinalConsonant2.oGar]) // 16, u → ue + o-gar
    assertParadigm("jugar", jugar, { .presenteDeIndicativo($0) },
                   ["juego", "juegas", "juega", "jugamos", "jugáis", "juegan"])
    assertParadigm("jugar", jugar, { .presenteDeSubjuntivo($0) },
                   ["juegue", "juegues", "juegue", "juguemos", "juguéis", "jueguen"])
    assertEqual("jugar", jugar, .pretérito(.firstSingular), "jugué")
  }

  // Control case: discernir (15) diphthongizes in STR but its WK slots stay
  // regular — it proves the diphthong feature is independent of the raise.
  func testDiphthongOnIrNoRaise() {
    let m = VerbModel2(base: .ir, features: [StemVowel2.dIe])
    assertParadigm("discernir", m, { .presenteDeIndicativo($0) },
                   ["discierno", "disciernes", "discierne", "discernimos", "discernís", "disciernen"])
    assertParadigm("discernir", m, { .presenteDeSubjuntivo($0) },
                   ["discierna", "disciernas", "discierna", "discernamos", "discernáis", "disciernan"])
    // WK stays regular: no *discirnió / *discirnamos.
    assertEqual("discernir", m, .pretérito(.thirdSingular), "discernió")
    assertEqual("discernir", m, .pretérito(.thirdPlural), "discernieron")
    assertEqual("discernir", m, .gerundio, "discerniendo")
  }

  // MARK: - Phase 3: -ir weak-slot raising (§4.4) — the STR/WK split

  // sentir (6A) = subir + d-ie + r-ei-wk. The present subjunctive splits:
  // PS{1s,2s,3s,3p} diphthong (STR), PS{1p,2p} raise (WK). PR{1s,2s,1p,2p} stay
  // regular (only PR{3s,3p} are WK).
  func testSentir() {
    let m = VerbModel2(base: .ir, features: [StemVowel2.dIe, StemVowel2.rEiWk])
    assertParadigm("sentir", m, { .presenteDeIndicativo($0) },
                   ["siento", "sientes", "siente", "sentimos", "sentís", "sienten"])
    assertParadigm("sentir", m, { .pretérito($0) },
                   ["sentí", "sentiste", "sintió", "sentimos", "sentisteis", "sintieron"])
    assertParadigm("sentir", m, { .presenteDeSubjuntivo($0) },
                   ["sienta", "sientas", "sienta", "sintamos", "sintáis", "sientan"])
    assertParadigm("sentir", m, { .imperfectoDeSubjuntivoRa($0) },
                   ["sintiera", "sintieras", "sintiera", "sintiéramos", "sintierais", "sintieran"])
    assertParadigm("sentir", m, { .imperfectoDeSubjuntivoSe($0) },
                   ["sintiese", "sintieses", "sintiese", "sintiésemos", "sintieseis", "sintiesen"])
    assertEqual("sentir", m, .gerundio, "sintiendo")
    assertEqual("sentir", m, .imperativoAfirmativo(.secondSingular), "siente")
    assertEqual("sentir", m, .imperativoAfirmativo(.secondPlural), "sentid")
  }

  // pedir (6B) = subir + r-ei-str + r-ei-wk. Raise everywhere (STR and WK), no
  // diphthong — both PS halves raise (pida… / pidamos).
  func testPedir() {
    let m = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk])
    assertParadigm("pedir", m, { .presenteDeIndicativo($0) },
                   ["pido", "pides", "pide", "pedimos", "pedís", "piden"])
    assertParadigm("pedir", m, { .pretérito($0) },
                   ["pedí", "pediste", "pidió", "pedimos", "pedisteis", "pidieron"])
    assertParadigm("pedir", m, { .presenteDeSubjuntivo($0) },
                   ["pida", "pidas", "pida", "pidamos", "pidáis", "pidan"])
    assertParadigm("pedir", m, { .imperfectoDeSubjuntivoRa($0) },
                   ["pidiera", "pidieras", "pidiera", "pidiéramos", "pidierais", "pidieran"])
    assertEqual("pedir", m, .gerundio, "pidiendo")
    assertEqual("pedir", m, .imperativoAfirmativo(.secondSingular), "pide")
  }

  // dormir (6C) = subir + d-ue + r-ou-wk. Same STR/WK split as sentir, o → u.
  func testDormir() {
    let m = VerbModel2(base: .ir, features: [StemVowel2.dUe, StemVowel2.rOuWk])
    assertParadigm("dormir", m, { .presenteDeIndicativo($0) },
                   ["duermo", "duermes", "duerme", "dormimos", "dormís", "duermen"])
    assertParadigm("dormir", m, { .pretérito($0) },
                   ["dormí", "dormiste", "durmió", "dormimos", "dormisteis", "durmieron"])
    assertParadigm("dormir", m, { .presenteDeSubjuntivo($0) },
                   ["duerma", "duermas", "duerma", "durmamos", "durmáis", "duerman"])
    assertParadigm("dormir", m, { .imperfectoDeSubjuntivoRa($0) },
                   ["durmiera", "durmieras", "durmiera", "durmiéramos", "durmierais", "durmieran"])
    assertEqual("dormir", m, .gerundio, "durmiendo")
  }

  // MARK: - Phase 3: cross-phase composition (§4.3/§4.4 feature + a §4.1 swap)

  // Watch the preterite/subjunctive divergence: empiece (diphthong + z→c in PS)
  // vs empecé (PR 1s gets the z→c swap only — PR 1s ∉ STR, so no diphthong);
  // likewise niegue vs negué.
  func testCompositionDiphthongPlusOrthographic() {
    let negar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oGar]) // 4A-1
    assertParadigm("negar", negar, { .presenteDeSubjuntivo($0) },
                   ["niegue", "niegues", "niegue", "neguemos", "neguéis", "nieguen"])
    assertEqual("negar", negar, .pretérito(.firstSingular), "negué")
    assertEqual("negar", negar, .presenteDeIndicativo(.firstSingular), "niego")

    let empezar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oZar]) // 4A-2
    assertParadigm("empezar", empezar, { .presenteDeSubjuntivo($0) },
                   ["empiece", "empieces", "empiece", "empecemos", "empecéis", "empiecen"])
    assertEqual("empezar", empezar, .pretérito(.firstSingular), "empecé")

    let colgar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oGar]) // 4B-2
    assertParadigm("colgar", colgar, { .presenteDeSubjuntivo($0) },
                   ["cuelgue", "cuelgues", "cuelgue", "colguemos", "colguéis", "cuelguen"])
    assertEqual("colgar", colgar, .pretérito(.firstSingular), "colgué")

    let forzar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oZar]) // 4B-3
    assertParadigm("forzar", forzar, { .presenteDeSubjuntivo($0) },
                   ["fuerce", "fuerces", "fuerce", "forcemos", "forcéis", "fuercen"])
    assertEqual("forzar", forzar, .pretérito(.firstSingular), "forcé")

    let cocer = VerbModel2(base: .er, features: [StemVowel2.dUe, StemFinalConsonant2.oCz]) // 5B-1
    assertParadigm("cocer", cocer, { .presenteDeIndicativo($0) },
                   ["cuezo", "cueces", "cuece", "cocemos", "cocéis", "cuecen"])
    assertParadigm("cocer", cocer, { .presenteDeSubjuntivo($0) },
                   ["cueza", "cuezas", "cueza", "cozamos", "cozáis", "cuezan"])

    let elegir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGj]) // 6B-1
    assertParadigm("elegir", elegir, { .presenteDeIndicativo($0) },
                   ["elijo", "eliges", "elige", "elegimos", "elegís", "eligen"])
    assertParadigm("elegir", elegir, { .presenteDeSubjuntivo($0) },
                   ["elija", "elijas", "elija", "elijamos", "elijáis", "elijan"])
    assertEqual("elegir", elegir, .pretérito(.thirdSingular), "eligió")
    assertEqual("elegir", elegir, .gerundio, "eligiendo")

    let seguir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGug]) // 6B-2
    assertParadigm("seguir", seguir, { .presenteDeIndicativo($0) },
                   ["sigo", "sigues", "sigue", "seguimos", "seguís", "siguen"])
    assertParadigm("seguir", seguir, { .presenteDeSubjuntivo($0) },
                   ["siga", "sigas", "siga", "sigamos", "sigáis", "sigan"])
    assertEqual("seguir", seguir, .pretérito(.thirdSingular), "siguió")
    assertEqual("seguir", seguir, .gerundio, "siguiendo")
  }

  // Bonus (not required): ceñir (6B-3) = pedir-raises + o-llñ is clean composition
  // with no residue — the raise feeds the i, the palatal absorbs it (ciñó, ciñendo).
  func testCenir() {
    let m = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, AbsorbIAfterPalatal2.oLlñ])
    assertParadigm("ceñir", m, { .presenteDeIndicativo($0) },
                   ["ciño", "ciñes", "ciñe", "ceñimos", "ceñís", "ciñen"])
    assertParadigm("ceñir", m, { .pretérito($0) },
                   ["ceñí", "ceñiste", "ciñó", "ceñimos", "ceñisteis", "ciñeron"])
    assertParadigm("ceñir", m, { .presenteDeSubjuntivo($0) },
                   ["ciña", "ciñas", "ciña", "ciñamos", "ciñáis", "ciñan"])
    assertEqual("ceñir", m, .gerundio, "ciñendo")
  }

  // MARK: - Phase 3: prefix-invariance (the end-anchored rule for stem vowels)

  // A prefixed verb whose stem isn't a listed model gets the diphthong/raise on
  // its own last stem vowel, prefix riding free.
  func testStemVowelPrefixInvariance() {
    let comprobar = VerbModel2(base: .ar, features: [StemVowel2.dUe]) // d-ue on comprob-
    assertEqual("comprobar", comprobar, .presenteDeIndicativo(.firstSingular), "compruebo")
    assertEqual("comprobar", comprobar, .presenteDeIndicativo(.thirdPlural), "comprueban")

    let repetir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk]) // pedir-raises on repet-
    assertEqual("repetir", repetir, .presenteDeIndicativo(.firstSingular), "repito")
    assertEqual("repetir", repetir, .gerundio, "repitiendo")
  }

  // MARK: - Phase 4: irregular 1s + present subjunctive (§4.5)

  // zc: c→zc in PI 1s + PS{all}, built on the regular stem (subj-from-1s bundled).
  func testZc() { // conocer (7A) + lucir (7B)
    let conocer = VerbModel2(base: .er, features: [StemFeature2.zc])
    assertEqual("conocer", conocer, .presenteDeIndicativo(.firstSingular), "conozco")
    assertEqual("conocer", conocer, .presenteDeIndicativo(.secondSingular), "conoces")
    assertParadigm("conocer", conocer, { .presenteDeSubjuntivo($0) },
                   ["conozca", "conozcas", "conozca", "conozcamos", "conozcáis", "conozcan"])
    // The preterite stays regular (no strong preterite here).
    assertEqual("conocer", conocer, .pretérito(.firstSingular), "conocí")

    let lucir = VerbModel2(base: .ir, features: [StemFeature2.zc])
    assertEqual("lucir", lucir, .presenteDeIndicativo(.firstSingular), "luzco")
    assertParadigm("lucir", lucir, { .presenteDeSubjuntivo($0) },
                   ["luzca", "luzcas", "luzca", "luzcamos", "luzcáis", "luzcan"])
  }

  // g1-g: append g to the regular stem in PI 1s + PS{all}.
  func testG1g() { // asir (13)
    let asir = VerbModel2(base: .ir, features: [StemFeature2.g1g])
    assertEqual("asir", asir, .presenteDeIndicativo(.firstSingular), "asgo")
    assertEqual("asir", asir, .presenteDeIndicativo(.secondSingular), "ases")
    assertParadigm("asir", asir, { .presenteDeSubjuntivo($0) },
                   ["asga", "asgas", "asga", "asgamos", "asgáis", "asgan"])
  }

  // g1-ig + o-yhiatus: caigo/caiga AND the hiatus glide/accents (caíste/caído/
  // cayó/cayera) — the accent fires because the -i- follows a strong vowel (a).
  func testG1igPlusYhiatus() { // caer (9)
    let caer = VerbModel2(base: .er, features: [StemFeature2.g1ig, IYHiatus2.oYhiatus])
    assertEqual("caer", caer, .presenteDeIndicativo(.firstSingular), "caigo")
    assertParadigm("caer", caer, { .presenteDeSubjuntivo($0) },
                   ["caiga", "caigas", "caiga", "caigamos", "caigáis", "caigan"])
    assertParadigm("caer", caer, { .pretérito($0) },
                   ["caí", "caíste", "cayó", "caímos", "caísteis", "cayeron"])
    assertEqual("caer", caer, .participioPasado, "caído")
    assertEqual("caer", caer, .gerundio, "cayendo")
    assertParadigm("caer", caer, { .imperfectoDeSubjuntivoRa($0) },
                   ["cayera", "cayeras", "cayera", "cayéramos", "cayerais", "cayeran"])
  }

  // y-add + o-yhiatus: the i→y glide everywhere it surfaces (construyo/construye/
  // construyen, construya, construyó, construyera, construyendo) BUT the -uir
  // hiatus accents do NOT fire (construiste/construimos/construido) because the
  // -i- follows the weak -u-, not a strong vowel — Phase 4 crux 5.
  func testYAddPlusYhiatus() { // construir (8)
    let m = VerbModel2(base: .ir, features: [StemFeature2.yAdd, IYHiatus2.oYhiatus])
    assertParadigm("construir", m, { .presenteDeIndicativo($0) },
                   ["construyo", "construyes", "construye", "construimos", "construís", "construyen"])
    assertParadigm("construir", m, { .presenteDeSubjuntivo($0) },
                   ["construya", "construyas", "construya", "construyamos", "construyáis", "construyan"])
    assertParadigm("construir", m, { .pretérito($0) },
                   ["construí", "construiste", "construyó", "construimos", "construisteis", "construyeron"])
    assertEqual("construir", m, .gerundio, "construyendo")
    assertEqual("construir", m, .participioPasado, "construido")
    assertParadigm("construir", m, { .imperfectoDeSubjuntivoRa($0) },
                   ["construyera", "construyeras", "construyera", "construyéramos", "construyerais", "construyeran"])
  }

  // §4.5 + §4.7 integration (no residue): g1-g for the 1s/subjunctive, f-dr for
  // the future/conditional. (IMP is Phase-5 residue — sal — so it is skipped.)
  func testGoPlusFutureDr() { // salir (11) + valer (12)
    let salir = VerbModel2(base: .ir, features: [StemFeature2.g1g, FutureEndings2.fDr])
    assertEqual("salir", salir, .presenteDeIndicativo(.firstSingular), "salgo")
    assertParadigm("salir", salir, { .presenteDeSubjuntivo($0) },
                   ["salga", "salgas", "salga", "salgamos", "salgáis", "salgan"])
    assertParadigm("salir", salir, { .futuro($0) },
                   ["saldré", "saldrás", "saldrá", "saldremos", "saldréis", "saldrán"])
    assertParadigm("salir", salir, { .condicional($0) },
                   ["saldría", "saldrías", "saldría", "saldríamos", "saldríais", "saldrían"])

    let valer = VerbModel2(base: .er, features: [StemFeature2.g1g, FutureEndings2.fDr])
    assertEqual("valer", valer, .presenteDeIndicativo(.firstSingular), "valgo")
    assertEqual("valer", valer, .presenteDeSubjuntivo(.firstSingular), "valga")
    assertParadigm("valer", valer, { .futuro($0) },
                   ["valdré", "valdrás", "valdrá", "valdremos", "valdréis", "valdrán"])
  }

  // MARK: - Phase 4: strong / suppletive preterites (§4.6)

  // sp-end is base-independent: andar/estar are -ar verbs yet take the -ie- IS
  // (anduviera, not *anduvara) — crux 2.
  func testSpEnd() { // andar (35) + estar (20) + tener preterite
    let andar = VerbModel2(base: .ar, features: [StemFeature2.strongPreterite(from: "and", to: "anduv"), PreteriteEndings2.spEnd])
    assertParadigm("andar", andar, { .pretérito($0) },
                   ["anduve", "anduviste", "anduvo", "anduvimos", "anduvisteis", "anduvieron"])
    assertParadigm("andar", andar, { .imperfectoDeSubjuntivoRa($0) },
                   ["anduviera", "anduvieras", "anduviera", "anduviéramos", "anduvierais", "anduvieran"])
    assertParadigm("andar", andar, { .imperfectoDeSubjuntivoSe($0) },
                   ["anduviese", "anduvieses", "anduviese", "anduviésemos", "anduvieseis", "anduviesen"])

    let estar = VerbModel2(base: .ar, features: [StemFeature2.strongPreterite(from: "est", to: "estuv"), PreteriteEndings2.spEnd])
    assertEqual("estar", estar, .pretérito(.firstSingular), "estuve")
    assertEqual("estar", estar, .imperfectoDeSubjuntivoRa(.firstSingular), "estuviera")

    let tener = VerbModel2(base: .er, features: [StemFeature2.strongPreterite(from: "ten", to: "tuv"), PreteriteEndings2.spEnd])
    assertParadigm("tener", tener, { .pretérito($0) },
                   ["tuve", "tuviste", "tuvo", "tuvimos", "tuvisteis", "tuvieron"])
    assertEqual("tener", tener, .imperfectoDeSubjuntivoRa(.firstSingular), "tuviera")
  }

  // sp-jend absorbs the i after j: 3p -eron (not -ieron), IS -era (not -iera).
  func testSpJend() { // conducir (34, zc + sp-jend) + decir preterite (28)
    let conducir = VerbModel2(base: .ir, features: [
      StemFeature2.zc,
      StemFeature2.strongPreterite(from: "conduc", to: "conduj"),
      PreteriteEndings2.spJend
    ])
    assertEqual("conducir", conducir, .presenteDeIndicativo(.firstSingular), "conduzco")
    assertParadigm("conducir", conducir, { .pretérito($0) },
                   ["conduje", "condujiste", "condujo", "condujimos", "condujisteis", "condujeron"])
    assertParadigm("conducir", conducir, { .imperfectoDeSubjuntivoRa($0) },
                   ["condujera", "condujeras", "condujera", "condujéramos", "condujerais", "condujeran"])

    let decir = VerbModel2(base: .ir, features: [StemFeature2.strongPreterite(from: "dec", to: "dij"), PreteriteEndings2.spJend])
    assertParadigm("decir", decir, { .pretérito($0) },
                   ["dije", "dijiste", "dijo", "dijimos", "dijisteis", "dijeron"])
    assertEqual("decir", decir, .imperfectoDeSubjuntivoRa(.firstSingular), "dijera")
  }

  // wp-i: unaccented monosyllables, and -iera forced on an -ar base (dar → diera,
  // not *dara) — crux 4.
  func testWpI() { // dar (25) + ver (14)
    let dar = VerbModel2(base: .ar, features: [PreteriteEndings2.wpI])
    assertParadigm("dar", dar, { .pretérito($0) },
                   ["di", "diste", "dio", "dimos", "disteis", "dieron"])
    assertParadigm("dar", dar, { .imperfectoDeSubjuntivoRa($0) },
                   ["diera", "dieras", "diera", "diéramos", "dierais", "dieran"])
    assertEqual("dar", dar, .imperfectoDeSubjuntivoSe(.firstSingular), "diese")

    let ver = VerbModel2(base: .er, features: [PreteriteEndings2.wpI])
    assertParadigm("ver", ver, { .pretérito($0) },
                   ["vi", "viste", "vio", "vimos", "visteis", "vieron"])
    assertEqual("ver", ver, .imperfectoDeSubjuntivoRa(.firstSingular), "viera")
  }

  // pret-fue: the suppletive fu- stem shared by ser and ir.
  func testPretFue() { // ser (19) + ir (24)
    let ser = VerbModel2(base: .er, features: [SuppletivePreterite2.fue])
    assertParadigm("ser", ser, { .pretérito($0) },
                   ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"])
    assertParadigm("ser", ser, { .imperfectoDeSubjuntivoRa($0) },
                   ["fuera", "fueras", "fuera", "fuéramos", "fuerais", "fueran"])
    assertParadigm("ser", ser, { .imperfectoDeSubjuntivoSe($0) },
                   ["fuese", "fueses", "fuese", "fuésemos", "fueseis", "fuesen"])

    let ir = VerbModel2(base: .ir, features: [SuppletivePreterite2.fue])
    assertParadigm("ir", ir, { .pretérito($0) },
                   ["fui", "fuiste", "fue", "fuimos", "fuisteis", "fueron"])
    assertEqual("ir", ir, .imperfectoDeSubjuntivoSe(.firstSingular), "fuese")
  }

  // MARK: - Phase 4: future / conditional stems (§4.7)

  // f-drope drops the theme -e- (-er → -r); querer's stem ends in r, so the
  // future doubles it (querré).
  func testFDrope() { // haber (21) + querer (27) + poder (26)
    let haber = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
    assertParadigm("haber", haber, { .futuro($0) },
                   ["habré", "habrás", "habrá", "habremos", "habréis", "habrán"])
    assertParadigm("haber", haber, { .condicional($0) },
                   ["habría", "habrías", "habría", "habríamos", "habríais", "habrían"])

    let querer = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
    assertEqual("querer", querer, .futuro(.firstSingular), "querré")
    assertEqual("querer", querer, .condicional(.thirdPlural), "querrían")

    let poder = VerbModel2(base: .er, features: [FutureEndings2.fDrope])
    assertEqual("poder", poder, .futuro(.firstSingular), "podré")
  }

  // f-dr inserts d (drops the theme vowel).
  func testFDr() { // tener (31) + poner (30)
    let tener = VerbModel2(base: .er, features: [FutureEndings2.fDr])
    assertParadigm("tener", tener, { .futuro($0) },
                   ["tendré", "tendrás", "tendrá", "tendremos", "tendréis", "tendrán"])
    assertParadigm("tener", tener, { .condicional($0) },
                   ["tendría", "tendrías", "tendría", "tendríamos", "tendríais", "tendrían"])

    let poner = VerbModel2(base: .er, features: [FutureEndings2.fDr])
    assertEqual("poner", poner, .futuro(.firstSingular), "pondré")
  }

  // f-contract: a per-verb contracted future stem (residue) + the f-drope endings.
  func testFContract() { // hacer (29) + decir (28)
    let hacer = VerbModel2(base: .er, features: [StemFeature2.contractedFuture(from: "hac", to: "ha"), FutureEndings2.fContract])
    assertParadigm("hacer", hacer, { .futuro($0) },
                   ["haré", "harás", "hará", "haremos", "haréis", "harán"])
    assertParadigm("hacer", hacer, { .condicional($0) },
                   ["haría", "harías", "haría", "haríamos", "haríais", "harían"])

    let decir = VerbModel2(base: .ir, features: [StemFeature2.contractedFuture(from: "dec", to: "di"), FutureEndings2.fContract])
    assertEqual("decir", decir, .futuro(.firstSingular), "diré")
    assertEqual("decir", decir, .condicional(.thirdPlural), "dirían")
  }

  // MARK: - Phase 4: capstone — the whole phase in one verb (minus IMP residue)

  // tener (31) = comer + d-ie + g1-g + sp-end(tuv) + f-dr. Features are listed in
  // the §1 precedence order (stem-vowel → 1s/subjunctive → preterite → future),
  // so g1-g's subj-from-1s reset wins over the diphthong in PI 1s and all of PS
  // (tengo/tenga, not *tiengo/*tienga) while the diphthong still surfaces in
  // PI{2s,3s,3p} (tienes/tiene/tienen) — crux 1.
  func testTenerCapstone() {
    let tener = VerbModel2(base: .er, features: [
      StemVowel2.dIe,
      StemFeature2.g1g,
      StemFeature2.strongPreterite(from: "ten", to: "tuv"),
      PreteriteEndings2.spEnd,
      FutureEndings2.fDr
    ])
    assertParadigm("tener", tener, { .presenteDeIndicativo($0) },
                   ["tengo", "tienes", "tiene", "tenemos", "tenéis", "tienen"])
    assertParadigm("tener", tener, { .presenteDeSubjuntivo($0) },
                   ["tenga", "tengas", "tenga", "tengamos", "tengáis", "tengan"])
    assertParadigm("tener", tener, { .pretérito($0) },
                   ["tuve", "tuviste", "tuvo", "tuvimos", "tuvisteis", "tuvieron"])
    assertParadigm("tener", tener, { .imperfectoDeSubjuntivoRa($0) },
                   ["tuviera", "tuvieras", "tuviera", "tuviéramos", "tuvierais", "tuvieran"])
    assertParadigm("tener", tener, { .futuro($0) },
                   ["tendré", "tendrás", "tendrá", "tendremos", "tendréis", "tendrán"])
    assertParadigm("tener", tener, { .condicional($0) },
                   ["tendría", "tendrías", "tendría", "tendríamos", "tendríais", "tendrían"])
  }

  // venir (32) = subir + d-ie + r-ei-wk + g1-g + sp-end(vin) + f-dr. The extra
  // wrinkle over tener: r-ei-wk would raise the PS{1p,2p} stem (ven→vin), but
  // g1-g (listed after it) resets all of PS to veng- — vengamos, not *vingamos —
  // while the raise still drives the gerund (viniendo).
  func testVenir() {
    let venir = VerbModel2(base: .ir, features: [
      StemVowel2.dIe,
      StemVowel2.rEiWk,
      StemFeature2.g1g,
      StemFeature2.strongPreterite(from: "ven", to: "vin"),
      PreteriteEndings2.spEnd,
      FutureEndings2.fDr
    ])
    assertParadigm("venir", venir, { .presenteDeIndicativo($0) },
                   ["vengo", "vienes", "viene", "venimos", "venís", "vienen"])
    assertParadigm("venir", venir, { .presenteDeSubjuntivo($0) },
                   ["venga", "vengas", "venga", "vengamos", "vengáis", "vengan"])
    assertParadigm("venir", venir, { .pretérito($0) },
                   ["vine", "viniste", "vino", "vinimos", "vinisteis", "vinieron"])
    assertEqual("venir", venir, .gerundio, "viniendo")
    assertEqual("venir", venir, .futuro(.firstSingular), "vendré")
  }

  // MARK: - Phase 4: prefix-invariance (end-anchored inserts, strong & contracted stems)

  func testPhase4PrefixInvariance() {
    let conocer = VerbModel2(base: .er, features: [StemFeature2.zc])
    assertEqual("reconocer", conocer, .presenteDeIndicativo(.firstSingular), "reconozco")
    assertEqual("reconocer", conocer, .presenteDeSubjuntivo(.firstSingular), "reconozca")

    let tener = VerbModel2(base: .er, features: [
      StemVowel2.dIe,
      StemFeature2.g1g,
      StemFeature2.strongPreterite(from: "ten", to: "tuv"),
      PreteriteEndings2.spEnd,
      FutureEndings2.fDr
    ])
    assertEqual("detener", tener, .presenteDeIndicativo(.firstSingular), "detengo")
    assertEqual("detener", tener, .pretérito(.firstSingular), "detuve")
    assertEqual("detener", tener, .futuro(.firstSingular), "detendré")

    let poner = VerbModel2(base: .er, features: [
      StemFeature2.g1g,
      StemFeature2.strongPreterite(from: "pon", to: "pus"),
      PreteriteEndings2.spEnd,
      FutureEndings2.fDr
    ])
    assertEqual("componer", poner, .pretérito(.firstSingular), "compuse")
    assertEqual("componer", poner, .futuro(.firstSingular), "compondré")
  }

  // MARK: - Helpers

  private func assertParadigm(
    _ infinitive: String,
    _ tense: (PersonNumber2) -> Tense2,
    _ expected: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(persons.count, expected.count, "Expected one form per oracle person.", file: file, line: line)
    for (index, person) in persons.enumerated() {
      assertEqual(infinitive, tense(person), expected[index], file: file, line: line)
    }
  }

  private func assertEqual(
    _ infinitive: String,
    _ tense: Tense2,
    _ expected: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    switch Conjugator2.conjugate(infinitive: infinitive, tense: tense) {
    case .success(let form):
      XCTAssertEqual(form, expected, "\(infinitive) \(tense)", file: file, line: line)
    case .failure(let error):
      XCTFail("\(infinitive) \(tense) unexpectedly failed: \(error)", file: file, line: line)
    }
  }

  // Model-taking variants (Phase 2): conjugate against an explicit base + features.

  private func assertParadigm(
    _ infinitive: String,
    _ model: VerbModel2,
    _ tense: (PersonNumber2) -> Tense2,
    _ expected: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertEqual(persons.count, expected.count, "Expected one form per oracle person.", file: file, line: line)
    for (index, person) in persons.enumerated() {
      assertEqual(infinitive, model, tense(person), expected[index], file: file, line: line)
    }
  }

  private func assertEqual(
    _ infinitive: String,
    _ model: VerbModel2,
    _ tense: Tense2,
    _ expected: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    switch Conjugator2.conjugate(infinitive: infinitive, tense: tense, model: model) {
    case .success(let form):
      XCTAssertEqual(form, expected, "\(infinitive) \(tense)", file: file, line: line)
    case .failure(let error):
      XCTFail("\(infinitive) \(tense) unexpectedly failed: \(error)", file: file, line: line)
    }
  }

  private func assertFailure(
    _ result: Result<String, Conjugator2Error>,
    _ expected: Conjugator2Error,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    switch result {
    case .success(let form):
      XCTFail("Expected failure \(expected) but got \(form).", file: file, line: line)
    case .failure(let error):
      XCTAssertEqual(error, expected, file: file, line: line)
    }
  }
}
