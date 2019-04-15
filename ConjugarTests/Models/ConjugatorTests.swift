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
  func testBadInput() {
    var result = Conjugator.shared.conjugate(infinitive: "m", tense: .futuroDeIndicativo, personNumber: .firstSingular)
    switch result {
    case .failure:
      break
    default:
      XCTFail("One-letter words cannot be conjugated.")
    }

    result = Conjugator.shared.conjugate(infinitive: "tango 💃🏻", tense: .preterito, personNumber: .thirdPlural)
    switch result {
    case .failure:
      break
    default:
      XCTFail("Words not ending in ar, er, or ir cannot be conjugated.")
    }
  }

  func testThirdPersonSingularOnlyVerb() {
    VerbFamilies.thirdPersonSingularOnlyVerbs.forEach { verb in
      PersonNumber.allCases.forEach { personNumber in
        if ![.none, .thirdSingular].contains(personNumber) {
          let tense = Tense.conjugatedTenses[Int.random(in: 0 ..< Tense.conjugatedTenses.count)]
          let result = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
          switch result {
          case .success(let value):
            if value != Conjugator.defective {
              XCTFail("\(verb) should be defective for \(personNumber.pronoun), tense \(tense.displayName).")
            }
          default:
            XCTFail("\(verb) cannot be conjugated for \(personNumber.pronoun), tense \(tense.displayName).")
          }
        }
      }
    }
  }
}
