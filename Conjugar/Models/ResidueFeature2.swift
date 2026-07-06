//
//  ResidueFeature2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Phase 5 machinery — the **per-verb residue** (taxonomy §5/§6.4: "residue *is* a
// feature") plus the two cross-cutting derivations the earlier phases deferred
// (irregular participles §4.8, and — in `Conjugator2` — the imperative). Each
// type here is a `Feature2`, so the residue composes through the same seam as the
// productive features and obeys the same last-wins rule; residue features go
// **at the end** of a model's feature list.
//
// Four mechanisms live here:
//   - `LiteralSlotOverride2` — the catch-all: map specific slots to a literal
//     final form (the suppletive presents soy/voy/he…, the suppletive imperfects
//     era-/iba-, the accent residue dé/prevé…, the gerund residue yendo/pudiendo).
//   - `IrregularParticiple2` — the §4.8 past-participle attribute (puesto, hecho,
//     dicho, visto…), expressed as an **end-anchored** stem swap so it rides free
//     on prefixes (componer → compuesto, descubrir → descubierto).
//   - `ApocopatedImperative2` — the irregular tú imperatives (ten/pon/sal/ven and,
//     via c→z, haz), as the **bare regular stem** with the monosyllable→poly­
//     syllable accent shift baked in (so detener → detén, suponer → supón,
//     satisfacer → satisfaz all fall out by prefix-invariance, no per-verb residue).
//   - `DefectiveFeature2` — abolir: declare the slots that have **no form**.
//
// Two tiny orthographic-residue features round it out: `RunningStemConsonantSwap2`
// (hacer's PR 3s `hizo`, prefix-invariant to satisfizo) and `CollapseDoubleI2`
// (reír's raised stem-i meeting an ending-i: ri+ió → rió, ri+iendo → riendo).

// MARK: - Literal slot override (the catch-all residue)

/// Maps specific `(tense, person)` slots — and the person-less PP/GER — to a
/// **literal final form**, replacing whatever composition produced (it sits last
/// in the feature list, so it wins). Applied by returning `(literal, "")`, so the
/// existing `stem + ending` seam is untouched. This is the genuinely-suppletive
/// residue that no productive rule yields.
///
/// Not prefix-invariant by construction (the form is spelled out in full), which
/// is correct: every verb that needs a literal override is either prefix-free
/// (ser, ir, dar, haber…) or a monosyllabic base whose compounds are *more*
/// regular, not less (ver `veis` vs. prever `prevéis`).
struct LiteralSlotOverride2: Feature2 {
  /// Slot → literal final form. Listed as pairs (EngineTense is Equatable, not
  /// Hashable; the tables are a handful of entries, so a linear scan is fine).
  let overrides: [(slot: EngineTense, form: String)]

  func applies(to tense: EngineTense) -> Bool {
    overrides.contains { $0.slot == tense }
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    for override in overrides where override.slot == tense {
      return (override.form, "")
    }
    return (stem, ending)
  }
}

// MARK: - Irregular participle (§4.8)

/// The past participle as a per-model attribute (Conjuguer's `ep`). Encoded as an
/// **end-anchored stem swap** in the PP slot: replace the trailing `coreSuffix`
/// of the stem with `participle` and drop the regular `-ido`/`-ado` ending. That
/// keeps it prefix-invariant — `pon→puesto` gives `componer → compuesto`,
/// `cubr→cubierto` gives `descubrir → descubierto`, `v→visto` gives
/// `prever → previsto` — and, being its own feature *type*, it stays countable for
/// the future irregularity score (decision §6.5). A second accepted form may be
/// carried in `alternate` (impreso/imprimido, frito/freído); the conjugator emits
/// the book's primary `participle`.
struct IrregularParticiple2: Feature2 {
  /// The trailing slice of the regular stem the irregular participle replaces
  /// (`pon`, `hac`, `scrib`, `solv`, `v`…). Chosen so the prefix rides free.
  let coreSuffix: String
  /// The book's primary irregular participle (`puesto`, `hecho`, `escrito`…).
  let participle: String
  /// A second accepted participle, where the book lists one (`imprimido`,
  /// `freído`). Not emitted by the conjugator; recorded for completeness/scoring.
  let alternate: String?

