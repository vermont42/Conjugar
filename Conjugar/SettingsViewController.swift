//
//  SettingsViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/24/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
  @IBOutlet var regionControl: UISegmentedControl!
  @IBOutlet var difficultyControl: UISegmentedControl!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateControls()
  }
  
  private func updateControls() {
    switch SettingsManager.getRegion() {
    case .spain:
      regionControl.selectedSegmentIndex = 0
    case .latinAmerica:
      regionControl.selectedSegmentIndex = 1
    }
    
    switch SettingsManager.getDifficulty() {
    case .easy:
      difficultyControl.selectedSegmentIndex = 0
    case .moderate:
      difficultyControl.selectedSegmentIndex = 1
    case .difficult:
      difficultyControl.selectedSegmentIndex = 2
    }
  }
  
  @IBAction func regionChanged() {
    let index = regionControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setRegion(.spain)
    }
    else /* index == 1 */ {
      SettingsManager.setRegion(.latinAmerica)
    }
  }
  
  @IBAction func difficultyChanged() {
    let index = difficultyControl.selectedSegmentIndex
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
