//
//  PracticeStore.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Observation

/// The app's view of `PracticeRecord` (`Current.practice`): it maps questions and lookups to
/// items, saves each change to the App Group's defaults, and answers in verbs for the review card.
/// It also keeps the last quiz's results, which the Quiz tab shows, and the Speed Round's best.
/// Observable, so Settings' Reset Practice shows once there is something to reset.
@Observable
final class PracticeStore {
  private(set) var record: PracticeRecord
  private(set) var lastResult: LastQuizResult?
  /// The most right answers in one Speed Round, kept on the device and sent nowhere.
  private(set) var speedRoundBest: Int?
  @ObservationIgnored private let getterSetter: GetterSetter
  @ObservationIgnored private let calendar: Calendar

  /// The verb the review card offers, and what to say about it.
  struct CardOffer: Equatable {
    let entry: VerbMapEntry
    /// The verb's key conjugations that are due, in the card's order, which a reveal moves up and
    /// a dismissal snoozes.
    let items: [PracticeItem]
    /// Whole days since a key conjugation of the verb was last looked up or answered.
    let daysSinceActivity: Int?
    /// Whether that was a lookup rather than a quiz answer.
    let wasLookedUp: Bool
  }

  /// `getterSetter` must be the store that holds `LearnerVerbs`, since the first launch with a
  /// practice record migrates the review card's schedules from it.
  init(getterSetter: GetterSetter, calendar: Calendar = .current) {
    self.getterSetter = getterSetter
    self.calendar = calendar
    if let stored = getterSetter.get(key: PracticeRecord.storageKey).flatMap(PracticeRecord.init(json:)) {
      record = stored
    } else {
      record = Self.migrated(from: getterSetter, calendar: calendar)
      save()
    }
    lastResult = getterSetter.get(key: LastQuizResult.storageKey).flatMap(LastQuizResult.init(json:))
    speedRoundBest = getterSetter.get(key: Self.speedRoundBestKey).flatMap { Int($0) }
  }

  static let speedRoundBestKey = "speedRoundBest"

  var isEmpty: Bool {
    record.isEmpty && lastResult == nil && speedRoundBest == nil
  }

  /// A round's results, as they appear: after Ten More, the session's so far.
  func recordResult(_ result: LastQuizResult) {
    lastResult = result
    if let json = result.json {
      getterSetter.set(key: LastQuizResult.storageKey, value: json)
    }
  }

  /// A finished Speed Round's right answers, kept when they beat the best. Returns whether they
  /// did. A round with none right sets no best.
  @discardableResult
  func recordSpeedRound(correctCount: Int) -> Bool {
    guard correctCount > (speedRoundBest ?? 0) else {
      return false
    }
    speedRoundBest = correctCount
    getterSetter.set(key: Self.speedRoundBestKey, value: "\(correctCount)")
    return true
  }

  /// A quiz's final answer to a question: a slip's right second attempt counts as right, since
  /// one letter was all that stood between the learner and the conjugation.
  func recordAnswer(to question: QuizQuestion, isCorrect: Bool, at date: Date = .now) {
    guard let item = PracticeItem.exercised(by: question) else {
      return
    }
    record.recordAnswer(item, isCorrect: isCorrect, at: date, calendar: calendar)
    save()
  }

  /// A verb page was opened. An open from the review card does not reschedule, since the learner
  /// has just reviewed the verb.
  func recordLookup(_ infinitive: String, source: AnalyticsSource, at date: Date = .now) {
    let items = PracticeItem.keyConjugations(of: infinitive)
    guard !items.isEmpty else {
      return
    }
    record.recordLookup(items, at: date, reschedules: source != .reviewCard, calendar: calendar)
    save()
  }

  /// The items due at `date`, the longest overdue first.
  func dueItems(at date: Date = .now) -> [PracticeItem] {
    record.dueItems(at: date)
  }

