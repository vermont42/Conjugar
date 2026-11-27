//
//  VerbSpotlightTests.swift
//  ConjugarTests
//
//  Pins what each verb's Spotlight entry carries.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import CoreSpotlight
import Foundation
import Testing
@testable import Conjugar

@Suite struct VerbSpotlightTests {
  nonisolated private static let forms = VerbSpotlight.formsByInfinitive(in: .bundled)

  private func text(_ infinitive: String) throws -> VerbSpotlight.Text {
    let entry = try #require(VerbMap.shared.entry(for: infinitive))
    return VerbSpotlight.text(for: entry, forms: Self.forms[infinitive] ?? [])
  }

  @Test(arguments: zip(
    ["arrive, come", "put (something) away", "be able to; can", "  go  "],
    [["arrive", "come"], ["put away"], ["be able to", "can"], ["go"]]
  ))
  func glossPhrases(gloss: String, phrases: [String]) {
    #expect(VerbSpotlight.glossPhrases(in: gloss) == phrases)
  }

  /// The forms are read back from the bundled map. The oracle builds them from the engine, cell by
  /// cell, as the map's tool does: every one-word form but the infinitive, each at its first cell.
  /// ir is suppletive, arrepentir reflexive-only, and abolir defective.
  @Test(arguments: ["ir", "tener", "arrepentir", "abolir"])
  func formsAreEveryOneWordFormOnce(infinitive: String) throws {
    let forms = try #require(Self.forms[infinitive])
    let expected = ConjugationMap.oneWordCells.dropFirst().compactMap { ConjugationMap.form(of: infinitive, at: $0) }.uniqued()
    #expect(forms == expected)
    #expect(forms.count == Set(forms).count)
  }

  @Test func irCanBeFoundByItsFormsAndItsGloss() throws {
    let ir = try text("ir")
    #expect(ir.keywords.contains("fue"))
    #expect(ir.keywords.contains("go"))
    #expect(ir.keywords.contains("to go"))
  }

  @Test func theDescriptionIsTheKeyConjugationsWithNoLabel() throws {
    #expect(try text("tener").description == "tengo · tuve · tendré · tenido")
    #expect(try text("tener").description == KeyConjugation.line(for: "tener"))
  }

  @Test func theGlossLeadsTheAlternateNames() throws {
    let llegar = try text("llegar")
    #expect(llegar.alternateNames.prefix(2) == ["arrive", "come"])
    #expect(llegar.alternateNames.contains("llegué"))
  }

  @Test func aReflexiveOnlyVerbIsTitledWithItsPronoun() throws {
    let entry = try #require(VerbMap.shared.entry(for: "arrepentir"))
    let entity = VerbEntity(entry: entry)
    #expect(entity.id == "arrepentir")
    #expect(entity.citationForm == "arrepentirse")
    #expect(try text("arrepentir").alternateNames.contains("me arrepiento"))
  }

  @Test func everyVerbHasAnEntityThatCarriesItsText() throws {
    let entities = VerbSpotlight.entities()
    #expect(entities.count == VerbMap.shared.entries.count)
    let tener = try #require(entities.first { $0.id == "tener" })
    #expect(tener.spotlight?.keywords.contains("tuve") == true)
    #expect(tener.attributeSet.keywords?.contains("tuve") == true)
    #expect(tener.attributeSet.contentDescription == "tengo · tuve · tendré · tenido")
  }

  @Test(arguments: [
    ("VerbEntity/hablar", "hablar"),
    ("hablar", "hablar"),
    ("VerbEntity/añadir", "añadir")
  ])
  func aSpotlightActivityNamesItsVerb(identifier: String, infinitive: String) {
    #expect(VerbSpotlight.infinitive(fromActivityIdentifier: identifier) == infinitive)
  }

  @Test func anUnknownActivityNamesNoVerb() {
    #expect(VerbSpotlight.infinitive(fromActivityIdentifier: "VerbEntity/blorptar") == nil)
  }

  @Test func theQueryFindsTheVerbAskedForFirst() async {
    let entities = await VerbEntityQuery().entities(matching: "fue")
    #expect(entities.prefix(2).map(\.id) == ["ser", "ir"])
    #expect(entities.count <= VerbEntityQuery.matchLimit)
  }

  // A launch skips the index when this build has already filled it.
  @Test func aFirstRunIndexesAndRemovesNothing() {
    #expect(VerbSpotlight.plan(last: nil, stamp: "3.2 (1), 4811 verbs", infinitives: ["hablar"]) == .index(removing: []))
  }

  @Test func theSameStampSkips() {
    let last = VerbSpotlight.IndexRecord(stamp: "3.2 (1), 4811 verbs", infinitives: ["hablar", "tener"])
    #expect(VerbSpotlight.plan(last: last, stamp: "3.2 (1), 4811 verbs", infinitives: ["hablar"]) == .skip)
  }

  @Test func aNewStampRemovesTheVerbsTheMapLost() {
    let last = VerbSpotlight.IndexRecord(stamp: "3.2 (1), 4811 verbs", infinitives: ["tener", "abolir", "hablar", "churruscar"])
    let plan = VerbSpotlight.plan(last: last, stamp: "3.2 (2), 4810 verbs", infinitives: ["hablar", "tener", "comer"])
    #expect(plan == .index(removing: ["abolir", "churruscar"]))
  }

  @Test func theStampNamesTheBuildAndTheVerbCount() {
    let stamp = VerbSpotlight.stamp(verbCount: 4_811)
    #expect(stamp.hasSuffix(", 4811 verbs"))
    #expect(stamp != VerbSpotlight.stamp(verbCount: 4_810))
    #expect(!stamp.hasPrefix("?"))
  }

  @Test func aRunThatIndexedWritesItsRecord() async throws {
    let record = FileManager.default.temporaryDirectory.appending(path: "spotlight_index_\(UUID().uuidString).json")
    defer { try? FileManager.default.removeItem(at: record) }
    let stamp = VerbSpotlight.stamp(verbCount: VerbMap.shared.entries.count)
    let written = VerbSpotlight.IndexRecord(stamp: stamp, infinitives: ["hablar"])
    try JSONEncoder().encode(written).write(to: record)
    // The stamp matches, so the run skips the index and leaves the record as it was.
    await VerbSpotlight.indexVerbs(recordURL: record)
    #expect(try JSONDecoder().decode(VerbSpotlight.IndexRecord.self, from: Data(contentsOf: record)) == written)
  }

}
