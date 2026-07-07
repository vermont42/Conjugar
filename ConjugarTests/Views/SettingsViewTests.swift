//
//  SettingsViewTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/27/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Converted from XCTest to Swift Testing during the SwiftUI migration (Step 4):
//  under MainActor default isolation, XCTest deallocating a @MainActor @Observable
//  object (SettingsView's since-retired SelectionStore, and now @Observable Settings)
//  hits the Xcode 26.3 isolated-deinit double-free. Swift Testing sidesteps it
//  (see CLAUDE.md).
//

import SwiftUI
import Testing
@testable import Conjugar

@MainActor
@Suite struct SettingsViewTests {
  @Test func initializationProducesABody() {
    let settingsView = SettingsView()
    #expect(settingsView.body is (any View))
  }
}
