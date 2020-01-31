//
//  TestingRootViewController.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 1/31/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import UIKit
@testable import Conjugar

class TestingRootViewController: UIViewController {
  override func loadView() {
    let label = UILabel()
    label.text = "Running unit tests..."
    label.textAlignment = .center
    label.textColor = Colors.yellow
    label.font = Fonts.heading
    view = label
  }
}
