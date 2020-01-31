//
//  QuizUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/3/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class QuizUIV: UIView {
  static let tenseString = "Tense:"
  let lastLabel = UILabel()
  let correctLabel = UILabel()
  let elapsed = UILabel()
  let verb = UILabel()
  let translation = UILabel()
  let pronoun = UILabel()
  let last = UILabel()
  let correct = UILabel()
  let score = UILabel()
  let progress = UILabel()
  let tenseLabel = UILabel()
  private let verbLabel = UILabel()
  private let pronounLabel = UILabel()
  private let scoreLabel = UILabel()
  private let progressLabel = UILabel()
  private let elapsedLabel = UILabel()

  let conjugationField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.placeholder = " conjugation"
    return field
  }()

  let startRestartButton: UIButton = {
    let button = UIButton()
    button.setTitle("Start", for: .normal)
    button.titleLabel?.font = Fonts.button
    button.setTitleColor(Colors.red, for: .normal)
    return button
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [verb, verbLabel, translation, pronoun, pronounLabel, tenseLabel, last, lastLabel, correct, correctLabel, score, scoreLabel, progress, progressLabel, elapsed, elapsedLabel].forEach {
      $0.textColor = Colors.yellow
      $0.font = Fonts.label
    }
    [verb, translation, pronoun].forEach {
      $0.isUserInteractionEnabled = true
    }
    [(verbLabel, "Verb:"), (pronounLabel, "Pronoun:"), (tenseLabel, QuizUIV.tenseString), (lastLabel, "Last Answer:"), (correctLabel, "Correct Answer:"), (scoreLabel, "Score:"), (progressLabel, "Progress:"), (elapsedLabel, "Elapsed:"), (last, " "), (correct, " ")].forEach {
      $0.0.text = $0.1
    }
    [verb, verbLabel, translation, pronoun, pronounLabel, tenseLabel, last, lastLabel, correct, correctLabel, score, scoreLabel, progress, progressLabel, elapsed, elapsedLabel, startRestartButton, conjugationField].forEach {
      $0.enableAutoLayout()
      addSubview($0)
    }

    tenseLabel.adjustsFontSizeToFitWidth = true
    let minimumScaleFactor: CGFloat = 0.5
    tenseLabel.minimumScaleFactor = minimumScaleFactor

    NSLayoutConstraint.activate([
      verbLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      verbLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      verb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      verb.leadingAnchor.constraint(equalTo: verbLabel.trailingAnchor, constant: Layout.defaultSpacing),

      translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      translation.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      pronounLabel.topAnchor.constraint(equalTo: verbLabel.bottomAnchor, constant: Layout.defaultSpacing),
      pronounLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      pronoun.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: Layout.defaultSpacing),
      pronoun.leadingAnchor.constraint(equalTo: pronounLabel.trailingAnchor, constant: Layout.defaultSpacing),

      tenseLabel.topAnchor.constraint(equalTo: pronounLabel.bottomAnchor, constant: Layout.defaultSpacing),
      tenseLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      tenseLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      scoreLabel.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing),
      scoreLabel.trailingAnchor.constraint(equalTo: score.leadingAnchor, constant: Layout.defaultSpacing * -1.0),

      score.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing),
      score.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      progressLabel.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing),
      progressLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      progress.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing),
      progress.leadingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: Layout.defaultSpacing),

      elapsedLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: Layout.defaultSpacing),
      elapsedLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      elapsed.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: Layout.defaultSpacing),
      elapsed.leadingAnchor.constraint(equalTo: elapsedLabel.trailingAnchor, constant: Layout.defaultSpacing),

      lastLabel.topAnchor.constraint(equalTo: elapsedLabel.bottomAnchor, constant: Layout.defaultSpacing),
      lastLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      last.topAnchor.constraint(equalTo: elapsed.bottomAnchor, constant: Layout.defaultSpacing),
      last.leadingAnchor.constraint(equalTo: lastLabel.trailingAnchor, constant: Layout.defaultSpacing),

      correctLabel.topAnchor.constraint(equalTo: lastLabel.bottomAnchor, constant: Layout.defaultSpacing),
      correctLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      correct.topAnchor.constraint(equalTo: last.bottomAnchor, constant: Layout.defaultSpacing),
      correct.leadingAnchor.constraint(equalTo: correctLabel.trailingAnchor, constant: Layout.defaultSpacing),

      conjugationField.topAnchor.constraint(equalTo: correctLabel.bottomAnchor, constant: Layout.defaultSpacing),
      conjugationField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      conjugationField.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      startRestartButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: Layout.defaultSpacing),
      startRestartButton.centerXAnchor.constraint(equalTo: centerXAnchor)
    ])
  }

  func hideInProgressUI() {
    [verbLabel, verb, translation, pronounLabel, pronoun, tenseLabel, lastLabel, last, correctLabel, correct, scoreLabel, score, progressLabel, progress, elapsedLabel, elapsed, conjugationField].forEach {
      $0.isHidden = true
    }
  }

  func showInProgressUI() {
    [verbLabel, verb, translation, pronounLabel, pronoun, tenseLabel, scoreLabel, score, progressLabel, progress, elapsedLabel, elapsed, conjugationField].forEach {
      $0.isHidden = false
    }
  }
}
