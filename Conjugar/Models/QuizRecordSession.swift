//
//  QuizRecordSession.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A session drawn from the practice record rather than from a level's tenses: Review, of
/// whatever is due, and Practice My Mistakes, of what was last answered wrongly.
nonisolated enum QuizRecordSession: CaseIterable, Sendable {
  case review
  case mistakes

  /// The record's items for the session, in the order it asks them: the most overdue first for
  /// Review, the most recently missed first for My Mistakes.
  @MainActor
  func items(from practice: PracticeStore, at date: Date = .now) -> [PracticeItem] {
    switch self {
    case .review:
      return practice.dueItems(at: date)
    case .mistakes:
      return practice.missedItems()
    }
  }

  var title: String {
    switch self {
    case .review:
      return L.PracticeSession.review
    case .mistakes:
      return L.PracticeSession.mistakes
    }
  }

  var source: AnalyticsSource {
    switch self {
    case .review:
      return .review
    case .mistakes:
      return .mistakes
    }
  }
}

nonisolated extension QuizScope {
  /// Review or My Mistakes, from the Quiz tab: up to a round's length of items, then Ten More
  /// while any remain unasked. Never ranked, and mixing in nothing.
  static func recordSession(_ session: QuizRecordSession) -> QuizScope {
    QuizScope(verbs: nil, questionCount: roundLength, source: session.source, recordSession: session)
  }
}

nonisolated extension QuizDraw {
  /// Whether a record session can ask the item: a key conjugation of a verb in the map with an
  /// irregular cell built on it that the settings allow, or a pattern whose cell this version can
  /// read and the settings allow. Neither the level's tenses nor its band hold a session back,
  /// since the learner practiced or looked up each item.
  static func canAsk(_ item: PracticeItem, asks: (ConjugationCell) -> Bool) -> Bool {
    switch item {
    case let .keyConjugation(infinitive, key):
      return VerbMap.shared.entry(for: infinitive) != nil
        && PracticeItem.irregularCells(of: infinitive, builtOn: key).contains(where: asks)
    case .pattern:
      guard let cell = item.cell, item.ending != nil else {
        return false
      }
      return asks(cell)
    }
  }

  /// A round of a Review or My Mistakes session: a question for each of the first `limit` items
  /// that can be asked. A key conjugation asks the first irregular cell built on it that the
  /// settings allow, its own cell first, so that pedir's yo pretérito is asked as pidió; a pattern
  /// asks its cell of a regular verb of its ending from the learner's band. Items in `excluded`,
  /// keys the session has already asked, are skipped, since a mistake missed again would
  /// otherwise come straight back in Ten More.
  ///
  /// A verb's key conjugations sit together, in the order the verb page shows them, at the place
  /// of the first one drawn, so that a review of tener reads tengo · tuve · tendré.
  static func sessionQuestions(
    for items: [PracticeItem],
    band frequencyBand: FrequencyBand?,
    asks: (ConjugationCell) -> Bool,
    excluded: Set<String> = [],
    limit: Int = QuizScope.roundLength,
    using generator: inout some RandomNumberGenerator
  ) -> [QuizQuestion] {
    let available = items.filter { !excluded.contains($0.key) }
    let drawn = recordQuestions(for: available, keyConjugationBand: nil, patternBand: frequencyBand, asks: asks, limit: limit, using: &generator)
    var groupOrder: [String] = []
    var groups: [String: [(item: PracticeItem, question: QuizQuestion)]] = [:]
    for entry in drawn {
      let groupKey = entry.item.infinitive.map { "key:\($0)" } ?? entry.item.key
      if groups[groupKey] == nil {
        groupOrder.append(groupKey)
      }
      groups[groupKey, default: []].append(entry)
    }
    return groupOrder.flatMap { groupKey in
      (groups[groupKey] ?? [])
        .sorted { keyOrder($0.item) < keyOrder($1.item) }
        .map(\.question)
    }
  }

  private static func keyOrder(_ item: PracticeItem) -> Int {
    guard case let .keyConjugation(_, key) = item else {
      return 0
    }
    return PracticeItem.Key.allCases.firstIndex(of: key) ?? 0
  }
}
