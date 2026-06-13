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
