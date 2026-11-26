//
//  ModelSearch.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The Models tab's search: the models its text finds, in the chosen order, and when a failed
/// search earns the sad trombone. Unlike the Verbs tab, it does not rank.
struct ModelSearch {
  /// Every model in each order, sorted once.
  static let modelsBySort = ModelSort.sortedLists(of: ModelInfo.all)

  private(set) var text = ""
  private(set) var sort: ModelSort
  /// The models the list shows: every model while nothing but spaces is typed.
  private(set) var models: [ModelInfo]

  init(sort: ModelSort) {
    self.sort = sort
    models = Self.modelsBySort[sort] ?? []
  }

  /// Whether the text holds a query. A space alone is not one, so it neither hides the collections
  /// nor filters anything.
  var isSearching: Bool {
    !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// Takes the field's text and the picker's order. Returns true when the text changed to a query
  /// that finds nothing, which is when the sad trombone plays; a new order for the same failed query
  /// is not another failure.
  mutating func update(text: String, sort: ModelSort) -> Bool {
    let textChanged = text != self.text
    self.text = text
    self.sort = sort
    models = Self.models(in: Self.modelsBySort[sort] ?? [], matching: text)
    return textChanged && isSearching && models.isEmpty
  }

  /// The models whose exemplar or class number contains the query after `SpellingComparison.fold`, the
  /// Verbs tab's folding, which drops case and every diacritic, ñ included, so that a query behaves
  /// alike in both tabs: `28` or `4B` finds a model by its class number, `hacer` by its exemplar.
  /// Every model, in order, when the query is empty or only spaces.
  static func models(in models: [ModelInfo], matching query: String) -> [ModelInfo] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return models
    }
    let folded = SpellingComparison.fold(trimmed)
    return models.filter { model in
      SpellingComparison.fold(model.exemplar).contains(folded) || SpellingComparison.fold(model.classNumber).contains(folded)
    }
  }
}
