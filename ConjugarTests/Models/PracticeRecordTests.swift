//
//  PracticeRecordTests.swift
//  ConjugarTests
//
//  The practice record and its store: answers and lookups moving items, the order of due and
//  missed items, the review card's offer, a relaunch, the migration of the review card's older
//  schedules, and a reset. MainActor because the store is.
//

import Foundation
import Testing
@testable import Conjugar

@MainActor
struct PracticeRecordTests {
  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
    return calendar
  }()

  private var calendar: Calendar { Self.calendar }

  private func date(_ day: Int, hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)) ?? .distantPast
  }

  private func startOf(_ day: Int) -> Date {
    date(day, hour: 0)
  }

  private func key(_ verb: String, _ key: PracticeItem.Key) -> PracticeItem {
    .keyConjugation(infinitive: verb, key: key)
  }

  private let imperfecto = PracticeItem.pattern(tenseKey: "imperfecto_de_indicativo", person: "fs", ending: "er")

  /// The store's tests run at a fixed noon in UTC, and count back by calendar days. Counting back
  /// from `Date.now` by flat 86,400-second days, in the device's time zone, gave one day too few
  /// in the hour after midnight within ten days of a spring-forward change.
  private var now: Date {
    date(20)
  }

  private func daysAgo(_ days: Int) -> Date {
    calendar.date(byAdding: .day, value: -days, to: now) ?? .distantPast
  }

  @Test func answersMoveAnItemUpTheLadderAndAMissStartsItOver() {
    var record = PracticeRecord()

    record.recordAnswer(imperfecto, isCorrect: true, at: date(1), calendar: calendar)
    #expect(record.entry(for: imperfecto)?.schedule == ReviewSchedule(box: 1, due: startOf(4)))

    // Not yet due, so a second right answer the same day changes nothing.
    record.recordAnswer(imperfecto, isCorrect: true, at: date(1, hour: 15), calendar: calendar)
    #expect(record.entry(for: imperfecto)?.schedule.box == 1)

    record.recordAnswer(imperfecto, isCorrect: true, at: date(4), calendar: calendar)
    #expect(record.entry(for: imperfecto)?.schedule == ReviewSchedule(box: 2, due: startOf(11)))

    record.recordAnswer(imperfecto, isCorrect: false, at: date(5), calendar: calendar)
    #expect(record.entry(for: imperfecto)?.schedule == ReviewSchedule(box: 0, due: startOf(6)))
    #expect(record.entry(for: imperfecto)?.lastAnswerWasRight == false)
    #expect(record.entry(for: imperfecto)?.lastAnswered == date(5))
  }

  @Test func dueItemsComeLongestOverdueFirstAndMissedItemsMostRecentFirst() {
    var record = PracticeRecord()
    record.recordAnswer(key("ser", .yoPresente), isCorrect: false, at: date(3), calendar: calendar)
    record.recordAnswer(key("tener", .yoPresente), isCorrect: false, at: date(1), calendar: calendar)
    record.recordAnswer(imperfecto, isCorrect: true, at: date(1), calendar: calendar)
    record.recordAnswer(key("ir", .yoPresente), isCorrect: false, at: date(1, hour: 9), calendar: calendar)

    #expect(record.dueItems(at: date(1, hour: 20)).isEmpty)
    #expect(record.dueItems(at: date(9)).map(\.key) == ["key:ir:yo_presente", "key:tener:yo_presente", "key:ser:yo_presente", imperfecto.key])
    #expect(record.missedItems() == [key("ser", .yoPresente), key("tener", .yoPresente), key("ir", .yoPresente)])

    record.recordAnswer(key("ser", .yoPresente), isCorrect: true, at: date(9), calendar: calendar)
    #expect(record.missedItems() == [key("tener", .yoPresente), key("ir", .yoPresente)])
    #expect(record.nextDue(after: date(9)) == startOf(12))
  }

  @Test func aLookupStartsItsItemsOverUnlessItCameFromTheCard() {
    var record = PracticeRecord()
    let items = [key("ir", .yoPresente), key("ir", .yoPretérito)]
    record.recordLookup(items, at: date(1), calendar: calendar)
    record.recordReview(items, at: date(2), calendar: calendar)
    #expect(record.entry(for: items[0])?.schedule == ReviewSchedule(box: 1, due: startOf(5)))

    record.recordLookup(items, at: date(3), reschedules: false, calendar: calendar)
    #expect(record.entry(for: items[0])?.schedule.box == 1)
    #expect(record.entry(for: items[0])?.lastLookedUp == date(3))

    record.recordLookup(items, at: date(3), calendar: calendar)
    #expect(record.entry(for: items[0])?.schedule == ReviewSchedule(box: 0, due: startOf(4)))
  }

  @Test func theCardsRevealRaisesOnlyDueItemsAndADismissalSnoozesThem() {
    var record = PracticeRecord()
    let due = key("tener", .yoPresente)
    let notDue = key("tener", .yoFuturo)
    record.recordLookup([due], at: date(1), calendar: calendar)
    record.recordAnswer(notDue, isCorrect: true, at: date(2), calendar: calendar)

    var snoozed = record
    snoozed.snooze([due, notDue], at: date(3), calendar: calendar)
    #expect(snoozed.entry(for: due)?.schedule == ReviewSchedule(box: 0, due: startOf(4)))
    #expect(snoozed.entry(for: notDue) == record.entry(for: notDue))

    record.recordReview([due, notDue], at: date(3), calendar: calendar)
    #expect(record.entry(for: due)?.schedule == ReviewSchedule(box: 1, due: startOf(6)))
    #expect(record.entry(for: notDue)?.schedule == ReviewSchedule(box: 1, due: startOf(5)))
  }

  @Test func theRecordSurvivesItsJSONAndToleratesAnEntryWithOnlyItsSchedule() throws {
    var record = PracticeRecord()
    record.recordAnswer(imperfecto, isCorrect: false, at: date(1), calendar: calendar)
    record.recordLookup([key("ir", .yoPresente)], at: date(2), calendar: calendar)
    let json = try #require(record.json)
    #expect(PracticeRecord(json: json) == record)

    let bare = #"{"entries":{"key:ir:yo_presente":{"schedule":{"box":2,"due":10}}}}"#
    let decoded = try #require(PracticeRecord(json: bare))
    #expect(decoded.entry(for: key("ir", .yoPresente))?.schedule.box == 2)
    #expect(PracticeRecord(json: "not json") == nil)
  }

  @Test func anUnreadableKeyIsSkippedRatherThanOffered() throws {
    let json = #"{"entries":{"key:ir:yo_imperfecto":{"schedule":{"box":0,"due":0}},"key:ir:yo_presente":{"schedule":{"box":0,"due":0}}}}"#
    let record = try #require(PracticeRecord(json: json))
    #expect(record.dueItems(at: date(1)) == [key("ir", .yoPresente)])
  }

  @Test func theStoreMapsAnswersAndLookupsToItems() {
    let store = PracticeStore(getterSetter: GetterSetterFake(), calendar: calendar)

    store.recordAnswer(to: QuizQuestion("tener", .presenteDeSubjuntivo, .firstPlural), isCorrect: false, at: date(1))
    store.recordAnswer(to: QuizQuestion("tener", .imperfectoDeIndicativo, .firstSingular), isCorrect: true, at: date(1))
    store.recordLookup("hablar", source: .search, at: date(1))
    store.recordLookup("pensar", source: .search, at: date(1))

    #expect(Set(store.record.entries.keys) == [
      "key:tener:yo_presente",
      imperfecto.key,
      "key:pensar:yo_presente"
    ])
  }

  @Test func theCardOffersTheVerbLongestOverdueWithItsDueKeyConjugations() throws {
    let store = PracticeStore(getterSetter: GetterSetterFake(), calendar: calendar)
    store.recordLookup("tener", source: .search, at: daysAgo(10))
    store.recordLookup("ir", source: .search, at: daysAgo(5))
    store.recordAnswer(to: QuizQuestion("hablar", .imperfectoDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(20))

    let offer = try #require(store.cardOffer(at: now))
    #expect(offer.entry.infinitive == "tener")
    #expect(offer.items == PracticeItem.keyConjugations(of: "tener"))
    #expect(offer.daysSinceActivity == 10)
    #expect(offer.wasLookedUp)

    store.recordReview(offer, at: now)
    #expect(store.cardOffer(at: now)?.entry.infinitive == "ir")
  }

  @Test func theCardSaysPracticedWhenAnAnswerCameAfterTheLookup() throws {
    let store = PracticeStore(getterSetter: GetterSetterFake(), calendar: calendar)
    store.recordLookup("tener", source: .search, at: daysAgo(10))
    store.recordAnswer(to: QuizQuestion("tener", .futuroDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(4))

    let offer = try #require(store.cardOffer(at: now))
    #expect(!offer.wasLookedUp)
    #expect(offer.daysSinceActivity == 4)
    #expect(offer.items.contains(key("tener", .yoFuturo)))

    store.snooze(offer, at: now)
    #expect(store.cardOffer(at: now) == nil)
  }

  @Test func aRegularVerbsPatternsAreNeverOnTheCard() {
    let store = PracticeStore(getterSetter: GetterSetterFake(), calendar: calendar)
    store.recordAnswer(to: QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular), isCorrect: false, at: daysAgo(10))
    store.recordLookup("hablar", source: .search, at: daysAgo(10))

    #expect(!store.isEmpty)
    #expect(store.cardOffer(at: now) == nil)
  }

  @Test func theRecordSurvivesARelaunch() {
    let getterSetter = GetterSetterFake()
    let store = PracticeStore(getterSetter: getterSetter, calendar: calendar)
    store.recordLookup("tener", source: .search, at: daysAgo(3))
    store.recordAnswer(to: QuizQuestion("comer", .imperfectoDeIndicativo, .firstSingular), isCorrect: false, at: now)

    let reloaded = PracticeStore(getterSetter: getterSetter, calendar: calendar)
    #expect(reloaded.record == store.record)
    #expect(reloaded.cardOffer(at: now)?.entry.infinitive == "tener")
  }

  /// The review card kept one schedule per irregular verb on `LearnerVerbs.Entry.review`, and an
  /// entry from before that had none. The first launch with a practice record gives each
  /// irregular verb's key conjugations its schedule, or a start at its last open.
  @Test func theFirstLaunchMigratesTheReviewCardsSchedules() throws {
    let getterSetter = GetterSetterFake()
    let opened = daysAgo(10).timeIntervalSinceReferenceDate
    let due = daysAgo(2).timeIntervalSinceReferenceDate
    let json = #"{"entries":{"tener":{"infinitive":"tener","openCount":2,"lastOpened":\#(opened),"review":{"box":2,"due":\#(due)}},"ir":{"infinitive":"ir","openCount":1,"lastOpened":\#(opened)},"hablar":{"infinitive":"hablar","openCount":1,"lastOpened":\#(opened)},"ser":{"infinitive":"ser","openCount":0,"starred":0}}}"#
    getterSetter.set(key: LearnerVerbs.storageKey, value: json)

    let store = PracticeStore(getterSetter: getterSetter, calendar: calendar)

    for item in PracticeItem.keyConjugations(of: "tener") {
      #expect(store.record.entry(for: item)?.schedule == ReviewSchedule(box: 2, due: Date(timeIntervalSinceReferenceDate: due)))
    }
    for item in PracticeItem.keyConjugations(of: "ir") {
      #expect(store.record.entry(for: item)?.schedule.box == 0)
      #expect(store.record.entry(for: item)?.lastLookedUp == Date(timeIntervalSinceReferenceDate: opened))
    }
    #expect(store.record.entries.keys.allSatisfy { $0.hasPrefix("key:tener:") || $0.hasPrefix("key:ir:") })
    #expect(store.cardOffer(at: now)?.entry.infinitive == "ir")
    let saved = try #require(getterSetter.get(key: PracticeRecord.storageKey).flatMap(PracticeRecord.init(json:)))
    #expect(saved == store.record)
    // The learner's verbs still decode, without their old schedules.
    #expect(LearnerVerbStore(getterSetter: getterSetter).recentVerbs.map(\.infinitive).sorted() == ["hablar", "ir", "tener"])
  }

  /// A stored record that fails to decode is copied aside, and the store starts empty rather
  /// than running the first launch's migration again over it.
  @Test func anUnreadableRecordIsBackedUpAndNotMigratedOver() {
    let getterSetter = GetterSetterFake()
    let opened = daysAgo(10).timeIntervalSinceReferenceDate
    getterSetter.set(key: LearnerVerbs.storageKey, value: #"{"entries":{"ir":{"infinitive":"ir","openCount":1,"lastOpened":\#(opened)}}}"#)
    let corrupt = #"{"entries":{"key:ir:participio":{}}}"#
    getterSetter.set(key: PracticeRecord.storageKey, value: corrupt)

    let store = PracticeStore(getterSetter: getterSetter, calendar: calendar)

    #expect(store.record.isEmpty)
    #expect(getterSetter.get(key: PracticeRecord.unreadableKey) == corrupt)
    #expect(getterSetter.get(key: PracticeRecord.storageKey) != corrupt)
  }

  @Test func aFirstLaunchBacksUpNothing() {
    let getterSetter = GetterSetterFake()
    _ = PracticeStore(getterSetter: getterSetter, calendar: calendar)
    #expect(getterSetter.get(key: PracticeRecord.unreadableKey) == nil)
  }

  @Test func aResetStaysReset() {
    let getterSetter = GetterSetterFake()
    let opened = daysAgo(10).timeIntervalSinceReferenceDate
    getterSetter.set(key: LearnerVerbs.storageKey, value: #"{"entries":{"ir":{"infinitive":"ir","openCount":1,"lastOpened":\#(opened)}}}"#)
    let store = PracticeStore(getterSetter: getterSetter, calendar: calendar)
    #expect(!store.isEmpty)

    store.reset()

    #expect(store.isEmpty)
    #expect(PracticeStore(getterSetter: getterSetter, calendar: calendar).isEmpty)
  }
}
