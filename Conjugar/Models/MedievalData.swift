//
//  MedievalData.swift
//  Conjugar
//
//  Supplies the array of Medieval-Spanish examples for a verb, keyed by bare
//  infinitive, loaded once from the bundled `MedievalExamples.json`. Mirrors
//  `ExampleData`/`EtymologyCache`: a load-once `@unchecked Sendable` cache behind an
//  `NSLock`, `nonisolated` throughout. Returns `[]` when the verb has none.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum MedievalData {
  private static let cache = MedievalCache()

  /// Every Medieval-Spanish example for a bare infinitive (possibly empty).
  static func examples(for infinitive: String) -> [MedievalExample] {
    cache.examples(for: infinitive)
  }
}

/// Loads `MedievalExamples.json` once. `@unchecked Sendable` + a lock mirrors
/// `VerbMap`'s load-once cache so the lookup stays `nonisolated`.
nonisolated private final class MedievalCache: @unchecked Sendable {
  private let lock = NSLock()
  private var examples: [String: [MedievalExample]]?

  func examples(for infinitive: String) -> [MedievalExample] {
    lock.lock()
    defer { lock.unlock() }
    if examples == nil {
      examples = Self.load()
    }
    return examples?[infinitive] ?? []
  }

  private static func load() -> [String: [MedievalExample]] {
    let bundle = Bundle.main.url(forResource: "MedievalExamples", withExtension: "json") != nil
      ? Bundle.main
      : Bundle(for: MedievalCache.self)
    guard
      let url = bundle.url(forResource: "MedievalExamples", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let decoded = try? JSONDecoder().decode([String: [MedievalExample]].self, from: data)
    else {
      return [:]
    }
    return decoded
  }
}
