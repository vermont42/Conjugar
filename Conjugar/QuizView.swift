//
//  QuizView.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/3/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class QuizView: UIView {
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
    [(verbLabel, "Verb:"), (pronounLabel, "Pronoun:"), (tenseLabel, QuizView.tenseString), (lastLabel, "Last Answer:"), (correctLabel, "Correct Answer:"), (scoreLabel, "Score:"), (progressLabel, "Progress:"), (elapsedLabel, "Elapsed:"), (last, " "), (correct, " ")].forEach {
      $0.0.text = $0.1
    }
    [verb, verbLabel, translation, pronoun, pronounLabel, tenseLabel, last, lastLabel, correct, correctLabel, score, scoreLabel, progress, progressLabel, elapsed, elapsedLabel, startRestartButton, conjugationField].forEach {
      $0.enableAutoLayout()
      addSubview($0)
    }

    verbLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).activate()
    verbLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    verb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).activate()
    verb.leadingAnchor.constraint(equalTo: verbLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).activate()
    translation.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    pronounLabel.topAnchor.constraint(equalTo: verbLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    pronounLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    pronoun.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: Layout.defaultSpacing).activate()
    pronoun.leadingAnchor.constraint(equalTo: pronounLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    tenseLabel.topAnchor.constraint(equalTo: pronounLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    tenseLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    tenseLabel.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    tenseLabel.adjustsFontSizeToFitWidth = true
    let minimumScaleFactor: CGFloat = 0.5
    tenseLabel.minimumScaleFactor = minimumScaleFactor

    scoreLabel.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    scoreLabel.trailingAnchor.constraint(equalTo: score.leadingAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    score.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    score.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    progressLabel.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    progressLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    progress.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    progress.leadingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    elapsedLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    elapsedLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    elapsed.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: Layout.defaultSpacing).activate()
    elapsed.leadingAnchor.constraint(equalTo: elapsedLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    lastLabel.topAnchor.constraint(equalTo: elapsedLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    lastLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    last.topAnchor.constraint(equalTo: elapsed.bottomAnchor, constant: Layout.defaultSpacing).activate()
    last.leadingAnchor.constraint(equalTo: lastLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    correctLabel.topAnchor.constraint(equalTo: lastLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    correctLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    correct.topAnchor.constraint(equalTo: last.bottomAnchor, constant: Layout.defaultSpacing).activate()
    correct.leadingAnchor.constraint(equalTo: correctLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    conjugationField.topAnchor.constraint(equalTo: correctLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    conjugationField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    conjugationField.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    startRestartButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: Layout.defaultSpacing).activate()
    startRestartButton.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
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
