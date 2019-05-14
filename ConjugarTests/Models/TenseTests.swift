//
//  TenseTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/14/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class TenseTests: XCTestCase {
  func testDisplayName() {
    var tense: Tense = .infinitivo
    XCTAssertEqual(tense.displayName, "infinitivo")
    tense = .translation
    XCTAssertEqual(tense.displayName, "translation")
    tense = .gerundio
    XCTAssertEqual(tense.displayName, "gerundio")
    tense = .participio
    XCTAssertEqual(tense.displayName, "participio")
    tense = .raízFutura
    XCTAssertEqual(tense.displayName, "raíz futura")
    tense = .imperativoPositivo
    XCTAssertEqual(tense.displayName, "imperativo positivo")
    tense = .imperativoNegativo
    XCTAssertEqual(tense.displayName, "imperativo negativo")
    tense = .presenteDeIndicativo
    XCTAssertEqual(tense.displayName, "presente de indicativo")
    tense = .pretérito
    XCTAssertEqual(tense.displayName, "pretérito")
    tense = .imperfectoDeIndicativo
    XCTAssertEqual(tense.displayName, "imperfecto de indicativo")
    tense = .futuroDeIndicativo
    XCTAssertEqual(tense.displayName, "futuro de indicativo")
    tense = .condicional
    XCTAssertEqual(tense.displayName, "condicional")
    tense = .presenteDeSubjuntivo
    XCTAssertEqual(tense.displayName, "presente de subjuntivo")
    tense = .imperfectoDeSubjuntivo1
    XCTAssertEqual(tense.displayName, "imperfecto de subjuntivo 1")
    tense = .imperfectoDeSubjuntivo2
    XCTAssertEqual(tense.displayName, "imperfecto de subjuntivo 2")
    tense = .futuroDeSubjuntivo
    XCTAssertEqual(tense.displayName, "futuro de subjuntivo")
    tense = .perfectoDeIndicativo
    XCTAssertEqual(tense.displayName, "perfecto de indicativo")
    tense = .pretéritoAnterior
    XCTAssertEqual(tense.displayName, "pretérito anterior")
    tense = .pluscuamperfectoDeIndicativo
    XCTAssertEqual(tense.displayName, "pluscuamperfecto de indicativo")
    tense = .futuroPerfecto
    XCTAssertEqual(tense.displayName, "futuro perfecto")
    tense = .condicionalCompuesto
    XCTAssertEqual(tense.displayName, "condicional compuesto")
    tense = .perfectoDeSubjuntivo
    XCTAssertEqual(tense.displayName, "perfecto de subjuntivo")
    tense = .pluscuamperfectoDeSubjuntivo1
    XCTAssertEqual(tense.displayName, "pluscuamperfecto de subjuntivo 1")
    tense = .pluscuamperfectoDeSubjuntivo2
    XCTAssertEqual(tense.displayName, "pluscuamperfecto de subjuntivo 2")
  }

  func testTitleCaseName() {
    var tense: Tense = .infinitivo
    XCTAssertEqual(tense.titleCaseName, "Infinitivo")
    tense = .translation
    XCTAssertEqual(tense.titleCaseName, "Translation")
    tense = .gerundio
    XCTAssertEqual(tense.titleCaseName, "Gerundio")
    tense = .participio
    XCTAssertEqual(tense.titleCaseName, "Participio")
    tense = .raízFutura
    XCTAssertEqual(tense.titleCaseName, "Raíz Futura")
    tense = .imperativoPositivo
    XCTAssertEqual(tense.titleCaseName, "Imperativo Positivo")
    tense = .imperativoNegativo
    XCTAssertEqual(tense.titleCaseName, "Imperativo Negativo")
    tense = .presenteDeIndicativo
    XCTAssertEqual(tense.titleCaseName, "Presente de Indicativo")
    tense = .pretérito
    XCTAssertEqual(tense.titleCaseName, "Pretérito")
    tense = .imperfectoDeIndicativo
    XCTAssertEqual(tense.titleCaseName, "Imperfecto de Indicativo")
    tense = .futuroDeIndicativo
    XCTAssertEqual(tense.titleCaseName, "Futuro de Indicativo")
    tense = .condicional
    XCTAssertEqual(tense.titleCaseName, "Condicional")
    tense = .presenteDeSubjuntivo
    XCTAssertEqual(tense.titleCaseName, "Presente de Subjuntivo")
    tense = .imperfectoDeSubjuntivo1
    XCTAssertEqual(tense.titleCaseName, "Imperfecto de Subjuntivo 1")
    tense = .imperfectoDeSubjuntivo2
    XCTAssertEqual(tense.titleCaseName, "Imperfecto de Subjuntivo 2")
    tense = .futuroDeSubjuntivo
    XCTAssertEqual(tense.titleCaseName, "Futuro de Subjuntivo")
    tense = .perfectoDeIndicativo
    XCTAssertEqual(tense.titleCaseName, "Perfecto de Indicativo")
    tense = .pretéritoAnterior
    XCTAssertEqual(tense.titleCaseName, "Pretérito Anterior")
    tense = .pluscuamperfectoDeIndicativo
    XCTAssertEqual(tense.titleCaseName, "Pluscuamperfecto de Indicativo")
    tense = .futuroPerfecto
    XCTAssertEqual(tense.titleCaseName, "Futuro Perfecto")
    tense = .condicionalCompuesto
    XCTAssertEqual(tense.titleCaseName, "Condicional Compuesto")
    tense = .perfectoDeSubjuntivo
    XCTAssertEqual(tense.titleCaseName, "Perfecto de Subjuntivo")
    tense = .pluscuamperfectoDeSubjuntivo1
    XCTAssertEqual(tense.titleCaseName, "Pluscuamperfecto de Subjuntivo 1")
    tense = .pluscuamperfectoDeSubjuntivo2
    XCTAssertEqual(tense.titleCaseName, "Pluscuamperfecto de Subjuntivo 2")
    tense = .futuroPerfectoDeSubjuntivo
    XCTAssertEqual(tense.titleCaseName, "Futuro Perfecto de Subjuntivo")
  }

  func testHaberTenseForCompoundTense() {
    var tense: Tense = .perfectoDeIndicativo
    var result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .presenteDeIndicativo)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .pretéritoAnterior
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .pretérito)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .pluscuamperfectoDeIndicativo
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .imperfectoDeIndicativo)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .futuroPerfecto
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .futuroDeIndicativo)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .condicionalCompuesto
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .condicional)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .perfectoDeSubjuntivo
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .presenteDeSubjuntivo)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .pluscuamperfectoDeSubjuntivo1
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .imperfectoDeSubjuntivo1)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .pluscuamperfectoDeSubjuntivo2
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .imperfectoDeSubjuntivo2)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .futuroPerfectoDeSubjuntivo
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, .futuroDeSubjuntivo)
    case .failure(_):
      XCTFail("No haber tense found for \(tense.displayName).")
    }

    tense = .infinitivo
    result = tense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTFail("Haber form \(haberTense.displayName) incorrectly found for tense \(tense.displayName).")
    case .failure(_):
      break
    }
  }
}
