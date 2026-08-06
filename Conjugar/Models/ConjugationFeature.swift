//
//  ConjugationFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// A composable irregularity layered onto a `RegularRoot` (model = base + an
// ordered list of features, last-wins on slot conflicts).
//
// A feature is two things:
//   - `applies(to:)`  — which (tense, person) slots it touches.
//   - `apply(stem:ending:tense:)` — how it rewrites the
//     regular `(stem, ending)` pair for one of those slots.
//
// **End-anchored constraint.** Every operation must be defined
// relative to the END of the stem (its last consonant / last vowel) or the
// START of the ending — never the start of the stem. That is what makes features
// prefix-invariant: `o-car` on `c` turns `sac` → `saqu`, and so it turns
// `resec` → `reseq` and any other `-car` stem for free, with the prefix riding
// along untouched. `o-yhiatus`/`o-llñ` likewise touch only the ending boundary,
// so `releer` → `releyó` needs no model of its own.
//
// Composition (`Conjugator.compose`) threads the `(stem, ending)` pair through
// the model's features in listed order: feature N sees the pair as rewritten by
// features 1…N-1. Orthogonal changes therefore stack (`a-stem` accents the stem
// vowel, then `o-car` rewrites the stem-final consonant → `ahínque`), and a true
// conflict resolves last-wins (the later feature's output is final).
nonisolated protocol ConjugationFeature: Sendable {
  /// True for each slot this feature transforms.
  func applies(to tense: EngineTense) -> Bool

  /// Rewrite the regular `(stem, ending)` pair for a slot this feature applies
  /// to. Must be end-anchored (see the type doc). Called only when
  /// `applies(to: tense)` is true; returning the pair unchanged is fine when the
  /// trigger letter happens to be absent.
  ///
  /// `regularStem` is the verb's **base** stem (infinitive minus its two-letter
  /// ending), *before* any feature ran — the seam that lets the
  /// 1s/subjunctive features and the residue stem features **rebuild** the
  /// stem from the regular base, discarding a prior diphthong/raise (the
  /// `subj-from-1s` last-wins reset: tener → `teng-`, not `*tieng-`). The other
  /// features ignore it and transform the running `stem` as before.
  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String)

  /// True for a slot that this feature declares **has no form at all** (a
  /// *defective* verb — abolir). The conjugator reports such
  /// a slot as `.noForm` rather than composing a (nonexistent) form. Defaults to
  /// `false`: a feature suppresses nothing unless it opts in (`DefectiveFeature`).
  func suppresses(_ tense: EngineTense) -> Bool
}

extension ConjugationFeature {
  nonisolated func suppresses(_ tense: EngineTense) -> Bool { false }
}

