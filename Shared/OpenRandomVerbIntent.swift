//
//  OpenRandomVerbIntent.swift
//  Conjugar
//
//  The action behind the Random Verb control-center widget. Opens the app and stashes
//  a deeplink the app drains on activation.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenRandomVerbIntent: AppIntent {
  static let title = LocalizedStringResource("Widget.intentOpenRandomVerb", defaultValue: "Open Random Verb")
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set("conjugar://verb/random", forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
