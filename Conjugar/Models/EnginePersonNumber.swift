//
//  EnginePersonNumber.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The engine-side person model; the UI's `DisplayPersonNumber` vocabulary maps
// onto it via `TenseBridge`.
//
// The six standard persons (yo, tú, él, nosotros, vosotros, ellos) plus `vos`.
// `vos` is supplemental but is a first-class person from the start so it never
// becomes a later core-type change.
nonisolated enum EnginePersonNumber: CaseIterable {
  case firstSingular        // yo
  case secondSingular       // tú
  case secondSingularVos    // vos
  case thirdSingular        // él / ella / usted
  case firstPlural          // nosotros
  case secondPlural         // vosotros
  case thirdPlural          // ellos / ellas / ustedes

  /// The six standard persons, in canonical order (vos excluded — it is a
  /// supplement).
  static let oracleOrder: [EnginePersonNumber] = [
    .firstSingular, .secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]

  /// Persons that have an affirmative imperative form in the regular paradigm.
  /// (usted / ustedes / nosotros imperatives are derived from the present
  /// subjunctive; only 2s and 2p have a regular affirmative imperative.)
  var hasRegularAffirmativeImperative: Bool {
    switch self {
    case .secondSingular, .secondSingularVos, .secondPlural:
      return true
    default:
      return false
    }
  }
}
