//
//  VerbCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class VerbCell: UITableViewCell {
  static let identifier = "VerbCell"
  
  private let verb: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.largeCell
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    addSubview(verb)
    
    addConstraint(NSLayoutConstraint(item: verb, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
    addConstraint(NSLayoutConstraint(item: verb, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
  }
  
  func configure(verb: String) {
    self.verb.text = verb
  }
}
