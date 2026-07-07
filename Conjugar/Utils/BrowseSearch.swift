//
//  BrowseSearch.swift
//  Conjugar
//
//  The one piece the Verb and Model browse screens genuinely share: filter the
//  current items by the query, returning everything when the query is empty and
//  playing the sad trombone once when an active query finds nothing. Each screen
//  keeps its own `matches` closure, so the rest of its view stays self-contained.
//  Ported from Conjuguer's BrowseSearch, adapted to Conjugar's static SoundPlayer.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

enum BrowseSearch {
  static func results<Item>(
    in items: [Item],
    query: String,
    playSoundIfEmpty: Bool,
    matches: (Item, String) -> Bool
  ) -> [Item] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return items
    }
    let filtered = items.filter { matches($0, trimmed) }
    if filtered.isEmpty && playSoundIfEmpty {
      SoundPlayer.playRandomSadTrombone()
    }
    return filtered
  }
}
