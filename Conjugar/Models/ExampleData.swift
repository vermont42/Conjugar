//
//  ExampleData.swift
//  Conjugar
//
//  Supplies the modern-prose example for a verb, keyed by bare infinitive, loaded
//  once from the bundled `ExampleUses.json`. Mirrors `Etymology`/`EtymologyCache`:
//  a load-once `@unchecked Sendable` cache behind an `NSLock`, `nonisolated`
//  throughout so the MainActor UI can read it synchronously.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum ExampleData {
  private static let cache = ExampleCache()

  /// The modern example for a bare infinitive, or `nil` if none is on file.
  static func example(for infinitive: String) -> Example? {
    cache.example(for: infinitive)
  }
}

/// Loads `ExampleUses.json` once. `@unchecked Sendable` + a lock mirrors `VerbMap`'s
/// load-once cache so the lookup stays `nonisolated`.
nonisolated private final class ExampleCache: @unchecked Sendable {
  private let lock = NSLock()
  private var examples: [String: Example]?

  func example(for infinitive: String) -> Example? {
    lock.lock()
    defer { lock.unlock() }
    if examples == nil {
      examples = Self.load()
    }
    return examples?[infinitive]
  }

  private static func load() -> [String: Example] {
    let bundle = Bundle.main.url(forResource: "ExampleUses", withExtension: "json") != nil
      ? Bundle.main
      : Bundle(for: ExampleCache.self)
    guard
      let url = bundle.url(forResource: "ExampleUses", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let decoded = try? JSONDecoder().decode([String: Example].self, from: data)
    else {
      return [:]
    }
    return decoded
  }
}
