//
//  WidgetWeekTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

/// The week of verbs and questions that the app writes for the widgets, so that they change at
/// midnight without the app being opened. Nonisolated: it touches only the engine, the verb map,
/// and value types.
struct WidgetWeekTests {
  private func entry(_ infinitive: String) throws -> VerbMapEntry {
    try #require(VerbMap.shared.entry(for: infinitive))
  }

  /// Noon of the day `offset` days after 2026-01-01, the writer's day zero.
  private func day(_ offset: Int, hour: Int = 12) throws -> Date {
    let calendar = CalendarDay.calendar
    let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour)))
    return try #require(calendar.date(byAdding: .day, value: offset, to: start))
  }

  private func roundTrip(_ week: WidgetWeek) throws -> WidgetWeek {
    try JSONDecoder().decode(WidgetWeek.self, from: try JSONEncoder().encode(week))
  }

  // The writer, driven for a day, gives that day and the six after, each with VerbDraw's verb.
  @Test func aWeekHoldsSevenDatedDaysOfVerbDrawsVerbs() throws {
    let myVerbs = try ["churruscar", "abolir", "arrepentir"].map(entry)
    let date = try day(325, hour: 8)
    let week = try roundTrip(try #require(WidgetSnapshotWriter.makeWeek(for: date, myVerbs: myVerbs)))

    #expect(week.days.count == WidgetSnapshotWriter.weekLength)
    var lastShown: [String: Int] = [:]
    for (offset, snapshot) in week.days.enumerated() {
      let date = try day(325 + offset)
      let number = WidgetSnapshotWriter.dayNumber(of: date)
      #expect(number == 325 + offset)
      #expect(snapshot.dateString == CalendarDay.string(for: date))
      let expected = try #require(VerbDraw.verbOfTheDay(dayNumber: number, myVerbs: myVerbs, lastShown: lastShown, frequentVerbs: VerbDraw.frequentVerbs))
      #expect(snapshot.infinitive == expected.citationForm, "\(snapshot.dateString)")
      if VerbDraw.isMyVerbsDay(number) {
        lastShown[expected.infinitive] = number
      }
      #expect(snapshot.quizQuestion.questionID.hasPrefix(WidgetSnapshotWriter.questionIDPrefix(on: date, challenge: .initial)))
    }
    #expect(week.myVerbs == ["abolir", "arrepentir", "churruscar"])
    #expect(week.myVerbsTurns?.map(\.dayNumber) == [327, 330])
    #expect(week.myVerbsTurns?.map(\.verb) == ["abolir", "arrepentir"])
    #expect(week.myVerbsShown == [:])
  }

  // 2026-11-24 is day 327; a calendar setting other than Gregorian cannot move it.
  @Test func theDayNumberIsGregorian() throws {
    let date = try #require(CalendarDay.noon(of: "2026-11-24"))
    #expect(WidgetSnapshotWriter.dayNumber(of: date) == 327)
    #expect(WidgetSnapshotWriter.dayNumber(of: try day(0, hour: 0)) == 0)
    #expect(WidgetSnapshotWriter.dayNumber(of: try day(-1, hour: 23)) == -1)
    #expect(CalendarDay.calendar.identifier == .gregorian)
  }

  // Opening the app on a day the last week covers keeps that day's verb, though My Verbs changed;
  // the later days are planned again, and the verb just opened has the next My Verbs day.
  @Test func aRewriteKeepsTodaysVerbAndReplansTheRest() throws {
    let before = try ["beber", "comer"].map(entry)
    let first = try #require(WidgetSnapshotWriter.makeWeek(for: try day(0), myVerbs: before))
    #expect(first.firstDay.infinitive == "beber")

    let after = try [entry("abrir")] + before
    let second = try #require(WidgetSnapshotWriter.makeWeek(for: try day(0, hour: 20), myVerbs: after, previous: try roundTrip(first)))
    #expect(second.firstDay == first.firstDay)
    #expect(second.myVerbsTurns?.first == WidgetWeek.Turn(dayNumber: 0, verb: "beber"))
    #expect(second.days[3].infinitive == "abrir")
    #expect(second.days[6].infinitive == "comer")
  }

  // The app opened at odd intervals, with My Verbs growing and reordered between: on each My
  // Verbs day the widget shows, no verb comes back while another of the list has waited longer,
  // and a day the widget has shown keeps its verb when the app writes again.
  @Test func turnsSurviveTheAppOpenedAtOddIntervals() throws {
    let pool = try ["beber", "comer", "hablar", "vivir", "abrir", "zurcir", "mirar", "leer"].map(entry)
    let opens = [0, 1, 2, 3, 5, 9, 10, 16, 17, 20, 26, 27, 28, 33, 39, 40]
    var week: WidgetWeek?
    var shownByWidget: [String: Int] = [:]
    var list: [VerbMapEntry] = []
    for dayNumber in 0..<46 {
      let date = try day(dayNumber, hour: 9)
      if let index = opens.firstIndex(of: dayNumber) {
        let grown = Array(pool.prefix(3 + index / 3))
        list = index.isMultiple(of: 2) ? grown : grown.reversed()
        let next = try #require(WidgetSnapshotWriter.makeWeek(for: date, myVerbs: list, previous: try week.map(roundTrip)))
        if let shown = week?.days.first(where: { $0.dateString == CalendarDay.string(for: date) }) {
          #expect(next.firstDay == shown, "day \(dayNumber)")
        }
        week = next
      }
      let current = try #require(week)
      // The eighth day and after repeat the last day written, as decided.
      guard VerbDraw.isMyVerbsDay(dayNumber), let lastDay = current.days.last, CalendarDay.string(for: date) <= lastDay.dateString else {
        continue
      }
      let verb = current.day(on: date).infinitive
      let chosen = shownByWidget[verb] ?? Int.min
      for other in list where other.infinitive != verb {
        #expect((shownByWidget[other.infinitive] ?? Int.min) >= chosen, "day \(dayNumber): \(verb) came back while \(other.infinitive) waited")
      }
      shownByWidget[verb] = dayNumber
    }
    #expect(shownByWidget.count == pool.count)
  }

  // A verb gone from My Verbs is forgotten, so the record stays as small as the list.
  @Test func theRecordKeepsOnlyMyVerbs() throws {
    let both = try ["beber", "comer"].map(entry)
    let first = try #require(WidgetSnapshotWriter.makeWeek(for: try day(0), myVerbs: both))
    let later = try #require(WidgetSnapshotWriter.makeWeek(for: try day(4), myVerbs: [try entry("comer")], previous: first))
    #expect(later.myVerbsShown == ["comer": 3])
  }

  @Test func theGateNoticesADayMyVerbsOrTheChallenge() throws {
    let names = ["beber", "comer"]
    let date = try day(0, hour: 9)
    var week = try #require(WidgetSnapshotWriter.makeWeek(for: date, myVerbs: try names.map(entry)))
    week.myVerbs = names.sorted()
    let challenge = WidgetSnapshotWriter.ChallengeContext.initial
    #expect(WidgetSnapshotWriter.isCurrent(week, on: try day(0, hour: 22), myVerbs: Array(names.reversed()), challenge: challenge))
    #expect(!WidgetSnapshotWriter.isCurrent(week, on: try day(1, hour: 9), myVerbs: names, challenge: challenge))
    #expect(!WidgetSnapshotWriter.isCurrent(week, on: date, myVerbs: names + ["vivir"], challenge: challenge))
    let other = WidgetSnapshotWriter.ChallengeContext(level: .advanced, region: .spain, secondSingular: .secondSingularTú)
    #expect(!WidgetSnapshotWriter.isCurrent(week, on: date, myVerbs: names, challenge: other))
  }

  // A widget that knows one day reads the first day from a week's file, and a widget that knows
  // the week reads a file of one day as a week of one.
  @Test func theFileReadsBothWays() throws {
    let week = try #require(WidgetSnapshotWriter.makeWeek(for: try day(0), myVerbs: [try entry("beber")]))
    let data = try JSONEncoder().encode(week)
    #expect(try JSONDecoder().decode(WidgetSnapshot.self, from: data) == week.firstDay)
    #expect(try JSONDecoder().decode(WidgetWeek.self, from: data) == week)

    let oneDay = try JSONDecoder().decode(WidgetWeek.self, from: try JSONEncoder().encode(week.days[2]))
    #expect(oneDay.days == [week.days[2]])
    #expect(oneDay.myVerbs == nil)
    #expect(oneDay.myVerbsTurns == nil)
  }

  // The widget shows the day of its own date, not the first in the file.
  @Test func theTimelineShowsEachDayFromItsMidnight() throws {
    let week = try #require(WidgetSnapshotWriter.makeWeek(for: try day(10), myVerbs: []))
    let calendar = CalendarDay.calendar
    let now = try day(12, hour: 10)

    let (moments, reload) = week.timeline(from: now)
    #expect(moments.map(\.day) == Array(week.days.dropFirst(2)))
    #expect(moments.first?.date == now)
    for (moment, offset) in zip(moments.dropFirst(), 13...) {
      #expect(moment.date == calendar.startOfDay(for: try day(offset)))
    }
    #expect(reload == calendar.startOfDay(for: try day(17)))
    #expect(week.day(on: try day(12, hour: 0)) == week.days[2])
    #expect(week.day(on: try day(12, hour: 23)) == week.days[2])
  }

  @Test func afterTheLastDayTheLastDayStays() throws {
    let week = try #require(WidgetSnapshotWriter.makeWeek(for: try day(10), myVerbs: []))
    let now = try day(20, hour: 10)
    let (moments, reload) = week.timeline(from: now)
    #expect(moments.map(\.day) == [week.days[6]])
    #expect(reload == CalendarDay.calendar.startOfDay(for: try day(21)))
    // A clock turned back shows the first day.
    #expect(week.day(on: try day(5)) == week.firstDay)
  }

  @Test func anAnswerFindsItsOwnDaysQuestion() throws {
    let week = try #require(WidgetSnapshotWriter.makeWeek(for: try day(10), myVerbs: []))
    let third = week.days[3]
    #expect(week.day(askingQuestion: third.quizQuestion.questionID) == third)
    #expect(week.day(askingQuestion: "nothing") == nil)
    #expect(Set(week.days.map(\.quizQuestion.questionID)).count == week.days.count)
  }
}
