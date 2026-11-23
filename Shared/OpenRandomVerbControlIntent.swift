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

  /// A literal, since `AnalyticsSource` is not in this target. `AppRouterTests` pins it to the vocabulary.
  static let pendingDeeplink = "conjugar://verb/random?source=control"

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set(Self.pendingDeeplink, forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
