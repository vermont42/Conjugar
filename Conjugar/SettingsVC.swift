//
//  SettingsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/24/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

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
    settingsView.browseVosControl.addTarget(self, action: #selector(SettingsVC.browseVosChanged(_:)), for: .valueChanged)
    settingsView.quizVosControl.addTarget(self, action: #selector(SettingsVC.quizVosChanged(_:)), for: .valueChanged)
    settingsView.gameCenterButton.addTarget(self, action: #selector(authenticate), for: .touchUpInside)

    navigationItem.titleView = UILabel.titleLabel(title: "Settings")
    view = settingsView
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateControls()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    [settingsView.gameCenterLabel, settingsView.gameCenterDescription, settingsView.gameCenterButton].forEach {
      $0.isHidden = GameCenterManager.shared.isAuthenticated
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !settingsView.gameCenterButton.isHidden {
      settingsView.gameCenterButton.pulsate()
    }
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

    switch SettingsManager.getSecondSingularBrowse() {
    case .tu:
      settingsView.browseVosControl.selectedSegmentIndex = 0
    case .vos:
      settingsView.browseVosControl.selectedSegmentIndex = 1
    case .both:
      settingsView.browseVosControl.selectedSegmentIndex = 2
    }

    switch SettingsManager.getSecondSingularQuiz() {
    case .tu:
      settingsView.quizVosControl.selectedSegmentIndex = 0
    case .vos:
      settingsView.quizVosControl.selectedSegmentIndex = 1
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

  @objc func quizVosChanged(_ sender: UISegmentedControl) {
    let index = settingsView.quizVosControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setSecondSingularQuiz(.tu)
    }
    else if index == 1 {
      SettingsManager.setSecondSingularQuiz(.vos)
    }
  }

  @objc func browseVosChanged(_ sender: UISegmentedControl) {
    let index = settingsView.browseVosControl.selectedSegmentIndex
    if index == 0 {
      SettingsManager.setSecondSingularBrowse(.tu)
    }
    else if index == 1 {
      SettingsManager.setSecondSingularBrowse(.vos)
    }
    else if index == 2 {
      SettingsManager.setSecondSingularBrowse(.both)
    }
  }

  @objc func authenticate(sender: UIButton!) {
    SettingsManager.setUserRejectedGameCenter(false)
    GameCenterManager.shared.authenticate { authenticated in
      DispatchQueue.main.async {
        [self.settingsView.gameCenterLabel, self.settingsView.gameCenterDescription, self.settingsView.gameCenterButton].forEach {
          $0.isHidden = authenticated
        }
      }
    }
  }
}

