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
  internal var infoIndex = 0
  internal weak var infoDelegate: InfoDelegate? = nil
  
  override func viewDidLoad() {
    infoView.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    infoView.attributedText = (Info.infos[infoIndex]).infoString
  }
  
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    if let index = Info.infoTitles.index(of: URL.absoluteString) {
      navigationController?.popViewController(animated: true)
      infoDelegate?.infoSelectionDidChange(newIndex: index)
    }
    return false
  }
}

