//
//  InfoUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/30/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class InfoUIV: UIView {
  @UsesAutoLayout
  var info: UITextView = {
    var textView = UITextView()
    textView.backgroundColor = Colors.black
    textView.textColor = Colors.yellow
    textView.tintColor = Colors.blue
    textView.isEditable = false
    return textView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(info)

    NSLayoutConstraint.activate([
      info.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      info.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      info.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      info.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }
}
