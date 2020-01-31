//
//  TenseCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 5/7/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class TenseCell: UITableViewCell {
  static let identifier = "TenseCell"

  @UsesAutoLayout
  var tense: UILabel = {
    let label = UILabel()
    label.textColor = Colors.red
    label.font = Fonts.regularCell
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    selectionStyle = .none
    addSubview(tense)

    NSLayoutConstraint.activate([
      tense.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.defaultSpacing),
      tense.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Layout.defaultSpacing * -1.0),
      tense.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }

  func configure(tense: String) {
    self.tense.text = tense
  }
}
