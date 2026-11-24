//
//  WidgetDeeplink.swift
//  ConjugarWidget
//
//  Builds the `conjugar://` URLs the widgets attach via `.widgetURL(_:)` so tapping
//  a widget deep-links into the app. A verb link names its surface (`?source=widget`), which the
//  app's verb page reports as its `source` analytics parameter.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum WidgetDeeplink {
  static func verb(_ infinitive: String) -> URL? {
    let encoded = infinitive.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? infinitive
    return URL(string: "conjugar://verb/\(encoded)?source=widget")
  }

  static var quizStart: URL? {
    URL(string: "conjugar://quiz/start")
  }

  /// The day's challenge at the learner's level and region, whose first question the quiz widget
  /// asks.
  static var challenge: URL? {
    URL(string: "conjugar://quiz/challenge?source=challengeWidget")
  }
}
