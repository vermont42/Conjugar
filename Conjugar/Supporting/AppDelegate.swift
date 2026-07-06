//
//  AppDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
  // Retained under @UIApplicationDelegateAdaptor for the hooks the App
  // lifecycle doesn't cover. The window is now owned by SwiftUI's WindowGroup,
  // so this no longer creates one; it only styles the shared UIKit appearance
  // (which still applies to the SwiftUI TabView and the wrapped UIKit VCs) and
  // handles the UI-test-World override.
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    configureTabBar()
    configureNavBar()

    let uiTestingFlag = "enable-ui-testing"
    if CommandLine.arguments.contains(uiTestingFlag) {
      Current = World.uiTest(launchArguments: CommandLine.arguments)
    }

    Utterer.setup(settings: Current.settings)

    return true
  }

  private func configureTabBar() {
    UITabBar.appearance().barTintColor = Colors.background
    UITabBar.appearance().tintColor = Colors.yellow
  }

  private func configureNavBar() {
    UINavigationBar.appearance().barTintColor = Colors.background
    UINavigationBar.appearance().tintColor = Colors.yellow
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): Colors.yellow]
  }

  func applicationWillResignActive(_ application: UIApplication) {}

  func applicationDidEnterBackground(_ application: UIApplication) {}

  func applicationWillEnterForeground(_ application: UIApplication) {}

  func applicationDidBecomeActive(_ application: UIApplication) {
    Current.analytics.recordBecameActive()
  }

  func applicationWillTerminate(_ application: UIApplication) {}
}
