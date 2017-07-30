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
  private var safeBottomInset: CGFloat = 0.0
  
  internal let info: UITextView = {
    let textView = UITextView()
    textView.backgroundColor = Colors.black
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.font = Fonts.body
    textView.textColor = Colors.yellow
    textView.isEditable = false
    return textView
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  private func commonInit() {
    addSubview(info)
    let defaultSpacing: CGFloat = 8.0
    info.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    info.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    info.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    if #available(iOS 11.0, *) {
      info.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * defaultSpacing).isActive = true
    } else { // TODO: Delete this logic, safeBottomInset, and the associated init when iOS 11 goes live.
      info.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -1.0 * (safeBottomInset + defaultSpacing)).isActive = true
    }
  }
  
  convenience init(frame: CGRect, safeBottomInset: CGFloat) {
    self.init(frame: frame)
    self.safeBottomInset = safeBottomInset
    commonInit()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }
}
