//
//  VerbMap.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/13/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The **verb→model map**: the easy-data-entry half of the parsimony scheme.
// Loads `verbModelMap.xml` into a lookup the resolver consults:
//
//     bare infinitive → (class number(s), English gloss(es), reflexive?)
//
// One `<verb>` element per (verb, sense): `in` = infinitive, `cl` = class
// number (the `ModelCatalog` key), `tn` = terse English gloss (display-only,
// **decoupled from conjugation** — a wrong gloss can never produce a wrong form),
// optional `rx="1"` = reflexive-only. The schema deliberately leaves room for
// future optional attributes (`tnr` reflexive gloss, `dg` defect group) with zero
// migration.
//
// **Homonyms** (apostar/asolar/aterrar/atestar) appear as **two** elements with the
// same `in` and different `cl`/`tn`; they collapse into one `Entry` whose
// `classNumbers`/`glosses` hold both senses **in file order = default sense first**
// (the resolver conjugates the default; the future UI can offer both).

import Foundation

/// One verb's mapping. For non-homonyms `classNumbers`/`glosses` have a single
/// element; for the 4 homonyms they hold both senses, default sense first.
nonisolated struct VerbMapEntry {
  let infinitive: String
  let classNumbers: [String]
  let glosses: [String]
  let isReflexive: Bool

  /// CORPES XXI lemma hits, the `hi` attribute: the bare infinitive plus its `-se` lemma,
  /// which is what recovers the pronominal verbs the corpus lemmatizes with the clitic
  /// attached. Ordering by this is *most* common first, so prefer `frequencyRank` anywhere
  /// order matters. Display-only — a count can never affect a conjugation.
  let hits: Int

  /// Google Books 1950–2019 verb-form tokens, the `gb` attribute, summed through the app's
  /// own paradigms. The tie-breaker, not a ranking: Google's tagger marks a noun `_VERB`
  /// whenever it coincides with a form of a rare verb. `nil` where the corpus has nothing,
  /// which sorts *below* a measured zero. See `frequency/README.md`.
  let bookHits: Int?

  /// True when `hits` is an estimate rather than a measured CORPES count, because no corpus
  /// lists the verb. Affects nothing the user sees (the rank derives from `hits` either
  /// way), and exists so the provisional population stays findable rather than quietly
  /// becoming permanent. See `hp` in `frequency/README.md`.
  let hitsAreProvisional: Bool

  /// Dense rank over the whole verb list, 1 being the most common. Derived from `hits` by
  /// `VerbMap.ranked(_:)` at parse time rather than stored, so adding a verb does not
  /// renumber every incumbent. This is the number the UI renders as `#168`. Per spelling,
  /// not per sense, so a homonym's two rows share one rank.
  let frequencyRank: Int

  /// The default-sense class number (what the no-`model:` resolver conjugates).
  var classNumber: String { classNumbers[0] }
  /// The default-sense gloss.
  var gloss: String { glosses[0] }
  /// Whether this verb carries more than one sense (a homonym).
  var isHomonym: Bool { classNumbers.count > 1 }

  func withFrequencyRank(_ rank: Int) -> VerbMapEntry {
    VerbMapEntry(
      infinitive: infinitive,
      classNumbers: classNumbers,
      glosses: glosses,
      isReflexive: isReflexive,
      hits: hits,
      bookHits: bookHits,
      hitsAreProvisional: hitsAreProvisional,
      frequencyRank: rank
    )
  }
}

