//
//  FontExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI

extension Font {
  static var heading: Font {
    Font.custom("AvenirNext-Bold", size: 24.0)
  }

  static var subheading: Font {
    Font.custom("AvenirNext-Bold", size: 18.0)
  }

  static var smallBody: Font {
    Font.custom("AvenirNext-Demibold", size: 12.0)
  }

  static var button: Font {
    Font.custom("AvenirNext-Demibold", size: 24.0)
  }
}
