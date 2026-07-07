//
//  RichTextView.swift
//  Conjugar
//
//  Renders the parsed Info markup (`[RichTextBlock]`, see RichText.swift) as
//  native SwiftUI Text. Ported and adapted from Konjugieren's `RichTextView`.
//  Body copy is set in the adaptive `customForeground` (audit §8: "reconsider the
//  all-gold body text"); subheadings are serif gold; irregular conjugation spans
//  are `customRed`; links route through the environment's `openURL` action.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct RichTextView: View {
  let blocks: [RichTextBlock]

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      ForEach(blocks, id: \.self) { block in
        switch block {
        case .subheading(let text):
          HStack(alignment: .center, spacing: Layout.defaultSpacing) {
            Circle()
              .fill(Color.customRed)
              .frame(width: 4, height: 4)
            Text(text)
              .font(.title3.bold())
              .fontDesign(.serif)
              .foregroundStyle(Color.customYellow)
              .accessibilityAddTraits(.isHeader)
          }
          .padding(.top, Layout.defaultSpacing)
          .frame(maxWidth: .infinity, alignment: .leading)

        case .body(let segments):
          BodyTextView(segments: segments)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
  }
}

private struct BodyTextView: View {
  let segments: [TextSegment]

  var body: some View {
    Text(combinedAttributedString)
      .lineSpacing(4)
  }

  /// Concatenate every segment's attributed string into one, preserving each
  /// run's color / emphasis / link so the whole body renders as a single `Text`.
  private var combinedAttributedString: AttributedString {
    segments.reduce(into: AttributedString()) { $0.append(attributedString(for: $1)) }
  }

  private func attributedString(for segment: TextSegment) -> AttributedString {
    switch segment {
    case .plain(let text):
      var attributed = AttributedString(text)
      attributed.foregroundColor = Color.customForeground
      return attributed

    case .bold(let text):
      var attributed = AttributedString(text)
      attributed.inlinePresentationIntent = .stronglyEmphasized
      attributed.foregroundColor = Color.customForeground
      return attributed

    case .link(let text, let url):
      let markdownLink = "[\(text)](\(url.absoluteString))"
      if let attributedLink = try? AttributedString(markdown: markdownLink) {
        return attributedLink
      }
      var attributed = AttributedString(text)
      attributed.foregroundColor = Color.customBlue
      attributed.underlineStyle = .single
      return attributed

    case .conjugation(let parts):
      var result = AttributedString()
      for part in parts {
        switch part {
        case .regular(let text):
          var regularAttr = AttributedString(text)
          regularAttr.foregroundColor = Color.customForeground
          result.append(regularAttr)
        case .irregular(let text):
          var irregularAttr = AttributedString(text)
          irregularAttr.foregroundColor = Color.customRed
          result.append(irregularAttr)
        }
      }
      return result
    }
  }
}
