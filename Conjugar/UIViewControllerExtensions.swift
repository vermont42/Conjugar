//
//  UIViewControllerExtensions.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/11/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

extension UIViewController {
  func fatalCastMessage(view: Any) -> String {
    return "Could not cast \(self).view to \(view)."
  }

  static func fatalErrorNotImplemented() -> Never {
    fatalError("init(coder:) has not been implemented")
  }
}
