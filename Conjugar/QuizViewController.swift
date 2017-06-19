//
//  QuizViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class QuizViewController: UIViewController, UITextFieldDelegate, QuizDelegate {
  @IBOutlet var verbLabelLabel: UILabel!
  @IBOutlet var verbLabel: UILabel!
  @IBOutlet var translationLabel: UILabel!
  @IBOutlet var pronounLabelLabel: UILabel!
  @IBOutlet var pronounLabel: UILabel!
  @IBOutlet var tenseLabelLabel: UILabel!
  @IBOutlet var tenseLabel: UILabel!
  @IBOutlet var scoreLabelLabel: UILabel!
  @IBOutlet var scoreLabel: UILabel!
  @IBOutlet var progressLabelLabel: UILabel!
  @IBOutlet var progressLabel: UILabel!
  @IBOutlet var elapsedLabelLabel: UILabel!
  @IBOutlet var elapsedLabel: UILabel!
  @IBOutlet var conjugationField: UITextField!
  @IBOutlet var startRestartButton: UIButton!
  
  override func viewDidLoad() {
    conjugationField.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    Quiz.shared.delegate = self
    switch Quiz.shared.quizState {
    case .notStarted:
      hideInProgressUI()
      startRestartButton.setTitle("Start", for: .normal)
    case .inProgress:
      showInProgressUI()
      startRestartButton.setTitle("Restart", for: .normal)
      let verb = Quiz.shared.verb
      verbLabel.text = verb
      let translationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
      switch translationResult {
      case let .success(value):
        translationLabel.text = value
      default:
        fatalError()
      }
      tenseLabel.text = Quiz.shared.tense.displayName
      pronounLabel.text = Quiz.shared.personNumber.pronoun
      scoreLabel.text = String(Quiz.shared.score)
      progressLabel.text = String(Quiz.shared.currentQuestionIndex + 1) + " / " + String(Quiz.shared.questionCount)
    case .finished:
      hideInProgressUI()
      startRestartButton.setTitle("Start", for: .normal)
    }
  }
  
  private func hideInProgressUI() {
    _ = [verbLabelLabel, verbLabel, translationLabel, pronounLabelLabel, pronounLabel, tenseLabelLabel, tenseLabel, scoreLabelLabel, scoreLabel, progressLabelLabel, progressLabel, elapsedLabelLabel, elapsedLabel, conjugationField].map {
      $0.isHidden = true
    }
  }
  
  private func showInProgressUI() {
    _ = [verbLabelLabel, verbLabel, translationLabel, pronounLabelLabel, pronounLabel, tenseLabelLabel, tenseLabel, scoreLabelLabel, scoreLabel, progressLabelLabel, progressLabel, elapsedLabelLabel, elapsedLabel, conjugationField].map {
      $0.isHidden = false
    }
  }
  
  @IBAction func startRestart() {
    Quiz.shared.start()
    startRestartButton.setTitle("Restart", for: .normal)
    showInProgressUI()
  }
  
  func scoreDidChange(newScore: Int) {
    scoreLabel.text = String(newScore)
  }
  
  func timeDidChange(newTime: Int) {
    elapsedLabel.text = String(newTime)
  }
  
  func progressDidChange(current: Int, total: Int) {
    progressLabel.text = String(current + 1) + " / " + String(total)
  }
  
  func questionDidChange(verb: String, tense: Tense, personNumber: PersonNumber) {
    verbLabel.text = verb
    let translationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
    switch translationResult {
    case let .success(value):
      translationLabel.text = value
    default:
      fatalError()
    }
    tenseLabel.text = tense.displayName
    pronounLabel.text = personNumber.pronoun
  }
  
  func quizDidFinish() {
    hideInProgressUI()
    startRestartButton.setTitle("Start", for: .normal)
    UIAlertController.showMessage("You scored \(Quiz.shared.score) points.", title: "Results")
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = conjugationField.text else { return false }
    guard text != "" else { return false }
    let isCorrect = Quiz.shared.process(proposedAnswer: text)
    conjugationField.text = nil
    conjugationField.resignFirstResponder()
    if isCorrect {
      SoundManager.play(.successChime)
    }
    else {
      SoundManager.play(.failBuzzer)
    }
    return true
  }
}
