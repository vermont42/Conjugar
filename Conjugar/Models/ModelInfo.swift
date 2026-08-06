//
//  ModelInfo.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The Models tab's row model: one displayable row per verb model in
// `ModelCatalog`, carrying the class number, the exemplar, every verb that
// conjugates with the model, and a computed irregularity percent.
//
// The prefix-accent alias classes (29-2 satisfacer / 30-1 suponer / 31-1
// obtener / 32-1 convenir) ride their parents' models byte-for-byte (see
// `ModelCatalog`), so they get no rows of their own; their verbs fold into the
// parent row's list. That yields 102 rows from the catalog's 106 class numbers.
//
// The irregularity percent is not stored anywhere — it is computed by
// conjugating the exemplar's every simple-tense slot twice, once normally and
// once against a feature-less regular model (the same baseline
// `TenseBridge.regularForm` diffs against), and counting the slots whose
// results differ. An error is a distinct value, so a defective verb's formless
// slots count as deviations from the regular paradigm.

import Foundation

struct ModelInfo: Identifiable, Hashable {
  let classNumber: String
  let exemplar: String
  let verbs: [String]
  let irregularityPercent: Int

  /// The class number uniquely identifies a model row — used for SwiftUI
  /// navigation and list identity.
  var id: String { classNumber }

  /// Every displayable model row, built once. Order is unspecified; `ModelSort`
  /// supplies the display orders.
  static let all: [ModelInfo] = {
    var verbsByClass: [String: [String]] = [:]
    for entry in VerbMap.shared.entries.values {
      for classNumber in entry.classNumbers {
        let rowClass = parentByAlias[classNumber] ?? classNumber
        verbsByClass[rowClass, default: []].append(entry.infinitive)
      }
    }
    return ModelCatalog.classNumbers
      .filter { parentByAlias[$0] == nil }
      .map { classNumber in
        guard let exemplar = ModelCatalog.exemplar(forClass: classNumber) else {
          fatalError("No exemplar for class \(classNumber).")
        }
        return ModelInfo(
          classNumber: classNumber,
          exemplar: exemplar,
          verbs: (verbsByClass[classNumber] ?? []).sorted {
            $0.compare($1, locale: VerbSort.spanish) == .orderedAscending
          },
          irregularityPercent: irregularityPercent(exemplar: exemplar)
        )
      }
  }()

  /// The alias classes that ride a parent's model and exemplar verbatim; their
  /// verbs display under the parent's row.
  static let parentByAlias = ["29-2": "29", "30-1": "30", "31-1": "31", "32-1": "32"]

  /// The percent of the exemplar's slots that deviate from a feature-less
  /// regular conjugation of the same infinitive, rounded to the nearest integer.
  static func irregularityPercent(exemplar: String) -> Int {
    guard let base = RegularRoot(infinitive: exemplar) else {
      return 0
    }
    let regularModel = VerbModel(base: base)
    let differingCount = allSlots.filter { slot in
      Conjugator.conjugate(infinitive: exemplar, tense: slot) != Conjugator.conjugate(infinitive: exemplar, tense: slot, model: regularModel)
    }.count
    return Int((Double(differingCount) / Double(allSlots.count) * 100.0).rounded())
  }

  /// The compared slot set: every person-bearing simple tense across all seven
  /// persons, plus the two non-finite forms.
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
}
