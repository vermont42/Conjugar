//
//  UIViewExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/12/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

extension UIView {
  func pulsate() {
    let duration: TimeInterval = 0.3
    let scale: CGFloat = 0.6
    UIView.animate(withDuration: duration, animations: {
      self.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
    }, completion: { _ in
      UIView.animate(withDuration: duration, animations: {
        self.transform = CGAffineTransform.identity
      })
    })
  }
}

extension UIView {
  func setAccessibilityLabelInSpanish(_ label: String, region: String = Current.settings.region.accent) {
    setAccessibilityLabel(label, spokenInLanguage: "es_\(region)")
  }

  private func setAccessibilityLabel(_ label: String, spokenInLanguage languageCode: String) {
    let attributes: [NSAttributedString.Key: Any] = [
      .accessibilitySpeechLanguage: languageCode
    ]
    let attributedLabel = NSAttributedString(string: label, attributes: attributes)
    accessibilityAttributedLabel = attributedLabel
  }
}
