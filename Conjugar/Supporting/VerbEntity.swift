//
//  VerbEntity.swift
//  Conjugar
//
//  A verb as App Intents and Spotlight see it.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import AppIntents
import CoreSpotlight

/// One verb, identified by the bare infinitive that `VerbMap` and links key on, and titled as the
/// app shows it (arrepentirse). `VerbSpotlight` indexes one per verb.
nonisolated struct VerbEntity: AppEntity, IndexedEntity {
  static let typeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Intent.verbEntityName", defaultValue: "Verb"))
  static let defaultQuery = VerbEntityQuery()

  let id: String
  let citationForm: String
  let gloss: String

  /// Set only on the entities that `VerbSpotlight` indexes. A query's entities leave it nil,
  /// because a picker shows only the title and subtitle.
  var spotlight: VerbSpotlight.Text?

  init(entry: VerbMapEntry, spotlight: VerbSpotlight.Text? = nil) {
    id = entry.infinitive
    citationForm = entry.citationForm
    gloss = entry.gloss
    self.spotlight = spotlight
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(citationForm)", subtitle: "\(gloss)")
  }

  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = defaultAttributeSet
    if let spotlight {
      attributes.alternateNames = spotlight.alternateNames
      attributes.keywords = spotlight.keywords
      attributes.contentDescription = spotlight.description
    }
    return attributes
  }
}

/// Finds verbs for a parameter's picker, as the verb list's search finds them.
nonisolated struct VerbEntityQuery: EntityStringQuery {
  static let matchLimit = 25

  func entities(for identifiers: [String]) async -> [VerbEntity] {
    identifiers.compactMap { VerbMap.shared.entry(for: $0).map { VerbEntity(entry: $0) } }
  }

  // Ranking happens before the limit, so that the verb asked for is not cut off behind 25
  // verbs that merely begin with it.
  func entities(matching string: String) async -> [VerbEntity] {
    VerbSearch.matches(for: string, in: VerbMap.shared.entries.values)
      .prefix(Self.matchLimit)
      .map { VerbEntity(entry: $0.entry) }
  }

  func suggestedEntities() async -> [VerbEntity] {
    VerbMap.shared.entries.values
      .sorted { $0.frequencyRank < $1.frequencyRank }
      .prefix(10)
      .map { VerbEntity(entry: $0) }
  }
}
