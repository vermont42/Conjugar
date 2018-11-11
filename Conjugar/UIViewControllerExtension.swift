//
//  UIViewControllerExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 11/11/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

extension UIViewController {
  func fatalCastMessage(viewController: Any, view: Any) -> String {
    return "Could not cast \(viewController).view to \(view)."
  }
}
