//
//  LearnerVerbStore.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Observation

/// The app's view of `LearnerVerbs` (`Current.learnerVerbs`): it records opens, stars, and the
/// review card's reveals and dismissals, saves each change, and answers in verb-map entries rather
/// than infinitives. A verb no longer in the verb map is skipped. It decides which verbs the review
/// card schedules, which the record cannot, having no verb map. Observable, so the verb list and
/// the star redraw when the record changes.
@Observable
final class LearnerVerbStore {
  private(set) var record: LearnerVerbs
  @ObservationIgnored private let getterSetter: GetterSetter

  init(getterSetter: GetterSetter) {
    self.getterSetter = getterSetter
    record = getterSetter.get(key: LearnerVerbs.storageKey).flatMap(LearnerVerbs.init(json:)) ?? LearnerVerbs()
    if record.scheduleUnscheduledReviews(where: Self.isReviewable) {
      save()
    }
  }

  /// Whether the review card offers the verb: only an irregular verb, counted as the verb page's
  /// pill counts it, so the orthographic classes (buscar, busqué) too.
  static func isReviewable(_ infinitive: String) -> Bool {
    VerbMap.shared.entry(for: infinitive).map(VerbDraw.isIrregular) ?? false
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

  /// The verb the review card offers: the longest overdue.
  func verbDueForReview(at date: Date = .now) -> VerbMapEntry? {
    record.dueForReview(at: date).lazy
      .filter(Self.isReviewable)
      .compactMap { VerbMap.shared.entry(for: $0) }
      .first
  }

  func daysSinceOpened(_ infinitive: String, at date: Date = .now) -> Int? {
    record.daysSinceOpened(infinitive, at: date)
  }

  /// An open by any route but the review card puts an irregular verb in the first box, or back
  /// there. An open from the card leaves the schedule its reveal just set.
  func recordOpen(_ infinitive: String, source: AnalyticsSource, at date: Date = .now) {
    let schedulesReview = source != .reviewCard && Self.isReviewable(infinitive)
    record.recordOpen(infinitive, at: date, schedulesReview: schedulesReview)
    save()
  }

  func recordReveal(_ infinitive: String, at date: Date = .now) {
    record.recordReveal(infinitive, at: date)
    save()
  }

  func recordDismissal(_ infinitive: String, at date: Date = .now) {
    record.recordDismissal(infinitive, at: date)
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
