//
//  AppIcon.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// The user-selectable app icons, ported from Conjuguer's alternate-icon feature and
// adapted for Conjugar (July 2026). Three photoreal Spanish icons — a bull, a flamenco
// dancer, and a matador, each with a light and dark appearance variant — plus the
// original flat-vector dancer, retained as `classic` for nostalgia. The enum drives
// both the runtime icon swap (`alternateIconName`) and the Settings picker thumbnails
// (`previewAssetName`). `dancer` is the primary `DancerIcon` asset
// (`ASSETCATALOG_COMPILER_APPICON_NAME`), so its `alternateIconName` is nil and fresh
// installs default to it; the original flat-vector icon is the `ClassicIcon` alternate.
// `CaseIterable` order is the grid order (classic last).
enum AppIcon: String, CaseIterable {
  case bull
  case dancer
  case matador
  case classic

  // The name of the alternate-icon set in the asset catalog, or nil for the primary
  // DancerIcon. Must match the `.appiconset` name (exposed as an alternate icon via
  // ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES).
  var alternateIconName: String? {
    switch self {
    case .bull:
      return "BullIcon"
    case .dancer:
      return nil
    case .matador:
      return "MatadorIcon"
    case .classic:
      return "ClassicIcon"
    }
  }

  // The imageset shown as a tappable thumbnail in the Settings picker. The app icon
  // itself isn't loadable by name at runtime, so each icon ships a separate preview
  // imageset (light/dark variants where the icon has them).
  var previewAssetName: String {
    switch self {
    case .bull:
      return "BullIconPreview"
    case .dancer:
      return "DancerIconPreview"
    case .matador:
      return "MatadorIconPreview"
    case .classic:
      return "ClassicIconPreview"
    }
  }

  var localizedName: String {
    switch self {
    case .bull:
      return L.AppIcon.bull
    case .dancer:
      return L.AppIcon.dancer
    case .matador:
      return L.AppIcon.matador
    case .classic:
      return L.AppIcon.classic
    }
  }
}
