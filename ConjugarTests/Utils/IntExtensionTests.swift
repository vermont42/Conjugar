//
//  IntExtensionTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class IntExtensionTests: XCTestCase {
  func testShort() {
    let time = 42
    XCTAssertEqual(time.timeString, "42")
  }

  func testMedium() {
    let time = 142
    XCTAssertEqual(time.timeString, "2:22")
  }

  func testLong() {
    let time = 3601
    XCTAssertEqual(time.timeString, "1:00:01")
  }
}
