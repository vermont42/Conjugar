//
//  CalendarDay.swift
//  Conjugar
//
//  Shared between the app and the ConjugarWidget extension.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A day as the learner's own calendar names it: `yyyy-MM-dd` in the Gregorian calendar and the
/// current time zone. The daily challenge, its links, and the widgets' days all name a day this
/// way, so that a learner whose calendar setting is Buddhist or Japanese still names the day a link
/// does, and the widget and the app agree on which day an entry is for.
nonisolated enum CalendarDay {
  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  static func string(for date: Date) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
  }

  /// Noon of a `yyyy-MM-dd` day, or nil for text that names no day.
  static func noon(of day: String) -> Date? {
    let parts = day.split(separator: "-", omittingEmptySubsequences: false)
    guard
      parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
      let year = Int(parts[0]), let month = Int(parts[1]), let dayOfMonth = Int(parts[2]),
      let date = calendar.date(from: DateComponents(year: year, month: month, day: dayOfMonth, hour: 12)),
      string(for: date) == day
    else {
      return nil
    }
    return date
  }

  /// The first instant of a `yyyy-MM-dd` day, or nil for text that names no day.
  static func start(of day: String) -> Date? {
    noon(of: day).map { calendar.startOfDay(for: $0) }
  }

  /// The first instant of the day after the date's.
  static func nextMidnight(after date: Date) -> Date {
    let startOfDay = calendar.startOfDay(for: date)
    // A calendar day, not 86,400 seconds, so that the rollover lands on midnight on a
    // daylight-saving day.
    return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86_400)
  }
}
