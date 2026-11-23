//
//  LearnerVerbs.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The learner's own verbs: each verb opened, when and how often, and each verb starred (browse
/// plan, Phase 12, ported from Konjugieren). It is kept in the App Group's shared defaults, so the
/// widget extension can read what the app writes, and it names verbs by infinitive, as
/// `verbModelMap.xml` keys them (a reflexive-only verb by its bare infinitive), because the widget
/// has no verb map. Phases 13 to 16 of the browse plan read it, and so will the pedagogy plan.
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

  mutating func recordOpen(_ infinitive: String, at date: Date) {
    var entry = entries[infinitive] ?? Entry(infinitive: infinitive)
    entry.firstOpened = entry.firstOpened ?? date
    entry.lastOpened = date
    entry.openCount += 1
    entries[infinitive] = entry
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

  /// Forgets every verb opened. Stars stay.
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

  private mutating func store(_ entry: Entry) {
    entries[entry.infinitive] = entry.starred == nil && entry.lastOpened == nil ? nil : entry
  }
}
