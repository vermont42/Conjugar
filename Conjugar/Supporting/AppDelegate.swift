//
//  AppDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
  // Retained under @UIApplicationDelegateAdaptor for the hooks the App lifecycle doesn't
  // cover. SwiftUI's WindowGroup owns the window; this sets the one global UIKit appearance
  // the SwiftUI screens rely on, handles the UI-test-World override, installs and receives the
  // Home Screen quick action (see QuickAction.swift), and names the delegate that opens a tapped
  // daily reminder.
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    configureSegmentedControlAppearance()

    let uiTestingFlag = "enable-ui-testing"
    if CommandLine.arguments.contains(uiTestingFlag) {
      Current = World.uiTest(launchArguments: CommandLine.arguments)
    }

    // Order matters: Utterer configures the shared AVAudioSession (`.ambient`); the
    // sound player then warms the audio stack off-main against that session.
    Utterer.setup(settings: Current.settings)
    Current.soundPlayer.setup()

    QuickAction.install()
    UNUserNotificationCenter.current().delegate = ReminderNotificationDelegate.shared

    return true
  }

  // Names the scene delegate that receives Home Screen quick actions, for which SwiftUI has no
  // hook. SwiftUI still builds and owns the window.
  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    configuration.delegateClass = QuickActionSceneDelegate.self
    return configuration
  }

  // Conjugar styles its segmented controls (Browse/Models sort, Settings pickers) with
  // yellow titles, the one global UIKit appearance the SwiftUI screens rely on. Set once at
  // launch, not from `SettingsView.init`, which runs on every `MainTabView` body evaluation.
  private func configureSegmentedControlAppearance() {
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .selected)
    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: Colors.yellow], for: .normal)
  }
}
