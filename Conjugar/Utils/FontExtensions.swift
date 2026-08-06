//
//  FontExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI

extension Font {
  static var button: Font {
    Font.custom("AvenirNext-Demibold", size: 24.0)
  }

  /// A large rounded numeral for hero counts — the Results score, promoted from a
  /// labeled line to a big color-coded number. Pair with `.numeric()` to animate
  /// it up.
  static var heroNumeral: Font {
    Font.system(size: 64.0, weight: .bold, design: .rounded)
  }
}