nonisolated final class VerbMap: @unchecked Sendable {
  /// infinitive → its mapping.
  private(set) var entries: [String: VerbMapEntry] = [:]

  /// The shared map, loaded once from the app/test bundle resource.
  static let shared = VerbMap()

  /// Spanish collation, the last tie-break in `ranked(_:)`. Lives here rather than on
  /// `VerbSort` because the parser is `nonisolated` and `VerbSort`, like everything else
  /// without an explicit annotation, is `@MainActor`.
  nonisolated static let spanish = Locale(identifier: "es")

  /// Look up a bare infinitive (markers already stripped: no `(se)`/`(DEF)`/`(1)`).
  func entry(for infinitive: String) -> VerbMapEntry? { entries[infinitive] }

  var count: Int { entries.count }

  /// The number the ranks run to: `frequencyRank` covers exactly `1...rankCount`, each once.
  /// Equal to `count`, because a rank belongs to a spelling and homonyms collapse into one
  /// entry — the name says which of the two meanings a caller wants.
  var rankCount: Int { entries.count }

  /// Load from an explicit URL (used by the `swiftc` driver and unit tests).
  init(url: URL) {
    if let parser = XMLParser(contentsOf: url) {
      let delegate = VerbMapParser()
      parser.delegate = delegate
      parser.parse()
      entries = Self.ranked(delegate.entries)
    }
  }

  /// Load from the bundle resource `verbModelMap.xml`. Tries the app bundle first
  /// (`Bundle.main`, which is the host app under unit tests) then the framework
  /// bundle, so it resolves in both the app and the test target.
  private init() {
    let bundle = Bundle.main.url(forResource: "verbModelMap", withExtension: "xml") != nil
      ? Bundle.main
      : Bundle(for: VerbMap.self)
    guard let url = bundle.url(forResource: "verbModelMap", withExtension: "xml") else {
      assertionFailure("verbModelMap.xml not found in bundle")
      return
    }
    if let parser = XMLParser(contentsOf: url) {
      let delegate = VerbMapParser()
      parser.delegate = delegate
      parser.parse()
      entries = Self.ranked(delegate.entries)
    }
  }

  /// Assigns each verb its frequency rank, 1 being the most common.
  ///
  /// The map stores raw corpus counts rather than ranks because a rank is a property of the
  /// corpus, not of the verb: were ranks stored, adding one verb would renumber every verb
  /// below it, turning a one-line change into a 4,800-line diff. Deriving them here costs
  /// one sort per launch and keeps the resource additive.
  ///
  /// The sort descends through the two counts in order of trustworthiness — CORPES XXI
  /// first, then Google Books, which is contaminated enough to break ties but not to make
  /// them. A missing Google Books count sorts below a measured zero: zero is a corpus that
  /// could have seen the verb and did not, whereas absence is a corpus that never had the
  /// chance. The infinitive settles what is left, in Spanish collation, which is
  /// load-bearing rather than defensive — hundreds of verbs in the tail share a CORPES
  /// count, and without it their order would depend on dictionary iteration.
  ///
  /// The map is keyed by infinitive and a homonym's two `<verb>` rows have already merged
  /// into one entry, so each rank belongs to one spelling with no grouping step needed.
  private static func ranked(_ entries: [String: VerbMapEntry]) -> [String: VerbMapEntry] {
    let ordered = entries.keys.sorted { lhs, rhs in
      guard let left = entries[lhs], let right = entries[rhs] else {
        return lhs.compare(rhs, locale: VerbMap.spanish) == .orderedAscending
      }
      if left.hits != right.hits {
        return left.hits > right.hits
      }
      if left.bookHits != right.bookHits {
        return (left.bookHits ?? -1) > (right.bookHits ?? -1)
      }
      return lhs.compare(rhs, locale: VerbMap.spanish) == .orderedAscending
    }

    var ranked: [String: VerbMapEntry] = [:]
    ranked.reserveCapacity(entries.count)
    for (index, key) in ordered.enumerated() {
      ranked[key] = entries[key]?.withFrequencyRank(index + 1)
    }
    return ranked
  }
}

/// `XMLParser` delegate. Accumulates `<verb>` elements, merging same-`in` rows
/// into one entry so homonyms keep both senses in file order.
nonisolated private final class VerbMapParser: NSObject, XMLParserDelegate {
  var entries: [String: VerbMapEntry] = [:]

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
    guard elementName == "verb" else { return }
    guard let infinitive = attributeDict["in"], let cl = attributeDict["cl"] else { return }
    let gloss = attributeDict["tn"] ?? ""
    let reflexive = attributeDict["rx"] == "1"
    // `hi` is written on every row by docs/_build_verbmap.py, which refuses to emit a verb
    // the counts table has no row for. A missing or non-numeric one is therefore a build
    // error surfacing late: trap it in debug, and in release let the verb rank last rather
    // than take the whole map down over a display-only attribute.
    guard let hits = attributeDict["hi"].flatMap({ Int($0) }) else {
      assertionFailure("verbModelMap.xml: \(infinitive) has no usable hi attribute")
      addEntry(infinitive: infinitive, cl: cl, gloss: gloss, reflexive: reflexive,
               hits: -1, bookHits: nil, provisional: true)
      return
    }
    addEntry(
      infinitive: infinitive,
      cl: cl,
      gloss: gloss,
      reflexive: reflexive,
      hits: hits,
      bookHits: attributeDict["gb"].flatMap { Int($0) },
      provisional: attributeDict["hp"] == "y"
    )
  }

  /// Merges a `<verb>` row into the entry for its infinitive. The rank is a placeholder —
  /// `VerbMap.ranked(_:)` fills it in once the whole map is loaded.
  private func addEntry(
    infinitive: String,
    cl: String,
    gloss: String,
    reflexive: Bool,
    hits: Int,
    bookHits: Int?,
    provisional: Bool
  ) {
    if let existing = entries[infinitive] {
      // A second sense of a homonym — append, preserving file order. Both rows carry the
      // same counts (they belong to the spelling); keep whichever the first row supplied.
      entries[infinitive] = VerbMapEntry(
        infinitive: infinitive,
        classNumbers: existing.classNumbers + [cl],
        glosses: existing.glosses + [gloss],
        isReflexive: existing.isReflexive || reflexive,
        hits: existing.hits,
        bookHits: existing.bookHits,
        hitsAreProvisional: existing.hitsAreProvisional,
        frequencyRank: existing.frequencyRank
      )
    } else {
      entries[infinitive] = VerbMapEntry(
        infinitive: infinitive,
        classNumbers: [cl],
        glosses: [gloss],
        isReflexive: reflexive,
        hits: hits,
        bookHits: bookHits,
        hitsAreProvisional: provisional,
        frequencyRank: 0
      )
    }
  }
}
