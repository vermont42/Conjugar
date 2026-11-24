//
//  SpeedRound.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The Speed Round: sixty seconds of questions on what the practice record says is mastered,
/// counting right answers. It is speed for material already accurate, and the one place where the
/// quiz's clock counts.
///
/// The round leaves the record untouched. A miss does not send an item down the ladder, since a
/// speed error is often haste, and a record that counted only a timed round's hits would be
/// one-sided.
nonisolated enum SpeedRound {
  /// Seconds in a round.
  static let duration = 60

  /// The round opens once this many items are mastered, and repeats them as a round needs.
  static let minimumMasteredCount = 5

  /// Questions drawn at a time. The round draws more as it reaches the last of them, since nobody
  /// knows in advance how many a learner answers in a minute.
  static let batchSize = 10

  /// The clock turns red, and VoiceOver hears how much time is left, at this many seconds.
  static let warningSecondsLeft = 10

  /// The mastered items a round can ask in the learner's tú or vos and region, in key order, so
  /// that a seeded draw is the same in every process. The level does not hold an item back, since a
  /// mastered item stays mastered when the level changes.
  static func masteredItems(in record: PracticeRecord, asks: (ConjugationCell) -> Bool) -> [PracticeItem] {
    record.entries
      .filter { $0.value.schedule.box >= MasteryState.masteredBox }
      .keys
      .sorted()
      .compactMap(PracticeItem.init(key:))
      .filter { QuizDraw.canAsk($0, asks: asks) }
  }
}

nonisolated extension QuizScope {
  /// The Speed Round, from the Quiz tab's Exercises. Never ranked, never continued, and mixing in
  /// nothing.
  static func speedRound() -> QuizScope {
    QuizScope(verbs: nil, questionCount: SpeedRound.batchSize, source: .speedRound, isSpeedRound: true)
  }
}

nonisolated extension QuizDraw {
  /// `count` questions on mastered items, each item asked once before any is asked again, and never
  /// the same item twice running, `previous` included, which is the last question of the batch
  /// before.
  ///
  /// A key conjugation asks any irregular cell built on it that the level asks (`levelAsks`), as
  /// `PracticeItem.exercised(by:)` credits them, and the first irregular cell built on it that the
  /// settings allow, its own cell where that is irregular: mastered tuve asks tuvieron where the
  /// level asks the pretérito, and tuve itself at Beginner, which asks none. A pattern asks its cell
  /// of a regular verb of its ending from `band`, a fresh one each time it comes back.
  static func speedRoundQuestions(
    for items: [PracticeItem],
    levelAsks: (ConjugationCell) -> Bool,
    allows: (ConjugationCell) -> Bool,
    band frequencyBand: FrequencyBand?,
    count: Int,
    after previous: PracticeItem? = nil,
    using generator: inout some RandomNumberGenerator
  ) -> [QuizQuestion] {
    var regularVerbsByEnding: [String: [String]] = [:]
    var askable = items
    var drawn: [QuizQuestion] = []
    var last = previous

    func question(for item: PracticeItem) -> QuizQuestion? {
      switch item {
      case let .keyConjugation(infinitive, key):
        let cells = speedRoundCells(of: infinitive, builtOn: key, levelAsks: levelAsks, allows: allows)
        guard let cell = cells.randomElement(using: &generator) else {
          return nil
        }
        return QuizQuestion(infinitive, cell.tense, cell.personNumber)
      case .pattern:
        guard let cell = item.cell, let ending = item.ending, allows(cell) else {
          return nil
        }
        let candidates = regularVerbsByEnding[ending.practiceKey] ?? verbs(in: frequencyBand)
          .filter { !VerbDraw.isIrregular($0) && RegularRoot(infinitive: $0.infinitive) == ending }
          .map(\.infinitive)
        regularVerbsByEnding[ending.practiceKey] = candidates
        for _ in 0..<attemptsPerSpeedRoundPattern {
          guard let verb = candidates.randomElement(using: &generator) else {
            return nil
          }
          if isIrregular(verb, in: cell) == false {
            return QuizQuestion(verb, cell.tense, cell.personNumber)
          }
        }
        return nil
      }
    }

    while drawn.count < count, !askable.isEmpty {
      var cycle = askable.shuffled(using: &generator)
      if cycle.count > 1, let last, cycle.first == last {
        cycle.swapAt(0, Int.random(in: 1..<cycle.count, using: &generator))
      }
      for item in cycle where drawn.count < count {
        guard let question = question(for: item) else {
          askable.removeAll { $0 == item }
          continue
        }
        drawn.append(question)
        last = item
      }
    }
    return drawn
  }

  /// The cells a mastered key conjugation can ask: the first irregular cell built on it that the
  /// settings allow, then every other irregular cell built on it that the level asks.
  static func speedRoundCells(
    of infinitive: String,
    builtOn key: PracticeItem.Key,
    levelAsks: (ConjugationCell) -> Bool,
    allows: (ConjugationCell) -> Bool
  ) -> [ConjugationCell] {
    guard VerbMap.shared.entry(for: infinitive) != nil else {
      return []
    }
    let built = Array(PracticeItem.irregularCells(of: infinitive, builtOn: key)).filter(allows)
    guard let first = built.first else {
      return []
    }
    return [first] + built.dropFirst().filter(levelAsks)
  }

  private static let attemptsPerSpeedRoundPattern = 8
}
