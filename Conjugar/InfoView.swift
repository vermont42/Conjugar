//
//  InfoView.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/30/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class InfoView: UIView {
  internal let info: UITextView = {
    let textView = UITextView()
    textView.backgroundColor = Colors.black
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.textColor = Colors.yellow
    textView.isEditable = false
    return textView
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(info)
    info.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    info.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    info.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    if #available(iOS 11.0, *) {
      info.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).isActive = true
    } else {
      info.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).isActive = true
    }
  }
}
