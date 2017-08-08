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
    settingsView = SettingsView(frame: UIScreen.main.bounds)
    settingsView.regionControl.addTarget(self, action: #selector(SettingsVC.regionChanged(_:)), for: .valueChanged)
    settingsView.difficultyControl.addTarget(self, action: #selector(SettingsVC.difficultyChanged(_:)), for: .valueChanged)
    navigationItem.titleView = UILabel.titleLabel(title: "Settings")
    view = settingsView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateControls()
  }
  
  private func updateControls() {
    switch SettingsManager.getRegion() {
    case .spain:
      settingsView.regionControl.selectedSegmentIndex = 0
    case .latinAmerica:
      settingsView.regionControl.selectedSegmentIndex = 1
    }
    
    switch SettingsManager.getDifficulty() {
    case .easy:
      settingsView.difficultyControl.selectedSegmentIndex = 0
    case .moderate:
      settingsView.difficultyControl.selectedSegmentIndex = 1
    case .difficult:
      settingsView.difficultyControl.selectedSegmentIndex = 2
    }
  }
  
  @objc func regionChanged(_ sender: UISegmentedControl) {
    let index = settingsView.regionControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setRegion(.spain)
    }
    else /* index == 1 */ {
      SettingsManager.setRegion(.latinAmerica)
    }
  }
  
  @objc func difficultyChanged(_ sender: UISegmentedControl) {
    let index = settingsView.difficultyControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setDifficulty(.easy)
    }
    else if index == 1 {
      SettingsManager.setDifficulty(.moderate)
    }
    else /* index == 2 */ {
      SettingsManager.setDifficulty(.difficult)
    }
  }
}

