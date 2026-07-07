//
//  UIAlertControllerExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/19/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

extension UIAlertController {
  class func showMessage(_ message: String, title: String, okTitle: String, onViewController viewController: UIViewController, handler: ((UIAlertAction) -> Void)? = nil) {
      let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
      let okAction = UIAlertAction(title: okTitle, style: UIAlertAction.Style.default, handler: handler)
      alertController.addAction(okAction)
      viewController.present(alertController, animated: true, completion: nil)
  }
}
