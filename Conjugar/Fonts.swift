//
//  Fonts.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

struct Fonts {
  static let heading = UIFont(name: "AvenirNext-Bold", size: 24.0) ?? safeFont
  static let subheading = UIFont(name: "AvenirNext-Demibold", size: 18.0) ?? safeFont
  static let largeCell = UIFont(name: "AvenirNext-Regular", size: 24.0) ?? safeFont
  static let regularCell = UIFont(name: "AvenirNext-Bold", size: 18.0) ?? safeFont
  static let smallCell = UIFont(name: "AvenirNext-Regular", size: 18.0) ?? safeFont
  static let button = UIFont(name: "AvenirNext-Demibold", size: 24.0) ?? safeFont
  static let label = UIFont(name: "AvenirNext-Demibold", size: 18.0) ?? safeFont
  static let body = UIFont(name: "AvenirNext-Regular", size: 16.0) ?? safeFont
  static let smallBody = UIFont(name: "AvenirNext-Demibold", size: 12.0) ?? safeFont
  static let boldBody = UIFont(name: "AvenirNext-Bold", size: 16.0) ?? safeFont
  private static let safeFont = UIFont.systemFont(ofSize: 18.0)
}
