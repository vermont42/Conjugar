//
//  OpenVerbSearchIntent.swift
//  Conjugar
//
//  The action behind the Find a Verb control in Control Center (browse plan, Phase 10). It
//  opens the app on the Verbs tab with an empty, focused search field, as the Home Screen quick
//  action and Command-F do. A control cannot navigate, so it stashes a deeplink that the app
//  drains when it becomes active. Hidden from Shortcuts, which will offer Look Up a Verb
//  (Phase 11) instead. Lives in Shared so the app can also resolve the intent's metadata.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenVerbSearchIntent: AppIntent {
  // Inline literal, not WidgetL: AppIntent metadata is extracted at compile time.
  static let title = LocalizedStringResource("Widget.intentFindVerb", defaultValue: "Find a Verb")
  static let openAppWhenRun = true
  static let isDiscoverable = false

  /// A literal, since `URL.searchDeeplink` and `AnalyticsSource` are not in this target.
  /// `AppRouterTests` pins it to the vocabulary.
  static let pendingDeeplink = "conjugar://search?source=control"

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set(Self.pendingDeeplink, forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
