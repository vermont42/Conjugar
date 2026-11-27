//
//  EqualWidthRow.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A row of children of equal width and equal height, which fills the width it is offered.
///
/// Its ideal width is honest: as many times the widest child's ideal width as there are children,
/// plus the gaps. So inside `ViewThatFits(in: .horizontal)` the row is chosen only when every
/// child would get the width it needs, and a level name that cannot wrap falls through to a layout
/// with fewer columns instead of truncating. An `HStack` of `maxWidth: .infinity` children always
/// claims to fit, because its ideal width is the sum of its children's, not the widest one's
/// times their number.
struct EqualWidthRow: SwiftUI.Layout {
  let spacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard !subviews.isEmpty else {
      return .zero
    }
    let width: CGFloat
    if let proposed = proposal.width, proposed.isFinite {
      width = proposed
    } else {
      let widest = subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
      width = widest * CGFloat(subviews.count) + gaps(subviews)
    }
    let childWidth = self.childWidth(in: width, subviews: subviews)
    let height = subviews.map { $0.sizeThatFits(ProposedViewSize(width: childWidth, height: nil)).height }.max() ?? 0
    return CGSize(width: width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let childWidth = self.childWidth(in: bounds.width, subviews: subviews)
    var x = bounds.minX
    for subview in subviews {
      subview.place(
        at: CGPoint(x: x, y: bounds.minY),
        anchor: .topLeading,
        proposal: ProposedViewSize(width: childWidth, height: bounds.height)
      )
      x += childWidth + spacing
    }
  }

  private func gaps(_ subviews: Subviews) -> CGFloat {
    spacing * CGFloat(max(subviews.count - 1, 0))
  }

  private func childWidth(in width: CGFloat, subviews: Subviews) -> CGFloat {
    max((width - gaps(subviews)) / CGFloat(max(subviews.count, 1)), 0)
  }
}
