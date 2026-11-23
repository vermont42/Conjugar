//
//  OpenRandomVerbIntent.swift
//  Conjugar
//
//  Open Random Verb, as the Shortcuts app and Siri offer it (the Random Verb App Shortcut in
//  `ConjugarShortcuts`, since browse Phase 11). Opens the app and stashes a
//  deeplink the app drains on activation. The Random Verb control runs its own hidden
//  `OpenRandomVerbControlIntent` instead, because an intent cannot tell which of the two ran it,
//  and the verb page reports which (`source=shortcut` here, `control` there).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenRandomVerbIntent: AppIntent {
  static let title = LocalizedStringResource("Widget.intentOpenRandomVerb", defaultValue: "Open Random Verb")
  static let openAppWhenRun = true

  /// A literal, since `AnalyticsSource` is not in this target. `AppRouterTests` pins it to the vocabulary.
  static let pendingDeeplink = "conjugar://verb/random?source=shortcut"

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set(Self.pendingDeeplink, forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
