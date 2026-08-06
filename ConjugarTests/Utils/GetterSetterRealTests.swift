//
//  GetterSetterRealTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 5/14/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// Swift Testing (not XCTest) — see SettingsTests for the isolated-deinit rationale.
@Suite("GetterSetterReal")
@MainActor
struct GetterSetterRealTests {
  @Test func getAndSet() {
    let settings = Settings(getterSetter: GetterSetterReal())
    let savedRegion = settings.region
    settings.region = .spain
    #expect(settings.region == .spain)
    settings.region = .latinAmerica
    #expect(settings.region == .latinAmerica)
    settings.region = savedRegion
  }
}
