//
//  VerbCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class VerbCell: UITableViewCell {
  @IBOutlet var verb: UILabel!
  
  func configure(verb: String) {
    self.verb.text = verb
  }
}
