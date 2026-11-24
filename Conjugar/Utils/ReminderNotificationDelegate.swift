//
//  ReminderNotificationDelegate.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import UserNotifications

/// Opens a tapped reminder's link, which starts a daily session. A reminder due while the app is
/// open shows nothing, since the Quiz tab already offers the session.
final class ReminderNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  static let shared = ReminderNotificationDelegate()

  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    guard let link = response.notification.request.content.userInfo[ReminderSchedulerReal.deeplinkKey] as? String,
          let url = URL(string: link) else {
      return
    }
    await MainActor.run {
      AppRouter.shared.handle(url: url)
    }
  }

  nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    []
  }
}
