//
//  ConjugarUITests.swift
//  ConjugarUITests
//
//  Created by Joshua Adams on 12/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import XCTest

class ConjugarUITests: XCTestCase {

    override func setUp() {
      continueAfterFailure = false
      let app = XCUIApplication()
      app.launchArguments = ["enable-ui-testing"]
      app.launch()
    }

    override func tearDown() {}

    func testExample() {

  }
}
