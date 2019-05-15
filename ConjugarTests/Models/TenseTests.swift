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
  func testDisplayNames() {
    [(Tense.infinitivo, "infinitivo"), (.translation, "translation"), (.gerundio, "gerundio"), (.participio, "participio"), (.raízFutura, "raíz futura"), (.imperativoPositivo, "imperativo positivo"), (.imperativoNegativo, "imperativo negativo"), (.presenteDeIndicativo, "presente de indicativo"), (.pretérito, "pretérito"), (.imperfectoDeIndicativo, "imperfecto de indicativo"), (.futuroDeIndicativo, "futuro de indicativo"), (.condicional, "condicional"), (.presenteDeSubjuntivo, "presente de subjuntivo"), (.imperfectoDeSubjuntivo1, "imperfecto de subjuntivo 1"), (.imperfectoDeSubjuntivo2, "imperfecto de subjuntivo 2"), (.futuroDeSubjuntivo, "futuro de subjuntivo"), (.perfectoDeIndicativo, "perfecto de indicativo"), (.pretéritoAnterior, "pretérito anterior"), (.pluscuamperfectoDeIndicativo, "pluscuamperfecto de indicativo"), (.futuroPerfecto, "futuro perfecto"), (.condicionalCompuesto, "condicional compuesto"), (.perfectoDeSubjuntivo, "perfecto de subjuntivo"), (.pluscuamperfectoDeSubjuntivo1, "pluscuamperfecto de subjuntivo 1"), (.pluscuamperfectoDeSubjuntivo2, "pluscuamperfecto de subjuntivo 2")].forEach {
      testDisplayName(tense: $0.0, displayName: $0.1)
    }
  }

  private func testDisplayName(tense: Tense, displayName: String) {
    XCTAssertEqual(tense.displayName, displayName)
  }

  func testTitleCaseNames() {
    [(Tense.infinitivo, "Infinitivo"), (.translation, "Translation"), (.gerundio, "Gerundio"), (.participio, "Participio"), (.raízFutura, "Raíz Futura"), (.imperativoPositivo, "Imperativo Positivo"), (.imperativoNegativo, "Imperativo Negativo"), (.presenteDeIndicativo, "Presente de Indicativo"), (.pretérito, "Pretérito"), (.imperfectoDeIndicativo, "Imperfecto de Indicativo"), (.futuroDeIndicativo, "Futuro de Indicativo"), (.condicional, "Condicional"), (.presenteDeSubjuntivo, "Presente de Subjuntivo"), (.imperfectoDeSubjuntivo1, "Imperfecto de Subjuntivo 1"), (.imperfectoDeSubjuntivo2, "Imperfecto de Subjuntivo 2"), (.futuroDeSubjuntivo, "Futuro de Subjuntivo"), (.perfectoDeIndicativo, "Perfecto de Indicativo"), (.pretéritoAnterior, "Pretérito Anterior"), (.pluscuamperfectoDeIndicativo, "Pluscuamperfecto de Indicativo"), (.futuroPerfecto, "Futuro Perfecto"), (.condicionalCompuesto, "Condicional Compuesto"), (.perfectoDeSubjuntivo, "Perfecto de Subjuntivo"), (.pluscuamperfectoDeSubjuntivo1, "Pluscuamperfecto de Subjuntivo 1"), (.pluscuamperfectoDeSubjuntivo2, "Pluscuamperfecto de Subjuntivo 2")].forEach {
      testTitleCaseName(tense: $0.0, titleCaseName: $0.1)
    }
  }

  private func testTitleCaseName(tense: Tense, titleCaseName: String) {
    XCTAssertEqual(tense.titleCaseName, titleCaseName)
  }

  func testHaberTensesForCompoundTenses() {
    // The following line uses as much type inference as the compiler allows.
    [(Tense.perfectoDeIndicativo, .presenteDeIndicativo), (.pretéritoAnterior, .pretérito), (.pluscuamperfectoDeIndicativo, .imperfectoDeIndicativo), (.futuroPerfecto, .futuroDeIndicativo), (.condicionalCompuesto, .condicional), (.perfectoDeSubjuntivo, .presenteDeSubjuntivo), (.pluscuamperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo1), (.pluscuamperfectoDeSubjuntivo2, .imperfectoDeSubjuntivo1), (Tense.futuroPerfectoDeSubjuntivo, Tense.futuroDeSubjuntivo)].forEach {
      testHaberTenseForCompoundTense(compoundTense: $0.0, haberTense: $0.1)
    }

    let notACompoundTense: Tense = .infinitivo
    let result = notACompoundTense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTFail("Haber form \(haberTense.displayName) incorrectly found for tense \(notACompoundTense.displayName).")
    case .failure:
      break
    }
  }

  private func testHaberTenseForCompoundTense(compoundTense: Tense, haberTense: Tense) {
    let result = compoundTense.haberTenseForCompoundTense()
    switch result {
    case .success(let haberTense):
      XCTAssertEqual(haberTense, haberTense)
    case .failure:
      XCTFail("No haber tense found for \(compoundTense.displayName).")
    }
  }
}
