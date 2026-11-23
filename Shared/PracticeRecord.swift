//
//  PracticeRecord.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// What one quiz answer exercises, and what the review ladder schedules. A question whose cell is
/// irregular exercises one of its verb's key conjugations, the stem the cell is built on (tenga
/// exercises tengo). A question whose cell is regular exercises a pattern, a tense, a person, and
/// an ending that every verb regular in that cell shares, since a learner who can write hablaba
/// can write cantaba. The app decides which question maps to which item
/// (`PracticeItemMapping.swift`). This file only names items, so that the widget, which has no
/// verb map, can read the record.
nonisolated enum PracticeItem: Hashable, Sendable {
  // Semantic ordering: the order the key conjugations are shown in.
  /// The four key conjugations: tengo · tuve · tendré · tenido.
  enum Key: String, CaseIterable, Sendable {
    case yoPresente = "yo_presente"
    case yoPretérito = "yo_preterito"
    case yoFuturo = "yo_futuro"
    case participio
  }

  /// `infinitive` is bare, as the verb map keys it (arrepentir, not arrepentirse).
  case keyConjugation(infinitive: String, key: Key)
  /// `tenseKey` is the tense's permanent key (`CustomQuiz.key(for:)`), `person` a
  /// `DisplayPersonNumber` raw value, nil for the gerundio and participio, and `ending` ar, er, or
  /// ir.
  case pattern(tenseKey: String, person: String?, ending: String)

  static let endings = ["ar", "er", "ir"]

  /// The item's permanent name in the stored record: `key:tener:yo_presente` or
  /// `pattern:imperfecto_de_indicativo:fs:er`. Changing it would orphan every learner's schedule
  /// for the item.
  var key: String {
    switch self {
    case let .keyConjugation(infinitive, key):
      return [Self.keyConjugationPrefix, infinitive, key.rawValue].joined(separator: Self.separator)
    case let .pattern(tenseKey, person, ending):
      return ([Self.patternPrefix, tenseKey] + (person.map { [$0] } ?? []) + [ending]).joined(separator: Self.separator)
    }
  }

  init?(key: String) {
    let parts = key.components(separatedBy: Self.separator)
    switch parts.first {
    case Self.keyConjugationPrefix:
      guard parts.count == 3, !parts[1].isEmpty, let conjugation = Key(rawValue: parts[2]) else {
        return nil
      }
      self = .keyConjugation(infinitive: parts[1], key: conjugation)
    case Self.patternPrefix:
      guard parts.count == 3 || parts.count == 4, !parts[1].isEmpty, let ending = parts.last, Self.endings.contains(ending) else {
        return nil
      }
      self = .pattern(tenseKey: parts[1], person: parts.count == 4 ? parts[2] : nil, ending: ending)
    default:
      return nil
    }
  }

  /// A key conjugation's verb. Nil for a pattern.
  var infinitive: String? {
    if case let .keyConjugation(infinitive, _) = self {
      return infinitive
    }
    return nil
  }

  private static let separator = ":"
  private static let keyConjugationPrefix = "key"
  private static let patternPrefix = "pattern"
}

