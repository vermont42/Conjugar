//
//  OrthographicFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Taxonomy §4.1 — orthographic (spelling-only) features. Two sub-kinds:
//
//   1. Stem-final consonant swaps triggered by the *following* ending vowel
//      (`StemFinalConsonant`): c↔qu, g↔gu, gu↔gü/g, z↔c, c↔z, qu↔c. These keep
//      the spoken consonant constant across a front/back ending vowel.
//   2. i/y changes at the stem↔ending junction (`IYHiatus` = `o-yhiatus`,
//      `AbsorbIAfterPalatal` = `o-llñ`): these rewrite the ending, not the
//      stem-final consonant.
//
// All operations are end-anchored (see `ConjugationFeature`), so they ride free on
// prefixed verbs (`reconocer`, `releer`, …).

// MARK: - Stem-final consonant swaps (o-car … o-quc)

/// The two slot patterns a consonant swap fires in. A consonant's spelling has
/// to change exactly when the ending's leading vowel crosses the front/back line.
enum ConsonantTrigger {
  /// Fires before a front vowel **e**: `PR{1s}` + `PS{all}`. (-ar verbs: the
  /// preterite 1s `-é` and the whole present subjunctive `-e…`.)
  case beforeFrontE
  /// Fires before a back vowel **a/o**: `PI{1s}` + `PS{all}`. (-er/-ir verbs: the
  /// present indicative 1s `-o` and the whole present subjunctive `-a…`.)
  case beforeBackAO

  func applies(to tense: EngineTense) -> Bool {
    switch tense {
    case .presenteDeSubjuntivo:
      return true
    case .pretérito(.firstSingular):
      return self == .beforeFrontE
    case .presenteDeIndicativo(.firstSingular):
      return self == .beforeBackAO
    default:
      return false
    }
  }
}

/// A stem-final consonant swap: replace the trailing `from` of the stem with
/// `to` in the trigger's slots. The slot set guarantees the triggering vowel, so
/// no inspection of the ending is needed.
struct StemFinalConsonant: ConjugationFeature {
  let from: String
  let to: String
  let trigger: ConsonantTrigger

  func applies(to tense: EngineTense) -> Bool {
    trigger.applies(to: tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard stem.hasSuffix(from) else { return (stem, ending) }
    return (String(stem.dropLast(from.count)) + to, ending)
  }

  // The §4.1 catalog. `-ar` swaps fire before -e; `-er`/`-ir` swaps before -a/-o.
  static let oCar = StemFinalConsonant(from: "c", to: "qu", trigger: .beforeFrontE)   // tocar → toqué, toque
  static let oGar = StemFinalConsonant(from: "g", to: "gu", trigger: .beforeFrontE)   // pagar → pagué, pague
  static let oGuar = StemFinalConsonant(from: "gu", to: "gü", trigger: .beforeFrontE) // averiguar → averigüé
  static let oZar = StemFinalConsonant(from: "z", to: "c", trigger: .beforeFrontE)    // cazar → cacé, cace
  static let oCz = StemFinalConsonant(from: "c", to: "z", trigger: .beforeBackAO)     // vencer → venzo; fruncir → frunzo
  static let oGj = StemFinalConsonant(from: "g", to: "j", trigger: .beforeBackAO)     // coger → cojo; dirigir → dirijo
  static let oGug = StemFinalConsonant(from: "gu", to: "g", trigger: .beforeBackAO)   // distinguir → distingo
  static let oQuc = StemFinalConsonant(from: "qu", to: "c", trigger: .beforeBackAO)   // delinquir → delinco
}

// MARK: - i/y at the stem↔ending junction (o-yhiatus, o-llñ)

/// The slots both junction features share: unstressed -i- of the ending sits
/// between the stem-final vowel/palatal and the next vowel. `PR{3s,3p}` + `GER` +
/// `IS{all}` — every ending here begins with that -i- (-ió, -ieron, -iendo,
/// -iera…, -iese…).
private func isIGlideSlot(_ tense: EngineTense) -> Bool {
  switch tense {
  case .pretérito(.thirdSingular), .pretérito(.thirdPlural),
       .gerundio,
       .imperfectoDeSubjuntivoRa, .imperfectoDeSubjuntivoSe:
    return true
  default:
    return false
  }
}

/// `o-yhiatus` — unstressed -i- between vowels becomes -y- (leer → leyó, leyendo,
/// leyera), and the regular -i- forms that *aren't* rewritten take a written
/// accent to mark the hiatus (leíste, leímos, leísteis, leído). Covers
/// -eer/-aer/-oer verbs.
struct IYHiatus: ConjugationFeature {
  /// The remaining regular -i- forms that take a written accent: `PR{2s,1p,2p}`
  /// (the -i…- preterite forms whose stress is on the ending) + `PP`, plus the two
  /// present-system -i--initial endings the preterite/PP slots don't reach:
  /// `PI{1p}` (-imos) and `IMP{2p}` (-id). The accent fires only when the ending
  /// starts with -i- AND the stem's last char is a strong vowel (a/e/o), so adding
  /// these slots is a no-op for the -er users (leer/caer/traer/raer/roer: -emos/-ed
  /// don't start with -i-) and the weak-stem -ir user (construir: stem ends in -u-,
  /// guard blocks → construimos/construid). It surfaces only on oír (oímos/oíd) and
  /// reír (reímos/reíd), where the stem's last vowel is a strong o/e.
  private func isAccentSlot(_ tense: EngineTense) -> Bool {
    switch tense {
    case .pretérito(.secondSingular), .pretérito(.firstPlural), .pretérito(.secondPlural),
         .participioPasado,
         .presenteDeIndicativo(.firstPlural), .imperativoAfirmativo(.secondPlural):
      return true
    default:
      return false
    }
  }

  func applies(to tense: EngineTense) -> Bool {
    isIGlideSlot(tense) || isAccentSlot(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard ending.hasPrefix("i") else { return (stem, ending) }
    let rest = ending.dropFirst()
    if isIGlideSlot(tense) {
      // The i→y glide fires regardless of the preceding vowel (leyó, oyó, and
      // construyó / huyó after a weak -u-).
      return (stem, "y" + rest)
    }
    // Accent slot: the written accent marks a true hiatus, so it fires **only
    // when the -i- follows a strong vowel (a/e/o)** — leíste/caído/oímos. After
    // a weak vowel there is no hiatus, so the -uir verbs take no accent:
    // construiste / construido (Phase 4 §4.5 crux). This keeps the accent
    // end-anchored to the stem's last vowel.
    let strongVowels: Set<Character> = ["a", "e", "o"]
    guard let last = stem.last, strongVowels.contains(last) else { return (stem, ending) }
    return (stem, "í" + rest)
  }

  static let oYhiatus = IYHiatus()
}

/// `o-llñ` — after a palatal stem-final ll/ñ the unstressed -i- of the ending is
/// absorbed (-ió→-ó, -ieron→-eron, -iendo→-endo, -iera→-era): tañer → tañó,
/// tañendo; bullir → bulló. Same i-glide slots as `o-yhiatus`, but the -i- is
/// dropped rather than turned to -y-, and no written accents are added.
struct AbsorbIAfterPalatal: ConjugationFeature {
  func applies(to tense: EngineTense) -> Bool {
    isIGlideSlot(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard ending.hasPrefix("i") else { return (stem, ending) }
    return (stem, String(ending.dropFirst()))
  }

  static let oLlñ = AbsorbIAfterPalatal()
}
