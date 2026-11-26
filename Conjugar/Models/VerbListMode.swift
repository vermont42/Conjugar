//
//  VerbListMode.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// What the verb list shows while its search field is empty: every verb in a sort order, or My
/// Verbs. The picker under the list offers all three. Only a sort is saved in Settings, so the app
/// always opens on the full list, where the launch anchor is.
///
/// Nonisolated, with only its name on the main actor: a main-actor enum's synthesized `Hashable`
/// conformance is isolated, and `PickerOption` cannot take an isolated one.
nonisolated enum VerbListMode: PickerOption {
  case frequency
  case alphabetical
  case myVerbs

  init(sort: VerbSort) {
    switch sort {
    case .frequency:
      self = .frequency
    case .alphabetical:
      self = .alphabetical
    }
  }

  /// The sort order this mode lists every verb in, or nil for My Verbs.
  var sort: VerbSort? {
    switch self {
    case .frequency:
      return .frequency
    case .alphabetical:
      return .alphabetical
    case .myVerbs:
      return nil
    }
  }

  @MainActor var localizedDisplayName: String {
    sort?.localizedDisplayName ?? L.MyVerbs.title
  }
}
