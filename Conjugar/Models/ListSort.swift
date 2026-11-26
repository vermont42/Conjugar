//
//  ListSort.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A choice that a segmented `SortPicker` offers, each case under its localized name.
@MainActor protocol PickerOption: Hashable, CaseIterable where AllCases: RandomAccessCollection {
  var localizedDisplayName: String { get }
}

/// An order for a list's items: `VerbSort` for verbs, `ModelSort` for models.
protocol ListSort: PickerOption {
  associatedtype Item

  func sorted(_ items: some Sequence<Item>) -> [Item]
}

extension ListSort {
  /// The items in every order, sorted once, so that changing the order sorts nothing.
  static func sortedLists(of items: some Sequence<Item>) -> [Self: [Item]] {
    let items = Array(items)
    return Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.sorted(items)) })
  }
}
