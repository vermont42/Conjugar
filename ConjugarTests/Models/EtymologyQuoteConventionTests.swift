//
//  EtymologyQuoteConventionTests.swift
//  ConjugarTests
//
//  Pins the gloss-quote convention in the shipped `Etymologies.json` so future
//  generation batches can't drift back to the French-style spacing they started
//  with: Spanish sets glosses closed in guillemets (`«ser»`, never `« ser »`) and
//  uses no curly quotes; English sets them in curly double quotes (`“to be”`) and
//  uses no guillemets. Reads the source-tree JSON via the `#filePath`-relative
//  repo-root idiom from `CorpusFormsDumpTests`/`SymbolValidityTests`.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite("EtymologyQuoteConvention")
struct EtymologyQuoteConventionTests {
  private static func load() throws -> [String: [String: String]] {
    let url = URL(filePath: #filePath)
      .deletingLastPathComponent()  // Models/
      .deletingLastPathComponent()  // ConjugarTests/
      .deletingLastPathComponent()  // repo root
      .appending(path: "Conjugar/Models/Etymologies.json")
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode([String: [String: String]].self, from: data)
  }

  @Test func spanishUsesClosedGuillemetsAndNoCurlyQuotes() throws {
    let es = try #require(try Self.load()["es"])
    #expect(!es.isEmpty)
    for (verb, text) in es {
      #expect(!text.contains("«\u{20}") && !text.contains(" »"), "es \(verb): guillemet with inner padding")
      #expect(!text.contains("“") && !text.contains("”"), "es \(verb): curly quote (guillemets are the es convention)")
    }
  }

  @Test func englishUsesCurlyQuotesAndNoGuillemets() throws {
    let en = try #require(try Self.load()["en"])
    #expect(!en.isEmpty)
    for (verb, text) in en {
      #expect(!text.contains("«") && !text.contains("»"), "en \(verb): guillemet (curly quotes are the en convention)")
    }
  }
}
