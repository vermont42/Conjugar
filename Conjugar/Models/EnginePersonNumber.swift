//
//  EnginePersonNumber.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/12/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// New (composition-engine) person model. Suffixed `2` while it lives alongside
// the old `DisplayPersonNumber`; the suffix is dropped once the old engine is removed.
//
// The six oracle persons (yo, tú, él, nosotros, vosotros, ellos) plus `vos`.
// `vos` is supplemental to the book (see the Voseo section of spanish_models.md)
// but is a first-class person from the start so it never becomes a later
// core-type change.
enum EnginePersonNumber: CaseIterable {
  case firstSingular        // yo
  case secondSingular       // tú
  case secondSingularVos    // vos
  case thirdSingular        // él / ella / usted
  case firstPlural          // nosotros
  case secondPlural         // vosotros
  case thirdPlural          // ellos / ellas / ustedes

  /// The six persons the verified oracle covers, in the book's row order
  /// (vos excluded — it is a supplement).
  static let oracleOrder: [EnginePersonNumber] = [
    .firstSingular, .secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]

  /// Persons that have an affirmative imperative form in the regular paradigm.
  /// (usted / ustedes / nosotros imperatives are derived from the present
  /// subjunctive in a later phase; the oracle lists only 2s and 2p.)
  var hasRegularAffirmativeImperative: Bool {
    switch self {
    case .secondSingular, .secondSingularVos, .secondPlural:
      return true
    default:
      return false
    }
  }
}
