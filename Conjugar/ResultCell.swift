//
//  ResultCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

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
    [verb, tensePersonNumber, correctAnswer, proposedAnswer].forEach {
      $0.textColor = Colors.yellow
      $0.font = Fonts.smallCell
      $0.enableAutoLayout()
      addSubview($0)
    }
    verb.font = Fonts.regularCell
    backgroundColor = Colors.black
    selectionStyle = .none
    verb.topAnchor.constraint(equalTo: topAnchor, constant: 4.0).activate()
    verb.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    tensePersonNumber.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: 4.0).activate()
    tensePersonNumber.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    correctAnswer.topAnchor.constraint(equalTo: tensePersonNumber.bottomAnchor, constant: 4.0).activate()
    correctAnswer.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    proposedAnswer.topAnchor.constraint(equalTo: correctAnswer.bottomAnchor, constant: 4.0).activate()
    proposedAnswer.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
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
