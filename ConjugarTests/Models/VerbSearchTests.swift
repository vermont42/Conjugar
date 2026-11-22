//
//  VerbSearchTests.swift
//  ConjugarTests
//
//  Pins the verb search's matching and ranking against the bundled verb map, including the
//  table of queries whose first results Josh chose on 2026-11-22.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct VerbSearchTests {
  private static let entries = Array(VerbMap.shared.entries.values)

  private func infinitives(for query: String, in entries: [VerbMapEntry] = Self.entries) -> [String] {
    VerbSearch.matches(for: query, in: entries).map(\.entry.infinitive)
  }

  /// The queries Josh judged, and the verbs each must list first, in order.
  @Test(arguments: [
    ("go", ["ir"]),
    ("be", ["ser", "estar"]),
    ("do", ["hacer"]),
    ("come", ["llegar", "venir", "acudir"]),
    ("have", ["tener", "haber"]),
    ("see", ["ver"]),
    ("ver", ["ver"]),
    ("comer", ["comer"]),
    ("sonar", ["sonar", "soñar"]),
    ("levantarse", ["levantar"]),
    ("to go", ["ir"]),
    ("drive", ["conducir"]),
    ("anadir", ["añadir"])
  ])
  func chosenFirstResults(query: String, expected: [String]) {
    #expect(Array(infinitives(for: query).prefix(expected.count)) == expected)
  }

  @Test func exactGlossSenseOutranksInfinitivePrefix() throws {
    let results = infinitives(for: "go")
    let ir = try #require(results.firstIndex(of: "ir"))
    let gobernar = try #require(results.firstIndex(of: "gobernar"))
    #expect(ir < gobernar)
    #expect(VerbSearch.matches(for: "go", in: Self.entries).first?.kind == .exactGlossSense)
  }

  @Test func literalMatchLeadsItsFoldedTwin() {
    let matches = VerbSearch.matches(for: "sonar", in: Self.entries)
    #expect(matches.first?.entry.infinitive == "sonar")
    #expect(matches.first?.kind == .exactInfinitive)
    #expect(matches.dropFirst().first?.entry.infinitive == "soñar")
    #expect(matches.dropFirst().first?.kind == .exactFoldedInfinitive)
  }

  @Test func accentedQueryFindsTheLiteralVerbFirst() {
    #expect(infinitives(for: "soñar").first == "soñar")
    #expect(infinitives(for: "soñar").dropFirst().first == "sonar")
  }

  @Test func foldingDropsCaseAccentsAndTilde() {
    #expect(VerbSearch.fold("Añadir") == "anadir")
    #expect(VerbSearch.fold("REÍR") == "reir")
    #expect(VerbSearch.fold("argüir") == "arguir")
  }

  @Test func everyGlossOfAHomonymIsSearched() {
    // apostar is "bet" and, as its second sense, "station".
    #expect(infinitives(for: "station").first == "apostar")
    #expect(infinitives(for: "bet").first == "apostar")
  }

  @Test(arguments: [
    ("levantarse", "levantar"),
    ("Levantarse", "levantar"),
    ("levantar(se)", "levantar"),
    ("se levantar", "levantar"),
    ("arrepentirse", "arrepentir"),
    ("reírse", "reír"),
    ("irse", "ir"),
    ("base", "base"),
    ("clase", "clase"),
    ("se", "se")
  ])
  func pronominalSeIsStripped(query: String, expected: String) {
    #expect(VerbSearch.spanishQuery(from: query) == expected)
  }

  @Test func pronominalQueryFindsItsVerb() {
    #expect(infinitives(for: "arrepentirse").first == "arrepentir")
    #expect(infinitives(for: "se levantar").first == "levantar")
  }

  @Test func baseIsSearchedAsTyped() {
    // Stripped, "base" would be "ba", a prefix of many verbs. As typed, it is a gloss substring.
    #expect(infinitives(for: "base").first == "basar")
  }

  @Test func leadingToIsIgnoredInGlosses() {
    #expect(VerbSearch.glossQuery(from: "to go") == "go")
    #expect(VerbSearch.glossQuery(from: "  To   Eat ") == "eat")
    #expect(VerbSearch.glossQuery(from: "to") == "to")
    #expect(VerbSearch.glossQuery(from: "tomar") == "tomar")
  }

  @Test func wholeWordGlossOutranksGlossSubstring() {
    #expect(VerbSearch.containsWholeWord("eat", in: "eat"))
    #expect(VerbSearch.containsWholeWord("look", in: "look for, seek"))
    #expect(!VerbSearch.containsWholeWord("eat", in: "beat"))
    let matches = VerbSearch.matches(for: "eat", in: Self.entries)
    // batir is "beat": "eat" lies inside a word of its gloss and nowhere in its infinitive.
    let batir = matches.first { $0.entry.infinitive == "batir" }
    #expect(batir?.kind == .glossSubstring)
    // apolillar is "moth-eat": a hyphen is not a letter, so "eat" is a word of it.
    let apolillar = matches.first { $0.entry.infinitive == "apolillar" }
    #expect(apolillar?.kind == .wholeWordGloss)
    #expect(matches.first?.entry.infinitive == "comer")
  }

  @Test func glossSensesSplitOnCommas() {
    #expect(VerbSearch.senses(of: "arrive, come") == ["arrive", "come"])
    #expect(VerbSearch.senses(of: "play (a musical instrument)") == ["play (a musical instrument)"])
  }

  @Test func rankingIgnoresInputOrder() {
    let forward = infinitives(for: "es", in: Self.entries)
    let alphabetical = Self.entries.sorted { $0.infinitive < $1.infinitive }
    #expect(infinitives(for: "es", in: alphabetical) == forward)
    #expect(infinitives(for: "es", in: alphabetical.reversed()) == forward)
  }

  @Test func withinAKindTheMoreFrequentVerbComesFirst() {
    let matches = VerbSearch.matches(for: "es", in: Self.entries)
    for (earlier, later) in zip(matches, matches.dropFirst()) where earlier.kind == later.kind {
      #expect(earlier.entry.frequencyRank < later.entry.frequencyRank)
    }
    #expect(zip(matches, matches.dropFirst()).allSatisfy { $0.kind <= $1.kind })
  }

  @Test func eachVerbMatchesOnce() {
    let results = infinitives(for: "a")
    #expect(Set(results).count == results.count)
  }

  @Test func emptyQueryMatchesNothing() {
    #expect(infinitives(for: "").isEmpty)
    #expect(infinitives(for: "   ").isEmpty)
  }

  @Test func nonsenseMatchesNothing() {
    #expect(infinitives(for: "xyzzyq").isEmpty)
  }

  @Test func entriesOutsideTheBundledMapAreSearched() {
    let invented = VerbMapEntry(
      infinitive: "zorglar",
      classNumbers: ["1"],
      glosses: ["frobnicate"],
      isReflexive: false,
      hits: 0,
      bookHits: nil,
      hitsAreProvisional: true,
      frequencyRank: 1
    )
    #expect(infinitives(for: "frobnicate", in: [invented]) == ["zorglar"])
    #expect(infinitives(for: "zorglar", in: [invented]) == ["zorglar"])
  }
}
