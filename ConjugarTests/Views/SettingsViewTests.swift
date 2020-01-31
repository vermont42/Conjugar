//
//  SettingsViewTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/27/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class SettingsViewTests: XCTestCase {
  func testInitialization() {
    let settingsView = SettingsView()
    XCTAssertNotNil(settingsView)
    XCTAssertNotNil(settingsView.body)
  }
}
