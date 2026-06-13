//
//  Conjugator2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The new composition-aware conjugator (taxonomy §1 / build plan Phase 1).
// Suffixed `2` while it lives alongside the old `Conjugator`; the suffix is
// dropped once the old engine is removed.
//
// Phase 1 scope: conjugate the three regular roots (and therefore any regular
// -ar/-er/-ir verb) correctly. There is no verb→model map yet, so a verb's model
// is inferred from its ending as the matching base with no features. Features and
// the verb→model map arrive in later phases; the composition seam (`compose`) is
// already in place so they slot in without restructuring.
enum Conjugator2 {
  /// Smallest valid Spanish infinitive length ("ir").
  static let minimumInfinitiveLength = 2

  static func conjugate(infinitive: String, tense: Tense2) -> Result<String, Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }

    // Phase 1: a regular verb's model is just its base with no features.
    let model = VerbModel2(base: base)

    let stem = String(infinitive.dropLast(2))

    guard let ending = base.ending(for: tense) else {
      // The only slot a regular root legitimately lacks is an affirmative
      // imperative for a non-2nd-person (those are derived later).
      if case let .imperativoAfirmativo(personNumber) = tense {
        return .failure(.imperativeNotAvailable(personNumber))
      }
      preconditionFailure("Regular root \(base) produced no ending for \(tense).")
    }

    let regularForm = stem + ending
    return .success(compose(regularForm, tense: tense, base: base, stem: stem, features: model.features))
  }

  /// Composition seam (taxonomy §1): apply each feature's slot override in listed
  /// order, later features winning on conflicts. Phase 1 defines no features, so
  /// the regular form is returned unchanged; Phase 2 implements `Feature2`'s
  /// override API and folds it here.
  private static func compose(_ regularForm: String, tense: Tense2, base: RegularRoot2, stem: String, features: [Feature2]) -> String {
    return regularForm
  }
}
