//
//  DiaeresisFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/13/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The **GÜY → GUY** diaeresis drop (class 18 argüir, "like construir except
// GÜY → GUY").
//
// argüir is construir's build (`y-add` + `o-yhiatus`) on the stem `argü`. The
// one extra rule: when the glide `y` lands immediately after `gü`, the
// diaeresis is dropped — `argüy-` → `arguy-` (arguyo, arguyendo, arguyera) — but a
// plain `güi` keeps it (argüimos, argüí, argüido). The crux is that the `güy`
// cluster can **span the stem↔ending boundary**: in `arguyó`/`arguyendo` the `ü`
// is stem-final (from the base) and the `y` is ending-initial (from `o-yhiatus`'s
// i→y glide), so a feature anchored to only one side can't see it. This feature
// therefore handles **both** placements:
//
//   - **In-stem** (`argüy-` + a vowel ending): `y-add` produced `…güy…` in the
//     stem; rewrite that cluster to `…guy…`. (arguyo, arguyes, arguya, arguyamos.)
//   - **Boundary** (stem ends `gü`, ending starts `y`): `o-yhiatus` turned the
//     ending's leading `i` into `y`; drop the stem's diaeresis. (arguyó, arguyeron,
//     arguyera, arguyendo.)
//
// It runs **last** (after `y-add` and `o-yhiatus`) and is a pure guarded fixup:
// it touches a slot only when an actual `gü`+`y` adjacency is present, so it is
// inert on `güi` slots and end-anchored / prefix-invariant (a hypothetical
// `re-argüir` rides free). It is harmless to leave `applies` always-true: the
// guards make every non-`güy` slot a no-op.
nonisolated struct DiaeresisDropBeforeY: ConjugationFeature {
  func applies(to tense: EngineTense) -> Bool { true }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    // Boundary case first: stem ends `gü`, ending begins `y` (argü + yó → arguyó).
    // Drop only the diaeresis (ü → u); the `y` stays on the ending.
    if stem.hasSuffix("gü"), ending.hasPrefix("y") {
      return (String(stem.dropLast()) + "u", ending)
    }
    // In-stem case: `y-add` appended its glide to a `gü` stem, so the stem now
    // **ends** `güy` (argü → argüy). End-anchored: rewrite that suffix `güy` → `guy`.
    if stem.hasSuffix("güy") {
      return (String(stem.dropLast(3)) + "guy", ending)
    }
    return (stem, ending)
  }

  static let güyGuy = DiaeresisDropBeforeY()
}