  init(_ coreSuffix: String, _ participle: String, alternate: String? = nil) {
    self.coreSuffix = coreSuffix
    self.participle = participle
    self.alternate = alternate
  }

  func applies(to tense: EngineTense) -> Bool {
    tense == .participioPasado
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    (form(participle, stem: stem), "")
  }

  /// End-anchored realization of a participle string against this stem: prefix
  /// (stem − coreSuffix) + the participle, so it rides free on prefixes
  /// (`compon` → compuesto, `inscrib` → inscripto). Shared by `apply` (primary)
  /// and `Conjugator2.conjugateAll` (the `alternate`). The guard's fallback (no
  /// suffix match) returns the bare string, reached only for a degenerate stem.
  func form(_ participleString: String, stem: String) -> String {
    guard stem.hasSuffix(coreSuffix) else { return participleString }
    return String(stem.dropLast(coreSuffix.count)) + participleString
  }
}

// MARK: - Irregular tú imperative (apocopated)

/// The irregular tú imperatives that are the **bare regular stem** (taxonomy §1
/// imperative row + §5 residue): `ten`, `pon`, `sal`, `ven`, and — with a c→z
/// finish — `haz`. Built from `regularStem` (so a diphthong/raise is reset:
/// tener's STR `tien-` becomes `ten`), targeting **`.secondSingular` only** so the
/// regular vos (`tené`) and vosotros (`tened`) are untouched (crux 2).
///
/// The monosyllable→polysyllable accent shift (crux 3) is intrinsic, not residue:
/// the bare stem takes a written accent on its last vowel exactly when it is
/// polysyllabic **and** ends in a vowel, `n`, or `s` (the cases Spanish stress
/// rules would otherwise mis-read). So the bare verbs stay accentless (`ten`,
/// `pon`, `ven`, `sal`, `haz`) while every prefixed compound gains the accent for
/// free — `detener → detén`, `suponer → supón`, `convenir → convén`,
/// `reponer → repón` — and the z-final `satisfacer → satisfaz` / `deshacer →
/// deshaz` correctly do **not** (they end in `z`). No per-compound residue.
struct ApocopatedImperative2: Feature2 {
  /// An optional final-consonant finish applied to the bare stem (`hacer`'s
  /// c→z: hac → haz). `nil` for the plain g-stems (ten/pon/sal/ven).
  let finalSwap: (from: Character, to: Character)?

  init(finalSwap: (from: Character, to: Character)? = nil) {
    self.finalSwap = finalSwap
  }

  func applies(to tense: EngineTense) -> Bool {
    tense == .imperativoAfirmativo(.secondSingular)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    var letters = Array(regularStem)
    if let finalSwap, letters.last == finalSwap.from {
      letters[letters.count - 1] = finalSwap.to
    }
    let bare = String(letters)
    return (Self.accentedIfNeeded(bare), "")
  }

  /// Accent the last vowel iff the bare imperative is polysyllabic and ends in a
  /// vowel, `n`, or `s` — the monosyllable→polysyllable shift.
  private static func accentedIfNeeded(_ word: String) -> String {
    guard syllableCount(word) >= 2, let last = word.last, "aeiouáéíóúns".contains(last) else {
      return word
    }
    return accentingLastVowel(word)
  }

  private static let plainVowels: Set<Character> = ["a", "e", "i", "o", "u"]

  /// Rough syllable count = number of maximal vowel runs (good enough for the
  /// apocopated imperatives, which are short and prefix-stacked).
  private static func syllableCount(_ word: String) -> Int {
    var count = 0
    var inVowelRun = false
    for character in word {
      if plainVowels.contains(character) {
        if !inVowelRun { count += 1 }
        inVowelRun = true
      } else {
        inVowelRun = false
      }
    }
    return count
  }

  private static let accents: [Character: Character] = [
    "a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú"
  ]

