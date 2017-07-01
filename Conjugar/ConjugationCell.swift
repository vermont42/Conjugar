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
  
  override func awakeFromNib() {
    super.awakeFromNib()
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap(_:))))
  }
  
  func configure(tense: Tense, personNumber: PersonNumber, conjugation: String) {
    var conjugation = conjugation
    if conjugation == Conjugator.defective {
      self.conjugation.text = ""
    }
    else {
      if tense == .imperativo || tense == .imperativoNegativo {
        conjugation = "¡" + conjugation + "!"
      }
      else {
        conjugation = personNumber.pronoun + " " + conjugation
      }
      self.conjugation.attributedText = conjugation.attributedString
    }
  }
  
  @objc func tap(_ sender: UITapGestureRecognizer) {
    Utterer.utter(conjugation.attributedText?.string ?? conjugation.text!)
  }
}
