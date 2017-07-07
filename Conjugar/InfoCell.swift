//
//  InfoCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class InfoCell: UITableViewCell {
  @IBOutlet var heading: UILabel!
  
  func configure(heading: String) {
    self.heading.text = heading
  }
}
