//
//  DisplayPersonNumberTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

@MainActor
class DisplayPersonNumberTests: XCTestCase {
  func testShortDisplayName() {
    var personNumber = DisplayPersonNumber.firstSingular
    XCTAssertEqual(personNumber.shortDisplayName, "1S")
    personNumber = .secondSingularTú
    XCTAssertEqual(personNumber.shortDisplayName, "2S")
    personNumber = .secondSingularVos
    XCTAssertEqual(personNumber.shortDisplayName, "2SV")
    personNumber = .thirdSingular
    XCTAssertEqual(personNumber.shortDisplayName, "3S")
    personNumber = .firstPlural
    XCTAssertEqual(personNumber.shortDisplayName, "1P")
    personNumber = .secondPlural
    XCTAssertEqual(personNumber.shortDisplayName, "2P")
    personNumber = .thirdPlural
    XCTAssertEqual(personNumber.shortDisplayName, "3P")
    personNumber = .none
    XCTAssertEqual(personNumber.shortDisplayName, "none")
  }

  func testPronoun() {
    var personNumber = DisplayPersonNumber.firstSingular
    XCTAssertEqual(personNumber.pronoun, "yo")
    personNumber = DisplayPersonNumber.secondSingularTú
    XCTAssertEqual(personNumber.pronoun, "tú")
    personNumber = DisplayPersonNumber.secondSingularVos
    XCTAssertEqual(personNumber.pronoun, "vos")
    personNumber = DisplayPersonNumber.thirdSingular
    XCTAssertEqual(personNumber.pronoun, "él")
    personNumber = DisplayPersonNumber.firstPlural
    XCTAssertEqual(personNumber.pronoun, "nosotros")
    personNumber = DisplayPersonNumber.secondPlural
    XCTAssertEqual(personNumber.pronoun, "vosotros")
    personNumber = DisplayPersonNumber.thirdPlural
    XCTAssertEqual(personNumber.pronoun, "ellas")
    personNumber = DisplayPersonNumber.none
    XCTAssertEqual(personNumber.pronoun, "none")
  }
}
