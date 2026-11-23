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

  @Test func formsAreEveryOneWordFormOnce() throws {
    let ir = try #require(Self.forms["ir"])
    #expect(ir.count == Set(ir).count)
    #expect(Set(["voy", "fue", "fui", "yendo", "ido", "iba", "vaya"]).isSubset(of: Set(ir)))
    #expect(!ir.contains("ir"))
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
}
