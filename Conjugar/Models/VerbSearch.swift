//
//  VerbSearch.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The one matching and ranking rule for verb search. Every search calls it, so that what a
/// learner finds cannot depend on where the learner typed.
nonisolated enum VerbSearch {
  /// The kinds of match, best first. Within a kind, the more frequent verb ranks first, whatever
  /// order the list is sorted in.
  ///
  /// A gloss sense that is the whole query outranks an infinitive that merely begins with it,
  /// because the commonest English queries are also Spanish prefixes: "go" would otherwise list
  /// golpear, gobernar, and gozar above ir, "be" beber above ser, and "do" dormir above hacer.
  /// Below that, a literal match outranks a folded one of the same shape, so sonar leads soñar.
  ///
  /// A form of a verb ranks below an exact gloss sense, so that "come" keeps llegar and venir
  /// first and "listen" finds escuchar before listar, and above an infinitive prefix, so that "ve"
  /// finds ir and ver before verter and "come" finds comer before comenzar. A form found only by
  /// folding ranks right after a literal one, not below every literal kind: Spanish learners leave
  /// accents out, and "de", "se", and "esta" must find dar, saber, and estar before the hundreds
  /// of verbs that begin with them.
  enum MatchKind: Int, CaseIterable, Comparable, Sendable {
    case exactInfinitive
    case exactFoldedInfinitive
    case exactGlossSense
    case conjugation
    case foldedConjugation
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

    /// For a conjugation match, the forms the query matched, literal ones first: "hablo" gives
    /// hablo (presente, yo) and then habló (pretérito, él). Empty for any other kind.
    let forms: [MatchedForm]

    init(entry: VerbMapEntry, kind: MatchKind, forms: [MatchedForm] = []) {
      self.entry = entry
      self.kind = kind
      self.forms = forms
    }
  }

  /// Every verb in `entries` that matches `query`, one match per verb, its best, ranked by kind,
  /// then frequency, then infinitive. Empty for an empty query. A query that is a form of a verb
  /// finds the verb through `FormLookup`, in `index`.
  static func matches(for query: String, in entries: some Sequence<VerbMapEntry>, index: ConjugationIndex = .bundled) -> [Match] {
    let spanish = spanishQuery(from: query)
    let english = glossQuery(from: query)
    guard !spanish.isEmpty || !english.isEmpty else {
      return []
    }
    let foldedSpanish = SpellingComparison.fold(spanish)

    var entriesByInfinitive: [String: VerbMapEntry] = [:]
    var best: [String: Match] = [:]
    for entry in entries {
      entriesByInfinitive[entry.infinitive] = entry
      if let kind = kind(of: keys(for: entry), spanish: spanish, foldedSpanish: foldedSpanish, english: english) {
        best[entry.infinitive] = Match(entry: entry, kind: kind)
      }
    }

    for (infinitive, forms) in FormLookup.forms(for: query, index: index) {
      guard let entry = entriesByInfinitive[infinitive] else {
        continue
      }
      let kind: MatchKind = forms.contains { !$0.isFolded } ? .conjugation : .foldedConjugation
      if let current = best[infinitive], current.kind <= kind {
        continue
      }
      best[infinitive] = Match(entry: entry, kind: kind, forms: forms)
    }

    return best.values.sorted {
      ($0.kind, $0.entry.frequencyRank, $0.entry.infinitive) < ($1.kind, $1.entry.frequencyRank, $1.entry.infinitive)
    }
  }

  /// A verb offered when a search matched nothing, with the form it was guessed from, if it was
  /// guessed from one.
  struct Guess: Equatable, Sendable {
    let entry: VerbMapEntry
    let form: MatchedForm?
  }

  /// The verb whose folded infinitive, or one of whose folded forms, is fewest edits from the
  /// folded query: "hablr" guesses hablar, and "tenjo" guesses tener through tengo. On a tie an
  /// infinitive beats a form, so only a form nearer than every infinitive is considered. Among
  /// forms, ties break as `closestVerb` breaks them. A form must begin with the query's first
  /// letter, as a learner's misspelling usually does, which keeps the comparison to a few
  /// thousand forms rather than a quarter of a million. Nil when nothing is near enough.
  static func guess(for query: String, in entries: some Sequence<VerbMapEntry>, index: ConjugationIndex = .bundled) -> Guess? {
    let entries = Array(entries)
    let foldedQuery = Array(SpellingComparison.fold(spanishQuery(from: query)))
    guard !foldedQuery.isEmpty else {
      return nil
    }
    let infinitiveGuess = closestVerb(to: query, in: entries)
    let infinitiveDistance = infinitiveGuess.map { SpellingComparison.editDistance(foldedQuery, Array(keys(for: $0).foldedInfinitive)) }
    // A form at distance zero would have matched, so a guess one edit away cannot be beaten.
    guard !foldedQuery.contains(" "), infinitiveDistance.map({ $0 > 1 }) ?? true else {
      return infinitiveGuess.map { Guess(entry: $0, form: nil) }
    }

    let maxDistance = min(maxGuessDistance(forQueryLength: foldedQuery.count), (infinitiveDistance ?? Int.max) - 1)
    let entriesByInfinitive = Dictionary(entries.map { ($0.infinitive, $0) }) { first, _ in first }
    var best: (guess: Guess, rank: (Int, Int, Int))?
    let queryLetters = Array(String(foldedQuery).utf8)
    for folded in index.foldedForms(startingWith: foldedQuery[0], nearLength: foldedQuery.count, distance: maxDistance) {
      guard let distance = SpellingComparison.editDistance(queryLetters, Array(folded.utf8), limit: maxDistance) else {
        continue
      }
      let candidate = Array(folded)
      let sharedPrefix = zip(foldedQuery, candidate).prefix { $0 == $1 }.count
      for form in index.forms(folding: folded) {
        for mapEntry in index.map.entries(for: form) {
          guard let entry = entriesByInfinitive[mapEntry.infinitive] else {
            continue
          }
          let rank = (distance, foldedQuery.count - sharedPrefix, entry.frequencyRank)
          if let current = best, current.rank <= rank {
            continue
          }
          let cells = ConjugationMatch.inPageOrder(mapEntry.cells.filter { $0.tense != .infinitivo })
          let matched = cells.isEmpty ? nil : MatchedForm(text: form, cells: cells, isFolded: false)
          best = (Guess(entry: entry, form: matched), rank)
        }
      }
    }
    return best?.guess ?? infinitiveGuess.map { Guess(entry: $0, form: nil) }
  }

  /// The verb whose folded infinitive is fewest edits from the folded query, for a search that
  /// found nothing. On a tie, the verb that shares more of the query's beginning wins, because a
  /// learner usually gets the start of a word right: "hablr" is one edit from haber as well as
  /// from hablar, but shares four letters with hablar and three with haber. Then the more
  /// frequent verb wins. Nil when no verb is near enough to be
  /// a plausible misspelling, so that nonsense guesses nothing. The query is read as the
  /// infinitive search reads it, so a pronominal "levantarse" is measured as levantar.
  static func closestVerb(to query: String, in entries: some Sequence<VerbMapEntry>) -> VerbMapEntry? {
    let foldedQuery = Array(SpellingComparison.fold(spanishQuery(from: query)))
    guard !foldedQuery.isEmpty else {
      return nil
    }
    let maxDistance = maxGuessDistance(forQueryLength: foldedQuery.count)
    // Lower is better in every place: the distance, the letters of the query's beginning that
    // the candidate lacks, and the frequency rank.
    var best: (entry: VerbMapEntry, rank: (Int, Int, Int))?
    for entry in entries {
      let candidate = Array(keys(for: entry).foldedInfinitive)
      guard abs(candidate.count - foldedQuery.count) <= maxDistance else {
        continue
      }
      let distance = SpellingComparison.editDistance(foldedQuery, candidate)
      guard distance <= maxDistance else {
        continue
      }
      let sharedPrefix = zip(foldedQuery, candidate).prefix { $0 == $1 }.count
      let rank = (distance, foldedQuery.count - sharedPrefix, entry.frequencyRank)
      if let current = best, current.rank <= rank {
        continue
      }
      best = (entry, rank)
    }
    return best?.entry
  }

  /// One edit in three letters, and never more than three, keeps a guess recognizable: hablr
  /// finds hablar, but a four-letter query never "finds" a verb that shares one letter with it.
  static func maxGuessDistance(forQueryLength length: Int) -> Int {
    min(3, max(1, length / 3))
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
    } else if let bare = ReflexivePronoun.bareInfinitive(fromCitation: spanish) {
      spanish = bare
    }
    return spanish
  }

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

  /// The index of `entry`'s first gloss that has `query` as a sense in full: 1 for apostar and
  /// "station", its second sense. Nil when no gloss does.
  static func sense(of entry: VerbMapEntry, namedBy query: String) -> Int? {
    let english = glossQuery(from: query)
    return entry.glosses.firstIndex { senses(of: $0.lowercased()).contains(english) }
  }

  /// What a verb is matched on, lowercased and folded once rather than on every keystroke.
  private struct Keys: Sendable {
    /// The entry the keys were made from, so that a cached set serves only that entry.
    let entry: VerbMapEntry
    let infinitive: String
    let foldedInfinitive: String
    /// A reflexive-only verb's infinitive with its "se", as the list shows it (arrepentirse), so
    /// that a query typed toward it ("arrepentirs") keeps finding it. Nil for any other verb.
    let citation: String?
    let foldedCitation: String?
    /// Every gloss of every sense of a homonym, lowercased.
    let glosses: [String]
    let glossSenses: Set<String>

    init(entry: VerbMapEntry) {
      self.entry = entry
      infinitive = entry.infinitive.lowercased()
      foldedInfinitive = SpellingComparison.fold(infinitive)
      citation = entry.isReflexive ? entry.citationForm.lowercased() : nil
      foldedCitation = citation.map(SpellingComparison.fold)
      glosses = entry.glosses.map { $0.lowercased() }
      glossSenses = Set(glosses.flatMap { VerbSearch.senses(of: $0) })
    }
  }

  private static let bundledKeys: [String: Keys] = VerbMap.shared.entries.mapValues(Keys.init)

  private static func keys(for entry: VerbMapEntry) -> Keys {
    // A test may pass entries the bundled map lacks, or entries that differ from the bundled
    // ones under the same infinitive, in any field that a key reads.
    if let keys = bundledKeys[entry.infinitive], keys.entry == entry {
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
    if !spanish.isEmpty && (keys.infinitive.hasPrefix(spanish) || keys.citation?.hasPrefix(spanish) == true) {
      return .infinitivePrefix
    }
    if keys.glosses.contains(where: { containsWholeWord(english, in: $0) }) {
      return .wholeWordGloss
    }
    if !spanish.isEmpty {
      if keys.infinitive.contains(spanish) {
        return .infinitiveSubstring
      }
      if keys.foldedInfinitive.hasPrefix(foldedSpanish) || keys.foldedCitation?.hasPrefix(foldedSpanish) == true {
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
