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
  static let identifier = "ResultCell"

  private let verb: UILabel = { return UILabel() } ()
  private let tensePersonNumber: UILabel = { return UILabel() } ()
  private let correctAnswer: UILabel = { return UILabel() } ()
  private let proposedAnswer: UILabel = { return UILabel() } ()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    _ = [verb, tensePersonNumber, correctAnswer, proposedAnswer].map {
      $0.textColor = Colors.yellow
      $0.font = Fonts.heading3
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }
    verb.font = Fonts.heading2
    backgroundColor = Colors.black
    selectionStyle = .none
    verb.topAnchor.constraint(equalTo: self.topAnchor, constant: 4.0).isActive = true
    verb.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    tensePersonNumber.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: 4.0).isActive = true
    tensePersonNumber.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    correctAnswer.topAnchor.constraint(equalTo: tensePersonNumber.bottomAnchor, constant: 4.0).isActive = true
    correctAnswer.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    proposedAnswer.topAnchor.constraint(equalTo: correctAnswer.bottomAnchor, constant: 4.0).isActive = true
    proposedAnswer.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
  }
  
  func configure(verb: String, tense: Tense, personNumber: PersonNumber, correctAnswer: String, proposedAnswer: String) {
    self.verb.text = verb.lowercased()
    tensePersonNumber.text = "\(tense.displayName), \(personNumber.shortDisplayName)"
    self.correctAnswer.attributedText = correctAnswer.conjugatedString
    if correctAnswer.lowercased() == proposedAnswer.lowercased() {
      self.proposedAnswer.text = proposedAnswer.lowercased()
    }
    else {
      self.proposedAnswer.attributedText = proposedAnswer.coloredString(color: Colors.blue)
    }
  }
}
