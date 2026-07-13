//
//  AppRouter.swift
//  Conjugar
//
//  Tab selection + deeplink routing for the widgets and control-center controls. A
//  `conjugar://` URL (from a widget tap) or a drained control-widget deeplink is turned
//  into a tab switch plus a pending navigation the destination screen consumes. Added
//  with the widget port (July 2026).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

enum AppTab: Hashable {
  case browseVerbs
  case models
  case quiz
  case info
  case settings
}

@Observable
final class AppRouter {
  var selectedTab: AppTab = .browseVerbs
  /// A verb the Browse tab should push. `VerbBrowseView` consumes and clears it.
  var pendingVerb: String?
  /// A one-shot request for the Quiz tab to start a quiz. `QuizView` consumes it.
  var pendingQuizStart = false
  /// Drives a full-screen `GameView` cover from `MainTabView`, tab-independent so a
  /// `conjugar://game` deeplink jumps straight to the game from any screen. (The
  /// Settings tab's Play button presents the game via its own state; both are fine.)
  var showGame = false
  /// A one-shot request to start the game at the boss fight, set by the
  /// `conjugar://game/boss` debug deeplink. `GameView` consumes it after configure.
  var pendingBossEntry = false
  /// Drives the first-launch onboarding cover from `MainTabView`. Tripped once at
  /// launch when `Settings.hasSeenOnboarding` is false (and the kill switch is on).
  var showOnboarding = false
  /// A one-shot request for the Info tab to push the conjugation tutor, set by the
  /// onboarding "Meet the Tutor" CTA. `InfoBrowseView` consumes and clears it.
  var pendingTutor = false

  /// Route a `conjugar://` deeplink. Hosts: `verb/<infinitive>` (or `verb/random`),
  /// `quiz/start`, and `game`. Unknown or unmapped verbs are ignored.
  func handle(url: URL) {
    guard url.scheme == "conjugar", let host = url.host() else { return }
    switch host {
    case "verb":
      let last = url.lastPathComponent
      if last == "random", let random = VerbMap.shared.entries.keys.randomElement() {
        open(verb: random)
      } else if VerbMap.shared.entry(for: last) != nil {
        open(verb: last)
      }
    case "quiz":
      selectedTab = .quiz
      pendingQuizStart = true
    case "game":
      // `conjugar://game/boss` is the boss fight's debug entry (same host, one
      // path component); plain `conjugar://game` starts the climb as always.
      if url.lastPathComponent == "boss" {
        pendingBossEntry = true
      }
      showGame = true
    default:
      break
    }
  }

  private func open(verb: String) {
    selectedTab = .browseVerbs
    pendingVerb = verb
  }
}
