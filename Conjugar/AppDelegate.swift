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

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    configureTabBar()
    configureNavBar()
    configureStatusBar()

    let mainTabBarVC: MainTabBarVC
    let settings: Settings

    if CommandLine.arguments.contains("enable-ui-testing") {
      settings = Settings(getterSetter: DictionaryGetterSetter())

      if CommandLine.arguments.contains(Region.spain.rawValue) {
        settings.region = .spain
      } else if CommandLine.arguments.contains(Region.latinAmerica.rawValue) {
        settings.region = .latinAmerica
      }

      if CommandLine.arguments.contains(Difficulty.difficult.rawValue) {
        settings.difficulty = .difficult
      } else if CommandLine.arguments.contains(Difficulty.moderate.rawValue) {
        settings.difficulty = .moderate
      } else if CommandLine.arguments.contains(Difficulty.easy.rawValue) {
        settings.difficulty = .easy
      }

      mainTabBarVC = MainTabBarVC(settings: settings, quiz: Quiz(settings: settings, gameCenter: TestGameCenter(), shouldShuffle: false), analyticsService: TestAnalyticsService(), reviewPrompter: TestReviewPrompter(), gameCenter: TestGameCenter())
    } else {
      settings = Settings(getterSetter: UserDefaultsGetterSetter())
      #if targetEnvironment(simulator)
      let testGameCenter = TestGameCenter()
      mainTabBarVC = MainTabBarVC(settings: settings, quiz: Quiz(settings: settings, gameCenter: testGameCenter, shouldShuffle: true), analyticsService: TestAnalyticsService(), reviewPrompter: TestReviewPrompter(), gameCenter: testGameCenter)
      #else
      mainTabBarVC = MainTabBarVC(settings: settings, quiz: Quiz.shared, analyticsService: AWSAnalyticsService.shared, reviewPrompter: ReviewPrompter.shared, gameCenter: GameCenter.shared)
      #endif
    }

    Utterer.setup(settings: settings)
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = mainTabBarVC
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

  func applicationDidBecomeActive(_ application: UIApplication) {}

  func applicationWillTerminate(_ application: UIApplication) {}
}
