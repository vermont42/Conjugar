//
//  HapticPlayerDummy.swift
//  Conjugar
//
//  The test-world conformer: a no-op so the unit-test and UI-test worlds never touch
//  the Taptic Engine (matching the SoundPlayer…Real/Dummy convention). A Dummy —
//  passed to fill the slot, never exercised.
//

class HapticPlayerDummy: HapticPlayer {
  func prepare() {}
  func play(_ haptic: Haptic) {}
}
