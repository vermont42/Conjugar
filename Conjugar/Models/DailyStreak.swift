//
//  DailyStreak.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The daily session's streak: the days on which the learner finished a daily session, and how
/// many each day. It is kept on the device beside the practice record and sent nowhere but as a
/// band.
///
/// A streak broken by one missed day is repaired by finishing two daily sessions the following day,
/// since a broken streak lowers later engagement unless it can be repaired. The missed day does not
/// count toward the length, which is the days practiced.
nonisolated struct DailyStreak: Codable, Equatable, Sendable {
  /// What the streak is on a day, before or after that day's sessions.
  enum Status: Equatable, Sendable {
    /// No streak: nothing finished yesterday or today, and none to repair.
    case none
    case active(length: Int, isDoneToday: Bool)
    /// Yesterday was missed. Two sessions today keep `length`, and `sessionsToday` have been
    /// finished.
    case repairable(length: Int, sessionsToday: Int)

    /// The streak a learner sees: the one kept, or the one at stake.
    var length: Int {
      switch self {
      case .none:
        return 0
      case let .active(length, _), let .repairable(length, _):
        return length
      }
    }

    /// Whether one more session today would keep the streak, which the results offer.
    var awaitsRepairSession: Bool {
      if case let .repairable(_, sessionsToday) = self {
        return sessionsToday > 0
      }
      return false
    }
  }

  static let storageKey = "dailyStreak"
  /// Sessions on the day after a missed day that repair the streak.
  static let repairSessionCount = 2

  /// Finished daily sessions by day, keyed `2026-11-24` in the learner's calendar.
  private(set) var sessions: [String: Int] = [:]

  init() {}

  init?(json: String) {
    guard let data = json.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(DailyStreak.self, from: data) else {
      return nil
    }
    self = decoded
  }

  var json: String? {
    (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
  }

  var isEmpty: Bool {
    sessions.isEmpty
  }

  /// A daily session finished at `date`. Days that can no longer change the streak are dropped.
  mutating func recordSession(at date: Date, calendar: Calendar = .current) {
    sessions[Self.dayKey(date, calendar: calendar), default: 0] += 1
    prune(calendar: calendar)
  }

  func status(at date: Date, calendar: Calendar = .current) -> Status {
    let today = Self.dayNumber(date, calendar: calendar)
    let past = sessions.filter { Self.dayNumber(key: $0.key, calendar: calendar).map { $0 <= today } ?? false }
    let runs = Self.runs(of: past, calendar: calendar)
    guard let last = runs.last, let lastDay = last.days.last else {
      return .none
    }
    let countToday = lastDay == today ? sessions[Self.dayKey(date, calendar: calendar)] ?? 0 : 0
    switch today - lastDay {
    case 0:
      // One session on the day after a missed day starts a run of its own until a second
      // repairs the one before.
      if last.length == 1, countToday < Self.repairSessionCount, runs.count > 1,
         let previousDay = runs[runs.count - 2].days.last, today - previousDay == 2 {
        return .repairable(length: runs[runs.count - 2].length, sessionsToday: countToday)
      }
      return .active(length: last.length, isDoneToday: true)
    case 1:
      return .active(length: last.length, isDoneToday: false)
    case 2:
      return .repairable(length: last.length, sessionsToday: 0)
    default:
      return .none
    }
  }

  /// A run of days, each a day or, by a repair, two after the one before.
  private struct Run {
    var days: [Int]
    var length: Int
  }

  /// The runs of `sessions`, oldest first. A day joins the run before it when it follows its last
  /// day, or follows a missed day with two sessions.
  private static func runs(of sessions: [String: Int], calendar: Calendar) -> [Run] {
    let days = sessions.compactMap { key, count in
      dayNumber(key: key, calendar: calendar).map { (day: $0, sessionCount: count) }
    }
    .sorted { $0.day < $1.day }
    var runs: [Run] = []
    for entry in days where entry.sessionCount > 0 {
      if var run = runs.last, let lastDay = run.days.last {
        let gap = entry.day - lastDay
        if gap == 1 || (gap == 2 && entry.sessionCount >= repairSessionCount) {
          run.days.append(entry.day)
          run.length += 1
          runs[runs.count - 1] = run
          continue
        }
      }
      runs.append(Run(days: [entry.day], length: 1))
    }
    return runs
  }

  /// Keeps the last two runs, since a run can be joined only to the one just before it, and a run
  /// before that is broken for good.
  private mutating func prune(calendar: Calendar) {
    let runs = Self.runs(of: sessions, calendar: calendar)
    guard runs.count > 2, let firstKept = runs[runs.count - 2].days.first else {
      return
    }
    sessions = sessions.filter { (Self.dayNumber(key: $0.key, calendar: calendar) ?? .min) >= firstKept }
  }

  static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
  }

  /// Days since a fixed day, so that two days' difference is a subtraction. Counted in the
  /// calendar's days, not in hours, so that a day of 23 or 25 hours is still one day.
  private static func dayNumber(_ date: Date, calendar: Calendar) -> Int {
    calendar.dateComponents([.day], from: epoch(calendar), to: calendar.startOfDay(for: date)).day ?? 0
  }

  private static func dayNumber(key: String, calendar: Calendar) -> Int? {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3, let date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) else {
      return nil
    }
    return dayNumber(date, calendar: calendar)
  }

  private static func epoch(_ calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date(timeIntervalSince1970: 946_684_800)
  }
}
