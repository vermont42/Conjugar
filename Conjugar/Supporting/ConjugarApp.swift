//
//  ConjugarApp.swift
//  Conjugar
//
//  Created during the SwiftUI migration, July 2026, replacing the custom
//  main.swift (UIApplicationMain + NSClassFromString("TestingAppDelegate")).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

// The App-lifecycle equivalent of the old main.swift's TestingAppDelegate trick:
// under XCTest we launch a minimal placeholder scene instead of the full UI, so
// the test bundle drives an app process that isn't racing the real UI. The
// `Current = World.unitTest` selection now lives in `World.chooseWorld()`.
@main
enum AppLauncher {
  static func main() {
    if NSClassFromString("XCTestCase") == nil {
      ConjugarApp.main()
    } else {
      TestApp.main()
    }
  }
}

struct ConjugarApp: App {
  // Kept only for the delegate hooks the App lifecycle doesn't cover: UIKit
  // appearance config, the UI-test-World launch-argument override, and
  // Utterer setup / became-active analytics.
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      MainTabView()
    }
  }
}

struct TestApp: App {
  var body: some Scene {
    WindowGroup {
      Text(verbatim: "Running unit tests…")
    }
  }
}
