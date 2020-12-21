//
//  UIApplicationExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 12/17/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit

extension UIApplication {
  class func topViewController(_ base: UIViewController? = UIApplication.shared.compatibilityWindow?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      if let selected = tab.selectedViewController {
        return topViewController(selected)
      }
    }
    if let presented = base?.presentedViewController {
      return topViewController(presented)
    }
    return base
  }

  // https://stackoverflow.com/a/57169802/8248798
  var compatibilityWindow: UIWindow? {
    return UIApplication.shared.connectedScenes
    .filter({$0.activationState == .foregroundActive})
    .map({$0 as? UIWindowScene})
    .compactMap({$0})
    .first?.windows
    .filter({$0.isKeyWindow}).first
  }
}
