//
//  ContentCaches.swift
//  Conjugar
//
//  A single entry point for pre-warming the three bundled content caches
//  (`Etymology`, `ExampleData`, `MedievalData`) off the main actor. Each cache loads
//  its whole JSON file on first touch regardless of the key, so one lookup apiece
//  triggers the parse; a launch-time `Task.detached` calls `warm()` so the first
//  Browse→verb push doesn't pay the ~4 MB decode on the main thread. Everything it
//  touches is `nonisolated` + lock-guarded, so off-main warming is safe by design.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum ContentCaches {
  /// Force all three content caches to load. Any key works — the caches load the full
  /// file on first access — so a sentinel infinitive that isn't in the tables is fine.
  static func warm() {
    let sentinel = "__warm__"
    _ = Etymology.text(for: sentinel)
    _ = ExampleData.example(for: sentinel)
    _ = MedievalData.examples(for: sentinel)
  }
}
