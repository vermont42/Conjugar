//
//  SettingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class SettingsView: UIView {
  private let regionLabel: UILabel = {
    let label = UILabel()
    label.text = "Region"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Difficulty"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  internal let gameCenterLabel: UILabel = {
    let label = UILabel()
    label.text = "Game Center"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()

  
  private let regionDescription: UILabel = {
    let label = UILabel()
    label.text = "In Latin American mode, quizzes do not include vosotros conjugations. This setting also determines how Conjugar pronounces conjugations."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  private let difficultyDescription: UILabel = {
    let label = UILabel()
    label.text = "Moderate-mode quizzes test more tenses than easy-mode quizzes. Difficult-mode quizzes test more tenses than moderate-mode quizzes."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  internal let gameCenterDescription: UILabel = {
    let label = UILabel()
    label.text = "Conjugar can send future quiz scores to Game Center so that you can see them in the global leaderboard. Tap Enable to enable this."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  internal let regionControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Spain", "Latin America"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.translatesAutoresizingMaskIntoConstraints = false
    control.tintColor = Colors.red
    return control
  } ()
  
  internal let difficultyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Easy", "Moderate", "Difficult"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.translatesAutoresizingMaskIntoConstraints = false
    control.tintColor = Colors.red
    return control
  } ()
  
  internal let gameCenterButton: UIButton = {
    let button = UIButton()
    button.setTitle("Enable", for: .normal)
    button.titleLabel?.font = Fonts.button
    button.setTitleColor(Colors.red, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    _ = [regionLabel, difficultyLabel, gameCenterLabel, regionDescription, difficultyDescription, gameCenterDescription, regionControl, difficultyControl, gameCenterButton].map {
      addSubview($0)
    }
    
    if #available(iOS 11.0, *) {
      regionLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      regionLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    regionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    regionControl.topAnchor.constraint(equalTo: regionLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    regionControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    regionControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    regionDescription.topAnchor.constraint(equalTo: regionControl.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    regionDescription.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    regionDescription.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    difficultyLabel.topAnchor.constraint(equalTo: regionDescription.bottomAnchor, constant: Layout.doubleDefaultSpacing).isActive = true
    difficultyLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    
    difficultyControl.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    difficultyControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    difficultyControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    difficultyDescription.topAnchor.constraint(equalTo: difficultyControl.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    difficultyDescription.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    difficultyDescription.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    gameCenterLabel.topAnchor.constraint(equalTo: difficultyDescription.bottomAnchor, constant: Layout.doubleDefaultSpacing).isActive = true
    gameCenterLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    gameCenterButton.topAnchor.constraint(equalTo: gameCenterLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    gameCenterButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    gameCenterDescription.topAnchor.constraint(equalTo: gameCenterButton.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    gameCenterDescription.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    gameCenterDescription.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
  }
}
