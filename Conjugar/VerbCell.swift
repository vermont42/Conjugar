//
//  VerbCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbCell: UITableViewCell {
  static let identifier = "VerbCell"

  let verb: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.largeCell
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.enableAutoLayout()
    return label
  }()

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    addSubview(verb)

    NSLayoutConstraint.activate([
      verb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      verb.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Layout.defaultSpacing * -1.0),
      verb.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  func configure(verb: String) {
    self.verb.text = verb
  }
}
