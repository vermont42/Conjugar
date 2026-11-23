//
//  ReviewSchedule.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// When a verb is next due on the review card, and which box of the ladder it is in (browse plan,
/// Phase 15, ported from Konjugieren). This is the Leitner system at its smallest: a lookup puts a
/// verb in the first box, a revealed card moves it up one, and a later lookup sends it back to the
/// first. The pedagogy plan's practice record is meant to take it over, moving verbs on right and
/// wrong answers too, so it is a type of its own rather than fields on `LearnerVerbs.Entry`.
///
/// Only irregular verbs are scheduled (Josh, 2026-11-22): a regular verb's key conjugations are
/// the pattern every verb of its class shares, so its lookup has nothing of its own to review.
/// `LearnerVerbs` has no verb map and cannot tell, so its caller decides.
///
/// Due dates fall at the start of a day, so a verb looked up late in the evening waits until the
/// next morning rather than an hour.
nonisolated struct ReviewSchedule: Codable, Equatable, Sendable {
  /// Days between reviews, box by box. The last box repeats. The pedagogy report proposes these
  /// numbers and warns against agonizing over them, since the evidence singles out none.
  static let intervals = [1, 3, 7, 14, 30]

  /// The box of the ladder, from 0, which indexes `intervals`.
  let box: Int
  let due: Date

  /// A verb just looked up, or looked up again, which suggests it was forgotten: Leitner's wrong
  /// answer.
  static func lookedUp(at date: Date, calendar: Calendar) -> ReviewSchedule {
    ReviewSchedule(box: 0, due: dueDate(days: intervals[0], after: date, calendar: calendar))
  }

  func isDue(at date: Date) -> Bool {
    due <= date
  }

  /// The learner revealed the card's conjugations, so the verb waits longer next time.
  func revealed(at date: Date, calendar: Calendar) -> ReviewSchedule {
    let next = min(max(box + 1, 0), Self.intervals.count - 1)
    return ReviewSchedule(box: next, due: Self.dueDate(days: Self.intervals[next], after: date, calendar: calendar))
  }

  /// The card was dismissed before its conjugations were revealed. That is no review, so the verb
  /// keeps its box and returns tomorrow.
  func dismissed(at date: Date, calendar: Calendar) -> ReviewSchedule {
    ReviewSchedule(box: box, due: Self.dueDate(days: 1, after: date, calendar: calendar))
  }

  private static func dueDate(days: Int, after date: Date, calendar: Calendar) -> Date {
    let day = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: days, to: day) ?? day.addingTimeInterval(Double(days) * 86_400)
  }
}
