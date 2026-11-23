//
//  BrowseSearch.swift
//  Conjugar
//
//  Filter the current items by the query, returning everything when the query is
//  empty. The Models tab filters through it with its own `matches` closure. The Verbs
//  tab, which ranks its matches, uses `VerbSearch` instead; the two share only
//  `VerbSearch.fold`. A **pure** function: the no-results sad trombone is fired by the
//  caller from an `.onChange` handler — the one-shot search transition — rather than as
//  a side effect of view evaluation, so it can't re-fire on unrelated re-renders.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum BrowseSearch {
  static func results<Item>(
    in items: [Item],
    query: String,
    matches: (Item, String) -> Bool
  ) -> [Item] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return items
    }
    return items.filter { matches($0, trimmed) }
  }
}
