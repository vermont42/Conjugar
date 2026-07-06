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
// The no-`model:` entry points (Phase 6 C) resolve a verb's model from the
// verb→model map (`VerbMap2` → `ModelCatalog2`), falling back to a regular base
// inferred from the ending for any verb outside the 4,818. The `model:`-taking
// overloads take an explicit `VerbModel2` and are unchanged (the tests and the
// alternate-forms path call them directly). The composition seam (`compose`) is
// end-anchored, so a prefixed verb (detener, reconocer) rides its base's model
// for free.
enum Conjugator2 {
  /// Smallest valid Spanish infinitive length ("ir").
  static let minimumInfinitiveLength = 2

  /// Conjugate by verb name alone — the convenience entry point. Resolves the
  /// verb's model from the verb→model map (Phase 6 C; see `resolvedModel`) and
  /// conjugates against it, so an irregular verb conjugates correctly without the
  /// caller naming its model. A verb outside the map falls back to a regular base
  /// inferred from the ending.
  static func conjugate(infinitive: String, tense: EngineTense) -> Result<String, Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    return conjugate(infinitive: infinitive, tense: tense, model: resolvedModel(for: infinitive, base: base))
  }

  /// Conjugate `infinitive` against an explicit `model` (base + ordered features).
  /// Endings come from `model.base`; the stem is the infinitive minus its two-
  /// letter ending, so a prefixed verb (`releer`, `reenviar`) conjugates on its
  /// own stem and the model's end-anchored features ride along untouched. This is
  /// the test entry point until the verb→model map arrives in Phase 6.
  static func conjugate(infinitive: String, tense: EngineTense, model: VerbModel2) -> Result<String, Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard RegularRoot2(infinitive: infinitive) != nil else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    // The single-form answer is the **primary** feature stack only — alternates
    // (`model.alternates`) are invisible here, so this path (and the irregularity
    // score that reads `model.features`) is byte-for-byte unchanged by Phase 5b.
    return conjugateOne(infinitive: infinitive, tense: tense, base: model.base, features: model.features)
  }

  // MARK: - All accepted forms (Phase 5b)

  /// All accepted forms for a slot — the **primary** form plus any alternates,
  /// primary first, in the book's preference order, de-duplicated. For a regular
  /// verb or a single-form irregular this is exactly `[conjugate(...)]`; the path
  /// is a strict superset of `conjugate` that degenerates correctly.
  ///
  /// Two sources of alternates compose here (taxonomy §5b):
  ///   1. **Variant paradigms** (`model.alternates`): each is a whole alternate
  ///      feature stack, composed through the *same* `conjugateOne` machinery and
  ///      unioned per slot (erguir yergo/irgo, raer raigo/rayo, roer roo/roigo/royo,
  ///      yacer yazco/yazgo/yago). Slots where the stacks agree collapse via dedup.
  ///   2. **Per-slot literal alternates**: a second participle carried on
  ///      `IrregularParticiple2.alternate` (impreso/imprimido, frito/freído, the
  ///      escribir `-scripto` family), surfaced only in the PP slot.
  ///
  /// The primary element **must** equal `conjugate`'s result (crux 1); it is in
  /// fact produced by the identical call. An alternate stack that fails/suppresses
  /// for a given slot is simply skipped (it contributes no form there).
  static func conjugateAll(infinitive: String, tense: EngineTense) -> Result<[String], Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    // Same resolution as `conjugate`, so the all-forms path picks up a mapped
    // model's alternates (erguir yergo/irgo, raer raigo/rayo, …) by verb name.
    return conjugateAll(infinitive: infinitive, tense: tense, model: resolvedModel(for: infinitive, base: base))
  }

  static func conjugateAll(infinitive: String, tense: EngineTense, model: VerbModel2) -> Result<[String], Conjugator2Error> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard RegularRoot2(infinitive: infinitive) != nil else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }

    // Primary first — the same call `conjugate` makes, so element 0 is identical.
    let primary = conjugateOne(infinitive: infinitive, tense: tense, base: model.base, features: model.features)
    guard case let .success(primaryForm) = primary else {
      // A formless primary slot (defective) has no alternates to offer either.
      return primary.map { [$0] }
    }

    var forms = [primaryForm]

    // 1. Variant-paradigm alternate stacks (each through the same machinery).
    for stack in model.alternates {
      if case let .success(form) = conjugateOne(infinitive: infinitive, tense: tense, base: model.base, features: stack) {
        forms.append(form)
      }
    }

    // 2. Per-slot literal participle alternates (PP only).
    if tense == .participioPasado {
      let stem = String(infinitive.dropLast(2))
      for case let participle as IrregularParticiple2 in model.features {
        if let alternate = participle.alternate {
          forms.append(participle.form(alternate, stem: stem))
        }
      }
    }

    // Stable dedup: keep first occurrence, so order is primary then alternates in
    // book-preference order, and coincident slots collapse to a single form.
    var seen = Set<String>()
    return .success(forms.filter { seen.insert($0).inserted })
  }

  // MARK: - The resolver (Phase 6 C)

  /// Resolve a verb's model for the no-`model:` entry points: consult the
  /// verb→model map (`VerbMap2`, loaded from `verbModelMap.xml`) — verb → its
  /// default class number → the `ModelCatalog2` model — so an irregular verb
  /// conjugates correctly by name, and a prefixed compound (detener, reconocer)
  /// rides its base's model on its own stem (the end-anchored §1 payoff).
  ///
  /// **Fallback policy:** a verb **not** in the map (a typo, or a verb outside the
  /// 4,818 — `hablar`, `vivir`, …) falls back to a **regular base inferred from the
  /// ending**, today's pre-Phase-6 behavior. This is the safe, useful default: an
  /// unknown verb that conjugates regularly still works, and every pre-Phase-6
  /// no-`model:` test stays green. (The alternative — a `.unknownVerb` error — was
  /// rejected: it would break those tests and gives callers nothing useful.) The
  /// same fallback covers the should-never-happen case of a class number the map
  /// carries but the catalog lacks (the catalog-completeness test rules it out).
  ///
  /// **Homonym policy (crux 4):** the map stores **both** senses of the 4 homonyms
  /// (apostar/asolar/aterrar/atestar); the resolver conjugates the **default
  /// sense** — `entry.classNumber`, the first/everyday sense (apostar→bet 4B,
  /// asolar→raze 4B, aterrar→terrify 1, atestar→stuff 4A). Both senses remain
  /// retrievable through `VerbMap2` for the future UI, which can offer the other.
  ///
  /// The gloss (`entry.gloss`) is display-only and never consulted here, so it can
  /// never influence a conjugation.
  private static func resolvedModel(for infinitive: String, base: RegularRoot2) -> VerbModel2 {
    if
      let entry = VerbMap2.shared.entry(for: infinitive),
      let model = ModelCatalog2.model(forClass: entry.classNumber) {
      return model
    }
    return VerbModel2(base: base)
  }

  /// The post-validation single-slot core: defectivity check → regular ending →
  /// `compose` (or the derived imperative). Shared by `conjugate` (the primary
  /// stack) and `conjugateAll` (the primary stack *and* each alternate stack), so
  /// alternates ride the exact same seam, derivation rules, and imperative logic.
  private static func conjugateOne(infinitive: String, tense: EngineTense, base: RegularRoot2, features: [Feature2]) -> Result<String, Conjugator2Error> {
    // Outside the presente de indicativo and the affirmative imperative — the
    // two tenses with distinct voseo forms — vos conjugates identically to tú,
    // so canonicalize the slot to tú before composing. The ending tables already
    // fall back; doing it here makes every *feature* (hiatus accents, raises,
    // strong stems, residue literals) ride along too (caíste, duermas, ibas).
    let tense = canonicalized(tense)
    let stem = String(infinitive.dropLast(2))

    // Defectivity (taxonomy §5 abolir): a slot a feature declares formless has no
    // composition at all — report it before reaching the ending tables.
    if features.contains(where: { $0.suppresses(tense) }) {
      return .failure(.noForm(tense))
    }

    guard let ending = base.ending(for: tense) else {
      // The only slot a regular root legitimately lacks is an affirmative
      // imperative for a non-2nd-person; those are now **derived** (usted/
      // ustedes/nosotros from the present subjunctive, taxonomy §1).
      if case let .imperativoAfirmativo(personNumber) = tense {
        return deriveImperative(personNumber: personNumber, stem: stem, base: base, features: features)
      }
      preconditionFailure("Regular root \(base) produced no ending for \(tense).")
    }

    return .success(compose(stem: stem, ending: ending, tense: tense, features: features))
  }

  /// The tú-slot equivalent of a vos slot in the tenses where vos and tú share
  /// every form; identity everywhere else (PI and IMP keep their real voseo
  /// slots — cantás/cantá and the sos/ves/has/andá residue).
  private static func canonicalized(_ tense: EngineTense) -> EngineTense {
    switch tense {
    case .pretérito(.secondSingularVos):
      return .pretérito(.secondSingular)
    case .imperfectoDeIndicativo(.secondSingularVos):
      return .imperfectoDeIndicativo(.secondSingular)
    case .futuro(.secondSingularVos):
      return .futuro(.secondSingular)
    case .condicional(.secondSingularVos):
      return .condicional(.secondSingular)
    case .presenteDeSubjuntivo(.secondSingularVos):
      return .presenteDeSubjuntivo(.secondSingular)
    case .imperfectoDeSubjuntivoRa(.secondSingularVos):
      return .imperfectoDeSubjuntivoRa(.secondSingular)
    case .imperfectoDeSubjuntivoSe(.secondSingularVos):
      return .imperfectoDeSubjuntivoSe(.secondSingular)
    default:
      return tense
    }
  }

  /// Derive the affirmative imperative for usted (3s) / nosotros (1p) / ustedes
  /// (3p) — the persons the regular paradigm lacks (taxonomy §1 imperative row).
  /// They are the **present subjunctive** of the same person, so every PS
  /// irregularity rides through for free (tenga, pongamos, conduzcan, vayan, sea,
  /// dé). Crucially this reuses the *computed* PS (`compose`), not a re-derivation
  /// (crux 1). A trailing imperative-slot residue may then override it — the one
  /// case being `ir`'s nosotros = **vamos** (not vayamos).
  private static func deriveImperative(personNumber: PersonNumber2, stem: String, base: RegularRoot2, features: [Feature2]) -> Result<String, Conjugator2Error> {
    guard let psEnding = base.ending(for: .presenteDeSubjuntivo(personNumber)) else {
      return .failure(.imperativeNotAvailable(personNumber))
    }
    let subjunctive = compose(stem: stem, ending: psEnding, tense: .presenteDeSubjuntivo(personNumber), features: features)

    // Apply any imperative-slot residue (a literal override) on top of the PS
    // form. Only residue literals target a non-2nd imperative person, so this
    // loop is a no-op except for the `ir` vamos exception.
    let imperative = EngineTense.imperativoAfirmativo(personNumber)
    var form = subjunctive
    for feature in features where feature.applies(to: imperative) {
      (form, _) = feature.apply(stem: form, ending: "", tense: imperative, regularStem: stem)
    }
    return .success(form)
  }

  // MARK: - App-facing accessors (the Conjugator → Conjugator2 migration)

  /// The future root ("raíz futura") the Verb screen displays: the stem the whole
  /// future/conditional system is built on (hablar → "hablar", tener → "tendr",
  /// hacer → "har"). The future 1s always ends in the accented marker `-é`
  /// (hablaré, tendré, iré), so the root is that form minus its final character.
  static func futureRoot(infinitive: String) -> Result<String, Conjugator2Error> {
    conjugate(infinitive: infinitive, tense: .futuro(.firstSingular)).map { String($0.dropLast()) }
  }

  /// Whether any slot of this verb's paradigm has no form at all (taxonomy §5
  /// abolir). True exactly when the resolved model carries a feature that
  /// suppresses at least one slot.
  static func isDefective(infinitive: String) -> Bool {
    guard let base = RegularRoot2(infinitive: infinitive) else {
      return false
    }
    let features = resolvedModel(for: infinitive, base: base).features
    return allSlots.contains { slot in features.contains { $0.suppresses(slot) } }
  }

  /// The four-way classification the Verb screen displays, derived from the
  /// mapped class number: 1/2/3 are the perfectly regular classes; every other
  /// class (including the orthographic sub-classes) counts as irregular. A verb
  /// outside the map conjugates regularly, so it classifies by its ending.
  static func verbType(infinitive: String) -> VerbType {
    switch VerbMap2.shared.entry(for: infinitive)?.classNumber {
    case "1":
      return .regularAr
    case "2":
      return .regularEr
    case "3":
      return .regularIr
    case .some:
      return .irregular
    case nil:
      switch RegularRoot2(infinitive: infinitive) {
      case .ar:
        return .regularAr
      case .er:
        return .regularEr
      case .ir:
        return .regularIr
      case nil:
        return .irregular
      }
    }
  }

  /// Every slot a verb's paradigm can have — the domain `isDefective` sweeps.
  private static var allSlots: [EngineTense] {
    var slots: [EngineTense] = [.participioPasado, .gerundio]
    for personNumber in PersonNumber2.allCases {
      slots += [
        .presenteDeIndicativo(personNumber),
        .pretérito(personNumber),
        .imperfectoDeIndicativo(personNumber),
        .futuro(personNumber),
        .condicional(personNumber),
        .presenteDeSubjuntivo(personNumber),
        .imperfectoDeSubjuntivoRa(personNumber),
        .imperfectoDeSubjuntivoSe(personNumber),
        .imperativoAfirmativo(personNumber)
      ]
    }
    return slots
  }

  /// Composition seam (taxonomy §1): start from the regular `(stem, ending)` pair
  /// and thread it through the model's features in listed order. Each feature
  /// that `applies(to:)` this slot rewrites the pair, seeing the prior features'
  /// result — so orthogonal changes stack (`a-stem` then `o-car` → `ahínque`) and
  /// a true conflict resolves last-wins. Every feature operation is end-anchored,
  /// so prefixes ride along untouched. With no features this returns the regular
  /// `stem + ending`.
  private static func compose(stem: String, ending: String, tense: EngineTense, features: [Feature2]) -> String {
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
