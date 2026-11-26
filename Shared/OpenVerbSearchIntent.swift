//
//  OpenVerbSearchIntent.swift
//  Conjugar
//
//  The action behind the Find a Verb control in Control Center. It opens the app on the Verbs
//  tab with an empty, focused search field, as the Home Screen quick action and Command-F do. A
//  control cannot navigate, so it stashes its link (`LinkStashingIntent`).
//  Hidden from Shortcuts, which offers Look Up a Verb instead. Lives in Shared so the app can
//  also resolve the intent's metadata.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenVerbSearchIntent: LinkStashingIntent {
  // Inline literal, not WidgetL: AppIntent metadata is extracted at compile time.
  static let title = LocalizedStringResource("Widget.intentFindVerb", defaultValue: "Find a Verb")
  static let openAppWhenRun = true
  static let isDiscoverable = false

  /// `conjugar://search?source=control`. The source is a literal, since `AnalyticsSource` is not
  /// in this target; `AppRouterTests` pins it to the vocabulary.
  static let link = URL.deeplink(host: URL.searchHost, target: nil, queryItems: [
    URLQueryItem(name: URL.sourceQueryName, value: "control")
  ])
}
