//
//  ReviewScheduleTests.swift
//  ConjugarTests
//
//  The review card's schedule, the record's operations on it, and the store's choice of which
//  verbs it schedules (browse plan, Phase 15). MainActor because the store is.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct ReviewScheduleTests {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
  }()

  private var calendar: Calendar { Self.calendar }

  /// Day `day` of 2026-11, at `hour` UTC.
  private func date(_ day: Int, hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)) ?? .distantPast
  }

  private func startOf(_ day: Int) -> Date {
    date(day, hour: 0)
  }

  // MARK: - The schedule

  @Test func aLookupIsDueTheNextMorning() {
    let schedule = ReviewSchedule.lookedUp(at: date(10, hour: 23), calendar: calendar)

    #expect(schedule.box == 0)
    #expect(schedule.due == startOf(11))
    #expect(!schedule.isDue(at: date(10, hour: 23)))
    #expect(schedule.isDue(at: startOf(11)))
  }

  @Test func revealsClimbTheLadderAndStayOnItsLastRung() {
    var schedule = ReviewSchedule.lookedUp(at: date(1), calendar: calendar)
    var dueDays: [Int] = []
    for _ in 0..<6 {
      schedule = schedule.revealed(at: schedule.due, calendar: calendar)
      dueDays.append(calendar.dateComponents([.day], from: startOf(1), to: schedule.due).day ?? -1)
    }

    // Looked up on the 1st and due on the 2nd; then 3, 7, 14, 30, and 30 days after each reveal.
    #expect(dueDays == [4, 11, 25, 55, 85, 115])
    #expect(schedule.box == ReviewSchedule.intervals.count - 1)
  }

  @Test func aDismissalKeepsTheBoxAndWaitsADay() {
    let schedule = ReviewSchedule.lookedUp(at: date(1), calendar: calendar).revealed(at: date(2), calendar: calendar)

    let dismissed = schedule.dismissed(at: date(5, hour: 8), calendar: calendar)

    #expect(dismissed.box == schedule.box)
    #expect(dismissed.due == startOf(6))
  }

  // MARK: - The record

  /// A record whose verbs were each opened with a schedule, as the store opens irregular verbs.
  private func record(opening opens: [(String, Date)]) -> LearnerVerbs {
    var record = LearnerVerbs()
    for (infinitive, date) in opens {
      record.recordOpen(infinitive, at: date, schedulesReview: true, calendar: calendar)
    }
    return record
  }

  @Test func dueVerbsComeLongestOverdueFirst() {
    let record = record(opening: [("ser", date(3)), ("tener", date(1)), ("ir", date(1)), ("hacer", date(9))])

    #expect(record.dueForReview(at: date(9)) == ["ir", "tener", "ser"])
    #expect(record.dueForReview(at: date(1)).isEmpty)
  }

  @Test func anOpenThatSchedulesNothingLeavesNoSchedule() {
    var record = LearnerVerbs()
    record.recordOpen("hablar", at: date(1), calendar: calendar)

    #expect(record.entries["hablar"]?.review == nil)
    #expect(record.dueForReview(at: date(30)).isEmpty)
  }

  @Test func aRevealPostponesTheVerb() {
    var record = record(opening: [("ir", date(1))])

    record.recordReveal("ir", at: date(2), calendar: calendar)

    #expect(record.entries["ir"]?.review == ReviewSchedule(box: 1, due: startOf(5)))
    #expect(record.dueForReview(at: date(4)).isEmpty)
    #expect(record.dueForReview(at: date(5)) == ["ir"])
  }

  @Test func aDismissalBringsTheVerbBackTomorrowInTheSameBox() {
    var record = record(opening: [("ir", date(1))])

    record.recordDismissal("ir", at: date(2), calendar: calendar)

    #expect(record.dueForReview(at: date(2)).isEmpty)
    #expect(record.dueForReview(at: date(3)) == ["ir"])
    #expect(record.entries["ir"]?.review?.box == 0)
  }

  @Test func lookingAVerbUpAgainSendsItBackToTheFirstBox() {
    var record = record(opening: [("ir", date(1))])
    record.recordReveal("ir", at: date(2), calendar: calendar)
    record.recordReveal("ir", at: date(5), calendar: calendar)

    record.recordOpen("ir", at: date(6), schedulesReview: true, calendar: calendar)

    #expect(record.entries["ir"]?.review == ReviewSchedule(box: 0, due: startOf(7)))
  }

  @Test func anOpenThatSchedulesNothingKeepsAnExistingSchedule() {
    var record = record(opening: [("ir", date(1))])
    record.recordReveal("ir", at: date(2), calendar: calendar)
    let revealed = record.entries["ir"]?.review

    record.recordOpen("ir", at: date(2), calendar: calendar)

    #expect(record.entries["ir"]?.review == revealed)
    #expect(record.entries["ir"]?.openCount == 2)
  }

  @Test func aStarredVerbNeverOpenedIsNeverDue() {
    var record = LearnerVerbs()
    record.setStarred(true, infinitive: "ir", at: date(1))

    #expect(record.dueForReview(at: date(30)).isEmpty)
  }

  @Test func starringKeepsTheSchedule() {
    var record = record(opening: [("ir", date(1))])
    let schedule = record.entries["ir"]?.review

    record.setStarred(true, infinitive: "ir", at: date(2))

    #expect(record.entries["ir"]?.review == schedule)
  }

  @Test func clearingRecentsAndRemovingEndReviews() {
    var record = record(opening: [("ir", date(1)), ("ser", date(1))])
    record.setStarred(true, infinitive: "ir", at: date(1))
    record.remove("ser")
    #expect(record.dueForReview(at: date(30)) == ["ir"])

    record.clearRecents()

    #expect(record.dueForReview(at: date(30)).isEmpty)
    #expect(record.isStarred("ir"))
  }

  @Test func revealingOrDismissingAnUnscheduledVerbChangesNothing() {
    var record = record(opening: [("ser", date(1))])
    record.recordOpen("hablar", at: date(1), calendar: calendar)
    let before = record

    record.recordReveal("ir", at: date(2), calendar: calendar)
    record.recordDismissal("ir", at: date(2), calendar: calendar)
    record.recordReveal("hablar", at: date(2), calendar: calendar)
    record.recordDismissal("hablar", at: date(2), calendar: calendar)

    #expect(record == before)
  }

  @Test func unscheduledVerbsAreScheduledFromTheirLastOpenWhereAllowed() throws {
    let lastOpened = date(4)
    let json = #"{"entries":{"ir":{"infinitive":"ir","openCount":1,"lastOpened":\#(lastOpened.timeIntervalSinceReferenceDate)},"hablar":{"infinitive":"hablar","openCount":1,"lastOpened":\#(lastOpened.timeIntervalSinceReferenceDate)},"ser":{"infinitive":"ser","openCount":0,"starred":0}}}"#
    var record = try #require(LearnerVerbs(json: json))

    let firstRunChanged = record.scheduleUnscheduledReviews(where: { $0 != "hablar" }, calendar: calendar)
    #expect(firstRunChanged)

    #expect(record.entries["ir"]?.review == ReviewSchedule(box: 0, due: startOf(5)))
    #expect(record.entries["hablar"]?.review == nil)
    #expect(record.entries["ser"]?.review == nil)
    let secondRunChanged = record.scheduleUnscheduledReviews(where: { $0 != "hablar" }, calendar: calendar)
    #expect(!secondRunChanged)
  }

  @Test(arguments: [(10, 23, 0), (11, 0, 1), (13, 7, 3)])
  func daysSinceOpenedCountsCalendarDays(day: Int, hour: Int, expected: Int) {
    var record = LearnerVerbs()
    record.recordOpen("ir", at: date(10, hour: 22), calendar: calendar)

    #expect(record.daysSinceOpened("ir", at: date(day, hour: hour), calendar: calendar) == expected)
  }

  @Test func theScheduleSurvivesTheJSONRoundTrip() throws {
    var record = record(opening: [("ir", date(1))])
    record.recordReveal("ir", at: date(2), calendar: calendar)

    let json = try #require(record.json)
    #expect(LearnerVerbs(json: json) == record)
  }

  // MARK: - The store

  @Test func onlyIrregularVerbsAreReviewable() {
    #expect(LearnerVerbStore.isReviewable("ir"))
    #expect(LearnerVerbStore.isReviewable("tener"))
    // Orthographic changes count, as the verb page's pill counts them: busqué.
    #expect(LearnerVerbStore.isReviewable("buscar"))
    // A reflexive-only verb, under its bare infinitive.
    #expect(LearnerVerbStore.isReviewable("arrepentir"))
    #expect(!LearnerVerbStore.isReviewable("hablar"))
    #expect(!LearnerVerbStore.isReviewable("comer"))
    #expect(!LearnerVerbStore.isReviewable("vivir"))
    #expect(!LearnerVerbStore.isReviewable("noesverbo"))
  }

  @Test func theStoreSchedulesOnlyIrregularVerbs() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    let tenDaysAgo = Date.now.addingTimeInterval(-10 * 86_400)

    store.recordOpen("hablar", source: .search, at: tenDaysAgo)
    store.recordOpen("tener", source: .search, at: tenDaysAgo)

    #expect(store.record.entries["hablar"]?.review == nil)
    #expect(store.record.entries["tener"]?.review != nil)
    #expect(store.verbDueForReview()?.infinitive == "tener")
  }

  @Test func theStoreOffersTheLongestOverdueVerbAndAnOpenFromTheCardKeepsItsSchedule() {
    let getterSetter = GetterSetterFake()
    let store = LearnerVerbStore(getterSetter: getterSetter)
    let tenDaysAgo = Date.now.addingTimeInterval(-10 * 86_400)
    store.recordOpen("ir", source: .search, at: tenDaysAgo)
    store.recordOpen("ser", source: .browse, at: tenDaysAgo.addingTimeInterval(86_400))

    #expect(store.verbDueForReview()?.infinitive == "ir")

    store.recordReveal("ir")
    let revealed = store.record.entries["ir"]?.review
    store.recordOpen("ir", source: .reviewCard)
    #expect(store.record.entries["ir"]?.review == revealed)
    #expect(store.verbDueForReview()?.infinitive == "ser")

    let reloaded = LearnerVerbStore(getterSetter: getterSetter)
    #expect(reloaded.verbDueForReview()?.infinitive == "ser")
    reloaded.recordDismissal("ser")
    #expect(reloaded.verbDueForReview() == nil)
  }

  @Test func anOpenByAnyOtherRouteRestartsTheSchedule() {
    let store = LearnerVerbStore(getterSetter: GetterSetterFake())
    store.recordOpen("ir", source: .search, at: Date.now.addingTimeInterval(-10 * 86_400))
    store.recordReveal("ir")
    #expect(store.record.entries["ir"]?.review?.box == 1)

    store.recordOpen("ir", source: .widget)

    #expect(store.record.entries["ir"]?.review?.box == 0)
  }

  /// A record written before Phase 15 has opens but no schedules. The store schedules its
  /// irregular verbs as it loads, so a card can appear on the first day, and saves the result.
  @Test func theStoreSchedulesAnOlderRecordsIrregularVerbsAsItLoads() throws {
    let getterSetter = GetterSetterFake()
    let tenDaysAgo = Date.now.addingTimeInterval(-10 * 86_400).timeIntervalSinceReferenceDate
    let json = #"{"entries":{"tener":{"infinitive":"tener","openCount":1,"lastOpened":\#(tenDaysAgo)},"hablar":{"infinitive":"hablar","openCount":1,"lastOpened":\#(tenDaysAgo)}}}"#
    getterSetter.set(key: LearnerVerbs.storageKey, value: json)

    let store = LearnerVerbStore(getterSetter: getterSetter)

    #expect(store.verbDueForReview()?.infinitive == "tener")
    #expect(store.record.entries["hablar"]?.review == nil)
    let saved = try #require(getterSetter.get(key: LearnerVerbs.storageKey).flatMap(LearnerVerbs.init(json:)))
    #expect(saved.entries["tener"]?.review != nil)
  }
}
