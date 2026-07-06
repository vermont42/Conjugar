//
//  ConjugationResultTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

@MainActor
class ConjugationResultTests: XCTestCase {
  func testCompare() {
    var lhs = ""
    var rhs = ""

    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .noMatch)
    lhs = " "
    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .noMatch)
    lhs = "cómo"
    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .noMatch)
    rhs = "comó"
    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .partialMatch)
    lhs = "comó"
    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .totalMatch)
    rhs = "🥥🥥🥥🥥"
    XCTAssertEqual(ConjugationResult.compare(lhs: lhs, rhs: rhs), .noMatch)
  }
}
