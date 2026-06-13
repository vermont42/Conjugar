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
// PLACEHOLDER. The Phase 1 skeleton ships no features and conjugates only the
// three regular roots, so the slot-override API is intentionally left undefined
// here — it is designed in Phase 2 (orthographic + accent features), where the
// real method set (anchored to the END of the stem, for prefix-invariance) is
// added. `VerbModel2` already carries `[Feature2]`, and `Conjugator2` already
// has the fold seam, so introducing features later is additive.
protocol Feature2 {
}
