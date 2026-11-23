//
//  LearnerVerbs.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The learner's own verbs: each verb opened, when and how often, each verb starred, and when each
/// irregular verb is due on the review card. It is kept in the App Group's shared defaults, so the
/// widget extension can read what the app writes, and it names verbs by infinitive, as
/// `verbModelMap.xml` keys them (a reflexive-only verb by its bare infinitive), because the widget
/// has no verb map.
nonisolated struct LearnerVerbs: Codable, Equatable, Sendable {
  // A field added later must be optional. Synthesized decoding ignores a default value and
  // requires the key, so any other field would fail to decode every record written before it,
  // and the learner's verbs would silently vanish. `LearnerVerbsTests` pins this.
  struct Entry: Codable, Equatable, Sendable {
    let infinitive: String
    var firstOpened: Date?
    var lastOpened: Date?
    var openCount = 0
    var starred: Date?
    /// When the verb is due on the review card. Nil for a verb never scheduled: a regular verb, a
    /// verb only starred, or an entry written before reviews existed that `LearnerVerbStore` has
    /// not yet scheduled.
    var review: ReviewSchedule?

    var isStarred: Bool {
      starred != nil
    }
  }

  static let storageKey = "learnerVerbs"
  static let recentLimit = 20

  private(set) var entries: [String: Entry] = [:]

  init() {}

  init?(json: String) {
    guard
      let data = json.data(using: .utf8),
      let decoded = try? JSONDecoder().decode(LearnerVerbs.self, from: data)
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

  func isStarred(_ infinitive: String) -> Bool {
    entries[infinitive]?.isStarred ?? false
  }

  /// Whether the verb has been opened since its opens were last forgotten.
  func hasOpened(_ infinitive: String) -> Bool {
    entries[infinitive]?.lastOpened != nil
  }

  /// Starred verbs, the most recently starred first.
  var starred: [String] {
    newestFirst(by: \.starred)
  }

  /// Opened verbs, the most recently opened first.
  func recent(limit: Int = recentLimit) -> [String] {
    Array(newestFirst(by: \.lastOpened).prefix(limit))
  }

  /// What My Verbs holds: the starred verbs, then the recent ones not starred.
  var myVerbs: [String] {
    let starred = self.starred
    let starredSet = Set(starred)
    return starred + recent().filter { !starredSet.contains($0) }
  }

  /// The verbs due on the review card, the longest overdue first, ties broken by infinitive.
  func dueForReview(at date: Date) -> [String] {
    let due: [(infinitive: String, due: Date)] = entries.values.compactMap { entry in
      guard let review = entry.review, review.isDue(at: date) else {
        return nil
      }
      return (entry.infinitive, review.due)
    }
    return due
      .sorted { lhs, rhs in
        lhs.due != rhs.due ? lhs.due < rhs.due : lhs.infinitive < rhs.infinitive
      }
      .map(\.infinitive)
  }

  /// Whole days from the verb's last open to `date`, counted by the calendar: 1 for yesterday.
  func daysSinceOpened(_ infinitive: String, at date: Date, calendar: Calendar = .current) -> Int? {
    guard let lastOpened = entries[infinitive]?.lastOpened else {
      return nil
    }
    return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastOpened), to: calendar.startOfDay(for: date)).day
  }

  /// `schedulesReview` puts the verb in the review ladder's first box, or back there, since
  /// looking a verb up again suggests it was forgotten. The caller passes false for a regular
  /// verb, which is never scheduled, and for an open from the review card itself, whose reveal
  /// has just scheduled the verb. False leaves any schedule as it was.
  mutating func recordOpen(_ infinitive: String, at date: Date, schedulesReview: Bool = false, calendar: Calendar = .current) {
    var entry = entries[infinitive] ?? Entry(infinitive: infinitive)
    entry.firstOpened = entry.firstOpened ?? date
    entry.lastOpened = date
    entry.openCount += 1
    if schedulesReview {
      entry.review = .lookedUp(at: date, calendar: calendar)
    }
    entries[infinitive] = entry
  }

  mutating func recordReveal(_ infinitive: String, at date: Date, calendar: Calendar = .current) {
    updateReview(of: infinitive) { $0.revealed(at: date, calendar: calendar) }
  }

  mutating func recordDismissal(_ infinitive: String, at date: Date, calendar: Calendar = .current) {
    updateReview(of: infinitive) { $0.dismissed(at: date, calendar: calendar) }
  }

  /// Schedules each verb opened but never scheduled that `isReviewable` accepts, as looked up on
  /// its last open. A record written before reviews existed thereby offers a card on the first
  /// day, without a migration. Returns whether anything changed. A regular verb stays unscheduled
  /// however often this runs.
  mutating func scheduleUnscheduledReviews(where isReviewable: (String) -> Bool, calendar: Calendar = .current) -> Bool {
    var changed = false
    for (infinitive, entry) in entries {
      guard entry.review == nil, let lastOpened = entry.lastOpened, isReviewable(infinitive) else {
        continue
      }
      var scheduled = entry
      scheduled.review = .lookedUp(at: lastOpened, calendar: calendar)
      entries[infinitive] = scheduled
      changed = true
    }
    return changed
  }

  mutating func setStarred(_ isStarred: Bool, infinitive: String, at date: Date) {
    var entry = entries[infinitive] ?? Entry(infinitive: infinitive)
    entry.starred = isStarred ? (entry.starred ?? date) : nil
    store(entry)
  }

  /// Forgets the verb: its star and its opens. Unstarring alone would move an opened verb from
  /// the starred verbs to the recent ones, and a verb deleted from My Verbs should leave it.
  mutating func remove(_ infinitive: String) {
    entries[infinitive] = nil
  }

  /// Forgets every verb opened, and with the opens their reviews. Stars stay.
  mutating func clearRecents() {
    for (infinitive, entry) in entries {
      store(Entry(infinitive: infinitive, starred: entry.starred))
    }
  }

  /// The infinitives of the entries that have the date, newest first. Equal dates fall back to
  /// the infinitive, so the order never depends on the dictionary's.
  private func newestFirst(by date: KeyPath<Entry, Date?>) -> [String] {
    let dated: [(infinitive: String, date: Date)] = entries.values.compactMap { entry in
      guard let date = entry[keyPath: date] else {
        return nil
      }
      return (entry.infinitive, date)
    }
    return dated
      .sorted { lhs, rhs in
        lhs.date != rhs.date ? lhs.date > rhs.date : lhs.infinitive < rhs.infinitive
      }
      .map(\.infinitive)
  }

  private mutating func updateReview(of infinitive: String, _ change: (ReviewSchedule) -> ReviewSchedule) {
    guard var entry = entries[infinitive], let review = entry.review else {
      return
    }
    entry.review = change(review)
    entries[infinitive] = entry
  }

  private mutating func store(_ entry: Entry) {
    entries[entry.infinitive] = entry.starred == nil && entry.lastOpened == nil ? nil : entry
  }
}
