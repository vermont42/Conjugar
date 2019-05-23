//
//  ResultCellTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/16/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ResultCellTests: XCTestCase {
  func testResultCell() {
    let cell = ResultCell(style: .default, reuseIdentifier: "cell")

    cell.configure(verb: "dar", tense: .presenteDeIndicativo, personNumber: .firstSingular, correctAnswer: "doy", proposedAnswer: "doy")
    XCTAssertEqual(cell.verb.text, "dar")
    XCTAssertEqual(cell.tensePersonNumber.text, "presente de indicativo, 1S")
    XCTAssertEqual(cell.correctAnswer.text, "doy")
    XCTAssertEqual(cell.proposedAnswer.text, "doy")
    XCTAssert(cell.proposedAnswer.textColor == Colors.yellow)

    cell.configure(verb: "dar", tense: .presenteDeIndicativo, personNumber: .firstSingular, correctAnswer: "doy", proposedAnswer: "do")
    XCTAssertEqual(cell.verb.text, "dar")
    XCTAssertEqual(cell.tensePersonNumber.text, "presente de indicativo, 1S")
    XCTAssertEqual(cell.correctAnswer.text, "doy")
    XCTAssertEqual(cell.proposedAnswer.text, "do")
    XCTAssert(cell.proposedAnswer.textColor == Colors.blue)
  }
}
