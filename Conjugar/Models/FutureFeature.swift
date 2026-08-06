//
//  FutureFeature.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Irregular future / conditional. One future-stem override drives
// the **whole** future *and* conditional (the "future stem" derivation rule):
// they share the stem and differ only in the endings. Because `RegularRoot`'s
// FU/CO endings bake in the theme vowel (`-eré`, `-ería`, …), the lowest-risk
// realization is an **ending rewrite** over `FU{all}` + `CO{all}` that strips the
// theme vowel and emits the irregular connector — uniform with how the strong
// preterites rewrite their endings. The stem stays the regular base (which, in FU/CO, is never
// touched by a diphthong/raise — STR/WK exclude the future system):
//
//   - `f-drope` (drop the theme -e-, -er → -r): connector "" → hab+**ré** = habré,
//     quer+**ré** = que**rr**é (the doubled r falls out), pod+ré, sab+ré, cab+ré.
//   - `f-dr` (insert d): connector "d" → ten+**dré** = tendré, pon+dré, sal+dré,
//     val+dré, ven+dré.
//
// `f-contract` (hacer→har-, decir→dir-) is connector "" here **plus** a
// `StemFeature.contractedFuture` that swaps the stem (hac→ha, dec→di): ha+ré =
// haré, di+ré = diré.
nonisolated struct FutureEndings: ConjugationFeature {
  /// Inserted between the stem and the bare future/conditional marker: "" for
  /// `f-drope`/`f-contract`, "d" for `f-dr`.
  let connector: String

  func applies(to tense: EngineTense) -> Bool {
    Slot.isFutureSystem(tense)
  }

  func apply(stem: String, ending: String, tense: EngineTense, regularStem: String) -> (stem: String, ending: String) {
    guard let person = tense.personNumber else { return (stem, ending) }
    let key: EnginePersonNumber = (person == .secondSingularVos) ? .secondSingular : person
    let markers: [EnginePersonNumber: String]
    switch tense {
    case .futuro:
      markers = Self.futureMarkers
    case .condicional:
      markers = Self.conditionalMarkers
    default:
      return (stem, ending)
    }
    guard let marker = markers[key] else { return (stem, ending) }
    return (stem, connector + marker)
  }

  // The bare future/conditional markers (theme vowel already dropped) the
  // connector prefixes: "r" + the simple future/conditional person endings.
  private static let futureMarkers: [EnginePersonNumber: String] = [
    .firstSingular: "ré", .secondSingular: "rás", .thirdSingular: "rá",
    .firstPlural: "remos", .secondPlural: "réis", .thirdPlural: "rán"
  ]
  private static let conditionalMarkers: [EnginePersonNumber: String] = [
    .firstSingular: "ría", .secondSingular: "rías", .thirdSingular: "ría",
    .firstPlural: "ríamos", .secondPlural: "ríais", .thirdPlural: "rían"
  ]

  static let fDrope = FutureEndings(connector: "")  // haber→habr-, saber→sabr-, querer→querr-
  static let fDr = FutureEndings(connector: "d")    // tener→tendr-, poner→pondr-, salir→saldr-
  static let fContract = FutureEndings(connector: "") // hacer→har-, decir→dir- (+ contractedFuture stem)
}
