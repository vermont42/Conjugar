//
//  QuickQuizControl.swift
//  ConjugarWidget
//
//  A Control Center / Lock Screen control that starts a Conjugar quiz. Ported from
//  Conjuguer.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import SwiftUI
import WidgetKit

struct QuickQuizControl: ControlWidget {
  let kind = "QuickQuizControl"

  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: kind) {
      ControlWidgetButton(action: OpenQuizIntent()) {
        Label(WidgetL.QuickQuizControl.name, systemImage: "pencil.circle.fill")
      }
    }
    .displayName(WidgetL.QuickQuizControl.name)
    .description(WidgetL.QuickQuizControl.description)
  }
}
