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
  
  internal let verb: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.largeCell
    label.enableAutoLayout()
    return label
  } ()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    addSubview(verb)
    verb.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    verb.centerYAnchor.constraint(equalTo: centerYAnchor).activate()
  }
  
  func configure(verb: String) {
    self.verb.text = verb
  }
}

