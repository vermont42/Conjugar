//
//  VerbModel2.swift
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
struct VerbModel2 {
  let base: RegularRoot2
  let features: [Feature2]

  init(base: RegularRoot2, features: [Feature2] = []) {
    self.base = base
    self.features = features
  }
}
