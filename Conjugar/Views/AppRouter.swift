//
//  AppRouter.swift
//  Conjugar
//
//  Tab selection + deeplink routing for the widgets and control-center controls. A
//  `conjugar://` URL (from a widget tap) or a drained control-widget deeplink is turned
//  into a tab switch plus a pending navigation the destination screen consumes. Added
//  with the widget port (July 2026), mirroring Conjuguer's World.handleURL.
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

  /// Route a `conjugar://` deeplink. Hosts: `verb/<infinitive>` (or `verb/random`) and
  /// `quiz/start`. Unknown or unmapped verbs are ignored.
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
    default:
      break
    }
  }

  private func open(verb: String) {
    selectedTab = .browseVerbs
    pendingVerb = verb
  }
}
