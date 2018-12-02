//
//  AppDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // https://stackoverflow.com/a/47750574/8248798
    // I like blue and prefer not to override preferredStatusBarStyle in every UIViewController.
    let statusBarKey = "statusBar"
    let statusbar = UIApplication.shared.value(forKey: statusBarKey) as? UIView
    let foregroundColorKey = "foregroundColor"
    statusbar?.setValue(Colors.blue, forKey: foregroundColorKey)

    UINavigationBar.appearance().barTintColor = UIColor.black
    UINavigationBar.appearance().tintColor = Colors.yellow
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): Colors.yellow]

    UITabBar.appearance().barTintColor = UIColor.black
    UITabBar.appearance().tintColor = Colors.yellow

    Utterer.setup(settings: Settings.shared)

    window = UIWindow(frame: UIScreen.main.bounds)

    #if targetEnvironment(simulator)
    let mainTabBarVC = MainTabBarVC(settings: Settings.shared, quiz: Quiz(settings: Settings.shared, shouldShuffle: true), analyticsService: TestAnalyticsService(), reviewPrompter: TestReviewPrompter(), gameCenterManager: TestGameCenterManager())
    #else
    let mainTabBarVC = MainTabBarVC(settings: Settings.shared, quiz: Quiz.shared, analyticsService: AWSAnalyticsService.shared, reviewPrompter: ReviewPrompter.shared, gameCenterManager: GameCenterManager.shared)
    #endif

    window?.rootViewController = mainTabBarVC
    window?.makeKeyAndVisible()

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {}

  func applicationDidEnterBackground(_ application: UIApplication) {}

  func applicationWillEnterForeground(_ application: UIApplication) {}

  func applicationDidBecomeActive(_ application: UIApplication) {}

  func applicationWillTerminate(_ application: UIApplication) {}
}
