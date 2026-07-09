//
//  AccentFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// A written accent lands on a stem vowel in the stressed-stem slots. The three
// stress-accent patterns — i→í (enviar → envío), u→ú (actuar → actúo), and the
// stem-vowel variant (aislar → aíslo, reunir → reúno) — are mechanically one
// operation: accent the last i or last u of the stem. They are unified here as
// `AccentStem(vowel:)`, parameterized by the accented vowel.
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

  static let aI = AccentStem(vowel: .i)     // enviar → envío
  static let aU = AccentStem(vowel: .u)     // actuar → actúo
  static let aStemI = AccentStem(vowel: .i) // aislar → aíslo
  static let aStemU = AccentStem(vowel: .u) // aullar → aúllo
}
