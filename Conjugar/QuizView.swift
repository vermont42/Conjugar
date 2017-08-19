//
//  QuizView.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/3/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class QuizView: UIView {
  private let verbLabel: UILabel = { return UILabel() } ()
  private let pronounLabel: UILabel = { return UILabel() } ()
  private let tenseLabel: UILabel = { return UILabel() } ()
  private let scoreLabel: UILabel = { return UILabel() } ()
  private let progressLabel: UILabel = { return UILabel() } ()
  private let elapsedLabel: UILabel = { return UILabel() } ()
  internal let lastLabel: UILabel = { return UILabel() } ()
  internal let correctLabel: UILabel = { return UILabel() } ()
  internal let elapsed: UILabel = { return UILabel() } ()
  internal let verb: UILabel = { return UILabel() } ()
  internal let translation: UILabel = { return UILabel() } ()
  internal let pronoun: UILabel = { return UILabel() } ()
  internal let tense: UILabel = { return UILabel() } ()
  internal let last: UILabel = { return UILabel() } ()
  internal let correct: UILabel = { return UILabel() } ()
  internal let score: UILabel = { return UILabel() } ()
  internal let progress: UILabel = { return UILabel() } ()
  
  internal let conjugationField: UITextField = {
    let field = UITextField()
    field.autocapitalizationType = .none
    field.autocorrectionType = .no
    field.placeholder = "conjugation"
    field.backgroundColor = UIColor.white
    return field
  } ()
  
  internal let startRestartButton: UIButton = {
    let button = UIButton()
    button.setTitle("Start", for: .normal)
    button.titleLabel?.font = Fonts.button
    button.setTitleColor(Colors.red, for: .normal)
    return button
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    _ = [verb, verbLabel, translation, pronoun, pronounLabel, tense, tenseLabel, last, lastLabel, correct, correctLabel, score, scoreLabel, progress, progressLabel, elapsed, elapsedLabel].map {
      $0.textColor = Colors.yellow
      $0.font = Fonts.label
    }
    _ = [verb, translation, pronoun, tense].map {
      $0.isUserInteractionEnabled = true
    }
    _ = [(verbLabel, "Verb:"), (pronounLabel, "Pronoun:"), (tenseLabel, "Tense:"), (lastLabel, "Last Answer:"), (correctLabel, "Correct Answer:"), (scoreLabel, "Score:"), (progressLabel, "Progress:"), (elapsedLabel, "Elapsed:"), (last, " "), (correct, " ")].map {
      $0.0.text = $0.1
    }
    _ = [verb, verbLabel, translation, pronoun, pronounLabel, tense, tenseLabel, last, lastLabel, correct, correctLabel, score, scoreLabel, progress, progressLabel, elapsed, elapsedLabel, startRestartButton, conjugationField].map {
      guard let view = $0 as? UIView else { fatalError("Could not cast UIView to UIView.") }
      view.translatesAutoresizingMaskIntoConstraints = false
      addSubview(view)
    }
    
    if #available(iOS 11.0, *) {
      verbLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      verbLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    verbLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      verb.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      verb.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    verb.leadingAnchor.constraint(equalTo: verbLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    if #available(iOS 11.0, *) {
      translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      translation.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    translation.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    pronounLabel.topAnchor.constraint(equalTo: verbLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    pronounLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    pronoun.topAnchor.constraint(equalTo: verb.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    pronoun.leadingAnchor.constraint(equalTo: pronounLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    tenseLabel.topAnchor.constraint(equalTo: pronounLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    tenseLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    tense.topAnchor.constraint(equalTo: pronoun.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    tense.leadingAnchor.constraint(equalTo: tenseLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    scoreLabel.topAnchor.constraint(equalTo: tenseLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    scoreLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    score.topAnchor.constraint(equalTo: tense.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    score.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    progressLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    progressLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    progress.topAnchor.constraint(equalTo: score.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    progress.leadingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    elapsedLabel.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    elapsedLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    elapsed.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    elapsed.leadingAnchor.constraint(equalTo: elapsedLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    lastLabel.topAnchor.constraint(equalTo: elapsedLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    lastLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    last.topAnchor.constraint(equalTo: elapsed.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    last.leadingAnchor.constraint(equalTo: lastLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    correctLabel.topAnchor.constraint(equalTo: lastLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    correctLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    correct.topAnchor.constraint(equalTo: last.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    correct.leadingAnchor.constraint(equalTo: correctLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true

    conjugationField.topAnchor.constraint(equalTo: correctLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    conjugationField.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    conjugationField.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      startRestartButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      startRestartButton.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).isActive = true
    }
    startRestartButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
  }
  
  internal func hideInProgressUI() {
    _ = [verbLabel, verb, translation, pronounLabel, pronoun, tenseLabel, tense, lastLabel, last, correctLabel, correct, scoreLabel, score, progressLabel, progress, elapsedLabel, elapsed, conjugationField].map {
      $0.isHidden = true
    }
  }
  
  internal func showInProgressUI() {
    _ = [verbLabel, verb, translation, pronounLabel, pronoun, tenseLabel, tense, scoreLabel, score, progressLabel, progress, elapsedLabel, elapsed, conjugationField].map {
      $0.isHidden = false
    }
  }
}

