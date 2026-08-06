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
