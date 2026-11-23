//
//  ConjugarApp.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

// Under XCTest we launch a minimal placeholder scene instead of the full UI, so the test
// bundle drives an app process that isn't racing the real UI. `World.chooseWorld()`
// selects `World.unitTest`.
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
  // Held here rather than by MainTabView so that a menu command, such as Command-F, can route,
  // and shared so that the Home Screen quick action's scene delegate can too.
  @State private var router = AppRouter.shared

  init() {
    // The TelemetryDeck app ID is kept out of the working tree: it lives in the
    // gitignored Conjugar/Secrets.xcconfig as TELEMETRY_DECK_APP_ID, is surfaced
    // through the TelemetryDeckAppID Info.plist key, and is read here. A missing
    // or empty value leaves AnalyticsReal uninitialized, so it drops every signal
    // rather than crashing — a fresh clone without Secrets.xcconfig still builds.
    let appID = Bundle.main.infoDictionary?["TelemetryDeckAppID"] as? String ?? ""
    Current.analytics.initialize(appID: appID)
    // Before any view can start a quiz of its own, whose entry this would report.
    QuizAbandonment.reportAndClear(getterSetter: Current.getterSetter, analytics: Current.analytics)

    // TipKit shows nothing until configured, so the `tipsEnabled` kill switch —
    // flipped off before capturing screenshots — hides every tip app-wide with no
    // per-call-site changes. Configured here (only the real app, never TestApp, is
    // launched by AppLauncher), so the unit-test process never touches TipKit.
    if TipDisplay.tipsEnabled {
      try? Tips.configure()
    }
  }

  var body: some Scene {
    WindowGroup {
      MainTabView(router: router)
    }
    .commands {
      VerbSearchCommands(router: router)
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
