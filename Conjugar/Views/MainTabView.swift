//
//  MainTabView.swift
//  Conjugar
//
//  The SwiftUI-first app shell that replaces the UIKit MainTabBarVC, created
//  during the SwiftUI migration, July 2026. Every tab except Settings still
//  hosts its not-yet-migrated UIKit VC via a UIViewControllerRepresentable;
//  those wrappers disappear one at a time as each screen is migrated (Step 4).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

struct MainTabView: View {
  var body: some View {
    TabView {
      VerbBrowseView()
        .tabItem { Label(L.BrowseVerbs.localizedTitle, image: "Browse") }

      NavHostedVC { BrowseModelsVC() }
        .ignoresSafeArea()
        .tabItem { Label(L.BrowseModels.localizedTitle, systemImage: "key.fill") }

      NavHostedVC { QuizVC() }
        .ignoresSafeArea()
        .tabItem { Label(L.Quiz.localizedTitle, image: "Quiz") }

      InfoBrowseView()
        .tabItem { Label(L.BrowseInfo.localizedTitle, image: "Info") }

      SettingsView()
        .tabItem { Label(L.Settings.localizedTitle, image: "Settings") }
    }
    // NOTE: the launch-time "new communication" presentation that MainTabBarVC
    // did in viewDidLoad (present CommunVC when a newer commun exists and no
    // quiz is in progress) is intentionally deferred until CommunVC is migrated
    // to SwiftUI in Step 4, rather than bridging a self-dismissing UIKit modal
    // into a SwiftUI cover for a screen about to be rewritten.
  }
}

/// Transitional bridge: hosts a not-yet-migrated UIKit view controller — wrapped
/// in a UINavigationController so its `pushViewController` navigation keeps
/// working — inside a SwiftUI tab. Each of these is retired as its screen is
/// migrated to a native SwiftUI `NavigationStack` in Step 4.
struct NavHostedVC<VC: UIViewController>: UIViewControllerRepresentable {
  let make: () -> VC

  func makeUIViewController(context: Context) -> UINavigationController {
    UINavigationController(rootViewController: make())
  }

  func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
