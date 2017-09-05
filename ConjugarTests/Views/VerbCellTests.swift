//
//  VerbCellTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/5/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class VerbCellTests: XCTestCase {
  func testVerbCell() {
    let cell = VerbCell(style: .default, reuseIdentifier: "cell")
    cell.configure(verb: "maltear")
    XCTAssertEqual(cell.verb.text, "maltear")
    XCTAssertEqual(cell.verb.textColor, Colors.yellow)
    XCTAssertEqual(cell.verb.font, Fonts.largeCell)
  }
}
