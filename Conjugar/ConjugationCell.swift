//
//  ConjugationCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/7/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class ConjugationCell: UITableViewCell {
  @IBOutlet var conjugation: UILabel!
  
  func configure(tense: Tense, personNumber: PersonNumber, conjugation: String) {
    if conjugation == Conjugator.defective {
      self.conjugation.text = ""
    }
    else {
      if tense == .imperativo || tense == .imperativoNegativo {
        self.conjugation.text = "¡" + conjugation + "!"
      }
      else {
        self.conjugation.text = personNumber.pronoun + " " + conjugation
      }
    }
  }
}
