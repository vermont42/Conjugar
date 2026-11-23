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

    #expect(record.recent() == ["ir", "tener", "ser"])
  }

  @Test func recentStopsAtItsLimit() {
    var record = LearnerVerbs()
    for index in 0..<(LearnerVerbs.recentLimit + 5) {
      record.recordOpen("verb\(index)", at: date(Double(index)))
    }

    let recent = record.recent()
    #expect(recent.count == LearnerVerbs.recentLimit)
    #expect(recent.first == "verb\(LearnerVerbs.recentLimit + 4)")
  }

  @Test func equalDatesFallBackToTheInfinitive() {
    var record = LearnerVerbs()
    record.recordOpen("ser", at: date(1))
    record.recordOpen("ir", at: date(1))

    #expect(record.recent() == ["ir", "ser"])
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

    #expect(record.recent() == ["ir"])
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

  @Test func clearRecentsForgetsOpensAndKeepsStars() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.recordOpen("ser", at: date(2))
    record.setStarred(true, infinitive: "ser", at: date(3))

    record.clearRecents()

    #expect(record.recent().isEmpty)
    #expect(!record.hasOpened("ir"))
    #expect(record.starred == ["ser"])
    #expect(record.entries.count == 1)
    #expect(record.entries["ser"]?.openCount == 0)
  }

  @Test func removingAStarredVerbThatWasOpenedForgetsItEntirely() {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(1))
    record.setStarred(true, infinitive: "ir", at: date(2))
    record.recordOpen("ser", at: date(3))

    record.remove("ir")

    #expect(record.starred.isEmpty)
    #expect(record.recent() == ["ser"])
    #expect(record.myVerbs == ["ser"])
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

  /// A field added later, such as the review due date, must stay optional, so that what an older
  /// build wrote still decodes. This pins the decoding of an entry that carries only its key and
  /// its count, as an entry written today by `clearRecents` for a starred verb nearly does.
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
    #expect(record.recent() == ["ir"])
  }

  @Test func garbageDoesNotDecode() {
    #expect(LearnerVerbs(json: "not json") == nil)
  }

  @Test func theStoreSavesAndReloads() {
    let getterSetter = GetterSetterFake()
    let store = LearnerVerbStore(getterSetter: getterSetter)

    store.recordOpen("ir", source: .browse, at: date(1))
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
    store.recordOpen("ir", source: .browse, at: date(1))
    store.toggleStar("ir", at: date(2))
    store.recordOpen("ser", source: .browse, at: date(3))
    store.toggleStar("tener", at: date(4))

    store.remove("ir")
    store.clearRecents()

    let reloaded = LearnerVerbStore(getterSetter: getterSetter)
    #expect(reloaded.myVerbs.map(\.infinitive) == ["tener"])
    #expect(!reloaded.hasOpened("ser"))
    #expect(!reloaded.isStarred("ir"))
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
    store.recordOpen("arrepentir", source: .browse, at: date(1))

    #expect(store.recentVerbs.map(\.citationForm) == ["arrepentirse"])
  }

  @Test func recentUnstarredLeavesOutStarredVerbs() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    store.recordOpen("ir", source: .browse, at: date(1))
    store.recordOpen("ser", source: .browse, at: date(2))
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
}
