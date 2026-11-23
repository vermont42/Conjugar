//
//  Colors.swift
//  Conjugar
//
//  Created by Adams, Josh on 5/13/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

/// Conjugar's semantic color palette, backed by the light/dark colorsets in
/// `Assets.xcassets`. Every color adapts to the current appearance, so the app
/// supports light **and** dark mode automatically.
///
/// SwiftUI code should prefer the auto-generated asset symbols directly
/// (`Color.customYellow`, `Color.customBackground`, …). This type is the
/// **UIKit-facing** bridge, for the few UIKit call sites (the segmented-control
/// appearance in `AppDelegate`). Both read from the same colorsets, so the two APIs
/// never drift.
enum Colors {
  /// Conjugar's brand red (193, 0, 29) — interactive text and buttons. Identical
  /// in both appearances; legible on white and on black.
  static let red = UIColor.customRed
  /// Conjugar's brand gold — headings and highlights. Bright yellow (205, 165, 27)
  /// in dark mode; a darker, legible gold on white in light mode.
  static let yellow = UIColor.customYellow
  /// Conjugar's brand blue — links. Darkened for contrast in light mode.
  static let blue = UIColor.customBlue
  /// The "correct" semantic. A legible forest green in light mode; a brighter
  /// green in dark mode. Quiz/results correctness gets its own color so that `red`
  /// means only error/irregularity.
  static let green = UIColor.customGreen

  /// The app background, the same color as `background`.
  static let black = UIColor.customBackground
  /// The app background. White (light) / black (dark).
  static let background = UIColor.customBackground
  /// Primary neutral text. Black (light) / white (dark).
  static let foreground = UIColor.customForeground
  /// Card / grouped-content fill.
  static let cardBackground = UIColor.customCardBackground
  /// Subtle accent-tinted card border.
  static let cardBorder = UIColor.customCardBorder
}
