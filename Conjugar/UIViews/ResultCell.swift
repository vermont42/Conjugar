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

  @UsesAutoLayout private(set) var verb = UILabel()
  @UsesAutoLayout private(set) var tensePersonNumber = UILabel()
  @UsesAutoLayout private(set) var correctAnswer = UILabel()
  @UsesAutoLayout private(set) var proposedAnswer = UILabel()

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    [verb, tensePersonNumber, correctAnswer, proposedAnswer].forEach {
      $0.textColor = Colors.yellow
      $0.font = Fonts.smallCell
      addSubview($0)
    }
    verb.font = Fonts.regularCell
    backgroundColor = Colors.black
    selectionStyle = .none

    NSLayoutConstraint.activate([
      verb.topAnchor.constraint(equalTo: topAnchor, constant: 4.0),
      verb.centerXAnchor.constraint(equalTo: centerXAnchor),
      tensePersonNumber.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: 4.0),
      tensePersonNumber.centerXAnchor.constraint(equalTo: centerXAnchor),
      correctAnswer.topAnchor.constraint(equalTo: tensePersonNumber.bottomAnchor, constant: 4.0),
      correctAnswer.centerXAnchor.constraint(equalTo: centerXAnchor),
      proposedAnswer.topAnchor.constraint(equalTo: correctAnswer.bottomAnchor, constant: 4.0),
      proposedAnswer.centerXAnchor.constraint(equalTo: centerXAnchor)
    ])
  }

  func configure(verb: String, tense: Tense, personNumber: PersonNumber, correctAnswer: String, proposedAnswer: String) {
    self.verb.text = verb.lowercased()
    tensePersonNumber.text = "\(tense.displayName), \(personNumber.shortDisplayName)"
    self.correctAnswer.attributedText = correctAnswer.conjugatedString
    self.proposedAnswer.text = proposedAnswer.lowercased()
    if correctAnswer.lowercased() != proposedAnswer.lowercased() {
      self.proposedAnswer.textColor = Colors.blue
    }
  }
}
