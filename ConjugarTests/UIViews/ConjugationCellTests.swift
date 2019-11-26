//
//  ConjugationCellTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/22/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ConjugationCellTests: XCTestCase {
  func testConjugationCell() {
    let cell = ConjugationCell(style: .default, reuseIdentifier: "cell")
    XCTAssertEqual(cell.conjugation.textColor, Colors.yellow)
    XCTAssertEqual(cell.conjugation.font, Fonts.smallCell)

    cell.configure(tense: .pretérito, personNumber: .secondSingularTú, conjugation: "fuistes")
    XCTAssertEqual(cell.conjugation.text, "tú fuistes")

    cell.configure(tense: .imperativoPositivo, personNumber: .secondSingularTú, conjugation: "se")
    XCTAssertEqual(cell.conjugation.text, "¡se!")

    cell.configure(tense: .imperativoNegativo, personNumber: .secondSingularTú, conjugation: "no seas")
    XCTAssertEqual(cell.conjugation.text, "¡no seas!")

    cell.configure(tense: .imperativoNegativo, personNumber: .secondSingularTú, conjugation: Conjugator.defective)
    XCTAssertEqual(cell.conjugation.text, "")
  }
}
