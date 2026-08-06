//
//  ExampleDataTests.swift
//  ConjugarTests
//
//  Swift Testing for the example-uses feature's data layer: the bundled
//  `ExampleUses.json` / `MedievalExamples.json` decode and look up by bare infinitive,
//  and `ExampleSource` maps a raw source filename onto the right attribution kind.
//  The loaders and models are `nonisolated`, so this suite is too.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct ExampleDataTests {
  @Test func modernExampleLoadsForRankedVerb() {
    let example = ExampleData.example(for: "abandonar")
    #expect(example != nil)
    #expect(example?.es.isEmpty == false)
    #expect(example?.en.isEmpty == false)
    // The example's token is a real surface form, and the source is a corpus filename.
    #expect(example?.source.isEmpty == false)
  }

  @Test func medievalExamplesLoadAndAreOrdered() {
    let examples = MedievalData.examples(for: "abajar")
    #expect(examples.count > 1)
    // Every entry carries a known work, a citation, an Old-Spanish line, and a translation.
    for example in examples {
      #expect(["cid", "berceo", "lba"].contains(example.work))
      #expect(example.ref.isEmpty == false)
      #expect(example.os.isEmpty == false)
      #expect(example.tr.isEmpty == false)
    }
  }

  @Test func absentVerbsReturnNilAndEmpty() {
    #expect(ExampleData.example(for: "notaverbxyz") == nil)
    #expect(MedievalData.examples(for: "notaverbxyz").isEmpty)
  }

  @Test func medievalReferencePrependsWorkTitle() {
    let example = MedievalExample(work: "cid", ref: "Cantar I, v. 330", os: "…", tr: "…")
    #expect(example.workTitle == "Cantar de mio Cid")
    #expect(example.reference == "Cantar de mio Cid, Cantar I, v. 330")
    #expect(MedievalExample(work: "berceo", ref: "estrofa 470", os: "…", tr: "…").workTitle == "Milagros de Nuestra Señora")
    #expect(MedievalExample(work: "lba", ref: "copla 900", os: "…", tr: "…").workTitle == "Libro de buen amor")
  }

  @Test func literatureSourceAttribution() {
    let source = ExampleSource(rawSource: "fortunata-y-jacinta-galdos-1887.txt")
    #expect(source == .literature(author: "Benito Pérez Galdós", title: "Fortunata y Jacinta", year: "1887"))
    #expect(source.attribution == "— Benito Pérez Galdós, Fortunata y Jacinta (1887)")
  }

  @Test func governmentSourceAttributionWrapsBody() {
    let source = ExampleSource(rawSource: "es-ine-informe-anual-2024.txt")
    guard case .government(let body) = source else {
      Issue.record("Expected a government source")
      return
    }
    #expect(body == "INE, Informe Anual 2024")
    // The localized "Fuente:/Source:" prefix wraps the body.
    #expect(source.attribution.contains(body))
  }

  @Test func claudeSourceIsAuthored() {
    let source = ExampleSource(rawSource: "Claude (Opus 4.8)")
    #expect(source == .claude)
    #expect(source.attribution.contains("Claude"))
  }

  @Test func unknownSourceFallsBackToOther() {
    let source = ExampleSource(rawSource: "mystery-source.txt")
    #expect(source == .other("mystery-source.txt"))
    #expect(source.attribution == "— mystery-source.txt")
  }
}
