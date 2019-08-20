//
//  AppDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit
import Swinject

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    configureTabBar()
    configureNavBar()
    configureStatusBar()

    let uiTestingFlag = "enable-ui-testing"
    if CommandLine.arguments.contains(uiTestingFlag) {
      GlobalContainer.registerUITestingDependencies(launchArguments: CommandLine.arguments)
    } else {
      #if targetEnvironment(simulator)
        GlobalContainer.registerSimulatorDependencies()
      #else
        GlobalContainer.registerDeviceDependencies()
      #endif
    }

    Utterer.setup(settings: GlobalContainer.settings)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = MainTabBarVC()
    window?.makeKeyAndVisible()

    return true
  }

  private func configureStatusBar() {
    // I like blue and prefer not to override preferredStatusBarStyle in every UIViewController.
    let statusBarKey = "statusBar"
    let statusbar = UIApplication.shared.value(forKey: statusBarKey) as? UIView
    let foregroundColorKey = "foregroundColor"
    statusbar?.setValue(Colors.blue, forKey: foregroundColorKey)
  }

  private func configureTabBar() {
    UITabBar.appearance().barTintColor = UIColor.black
    UITabBar.appearance().tintColor = Colors.yellow
  }

  private func configureNavBar() {
    UINavigationBar.appearance().barTintColor = UIColor.black
    UINavigationBar.appearance().tintColor = Colors.yellow
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): Colors.yellow]
  }

  func applicationWillResignActive(_ application: UIApplication) {}

  func applicationDidEnterBackground(_ application: UIApplication) {}

  func applicationWillEnterForeground(_ application: UIApplication) {}

  func applicationDidBecomeActive(_ application: UIApplication) {
    GlobalContainer.analytics.recordBecameActive()
  }

  func applicationWillTerminate(_ application: UIApplication) {}
}
