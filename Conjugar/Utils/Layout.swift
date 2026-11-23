//
//  Layout.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/8/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

struct Layout {
  static let defaultSpacing: CGFloat = 8.0
  static let doubleDefaultSpacing: CGFloat = 16.0
  static let tripleDefaultSpacing: CGFloat = 24.0
  static let defaultHorizontalMargin: CGFloat = 16.0
  /// Comfortable maximum measure for long-form linguistic reading content
  /// (Info articles, conjugation columns) on iPad / large Dynamic Type.
  static let readingWidth: CGFloat = 680.0
  /// Corner radius shared by cards and pills.
  static let cornerRadius: CGFloat = 12.0
  /// How far to grow a small glyph's hit area on each side, with `contentShape`, so that it
  /// reaches the 44-point minimum without changing the layout.
  static let tapTargetInset: CGFloat = 14.0
  /// The same, above and below a metadata pill, which is about 24 points tall.
  static let pillTapInset: CGFloat = 10.0
}
