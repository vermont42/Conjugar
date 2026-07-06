//
//  ModelInfoTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

struct ModelInfoTests {
  private func info(_ classNumber: String) -> ModelInfo? {
    ModelInfo.all.first { $0.classNumber == classNumber }
  }

  @Test func catalogYields102RowsWithNoAliasRows() {
    // 106 class numbers − the 4 prefix-accent aliases folded into their parents.
    #expect(ModelInfo.all.count == 102)
    for alias in ModelInfo.parentByAlias.keys {
      #expect(info(alias) == nil)
    }
  }

  @Test func aliasClassesFoldIntoParentRows() {
    // 29-2 satisfacer rides hacer's model, so satisfacer lists under row 29.
    let hacer = info("29")
    #expect(hacer?.exemplar == "hacer")
    #expect(hacer?.verbs.contains("satisfacer") == true)
    #expect(info("30")?.verbs.contains("suponer") == true)
    #expect(info("31")?.verbs.contains("obtener") == true)
    #expect(info("32")?.verbs.contains("convenir") == true)
  }

  @Test func verbListsCoverEveryVerbSense() {
    // Every (verb, sense) pair lands in exactly one row's list, so the row
    // counts sum to the total sense count (homonyms carry two class numbers).
    let senseCount = VerbMap.shared.entries.values.reduce(0) { $0 + $1.classNumbers.count }
    let rowCount = ModelInfo.all.reduce(0) { $0 + $1.verbs.count }
    #expect(rowCount == senseCount)
  }

  @Test func verbListsAreSortedWithSpanishCollation() {
    let verbs = info("1")?.verbs ?? []
    #expect(verbs == verbs.sorted { $0.compare($1, locale: VerbSort.spanish) == .orderedAscending })
    #expect(verbs.contains("cantar"))
  }

  @Test func regularClassesScoreZeroIrregularity() {
    #expect(info("1")?.irregularityPercent == 0)
    #expect(info("2")?.irregularityPercent == 0)
    #expect(info("3")?.irregularityPercent == 0)
  }

  @Test func irregularClassesScorePositiveIrregularity() {
    let pensar = info("4A")?.irregularityPercent ?? 0
    #expect(pensar > 0)
    #expect(pensar < 50)

    let ser = info("19")?.irregularityPercent ?? 0
    #expect(ser >= 50)

    let ir = info("24")?.irregularityPercent ?? 0
    #expect(ir >= 50)
  }
}
