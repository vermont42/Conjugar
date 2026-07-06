//
//  ConjugatorAccessorsTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// The engine's app-facing accessors: the Verb screen's raíz futura,
// defectiveness, and verb-type affordances, plus
// the class-number → exemplar-verb lookup that replaces the legacy "parent verb"
// label.
@Suite("Conjugator app-facing accessors")
struct ConjugatorAccessorsTests {
  // MARK: - futureRoot (raíz futura)

  @Test("futureRoot is the stem of the future system", arguments: [
    ("hablar", "hablar"),
    ("comer", "comer"),
    ("subir", "subir"),
    ("tener", "tendr"),
    ("poner", "pondr"),
    ("saber", "sabr"),
    ("hacer", "har"),
    ("decir", "dir"),
    ("ir", "ir"),
    ("obtener", "obtendr")
  ])
  func futureRoot(infinitive: String, expected: String) {
    #expect(Conjugator.futureRoot(infinitive: infinitive) == .success(expected))
  }

  // MARK: - isDefective

  @Test("isDefective is true exactly for verbs with formless slots")
  func isDefective() {
    #expect(Conjugator.isDefective(infinitive: "abolir"))
    #expect(!Conjugator.isDefective(infinitive: "hablar"))
    #expect(!Conjugator.isDefective(infinitive: "tener"))
    // Defective *by legacy data* only — the new engine conjugates these fully.
    #expect(!Conjugator.isDefective(infinitive: "gustar"))
    #expect(!Conjugator.isDefective(infinitive: "soler"))
  }

  // MARK: - verbType (class number → four-way classification)

  @Test("verbType derives from the mapped class number", arguments: [
    ("hablar", VerbType.regularAr),
    ("comer", .regularEr),
    ("subir", .regularIr),
    ("maltear", .regularAr),   // in the map, class 1
    ("tocar", .irregular),     // orthographic sub-class 1-1 counts as irregular
    ("tener", .irregular),
    ("abolir", .irregular),
    ("zumbarrar", .regularAr)  // off-list: falls back to regular-by-ending
  ])
  func verbType(infinitive: String, expected: VerbType) {
    #expect(Conjugator.verbType(infinitive: infinitive) == expected)
  }

  // MARK: - ModelCatalog.exemplar

  @Test("exemplar names the model verb for a class", arguments: [
    ("1", "cantar"),
    ("7A", "conocer"),
    ("31", "tener"),
    ("29-2", "hacer"),  // alias class rides its parent's model
    ("6B-4", "reír"),
    ("10", "oír"),
    ("18", "argüir")
  ])
  func exemplar(classNumber: String, expected: String) {
    #expect(ModelCatalog.exemplar(forClass: classNumber) == expected)
  }

  @Test("every catalog class has an exemplar, and every exemplar is a mapped verb")
  func exemplarCompleteness() {
    for classNumber in ModelCatalog.classNumbers {
      let exemplar = ModelCatalog.exemplar(forClass: classNumber)
      #expect(exemplar != nil, "class \(classNumber) has no exemplar")
      if let exemplar {
        #expect(VerbMap.shared.entry(for: exemplar) != nil, "exemplar \(exemplar) (class \(classNumber)) is not in the verb map")
      }
    }
  }

  @Test("an unknown class has no exemplar")
  func unknownClass() {
    #expect(ModelCatalog.exemplar(forClass: "99Z") == nil)
  }
}
