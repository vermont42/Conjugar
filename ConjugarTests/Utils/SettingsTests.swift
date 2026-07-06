//
//  SettingsTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class SettingsTests: XCTestCase {
  func testVerbSortDefaultsToFrequency() {
    let settings = Settings(getterSetter: GetterSetterFake())
    XCTAssertEqual(settings.verbSort, Settings.verbSortDefault)
    XCTAssertEqual(settings.verbSort, .frequency)
  }

  func testVerbSortPersists() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    settings.verbSort = .alphabetical
    XCTAssertEqual(getterSetter.get(key: Settings.verbSortKey), VerbSort.alphabetical.rawValue)

    let reloadedSettings = Settings(getterSetter: getterSetter)
    XCTAssertEqual(reloadedSettings.verbSort, .alphabetical)
  }
}