/// The named slot sets the feature catalog refers to by name. **STR** and **WK**
/// are the two recurring sets, and they are deliberately **disjoint**: an -ir
/// verb that both diphthongizes and raises splits its present
/// subjunctive cleanly along this line (PS{1s,2s,3s,3p} = STR, PS{1p,2p} = WK).
nonisolated enum Slot {
  /// **STR** ("stressed stem") = `PI{1s,2s,3s,3p}` + `PS{1s,2s,3s,3p}` + `IMP{2s}`:
  /// the slots where the stress falls on the stem, so a stem-vowel accent (or a
  /// diphthong) surfaces. Deliberately **excludes** voseo present-2s
  /// and imperative-2s: those are built on the regular stem and bypass the
  /// stem-vowel change (`vos enviás`, not *envíás`; `vos pensás`, not *piensás`).
  static func isStressedStem(_ tense: EngineTense) -> Bool {
    switch tense {
    case let .presenteDeIndicativo(pn), let .presenteDeSubjuntivo(pn):
      switch pn {
      case .firstSingular, .secondSingular, .thirdSingular, .thirdPlural:
        return true
      default:
        return false
      }
    case .imperativoAfirmativo(.secondSingular):
      return true
    default:
      return false
    }
  }

  /// **WK** ("weak -ir slots") = `PS{1p,2p}` + `PR{3s,3p}` + `GER` + `IS{all}`:
  /// the unstressed-stem slots where an -ir verb raises e→i / o→u. Disjoint from
  /// STR — note PS{1p,2p} are WK while PS{1s,2s,3s,3p} are STR, which is what
  /// lets the diphthong and raise features each fire on their own PS persons
  /// without conflict. `PR{1s,2s,1p,2p}` are **not** WK (sentí/sentiste/sentimos/
  /// sentisteis stay regular). Voseo slots are never WK.
  static func isWeakIr(_ tense: EngineTense) -> Bool {
    switch tense {
    case let .presenteDeSubjuntivo(pn):
      switch pn {
      case .firstPlural, .secondPlural:
        return true
      default:
        return false
      }
    case .pretérito(.thirdSingular), .pretérito(.thirdPlural),
         .gerundio,
         .imperfectoDeSubjuntivoRa, .imperfectoDeSubjuntivoSe:
      return true
    default:
      return false
    }
  }

  /// **subj-from-1s** target = `PI{1s}` + `PS{all}`. The productive features (`g1-g`,
  /// `g1-ig`, `zc`) and any explicit irregular-1s residue rebuild the stem from
  /// the regular base here, so the whole present subjunctive is built on the
  /// PI-1s stem and a prior diphthong is reset
  /// (tengo/tenga, not `*tiengo`). Deliberately excludes `PI{2s,3s,3p}`, where a
  /// diphthong still surfaces (tienes/tiene/tienen).
  static func isSubjFrom1s(_ tense: EngineTense) -> Bool {
    switch tense {
    case .presenteDeIndicativo(.firstSingular), .presenteDeSubjuntivo:
      return true
    default:
      return false
    }
  }

  /// `y-add`'s slots = `PI{1s,2s,3s,3p}` + `PS{all}` + `IMP{2s}` (construir →
  /// construyo/construyes/construye/construyen, construya, **construye**). Like
  /// subj-from-1s but also the stressed PI persons and the tú imperative. The
  /// tú imperative is included because it equals PI{3s} (construye, oye, arguye) —
  /// without it the glide would be lost there (*construe). It stays out of the
  /// voseo/vosotros imperatives, which are regular (construí / construid).
  static func isYAdd(_ tense: EngineTense) -> Bool {
    switch tense {
    case let .presenteDeIndicativo(pn):
      switch pn {
      case .firstSingular, .secondSingular, .thirdSingular, .thirdPlural:
        return true
      default:
        return false
      }
    case .presenteDeSubjuntivo, .imperativoAfirmativo(.secondSingular):
      return true
    default:
      return false
    }
  }

  /// **Preterite system** = `PR{all}` + `IS{all}` (both -ra and -se). A strong /
  /// suppletive preterite stem drives the imperfect subjunctives too (the
  /// "strong preterite" derivation rule), so the strong-stem and strong-ending
  /// features span this whole set.
  static func isPreteriteSystem(_ tense: EngineTense) -> Bool {
    switch tense {
    case .pretérito, .imperfectoDeSubjuntivoRa, .imperfectoDeSubjuntivoSe:
      return true
    default:
      return false
    }
  }

  /// **Future system** = `FU{all}` + `CO{all}`. One future-stem override drives
  /// both the future and the conditional (the "future stem" derivation rule).
  static func isFutureSystem(_ tense: EngineTense) -> Bool {
    switch tense {
    case .futuro, .condicional:
      return true
    default:
      return false
    }
  }

  /// **IM{all}** = the imperfect indicative. The only verbs with an irregular
  /// imperfect are `ser`/`ir`/`ver`; `ver`/`prever` route their
  /// `ve-`/`preve-` imperfect stem through `StemFeature` here (regular `-er`
  /// endings on the rebuilt stem), while `ser`/`ir` use literal residue.
  static func isImperfect(_ tense: EngineTense) -> Bool {
    if case .imperfectoDeIndicativo = tense { return true }
    return false
  }

  /// **PS{all}** = the whole present subjunctive. The suppletive-subjunctive
  /// verbs (`ser` sea-, `haber` haya-, `saber` sep-, `caber` quep-, `ir` vaya-)
  /// rebuild a fresh subjunctive stem here without touching the (separately
  /// suppletive) present indicative 1s — so this is `subj-from-1s` minus PI{1s}.
  static func isPresentSubjunctive(_ tense: EngineTense) -> Bool {
    if case .presenteDeSubjuntivo = tense { return true }
    return false
  }
}
