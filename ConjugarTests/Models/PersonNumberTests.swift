//
//  PersonNumberTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/13/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class PersonNumberTests: XCTestCase {
  func testShortDisplayName() {
    var personNumber = PersonNumber.firstSingular
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
    var personNumber = PersonNumber.firstSingular
    XCTAssertEqual(personNumber.pronoun, "yo")
    personNumber = PersonNumber.secondSingularTú
    XCTAssertEqual(personNumber.pronoun, "tú")
    personNumber = PersonNumber.secondSingularVos
    XCTAssertEqual(personNumber.pronoun, "vos")
    personNumber = PersonNumber.thirdSingular
    XCTAssertEqual(personNumber.pronoun, "él")
    personNumber = PersonNumber.firstPlural
    XCTAssertEqual(personNumber.pronoun, "nosotros")
    personNumber = PersonNumber.secondPlural
    XCTAssertEqual(personNumber.pronoun, "vosotros")
    personNumber = PersonNumber.thirdPlural
    XCTAssertEqual(personNumber.pronoun, "ellas")
    personNumber = PersonNumber.none
    XCTAssertEqual(personNumber.pronoun, "none")
  }
}
