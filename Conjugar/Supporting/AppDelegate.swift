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
  // so this no longer creates one; it sets the one global UIKit appearance the
  // SwiftUI screens still rely on and handles the UI-test-World override.
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    configureSegmentedControlAppearance()

    let uiTestingFlag = "enable-ui-testing"
    if CommandLine.arguments.contains(uiTestingFlag) {
      Current = World.uiTest(launchArguments: CommandLine.arguments)
    }

    Utterer.setup(settings: Current.settings)

    return true
  }

  // The empty lifecycle hooks and `applicationDidBecomeActive` were removed in
  // Phase 4 / item 4: under the SwiftUI scene lifecycle UIKit delivers activation
  // to the scene, not the app delegate, so those callbacks never fired. The
  // became-active analytics now ride `MainTabView`'s `scenePhase == .active`
  // observer, which actually runs.

  // Conjugar styles its segmented controls (Browse/Models sort, Settings pickers) with
  // yellow titles — the one global UIKit appearance the SwiftUI screens still rely on.
  // Set once at launch (item 13) rather than from `SettingsView.init`, which re-ran it
  // on every `MainTabView` body evaluation. The pre-iOS-13 tab-/nav-bar `barTintColor`
  // + `tintColor` + `titleTextAttributes` config that used to live here was verified
  // inert on iOS 26's Liquid-Glass bars (selected tab stayed system-blue, large titles
  // and the back chevron stayed default) and removed.
  private func configureSegmentedControlAppearance() {
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .selected)
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .normal)
  }
}
