//
//  MockNavigationC.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 8/27/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class MockNavigationC: UINavigationController {
  var pushedViewController: UIViewController?
  
  override func pushViewController(_ viewController: UIViewController, animated: Bool) {
    pushedViewController = viewController
    super.pushViewController(viewController, animated: true)
  }
}

