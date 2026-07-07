//
//  OpenQuizIntent.swift
//  Conjugar
//
//  The action behind the Quick Quiz control-center widget. Opens the app and stashes
//  a deeplink the app drains on activation (control widgets can't navigate directly).
//  Lives in Shared so the app can also resolve the intent's metadata. Ported from
//  Conjuguer.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenQuizIntent: AppIntent {
  // Inline literal, not WidgetL: AppIntent metadata is extracted at compile time.
  static let title = LocalizedStringResource("Widget.intentOpenQuiz", defaultValue: "Open Quiz")
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    WidgetConstants.sharedDefaults?.set("conjugar://quiz/start", forKey: WidgetConstants.pendingDeeplinkKey)
    return .result()
  }
}
