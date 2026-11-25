//
//  LearnerVerbs.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The learner's own verbs: each verb opened, when and how often, and each verb starred. The review
/// card's schedule is the practice record's (`PracticeRecord`). It names verbs by infinitive, as
/// `verbModelMap.xml` keys them (a reflexive-only verb by its bare infinitive). It is kept in the
/// App Group's defaults beside the practice record, but the widget extension never reads it: the
/// app hands My Verbs to `WidgetSnapshotWriter`, and the widget reads the snapshot.
///
/// Two things are kept apart. A verb is in My Verbs while it is starred or recently opened
/// (`starred`, `lastOpened`), which Clear and a swipe forget. A verb counts toward a collection
/// once it has ever been opened (`firstOpened`), which only Settings' Reset Practice forgets.
nonisolated struct LearnerVerbs: Codable, Equatable, Sendable {
  // A field added later must be optional. Synthesized decoding ignores a default value and
  // requires the key, so any other field would fail to decode every record that the build before
  // an app upgrade wrote, and the learner's verbs would silently vanish. `LearnerVerbsTests` pins
  // this.
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
  /// Where `LearnerVerbStore` copies a stored record that fails to decode, before anything
  /// overwrites it.
  static let unreadableKey = "learnerVerbsUnreadable"
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

  /// Whether the verb has ever been opened, a collection's progress. Clear and a swipe leave this
  /// alone; only `forgetOpenHistory()` forgets it.
  func hasOpened(_ infinitive: String) -> Bool {
    entries[infinitive]?.firstOpened != nil
  }

  /// Whether any verb counts as ever opened, so that Settings offers Reset Practice.
  var hasOpenHistory: Bool {
    entries.values.contains { $0.firstOpened != nil }
  }

  /// Starred verbs, the most recently starred first.
  var starred: [String] {
    newestFirst(by: \.starred)
  }

  /// The last `recentLimit` verbs opened, starred or not, the most recently opened first: the
  /// search field's recents.
  var recent: [String] {
    Array(newestFirst(by: \.lastOpened).prefix(Self.recentLimit))
  }

  /// The last `recentLimit` verbs opened that are not starred, the most recently opened first: My
  /// Verbs' Recent. The starred verbs are left out before the limit is taken, so that a list with
  /// many starred opens still shows twenty.
  var recentUnstarred: [String] {
    Array(newestFirst(by: \.lastOpened).filter { !isStarred($0) }.prefix(Self.recentLimit))
  }

  /// What My Verbs holds: the starred verbs, then the recent ones not starred.
  var myVerbs: [String] {
    starred + recentUnstarred
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

  /// Takes the verb out of My Verbs: forgets its star and its last open. Unstarring alone would
  /// move an opened verb from the starred verbs to the recent ones, and a verb removed from My
  /// Verbs should leave it. Its first open stays, so collections still count it.
  mutating func remove(_ infinitive: String) {
    guard var entry = entries[infinitive] else {
      return
    }
    entry.starred = nil
    entry.lastOpened = nil
    store(entry)
  }

  /// Empties My Verbs' Recent: forgets every verb's last open. Stars stay, and so do first opens,
  /// so collections still count every verb opened.
  mutating func clearRecents() {
    for var entry in entries.values {
      entry.lastOpened = nil
      store(entry)
    }
  }

  /// Forgets which verbs were ever opened, and how often, for Settings' Reset Practice. My Verbs
  /// keeps its starred and recent verbs.
  mutating func forgetOpenHistory() {
    for var entry in entries.values {
      entry.firstOpened = nil
      entry.openCount = 0
      store(entry)
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

  /// Keeps the entry while it says anything: a star, a last open, or a first open. An entry with
  /// only its first open is in neither Starred nor Recent, and counts toward collections.
  private mutating func store(_ entry: Entry) {
    let isEmpty = entry.starred == nil && entry.lastOpened == nil && entry.firstOpened == nil
    entries[entry.infinitive] = isEmpty ? nil : entry
  }
}
