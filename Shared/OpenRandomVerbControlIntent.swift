//
//  OpenRandomVerbControlIntent.swift
//  Conjugar
//
//  The action behind the Random Verb control in Control Center. It does what
//  `OpenRandomVerbIntent` does, but is hidden from Shortcuts and names the control as the
//  deeplink's source, so that the verb page can tell a control's random verb from a shortcut's.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenRandomVerbControlIntent: AppIntent {
  static let title = LocalizedStringResource("Widget.intentOpenRandomVerb", defaultValue: "Open Random Verb")
  static let openAppWhenRun = true
  static let isDiscoverable = false

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set("conjugar://verb/random?source=control", forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
