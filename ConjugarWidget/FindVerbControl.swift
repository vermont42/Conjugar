//
//  FindVerbControl.swift
//  ConjugarWidget
//
//  A Control Center / Lock Screen control that opens Conjugar's verb search, empty and
//  focused (browse plan, Phase 10).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import SwiftUI
import WidgetKit

struct FindVerbControl: ControlWidget {
  let kind = "FindVerbControl"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: kind) {
      ControlWidgetButton(action: OpenVerbSearchIntent()) {
        Label(WidgetL.FindVerbControl.name, systemImage: "magnifyingglass")
      }
    }
    .displayName(WidgetL.FindVerbControl.name)
    .description(WidgetL.FindVerbControl.description)
  }
}
