//
//  DeviceUtilityTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 4/24/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class DeviceUtilityTests: XCTestCase {
  func testModelName() {
    // This won't work if tests run on device. But in my case, they don't.
    XCTAssertEqual(UIDevice.current.modelName, "Simulator")
  }
}
