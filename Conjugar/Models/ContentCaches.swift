//
//  ContentCaches.swift
//  Conjugar
//
//  A single entry point for pre-warming the three bundled content caches
//  (`Etymology`, `ExampleData`, `MedievalData`), and the derived lists that the verb page
//  and the Models tab read on first use, off the main actor. Each cache loads
//  its whole JSON file on first touch regardless of the key, so one lookup apiece
//  triggers the parse; a launch-time `Task.detached` calls `warm()` so the first
//  Browse→verb push doesn't pay the ~4 MB decode on the main thread. Everything it
//  touches is `nonisolated` and either lock-guarded or a `static let`, which Swift
//  initializes once under its own lock, so off-main warming is safe by design.
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
    // The related verbs' index, which the verb page's card reads.
    _ = VerbRelations.shared
    // The Models tab's rows and its featured collections, which conjugate about a thousand
    // verbs: 0.3 to 0.8 s of the tab's first visit in a Debug build in the simulator.
    _ = ModelInfo.all
    _ = VerbCollection.featured.map(\.verbs)
  }
}
