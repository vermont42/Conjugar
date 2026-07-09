//
//  StemFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// A feature that **rebuilds the stem from the regular base stem** (the
// `regularStem` seam) in a given slot set. Unlike the features that transform the
// *running* `(stem, ending)`, this one discards the running stem and derives a
// fresh one from the base — so it **resets** any prior diphthong/raise in its
// slots. That single behavior realizes two things at once:
//
//   1. **Irregular 1s + present subjunctive** (`subj-from-1s` bundled): the
//      productive inserts `g1-g` / `g1-ig` / `zc` and the glide `y-add`. In
//      `PI{1s}` + `PS{all}` these win over a prior diphthong — tener →
//      `tengo`/`tenga` (not `*tiengo`) beside `tienes`/`tiene`/`tienen`, because
//      the feature builds `teng-` from the regular `ten-`, not from the
//      diphthongized `tien-`.
//   2. **Residue stems** (residue *is* a feature): the per-verb **strong
//      preterite** stem (ten→tuv, and→anduv, dec→dij, conduc→conduj…), the
//      **contracted future** stem (`f-contract`: hac→ha, dec→di), and
//      **explicit irregular 1s** stems (decir's dig-).
//
// Every operation is **end-anchored** (append to / swap the end of the regular
// stem, or — for a genuinely suppletive form — replace it whole), so prefixed
// verbs ride free: `reconoc` → `reconozc`, `deten` → `detuv`, `compon` → `compus`.
nonisolated struct StemFeature: ConjugationFeature {
  enum Operation {
    /// Append a suffix to the regular stem: `g1-g` (g), `g1-ig` (ig), `y-add` (y).
    case append(String)
    /// End-anchored swap of the regular stem's trailing `from` with `to`: `zc`
    /// (c→zc) and every residue stem (ten→tuv, dec→dij, hac→ha, …).
    case swapSuffix(from: String, to: String)
    /// Replace the whole stem (a suppletive form with no shared base — only
    /// `pret-fue`'s `fu-`). Prefix-invariance does not apply (there are no
    /// prefixed `ser`/`ir`).
    case replaceWhole(String)
  }

  let operation: Operation
  /// The slot set this stem rebuild fires in (a named derivation target).
  let slots: @Sendable (EngineTense) -> Bool

  func applies(to tense: EngineTense) -> Bool {
    slots(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    switch operation {
    case let .append(suffix):
      return (regularStem + suffix, ending)
    case let .swapSuffix(from, to):
      // End-anchored; if the trigger isn't present, leave the running stem alone.
      guard regularStem.hasSuffix(from) else { return (stem, ending) }
      return (String(regularStem.dropLast(from.count)) + to, ending)
    case let .replaceWhole(whole):
      return (whole, ending)
    }
  }

  static let g1g = StemFeature(operation: .append("g"), slots: Slot.isSubjFrom1s)   // salir→salgo, tener→tengo
  static let g1ig = StemFeature(operation: .append("ig"), slots: Slot.isSubjFrom1s) // caer→caigo, traer→traigo
  static let zc = StemFeature(operation: .swapSuffix(from: "c", to: "zc"), slots: Slot.isSubjFrom1s) // conocer→conozco
  static let yAdd = StemFeature(operation: .append("y"), slots: Slot.isYAdd)         // construir→construyo

  /// A strong / suppletive **preterite** stem, driving `PR{all}` + `IS{all}`
  /// (ten→tuv, and→anduv, dec→dij, conduc→conduj, …).
  static func strongPreterite(from: String, to: String) -> StemFeature {
    StemFeature(operation: .swapSuffix(from: from, to: to), slots: Slot.isPreteriteSystem)
  }

  /// A contracted **future** stem (`f-contract`), driving `FU{all}` + `CO{all}`
  /// (hac→ha, dec→di).
  static func contractedFuture(from: String, to: String) -> StemFeature {
    StemFeature(operation: .swapSuffix(from: from, to: to), slots: Slot.isFutureSystem)
  }

  /// An explicit irregular **1s/subjunctive** stem (decir's dig-), used where the
  /// `-go` is not a productive append (`subj-from-1s` slots).
  static func irregularFirstSingular(from: String, to: String) -> StemFeature {
    StemFeature(operation: .swapSuffix(from: from, to: to), slots: Slot.isSubjFrom1s)
  }
}
