//
//  SecondSingularBrowse.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/8/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

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
      return Localizations.both
    }
  }
}
