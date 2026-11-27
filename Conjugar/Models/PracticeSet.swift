//
//  PracticeSet.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A custom quiz shared as a link or a QR code, so that a teacher can hand a class one practice
/// set without accounts or a server. Opening one shows the set with Start rather than starting a
/// quiz unasked.
nonisolated struct PracticeSet: Equatable, Sendable {
  var custom: CustomQuiz

  /// The sharer's level, carried only while a part of the choice is left to the level, so that
  /// everyone who opens the set is asked the same tenses and verbs.
  var level: QuizLevel?

  init(custom: CustomQuiz, level: QuizLevel?) {
    self.custom = custom
    self.level = level
  }

  /// The set a learner shares from the Quiz tab. Their My Verbs are their own, so the link carries
  /// the verbs themselves, the first `maximumListCount` of them. An empty My Verbs leaves the
  /// verbs to the level.
  init(sharing custom: CustomQuiz, level: QuizLevel, myVerbs: [String]) {
    var shared = custom
    if custom.verbSet == .myVerbs {
      shared.verbSet = QuizVerbSet(infinitives: Array(myVerbs.prefix(Self.maximumListCount)))
    }
    self.custom = shared
    self.level = shared.tenses.isEmpty || shared.verbSet == nil ? level : nil
  }

  /// Keeps a projected QR code coarse enough to scan from the back of a classroom.
  static let maximumListCount = 100

  /// `conjugar://quiz/set?tenses=preterito&verbs=goVerbs&source=sharedLink`. Nil for any other
  /// link, and for a `quiz/set` link that names no tense or verb set this version knows. A link
  /// naming My Verbs would ask the opener's own, which no sharer means, so that part is dropped.
  init?(url: URL) {
    guard
      url.isDeeplink,
      url.deeplinkRoute == URL.quizHost,
      url.deeplinkTarget == URL.practiceSetTarget,
      let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery,
      var custom = CustomQuiz(rawValue: query)
    else {
      return nil
    }
    if custom.verbSet == .myVerbs {
      custom.verbSet = nil
    }
    guard !custom.isEmpty else {
      return nil
    }
    self.custom = custom
    level = url.deeplinkQueryValue(named: URL.levelQueryName).flatMap(QuizLevel.init(rawValue:))
  }

  /// `source` is `sharedLink` in shared text and `qrCode` in a QR code, so that `startQuiz` can
  /// tell which reached the learner.
  func deeplink(source: AnalyticsSource) -> URL? {
    URL.practiceSetDeeplink(custom: custom, level: level, source: source)
  }

  /// What a quiz over this set asks: the custom quiz's rules, at the set's level, a round of ten
  /// and then Ten More, never ranked. `title` is the quiz sheet's.
  func scope(source: AnalyticsSource, title: String? = nil) -> QuizScope {
    QuizScope(
      kind: .practiceSet,
      verbs: custom.verbSet?.infinitives(myVerbs: []),
      questionCount: QuizScope.roundLength,
      source: source,
      title: title,
      collectionKey: custom.verbSet?.collectionKey,
      custom: custom,
      level: level
    )
  }

  static let linkMethod = "link"
  static let qrCodeMethod = "qrCode"
}

extension PracticeSet {
  /// The tenses on one line and the verbs on the next, for the share text and the QR code's
  /// caption. One line read ambiguously, since a list's title holds a separator of its own.
  func summary(levelFallback: QuizLevel) -> String {
    "\(tensesSummary(levelFallback: levelFallback))\n\(verbsSummary(levelFallback: levelFallback))"
  }

  /// The chosen tenses' Spanish names, or the level that sets them.
  func tensesSummary(levelFallback: QuizLevel) -> String {
    custom.tenses.isEmpty
      ? "\(L.PracticeSet.byLevel): \((level ?? levelFallback).localizedName)"
      : custom.orderedTenses.map(\.titleCaseName).joined(separator: ", ")
  }

  func verbsSummary(levelFallback: QuizLevel) -> String {
    custom.verbSet?.title ?? "\(L.PracticeSet.byLevel): \(CustomQuiz.levelVerbsDescription(level ?? levelFallback))"
  }

  /// The summary, a link that opens the set for someone who has the app, and the App Store link
  /// for someone who does not. There is no web domain, so there is no universal link.
  func shareText(levelFallback: QuizLevel) -> String {
    L.PracticeSet.shareText(
      summary: summary(levelFallback: levelFallback),
      link: deeplink(source: .sharedLink)?.absoluteString ?? "",
      appStoreLink: URL.appStore.absoluteString
    )
  }

  /// Says how the set was shared and what kind of choice it is, never which tenses or verbs.
  func signalShare(method: String) {
    Current.analytics.signal(name: .tapSharePracticeSet, parameters: [
      ParameterKey.customChoice.rawValue: custom.choiceParameter,
      ParameterKey.method.rawValue: method
    ])
  }
}

/// A practice-set link to show, from `AppRouter.handle(url:)`. A nil set is a `quiz/set` link that
/// names nothing, which shows a sheet saying so rather than doing nothing.
struct PracticeSetRequest: Identifiable, Equatable {
  let id = UUID()
  let practiceSet: PracticeSet?
  let source: AnalyticsSource
}
