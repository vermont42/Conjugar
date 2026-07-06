//
//  SettingsTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// Swift Testing (not XCTest): under MainActor default isolation, XCTest's
// teardown deallocates the local @MainActor `Settings` via the isolated-deinit
// path, which crashes on the Xcode 26.3 toolchain. Swift Testing sidesteps that,
// matching Konjugieren's all-Swift-Testing suite.
@Suite("Settings")
@MainActor
struct SettingsTests {
  @Test func verbSortDefaultsToFrequency() {
    let settings = Settings(getterSetter: GetterSetterFake())
    #expect(settings.verbSort == Settings.verbSortDefault)
    #expect(settings.verbSort == .frequency)
  }

  @Test func verbSortPersists() {
    let getterSetter = GetterSetterFake()
    let settings = Settings(getterSetter: getterSetter)
    settings.verbSort = .alphabetical
    #expect(getterSetter.get(key: Settings.verbSortKey) == VerbSort.alphabetical.rawValue)

    let reloadedSettings = Settings(getterSetter: getterSetter)
    #expect(reloadedSettings.verbSort == .alphabetical)
  }
}
