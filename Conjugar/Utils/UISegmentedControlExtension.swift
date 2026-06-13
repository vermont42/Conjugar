//
//  UISegmentedControlExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 9/29/19.
//  Copyright © 2019 Josh Adams. All rights reserved.
//

import UIKit

extension UISegmentedControl {
  func yellowfyText() {
    let titleTextAttributes = [NSAttributedString.Key.foregroundColor: Colors.yellow]
    setTitleTextAttributes(titleTextAttributes, for: .normal)
    setTitleTextAttributes(titleTextAttributes, for: .selected)
  }
}
