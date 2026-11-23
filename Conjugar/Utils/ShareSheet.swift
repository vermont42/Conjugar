//
//  ShareSheet.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import LinkPresentation
import UIKit

// Workaround, ported from Konjugieren (its Phase 10, 2026-11-12): SwiftUI's ShareLink cannot
// serve the verb page. In a toolbar it reports no tap, so neither a gesture on it nor one on its
// label can send tapShareVerb, and giving it a SharePreview for the sheet's header drops Copy from
// the sheet (both seen on the iOS 26.3 simulator). UIActivityViewController keeps Copy and takes
// its header from LPLinkMetadata.
enum ShareSheet {
  /// Presents the system share sheet over whatever is on screen. On iPad the sheet is a popover,
  /// anchored to the bar button whose accessibility label or title is `anchorLabel`, when one is
  /// found, and otherwise to the top of the window.
  static func present(text: String, title: String, icon: UIImage?, anchorLabel: String) {
    guard
      let window = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap(\.windows)
        .first(where: \.isKeyWindow),
      var presenter = window.rootViewController
    else {
      return
    }
    while let presented = presenter.presentedViewController {
      presenter = presented
    }

    let source = ShareTextSource(text: text, title: title, icon: icon)
    let controller = UIActivityViewController(activityItems: [source], applicationActivities: nil)
    if let popover = controller.popoverPresentationController {
      if let item = barButtonItem(labeled: anchorLabel, in: presenter) {
        popover.sourceItem = item
      } else {
        popover.sourceView = window
        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.safeAreaInsets.top, width: 1, height: 1)
      }
    }
    presenter.present(controller, animated: true)
  }

  /// Searches only what is on screen: the selected tab and the top of each navigation stack,
  /// since a verb page in another tab, or under this one in the stack, has its own share button.
  private static func barButtonItem(labeled label: String, in controller: UIViewController) -> UIBarButtonItem? {
    let navigationItem = controller.navigationItem
    let items = (navigationItem.rightBarButtonItems ?? []) + (navigationItem.leftBarButtonItems ?? [])
      + navigationItem.trailingItemGroups.flatMap(\.barButtonItems)
      + navigationItem.leadingItemGroups.flatMap(\.barButtonItems)
    if let item = items.first(where: { $0.accessibilityLabel == label || $0.title == label }) {
      return item
    }
    let visibleChildren: [UIViewController]
    if let tabBarController = controller as? UITabBarController {
      visibleChildren = tabBarController.selectedViewController.map { [$0] } ?? []
    } else if let navigationController = controller as? UINavigationController {
      visibleChildren = navigationController.topViewController.map { [$0] } ?? []
    } else {
      visibleChildren = controller.children
    }
    for child in visibleChildren {
      if let item = barButtonItem(labeled: label, in: child) {
        return item
      }
    }
    return nil
  }
}

private final class ShareTextSource: NSObject, UIActivityItemSource {
  let text: String
  let title: String
  let icon: UIImage?

  init(text: String, title: String, icon: UIImage?) {
    self.text = text
    self.title = title
    self.icon = icon
  }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    text
  }

  func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    text
  }

  func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
    title
  }

  func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
    let metadata = LPLinkMetadata()
    metadata.title = title
    if let icon {
      metadata.iconProvider = NSItemProvider(object: icon)
    }
    return metadata
  }
}
