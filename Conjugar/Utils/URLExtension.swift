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

  /// The query item a `conjugar://` link names its surface in, as in
  /// `conjugar://verb/hablar?source=widget`. A widget or a control can hand the app only a URL.
  nonisolated static let sourceQueryName = "source"

  /// The surface this link says it came from, or nil if it names none that the app knows.
  nonisolated var analyticsSource: AnalyticsSource? {
    URLComponents(url: self, resolvingAgainstBaseURL: false)?
      .queryItems?
      .first { $0.name == Self.sourceQueryName }?
      .value
      .flatMap(AnalyticsSource.init(rawValue:))
  }
}
