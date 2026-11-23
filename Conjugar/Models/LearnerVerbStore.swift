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
  @ObservationIgnored private let getterSetter: GetterSetter

  init(getterSetter: GetterSetter) {
    self.getterSetter = getterSetter
    record = getterSetter.get(key: LearnerVerbs.storageKey).flatMap(LearnerVerbs.init(json:)) ?? LearnerVerbs()
  }

  var starredVerbs: [VerbMapEntry] {
    entries(record.starred)
  }

  var recentVerbs: [VerbMapEntry] {
    entries(record.recent())
  }

  /// The recent verbs that are not also starred, which My Verbs lists below the starred ones.
  var recentUnstarredVerbs: [VerbMapEntry] {
    entries(record.recent().filter { !record.isStarred($0) })
  }

  var myVerbs: [VerbMapEntry] {
    entries(record.myVerbs)
  }

  func isStarred(_ infinitive: String) -> Bool {
    record.isStarred(infinitive)
  }

  func hasOpened(_ infinitive: String) -> Bool {
    record.hasOpened(infinitive)
  }

  /// How many of the verbs have been opened, a collection's progress. A star alone does not count,
  /// and Clear resets every collection's progress, since it forgets the opens.
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

  private func entries(_ infinitives: [String]) -> [VerbMapEntry] {
    infinitives.compactMap { VerbMap.shared.entry(for: $0) }
  }

  private func save() {
    if let json = record.json {
      getterSetter.set(key: LearnerVerbs.storageKey, value: json)
    }
  }
}
