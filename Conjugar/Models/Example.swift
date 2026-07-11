//
//  Example.swift
//  Conjugar
//
//  One modern-prose example sentence for a verb (plus its English translation),
//  loaded from the bundled `ExampleUses.json` and keyed by bare infinitive. `source`
//  is the corpus filename (or "Claude (Opus 4.8)" for the AI-authored tail);
//  `provenance` maps it to a displayable attribution. `token` is the surface form
//  that matched; `line` is the physical line in the source (`nil` for authored ones).
//  Port of Conjuguer's `Example`, adapted for Spanish (`es`/`en`, bare-infinitive key).
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated struct Example: Codable, Hashable {
  let es: String
  let en: String
  let source: String
  let token: String
  let line: Int?

  var provenance: ExampleSource {
    ExampleSource(rawSource: source)
  }
}
