//
//  LearnerVerbStore.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Observation

/// The app's view of `LearnerVerbs` (`Current.learnerVerbs`): it records opens and stars, saves
/// each change, and answers in verb-map entries rather than infinitives. A verb no longer in the
/// verb map is skipped. Observable, so the verb list and the star redraw when the record changes.
@Observable
final class LearnerVerbStore {
  private(set) var record: LearnerVerbs
  /// The record's lists as verb-map entries, derived once per change rather than on every read:
  /// the Verbs tab's body reads the recents several times a render, and each derivation sorts the
  /// whole record.
  private(set) var starredVerbs: [VerbMapEntry] = []
  private(set) var recentVerbs: [VerbMapEntry] = []
  /// The recent verbs that are not also starred, which My Verbs lists below the starred ones.
  private(set) var recentUnstarredVerbs: [VerbMapEntry] = []
  private(set) var myVerbs: [VerbMapEntry] = []
  @ObservationIgnored private let getterSetter: GetterSetter

  /// A stored record that fails to decode is copied to `LearnerVerbs.unreadableKey` before the
  /// store starts empty, so that the first save does not destroy the only copy of it.
  init(getterSetter: GetterSetter) {
    self.getterSetter = getterSetter
    let stored = getterSetter.get(key: LearnerVerbs.storageKey)
    if let decoded = stored.flatMap(LearnerVerbs.init(json:)) {
      record = decoded
    } else {
      getterSetter.backUpUnreadable(stored, to: LearnerVerbs.unreadableKey)
      record = LearnerVerbs()
    }
    deriveLists()
  }

  func isStarred(_ infinitive: String) -> Bool {
    record.isStarred(infinitive)
  }

  func hasOpened(_ infinitive: String) -> Bool {
    record.hasOpened(infinitive)
  }

  /// How many of the verbs have ever been opened, a collection's progress. A star alone does not
  /// count. Clear and a swipe in My Verbs leave it; Reset Practice forgets it.
  func openedCount(of entries: [VerbMapEntry]) -> Int {
    entries.count { record.hasOpened($0.infinitive) }
  }

  func recordOpen(_ infinitive: String, at date: Date = .now) {
    record.recordOpen(infinitive, at: date)
    save()
  }

  /// Returns whether the verb is now starred.
  @discardableResult
  func toggleStar(_ infinitive: String, at date: Date = .now) -> Bool {
    let isStarred = !record.isStarred(infinitive)
    record.setStarred(isStarred, infinitive: infinitive, at: date)
    save()
    return isStarred
  }

  func remove(_ infinitive: String) {
    record.remove(infinitive)
    save()
  }

  func clearRecents() {
    record.clearRecents()
    save()
  }

  var hasOpenHistory: Bool {
    record.hasOpenHistory
  }

  func forgetOpenHistory() {
    record.forgetOpenHistory()
    save()
  }

  private func entries(_ infinitives: [String]) -> [VerbMapEntry] {
    infinitives.compactMap { VerbMap.shared.entry(for: $0) }
  }

  private func deriveLists() {
    starredVerbs = entries(record.starred)
    recentUnstarredVerbs = entries(record.recentUnstarred)
    recentVerbs = entries(record.recent)
    myVerbs = starredVerbs + recentUnstarredVerbs
  }

  /// Every change to the record comes through here, so the derived lists never lag it.
  private func save() {
    deriveLists()
    if let json = record.json {
      getterSetter.set(key: LearnerVerbs.storageKey, value: json)
    }
  }
}
