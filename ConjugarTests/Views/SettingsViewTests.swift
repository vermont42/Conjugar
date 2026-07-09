//
//  SettingsViewTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/27/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//
//  Converted from XCTest to Swift Testing during the SwiftUI migration:
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
  // A crash smoke test: constructing SettingsView and evaluating its body
  // exercises the `@Bindable` binding to `Current.settings` and the whole card tree.
  // The old `body is (any View)` assertion was vacuously true by construction — the
  // real signal is that neither `init` nor `body` traps. `_ = body` keeps that signal
  // without the tautological `#expect`.
  @Test func bodyEvaluatesWithoutTrapping() {
    let settingsView = SettingsView()
    _ = settingsView.body
  }
}
