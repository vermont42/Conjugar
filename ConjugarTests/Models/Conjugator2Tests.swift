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
