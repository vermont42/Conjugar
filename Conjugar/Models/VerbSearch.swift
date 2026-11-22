//
//  VerbSearch.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The one matching and ranking rule for verb search. The verb list uses it today, and the
/// reverse lookup and the search intent of later phases are to call it too, so that what a
/// learner finds cannot depend on where the learner typed.
nonisolated enum VerbSearch {
  /// The kinds of match, best first. Within a kind, the more frequent verb ranks first, whatever
  /// order the list is sorted in.
  ///
  /// A gloss sense that is the whole query outranks an infinitive that merely begins with it,
  /// because the commonest English queries are also Spanish prefixes: "go" would otherwise list
  /// golpear, gobernar, and gozar above ir, "be" beber above ser, and "do" dormir above hacer.
  /// Josh chose this order on 2026-11-22. Below that, the order is Konjugieren's: a literal match
  /// outranks a folded one of the same shape, so sonar leads soñar.
  enum MatchKind: Int, CaseIterable, Comparable, Sendable {
    case exactInfinitive
    case exactFoldedInfinitive
    case exactGlossSense
    case infinitivePrefix
    case wholeWordGloss
    case infinitiveSubstring
    case foldedInfinitivePrefix
    case foldedInfinitiveSubstring
    case glossSubstring

    static func < (lhs: MatchKind, rhs: MatchKind) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }

  struct Match: Equatable, Sendable {
    let entry: VerbMapEntry
    let kind: MatchKind
  }

  /// Every verb in `entries` that matches `query`, one match per verb, its best, ranked by kind,
  /// then frequency, then infinitive. Empty for an empty query.
  static func matches(for query: String, in entries: some Sequence<VerbMapEntry>) -> [Match] {
    let spanish = spanishQuery(from: query)
    let english = glossQuery(from: query)
    guard !spanish.isEmpty || !english.isEmpty else {
      return []
    }
    let foldedSpanish = fold(spanish)

    var found: [Match] = []
    for entry in entries {
      if let kind = kind(of: keys(for: entry), spanish: spanish, foldedSpanish: foldedSpanish, english: english) {
        found.append(Match(entry: entry, kind: kind))
      }
    }
    return found.sorted {
      ($0.kind, $0.entry.frequencyRank, $0.entry.infinitive) < ($1.kind, $1.entry.frequencyRank, $1.entry.infinitive)
    }
  }

  /// Case and every diacritic folded away, ñ to n included, so that a learner without a Spanish
  /// keyboard finds añadir by typing anadir. For matching only: never render it.
  static func fold(_ text: String) -> String {
    text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
  }

  /// What a query asks of the infinitives. Learners type a pronominal verb in its dictionary
  /// form, so "levantarse", "levantar(se)", and "se levantar" all search for levantar. A trailing
  /// "se" goes only when what remains could be an infinitive, so that "base" and "clase" are
  /// searched as typed.
  static func spanishQuery(from query: String) -> String {
    var spanish = normalized(query)
    if spanish.hasPrefix("se ") {
      spanish = String(spanish.dropFirst(3)).trimmingCharacters(in: .whitespaces)
    }
    if spanish.hasSuffix("(se)") {
      spanish = String(spanish.dropLast(4)).trimmingCharacters(in: .whitespaces)
    } else if spanish.hasSuffix("se") {
      let remainder = String(spanish.dropLast(2))
      if infinitiveEndings.contains(where: { remainder.hasSuffix($0) }) {
        spanish = remainder
      }
    }
    return spanish
  }

  private static let infinitiveEndings = ["ar", "er", "ir", "ír"]

  /// What a query asks of the glosses. Glosses are stored without a leading "to", so a learner
  /// who types "to go" means "go".
  static func glossQuery(from query: String) -> String {
    let english = normalized(query)
    guard english.hasPrefix("to ") else {
      return english
    }
    let stripped = english.dropFirst(3).trimmingCharacters(in: .whitespaces)
    return stripped.isEmpty ? english : stripped
  }

  /// Lowercased, trimmed, and with runs of spaces collapsed, so that "  To   Go " is "to go".
  private static func normalized(_ query: String) -> String {
    query.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
  }

  /// Whether `word` appears in `text` with no letter touching either end, so that "eat" is a word
  /// of "eat" and "eat up" but not of "beat".
  static func containsWholeWord(_ word: String, in text: String) -> Bool {
    guard !word.isEmpty else {
      return false
    }
    var searchRange = text.startIndex..<text.endIndex
    while let range = text.range(of: word, range: searchRange) {
      let letterBefore = range.lowerBound > text.startIndex && text[text.index(before: range.lowerBound)].isLetter
      let letterAfter = range.upperBound < text.endIndex && text[range.upperBound].isLetter
      if !letterBefore && !letterAfter {
        return true
      }
      searchRange = text.index(after: range.lowerBound)..<text.endIndex
    }
    return false
  }

  /// A gloss's senses: llegar's "arrive, come" has two, and "come" is one of them.
  static func senses(of gloss: String) -> [String] {
    gloss
      .split { $0 == "," || $0 == ";" }
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }

  /// What a verb is matched on, lowercased and folded once rather than on every keystroke.
  private struct Keys: Sendable {
    let rawGlosses: [String]
    let infinitive: String
    let foldedInfinitive: String
    /// Every gloss of every sense of a homonym, lowercased.
    let glosses: [String]
    let glossSenses: Set<String>

    init(entry: VerbMapEntry) {
      rawGlosses = entry.glosses
      infinitive = entry.infinitive.lowercased()
      foldedInfinitive = VerbSearch.fold(infinitive)
      glosses = entry.glosses.map { $0.lowercased() }
      glossSenses = Set(glosses.flatMap { VerbSearch.senses(of: $0) })
    }
  }

  private static let bundledKeys: [String: Keys] = VerbMap.shared.entries.mapValues(Keys.init)

  private static func keys(for entry: VerbMapEntry) -> Keys {
    // A test may pass entries the bundled map lacks, or entries that differ from the bundled
    // ones under the same infinitive.
    if let keys = bundledKeys[entry.infinitive], keys.rawGlosses == entry.glosses {
      return keys
    }
    return Keys(entry: entry)
  }

  private static func kind(of keys: Keys, spanish: String, foldedSpanish: String, english: String) -> MatchKind? {
    if !spanish.isEmpty {
      if keys.infinitive == spanish {
        return .exactInfinitive
      }
      if keys.foldedInfinitive == foldedSpanish {
        return .exactFoldedInfinitive
      }
    }
    if keys.glossSenses.contains(english) {
      return .exactGlossSense
    }
    if !spanish.isEmpty && keys.infinitive.hasPrefix(spanish) {
      return .infinitivePrefix
    }
    if keys.glosses.contains(where: { containsWholeWord(english, in: $0) }) {
      return .wholeWordGloss
    }
    if !spanish.isEmpty {
      if keys.infinitive.contains(spanish) {
        return .infinitiveSubstring
      }
      if keys.foldedInfinitive.hasPrefix(foldedSpanish) {
        return .foldedInfinitivePrefix
      }
      if keys.foldedInfinitive.contains(foldedSpanish) {
        return .foldedInfinitiveSubstring
      }
    }
    if !english.isEmpty && keys.glosses.contains(where: { $0.contains(english) }) {
      return .glossSubstring
    }
    return nil
  }
}
