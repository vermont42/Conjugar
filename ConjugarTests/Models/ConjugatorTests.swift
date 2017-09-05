//
//  ConjugatorTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/4/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ConjugatorTests: XCTestCase {
  func testConjugate() {
    var result = Conjugator.sharedInstance.conjugate(infinitive: "m", tense: .futuroDeIndicativo, personNumber: .firstSingular)
    switch result {
    case .failure:
      break
    default:
      XCTFail("One-letter words cannot be conjugated.")
      break
    }

    result = Conjugator.sharedInstance.conjugate(infinitive: "tango", tense: .preterito, personNumber: .thirdPlural)
    switch result {
    case .failure:
      break
    default:
      XCTFail("Words not ending in ar, er, or ir cannot be conjugated.")
      break
    }

    result = Conjugator.sharedInstance.conjugate(infinitive: "maltear", tense: .presenteDeIndicativo, personNumber: .secondSingular)
    switch result {
    case let .success(value):
      XCTAssertEqual(value, "malteas")
    default:
      XCTFail("Conjugation failed.")
      break
    }
  }
}
