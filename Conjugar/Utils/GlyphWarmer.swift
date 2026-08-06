//
//  GlyphWarmer.swift
//  Conjugar
//
//  Ported from Conjuguer (commit 9bb4f3e). Pre-rasterizes emoji glyphs into the
//  process-wide CoreText/CoreGraphics glyph cache. The first time a large color-emoji
//  glyph is drawn — especially flag emoji (🇪🇸, 🇲🇽, …) — CoreText loads and
//  rasterizes its color bitmap synchronously, stalling the SwiftUI render thread
//  (~0.5s, measured) the frame that glyph first appears. Conjugar's game rains flag
//  emoji, so warming them off-main at game start turns that stall into a cache hit.
//  The cache is process-wide, so warming in a throwaway offscreen bitmap benefits
//  SwiftUI's later Text render.
//

import UIKit

enum GlyphWarmer {
  // (glyph, font point size) pairs. Safe to call off the main actor: it only
  // does UIKit text drawing into private offscreen contexts, which is thread-safe.
  nonisolated static func warm(_ glyphs: [(String, CGFloat)]) {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 3 // @3x covers the densest device; warms the largest bitmap.
    format.opaque = false
    for (glyph, size) in glyphs {
      let attributed = NSAttributedString(
        string: glyph,
        attributes: [.font: UIFont.systemFont(ofSize: size)]
      )
      let measured = attributed.size()
      let renderSize = CGSize(
        width: max(1, ceil(measured.width)),
        height: max(1, ceil(measured.height))
      )
      let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
      _ = renderer.image { _ in
        attributed.draw(at: .zero)
      }
    }
  }
}
