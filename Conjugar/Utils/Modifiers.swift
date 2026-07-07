//
//  Modifiers.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/3/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Shared view modifiers (SwiftUI migration, Step 3)
//
// The design-system primitives the mapped audit (`docs/conjugar-ui-issues.md`)
// leans on, ported and adapted from Konjugieren's `Utils/Modifiers.swift`. They
// all read from the adaptive color assets (`.customBackground`, `.customCardBackground`,
// `.customYellow`, `.customGreen`, …), so every one supports light **and** dark mode
// automatically. Point new SwiftUI screens at these convenience methods rather than
// re-deriving card/pill/serif treatments per view.

extension View {
  /// Wrap content in a rounded card: `customCardBackground` fill with a subtle
  /// `customCardBorder` rim. The workhorse surface behind quiz cards, conjugation
  /// sections, results summaries, settings groups, and the model header.
  func card(cornerRadius: CGFloat = Layout.cornerRadius) -> some View {
    modifier(Card(cornerRadius: cornerRadius))
  }

  /// A `card()` with a colored accent bar down its leading edge — used to key
  /// conjugation-section cards to their tense.
  func cardWithAccentBar(_ color: Color = .customYellow, cornerRadius: CGFloat = Layout.cornerRadius) -> some View {
    modifier(CardWithAccentBar(color: color, cornerRadius: cornerRadius))
  }

  /// Just the card's rim — for content that already draws its own fill.
  func cardRim(cornerRadius: CGFloat = Layout.cornerRadius) -> some View {
    modifier(CardRim(cornerRadius: cornerRadius))
  }

  /// Set linguistic content (Spanish infinitives, conjugation forms, tense
  /// headings, article titles) in a serif face to distinguish "language" from
  /// "UI chrome". _(audit K9 / C-cross)_
  func linguistic() -> some View {
    fontDesign(.serif)
  }

  /// Constrain long-form reading content to a comfortable measure, centered, so
  /// Info articles and conjugation columns don't sprawl on iPad / large type.
  func readingWidth(_ maxWidth: CGFloat = Layout.readingWidth) -> some View {
    frame(maxWidth: maxWidth)
      .frame(maxWidth: .infinity)
  }

  /// Stabilize changing numbers (score, progress, elapsed time) so the layout
  /// stops jittering per tick. _(audit C5 / K6)_
  func numeric() -> some View {
    monospacedDigit()
      .contentTransition(.numericText())
  }

  /// A tinted, capsule-shaped badge for metadata (irregularity percent, verb
  /// count, participio/gerundio). _(audit K12 / C15)_
  func metadataPill(tint: Color = .customYellow) -> some View {
    modifier(MetadataPill(tint: tint))
  }

  /// A light selection haptic keyed to `trigger`. Attach to sort controls and
  /// pickers. _(audit K13 / C19)_
  func selectionFeedback(trigger: some Equatable) -> some View {
    sensoryFeedback(.selection, trigger: trigger)
  }

  /// Speak `text` on tap and flash a brief background to confirm the tap landed
  /// (skipped under VoiceOver, which has its own affordance). _(audit K11 / §4)_
  func speakOnTapFlash(_ text: String, locale: String? = nil, flash: Color = .customYellow) -> some View {
    modifier(SpeakOnTapFlash(text: text, locale: locale, flash: flash))
  }
}

// MARK: - Button styles

/// The primary call-to-action: a filled, accent-tinted capsule that scales
/// slightly on press and shrinks to fit large Dynamic Type rather than clipping.
/// Primary CTAs take the yellow/accent tint — red is reserved for destructive /
/// error. _(audit §1 / C6)_
struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.button)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .foregroundStyle(Color.customBackground)
      .padding(.vertical, Layout.defaultSpacing)
      .padding(.horizontal, Layout.tripleDefaultSpacing)
      .background(Color.customYellow, in: Capsule())
      .opacity(configuration.isPressed ? 0.85 : 1)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.15), value: configuration.isPressed)
  }
}

/// A subtle, tinted capsule for secondary actions that live inside a card —
/// "Enable", "Rate or Review". Reads as tappable (tinted fill + rim, press
/// feedback) without the visual weight of `PrimaryButtonStyle`'s filled CTA, and
/// keys itself to a per-action `tint` so it matches its section's icon.
struct TintedCapsuleButtonStyle: ButtonStyle {
  var tint: Color = .customYellow

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.callout.weight(.semibold))
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .foregroundStyle(tint)
      .padding(.vertical, Layout.defaultSpacing)
      .padding(.horizontal, Layout.doubleDefaultSpacing)
      .background(tint.opacity(0.15), in: Capsule())
      .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
      .opacity(configuration.isPressed ? 0.7 : 1)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.15), value: configuration.isPressed)
  }
}

/// A text-only action link in the brand link color — for non-destructive
/// actions like "Enable" and "Rate or Review" that today render in red.
/// _(audit §9 / C11)_
struct LinkButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.button)
      .foregroundStyle(Color.customBlue)
      .opacity(configuration.isPressed ? 0.6 : 1)
  }
}

// MARK: - Private primitives

private struct Card: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .padding()
      .background(Color.customCardBackground)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(Color.customCardBorder, lineWidth: 1)
      )
  }
}

private struct CardWithAccentBar: ViewModifier {
  let color: Color
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .card(cornerRadius: cornerRadius)
      .overlay(alignment: .leading) {
        Rectangle()
          .fill(color)
          .frame(width: 3)
          .clipShape(RoundedRectangle(cornerRadius: 1.5))
      }
  }
}

private struct CardRim: ViewModifier {
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(Color.customCardBorder, lineWidth: 1)
      )
  }
}

private struct MetadataPill: ViewModifier {
  let tint: Color

  func body(content: Content) -> some View {
    content
      .font(.caption.weight(.semibold))
      .foregroundStyle(tint)
      .padding(.vertical, 4)
      .padding(.horizontal, Layout.defaultSpacing)
      .background(tint.opacity(0.15), in: Capsule())
  }
}

private struct SpeakOnTapFlash: ViewModifier {
  let text: String
  let locale: String?
  let flash: Color
  @State private var isSpeaking = false

  func body(content: Content) -> some View {
    content
      .background(flash.opacity(isSpeaking ? 0.15 : 0))
      .animation(.easeOut(duration: 0.15), value: isSpeaking)
      .onTapGesture {
        guard !UIAccessibility.isVoiceOverRunning else { return }
        Utterer.utter(text, locale: locale)
        isSpeaking = true
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(300))
          isSpeaking = false
        }
      }
  }
}
