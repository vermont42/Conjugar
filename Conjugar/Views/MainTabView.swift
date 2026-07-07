//
//  MainTabView.swift
//  Conjugar
//
//  The SwiftUI-first app shell that replaces the UIKit MainTabBarVC, created
//  during the SwiftUI migration, July 2026. As of the Step 4 completion every tab
//  is a native SwiftUI screen; the transitional UIKit-hosting wrapper is gone.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  @State private var commun: Commun?

  var body: some View {
    TabView {
      VerbBrowseView()
        .tabItem { Label(L.BrowseVerbs.localizedTitle, image: "Browse") }

      ModelBrowseView()
        .tabItem { Label(L.BrowseModels.localizedTitle, systemImage: "key.fill") }

      QuizView()
        .tabItem { Label(L.Quiz.localizedTitle, image: "Quiz") }

      InfoBrowseView()
        .tabItem { Label(L.BrowseInfo.localizedTitle, image: "Info") }

      SettingsView()
        .tabItem { Label(L.Settings.localizedTitle, image: "Settings") }
    }
    .task { await presentCommunIfNeeded() }
    .fullScreenCover(item: $commun) { commun in
      CommunView(commun: commun) { self.commun = nil }
    }
  }

  /// The launch-time "new communication" presentation MainTabBarVC used to do in
  /// viewDidLoad: fetch the latest commun and present it once if it is newer than
  /// the last one shown and no quiz is in progress.
  private func presentCommunIfNeeded() async {
    guard let commun = await Current.communGetter.getCommunication() else { return }
    guard Current.quiz.quizState != .inProgress,
          commun.identifier > Current.settings.lastCommunIdentifierShown else { return }
    Current.settings.lastCommunIdentifierShown = commun.identifier
    self.commun = commun
  }
}
