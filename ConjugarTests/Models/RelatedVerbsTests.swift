//
//  RelatedVerbsTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

/// The relations behind the verb page's Related Verbs card. MainActor only because one test reads
/// `ModelInfo`.
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

  /// "Built on" is a claim about etymology. transpirar comes from *spirare*, not pirar; contemplar
  /// from *templum*, not templar's *temperare*; impedir from *pes*, not pedir's *petere*.
  @Test func falseByEtymologyHaveNoBase() {
    for verb in ["transpirar", "espirar", "expirar", "suspirar", "contemplar", "impedir"] {
      #expect(VerbRelations.shared.baseByVerb[verb] == nil, "\(verb)")
    }
  }

  /// Pairs true by etymology stay, however opaque to a learner.
  @Test func opaqueButTruePairsHold() {
    #expect(VerbRelations.shared.baseByVerb["acercar"] == "cercar")
    #expect(VerbRelations.shared.baseByVerb["preparar"] == "parar")
  }

  /// The model's row shows one verb per root, so its "All N" depends on the model's other verbs,
  /// not on how many chips the row has.
  @Test func theModelRowHasMoreWhenItsRootsHideVerbs() {
    func related(relatives: Int, count: Int) -> RelatedVerbs {
      RelatedVerbs(root: "x", builtOnRoot: [], modelClassNumber: "1", modelRelatives: (0..<relatives).map { "v\($0)" }, modelVerbCount: count)
    }
    // Twelve verbs over four other roots, this verb's included: four chips, seven more verbs.
    #expect(related(relatives: 4, count: 12).modelHasMore)
    // Every other verb has a chip.
    #expect(!related(relatives: 4, count: 5).modelHasMore)
    // More roots than chips.
    #expect(related(relatives: 9, count: 10).modelHasMore)
    #expect(!related(relatives: 6, count: 7).modelHasMore)
  }

  @Test func theBaseRowHasMoreBeyondSixVerbs() throws {
    #expect(try related("tener").builtOnRootHasMore)
    #expect(try !related("decir").builtOnRootHasMore)
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
    #expect(ModelInfo.row(for: "conducir")?.verbs.contains { $0.infinitive == "traducir" } == true)
    #expect(ModelInfo.row(for: "xyzzy") == nil)
  }

  @Test func aVerbWithNoRelativesIsEmpty() throws {
    // ser has its own model, and nothing is built on it.
    #expect(try related("ser").isEmpty)
    #expect(VerbRelations.related(to: "xyzzy") == nil)
  }

  @Test func theRelationCountsHold() {
    let index = VerbRelations.shared
    #expect(index.baseByVerb.count == 973)
    #expect(index.verbsByRoot.values.filter { $0.count > 1 }.count == 604)
  }
}
