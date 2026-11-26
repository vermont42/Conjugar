//
//  LinkStashingIntent.swift
//  Conjugar
//
//  The one `perform()` of the intents that open the app on a link: the Quick Quiz, Random Verb,
//  and Find a Verb controls, and the Start a Quiz and Random Verb shortcuts.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

/// An intent with `openAppWhenRun` that names the link the app should open. It cannot navigate, so
/// it stashes the link in the App Group's defaults and announces it (`PendingDeeplink`).
nonisolated protocol LinkStashingIntent: AppIntent {
  /// The link the app routes. `AppRouterTests` pins each intent's to its route and source.
  static var link: URL? { get }
}

extension LinkStashingIntent {
  func perform() async throws -> some IntentResult {
    if let link = Self.link {
      PendingDeeplink.stash(link, in: WidgetConstants.sharedDefaults)
      PendingDeeplink.announce()
    }
    return .result()
  }
}
