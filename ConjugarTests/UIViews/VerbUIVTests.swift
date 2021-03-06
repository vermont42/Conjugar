//
//  VerbUIVTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/4/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class VerbUIVTests: XCTestCase {
  func testVerbVC() {
    Current = World.unitTest
    let vvc = VerbVC(verb: "maltear")
    let verbView = vvc.verbView
    XCTAssertNotNil(verbView)
    let expectedSubviewCount = 8
    XCTAssertEqual(verbView.subviews.count, expectedSubviewCount)
  }
}
