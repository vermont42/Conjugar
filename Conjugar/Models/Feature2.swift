//
//  Feature2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// A composable irregularity layered onto a `RegularRoot2` (taxonomy §1:
// model = base + an ordered list of features, last-wins on slot conflicts).
//
// A feature is two things, mirroring its row in the taxonomy's feature table:
//   - `applies(to:)`  — the "Slots" column: which (tense, person) slots it touches.
//   - `apply(stem:ending:tense:)` — the "Rule" column: how it rewrites the
//     regular `(stem, ending)` pair for one of those slots.
//
// **End-anchored constraint (taxonomy §1).** Every operation must be defined
// relative to the END of the stem (its last consonant / last vowel) or the
// START of the ending — never the start of the stem. That is what makes features
// prefix-invariant: `o-car` on `c` turns `sac` → `saqu`, and so it turns
// `resec` → `reseq` and any other `-car` stem for free, with the prefix riding
// along untouched. `o-yhiatus`/`o-llñ` likewise touch only the ending boundary,
// so `releer` → `releyó` needs no model of its own.
//
// Composition (`Conjugator2.compose`) threads the `(stem, ending)` pair through
// the model's features in listed order: feature N sees the pair as rewritten by
// features 1…N-1. Orthogonal changes therefore stack (`a-stem` accents the stem
// vowel, then `o-car` rewrites the stem-final consonant → `ahínque`), and a true
// conflict resolves last-wins (the later feature's output is final).
protocol Feature2 {
  /// True for each slot this feature transforms (the taxonomy "Slots" column).
  func applies(to tense: Tense2) -> Bool

  /// Rewrite the regular `(stem, ending)` pair for a slot this feature applies
  /// to. Must be end-anchored (see the type doc). Called only when
  /// `applies(to: tense)` is true; returning the pair unchanged is fine when the
  /// trigger letter happens to be absent.
  func apply(stem: String, ending: String, tense: Tense2) -> (stem: String, ending: String)
}

// MARK: - Shared slot vocabulary (taxonomy §2)

/// The named slot sets the feature catalog refers to by name. Phase 2 needs only
/// **STR**; **WK** arrives with the Phase 3 -ir raising features.
enum Slot2 {
  /// **STR** ("stressed stem") = `PI{1s,2s,3s,3p}` + `PS{1s,2s,3s,3p}` + `IMP{2s}`:
  /// the slots where the stress falls on the stem, so a stem-vowel accent (or, in
  /// Phase 3, a diphthong) surfaces. Deliberately **excludes** voseo present-2s
  /// and imperative-2s: those are built on the regular stem and bypass the
  /// stem-vowel change (`vos enviás`, not *envíás`).
  static func isStressedStem(_ tense: Tense2) -> Bool {
    switch tense {
    case let .presenteDeIndicativo(pn), let .presenteDeSubjuntivo(pn):
      switch pn {
      case .firstSingular, .secondSingular, .thirdSingular, .thirdPlural:
        return true
      default:
        return false
      }
    case .imperativoAfirmativo(.secondSingular):
      return true
    default:
      return false
    }
  }
}
