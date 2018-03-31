//
//  UILabelExtension.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/30/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

extension UILabel {
  static func titleLabel(title: String) -> UILabel {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = Fonts.heading
    titleLabel.textColor = Colors.yellow
    let width = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
    let tappableHeight: CGFloat = 100.0
    titleLabel.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: width, height: tappableHeight))
    return titleLabel
  }
}
