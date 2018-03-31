//
//  NSLayoutConstraintExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/19/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {
  @discardableResult func activate() -> NSLayoutConstraint {
    isActive = true
    return self
  }
}
