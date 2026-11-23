//
//  QuickAction.swift
//  Conjugar
//
//  The Home Screen quick actions, shown on a long press of the app icon (browse plan, Phase 10).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

/// Each quick action opens a `conjugar://` link, so that it reaches the app by the same road as
/// a widget or a control. They are installed at launch rather than declared in Info.plist, so
/// that their titles come from the string catalog like every other string.
enum QuickAction: String, CaseIterable {
  /// Opens the verb search, empty and focused, as the Find a Verb control and Command-F do, and
  /// shares Command-F's title.
  case findVerb = "biz.joshadams.Conjugar.findVerb"

  var item: UIApplicationShortcutItem {
    switch self {
    case .findVerb:
      return UIApplicationShortcutItem(
        type: rawValue,
        localizedTitle: L.BrowseVerbs.findVerb,
        localizedSubtitle: nil,
        icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass")
      )
    }
  }

  var deeplink: URL? {
    switch self {
    case .findVerb:
      return URL.searchDeeplink(text: "", source: .quickAction)
    }
  }

  /// Run at every launch, so that a change of language retitles the item.
  static func install() {
    UIApplication.shared.shortcutItems = allCases.map(\.item)
  }

  /// Routes the item's link, and says whether the item was one of these.
  static func perform(_ item: UIApplicationShortcutItem, router: AppRouter) -> Bool {
    guard let url = QuickAction(rawValue: item.type)?.deeplink else {
      return false
    }
    router.handle(url: url)
    return true
  }
}

/// SwiftUI offers no hook for quick actions, which UIKit delivers to the scene delegate.
/// `AppDelegate` names this class as the scene's delegate; SwiftUI still manages the window, and
/// `.onOpenURL` still receives links.
final class QuickActionSceneDelegate: NSObject, UIWindowSceneDelegate {
  /// A quick action that launched the app arrives here, not in the method below.
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let item = connectionOptions.shortcutItem {
      _ = QuickAction.perform(item, router: .shared)
    }
  }

  func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    completionHandler(QuickAction.perform(shortcutItem, router: .shared))
  }
}
