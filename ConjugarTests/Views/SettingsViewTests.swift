//
//  SettingsViewTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 11/27/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI
import Testing
@testable import Conjugar

@MainActor
@Suite struct SettingsViewTests {
  // A crash smoke test: constructing SettingsView and evaluating its body
  // exercises the `@Bindable` binding to `Current.settings` and the whole card tree.
  // The signal is that neither `init` nor `body` traps, so there is nothing to `#expect`.
  @Test func bodyEvaluatesWithoutTrapping() {
    let settingsView = SettingsView(router: AppRouter())
    _ = settingsView.body
  }
}
