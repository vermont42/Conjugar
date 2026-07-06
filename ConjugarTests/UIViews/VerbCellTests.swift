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
  func testVerbCellWithRank() {
    let cell = VerbCell(style: .default, reuseIdentifier: "cell")
    let entry = VerbMapEntry(infinitive: "maltear", classNumbers: ["1"], glosses: ["malt"], isReflexive: false, frequencyRank: 42)
    cell.configure(entry: entry)
    XCTAssertEqual(cell.verb.text, "maltear")
    XCTAssertEqual(cell.verb.textColor, Colors.yellow)
    XCTAssertEqual(cell.verb.font, Fonts.largeCell)
    XCTAssertEqual(cell.gloss.text, "malt")
    XCTAssertEqual(cell.rank.text, "#42")
  }

  func testVerbCellWithoutRank() {
    let cell = VerbCell(style: .default, reuseIdentifier: "cell")
    let entry = VerbMapEntry(infinitive: "maltear", classNumbers: ["1"], glosses: ["malt"], isReflexive: false, frequencyRank: nil)
    cell.configure(entry: entry)
    XCTAssertEqual(cell.verb.text, "maltear")
    XCTAssertEqual(cell.gloss.text, "malt")
    XCTAssertNil(cell.rank.text)
  }
}
