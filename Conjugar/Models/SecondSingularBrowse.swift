//
//  SecondSingularBrowse.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

// The raw values are the persisted `Settings.secondSingularBrowse` value; keep them
// stable (renaming a case's raw value would silently reset stored user prefs — item
// 20). The *displayed* label is decoupled via `localizedSecondSingularBrowse`, so a
// label change never needs to touch the persisted raw value.
enum SecondSingularBrowse: String, CaseIterable {
  case tu = "Tú"
  case vos = "Vos"
  case both = "Both"

  /// The second-singular person the verb page hides, which a search's match line and a link's
  /// marks leave out where the other person shares its form. See `MatchedForm.shownCells(hiding:)`.
  var hiddenPersons: Set<DisplayPersonNumber> {
    switch self {
    case .tu:
      return [.secondSingularVos]
    case .vos:
      return [.secondSingularTú]
    case .both:
      return []
    }
  }

  var localizedSecondSingularBrowse: String {
    switch self {
    case .tu:
      return rawValue
    case .vos:
      return rawValue
    case .both:
      return L.Both.feminine
    }
  }
}
