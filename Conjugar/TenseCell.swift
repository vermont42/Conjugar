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
  
  private let tense: UILabel = {
    let label = UILabel()
    label.textColor = Colors.red
    label.font = Fonts.regularCell
    label.enableAutoLayout()
    return label
  } ()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    selectionStyle = .none
    addSubview(tense)
    tense.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    tense.centerYAnchor.constraint(equalTo: centerYAnchor).activate()
  }
  
  func configure(tense: String) {
    self.tense.text = tense
  }
}



