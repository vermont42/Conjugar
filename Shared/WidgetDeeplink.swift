//
//  WidgetDeeplink.swift
//  Conjugar
//
//  The `conjugar://` links the widgets and the Live Activity attach with `.widgetURL(_:)`, so that a
//  tap opens the app there. In Shared, though only the extension shows them, so that
//  `AppRouterTests` can route each one.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum WidgetDeeplink {
  /// `conjugar://verb/hablar?source=widget`. The source is a literal, since `AnalyticsSource` is
  /// not in this target. A reflexive-only verb comes as its citation form, arrepentirse, which the
  /// router accepts.
  static func verb(_ infinitive: String) -> URL? {
    URL.deeplink(host: URL.verbHost, target: infinitive, queryItems: [
      URLQueryItem(name: URL.sourceQueryName, value: "widget")
    ])
  }

  /// `conjugar://quiz/start`, from the Live Activity. It names no source, so the quiz reports
  /// `deeplink`.
  static var quizStart: URL? {
    URL.deeplink(host: URL.quizHost, target: URL.quizStartTarget, queryItems: [])
  }

  /// `conjugar://quiz/challenge?source=challengeWidget`: the day's challenge at the learner's
  /// level and region, whose first question the quiz widget asks.
  static var challenge: URL? {
    URL.deeplink(host: URL.quizHost, target: URL.challengeTarget, queryItems: [
      URLQueryItem(name: URL.sourceQueryName, value: "challengeWidget")
    ])
  }
}
