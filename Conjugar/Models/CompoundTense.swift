//
//  CompoundTense.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Composes the nine compound (perfect) tenses the UI displays. `Conjugator2`
// deliberately models only the simple tenses; the compounds are mechanical —
// haber conjugated in the matching simple tense plus the invariant past
// participle (perfecto de indicativo = presente of haber + participle,
// pluscuamperfecto = imperfecto of haber + participle, and so on, per the
// legacy `Tense.haberTenseForCompoundTense()` table). The auxiliary routes back
// through `TenseBridge` so futuro perfecto de subjuntivo picks up the derived
// futuro de subjuntivo of haber (hubiere) for free.
enum CompoundTense {
  /// The compound form for a legacy compound tense: "haber-in-tense participle".
  static func conjugate(infinitive: String, tense: Tense, personNumber: PersonNumber) -> Result<String, Conjugator2Error> {
    guard case let .success(haberTense) = tense.haberTenseForCompoundTense() else {
      fatalError("\(tense.displayName) is not a compound tense.")
    }
    switch TenseBridge.conjugate(infinitive: Tense.auxiliary, tense: haberTense, personNumber: personNumber) {
    case let .success(auxiliary):
      return Conjugator2.conjugate(infinitive: infinitive, tense: .participioPasado).map { auxiliary + " " + $0 }
    case let .failure(error):
      return .failure(error)
    }
  }
}
