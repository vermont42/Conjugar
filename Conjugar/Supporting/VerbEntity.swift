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

/// Finds verbs for a parameter's picker, as the verb list's search finds them. The first call loads
/// the verb map, and a search the conjugation index, which took 7.8 seconds cold in a Debug build in
/// the simulator. Called through `EntityStringQuery`, as App Intents calls it, a method already runs
/// off the main actor (measured 2026-11-26); called directly from it, a nonisolated async method
/// would run there. Each is `@concurrent`, as `LookUpVerbIntent`'s lookup is, so that neither way
/// waits on the main actor.
nonisolated struct VerbEntityQuery: EntityStringQuery {
  static let matchLimit = 25

  @concurrent
  func entities(for identifiers: [String]) async -> [VerbEntity] {
    identifiers.compactMap { VerbMap.shared.entry(for: $0).map { VerbEntity(entry: $0) } }
  }

  // Ranking happens before the limit, so that the verb asked for is not cut off behind 25
  // verbs that merely begin with it.
  @concurrent
  func entities(matching string: String) async -> [VerbEntity] {
    VerbSearch.matches(for: string, in: VerbMap.shared.entries.values)
      .prefix(Self.matchLimit)
      .map { VerbEntity(entry: $0.entry) }
  }

  @concurrent
  func suggestedEntities() async -> [VerbEntity] {
    VerbMap.shared.entriesByFrequency
      .prefix(10)
      .map { VerbEntity(entry: $0) }
  }
}
