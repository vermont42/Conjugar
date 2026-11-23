//
//  ReviewScheduleTests.swift
//  ConjugarTests
//
//  The ladder alone: where an item starts, how answers and the review card move it, and when it
//  is due. `PracticeRecordTests` covers the record that holds the schedules.
//

import Foundation
import Testing
@testable import Conjugar

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

  @Test func aStartIsDueTheNextMorning() {
    let schedule = ReviewSchedule.start(at: date(10, hour: 23), calendar: calendar)

    #expect(schedule.box == 0)
    #expect(schedule.due == startOf(11))
    #expect(!schedule.isDue(at: date(10, hour: 23)))
    #expect(schedule.isDue(at: startOf(11)))
  }

  @Test func reviewsClimbTheLadderAndStayOnItsLastRung() {
    var schedule = ReviewSchedule.start(at: date(1), calendar: calendar)
    var dueDays: [Int] = []
    for _ in 0..<6 {
      schedule = schedule.reviewed(at: schedule.due, calendar: calendar)
      dueDays.append(calendar.dateComponents([.day], from: startOf(1), to: schedule.due).day ?? -1)
    }

    // Started on the 1st and due on the 2nd; then 3, 7, 14, 30, and 30 days after each review.
    #expect(dueDays == [4, 11, 25, 55, 85, 115])
    #expect(schedule.box == ReviewSchedule.intervals.count - 1)
  }

  @Test func aSnoozeKeepsTheBoxAndWaitsADay() {
    let schedule = ReviewSchedule.start(at: date(1), calendar: calendar).reviewed(at: date(2), calendar: calendar)

    let snoozed = schedule.snoozed(at: date(5, hour: 8), calendar: calendar)

    #expect(snoozed.box == schedule.box)
    #expect(snoozed.due == startOf(6))
  }

  @Test func aNewItemIsDueAtOnceInTheFirstBox() {
    let schedule = ReviewSchedule.new(at: date(3))

    #expect(schedule.box == 0)
    #expect(schedule.isDue(at: date(3)))
    #expect(schedule.answered(correctly: true, at: date(3), calendar: calendar) == ReviewSchedule(box: 1, due: startOf(6)))
    #expect(schedule.answered(correctly: false, at: date(3), calendar: calendar) == ReviewSchedule(box: 0, due: startOf(4)))
  }

  @Test func aWrongAnswerAlwaysStartsOver() {
    let high = ReviewSchedule(box: 3, due: startOf(20))

    #expect(high.answered(correctly: false, at: date(5), calendar: calendar) == ReviewSchedule(box: 0, due: startOf(6)))
  }

  /// A pattern asked three times in an afternoon climbs one box, not three.
  @Test func aRightAnswerMovesUpOnlyWhenDue() {
    let schedule = ReviewSchedule(box: 1, due: startOf(10))

    #expect(schedule.answered(correctly: true, at: date(8), calendar: calendar) == schedule)
    let moved = schedule.answered(correctly: true, at: date(10), calendar: calendar)
    #expect(moved == ReviewSchedule(box: 2, due: startOf(17)))
    #expect(moved.answered(correctly: true, at: date(10, hour: 15), calendar: calendar) == moved)
  }
}
