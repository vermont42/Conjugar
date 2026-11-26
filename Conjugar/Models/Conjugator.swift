//
//  Conjugator.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The composition-aware conjugator.
//
// The no-`model:` entry points resolve a verb's model from the
// verb→model map (`VerbMap` → `ModelCatalog`), falling back to a regular base
// inferred from the ending for any verb outside the 4,818. The `model:`-taking
// overloads take an explicit `VerbModel` and are unchanged (the tests and the
// alternate-forms path call them directly). The composition seam (`compose`) is
// end-anchored, so a prefixed verb (detener, reconocer) rides its base's model
// for free.
nonisolated enum Conjugator {
  /// Smallest valid Spanish infinitive length ("ir").
  static let minimumInfinitiveLength = 2

  /// Conjugate by verb name alone — the convenience entry point. Resolves the
  /// verb's model from the verb→model map (see `resolvedModel`) and
  /// conjugates against it, so an irregular verb conjugates correctly without the
  /// caller naming its model. A verb outside the map falls back to a regular base
  /// inferred from the ending.
  static func conjugate(infinitive: String, tense: EngineTense) -> Result<String, ConjugatorError> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    return conjugate(infinitive: infinitive, tense: tense, model: resolvedModel(for: infinitive, base: base))
  }

  /// Conjugate `infinitive` against an explicit `model` (base + ordered features).
  /// Endings come from `model.base`; the stem is the infinitive minus its two-
  /// letter ending, so a prefixed verb (`releer`, `reenviar`) conjugates on its
  /// own stem and the model's end-anchored features ride along untouched.
  static func conjugate(infinitive: String, tense: EngineTense, model: VerbModel) -> Result<String, ConjugatorError> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard RegularRoot(infinitive: infinitive) != nil else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    // The single-form answer is the **primary** feature stack only — alternates
    // (`model.alternates`) are invisible here, so this path (and the irregularity
    // score that reads `model.features`) is unaffected by them.
    return conjugateOne(infinitive: infinitive, tense: tense, base: model.base, features: model.features)
      .map(Orthography.currentSpelling(of:))
  }

  /// All accepted forms for a slot — the **primary** form plus any alternates,
  /// primary first, in preference order, de-duplicated. For a regular
  /// verb or a single-form irregular this is exactly `[conjugate(...)]`; the path
  /// is a strict superset of `conjugate` that degenerates correctly.
  ///
  /// Two sources of alternates compose here:
  ///   1. **Variant paradigms** (`model.alternates`): each is a whole alternate
  ///      feature stack, composed through the *same* `conjugateOne` machinery and
  ///      unioned per slot (erguir yergo/irgo, raer raigo/rayo, roer roo/roigo/royo,
  ///      yacer yazco/yazgo/yago). Slots where the stacks agree collapse via dedup.
  ///   2. **Per-slot literal alternates**: a second participle carried on
  ///      `IrregularParticiple.alternate` (impreso/imprimido, frito/freído, the
  ///      escribir `-scripto` family), surfaced only in the PP slot.
  ///
  /// The primary element **must** equal `conjugate`'s result; it is in
  /// fact produced by the identical call. An alternate stack that fails/suppresses
  /// for a given slot is simply skipped (it contributes no form there).
  static func conjugateAll(infinitive: String, tense: EngineTense) -> Result<[String], ConjugatorError> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard let base = RegularRoot(infinitive: infinitive) else {
      return .failure(.invalidInfinitiveEnding(String(infinitive.suffix(2))))
    }
    // Same resolution as `conjugate`, so the all-forms path picks up a mapped
    // model's alternates (erguir yergo/irgo, raer raigo/rayo, …) by verb name.
    return conjugateAll(infinitive: infinitive, tense: tense, model: resolvedModel(for: infinitive, base: base))
  }

  static func conjugateAll(infinitive: String, tense: EngineTense, model: VerbModel) -> Result<[String], ConjugatorError> {
    guard infinitive.count >= minimumInfinitiveLength else {
      return .failure(.infinitiveTooShort)
    }
    guard RegularRoot(infinitive: infinitive) != nil else {
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
      for case let participle as IrregularParticiple in model.features {
        if let alternate = participle.alternate {
          forms.append(participle.form(alternate, stem: stem))
        }
      }
    }

    // 3. The spelling the 2010 Ortografía retired (rió beside rio), last, since a learner may
    // have been taught it.
    forms = forms.map(Orthography.currentSpelling(of:)) + forms

    // Stable dedup: keep first occurrence, so order is primary then alternates in
    // preference order, and coincident slots collapse to a single form.
    var seen = Set<String>()
    return .success(forms.filter { seen.insert($0).inserted })
  }

  /// The model the no-`model:` entry points conjugate `infinitive` against, or nil for text that
  /// is not an infinitive. A caller can rebuild it without a feature to ask what the verb's form
  /// would be without that irregularity.
  static func model(for infinitive: String) -> VerbModel? {
    guard infinitive.count >= minimumInfinitiveLength, let base = RegularRoot(infinitive: infinitive) else {
      return nil
    }
    return resolvedModel(for: infinitive, base: base)
  }

  /// Resolve a verb's model for the no-`model:` entry points: consult the
  /// verb→model map (`VerbMap`, loaded from `verbModelMap.xml`) — verb → its
  /// default class number → the `ModelCatalog` model — so an irregular verb
  /// conjugates correctly by name, and a prefixed compound (detener, reconocer)
  /// rides its base's model on its own stem (the end-anchored payoff).
  ///
  /// **Fallback policy:** a verb **not** in the map (a typo, or a verb outside the
  /// 4,818 — `hablar`, `vivir`, …) falls back to a **regular base inferred from the
  /// ending**. This is the safe, useful default: an unknown verb that conjugates
  /// regularly still works, and every no-`model:` test stays green. (The
  /// alternative — a `.unknownVerb` error — was
  /// rejected: it would break those tests and gives callers nothing useful.) The
  /// same fallback covers the should-never-happen case of a class number the map
  /// carries but the catalog lacks (the catalog-completeness test rules it out).
  ///
  /// **Homonym policy:** the map stores **both** senses of the 4 homonyms
  /// (apostar/asolar/aterrar/atestar); the resolver conjugates the **default
  /// sense** — `entry.classNumber`, the first/everyday sense (apostar→bet 4B,
  /// asolar→raze 4B, aterrar→terrify 1, atestar→stuff 4A). Both senses remain
  /// retrievable through `VerbMap` for the future UI, which can offer the other.
  ///
  /// The gloss (`entry.gloss`) is display-only and never consulted here, so it can
  /// never influence a conjugation.
  private static func resolvedModel(for infinitive: String, base: RegularRoot) -> VerbModel {
    if
      let entry = VerbMap.shared.entry(for: infinitive),
      let model = ModelCatalog.model(forClass: entry.classNumber) {
      return model
    }
    return VerbModel(base: base)
  }

  /// The post-validation single-slot core: defectivity check → regular ending →
  /// `compose` (or the derived imperative). Shared by `conjugate` (the primary
  /// stack) and `conjugateAll` (the primary stack *and* each alternate stack), so
  /// alternates ride the exact same seam, derivation rules, and imperative logic.
  private static func conjugateOne(infinitive: String, tense: EngineTense, base: RegularRoot, features: [ConjugationFeature]) -> Result<String, ConjugatorError> {
    // Outside the presente de indicativo and the affirmative imperative — the
    // two tenses with distinct voseo forms — vos conjugates identically to tú,
    // so canonicalize the slot to tú before composing. The ending tables already
    // fall back; doing it here makes every *feature* (hiatus accents, raises,
    // strong stems, residue literals) ride along too (caíste, duermas, ibas).
    let tense = canonicalized(tense)
    let stem = String(infinitive.dropLast(2))

    // Defectivity (abolir): a slot a feature declares formless has no
    // composition at all — report it before reaching the ending tables.
    if features.contains(where: { $0.suppresses(tense) }) {
      return .failure(.noForm(tense))
    }

    guard let ending = base.ending(for: tense) else {
      // The only slot a regular root legitimately lacks is an affirmative
      // imperative for a non-2nd-person; those are now **derived** (usted/
      // ustedes/nosotros from the present subjunctive).
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
  /// (3p) — the persons the regular paradigm lacks. They are the **present
  /// subjunctive** of the same person, so every PS
  /// irregularity rides through for free (tenga, pongamos, conduzcan, vayan, sea,
  /// dé). Crucially this reuses the *computed* PS (`compose`), not a re-derivation.
  /// A trailing imperative-slot residue may then override it — the one
  /// case being `ir`'s nosotros = **vamos** (not vayamos).
  private static func deriveImperative(personNumber: EnginePersonNumber, stem: String, base: RegularRoot, features: [ConjugationFeature]) -> Result<String, ConjugatorError> {
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

  /// The future root ("raíz futura") the Verb screen displays: the stem the whole
  /// future/conditional system is built on (hablar → "hablar", tener → "tendr",
  /// hacer → "har"). The future 1s always ends in the accented marker `-é`
  /// (hablaré, tendré, iré), so the root is that form minus its final character.
  static func futureRoot(infinitive: String) -> Result<String, ConjugatorError> {
    conjugate(infinitive: infinitive, tense: .futuro(.firstSingular)).map { String($0.dropLast()) }
  }

  /// Whether any slot of this verb's paradigm has no form at all (abolir). True
  /// exactly when the resolved model carries a feature that
  /// suppresses at least one slot.
  static func isDefective(infinitive: String) -> Bool {
    guard let base = RegularRoot(infinitive: infinitive) else {
      return false
    }
    let features = resolvedModel(for: infinitive, base: base).features
    return allSlots.contains { slot in features.contains { $0.suppresses(slot) } }
  }

  /// The four-way classification the Verb screen displays. A mapped verb is irregular as
  /// `VerbMapEntry.isIrregular` says, the orthographic sub-classes included; a regular one, like
  /// a verb outside the map, which conjugates regularly, classifies by its ending.
  static func verbType(infinitive: String) -> VerbType {
    if VerbMap.shared.entry(for: infinitive)?.isIrregular == true {
      return .irregular
    }
    switch RegularRoot(infinitive: infinitive) {
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

  /// Every slot a verb's paradigm can have — the domain `isDefective` sweeps.
  private static var allSlots: [EngineTense] {
    var slots: [EngineTense] = [.participioPasado, .gerundio]
    for personNumber in EnginePersonNumber.allCases {
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

  /// Composition seam: start from the regular `(stem, ending)` pair
  /// and thread it through the model's features in listed order. Each feature
  /// that `applies(to:)` this slot rewrites the pair, seeing the prior features'
  /// result — so orthogonal changes stack (`a-stem` then `o-car` → `ahínque`) and
  /// a true conflict resolves last-wins. Every feature operation is end-anchored,
  /// so prefixes ride along untouched. With no features this returns the regular
  /// `stem + ending`.
  private static func compose(stem: String, ending: String, tense: EngineTense, features: [ConjugationFeature]) -> String {
    // The regular base stem, captured before any feature runs, so the
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

/// Spelling rules the engine applies to every form it composes.
nonisolated enum Orthography {
  /// A form with each word that the 2010 *Ortografía* counts as a monosyllable written without
  /// its accent: rió as rio, guié as guie, huí as hui, riáis as riais, and the voseo fiás as fias.
  /// Such a word has its accent on a vowel joined to another vowel, a diphthong or triphthong for
  /// spelling purposes, and no other vowel group. Two open vowels side by side, or a stressed i
  /// or u beside an open vowel, are two syllables (reí, ríe), and a lone accented vowel is a
  /// diacritic accent (dé, sé); both keep theirs. Case is kept.
  static func currentSpelling(of form: String) -> String {
    form.split(separator: " ", omittingEmptySubsequences: false)
      .map { word in isAccentedMonosyllable(word) ? String(word.map { unaccented[$0] ?? $0 }) : String(word) }
      .joined(separator: " ")
  }

  private static let openVowels: Set<Character> = ["a", "e", "o", "á", "é", "ó"]
  private static let closedVowels: Set<Character> = ["i", "u", "ü", "í", "ú"]
  private static let stressedClosedVowels: Set<Character> = ["í", "ú"]
  private static let unaccented: [Character: Character] = [
    "á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U"
  ]

  private static func isAccentedMonosyllable(_ word: Substring) -> Bool {
    let letters = Array(word.lowercased())
    guard letters.contains(where: { unaccented[$0] != nil }) else {
      return false
    }
    // The u of gue, gui, que, and qui is silent, so it joins no vowel.
    var groups: [[Character]] = []
    var group: [Character] = []
    for (index, letter) in letters.enumerated() {
      let isSilentU = letter == "u" && index > 0 && ["g", "q"].contains(letters[index - 1])
        && index + 1 < letters.count && ["e", "i", "é", "í"].contains(letters[index + 1])
      if (openVowels.contains(letter) || closedVowels.contains(letter)) && !isSilentU {
        group.append(letter)
      } else if !group.isEmpty {
        groups.append(group)
        group = []
      }
    }
    if !group.isEmpty {
      groups.append(group)
    }
    guard groups.count == 1, let vowels = groups.first, vowels.count > 1 else {
      return false
    }
    return !zip(vowels, vowels.dropFirst()).contains { left, right in
      (openVowels.contains(left) && openVowels.contains(right))
        || (stressedClosedVowels.contains(left) && openVowels.contains(right))
        || (openVowels.contains(left) && stressedClosedVowels.contains(right))
    }
  }
}
