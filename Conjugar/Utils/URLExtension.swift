//
//  URLExtension.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

extension URL {
  /// Where feedback goes: Settings' email button and the verb search's request for a missing verb.
  nonisolated static let developerEmail = "vermontcoder@gmail.com"

  /// Conjugar's App Store page, which the verb page's share text links to. With no storefront in
  /// the path, the App Store opens the reader's own.
  nonisolated static var appStore: URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "apps.apple.com"
    components.path = "/app/conjugar/id\(RatingsFetcher.iTunesID)"
    return components.url ?? URL(filePath: "/")
  }

  nonisolated private static let mailtoUnreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

  /// A `mailto:` link with the subject and body filled in. Every character outside RFC 3986's
  /// unreserved set is percent-encoded, because a learner's query can hold &, =, #, or an ñ.
  nonisolated static func mailto(_ address: String, subject: String, body: String) -> URL? {
    let encode = { (text: String) in text.addingPercentEncoding(withAllowedCharacters: mailtoUnreserved) ?? "" }
    return URL(string: "mailto:\(address)?subject=\(encode(subject))&body=\(encode(body))")
  }

  // The grammar's constants, `isDeeplink`, and the raw builder are in `Shared/DeeplinkGrammar.swift`,
  // where the widget extension can see them.

  /// The link's target, its one path segment, decoded. Nil for a link with none or with more.
  nonisolated var deeplinkTarget: String? {
    let segments = pathComponents.filter { $0 != "/" }
    return segments.count == 1 ? segments[0] : nil
  }

  /// Whether the link has no path at all, as `conjugar://search` has.
  nonisolated var hasNoDeeplinkTarget: Bool {
    pathComponents.filter { $0 != "/" }.isEmpty
  }

  /// The value of a query item, such as a search's text.
  nonisolated func deeplinkQueryValue(named name: String) -> String? {
    URLComponents(url: self, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first { $0.name == name }?
      .value
  }

  /// The surface this link says it came from, or nil if it names none that the app knows.
  nonisolated var analyticsSource: AnalyticsSource? {
    deeplinkQueryValue(named: Self.sourceQueryName).flatMap(AnalyticsSource.init(rawValue:))
  }

  /// `conjugar://verb/tener?source=lookup&match=tuve`. A `match` names a form the page marks, and
  /// `cells`, when given, the cells it marks in place of every cell `match` is.
  nonisolated static func verbDeeplink(
    _ infinitive: String,
    source: AnalyticsSource,
    match: String? = nil,
    cells: [ConjugationCell]? = nil
  ) -> URL? {
    deeplink(host: verbHost, target: infinitive, queryItems: [
      URLQueryItem(name: sourceQueryName, value: source.rawValue),
      match.map { URLQueryItem(name: matchQueryName, value: $0) },
      cells.map { URLQueryItem(name: cellsQueryName, value: $0.map(\.code).joined(separator: ",")) }
    ])
  }

  /// The cells a verb link's `cells` names, those of its codes that are cells. Nil when it names
  /// none.
  nonisolated var deeplinkCells: [ConjugationCell]? {
    let cells = deeplinkQueryValue(named: Self.cellsQueryName)?
      .split(separator: ",")
      .compactMap(ConjugationCell.init(code:)) ?? []
    return cells.isEmpty ? nil : cells
  }

  /// `conjugar://search?q=fue&source=control`. With no text, or empty text, the search opens empty
  /// and focused for typing.
  nonisolated static func searchDeeplink(text: String?, source: AnalyticsSource) -> URL? {
    deeplink(host: searchHost, target: nil, queryItems: [
      text.map { URLQueryItem(name: searchTextQueryName, value: $0) },
      URLQueryItem(name: sourceQueryName, value: source.rawValue)
    ])
  }

  /// `conjugar://info/voseo`. A stable key survives a reordering of the articles, which a
  /// position does not.
  nonisolated static func infoDeeplink(stableKey: String) -> URL? {
    deeplink(host: infoHost, target: stableKey, queryItems: [])
  }

  /// `conjugar://list/goVerbs?source=sharedLink`, a collection by its key (`VerbCollection.key`).
  nonisolated static func listDeeplink(key: String, source: AnalyticsSource) -> URL? {
    deeplink(host: listHost, target: key, queryItems: [
      URLQueryItem(name: sourceQueryName, value: source.rawValue)
    ])
  }

  /// `conjugar://quiz/set?tenses=preterito&verbs=goVerbs&source=qrCode`, a practice set: the
  /// custom quiz's stored form as its query, then the level, when one travels, and the source.
  nonisolated static func practiceSetDeeplink(custom: CustomQuiz, level: QuizLevel?, source: AnalyticsSource) -> URL? {
    var components = URLComponents()
    components.percentEncodedQuery = custom.rawValue
    return deeplink(host: quizHost, target: practiceSetTarget, queryItems: (components.queryItems ?? []) + [
      level.map { URLQueryItem(name: levelQueryName, value: $0.rawValue) },
      URLQueryItem(name: sourceQueryName, value: source.rawValue)
    ])
  }

  /// `conjugar://quiz/daily?source=reminder`, which a tapped reminder opens.
  /// `conjugar://quiz/challenge?date=2026-11-24&level=elementary&region=spain&source=challengeLink`,
  /// a day's challenge. Without the key, the day's challenge at the learner's level and region.
  nonisolated static func challengeDeeplink(_ key: DailyChallenge.Key?, source: AnalyticsSource) -> URL? {
    deeplink(host: quizHost, target: challengeTarget, queryItems: [
      key.map { URLQueryItem(name: dateQueryName, value: $0.day) },
      key.map { URLQueryItem(name: levelQueryName, value: $0.levelKey) },
      key.map { URLQueryItem(name: regionQueryName, value: $0.regionKey) },
      URLQueryItem(name: sourceQueryName, value: source.rawValue)
    ])
  }

  nonisolated static func dailySessionDeeplink(source: AnalyticsSource) -> URL? {
    deeplink(host: quizHost, target: dailySessionTarget, queryItems: [
      URLQueryItem(name: sourceQueryName, value: source.rawValue)
    ])
  }
}
