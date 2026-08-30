//
//  CorpusFormsDumpTests.swift
//  ConjugarTests
//
//  Created by Josh Adams on 7/10/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar
import Foundation

// NOT a behavioral test — a build-time corpus tool that rides the test target so it can reuse
// the app's authoritative engine (`TenseBridge`/`Conjugator`/`VerbMap`) and the already-loaded
// verb data. It is the deterministic backbone of the "example uses" pipeline
// (`docs/example-corpus-sources.md`): it emits every single-word surface form of the
// usage-ranked verbs to `corpus/working/forms.json` as `{ "<form>": ["<infinitive>", …] }`, so
// the Python index builder does exact whole-token matching against the corpus instead of fragile
// per-verb stem-grepping — irregulars (voy/vas/fue → ir; supe/sabré → saber) and false-substring
// hits both fall out for free. Mirrors Conjuguer's `CorpusFormsDumpTests`.
//
// One form can map to several verbs (homographs: "vino" → venir & the noun; "es" → ser; the
// index records the occurrence under each candidate and the LLM-selection step disambiguates
// from context). Keys are the bare infinitive (Conjugar keys verbs by infinitive; a homonym's
// two senses share one id).
//
// Disabled by default (see the @Suite trait): it asserts nothing about behavior, writes files,
// and runs ~1.3M conjugations. To regenerate the dumps on demand, temporarily remove the
// `.disabled(...)` trait, then:
//   run_tests.sh --only-testing ConjugarTests/CorpusFormsDumpTests
@Suite(.disabled("Build-time corpus tool, not a behavioral test — see the file header to run on demand."))
struct CorpusFormsDumpTests {
  // Drop single-character tokens ("y", "a", "e", "o"): ultra-noisy and the verbs that emit them
  // (ir → "id", haber, …) are covered many times over by their longer forms.
  private static let minFormLength = 2

  // The two non-personal single-word forms worth harvesting (very common in prose). `raízFutura`
  // is a bare stem, not a word; `infinitivo`/`translation` aren't conjugations — the infinitive
  // surface form is added directly from the id.
  private static let nonPersonalTenses: [DisplayTense] = [.gerundio, .participio]

  // Every real person-number (both 2S tú and vos, so LatAm voseo forms are harvested too).
  private static let persons: [DisplayPersonNumber] = [
    .firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular,
    .firstPlural, .secondPlural, .thirdPlural
  ]

  // The "usage-ranked" set the example-uses pipeline mines: the thousand most common verbs.
  // Was `frequencyRank != nil` back when only ~1,000 verbs carried a rank at all; every verb
  // has one now, so the window has to be explicit or this would dump the whole map twice.
  private static let usageRankedCount = 1000

  @Test func testDumpUsageRankedVerbForms() throws {
    let ranked = VerbMap.shared.entries.values
      .filter { $0.frequencyRank <= Self.usageRankedCount }
      .sorted { $0.frequencyRank < $1.frequencyRank }
    #expect(!ranked.isEmpty, "Verb data not loaded — expected the usage-ranked set.")
    try dump(verbs: ranked.map(\.infinitive), to: "corpus/working/forms.json")
  }

  // Companion dump over the FULL verb map (all ~4,800 verbs, not just the usage-ranked set), to
  // `corpus/working/forms_all.json`. Needed when mining for verbs outside the ranked top — e.g.
  // the medieval-only verbs that have a Cid example but no modern one (Conjuguer's Chanson-only
  // analogue). Same schema; kept separate so the canonical ranked forms.json stays untouched.
  @Test func testDumpAllVerbForms() throws {
    let all = VerbMap.shared.entries.values.map(\.infinitive).sorted()
    #expect(!all.isEmpty, "Verb data not loaded.")
    try dump(verbs: all, to: "corpus/working/forms_all.json")
  }

  private func dump(verbs: [String], to relativePath: String) throws {
    // Repo root from this file's compile-time path: …/ConjugarTests/Models/<file> → up three.
    let outURL = URL(filePath: #filePath)
      .deletingLastPathComponent()  // Models/
      .deletingLastPathComponent()  // ConjugarTests/
      .deletingLastPathComponent()  // repo root
      .appending(path: relativePath)

    var index: [String: Set<String>] = [:]
    var conjugationCount = 0

    func add(_ raw: String, _ id: String) {
      // Each "/"-separated alternate is its own form; each space-separated form keeps only its
      // LAST word — for a compound tense ("he hablado") that is the participle, for imperativo
      // negativo ("no hable") the subjunctive; the dropped auxiliary/"no" are forms of haber /
      // the particle, covered elsewhere, and mapping them here would make every "he …" a false hit.
      for alternate in raw.split(separator: "/") {
        guard let last = alternate.split(separator: " ").last else { continue }
        let token = Self.normalize(String(last))
        if token.count >= Self.minFormLength {
          index[token, default: []].insert(id)
        }
      }
    }

    for infinitive in verbs {
      add(infinitive, infinitive)  // the infinitive itself is a surface form
      for tense in Self.nonPersonalTenses {
        if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: .none) {
          conjugationCount += 1
          add(form, infinitive)
        }
      }
      for tense in DisplayTense.conjugatedTenses {
        for person in Self.persons {
          if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: person) {
            conjugationCount += 1
            add(form, infinitive)
          }
        }
      }
    }

    // Serialize sorted for stable, reviewable diffs.
    let out = index.reduce(into: [String: [String]]()) { accumulator, pair in
      accumulator[pair.key] = pair.value.sorted()
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(out).write(to: outURL)

    print("CorpusFormsDump: \(verbs.count) verbs → \(conjugationCount) conjugations → "
      + "\(out.count) distinct forms → \(outURL.path)")
  }

  // Lowercase strips the `IrregularityMarker` UPPERCASE red-highlight encoding (voY → voy),
  // recovering the plain surface form. Accents are kept; the Python index builder applies the
  // same lowercasing to corpus tokens so both sides match.
  private static func normalize(_ token: String) -> String {
    token.lowercased()
  }
}
