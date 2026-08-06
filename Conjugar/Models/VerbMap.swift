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
  /// 1-based frequency rank (1 = most frequent), or `nil` for verbs outside the
  /// top 1000. Display-only — sourced from the `fr` attribute, never affects
  /// conjugation. Per spelling, not per sense, so a homonym's two rows share one
  /// rank.
  let frequencyRank: Int?

  /// The default-sense class number (what the no-`model:` resolver conjugates).
  var classNumber: String { classNumbers[0] }
  /// The default-sense gloss.
  var gloss: String { glosses[0] }
  /// Whether this verb carries more than one sense (a homonym).
  var isHomonym: Bool { classNumbers.count > 1 }
}

nonisolated final class VerbMap: @unchecked Sendable {
  /// infinitive → its mapping.
  private(set) var entries: [String: VerbMapEntry] = [:]

  /// The shared map, loaded once from the app/test bundle resource.
  static let shared = VerbMap()

  /// Look up a bare infinitive (markers already stripped: no `(se)`/`(DEF)`/`(1)`).
  func entry(for infinitive: String) -> VerbMapEntry? { entries[infinitive] }

  var count: Int { entries.count }

  /// Load from an explicit URL (used by the `swiftc` driver and unit tests).
  init(url: URL) {
    if let parser = XMLParser(contentsOf: url) {
      let delegate = VerbMapParser()
      parser.delegate = delegate
      parser.parse()
      entries = delegate.entries
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
      entries = delegate.entries
    }
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
    let frequencyRank = attributeDict["fr"].flatMap { Int($0) }

    if let existing = entries[infinitive] {
      // A second sense of a homonym — append, preserving file order. Both rows
      // carry the same `fr`; keep whichever the first row supplied.
      entries[infinitive] = VerbMapEntry(
        infinitive: infinitive,
        classNumbers: existing.classNumbers + [cl],
        glosses: existing.glosses + [gloss],
        isReflexive: existing.isReflexive || reflexive,
        frequencyRank: existing.frequencyRank ?? frequencyRank
      )
    } else {
      entries[infinitive] = VerbMapEntry(
        infinitive: infinitive,
        classNumbers: [cl],
        glosses: [gloss],
        isReflexive: reflexive,
        frequencyRank: frequencyRank
      )
    }
  }
}
