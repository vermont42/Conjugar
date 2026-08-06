//
//  WidgetConstants.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension. The single source of
//  truth for the App Group, the snapshot file
//  name, and the small mutable keys the interactive quiz + control widgets stash in
//  the shared defaults suite.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum WidgetConstants {
  /// Must match the `com.apple.security.application-groups` entry in **both**
  /// `Conjugar.entitlements` and `ConjugarWidget.entitlements`.
  static let appGroupID = "group.biz.joshadams.Conjugar"

  /// The verb-of-the-day + daily-quiz payload the app writes and the widget reads.
  static let snapshotFilename = "widget-snapshot.json"

  // Interactive-quiz answer state (written by AnswerQuizIntent, read by QuizProvider).
  static let quizAnsweredKey = "widgetQuizAnswered"
  static let quizCorrectKey = "widgetQuizCorrect"
  static let quizQuestionIDKey = "widgetQuizQuestionID"

  /// Control-widget deeplink, drained by the app on next activation.
  static let pendingDeeplinkKey = "widgetPendingDeeplink"

  static var sharedContainerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
  }

  static var snapshotURL: URL? {
    sharedContainerURL?.appendingPathComponent(snapshotFilename)
  }

  static var sharedDefaults: UserDefaults? {
    UserDefaults(suiteName: appGroupID)
  }
}
