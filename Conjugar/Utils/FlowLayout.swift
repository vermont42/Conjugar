//
//  FlowLayout.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Lays its children out in rows, wrapping to a new row when the next child would not fit.
/// `SwiftUI.Layout` is spelled out because the app has a `Layout` of its own.
struct FlowLayout: SwiftUI.Layout {
  var spacing: CGFloat = 8
  /// Centers each row in the width offered, as the Quiz tab's chips are, rather than starting it
  /// at the leading edge.
  var centersRows = false
  /// Centers each child in its row's height, as a sentence's words sit beside its taller field,
  /// rather than aligning the children's tops.
  var centersItemsVertically = false

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let rows = rows(for: subviews, width: proposal.width ?? .infinity)
    let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
    let width = rows.map(\.width).max() ?? 0
    return CGSize(width: proposal.width ?? width, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    var y = bounds.minY
    for row in rows(for: subviews, width: bounds.width) {
      var x = centersRows ? bounds.minX + max(bounds.width - row.width, 0) / 2 : bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        let offset = centersItemsVertically ? (row.height - size.height) / 2 : 0
        subviews[index].place(at: CGPoint(x: x, y: y + offset), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += row.height + spacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
    var rows: [Row] = []
    var current = Row()
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let widthWithChild = current.indices.isEmpty ? size.width : current.width + spacing + size.width
      if widthWithChild > width, !current.indices.isEmpty {
        rows.append(current)
        current = Row()
      }
      current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
      current.height = max(current.height, size.height)
      current.indices.append(index)
    }
    if !current.indices.isEmpty {
      rows.append(current)
    }
    return rows
  }
}
