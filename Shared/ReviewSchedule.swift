//
//  ReviewSchedule.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// When an item of the practice record is next due, and which box of the ladder it is in. This is
/// the Leitner system: an item enters the first box, a right answer or a revealed review card
/// moves it up one, and a wrong answer or a later lookup sends it back to the first.
///
/// Due dates fall at the start of a day, so an item missed late in the evening waits until the
/// next morning rather than an hour.
nonisolated struct ReviewSchedule: Codable, Equatable, Sendable {
  /// Days between reviews, box by box. The last box repeats. The evidence singles out no one
  /// schedule, so these numbers are not worth agonizing over.
  static let intervals = [1, 3, 7, 14, 30]

  /// The box of the ladder, from 0, which indexes `intervals`.
  let box: Int
  let due: Date

  /// An item entering the ladder, or sent back to its start: by a lookup, which suggests the verb
  /// was forgotten, or by a wrong answer.
  static func start(at date: Date, calendar: Calendar) -> ReviewSchedule {
    ReviewSchedule(box: 0, due: dueDate(days: intervals[0], after: date, calendar: calendar))
  }

  /// An item never practiced, which a first answer treats as due in the first box: a right one
  /// moves it to the second box, three days on, and a wrong one leaves it in the first, due
  /// tomorrow.
  static func new(at date: Date) -> ReviewSchedule {
    ReviewSchedule(box: 0, due: date)
  }

  func isDue(at date: Date) -> Bool {
    due <= date
  }

  /// The learner recalled the item, so it waits longer next time.
  func reviewed(at date: Date, calendar: Calendar) -> ReviewSchedule {
    let next = min(max(box + 1, 0), Self.intervals.count - 1)
    return ReviewSchedule(box: next, due: Self.dueDate(days: Self.intervals[next], after: date, calendar: calendar))
  }

  /// A quiz's answer. A wrong one starts the item over. A right one moves it up only when it was
  /// due, so that a pattern asked three times in one session does not climb three boxes in an
  /// afternoon, which would defeat the spacing.
  func answered(correctly: Bool, at date: Date, calendar: Calendar) -> ReviewSchedule {
    guard correctly else {
      return Self.start(at: date, calendar: calendar)
    }
    return isDue(at: date) ? reviewed(at: date, calendar: calendar) : self
  }

  /// The review card was dismissed before its conjugations were revealed. That is no review, so
  /// the item keeps its box and returns tomorrow.
  func snoozed(at date: Date, calendar: Calendar) -> ReviewSchedule {
    ReviewSchedule(box: box, due: Self.dueDate(days: 1, after: date, calendar: calendar))
  }

  private static func dueDate(days: Int, after date: Date, calendar: Calendar) -> Date {
    let day = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: days, to: day) ?? day.addingTimeInterval(Double(days) * 86_400)
  }
}
