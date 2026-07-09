//
//  RandomVerbControl.swift
//  ConjugarWidget
//
//  A Control Center / Lock Screen control that opens a random Spanish verb.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import SwiftUI
import WidgetKit

struct RandomVerbControl: ControlWidget {
  let kind = "RandomVerbControl"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: kind) {
      ControlWidgetButton(action: OpenRandomVerbIntent()) {
        Label(WidgetL.RandomVerbControl.name, systemImage: "shuffle")
      }
    }
    .displayName(WidgetL.RandomVerbControl.name)
    .description(WidgetL.RandomVerbControl.description)
  }
}
