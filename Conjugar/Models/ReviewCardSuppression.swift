//
//  ReviewCardSuppression.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Whether the verb list hides the review card. Off by default. The raw values are the persisted
/// `Settings.reviewCardSuppression` value; keep them stable.
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