  private static func accentingLastVowel(_ word: String) -> String {
    var letters = Array(word)
    if let index = letters.lastIndex(where: { plainVowels.contains($0) }), let accented = accents[letters[index]] {
      letters[index] = accented
    }
    return String(letters)
  }
}

// MARK: - Defectivity (abolir)

/// Declares the slots that have **no form** for a defective verb. Never rewrites
/// the running pair (it is inert as a `Feature2`); it only answers `suppresses`,
/// which the conjugator checks before composing and turns into a `.noForm`
/// failure. abolir (§5 3-14): only the slots whose post-stem vowel is `-i-` (or
/// the diphthongs `-ie-`/`-io-`) exist; the stressed-stem present, the whole
/// present subjunctive, and the imperatives derived from it do not.
struct DefectiveFeature2: Feature2 {
  let isMissing: (EngineTense) -> Bool

  func applies(to tense: EngineTense) -> Bool { false }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    (stem, ending)
  }

  func suppresses(_ tense: EngineTense) -> Bool { isMissing(tense) }

  /// abolir's missing slots: PI{1s,2s,3s,3p} (the post-stem vowel is o/e),
  /// PS{all} (post-stem a), and IMP{2s,3s,1p,3p} (the 2s `-e` and the PS-derived
  /// persons). PI{1p,2p}/vos, the whole preterite/imperfect/future/conditional,
  /// IS{all}, IMP 2p/vos, PP and GER all keep their `-i-`-vowel forms.
  static let abolir = DefectiveFeature2 { tense in
    switch tense {
    case let .presenteDeIndicativo(person):
      switch person {
      case .firstSingular, .secondSingular, .thirdSingular, .thirdPlural:
        return true
      default:
        return false
      }
    case .presenteDeSubjuntivo:
      return true
    case let .imperativoAfirmativo(person):
      switch person {
      case .secondSingular, .thirdSingular, .firstPlural, .thirdPlural:
        return true
      default:
        return false
      }
    default:
      return false
    }
  }
}

// MARK: - Tiny orthographic residues

/// Swap a trailing consonant on the **running** stem in a given slot set —
/// distinct from `StemFeature2`, which rebuilds from the *regular* base. Used for
/// hacer's `hizo`: after the strong stem is `hic-`, swap c→z in PR 3s only
/// (hic+o → hiz+o), prefix-invariant to `satisfizo`/`rehízo` and leaving the
/// other strong persons (hice/hiciste/hicimos) with their `c`.
struct RunningStemConsonantSwap2: Feature2 {
  let from: String
  let to: String
  let slots: (EngineTense) -> Bool

  func applies(to tense: EngineTense) -> Bool { slots(tense) }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard stem.hasSuffix(from) else { return (stem, ending) }
    return (String(stem.dropLast(from.count)) + to, ending)
  }

  /// hacer (29) — PR 3s `hizo` (c→z), run after the strong stem so it sees `hic-`.
  static let hizo = RunningStemConsonantSwap2(from: "c", to: "z", slots: { $0 == .pretérito(.thirdSingular) })
}

/// reír (6B-4): once `r-ei-str`/`r-ei-wk` have raised the stem to `ri-`, the
/// stem-final `-i-` collides with an ending that begins in `-i-`. Collapse the
/// double i (drop the ending's leading `-i-`) in the i-glide slots: ri+ió → rió,
/// ri+ieron → rieron, ri+iendo → riendo, ri+iera → riera. Mirrors `o-llñ`'s
/// absorption, but triggered by the raised stem vowel rather than a palatal.
struct CollapseDoubleI2: Feature2 {
  func applies(to tense: EngineTense) -> Bool {
    switch tense {
    case .pretérito(.thirdSingular), .pretérito(.thirdPlural),
         .gerundio,
         .imperfectoDeSubjuntivoRa, .imperfectoDeSubjuntivoSe:
      return true
    default:
      return false
    }
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard stem.hasSuffix("i"), ending.hasPrefix("i") else { return (stem, ending) }
    return (stem, String(ending.dropFirst()))
  }

  static let collapse = CollapseDoubleI2()
}
