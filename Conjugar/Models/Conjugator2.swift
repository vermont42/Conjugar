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

  /// Conjugate a regular verb (no features) — convenience over the model-taking
  /// entry point, inferring the base from the infinitive's ending.
  static func conjugate(infinitive: String, tense: Tense2) -> Result<String, Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    return conjugate(infinitive: infinitive, tense: tense, model: VerbModel2(base: base))
  }

  /// Conjugate `infinitive` against an explicit `model` (base + ordered features).
  /// Endings come from `model.base`; the stem is the infinitive minus its two-
  /// letter ending, so a prefixed verb (`releer`, `reenviar`) conjugates on its
  /// own stem and the model's end-anchored features ride along untouched. This is
  /// the test entry point until the verb→model map arrives in Phase 6.
  static func conjugate(infinitive: String, tense: Tense2, model: VerbModel2) -> Result<String, Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard RegularRoot2(infinitive: infinitive) != nil else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }

    let stem = String(infinitive.dropLast(2))

    // Defectivity (taxonomy §5 abolir): a slot a feature declares formless has no
    // composition at all — report it before reaching the ending tables.
    if model.features.contains(where: { $0.suppresses(tense) }) {
      return .failure(.noForm(tense))
    }

    guard let ending = model.base.ending(for: tense) else {
      // The only slot a regular root legitimately lacks is an affirmative
      // imperative for a non-2nd-person; those are now **derived** (usted/
      // ustedes/nosotros from the present subjunctive, taxonomy §1).
      if case let .imperativoAfirmativo(personNumber) = tense {
        return deriveImperative(personNumber: personNumber, stem: stem, model: model)
      }
      preconditionFailure("Regular root \(model.base) produced no ending for \(tense).")
    }

    return .success(compose(stem: stem, ending: ending, tense: tense, features: model.features))
  }

  /// Derive the affirmative imperative for usted (3s) / nosotros (1p) / ustedes
  /// (3p) — the persons the regular paradigm lacks (taxonomy §1 imperative row).
  /// They are the **present subjunctive** of the same person, so every PS
  /// irregularity rides through for free (tenga, pongamos, conduzcan, vayan, sea,
  /// dé). Crucially this reuses the *computed* PS (`compose`), not a re-derivation
  /// (crux 1). A trailing imperative-slot residue may then override it — the one
  /// case being `ir`'s nosotros = **vamos** (not vayamos).
  private static func deriveImperative(personNumber: PersonNumber2, stem: String, model: VerbModel2) -> Result<String, Conjugator2Error> {
    guard let psEnding = model.base.ending(for: .presenteDeSubjuntivo(personNumber)) else {
      return .failure(.imperativeNotAvailable(personNumber))
    }
    let subjunctive = compose(stem: stem, ending: psEnding, tense: .presenteDeSubjuntivo(personNumber), features: model.features)

    // Apply any imperative-slot residue (a literal override) on top of the PS
    // form. Only residue literals target a non-2nd imperative person, so this
    // loop is a no-op except for the `ir` vamos exception.
    let imperative = Tense2.imperativoAfirmativo(personNumber)
    var form = subjunctive
    for feature in model.features where feature.applies(to: imperative) {
      (form, _) = feature.apply(stem: form, ending: "", tense: imperative, regularStem: stem)
    }
    return .success(form)
  }

  /// Composition seam (taxonomy §1): start from the regular `(stem, ending)` pair
  /// and thread it through the model's features in listed order. Each feature
  /// that `applies(to:)` this slot rewrites the pair, seeing the prior features'
  /// result — so orthogonal changes stack (`a-stem` then `o-car` → `ahínque`) and
  /// a true conflict resolves last-wins. Every feature operation is end-anchored,
  /// so prefixes ride along untouched. With no features this returns the regular
  /// `stem + ending`.
  private static func compose(stem: String, ending: String, tense: Tense2, features: [Feature2]) -> String {
    // The regular base stem, captured before any feature runs, so the §4.5
    // 1s/subjunctive features and the residue stem features can rebuild from it
    // (the subj-from-1s reset and prefix-invariant strong/contracted stems).
    let regularStem = stem
    var stem = stem
    var ending = ending
    for feature in features where feature.applies(to: tense) {
      (stem, ending) = feature.apply(stem: stem, ending: ending, tense: tense, regularStem: regularStem)
    }
    return stem + ending
  }
}
