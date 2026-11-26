//
//  VerbDestination.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A verb page to push, with the way the learner reached it. Every stack that shows verb pages
/// pushes this rather than a bare infinitive, so that the page can report its `source`; each
/// registers it through `verbPageDestinations()`.
nonisolated struct VerbDestination: Hashable, Sendable {
  let infinitive: String
  let source: AnalyticsSource

  /// The cells that the search, link, or quiz correction which opened the page matched. The page
  /// scrolls to the first of them and marks them all. Empty for any other way in.
  let marks: Set<ConjugationCell>

  init(infinitive: String, source: AnalyticsSource, marks: Set<ConjugationCell> = []) {
    self.infinitive = infinitive
    self.source = source
    self.marks = marks
  }
}
