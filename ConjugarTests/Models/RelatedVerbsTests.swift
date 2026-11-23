//
//  RelatedVerbsTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

/// The relations behind the verb page's Related Verbs card (browse plan, Phase 8). MainActor only
/// because one test reads `ModelInfo`.
@MainActor
struct RelatedVerbsTests {
  private func related(_ infinitive: String) throws -> RelatedVerbs {
    try #require(VerbRelations.related(to: infinitive))
  }

  @Test func tenerLeadsItsCompounds() throws {
    let tener = try related("tener")
    #expect(tener.root == "tener")
    #expect(Set(tener.builtOnRoot) == ["mantener", "obtener", "sostener", "detener", "contener", "retener", "entretener", "abstener", "atener"])
    #expect(!tener.builtOnRoot.contains("tener"))
    // Every verb of tener's model is built on tener, so the model row has nothing to add.
    #expect(tener.modelRelatives.isEmpty)
    #expect(tener.modelClassNumber == "31")
  }

  @Test func aCompoundListsItsRootFirst() throws {
    let detener = try related("detener")
    #expect(detener.root == "tener")
    #expect(detener.builtOnRoot.first == "tener")
    #expect(!detener.builtOnRoot.contains("detener"))
    #expect(detener.builtOnRoot.contains("mantener"))
    // An alias class (31-1) shows under its parent's row.
    #expect(detener.modelClassNumber == "31")
  }

  @Test func decirLeadsCompoundsOfItsSubClasses() throws {
    // bendecir and maldecir are 28-2, contradecir, desdecir, and predecir 28-1, beside decir's 28.
    let decir = try related("decir")
    #expect(Set(decir.builtOnRoot) == ["bendecir", "contradecir", "desdecir", "maldecir", "predecir"])
    #expect(VerbRelations.shared.baseByVerb["bendecir"] == "decir")
  }

  @Test func theRootFollowsNestedPrefixes() throws {
    #expect(VerbRelations.shared.baseByVerb["desaparecer"] == "aparecer")
    #expect(try related("desaparecer").root == "parecer")
    #expect(try related("presuponer").root == "poner")
  }

  @Test func aRegularVerbHasCompoundsAndModelRelatives() throws {
    let formar = try related("formar")
    #expect(formar.root == "formar")
    #expect(Set(formar.builtOnRoot) == ["informar", "transformar", "conformar", "reformar", "deformar", "desinformar"])
    #expect(formar.modelClassNumber == "1")
    #expect(formar.modelVerbCount == ModelInfo.byClassNumber["1"]?.verbs.count)
    // One verb per other root, most frequent first, none built on formar.
    #expect(Array(formar.modelRelatives.prefix(3)) == ["pasar", "dejar", "llevar"])
    #expect(!formar.modelRelatives.contains { VerbRelations.shared.rootByVerb[$0] == "formar" })
  }

  @Test func modelRelativesAreOnePerRootAndByFrequency() throws {
    let hablar = try related("hablar")
    let roots = hablar.modelRelatives.map { VerbRelations.shared.rootByVerb[$0] ?? $0 }
    #expect(Set(roots).count == roots.count)
    let ranks = hablar.modelRelatives.compactMap { VerbMap.shared.entry(for: $0)?.frequencyRank }
    #expect(ranks == ranks.sorted())
    // A root that uses the model represents its group: pasar, not repasar.
    #expect(hablar.modelRelatives.contains("pasar"))
    #expect(!hablar.modelRelatives.contains("repasar"))
  }

  @Test func theClassRuleKeepsUnrelatedVerbsApart() {
    let bases = VerbRelations.shared.baseByVerb
    #expect(bases["presentar"] == nil)  // 1, not sentar's 4A
    #expect(bases["andar"] == nil)  // not dar
    #expect(bases["toser"] == nil)  // to- is not a prefix
    #expect(bases["llamar"] == nil)  // ll- is not a prefix
    #expect(bases["representar"] == "presentar")
  }

  @Test func falseCompoundsHaveNoBase() {
    for verb in ["trabajar", "escapar", "solicitar", "estimar", "comparar", "autorizar"] {
      #expect(VerbRelations.shared.baseByVerb[verb] == nil, "\(verb)")
    }
    // Every listed verb is in the map, so a misspelling cannot hide.
    for verb in VerbRelations.falseCompounds {
      #expect(VerbMap.shared.entry(for: verb) != nil, "\(verb)")
    }
  }

  @Test func everyBaseIsAVerbOfTheSameFamily() throws {
    for (verb, base) in VerbRelations.shared.baseByVerb {
      let verbEntry = try #require(VerbMap.shared.entry(for: verb))
      let baseEntry = try #require(VerbMap.shared.entry(for: base))
      #expect(verb.hasSuffix(base) && verb != base)
      #expect(VerbRelations.classFamily(verbEntry.classNumber) == VerbRelations.classFamily(baseEntry.classNumber))
      #expect(VerbRelations.prefixes.contains(String(verb.dropLast(base.count))))
    }
  }

  @Test func thePillOpensTheModelThePageNames() {
    // An alias class's verb opens its parent's row, whose exemplar the pill names.
    #expect(ModelInfo.row(for: "contener")?.classNumber == "31")
    #expect(ModelInfo.row(for: "contener")?.exemplar == "tener")
    #expect(ModelInfo.row(for: "hablar")?.exemplar == "cantar")
    #expect(ModelInfo.row(for: "conducir")?.verbs.contains("traducir") == true)
    #expect(ModelInfo.row(for: "xyzzy") == nil)
  }

  @Test func aVerbWithNoRelativesIsEmpty() throws {
    // ser has its own model, and nothing is built on it.
    #expect(try related("ser").isEmpty)
    #expect(VerbRelations.related(to: "xyzzy") == nil)
  }

  @Test func theCountsInTheJournalHold() {
    // docs/blog_notes.md and the plan's note quote these.
    let index = VerbRelations.shared
    #expect(index.baseByVerb.count == 976)
    #expect(index.verbsByRoot.values.filter { $0.count > 1 }.count == 605)
  }
}
