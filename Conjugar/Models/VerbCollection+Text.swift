//
//  VerbCollection+Text.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// What a collection says about itself, which needs `L` and so the main actor, apart from the
/// `nonisolated` membership in `VerbCollection.swift`.
@MainActor
extension VerbCollection {
  var title: String {
    switch self {
    case .top100:
      return L.VerbCollection.top100Title
    case .goVerbs:
      return L.VerbCollection.goVerbsTitle
    case .strongPreterite:
      return L.VerbCollection.strongPreteriteTitle
    case .irregularFuture:
      return L.VerbCollection.irregularFutureTitle
    case .irregularParticiple:
      return L.VerbCollection.irregularParticipleTitle
    case .model(let classNumber):
      return L.VerbCollection.modelTitle(exemplar: ModelCatalog.exemplar(forClass: classNumber) ?? classNumber)
    }
  }

  /// A model has none: its page is its description.
  var shortDescription: String {
    switch self {
    case .top100:
      return L.VerbCollection.top100Description
    case .goVerbs:
      return L.VerbCollection.goVerbsDescription
    case .strongPreterite:
      return L.VerbCollection.strongPreteriteDescription
    case .irregularFuture:
      return L.VerbCollection.irregularFutureDescription
    case .irregularParticiple:
      return L.VerbCollection.irregularParticipleDescription
    case .model:
      return ""
    }
  }

  /// Whether the collection's page adds `L.VerbCollection.patternNote`: a pattern list's verbs are
  /// a band's base verbs.
  var isPatternList: Bool {
    switch self {
    case .goVerbs, .strongPreterite, .irregularFuture, .irregularParticiple:
      return true
    case .top100, .model:
      return false
    }
  }

  var systemImageName: String {
    switch self {
    case .top100:
      return "chart.bar.fill"
    case .goVerbs:
      return "g.circle.fill"
    case .strongPreterite:
      return "bolt.fill"
    case .irregularFuture:
      return "arrow.forward.circle.fill"
    case .irregularParticiple:
      return "p.circle.fill"
    case .model:
      return "square.grid.3x3.fill"
    }
  }

  /// `conjugar://list/goVerbs?source=sharedLink`.
  var deeplink: URL? {
    URL.listDeeplink(key: key, source: .sharedLink)
  }

  static let shareSampleCount = 6

  /// What the share button sends: the title, the count, the most frequent verbs, a link that opens
  /// the list for someone who has the app, and the App Store link for someone who does not.
  var shareText: String {
    let verbs = self.verbs
    let sample = verbs.prefix(Self.shareSampleCount).map(\.citationForm)
    let more = verbs.count > sample.count ? " …" : ""
    return L.VerbCollection.shareText(
      title: title,
      verbCount: L.BrowseVerbs.verbCount(count: verbs.count),
      sample: sample.joined(separator: ", ") + more,
      link: deeplink?.absoluteString ?? "",
      appStoreLink: URL.appStore.absoluteString
    )
  }

  /// `viewCollection`: once for each opening of a collection's page or a model's page.
  func signalView(source: AnalyticsSource) {
    Current.analytics.signal(name: .viewCollection, parameters: [
      ParameterKey.collection.rawValue: key,
      ParameterKey.source.rawValue: source.rawValue
    ])
  }
}

nonisolated extension QuizScope {
  /// A full-length, unranked quiz over a collection, in the same sheet as Test Me, titled with the
  /// collection's name. Its `startQuiz` carries the collection's key.
  static func collection(_ collection: VerbCollection, title: String) -> QuizScope {
    QuizScope(
      verbs: collection.infinitives,
      questionCount: fullLength,
      source: .list,
      title: title,
      collectionKey: collection.key
    )
  }
}
