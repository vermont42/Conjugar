//
//  TenseCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/7/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class TenseCell: UITableViewCell {
  @IBOutlet var tense: UILabel!
  static let identifier = "TenseCell"
  
  func configure(tense: String) {
    self.tense.text = tense
  }
}
