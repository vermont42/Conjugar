//
//  AccentFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Taxonomy §4.2 — stress-accent features: a written accent lands on a stem vowel
// in the STR (stressed-stem) slots, where the stress falls on the stem.
//
// The three book features `a-i` (i→í, enviar → envío), `a-u` (u→ú, actuar →
// actúo) and the parameterized `a-stem` (aislar → aíslo, reunir → reúno) are
// mechanically one operation: accent the last i or last u of the stem in STR.
// They are unified here as `AccentStem(vowel:)`, parameterized by the accented
// vowel exactly as §6.3 resolved for `a-stem`; `a-i`/`a-u` are simply the i/u
// instances. (Their book names are kept as `static let`s for the catalog.)
nonisolated struct AccentStem: ConjugationFeature {
  enum Vowel {
    case i  // í
    case u  // ú

    var plain: Character { self == .i ? "i" : "u" }
    var accented: Character { self == .i ? "í" : "ú" }
  }

  let vowel: Vowel

  func applies(to tense: EngineTense) -> Bool {
    Slot.isStressedStem(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    // End-anchored: accent the LAST plain occurrence of the vowel in the stem
    // (descafeinar → descafeín, enraizar → enraíz, enviar → enví).
    guard let index = stem.lastIndex(of: vowel.plain) else { return (stem, ending) }
    var accented = stem
    accented.replaceSubrange(index ... index, with: String(vowel.accented))
    return (accented, ending)
  }

  static let aI = AccentStem(vowel: .i)    // enviar → envío   (§4.2 a-i)
  static let aU = AccentStem(vowel: .u)    // actuar → actúo   (§4.2 a-u)
  static let aStemI = AccentStem(vowel: .i) // aislar → aíslo   (§4.2 a-stem, í)
  static let aStemU = AccentStem(vowel: .u) // aullar → aúllo   (§4.2 a-stem, ú)
}
