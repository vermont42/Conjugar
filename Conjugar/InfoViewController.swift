//
//  InfoViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class InfoViewController: UIViewController, UITextViewDelegate {
  @IBOutlet var infoView: UITextView!
  internal weak var infoDelegate: InfoDelegate? = nil
  internal var infoString: NSAttributedString?
  
  override func viewDidLoad() {
    infoView.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    guard let infoString = infoString else { fatalError("InfoViewController's infoString property is nil.") }
    infoView.attributedText = infoString
  }
  
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    let http = "http"
    if URL.absoluteString.prefix(http.characters.count) == http {
      return true
    }
    else {
      navigationController?.popViewController(animated: true)
      infoDelegate?.infoSelectionDidChange(newHeading: URL.absoluteString)
      return false
    }
  }
}

