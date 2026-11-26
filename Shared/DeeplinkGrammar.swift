//
//  DeeplinkGrammar.swift
//  Conjugar
//
//  The constants of the `conjugar://` grammar and its one raw builder, shared by the app and the
//  widget extension so that the widgets and the intents in Shared build their links from the same
//  names as the app's `URL` builders (`Utils/URLExtension.swift`), which add the app's vocabulary.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

// The grammar is `conjugar://<route>[/<target>][?<item>=<value>&…]`: the route is the host, the
// target at most one path segment, and text only ever in a query item, because it can hold
// spaces and slashes. `docs/feature_architecture.md` § Deeplinks lists every route.
extension URL {
  nonisolated static let deeplinkScheme = "conjugar"
  nonisolated static let verbHost = "verb"
  nonisolated static let searchHost = "search"
  nonisolated static let infoHost = "info"
  nonisolated static let quizHost = "quiz"
  nonisolated static let gameHost = "game"
  /// A collection: `conjugar://list/top100`, `conjugar://list/model-31`.
  nonisolated static let listHost = "list"
  /// The target of `conjugar://verb/random`.
  nonisolated static let randomVerbTarget = "random"
  /// The target by which the Quick Quiz control, the quiz shortcut, and the Live Activity start a
  /// quiz, `conjugar://quiz/start`. The router starts one for any target but the three below.
  nonisolated static let quizStartTarget = "start"
  /// The target of a practice set's link, `conjugar://quiz/set?…`. The quiz route's other
  /// targets start a quiz.
  nonisolated static let practiceSetTarget = "set"
  /// The target of the daily session's link, `conjugar://quiz/daily?source=reminder`, which starts
  /// a daily session rather than the quiz over every verb.
  nonisolated static let dailySessionTarget = "daily"
  /// The target of a daily challenge's link, `conjugar://quiz/challenge?date=…&level=…&region=…`.
  nonisolated static let challengeTarget = "challenge"

  /// The query item a `conjugar://` link names its surface in, as in
  /// `conjugar://verb/hablar?source=widget`. A widget or a control can hand the app only a URL.
  nonisolated static let sourceQueryName = "source"
  /// A search's text: `conjugar://search?q=he%20hablado`.
  nonisolated static let searchTextQueryName = "q"
  /// A form a verb page marks, as it marks a search's match: `conjugar://verb/ir?match=fue`.
  nonisolated static let matchQueryName = "match"
  /// The cells a verb page marks, by `ConjugationCell.code` and separated by commas, when `match`
  /// alone would mark more: `conjugar://verb/levantar?match=levanta&cells=ioss` marks the tú
  /// command, not the presente's él as well. The page prefers it to `match`.
  nonisolated static let cellsQueryName = "cells"
  /// A practice set's level: `conjugar://quiz/set?tenses=futuro&level=beginner`.
  nonisolated static let levelQueryName = "level"
  /// A daily challenge's day, `yyyy-MM-dd`.
  nonisolated static let dateQueryName = "date"
  /// A daily challenge's region, `spain` or `latinAmerica`.
  nonisolated static let regionQueryName = "region"

  /// Whether this is a `conjugar://` link. iOS opens the app for the scheme in any case, so the
  /// app compares it without regard to case too.
  nonisolated var isDeeplink: Bool {
    scheme?.lowercased() == Self.deeplinkScheme
  }

  /// The link's route, its host, lowercased: `CONJUGAR://VERB/hablar` is a verb link. A target
  /// keeps its case, since a verb's name is spelled as the map spells it.
  nonisolated var deeplinkRoute: String? {
    host()?.lowercased()
  }

  /// A `conjugar://` link of the route `host`, with `target` as its one path segment and the
  /// non-nil `queryItems`, percent-encoded.
  nonisolated static func deeplink(host: String, target: String?, queryItems: [URLQueryItem?]) -> URL? {
    var components = URLComponents()
    components.scheme = deeplinkScheme
    components.host = host
    components.path = target.map { "/\($0)" } ?? ""
    let items = queryItems.compactMap { $0 }
    components.queryItems = items.isEmpty ? nil : items
    return components.url
  }
}
