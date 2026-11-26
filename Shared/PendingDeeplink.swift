//
//  PendingDeeplink.swift
//  Conjugar
//
//  A link that an intent leaves for the app in the App Group's defaults, with the time it was left.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import notify

/// The stash through which the controls and the shortcuts in Shared open a page. An intent cannot
/// navigate, so it writes its link here and announces it, and the app routes it: when the
/// announcement arrives, which reaches an app already in front, and when the scene becomes active.
/// Whichever drains first routes it, and the other finds nothing. A stash older than
/// `lifetime` is removed unopened, so that a link the app missed cannot open, days later, a random
/// verb or a quiz that nobody asked for.
nonisolated enum PendingDeeplink {
  /// How long a stashed link stays good.
  static let lifetime: TimeInterval = 60

  /// The Darwin notification an intent posts after stashing, which reaches every process.
  static let announcementName = "biz.joshadams.Conjugar.pendingDeeplink"

  private static let urlKey = "url"
  private static let dateKey = "date"

  /// Leaves `url` for the app, written at `date`, in place of any link already waiting.
  static func stash(_ url: URL, in defaults: UserDefaults?, at date: Date = .now) {
    defaults?.set(
      [urlKey: url.absoluteString, dateKey: date.timeIntervalSinceReferenceDate],
      forKey: WidgetConstants.pendingDeeplinkKey
    )
  }

  /// Removes what is waiting and returns its link if it was written within `lifetime` of `now`.
  /// A stash without a date, as builds before 2026-11-26 wrote it, is removed unopened.
  static func drain(from defaults: UserDefaults?, at now: Date = .now) -> URL? {
    guard let defaults, let stored = defaults.object(forKey: WidgetConstants.pendingDeeplinkKey) else {
      return nil
    }
    defaults.removeObject(forKey: WidgetConstants.pendingDeeplinkKey)
    guard
      let stash = stored as? [String: Any],
      let link = stash[urlKey] as? String,
      let written = stash[dateKey] as? TimeInterval,
      let url = URL(string: link),
      abs(now.timeIntervalSinceReferenceDate - written) <= lifetime
    else {
      return nil
    }
    return url
  }

  /// Tells the app, in whatever process it runs, that a link is waiting.
  static func announce() {
    notify_post(announcementName)
  }

  /// One element per announcement, on the main queue, until the stream's task is cancelled.
  static func announcements() -> AsyncStream<Void> {
    AsyncStream { continuation in
      var token: Int32 = 0
      let status = notify_register_dispatch(announcementName, &token, .main) { _ in
        continuation.yield()
      }
      guard status == NOTIFY_STATUS_OK else {
        continuation.finish()
        return
      }
      let registration = token
      continuation.onTermination = { _ in
        notify_cancel(registration)
      }
    }
  }
}
