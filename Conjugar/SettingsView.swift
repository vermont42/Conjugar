//
//  SettingsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class SettingsView: UIView {
  internal let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.enableAutoLayout()
    scrollView.isUserInteractionEnabled = true
    return scrollView
  }()

  private let regionLabel: UILabel = {
    let label = UILabel()
    label.text = "Region"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let regionControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Spain", "Latin America"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.enableAutoLayout()
    control.tintColor = Colors.red
    return control
  }()

  private let regionDescription: UILabel = {
    let label = UILabel()
    label.text = "In Latin American mode, quizzes do not include vosotros conjugations. This setting also determines how Conjugar pronounces conjugations."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Difficulty"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let difficultyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Easy", "Moderate", "Difficult"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.enableAutoLayout()
    control.tintColor = Colors.red
    return control
  }()

  private let difficultyDescription: UILabel = {
    let label = UILabel()
    label.text = "Moderate-mode quizzes test more tenses than easy-mode quizzes. Difficult-mode quizzes test more tenses than moderate-mode quizzes."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  private let browseVosLabel: UILabel = {
    let label = UILabel()
    label.text = "Browse Tú and/or Vos"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let browseVosControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Tú", "Vos", "Both"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.enableAutoLayout()
    control.tintColor = Colors.red
    return control
  }()

  private let browseVosDescription: UILabel = {
    let label = UILabel()
    label.text = "This setting determines whether you see tú conjugations, vos conjugations, or both when you browse verb conjugations."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  private let quizVosLabel: UILabel = {
    let label = UILabel()
    label.text = "Quiz Tú or Vos"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let quizVosControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Tú", "Vos"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.enableAutoLayout()
    control.tintColor = Colors.red
    return control
  }()

  private let quizVosDescription: UILabel = {
    let label = UILabel()
    label.text = "This setting determines whether Conjugar's quiz mode quizzes you on tú forms or vos forms of verbs."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let gameCenterLabel: UILabel = {
    let label = UILabel()
    label.text = "Game Center"
    label.font = Fonts.label
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  internal let gameCenterButton: UIButton = {
    let button = UIButton()
    button.setTitle("Enable", for: .normal)
    button.titleLabel?.font = Fonts.button
    button.setTitleColor(Colors.red, for: .normal)
    button.enableAutoLayout()
    return button
  }()

  internal let gameCenterDescription: UILabel = {
    let label = UILabel()
    label.text = "Conjugar can send future quiz scores to Game Center so that you can see them in the global leaderboard. Tap Enable to enable this."
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(scrollView)
    [regionLabel, difficultyLabel, gameCenterLabel, browseVosLabel, quizVosLabel, regionDescription, difficultyDescription, gameCenterDescription, browseVosDescription, quizVosDescription, regionControl, difficultyControl, browseVosControl, quizVosControl, gameCenterButton].forEach {
      scrollView.addSubview($0)
    }

    scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).activate()
    scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).activate()
    scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).activate()
    scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).activate()

    regionLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Layout.defaultSpacing).activate()
    regionLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    regionControl.topAnchor.constraint(equalTo: regionLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    regionControl.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    regionControl.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    regionDescription.topAnchor.constraint(equalTo: regionControl.bottomAnchor, constant: Layout.defaultSpacing).activate()
    regionDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    regionDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    difficultyLabel.topAnchor.constraint(equalTo: regionDescription.bottomAnchor, constant: Layout.tripleDefaultSpacing).activate()
    difficultyLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    difficultyControl.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    difficultyControl.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    difficultyControl.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    difficultyDescription.topAnchor.constraint(equalTo: difficultyControl.bottomAnchor, constant: Layout.defaultSpacing).activate()
    difficultyDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    difficultyDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    browseVosLabel.topAnchor.constraint(equalTo: difficultyDescription.bottomAnchor, constant: Layout.tripleDefaultSpacing).activate()
    browseVosLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    browseVosControl.topAnchor.constraint(equalTo: browseVosLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    browseVosControl.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    browseVosControl.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    browseVosDescription.topAnchor.constraint(equalTo: browseVosControl.bottomAnchor, constant: Layout.defaultSpacing).activate()
    browseVosDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    browseVosDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    quizVosLabel.topAnchor.constraint(equalTo: browseVosDescription.bottomAnchor, constant: Layout.tripleDefaultSpacing).activate()
    quizVosLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    quizVosControl.topAnchor.constraint(equalTo: quizVosLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    quizVosControl.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    quizVosControl.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    quizVosDescription.topAnchor.constraint(equalTo: quizVosControl.bottomAnchor, constant: Layout.defaultSpacing).activate()
    quizVosDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    quizVosDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    gameCenterLabel.topAnchor.constraint(equalTo: quizVosDescription.bottomAnchor, constant: Layout.tripleDefaultSpacing).activate()
    gameCenterLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    gameCenterButton.topAnchor.constraint(equalTo: gameCenterLabel.bottomAnchor).activate()
    gameCenterButton.centerXAnchor.constraint(equalTo: centerXAnchor).activate()

    gameCenterDescription.topAnchor.constraint(equalTo: gameCenterButton.bottomAnchor).activate()
    gameCenterDescription.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Layout.defaultSpacing).activate()
    gameCenterDescription.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    gameCenterDescription.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: Layout.defaultSpacing * -1.0).activate()
  }
}
