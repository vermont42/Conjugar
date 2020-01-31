//
//  TestingAppDelegate.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 1/31/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit
@testable import Conjugar

@objc(TestingAppDelegate)
final class TestingAppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Current = World.unitTest
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = TestingRootViewController()
    window?.makeKeyAndVisible()
    return true
  }
}
