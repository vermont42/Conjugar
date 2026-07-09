//
//  Etymology.swift
//  Conjugar
//
//  Created by Josh Adams on 7/8/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

// Supplies an etymology for a verb, keyed by infinitive, loaded from the bundled
// `Etymologies.json`. That file is keyed language → infinitive → text; the text uses
// single-tilde `~bold~` markup (bold every cited form/root/cognate, nothing else) and
// `\n\n` paragraph breaks. Entries are produced, a batch per session, by the pipeline in
// `prompts/etymology-pipeline.md` (English + Spanish for every verb). English is the
// fallback: `text(for:)` returns the `"en"` entry when the device language has no table.
//
// NOTE (wiring): this reads the JSON but is not yet displayed. Rendering it under the
// conjugations in `VerbView` (a `~…~`→bold attributed-string renderer + an etymology card)
// is the remaining lifecycle step — see the Status section of `etymology-pipeline.md`.
nonisolated enum Etymology {
  private static let cache = EtymologyCache()

  /// The etymology text for a bare infinitive, or `nil` if none is on file. `~…~` marks
  /// bold spans; `\n\n` separates paragraphs.
  static func text(for infinitive: String) -> String? {
    cache.text(for: infinitive)
  }
}

/// Loads `Etymologies.json` once and serves the table for the device language (falling
/// back to English). `@unchecked Sendable` + a lock mirrors `VerbMap`'s load-once cache so
/// the engine-adjacent lookup stays `nonisolated`.
nonisolated private final class EtymologyCache: @unchecked Sendable {
  private let lock = NSLock()
  private var etymologies: [String: String]?

  func text(for infinitive: String) -> String? {
    lock.lock()
    defer { lock.unlock() }
    if etymologies == nil {
      etymologies = Self.load()
    }
    return etymologies?[infinitive]
  }

  private static func load() -> [String: String] {
    let bundle = Bundle.main.url(forResource: "Etymologies", withExtension: "json") != nil
      ? Bundle.main
      : Bundle(for: EtymologyCache.self)
    guard
      let url = bundle.url(forResource: "Etymologies", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let file = try? JSONDecoder().decode([String: [String: String]].self, from: data)
    else {
      return [:]
    }
    let language = Locale.current.language.languageCode?.identifier ?? "en"
    return file[language] ?? file["en"] ?? [:]
  }
}
