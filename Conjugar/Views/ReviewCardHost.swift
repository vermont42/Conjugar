//
//  ReviewCardHost.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The review card in the verb list, if one is offered: `VerbBrowseReviewCard`'s choice drawn as
/// a `ReviewCardView`, which stops at 560 points on a regular width rather than spanning the grid.
struct ReviewCardHost: View {
  let model: VerbBrowseReviewCard
  /// The tab's one push, which waits when a search is ending.
  let push: (VerbDestination) -> Void
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private static let maxWidth: CGFloat = 560

  var body: some View {
    if let card = model.shownCard {
      ReviewCardView(
        entry: card.offer.entry,
        daysSinceActivity: card.offer.daysSinceActivity,
        wasLookedUp: card.offer.wasLookedUp,
        isRevealed: card.isRevealed,
        reveal: {
          withAnimation {
            model.reveal()
          }
        },
        open: {
          if let destination = model.destination {
            push(destination)
          }
        },
        dismiss: {
          withAnimation {
            model.dismiss()
          }
        }
      )
      .frame(maxWidth: horizontalSizeClass == .regular ? Self.maxWidth : .infinity)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal)
      .padding(.top, Layout.defaultSpacing)
      .transition(.opacity)
      .onAppear {
        model.cardAppeared()
      }
    }
  }
}
