//
//  InfoCell.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class InfoCell: UITableViewCell {
  static let identifier = "InfoCell"

  let heading: UILabel = {
    let label = UILabel()
    label.textColor = Colors.yellow
    label.font = Fonts.boldBody
    label.enableAutoLayout()
    return label
  }()

  required init?(coder aDecoder: NSCoder) {
    UIViewController.fatalErrorNotImplemented()
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = Colors.black
    addSubview(heading)
    heading.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    heading.centerYAnchor.constraint(equalTo: centerYAnchor).activate()
  }

  func configure(heading: String) {
    self.heading.text = heading
  }
}
