//
//  OpenRandomVerbIntent.swift
//  Conjugar
//
//  Open Random Verb, as the Shortcuts app and Siri offer it (the Random Verb App Shortcut in
//  `ConjugarShortcuts`). Opens the app on a random verb through `LinkStashingIntent`. The
//  Random Verb control runs its own hidden `OpenRandomVerbControlIntent` instead, because an
//  intent cannot tell which of the two ran it, and the verb page reports which
//  (`source=shortcut` here, `control` there).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenRandomVerbIntent: LinkStashingIntent {
  static let title = LocalizedStringResource("Widget.intentOpenRandomVerb", defaultValue: "Open Random Verb")
  static let openAppWhenRun = true

  /// `conjugar://verb/random?source=shortcut`. The source is a literal, since `AnalyticsSource` is
  /// not in this target; `AppRouterTests` pins it to the vocabulary.
  static let link = URL.deeplink(host: URL.verbHost, target: URL.randomVerbTarget, queryItems: [
    URLQueryItem(name: URL.sourceQueryName, value: "shortcut")
  ])
}
