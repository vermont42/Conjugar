//
//  WidgetDeeplink.swift
//  ConjugarWidget
//
//  Builds the `conjugar://` URLs the widgets attach via `.widgetURL(_:)` so tapping
//  a widget deep-links into the app.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum WidgetDeeplink {
  static func verb(_ infinitive: String) -> URL? {
    let encoded = infinitive.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? infinitive
    return URL(string: "conjugar://verb/\(encoded)")
  }

  static var quizStart: URL? {
    URL(string: "conjugar://quiz/start")
  }
}
