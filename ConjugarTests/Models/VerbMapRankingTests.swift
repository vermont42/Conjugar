//
//  VerbMapRankingTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 8/30/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation
import Testing
@testable import Conjugar

// Frequency ranking. `verbModelMap.xml` stores counts — `hi` (CORPES XXI lemma hits) and
// `gb` (the Google Books tie-breaker) — and `VerbMap.ranked(_:)` derives the dense
// 1…4,811 rank from them at parse time. These tests cover the derivation on a fixture
// small enough to reason about, the invariants of the real map, and the agreement between
// the app's ordering and `docs/frequencies.txt`, which the pipeline writes from the same
// XML with a hand-rolled imitation of ICU's Spanish collation. That last one is the
// load-bearing test: where Python and ICU disagree, Python is wrong, and only a comparison
// finds it.
//
// Nonisolated: `VerbMap` and everything it touches are, and keeping the suite that way
// lets it run in parallel with the rest.
@Suite("VerbMap frequency ranking")
struct VerbMapRankingTests {
  static let map = VerbMap.shared

  /// The repo root from this file's compile-time path: …/ConjugarTests/Models/<file> → up three.
  static let repoRoot = URL(filePath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()

  // MARK: - Derivation, on a fixture

  /// Six verbs over seven rows, chosen to exercise every step of the sort in one file:
  ///
  /// * `ser` wins outright on `hi`.
  /// * `nadar` and `obrar` tie on `hi` and are separated by `gb`.
  /// * `ñoñear` ties `nadar`/`obrar` on `hi` **and** has no `gb` at all, so it sorts below
  ///   both — absence is below a measured zero.
  /// * `apostar` appears twice, one row per homonym sense, and must take one rank.
  /// * `zurear` is an `hp="y"` estimate and must rank on its count like anything else.
  static let fixture = """
    <?xml version="1.0" encoding="utf-8"?>
    <verbs>
      <verb in="ser" cl="19" tn="be" hi="7661318" gb="1354822205" />
      <verb in="obrar" cl="1" tn="work" hi="500" gb="200" />
      <verb in="nadar" cl="1" tn="swim" hi="500" gb="900" />
      <verb in="ñoñear" cl="1" tn="whine" hi="500" />
      <verb in="apostar" cl="4B" tn="bet" hi="400" gb="100" />
      <verb in="apostar" cl="1" tn="station" hi="400" gb="100" />
      <verb in="zurear" cl="1" tn="coo" hi="450" gb="50" hp="y" />
    </verbs>
    """

  static func loadFixture() throws -> VerbMap {
    let url = URL(filePath: NSTemporaryDirectory())
      .appending(path: "VerbMapRankingTests-\(UUID().uuidString).xml")
    try fixture.write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    return VerbMap(url: url)
  }

  @Test("the three count attributes parse")
  func countsParse() throws {
    let map = try Self.loadFixture()
    let ser = try #require(map.entry(for: "ser"))
    #expect(ser.hits == 7_661_318)
    #expect(ser.bookHits == 1_354_822_205)
    #expect(ser.hitsAreProvisional == false)

    let zurear = try #require(map.entry(for: "zurear"))
    #expect(zurear.hits == 450)
    #expect(zurear.bookHits == 50)
    #expect(zurear.hitsAreProvisional)

    // A verb with no `gb` parses to nil, not to zero.
    #expect(try #require(map.entry(for: "ñoñear")).bookHits == nil)
  }

  @Test("the sort descends hi, then gb, then Spanish collation")
  func sortOrder() throws {
    let map = try Self.loadFixture()
    let ordered = map.entries.values
      .sorted { $0.frequencyRank < $1.frequencyRank }
      .map(\.infinitive)
    // ser wins on hi. nadar/obrar/ñoñear tie at hi=500: nadar's 900 beats obrar's 200, and
    // ñoñear has no gb at all, so it goes last of the three. zurear (450, estimated) and
    // apostar (400) then rank on hi like anything else.
    #expect(ordered == ["ser", "nadar", "obrar", "ñoñear", "zurear", "apostar"])
  }

  @Test("a missing gb sorts below a present one, even a smaller one")
  func absentBookHitsSortLast() throws {
    let map = try Self.loadFixture()
    let noBookHits = try #require(map.entry(for: "ñoñear")).frequencyRank
    let smallBookHits = try #require(map.entry(for: "obrar")).frequencyRank
    #expect(smallBookHits < noBookHits)
  }

  @Test("an estimated count ranks like a measured one")
  func provisionalRanksNormally() throws {
    let map = try Self.loadFixture()
    let zurear = try #require(map.entry(for: "zurear"))
    let apostar = try #require(map.entry(for: "apostar"))
    #expect(zurear.hitsAreProvisional)
    // 450 > 400, so the estimate outranks the measurement. Nothing about the flag enters
    // the sort; it exists only so the provisional population stays countable.
    #expect(zurear.frequencyRank < apostar.frequencyRank)
  }

  @Test("a homonym's two rows collapse to one entry with one rank")
  func homonymsShareARank() throws {
    let map = try Self.loadFixture()
    let apostar = try #require(map.entry(for: "apostar"))
    #expect(apostar.isHomonym)
    #expect(apostar.classNumbers == ["4B", "1"])
    #expect(apostar.hits == 400)
    // Seven <verb> elements, six spellings: ranks run 1...6, and rankCount counts
    // spellings rather than elements.
    #expect(map.rankCount == 6)
    #expect(apostar.frequencyRank == 6)
  }

  // MARK: - Invariants of the shipped map

  @Test("ranks are exactly 1...rankCount, each used once")
  func ranksAreDense() {
    let ranks = Self.map.entries.values.map(\.frequencyRank)
    #expect(ranks.count == Self.map.rankCount)
    #expect(Set(ranks) == Set(1...Self.map.rankCount), "ranks are not a dense 1…\(Self.map.rankCount)")
  }

  @Test("the map ranks all 4,811 verbs")
  func rankCount() {
    #expect(Self.map.rankCount == 4811, "rankCount = \(Self.map.rankCount)")
  }

  @Test("the three most common verbs", arguments: [("ser", 1), ("estar", 2), ("tener", 3)])
  func topThree(infinitive: String, rank: Int) {
    #expect(Self.map.entry(for: infinitive)?.frequencyRank == rank)
  }

  // A count is a number of times a corpus saw the verb, so it cannot be negative. -1 is the
  // parser's sentinel for a row whose `hi` was missing or unparseable, which is a build
  // error in `docs/_build_verbmap.py`; this is where it would surface in release.
  @Test("every verb has a non-negative hit count")
  func hitsAreNonNegative() {
    let negative = Self.map.entries.values.filter { $0.hits < 0 }.map(\.infinitive).sorted()
    #expect(negative.isEmpty, "negative hit counts: \(negative)")
  }

  // 42 verbs CORPES has no lemma for that Google Books counts, estimated through the
  // log-log fit, plus 4 that nothing counts, taken from frequency/editorial-counts.json.
  // Pinned so the provisional population stays visible rather than quietly growing: a
  // future source that measures one of them should make this number go down.
  @Test("exactly 46 verbs rest on an estimated count")
  func provisionalPopulation() {
    let provisional = Self.map.entries.values.filter(\.hitsAreProvisional).map(\.infinitive)
    #expect(provisional.count == 46, "provisional verbs = \(provisional.count)")
  }

  // The estimates are clamped at the measured count of the thousandth verb, so no guess can
  // land in the part of the list a learner actually reads. See frequency/README.md.
  @Test("no estimated verb ranks in the top 1000")
  func provisionalVerbsAreClampedOutOfTheTop() {
    let intruders = Self.map.entries.values
      .filter { $0.hitsAreProvisional && $0.frequencyRank <= 1000 }
      .map { "\($0.infinitive) #\($0.frequencyRank)" }
      .sorted()
    #expect(intruders.isEmpty, "estimated verbs inside the top 1000: \(intruders)")
  }

  @Test("a higher rank never has fewer hits")
  func ranksDescendByHits() {
    let ordered = Self.map.entries.values.sorted { $0.frequencyRank < $1.frequencyRank }
    let inversions = zip(ordered, ordered.dropFirst())
      .filter { $0.hits < $1.hits }
      .map { "\($0.infinitive) (\($0.hits)) before \($1.infinitive) (\($1.hits))" }
    #expect(inversions.isEmpty, "hit counts out of order: \(inversions.prefix(5))")
  }

  // MARK: - Agreement with docs/frequencies.txt

  // `frequency/generate_frequencies_txt.py` writes that file from the same XML, sorting with
  // a Python imitation of `compare(_:locale:)` under `es` — enye as a letter between n and o,
  // accents secondary. Only a line-for-line comparison can prove the imitation holds. If this
  // fails inside a tie group, the Python collation is wrong: fix the script and regenerate.
  @Test("docs/frequencies.txt names the same verb at every rank")
  func frequenciesFileAgrees() throws {
    let url = Self.repoRoot.appending(path: "docs/frequencies.txt")
    let text = try String(contentsOf: url, encoding: .utf8)
    let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
    #expect(lines.count == Self.map.rankCount, "docs/frequencies.txt has \(lines.count) lines")

    var disagreements: [String] = []
    for line in lines {
      let parts = line.split(separator: " ", maxSplits: 1)
      guard parts.count == 2, let rank = Int(parts[0]) else {
        disagreements.append("unparseable line: \(line)")
        continue
      }
      let infinitive = String(parts[1])
      let actual = Self.map.entry(for: infinitive)?.frequencyRank
      if actual != rank {
        disagreements.append("#\(rank) \(infinitive) — the map says \(actual.map(String.init) ?? "no such verb")")
      }
    }
    #expect(disagreements.isEmpty, "\(disagreements.count) disagreements, first few: \(disagreements.prefix(5))")
  }
}
