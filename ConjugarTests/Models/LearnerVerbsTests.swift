//
//  LearnerVerbsTests.swift
//  ConjugarTests
//
//  The learner's record of verbs opened and starred, and the app's store over it. MainActor
//  because the store is.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct LearnerVerbsTests {
  private let day: TimeInterval = 86_400

  private func date(_ days: Double) -> Date {
    Date(timeIntervalSinceReferenceDate: days * day)
  }

  @Test func recordOpenKeepsFirstAndLastDatesAndCount() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ir", at: date(3))

    let entry = record.entries["ir"]
    #expect(entry?.firstOpened == date(1))
    #expect(entry?.lastOpened == date(3))
    #expect(entry?.openCount == 2)
    #expect(entry?.isStarred == false)
  }

  @Test func hasOpenedCountsOpensNotStars() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.setStarred(true, infinitive: "ser", at: date(2))

    #expect(record.hasOpened("ir"))
    #expect(!record.hasOpened("ser"))
    #expect(!record.hasOpened("tener"))
  }

  @Test func recentIsNewestFirst() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ser", at: date(2))
    record.recordOpen("tener", at: date(3))
    record.recordOpen("ir", at: date(4))

    #expect(record.recent == ["ir", "tener", "ser"])
  }

  @Test func recentStopsAtItsLimit() {
    var record = LearnerVerbs()
    for index in 0..<(LearnerVerbs.recentLimit + 5) {
      record.recordOpen("verb\(index)", at: date(Double(index)))
    }

    let recent = record.recent
    #expect(recent.count == LearnerVerbs.recentLimit)
    #expect(recent.first == "verb\(LearnerVerbs.recentLimit + 4)")
  }

  @Test func equalDatesFallBackToTheInfinitive() {
    var record = LearnerVerbs()
    record.recordOpen("ser", at: date(1))
    record.recordOpen("ir", at: date(1))

    #expect(record.recent == ["ir", "ser"])
  }

  @Test func starringAndUnstarring() {
    var record = LearnerVerbs()
    record.setStarred(true, infinitive: "ir", at: date(1))
    record.setStarred(true, infinitive: "ser", at: date(2))
    #expect(record.isStarred("ir"))
    #expect(record.starred == ["ser", "ir"])

    record.setStarred(false, infinitive: "ir", at: date(3))
    #expect(!record.isStarred("ir"))
    #expect(record.starred == ["ser"])
  }

  @Test func starringAgainKeepsTheFirstDate() {
    var record = LearnerVerbs()
    record.setStarred(true, infinitive: "ir", at: date(1))
    record.setStarred(true, infinitive: "ir", at: date(5))

    #expect(record.entries["ir"]?.starred == date(1))
  }

  @Test func unstarringAVerbNeverOpenedForgetsIt() {
    var record = LearnerVerbs()
    record.setStarred(true, infinitive: "ir", at: date(1))
    record.setStarred(false, infinitive: "ir", at: date(2))

    #expect(record.entries.isEmpty)
  }

  @Test func unstarringAnOpenedVerbKeepsItsOpens() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.setStarred(true, infinitive: "ir", at: date(2))
    record.setStarred(false, infinitive: "ir", at: date(3))

    #expect(record.recent == ["ir"])
    #expect(record.entries["ir"]?.openCount == 1)
  }

  @Test func myVerbsListsStarredThenRecentWithoutRepeats() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ser", at: date(2))
    record.setStarred(true, infinitive: "ser", at: date(3))
    record.setStarred(true, infinitive: "poder", at: date(4))

    #expect(record.myVerbs == ["poder", "ser", "ir"])
  }

  /// Clear empties Recent and keeps the stars. It used to forget every open, and with them every
  /// collection's progress; now a verb once opened still counts.
  @Test func clearRecentsEmptiesRecentAndKeepsStarsAndFirstOpens() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ser", at: date(2))
    record.setStarred(true, infinitive: "ser", at: date(3))

    record.clearRecents()

    #expect(record.recent.isEmpty)
    #expect(record.myVerbs == ["ser"])
    #expect(record.starred == ["ser"])
    #expect(record.hasOpened("ir"))
    #expect(record.hasOpened("ser"))
    #expect(record.entries["ir"]?.lastOpened == nil)
    #expect(record.entries["ir"]?.firstOpened == date(1))
    #expect(record.entries["ir"]?.openCount == 1)
  }

  /// A swipe takes a starred, opened verb out of My Verbs, and a collection still counts it.
  @Test func removingAStarredVerbThatWasOpenedTakesItOutOfMyVerbsAndKeepsItsFirstOpen() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.setStarred(true, infinitive: "ir", at: date(2))
    record.recordOpen("ser", at: date(3))

    record.remove("ir")

    #expect(record.starred.isEmpty)
    #expect(record.recent == ["ser"])
    #expect(record.myVerbs == ["ser"])
    #expect(record.hasOpened("ir"))
    #expect(record.entries["ir"]?.firstOpened == date(1))
  }

  @Test func removingARecentVerbKeepsItsFirstOpen() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))

    record.remove("ir")

    #expect(record.myVerbs.isEmpty)
    #expect(record.hasOpened("ir"))
  }

  @Test func removingAStarredVerbNeverOpenedForgetsIt() {
    var record = LearnerVerbs()
    record.setStarred(true, infinitive: "ir", at: date(1))

    record.remove("ir")

    #expect(record.entries.isEmpty)
  }

  /// An entry with only its first open says something, so storing it does not drop it, and it is
  /// in neither of My Verbs' sections.
  @Test func anEntryWithOnlyItsFirstOpenIsKeptAndListedNowhere() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.clearRecents()
    record.setStarred(true, infinitive: "ir", at: date(2))
    record.setStarred(false, infinitive: "ir", at: date(3))

    #expect(record.entries["ir"]?.firstOpened == date(1))
    #expect(record.starred.isEmpty)
    #expect(record.recent.isEmpty)
    #expect(record.myVerbs.isEmpty)
    #expect(record.hasOpened("ir"))
    #expect(record.hasOpenHistory)
  }

  /// Reset Practice's forget: no verb counts as opened, an entry left with nothing is dropped, and
  /// My Verbs keeps its starred and recent verbs.
  @Test func forgettingTheOpenHistoryKeepsMyVerbs() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ser", at: date(2))
    record.recordOpen("tener", at: date(3))
    record.setStarred(true, infinitive: "tener", at: date(4))
    record.remove("ir")

    record.forgetOpenHistory()

    #expect(!record.hasOpenHistory)
    #expect(!record.hasOpened("ser"))
    #expect(!record.hasOpened("tener"))
    #expect(record.entries["ir"] == nil)
    #expect(record.myVerbs == ["tener", "ser"])
    #expect(record.entries["ser"]?.openCount == 0)

    record.recordOpen("ser", at: date(5))
    #expect(record.hasOpened("ser"))
    #expect(record.entries["ser"]?.firstOpened == date(5))
  }

  /// Recent leaves the starred verbs out before it takes its twenty, so that many starred opens
  /// do not shorten it while older unstarred opens wait.
  @Test func recentUnstarredFillsItsLimitPastStarredOpens() {
    var record = LearnerVerbs()
    let count = LearnerVerbs.recentLimit + 15
    for index in 0..<count {
      record.recordOpen("verb\(index)", at: date(Double(index)))
    }
    for index in (count - 15)..<count {
      record.setStarred(true, infinitive: "verb\(index)", at: date(Double(count)))
    }

    let recent = record.recentUnstarred
    #expect(recent.count == LearnerVerbs.recentLimit)
    #expect(recent.first == "verb\(count - 16)")
    #expect(recent.last == "verb0")
    #expect(record.myVerbs.count == 15 + LearnerVerbs.recentLimit)
    // The search field's recents still take the last twenty, starred or not.
    #expect(record.recent.first == "verb\(count - 1)")
    #expect(record.recent.count == LearnerVerbs.recentLimit)
  }

  @Test func removingAVerbNotInTheRecordChangesNothing() {
    var record = LearnerVerbs()
    record.recordOpen("ser", at: date(1))
    let before = record

    record.remove("ir")

    #expect(record == before)
  }

  @Test func jsonRoundTrips() throws {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.setStarred(true, infinitive: "ser", at: date(2))

    let json = try #require(record.json)
    #expect(LearnerVerbs(json: json) == record)
  }

  /// A field added later must stay optional, so that what the build before an app upgrade wrote
  /// still decodes. This pins the decoding of an entry that carries only its key and its count.
  @Test func anEntryWithoutItsOptionalFieldsDecodes() throws {
    let json = #"{"entries":{"ir":{"infinitive":"ir","openCount":0}}}"#

    let record = try #require(LearnerVerbs(json: json))
    #expect(record.entries["ir"]?.lastOpened == nil)
    #expect(record.entries["ir"]?.isStarred == false)
  }

  /// A record written by a later build, with a field this one does not know, still decodes.
  @Test func anEntryWithAnUnknownFieldDecodes() throws {
    let json = #"{"entries":{"ir":{"infinitive":"ir","openCount":2,"lastOpened":10,"due":20}}}"#

    let record = try #require(LearnerVerbs(json: json))
    #expect(record.recent == ["ir"])
  }

  /// An entry as every build before Phase 3 of the fixes plan wrote it decodes, and its first
  /// open counts toward collections.
  @Test func anEntryWrittenBeforeTheSplitDecodesAndCounts() throws {
    let json = #"{"entries":{"ir":{"infinitive":"ir","openCount":3,"firstOpened":5,"lastOpened":10,"starred":7}}}"#

    let record = try #require(LearnerVerbs(json: json))
    #expect(record.hasOpened("ir"))
    #expect(record.myVerbs == ["ir"])
    #expect(record.recent == ["ir"])
  }

  @Test func garbageDoesNotDecode() {
    #expect(LearnerVerbs(json: "not json") == nil)
  }

  /// A stored record that fails to decode is copied aside before the store's first save replaces
  /// it.
  @Test func theStoreBacksUpARecordItCannotRead() {
    let corrupt = #"{"entries":{"ir":{"infinitive":"ir"}}}"#
    let getterSetter = GetterSetterFake(dictionary: [LearnerVerbs.storageKey: corrupt])

    let store = LearnerVerbStore(getterSetter: getterSetter)
    #expect(store.myVerbs.isEmpty)
    #expect(getterSetter.get(key: LearnerVerbs.unreadableKey) == corrupt)

    store.recordOpen("ser", at: date(1))
    #expect(getterSetter.get(key: LearnerVerbs.unreadableKey) == corrupt)
    #expect(getterSetter.get(key: LearnerVerbs.storageKey) != corrupt)
  }

  @Test func theStoreBacksUpNothingWhenNothingIsStoredOrTheRecordReads() throws {
    let empty = GetterSetterFake()
    _ = LearnerVerbStore(getterSetter: empty)
    #expect(empty.get(key: LearnerVerbs.unreadableKey) == nil)

    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    let readable = GetterSetterFake(dictionary: [LearnerVerbs.storageKey: try #require(record.json)])
    _ = LearnerVerbStore(getterSetter: readable)
    #expect(readable.get(key: LearnerVerbs.unreadableKey) == nil)
  }

  @Test func theStoreSavesAndReloads() {
    let getterSetter = GetterSetterFake()
    let store = LearnerVerbStore(getterSetter: getterSetter)

    store.recordOpen("ir", at: date(1))
    #expect(store.toggleStar("ser", at: date(2)))

    let reloaded = LearnerVerbStore(getterSetter: getterSetter)
    #expect(reloaded.recentVerbs.map(\.infinitive) == ["ir"])
    #expect(reloaded.starredVerbs.map(\.infinitive) == ["ser"])
    #expect(reloaded.myVerbs.map(\.infinitive) == ["ser", "ir"])
    #expect(reloaded.isStarred("ser"))

    #expect(!reloaded.toggleStar("ser", at: date(3)))
    #expect(!LearnerVerbStore(getterSetter: getterSetter).isStarred("ser"))
  }

  @Test func theStoreSavesARemovalAndAClear() {
    let getterSetter = GetterSetterFake()
    let store = LearnerVerbStore(getterSetter: getterSetter)
    store.recordOpen("ir", at: date(1))
    store.toggleStar("ir", at: date(2))
    store.recordOpen("ser", at: date(3))
    store.toggleStar("tener", at: date(4))

    store.remove("ir")
    store.clearRecents()

    var reloaded = LearnerVerbStore(getterSetter: getterSetter)
    #expect(reloaded.myVerbs.map(\.infinitive) == ["tener"])
    #expect(reloaded.recentVerbs.isEmpty)
    #expect(reloaded.hasOpened("ser"))
    #expect(reloaded.hasOpened("ir"))
    #expect(!reloaded.isStarred("ir"))

    reloaded.forgetOpenHistory()
    reloaded = LearnerVerbStore(getterSetter: getterSetter)
    #expect(!reloaded.hasOpenHistory)
    #expect(reloaded.myVerbs.map(\.infinitive) == ["tener"])
  }

  @Test func theStoreSkipsAVerbNotInTheVerbMap() throws {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("noesverbo", at: date(2))
    let getterSetter = GetterSetterFake(dictionary: [LearnerVerbs.storageKey: try #require(record.json)])

    let store = LearnerVerbStore(getterSetter: getterSetter)
    #expect(store.recentVerbs.map(\.infinitive) == ["ir"])
  }

  /// A reflexive-only verb is kept under the bare infinitive the verb map keys on, and its entry
  /// carries the citation form the rows show.
  @Test func aReflexiveOnlyVerbIsKeptBare() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    store.recordOpen("arrepentir", at: date(1))

    #expect(store.recentVerbs.map(\.citationForm) == ["arrepentirse"])
  }

  @Test func recentUnstarredLeavesOutStarredVerbs() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    store.recordOpen("ir", at: date(1))
    store.recordOpen("ser", at: date(2))
    store.toggleStar("ser", at: date(3))

    #expect(store.recentVerbs.map(\.infinitive) == ["ser", "ir"])
    #expect(store.recentUnstarredVerbs.map(\.infinitive) == ["ir"])
  }

  @Test func listModesMapToSortsAndBack() {
    #expect(VerbListMode.allCases == [.frequency, .alphabetical, .myVerbs])
    for sort in VerbSort.allCases {
      #expect(VerbListMode(sort: sort).sort == sort)
    }
    #expect(VerbListMode.myVerbs.sort == nil)
  }

  @Test func starSignalNamesAreStable() {
    #expect(AnalyticsName.tapStarVerb.rawValue == "tapStarVerb")
    #expect(ParameterKey.starred.rawValue == "starred")
  }

  /// The store derives its lists once per change, so each list must follow every kind of change.
  @Test func theStoresListsFollowEveryChange() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    func expectLists(_ change: String, sourceLocation: SourceLocation = #_sourceLocation) {
      let record = store.record
      #expect(store.starredVerbs.map(\.infinitive) == record.starred, "\(change)", sourceLocation: sourceLocation)
      #expect(store.recentVerbs.map(\.infinitive) == record.recent, "\(change)", sourceLocation: sourceLocation)
      #expect(store.recentUnstarredVerbs.map(\.infinitive) == record.recentUnstarred, "\(change)", sourceLocation: sourceLocation)
      #expect(store.myVerbs.map(\.infinitive) == record.myVerbs, "\(change)", sourceLocation: sourceLocation)
    }
    store.recordOpen("ir", at: date(1))
    store.recordOpen("tener", at: date(2))
    expectLists("opens")
    #expect(store.recentVerbs.map(\.infinitive) == ["tener", "ir"])
    store.toggleStar("ir", at: date(3))
    expectLists("a star")
    #expect(store.myVerbs.map(\.infinitive) == ["ir", "tener"])
    store.recordOpen("ir", at: date(4))
    expectLists("a reopen")
    store.remove("tener")
    expectLists("a removal")
    store.clearRecents()
    expectLists("a clear")
    #expect(store.recentVerbs.isEmpty)
    store.forgetOpenHistory()
    expectLists("a reset")
    #expect(store.starredVerbs.map(\.infinitive) == ["ir"])
  }
}
