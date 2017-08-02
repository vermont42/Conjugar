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
  private var safeBottomInset: CGFloat = 0.0
  
  private let regionLabel: UILabel = {
    let label = UILabel()
    label.text = "Region"
    label.font = Fonts.subheading
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Difficulty"
    label.font = Fonts.subheading
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  private let regionDescription: UILabel = {
    let label = UILabel()
    label.text = "In Latin American mode, quizzes do not include vosotros conjugations. This setting determines how Conjugar pronounces conjugations."
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
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  private func commonInit() {
    _ = [regionLabel, difficultyLabel, regionDescription, difficultyDescription, regionControl, difficultyControl].map {
      addSubview($0)
    }
    let defaultSpacing: CGFloat = 8.0
    
    
    regionLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    regionLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    
    regionControl.topAnchor.constraint(equalTo: regionLabel.bottomAnchor, constant: defaultSpacing).isActive = true
    regionControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    regionControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    regionDescription.topAnchor.constraint(equalTo: regionControl.bottomAnchor, constant: defaultSpacing).isActive = true
    regionDescription.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    regionDescription.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    difficultyLabel.topAnchor.constraint(equalTo: regionDescription.bottomAnchor, constant: defaultSpacing).isActive = true
    difficultyLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    
    difficultyControl.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: defaultSpacing).isActive = true
    difficultyControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    difficultyControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    difficultyDescription.topAnchor.constraint(equalTo: difficultyControl.bottomAnchor, constant: defaultSpacing).isActive = true
    difficultyDescription.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    difficultyDescription.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
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