/// The learner's practice record: a box and a due date for each item a quiz answer, a lookup, or
/// the review card has touched, and how the last answer went. It is kept in the App Group's shared
/// defaults, so that a widget or a reminder can read it, and it is never sent anywhere.
nonisolated struct PracticeRecord: Codable, Equatable, Sendable {
  // A field added later must be optional. Synthesized decoding ignores a default value and
  // requires the key, so any other field would fail to decode every record written before it,
  // and the learner's practice would silently vanish.
  struct Entry: Codable, Equatable, Sendable {
    var schedule: ReviewSchedule
    var lastAnswered: Date?
    /// Whether the most recent answer was right, which Practice My Mistakes reads.
    var lastAnswerWasRight: Bool?
    var lastLookedUp: Date?

    /// The later of the last answer and the last lookup.
    var lastActivity: Date? {
      [lastAnswered, lastLookedUp].compactMap { $0 }.max()
    }

    /// Whether the last thing to touch the item was a lookup rather than an answer.
    var wasLastLookedUp: Bool {
      guard let lastLookedUp else {
        return false
      }
      return lastAnswered.map { lastLookedUp >= $0 } ?? true
    }
  }

  static let storageKey = "practiceRecord"

  /// Keyed by `PracticeItem.key`.
  private(set) var entries: [String: Entry] = [:]

  init() {}

  init?(json: String) {
    guard
      let data = json.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(PracticeRecord.self, from: data)
    else {
      return nil
    }
    self = decoded
  }

  var json: String? {
    guard let data = try? JSONEncoder().encode(self) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  var isEmpty: Bool {
    entries.isEmpty
  }

  func entry(for item: PracticeItem) -> Entry? {
    entries[item.key]
  }

  /// A quiz's answer, recorded as it is given, so that a quiz quit after six questions has still
  /// practiced six.
  mutating func recordAnswer(_ item: PracticeItem, isCorrect: Bool, at date: Date, calendar: Calendar = .current) {
    var entry = entries[item.key] ?? Entry(schedule: .new(at: date))
    entry.schedule = entry.schedule.answered(correctly: isCorrect, at: date, calendar: calendar)
    entry.lastAnswered = date
    entry.lastAnswerWasRight = isCorrect
    entries[item.key] = entry
  }

  /// A lookup puts the items in the first box, or back there: looking a verb up again suggests
  /// it was forgotten, Leitner's wrong answer. With `reschedules` false, for an open from the
  /// review card, which the learner has just reviewed, only an item not yet in the record enters.
  mutating func recordLookup(_ items: [PracticeItem], at date: Date, reschedules: Bool = true, calendar: Calendar = .current) {
    for item in items {
      var entry = entries[item.key] ?? Entry(schedule: .start(at: date, calendar: calendar))
      if reschedules {
        entry.schedule = .start(at: date, calendar: calendar)
      }
      entry.lastLookedUp = date
      entries[item.key] = entry
    }
  }

  /// The review card's conjugations were revealed, which moves each due item up a box. An item
  /// not yet due keeps its place.
  mutating func recordReview(_ items: [PracticeItem], at date: Date, calendar: Calendar = .current) {
    updateDue(items, at: date) { $0.reviewed(at: date, calendar: calendar) }
  }

  /// The review card was dismissed before its conjugations were revealed, so each due item keeps
  /// its box and returns tomorrow.
  mutating func snooze(_ items: [PracticeItem], at date: Date, calendar: Calendar = .current) {
    updateDue(items, at: date) { $0.snoozed(at: date, calendar: calendar) }
  }

  /// The items due at `date`, the longest overdue first. Equal due dates fall back to the key, so
  /// the order never depends on the dictionary's.
  func dueItems(at date: Date) -> [PracticeItem] {
    let due: [(key: String, due: Date)] = entries.compactMap { key, entry in
      entry.schedule.isDue(at: date) ? (key, entry.schedule.due) : nil
    }
    return due
      .sorted { lhs, rhs in
        lhs.due != rhs.due ? lhs.due < rhs.due : lhs.key < rhs.key
      }
      .compactMap { PracticeItem(key: $0.key) }
  }

  /// The items whose most recent answer was wrong, the most recently missed first. An item leaves
  /// the list once answered right.
  func missedItems() -> [PracticeItem] {
    let missed: [(key: String, answered: Date)] = entries.compactMap { key, entry in
      guard entry.lastAnswerWasRight == false, let answered = entry.lastAnswered else {
        return nil
      }
      return (key, answered)
    }
    return missed
      .sorted { lhs, rhs in
        lhs.answered != rhs.answered ? lhs.answered > rhs.answered : lhs.key < rhs.key
      }
      .compactMap { PracticeItem(key: $0.key) }
  }

  /// The earliest due date after `date`, for saying when a review will next have something to ask.
  func nextDue(after date: Date) -> Date? {
    entries.values.map(\.schedule.due).filter { $0 > date }.min()
  }

  /// Whole days from `earlier` to `date`, counted by the calendar: 1 for yesterday.
  static func daysBetween(_ earlier: Date, and date: Date, calendar: Calendar = .current) -> Int? {
    calendar.dateComponents([.day], from: calendar.startOfDay(for: earlier), to: calendar.startOfDay(for: date)).day
  }

  mutating func reset() {
    entries = [:]
  }

  /// Folds in a schedule from before the record existed, which only the migration uses.
  mutating func adopt(_ item: PracticeItem, schedule: ReviewSchedule, lastLookedUp: Date?) {
    entries[item.key] = Entry(schedule: schedule, lastLookedUp: lastLookedUp)
  }

  private mutating func updateDue(_ items: [PracticeItem], at date: Date, _ change: (ReviewSchedule) -> ReviewSchedule) {
    for item in items {
      guard var entry = entries[item.key], entry.schedule.isDue(at: date) else {
        continue
      }
      entry.schedule = change(entry.schedule)
      entries[item.key] = entry
    }
  }
}
