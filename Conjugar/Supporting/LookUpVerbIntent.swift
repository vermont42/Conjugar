//
//  LookUpVerbIntent.swift
//  Conjugar
//
//  The Look Up a Verb shortcut (browse plan, Phase 11), ported from Konjugieren's.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import Foundation

/// Says which verb a word belongs to ("fue: Pretérito (él) of ser", and the same of ir), then
/// opens the app: on that verb's page, the form marked, when the word settles one verb, and
/// otherwise on the verb list searched for the word. Answering before opening means the answer
/// arrives even when the learner only wanted to hear it.
///
/// Not marked `nonisolated`, as the intents in Shared are, because a property wrapper cannot be.
/// `perform()` is nonisolated all the same, so it hops to the main actor for the settings.
struct LookUpVerbIntent: AppIntent {
  static let title = LocalizedStringResource("Intent.lookUpVerbTitle", defaultValue: "Look Up a Verb")
  static let description = IntentDescription(LocalizedStringResource("Intent.lookUpVerbDescription"))

  // A shortcut's phrase can carry only an entity or an enum, not free text, so the shortcut asks
  // for the word. In Konjugieren an English keyboard's autocorrection turned ging into Going
  // before the intent saw it, and the default keyboard type, ASCII, offers no accents.
  @Parameter(
    title: LocalizedStringResource("Intent.lookUpVerbWord", defaultValue: "Word"),
    inputOptions: String.IntentInputOptions(keyboardType: .default, capitalizationType: .none, autocorrect: false),
    requestValueDialog: IntentDialog(LocalizedStringResource("Intent.lookUpVerbWordPrompt"))
  )
  var word: String

  func perform() async throws -> some IntentResult & OpensIntent & ProvidesDialog {
    let hidden = await MainActor.run { Current.settings.secondSingularBrowse.hiddenPersons }
    let (answer, destination) = await Self.lookUp(word, hiding: hidden)
    let open = OpenLookupResultIntent()
    open.url = destination
    return .result(opensIntent: open, dialog: IntentDialog(stringLiteral: answer))
  }

  /// About a second the first time, while the conjugation index loads, so not on the main actor.
  @concurrent
  nonisolated private static func lookUp(_ word: String, hiding hidden: Set<DisplayPersonNumber>) async -> (answer: String, destination: URL?) {
    let lookup = VerbLookup(word: word, entries: VerbMap.shared.entries.values, hiding: hidden)
    return (lookup.answer(), lookup.destination)
  }
}

/// What Look Up a Verb opens once it has answered. An intent's result can open the app only by
/// naming another intent, so this one exists only to be named there.
struct OpenLookupResultIntent: AppIntent {
  static let title = LocalizedStringResource("Intent.openLookupResultTitle", defaultValue: "Open Lookup Result")
  static let openAppWhenRun = true
  static let isDiscoverable = false

  @Parameter(title: LocalizedStringResource("Intent.openLookupResultURL", defaultValue: "Link"))
  var url: URL?

  func perform() async throws -> some IntentResult {
    let url = url
    await MainActor.run {
      if let url {
        AppRouter.shared.handle(url: url)
      }
    }
    return .result()
  }
}
