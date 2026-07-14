//
//  Haptic.swift
//  Conjugar
//
//  The vocabulary of tactile feedback, played through `Current.hapticPlayer`
//  (see `HapticPlayer`). Ported from the sibling apps' game feedback; Conjugar
//  taps it on the boss fight's dance judgments so a correct echo, a banked phrase,
//  a fail, and the freeze "hold!" moment each have their own feel. The cases map
//  onto UIKit's feedback generators: `selection` → `UISelectionFeedbackGenerator`,
//  the `impact*` → `UIImpactFeedbackGenerator`, and `success`/`warning`/`error` →
//  `UINotificationFeedbackGenerator`.
//

enum Haptic {
  /// A light tick — the crisp confirmation of a single correct dance move.
  case impactLight
  /// A rounder pop — surviving the freeze fake-out.
  case impactMedium
  /// A weighty thud — the bull's opening llamada stomp.
  case impactHeavy
  /// The rising three-tap "yes" — a banked phrase / the win.
  case success
  /// The double buzz that says "careful" — entering a freeze hold.
  case warning
  /// The sharp "no" — a failed phrase.
  case error
}
