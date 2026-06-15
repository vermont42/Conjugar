//
//  GetterSetterRealTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/14/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class GetterSetterRealTests: XCTestCase {
  func testGetAndSet() {
    let settings = Settings(getterSetter: GetterSetterReal())
    let savedRegion = settings.region
    settings.region = .spain
    XCTAssertEqual(settings.region, .spain)
    settings.region = .latinAmerica
    XCTAssertEqual(settings.region, .latinAmerica)
    settings.region = savedRegion
  }
}
