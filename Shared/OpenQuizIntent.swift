//
//  OpenQuizIntent.swift
//  Conjugar
//
//  The action behind the Quick Quiz control-center widget and the Start a Quiz App Shortcut
//  (`ConjugarShortcuts`). Opens the app on a quiz through `LinkStashingIntent`, since a control
//  cannot navigate. Lives in Shared so the app can also resolve the intent's metadata.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

nonisolated struct OpenQuizIntent: LinkStashingIntent {
  // Inline literal, not WidgetL: AppIntent metadata is extracted at compile time.
  static let title = LocalizedStringResource("Widget.intentOpenQuiz", defaultValue: "Open Quiz")
  static let openAppWhenRun = true

  /// `conjugar://quiz/start`, with no source, so that the quiz reports `deeplink`.
  static let link = URL.deeplink(host: URL.quizHost, target: URL.quizStartTarget, queryItems: [])
}
