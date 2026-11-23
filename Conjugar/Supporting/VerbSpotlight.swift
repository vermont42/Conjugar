//
//  VerbSpotlight.swift
//  Conjugar
//
//  Conjugar's Spotlight entries.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import CoreSpotlight

/// One Spotlight entry per verb, in a named index. Each can be found by its infinitive, by every
/// sense of its glosses, and by its one-word forms, so that typing fue or "arrive" on the Home
/// Screen can find ir or llegar. In the iOS 26.3 simulator Spotlight matched titles only, so
/// whether the other fields help is a device's question; see `docs/release.md`.
nonisolated enum VerbSpotlight {
  struct Text: Hashable, Sendable {
    /// The glosses' phrases, then the key conjugations (tengo, tuve, tendré, tenido). Spotlight
    /// shows the first under the description, so the gloss leads.
    let alternateNames: [String]

    /// Every one-word form in the conjugation map, then the glosses whole and their phrases with
    /// and without "to".
    let keywords: [String]

    /// Shown under the title: the key conjugations, which stand alone with no label. Spotlight
    /// shows a description on one line, so a gloss beside them would run into them.
    let description: String
  }

  static let indexName = "verbs"

  /// Builds every verb's entry and indexes them, at each launch. The engine is nonisolated, so all
  /// of it runs off the main actor. Building the entries takes about two seconds in a Debug build
  /// on an Intel Mac, and the indexing call about twenty more, so a verb first shows in Spotlight
  /// some seconds after the first launch. Conjugar never used the default index, so there is
  /// nothing to delete first. (Deleting entities from the default index empties the named one
  /// too.)
  @concurrent
  static func indexVerbs() async {
    let entities = entities()
    try? await CSSearchableIndex(name: indexName).indexAppEntities(entities)
  }

  static func entities(map: ConjugationMap = .bundled) -> [VerbEntity] {
    let forms = formsByInfinitive(in: map)
    return VerbMap.shared.entries.values
      .sorted { $0.infinitive < $1.infinitive }
      .map { VerbEntity(entry: $0, spotlight: text(for: $0, forms: forms[$0.infinitive] ?? [])) }
  }

  static func text(for entry: VerbMapEntry, forms: [String]) -> Text {
    let glossPhrases = entry.glosses.flatMap(glossPhrases(in:)).uniqued()
    let keyConjugations = KeyConjugation.forms(of: entry.infinitive).map { $0.form.lowercased() }
    return Text(
      alternateNames: (glossPhrases + keyConjugations).uniqued(),
      keywords: (forms + entry.glosses + glossPhrases + glossPhrases.map { "to \($0)" }).uniqued(),
      description: keyConjugations.joined(separator: " · ")
    )
  }

  /// The phrases a reader might type for a gloss: "arrive, come" gives "arrive" and "come", and
  /// "put (something) away" gives "put away". The parentheses only say what the verb takes.
  static func glossPhrases(in gloss: String) -> [String] {
    gloss
      .replacing(/\([^)]*\)/, with: "")
      .split(whereSeparator: { $0 == "," || $0 == ";" })
      .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
      .filter { !$0.isEmpty }
  }

  /// Each verb's distinct one-word forms (fue, fui, yendo), in the map's order of cells. The
  /// map has no compound tenses and no imperativo negativo, whose last word is already a form.
  static func formsByInfinitive(in map: ConjugationMap) -> [String: [String]] {
    map.paradigms().mapValues { forms in
      forms.dropFirst().compactMap { $0 }.uniqued()
    }
  }

  /// The infinitive of the entry a Spotlight result names. A continued activity carries the
  /// entity's identifier, which iOS has written both bare and as "VerbEntity/<id>".
  static func infinitive(fromActivityIdentifier identifier: String) -> String? {
    let id = identifier.split(separator: "/").last.map(String.init) ?? identifier
    return VerbMap.shared.entry(for: id) == nil ? nil : id
  }
}

extension Array where Element: Hashable {
  /// The elements in order, each at its first appearance.
  nonisolated func uniqued() -> [Element] {
    var seen: Set<Element> = []
    return filter { seen.insert($0).inserted }
  }
}
