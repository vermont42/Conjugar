//
//  ReminderSchedulerReal.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import UserNotifications

/// Schedules the daily reminders as local notifications. Each carries the link that starts a daily
/// session, which `ReminderNotificationDelegate` opens when the reminder is tapped.
final class ReminderSchedulerReal: ReminderScheduler {
  nonisolated static let deeplinkKey = "deeplink"

  func requestAuthorization() async -> Bool {
    (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
  }

  func isAuthorized() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .ephemeral, .provisional:
      return true
    case .denied, .notDetermined:
      return false
    @unknown default:
      return false
    }
  }

  func schedule(_ reminders: [ScheduledReminder]) {
    let link = URL.dailySessionDeeplink(source: .reminder)?.absoluteString ?? ""
    let requests = reminders.map { reminder in
      let content = UNMutableNotificationContent()
      content.title = reminder.title
      content.body = reminder.body
      content.sound = .default
      content.userInfo = [Self.deeplinkKey: link]
      let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
      return UNNotificationRequest(
        identifier: reminder.identifier,
        content: content,
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      )
    }
    Task {
      let center = UNUserNotificationCenter.current()
      let pending = await center.pendingNotificationRequests()
        .map(\.identifier)
        .filter { $0.hasPrefix(DailyReminderPlan.identifierPrefix) }
      center.removePendingNotificationRequests(withIdentifiers: pending)
      for request in requests {
        try? await center.add(request)
      }
    }
  }
}
