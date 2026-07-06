//
//  VerbModel.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// A model is one regular base root plus an ordered list of composable features
// (taxonomy §1). Conjugating starts from the base's regular endings and applies
// each feature's slot overrides in order; on a slot conflict the later feature
// wins.
//
// In the Phase 1 skeleton every (regular) verb's model is simply its base with
// an empty feature list; the feature machinery arrives in Phase 2.
//
// **Alternate paradigms (Phase 5b).** A handful of verbs have slots with more
// than one accepted form because the book lists two or three co-equal *whole
// derivations* of the same slots (erguir yergo/irgo, raer raigo/rayo, roer
// roo/roigo/royo, yacer yazco/yazgo/yago). Each such variant is a complete
// feature stack of its own, recorded in `alternates`. The *primary* stack
// (`features`) is the only thing `conjugate` and the irregularity score (§6.5)
// ever see; the alternate stacks surface **only** through `Conjugator.conjugateAll`,
// which composes each one and unions the per-slot results (dedup, primary first).
// Default `[]`, so every pre-5b model is unchanged and the single-form path is
// untouched. (Per-slot *literal* alternates — the two-form participles
// impreso/imprimido, frito/freído, the -scripto family — are carried instead on
// `IrregularParticiple.alternate`, not here; a whole stack would be overkill.)
nonisolated struct VerbModel {
  let base: RegularRoot
  let features: [ConjugationFeature]
  /// Zero or more alternate feature stacks (whole co-equal paradigms). Each is
  /// composed independently by `conjugateAll`; the union (primary first, then
  /// these in listed = book-preference order, de-duplicated) is the slot's
  /// answer. Invisible to `conjugate` and to the irregularity score.
  let alternates: [[ConjugationFeature]]

  init(base: RegularRoot, features: [ConjugationFeature] = [], alternates: [[ConjugationFeature]] = []) {
    self.base = base
    self.features = features
    self.alternates = alternates
  }
}
