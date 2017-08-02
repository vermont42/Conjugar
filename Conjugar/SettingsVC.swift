//
//  SettingsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/24/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class SettingsVC: UIViewController {
  var settingsView: SettingsView {
    return view as! SettingsView
  }
  
  override func loadView() {
    let settingsView: SettingsView
    if #available(iOS 11.0, *) {
      settingsView = SettingsView(frame: UIScreen.main.bounds)
    }
    else {
      settingsView = SettingsView(frame: UIScreen.main.bounds, safeBottomInset: 49)
    }
//    guard let infoString = infoString else { fatalError("InfoVC's infoString property is nil.") }
//    infoView.info.attributedText = infoString
//    infoView.info.delegate = self
//    infoView.info.contentOffset = CGPoint.zero
    view = settingsView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = UILabel.titleLabel(title: "Settings")
    //    updateControls()
  }
  
  
//
//
//  private func updateControls() {
//    switch SettingsManager.getRegion() {
//    case .spain:
//      regionControl.selectedSegmentIndex = 0
//    case .latinAmerica:
//      regionControl.selectedSegmentIndex = 1
//    }
//
//    switch SettingsManager.getDifficulty() {
//    case .easy:
//      difficultyControl.selectedSegmentIndex = 0
//    case .moderate:
//      difficultyControl.selectedSegmentIndex = 1
//    case .difficult:
//      difficultyControl.selectedSegmentIndex = 2
//    }
//  }
//
//  @IBAction func regionChanged() {
//    let index = regionControl.selectedSegmentIndex
//    if index == 0 {
//      SettingsManager.setRegion(.spain)
//    }
//    else /* index == 1 */ {
//      SettingsManager.setRegion(.latinAmerica)
//    }
//  }
  
//  @IBAction func difficultyChanged() {
//    let index = difficultyControl.selectedSegmentIndex
//    if index == 0 {
//      SettingsManager.setDifficulty(.easy)
//    }
//    else if index == 1 {
//      SettingsManager.setDifficulty(.moderate)
//    }
//    else /* index == 2 */ {
//      SettingsManager.setDifficulty(.difficult)
//    }
//  }
}

//class InfoVC: UIViewController, UITextViewDelegate {
//  internal weak var infoDelegate: InfoDelegate? = nil
//  internal var infoString: NSAttributedString?
//  var infoView: InfoView {
//    return view as! InfoView
//  }
//
//  override func loadView() {
//    let infoView: InfoView
//    if #available(iOS 11.0, *) {
//      infoView = InfoView(frame: UIScreen.main.bounds)
//    }
//    else {
//      infoView = InfoView(frame: UIScreen.main.bounds, safeBottomInset: 49)
//    }
//    guard let infoString = infoString else { fatalError("InfoVC's infoString property is nil.") }
//    infoView.info.attributedText = infoString
//    infoView.info.delegate = self
//    infoView.info.contentOffset = CGPoint.zero
//    view = infoView
//  }
//
//  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
//    let http = "http"
//    if URL.absoluteString.prefix(http.characters.count) == http {
//      return true
//    }
//    else {
//      navigationController?.popViewController(animated: true)
//      infoDelegate?.infoSelectionDidChange(newHeading: URL.absoluteString)
//      return false
//    }
//  }
//}

