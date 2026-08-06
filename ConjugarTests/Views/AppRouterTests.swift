//
//  AppRouterTests.swift
//  ConjugarTests
//
//  Deeplink routing for `AppRouter.handle(url:)`, focused on the one-shot game flags
//  (`pendingBossEntry` / `pendingEndScene`). They are drained only by `GameView.onAppear`,
//  so a `game/boss` or `game/end` URL arriving while the game is already presented must be
//  ignored — otherwise the stale flag would hijack the next plain `conjugar://game`.
//  Swift Testing + `@MainActor` (AppRouter is MainActor).
//

import Foundation
import Testing
@testable import Conjugar

@Suite("AppRouter")
@MainActor
struct AppRouterTests {
  private func url(_ string: String) -> URL { URL(string: string)! }

  @Test func plainGameDeeplinkPresentsWithoutBossOrEnd() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game"))
    #expect(router.showGame)
    #expect(!router.pendingBossEntry)
    #expect(!router.pendingEndScene)
  }

  @Test func bossDeeplinkSetsPendingBossEntryWhenGameClosed() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game/boss"))
    #expect(router.showGame)
    #expect(router.pendingBossEntry)
  }

  @Test func endDeeplinkSetsPendingEndSceneWhenGameClosed() {
    let router = AppRouter()
    router.handle(url: url("conjugar://game/end"))
    #expect(router.showGame)
    #expect(router.pendingEndScene)
  }

  /// The regression guard: a boss deeplink arriving while the game is already up must not
  /// leave a flag armed for the next plain launch.
  @Test func bossDeeplinkIgnoredWhileGameAlreadyPresented() {
    let router = AppRouter()
    router.showGame = true                       // game already on screen
    router.handle(url: url("conjugar://game/boss"))
    #expect(!router.pendingBossEntry)            // flag NOT armed
    #expect(router.showGame)
  }

  @Test func endDeeplinkIgnoredWhileGameAlreadyPresented() {
    let router = AppRouter()
    router.showGame = true
    router.handle(url: url("conjugar://game/end"))
    #expect(!router.pendingEndScene)
    #expect(router.showGame)
  }

  // The onboarding game-preview CTA defers the launch to the cover's onDismiss, unified
  // here so both presenters (MainTabView, SettingsView) share one flag + helper.
  @Test func requestGameAfterOnboardingArmsTheFlagWithoutLaunching() {
    let router = AppRouter()
    router.requestGameAfterOnboarding()
    #expect(router.pendingGameAfterOnboarding)
    #expect(!router.showGame)                    // launch waits for onDismiss
  }

  @Test func launchAfterOnboardingPresentsAndClearsWhenArmed() {
    let router = AppRouter()
    router.requestGameAfterOnboarding()
    router.launchGameAfterOnboardingIfRequested()
    #expect(router.showGame)
    #expect(!router.pendingGameAfterOnboarding)  // one-shot: cleared
  }

  @Test func launchAfterOnboardingIsNoOpWhenNotArmed() {
    let router = AppRouter()
    router.launchGameAfterOnboardingIfRequested()
    #expect(!router.showGame)
  }
}
