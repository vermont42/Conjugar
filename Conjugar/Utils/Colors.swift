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
/// supports light **and** dark mode automatically — replacing the four fixed,
/// dark-only `UIColor`s this file held through mid-2026.
///
/// SwiftUI code should prefer the auto-generated asset symbols directly
/// (`Color.customYellow`, `Color.customBackground`, …); those are what the ported
/// Konjugieren views use. This type is the **UIKit-facing** bridge: it keeps the
/// legacy `Colors.red/yellow/blue/black` names compiling for the not-yet-migrated
/// UIKit screens, which now become appearance-aware for free, and it names the
/// newer semantic roles (`foreground`, `cardBackground`, `cardBorder`) for any
/// remaining UIKit use. Both sets read from the same colorsets, so the two APIs
/// never drift.
enum Colors {
  // MARK: Brand accents (legacy names kept for UIKit call sites)

  /// Conjugar's brand red (193, 0, 29) — interactive text and buttons. Identical
  /// in both appearances; legible on white and on black.
  static let red = UIColor.customRed
  /// Conjugar's brand gold — headings and highlights. Bright yellow (205, 165, 27)
  /// in dark mode; a darker, legible gold on white in light mode.
  static let yellow = UIColor.customYellow
  /// Conjugar's brand blue — links. Darkened for contrast in light mode.
  static let blue = UIColor.customBlue

  // MARK: Semantic roles

  /// The app background. White in light mode, pure black in dark mode. Named
  /// `black` for source compatibility with the dark-only UIKit screens that set
  /// `backgroundColor = Colors.black`; retire in favor of `background` as those
  /// screens migrate to SwiftUI.
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
