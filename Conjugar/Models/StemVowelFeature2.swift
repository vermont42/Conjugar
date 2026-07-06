//
//  StemVowelFeature2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Taxonomy §4.3 (stem-vowel diphthongs in STR) and §4.4 (-ir weak-slot raising)
// are, mechanically, the **same operation**: replace the last `from` vowel of the
// stem with the `to` string, in a named slot set. The only axes that vary are the
// triggering vowel, the replacement string (the spelled variants — `ye`/`üe`/
// `hue` — are just different `to`s), and whether the change fires in the
// stressed-stem slots (STR, diphthongs and pedir-style raising) or the weak -ir
// slots (WK, sentir/dormir-style raising). So one parameterized feature covers the
// whole of §4.3 and §4.4; the catalog below is just its instances.
//
// Like every Phase 2 feature this is end-anchored — it rewrites the **last**
// occurrence of the trigger vowel — so it rides free on prefixed verbs
// (`comprobar` → compruebo, `repetir` → repito) and composes through the existing
// `Conjugator2.compose` seam.
//
// **The STR/WK split is the crux of Phase 3.** In an -ir verb that both
// diphthongizes and raises (e.g. sentir = subir + `d-ie` + `r-ei-wk`) the present
// subjunctive splits: PS{1s,2s,3s,3p} take the STR diphthong (sienta…), PS{1p,2p}
// take the WK raise (sintamos/sintáis). Because `Slot2.isStressedStem` and
// `Slot2.isWeakIr` are disjoint, each feature fires on its own PS persons and the
// two never conflict — composition just works.
struct StemVowel2: Feature2 {
  /// Which named slot set this stem-vowel change fires in (taxonomy §2).
  enum Slots {
    case str // diphthongs (§4.3) and pedir-style raise (`r-ei-str`)
    case wk  // -ir weak-slot raising (§4.4: `r-ei-wk`, `r-ou-wk`)

    func applies(to tense: EngineTense) -> Bool {
      switch self {
      case .str:
        return Slot2.isStressedStem(tense)
      case .wk:
        return Slot2.isWeakIr(tense)
      }
    }
  }

  /// The plain stem vowel that changes (e, o, i, u).
  let from: Character
  /// What it becomes — a string, so the spelled variants (`ye`, `üe`, `hue`) are
  /// the same feature with a different target.
  let to: String
  let slots: Slots

  func applies(to tense: EngineTense) -> Bool {
    slots.applies(to: tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    // End-anchored: rewrite the LAST occurrence of the trigger vowel in the stem
    // (pensar → piens-, mostrar → muestr-, adquirir → adquier-, comprobar →
    // compruebo on the last o). The prefix rides along untouched.
    guard let index = stem.lastIndex(of: from) else { return (stem, ending) }
    var result = stem
    result.replaceSubrange(index ... index, with: to)
    return (result, ending)
  }

  // MARK: - §4.3 diphthongs (STR)

  static let dIe = StemVowel2(from: "e", to: "ie", slots: .str)    // pensar → pienso; perder → pierdo
  static let dUe = StemVowel2(from: "o", to: "ue", slots: .str)    // mostrar → muestro; mover → muevo
  static let dIIe = StemVowel2(from: "i", to: "ie", slots: .str)   // adquirir → adquiero
  static let dUUe = StemVowel2(from: "u", to: "ue", slots: .str)   // jugar → juego

  // Spelled variants — same operation, different target string.
  static let dIeYe = StemVowel2(from: "e", to: "ye", slots: .str)    // errar → yerro
  static let dUeGue = StemVowel2(from: "o", to: "üe", slots: .str)   // agorar → agüero; avergonzar → avergüenzo
  static let dUeHue = StemVowel2(from: "o", to: "hue", slots: .str)  // oler → huelo; desosar → deshueso

  // MARK: - §4.4 -ir weak-slot raising

  static let rEiWk = StemVowel2(from: "e", to: "i", slots: .wk)   // sentir → sintió, sintamos, sintiendo
  static let rEiStr = StemVowel2(from: "e", to: "i", slots: .str) // pedir → pido (raise instead of diphthong)
  static let rOuWk = StemVowel2(from: "o", to: "u", slots: .wk)   // dormir → durmió, durmamos, durmiendo
}
