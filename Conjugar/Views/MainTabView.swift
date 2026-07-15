//
//  MainTabView.swift
//  Conjugar
//
//  The SwiftUI-first app shell that replaces the UIKit MainTabBarVC, created
//  during the SwiftUI migration, July 2026. Every tab is a native SwiftUI screen;
//  the transitional UIKit-hosting wrapper is gone.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  @State private var commun: Commun?
  @State private var router = AppRouter()
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    TabView(selection: $router.selectedTab) {
      // Tab(_:image:value:) builders (iOS 18+) replace the soft-deprecated
      // .tabItem/.tag pair. Models/Info/Settings are stock SF
      // Symbols; the dancer (Browse) and bull (Quiz) are still custom line-art bitmaps.
      // Tab bars auto-substitute the .fill variant of an SF Symbol, which would clash
      // with the outline dancer/bull — so the three symbol tabs use the explicit-label
      // Tab(value:content:label:) form and pin `.symbolVariants(.none)` on the Label
      // (the TabView-level environment doesn't reach the tab-bar chrome) to hold the
      // whole bar to one outline family. Browse/Quiz use custom symbol sets ("dancer"/
      // "bull", spliced from Noun Project line art into an SF Symbols template): custom
      // symbols take `image:`, not `systemImage:`, and aren't auto-filled, so they render
      // their line art as-is and need no symbolVariants override.
      Tab(L.BrowseVerbs.localizedTitle, image: "dancer", value: AppTab.browseVerbs) {
        VerbBrowseView()
      }

      Tab(value: AppTab.models) {
        ModelBrowseView()
      } label: {
        Label(L.BrowseModels.localizedTitle, systemImage: "key")
          .environment(\.symbolVariants, .none)
      }

      Tab(L.Quiz.localizedTitle, image: "bull", value: AppTab.quiz) {
        QuizView()
      }

      Tab(value: AppTab.info) {
        InfoBrowseView()
      } label: {
        Label(L.BrowseInfo.localizedTitle, systemImage: "info.circle")
          .environment(\.symbolVariants, .none)
      }

      Tab(value: AppTab.settings) {
        SettingsView(router: router)
      } label: {
        Label(L.Settings.localizedTitle, systemImage: "gearshape")
          .environment(\.symbolVariants, .none)
      }
    }
    .environment(router)
    .task {
      // Widgets show today's verb/quiz; clean up any Live Activity left by a prior run.
      LiveActivityManager.endAll()
      // Off-main: refresh() parses verbModelMap.xml + runs ~50 conjugations;
      // everything it touches is nonisolated/Sendable, so it belongs off the launch path.
      Task.detached { WidgetSnapshotWriter.refresh() }
      // First-launch onboarding wins the launch-time cover; skip the commun prompt this
      // launch so two covers don't contend for the anchor.
      guard !presentOnboardingIfNeeded() else { return }
      await presentCommunIfNeeded()
    }
    .onOpenURL { router.handle(url: $0) }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      // The scene lifecycle — not AppDelegate.applicationDidBecomeActive, which
      // never fires under WindowGroup — is where became-active analytics live now.
      Current.analytics.recordBecameActive()
      Task.detached { WidgetSnapshotWriter.refresh() }
      drainPendingDeeplink()
    }
    .fullScreenCover(item: $commun) { commun in
      CommunView(commun: commun) { self.commun = nil }
    }
    // A `conjugar://game` deeplink jumps straight to the game from any tab. The
    // router is passed explicitly (cover content doesn't inherit the custom
    // environment object) so GameView can consume a `conjugar://game/boss` entry.
    .fullScreenCover(isPresented: $router.showGame) { GameView(router: router) }
    // First-launch welcome tour. Its game-preview CTA defers the game launch to this
    // cover's onDismiss so the two covers never overlap.
    .fullScreenCover(isPresented: $router.showOnboarding, onDismiss: router.launchGameAfterOnboardingIfRequested) {
      OnboardingView(router: router, requestGame: router.requestGameAfterOnboarding)
    }
  }

  /// Trip the first-launch onboarding cover, unless already seen or disabled for
  /// screenshots. Returns whether it was presented, so the caller can skip the commun
  /// prompt for this launch.
  private func presentOnboardingIfNeeded() -> Bool {
    guard OnboardingDisplay.onboardingEnabled, !Current.settings.hasSeenOnboarding else {
      return false
    }
    router.showOnboarding = true
    return true
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
