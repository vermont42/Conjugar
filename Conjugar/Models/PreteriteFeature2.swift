//
//  PreteriteFeature2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Taxonomy §4.6 — strong / suppletive preterites. A strong preterite **replaces
// the endings** of `PR{all}`, and because the imperfect subjunctives derive from
// the preterite (the §1 "strong preterite" derivation rule), it replaces the
// `IS{all}` endings too. The *stem* a strong preterite runs on is per-verb
// residue (`StemFeature2.strongPreterite`); this feature owns only the **endings**.
//
// Crux of base-independence (the andar/estar proof): a strong preterite forces
// the `-ie-` family of IS endings **regardless of base** — `-ar` verbs included.
// So `andar` (cantar base) → anduve…anduvieron / **anduviera** (not `*anduvara`).
// On an `-er`/`-ir` base the IS override is a no-op (`-iera` is already regular).
struct PreteriteEndings2: Feature2 {
  /// Endings keyed by person for the preterite and the two imperfect
  /// subjunctives. `vos` falls back to the `tú` (secondSingular) form, as in the
  /// regular paradigm.
  let pr: [EnginePersonNumber: String]
  let isRa: [EnginePersonNumber: String]
  let isSe: [EnginePersonNumber: String]

  func applies(to tense: EngineTense) -> Bool {
    Slot2.isPreteriteSystem(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard let person = tense.personNumber else { return (stem, ending) }
    let key: EnginePersonNumber = (person == .secondSingularVos) ? .secondSingular : person
    let table: [EnginePersonNumber: String]
    switch tense {
    case .pretérito:
      table = pr
    case .imperfectoDeSubjuntivoRa:
      table = isRa
    case .imperfectoDeSubjuntivoSe:
      table = isSe
    default:
      return (stem, ending)
    }
    guard let replacement = table[key] else { return (stem, ending) }
    return (stem, replacement)
  }

  // The regular -er/-ir imperfect-subjunctive endings, forced regardless of base.
  private static let regularIsRa: [EnginePersonNumber: String] = [
    .firstSingular: "iera", .secondSingular: "ieras", .thirdSingular: "iera",
    .firstPlural: "iéramos", .secondPlural: "ierais", .thirdPlural: "ieran"
  ]
  private static let regularIsSe: [EnginePersonNumber: String] = [
    .firstSingular: "iese", .secondSingular: "ieses", .thirdSingular: "iese",
    .firstPlural: "iésemos", .secondPlural: "ieseis", .thirdPlural: "iesen"
  ]
  // The j-preterite imperfect subjunctive: no -i- after the j (dijera, condujese).
  private static let jIsRa: [EnginePersonNumber: String] = [
    .firstSingular: "era", .secondSingular: "eras", .thirdSingular: "era",
    .firstPlural: "éramos", .secondPlural: "erais", .thirdPlural: "eran"
  ]
  private static let jIsSe: [EnginePersonNumber: String] = [
    .firstSingular: "ese", .secondSingular: "eses", .thirdSingular: "ese",
    .firstPlural: "ésemos", .secondPlural: "eseis", .thirdPlural: "esen"
  ]

  /// `sp-end` — the "grave" strong preterite (unstressed 1s/3s): e, iste, o,
  /// imos, isteis, **ieron**; IS = regular `-iera…/-iese…`.
  /// tener (tuve…/tuviera), andar (anduve…, 35), estar (estuve…, 20), haber,
  /// poner, poder, saber, querer, caber.
  static let spEnd = PreteriteEndings2(
    pr: [
      .firstSingular: "e", .secondSingular: "iste", .thirdSingular: "o",
      .firstPlural: "imos", .secondPlural: "isteis", .thirdPlural: "ieron"
    ],
    isRa: regularIsRa,
    isSe: regularIsSe
  )

  /// `sp-jend` — the j-preterite: 3p is **eron** (no -i- after j), IS likewise
  /// drops the -i- (dijera, condujese). decir (28), conducir (34), traer (33).
  static let spJend = PreteriteEndings2(
    pr: [
      .firstSingular: "e", .secondSingular: "iste", .thirdSingular: "o",
      .firstPlural: "imos", .secondPlural: "isteis", .thirdPlural: "eron"
    ],
    isRa: jIsRa,
    isSe: jIsSe
  )

  /// `wp-i` — the weak monosyllabic -i preterite: i, iste, **io**, imos, isteis,
  /// ieron (unaccented monosyllables di/dio, vi/vio); IS forced to regular
  /// `-iera…` (so dar → diera, not `*dara`). dar (25), ver (14).
  static let wpI = PreteriteEndings2(
    pr: [
      .firstSingular: "i", .secondSingular: "iste", .thirdSingular: "io",
      .firstPlural: "imos", .secondPlural: "isteis", .thirdPlural: "ieron"
    ],
    isRa: regularIsRa,
    isSe: regularIsSe
  )
}

// `pret-fue` — the suppletive **fu-** preterite shared by ser and ir (19/24).
// Both the stem (always `fu-`) and the endings are suppletive: fui, fuiste, fue,
// fuimos, fuisteis, fueron; IS fuera…/fuese…. A single feature, since it owns
// stem and endings together (the stem is not derived from any base).
struct SuppletivePreterite2: Feature2 {
  func applies(to tense: EngineTense) -> Bool {
    Slot2.isPreteriteSystem(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard let person = tense.personNumber else { return ("fu", ending) }
    let key: EnginePersonNumber = (person == .secondSingularVos) ? .secondSingular : person
    let table: [EnginePersonNumber: String]
    switch tense {
    case .pretérito:
      table = pr
    case .imperfectoDeSubjuntivoRa:
      table = isRa
    case .imperfectoDeSubjuntivoSe:
      table = isSe
    default:
      return ("fu", ending)
    }
    return ("fu", table[key] ?? ending)
  }

  private let pr: [EnginePersonNumber: String] = [
    .firstSingular: "i", .secondSingular: "iste", .thirdSingular: "e",
    .firstPlural: "imos", .secondPlural: "isteis", .thirdPlural: "eron"
  ]
  private let isRa: [EnginePersonNumber: String] = [
    .firstSingular: "era", .secondSingular: "eras", .thirdSingular: "era",
    .firstPlural: "éramos", .secondPlural: "erais", .thirdPlural: "eran"
  ]
  private let isSe: [EnginePersonNumber: String] = [
    .firstSingular: "ese", .secondSingular: "eses", .thirdSingular: "ese",
    .firstPlural: "ésemos", .secondPlural: "eseis", .thirdPlural: "esen"
  ]

  static let fue = SuppletivePreterite2()
}
