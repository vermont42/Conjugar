//
//  ConjugatorResolverTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 6/13/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// Phase 6 (C) — the **resolver**. `VerbMapTests` drives the data path with an
// *explicit* catalog model; these tests drive the no-`model:` entry points
// (`conjugate(infinitive:tense:)` / `conjugateAll(...)`), which now resolve the
// model from the map themselves. The gate (cruxes 1/4/5) asks that the per-class
// sample and the prefix compounds conjugate **through the verb name alone** — so
// here we replay `VerbMapTests`'s samples through the convenience entry points,
// plus the homonym default, the fallback policy, and the all-forms wiring.
@Suite("Conjugator resolver (Phase 6 C — conjugate by name)")
struct ConjugatorResolverTests {
  /// Conjugate by **verb name alone** — the no-`model:` path under test. Returns
  /// the form, or nil on failure (so a failure surfaces as a clear mismatch).
  static func form(_ infinitive: String, _ tense: EngineTense) -> String? {
    if case .success(let conjugated) = Conjugator.conjugate(infinitive: infinitive, tense: tense) {
      return conjugated
    }
    return nil
  }

  // MARK: - Per-class sample, conjugated by name (gate; crux 5)

  // The same representative-per-class sample `VerbMapTests` checks through an
  // explicit model — here through the resolver, proving the no-`model:` path looks
  // up verb → class → catalog model → conjugate for every class.
  @Test("per-class sample conjugates correctly by name", arguments: VerbMapTests.perClassSample)
  func perClassByName(infinitive: String, tense: EngineTense, expected: String) {
    #expect(Self.form(infinitive, tense) == expected, "\(infinitive) \(tense)")
  }

  // MARK: - Prefix payoff, conjugated by name (gate; crux 1)

  // Each compound maps to its base verb's class; the resolver hands the catalog
  // model to the conjugator, which conjugates the compound's OWN stem and the
  // end-anchored features ride along — incl. the reír/oír families.
  @Test("prefix payoff: compounds conjugate on their own stem by name", arguments: VerbMapTests.prefixSample)
  func prefixPayoffByName(infinitive: String, tense: EngineTense, expected: String) {
    #expect(Self.form(infinitive, tense) == expected, "\(infinitive) \(tense)")
  }

  // MARK: - Homonym default sense (gate; crux 4)

  // The resolver conjugates the **default** (first/everyday) sense; the other
  // sense stays retrievable via the map (VerbMapTests covers the alternate).
  @Test("homonyms conjugate their default sense by name", arguments: [
    ("apostar", "apuesto"),  // default 4B (bet) — mostrar diphthong, not regular 1 (station)
    ("asolar",  "asuelo"),   // default 4B (raze)
    ("aterrar", "aterro"),   // default 1 (terrify) — regular, not 4A (demolish → atierro)
    ("atestar", "atiesto"),  // default 4A (stuff) — diphthong, not regular 1 (attest)
  ])
  func homonymDefaultByName(infinitive: String, expected: String) {
    #expect(Self.form(infinitive, .presenteDeIndicativo(.firstSingular)) == expected)
  }

  // MARK: - Fallback policy (gate)

  // A verb NOT in the 4,818-verb map falls back to a regular base inferred from the
  // ending (documented policy in `Conjugator.resolvedModel`). It must (a) really be
  // off-list and (b) conjugate as a plain regular verb of its conjugation.
  @Test("off-list verbs fall back to regular-by-ending", arguments: [
    ("plopar", EngineTense.presenteDeIndicativo(.firstSingular), "plopo"),
    ("plopar", .pretérito(.thirdSingular), "plopó"),
    ("zumber", .presenteDeIndicativo(.firstSingular), "zumbo"),
    ("frobir", .gerundio, "frobiendo"),
  ])
  func offListFallback(infinitive: String, tense: EngineTense, expected: String) {
    #expect(VerbMap.shared.entry(for: infinitive) == nil, "\(infinitive) unexpectedly in the map")
    #expect(Self.form(infinitive, tense) == expected, "\(infinitive) \(tense)")
  }

  @Test("invalid infinitives still fail the same way through the resolver")
  func invalidStillFails() {
    if case .success = Conjugator.conjugate(infinitive: "hello", tense: .gerundio) {
      Issue.record("Infinitive not ending in -ar/-er/-ir should fail, even via the resolver.")
    }
    if case .success = Conjugator.conjugate(infinitive: "a", tense: .gerundio) {
      Issue.record("Too-short infinitive should fail.")
    }
  }

  // MARK: - The resolver matches the explicit-model path (consistency)

  // For a spread of mapped verbs, conjugating by name === conjugating with the
  // model the map points at. This pins the no-`model:` path to the (independently
  // tested) explicit path so the two can never silently diverge.
  @Test("by-name == explicit model for mapped verbs", arguments: [
    "tener", "oír", "reír", "conducir", "hacer", "construir", "ir", "haber", "abrir", "cantar",
  ])
  func byNameMatchesExplicit(infinitive: String) {
    guard
      let entry = VerbMap.shared.entry(for: infinitive),
      let model = ModelCatalog.model(forClass: entry.classNumber)
    else { Issue.record("\(infinitive) did not resolve in the map/catalog"); return }
    let slots: [EngineTense] = [
      .presenteDeIndicativo(.firstSingular), .pretérito(.thirdSingular),
      .futuro(.firstSingular), .participioPasado, .gerundio,
      .imperativoAfirmativo(.secondSingular),
    ]
    for tense in slots {
      let byName = Conjugator.conjugate(infinitive: infinitive, tense: tense)
      let byModel = Conjugator.conjugate(infinitive: infinitive, tense: tense, model: model)
      #expect(byName == byModel, "\(infinitive) \(tense): by-name \(byName) != by-model \(byModel)")
    }
  }

  // MARK: - conjugateAll by name carries the model's alternates

  // The no-`model:` all-forms path resolves the same model, so an alternate-paradigm
  // verb surfaces its alternates by name (erguir yergo/irgo; roer's three 1s forms).
  @Test("conjugateAll by name surfaces alternates")
  func conjugateAllByName() {
    if case .success(let forms) = Conjugator.conjugateAll(infinitive: "erguir", tense: .presenteDeIndicativo(.firstSingular)) {
      #expect(forms == ["yergo", "irgo"], "erguir present-1s all forms: \(forms)")
    } else {
      Issue.record("erguir conjugateAll by name failed")
    }
    if case .success(let forms) = Conjugator.conjugateAll(infinitive: "roer", tense: .presenteDeIndicativo(.firstSingular)) {
      #expect(forms == ["roo", "roigo", "royo"], "roer present-1s all forms: \(forms)")
    } else {
      Issue.record("roer conjugateAll by name failed")
    }
    // A regular verb degenerates to exactly [onlyForm].
    if case .success(let forms) = Conjugator.conjugateAll(infinitive: "hablar", tense: .presenteDeIndicativo(.firstSingular)) {
      #expect(forms == ["hablo"])
    } else {
      Issue.record("hablar conjugateAll by name failed")
    }
  }
}
