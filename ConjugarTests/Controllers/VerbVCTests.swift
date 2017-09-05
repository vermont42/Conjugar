//
//  VerbVCTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class VerbVCTests: XCTestCase {
  func testVerbVC() {
    let vvc = VerbVC()
    vvc.verb = "maltear"
    UIApplication.shared.keyWindow?.rootViewController = vvc
    XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController)
    XCTAssertNotNil(vvc)
    XCTAssertNotNil(vvc.verbView)
  }
}

