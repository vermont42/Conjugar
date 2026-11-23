//
//  ConjugarShortcuts.swift
//  Conjugar
//
//  Conjugar's App Shortcuts: the shortcuts the Shortcuts app and Siri offer with no setup.
//  Phrases are English only; phrases in the app's second language were considered and declined.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents

struct ConjugarShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LookUpVerbIntent(),
      phrases: [
        "Look up a verb with \(.applicationName)",
        "Look up a word with \(.applicationName)",
        "Look up a conjugation with \(.applicationName)"
      ],
      shortTitle: LocalizedStringResource("Intent.lookUpVerbTitle", defaultValue: "Look Up a Verb"),
      systemImageName: "magnifyingglass"
    )

    AppShortcut(
      intent: OpenQuizIntent(),
      phrases: [
        "Start a quiz with \(.applicationName)",
        "Quiz me with \(.applicationName)"
      ],
      shortTitle: LocalizedStringResource("Shortcut.startQuiz", defaultValue: "Start a Quiz"),
      systemImageName: "questionmark.circle"
    )

    AppShortcut(
      intent: OpenRandomVerbIntent(),
      phrases: [
        "Show a random verb with \(.applicationName)",
        "Random verb with \(.applicationName)"
      ],
      shortTitle: LocalizedStringResource("Shortcut.randomVerb", defaultValue: "Random Verb"),
      systemImageName: "dice"
    )
  }
}
