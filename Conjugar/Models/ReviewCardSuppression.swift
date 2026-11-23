//
//  ReviewCardSuppression.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Whether the verb list hides the review card (browse plan, Phase 15). Off by default, as in
/// Konjugieren, where Josh asked for the setting after trying the card. The raw values are the
/// persisted `Settings.reviewCardSuppression` value; keep them stable.
enum ReviewCardSuppression: String, CaseIterable {
  case off
  case on

  var localizedReviewCardSuppression: String {
    switch self {
    case .off:
      return L.ReviewCardSuppression.off
    case .on:
      return L.ReviewCardSuppression.on
    }
  }
}
