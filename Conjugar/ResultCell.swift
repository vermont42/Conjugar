//
//  ResultCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class ResultCell: UITableViewCell {
  @IBOutlet var verbLabel: UILabel!
  @IBOutlet var tensePersonNumberLabel: UILabel!
  @IBOutlet var correctAnswerLabel: UILabel!
  @IBOutlet var proposedAnswerLabel: UILabel!
  
  func configure(verb: String, tense: Tense, personNumber: PersonNumber, correctAnswer: String, proposedAnswer: String) {
    verbLabel.text = verb.lowercased()
    tensePersonNumberLabel.text = "\(tense.displayName), \(personNumber.shortDisplayName)"
    correctAnswerLabel.attributedText = correctAnswer.attributedString
    if correctAnswer.lowercased() == proposedAnswer.lowercased() {
      proposedAnswerLabel.text = proposedAnswer.lowercased()
    }
    else {
      proposedAnswerLabel.attributedText = proposedAnswer.uppercased().attributedString(color: Colors.blue)
    }
  }
}
