//
//  ReminderScheduler.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Schedules the daily reminders with the system. `ReminderSchedulerReal` uses the notification
/// center, and `ReminderSchedulerSpy` records under unit tests.
protocol ReminderScheduler {
  /// Asks for permission to notify, which the system asks the learner only once. False when it was
  /// refused, now or before.
  func requestAuthorization() async -> Bool
  /// Whether notifications are allowed, which the learner can change in the Settings app.
  func isAuthorized() async -> Bool
  /// Replaces every scheduled reminder with these.
  func schedule(_ reminders: [ScheduledReminder])
}
