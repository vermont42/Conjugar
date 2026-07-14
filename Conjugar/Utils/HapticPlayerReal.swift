//
//  HapticPlayerReal.swift
//  Conjugar
//
//  UIKit-backed haptics. The generators are held (not created per call) and
//  re-`prepare()`d after each fire, which is Apple's recommended pattern for
//  low-latency, repeated feedback — a fresh generator would otherwise cold-start
//  the Taptic Engine (~tens of ms) on its first use. All UIFeedbackGenerator work
//  is main-actor, which is where the game loop's judgments already run.
//

import UIKit

class HapticPlayerReal: HapticPlayer {
  private let notification = UINotificationFeedbackGenerator()
  private let impactLight = UIImpactFeedbackGenerator(style: .light)
  private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
  private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

  func prepare() {
    notification.prepare()
    impactLight.prepare()
    impactMedium.prepare()
    impactHeavy.prepare()
  }

  func play(_ haptic: Haptic) {
    switch haptic {
    case .impactLight:
      impactLight.impactOccurred()
      impactLight.prepare()
    case .impactMedium:
      impactMedium.impactOccurred()
      impactMedium.prepare()
    case .impactHeavy:
      impactHeavy.impactOccurred()
      impactHeavy.prepare()
    case .success:
      notification.notificationOccurred(.success)
      notification.prepare()
    case .warning:
      notification.notificationOccurred(.warning)
      notification.prepare()
    case .error:
      notification.notificationOccurred(.error)
      notification.prepare()
    }
  }
}
