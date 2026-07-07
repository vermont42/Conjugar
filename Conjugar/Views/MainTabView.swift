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
  @State private var router = AppRouter()
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    TabView(selection: $router.selectedTab) {
      VerbBrowseView()
        .tabItem { Label(L.BrowseVerbs.localizedTitle, image: "Browse") }
        .tag(AppTab.browseVerbs)

      ModelBrowseView()
        .tabItem { Label(L.BrowseModels.localizedTitle, systemImage: "key.fill") }
        .tag(AppTab.models)

      QuizView()
        .tabItem { Label(L.Quiz.localizedTitle, image: "Quiz") }
        .tag(AppTab.quiz)

      InfoBrowseView()
        .tabItem { Label(L.BrowseInfo.localizedTitle, image: "Info") }
        .tag(AppTab.info)

      SettingsView()
        .tabItem { Label(L.Settings.localizedTitle, image: "Settings") }
        .tag(AppTab.settings)
    }
    .environment(router)
    .task {
      // Widgets show today's verb/quiz; clean up any Live Activity left by a prior run.
      LiveActivityManager.endAll()
      // Off-main (item 14): refresh() parses verbModelMap.xml + runs ~50 conjugations;
      // everything it touches is nonisolated/Sendable, so it belongs off the launch path.
      Task.detached { WidgetSnapshotWriter.refresh() }
      await presentCommunIfNeeded()
    }
    .onOpenURL { router.handle(url: $0) }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      // The scene lifecycle — not AppDelegate.applicationDidBecomeActive, which
      // never fires under WindowGroup — is where became-active analytics live now
      // (Phase 4 / item 4).
      Current.analytics.recordBecameActive()
      Task.detached { WidgetSnapshotWriter.refresh() }
      drainPendingDeeplink()
    }
    .fullScreenCover(item: $commun) { commun in
      CommunView(commun: commun) { self.commun = nil }
    }
  }

  /// Control-center controls can't navigate, so they stash a deeplink in the shared
  /// defaults suite; drain and route it when the app next becomes active.
  private func drainPendingDeeplink() {
    guard
      let defaults = WidgetConstants.sharedDefaults,
      let deeplink = defaults.string(forKey: WidgetConstants.pendingDeeplinkKey),
      let url = URL(string: deeplink)
    else {
      return
    }
    defaults.removeObject(forKey: WidgetConstants.pendingDeeplinkKey)
    router.handle(url: url)
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
