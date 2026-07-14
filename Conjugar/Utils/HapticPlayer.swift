//
//  HapticPlayer.swift
//  Conjugar
//
//  The haptics seam, ported from the sibling apps' game feedback and following the
//  same protocol-injected shape as `SoundPlayer`. Wired into `World` as
//  `Current.hapticPlayer` — `HapticPlayerReal` (UIKit feedback generators) on
//  device/simulator, `HapticPlayerDummy` in the test worlds so unit/UI tests never
//  touch the Taptic Engine. Haptics also no-op on devices without a Taptic Engine
//  and when the user has system haptics off, so callers need not gate on hardware.
//

@MainActor
protocol HapticPlayer {
  /// Warm the feedback generators so the first `play(_:)` fires with minimal
  /// latency. Called when the boss fight starts. Safe to call repeatedly.
  func prepare()
  func play(_ haptic: Haptic)
}
