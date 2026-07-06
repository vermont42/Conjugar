//
//  TenseCellTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/22/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

@MainActor
class TenseCellTests: XCTestCase {
  func testTenseCell() {
    let cell = TenseCell(style: .default, reuseIdentifier: "cell")
    XCTAssertEqual(cell.tense.textColor, Colors.red)
    XCTAssertEqual(cell.tense.font, Fonts.regularCell)

    cell.configure(tense: "Presente de Indicativo")
    XCTAssertEqual(cell.tense.text, "Presente de Indicativo")
  }
}