  /// Whole days from `date` to the next item to fall due, 1 for tomorrow. Nil when nothing in the
  /// record waits.
  func daysUntilNextDue(at date: Date = .now) -> Int? {
    record.nextDue(after: date).flatMap { PracticeRecord.daysBetween(date, and: $0, calendar: calendar) }
  }

  /// The items whose last answer was wrong, the most recently missed first.
  func missedItems() -> [PracticeItem] {
    record.missedItems()
  }

  /// The irregular verb whose key conjugation is longest overdue, with each of its due key
  /// conjugations, since the card shows all four.
  func cardOffer(at date: Date = .now) -> CardOffer? {
    let due = record.dueItems(at: date)
    guard let infinitive = due.lazy.compactMap(\.infinitive).first(where: PracticeItem.isReviewable),
          let entry = VerbMap.shared.entry(for: infinitive) else {
      return nil
    }
    let items = PracticeItem.Key.allCases
      .map { PracticeItem.keyConjugation(infinitive: infinitive, key: $0) }
      .filter(due.contains)
    let entries = PracticeItem.Key.allCases.compactMap { key in
      record.entry(for: .keyConjugation(infinitive: infinitive, key: key))
    }
    let latest = entries.max { ($0.lastActivity ?? .distantPast) < ($1.lastActivity ?? .distantPast) }
    return CardOffer(
      entry: entry,
      items: items,
      daysSinceActivity: latest?.lastActivity.flatMap { PracticeRecord.daysBetween($0, and: date, calendar: calendar) },
      wasLookedUp: latest?.wasLastLookedUp ?? true
    )
  }

  func recordReview(_ offer: CardOffer, at date: Date = .now) {
    record.recordReview(offer.items, at: date, calendar: calendar)
    save()
  }

  func snooze(_ offer: CardOffer, at date: Date = .now) {
    record.snooze(offer.items, at: date, calendar: calendar)
    save()
  }

  /// Settings' Reset Practice, which forgets the last quiz's results and the Speed Round's best
  /// too. The record is saved empty rather than removed, so that the next launch does not migrate
  /// the old schedules again. `GetterSetter` cannot remove a key, so the last result and the best
  /// are saved as empty strings, which read as none.
  func reset() {
    record.reset()
    save()
    lastResult = nil
    getterSetter.set(key: LastQuizResult.storageKey, value: "")
    speedRoundBest = nil
    getterSetter.set(key: Self.speedRoundBestKey, value: "")
  }

  private func save() {
    if let json = record.json {
      getterSetter.set(key: PracticeRecord.storageKey, value: json)
    }
  }

  /// Before the practice record, `LearnerVerbs.Entry.review` kept one review schedule per
  /// irregular verb, and an entry with no schedule, which predates that field, counts as looked up
  /// on its last open. Each irregular verb's schedule becomes its key conjugations' schedule. A
  /// regular verb never had one.
  private static func migrated(from getterSetter: GetterSetter, calendar: Calendar) -> PracticeRecord {
    var record = PracticeRecord()
    guard let json = getterSetter.get(key: LearnerVerbs.storageKey),
          let data = json.data(using: .utf8),
          let legacy = try? JSONDecoder().decode(LegacyLearnerVerbs.self, from: data) else {
      return record
    }
    for entry in legacy.entries.values {
      guard let schedule = entry.review ?? entry.lastOpened.map({ ReviewSchedule.start(at: $0, calendar: calendar) }) else {
        continue
      }
      for item in PracticeItem.keyConjugations(of: entry.infinitive) {
        record.adopt(item, schedule: schedule, lastLookedUp: entry.lastOpened)
      }
    }
    return record
  }

  /// The fields of a `LearnerVerbs` record that the migration reads. Decoding ignores the rest.
  private struct LegacyLearnerVerbs: Decodable {
    struct Entry: Decodable {
      let infinitive: String
      let lastOpened: Date?
      let review: ReviewSchedule?
    }

    let entries: [String: Entry]
  }
}
