//
//  QuizVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class QuizVC: UIViewController, UITextFieldDelegate, QuizDelegate {
  var quizView: QuizView {
    return view as! QuizView
  }
  
  override func loadView() {
    let quizView: QuizView
    quizView = QuizView(frame: UIScreen.main.bounds)
    quizView.startRestartButton.addTarget(self, action: #selector(startRestart), for: .touchUpInside)
    navigationItem.titleView = UILabel.titleLabel(title: "Quiz")
    quizView.conjugationField.delegate = self
    view = quizView
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    Quiz.shared.delegate = self
    switch Quiz.shared.quizState {
    case .notStarted , .finished:
      quizView.hideInProgressUI()
      quizView.startRestartButton.setTitle("Start", for: .normal)
    case .inProgress:
      quizView.showInProgressUI()
      quizView.startRestartButton.setTitle("Restart", for: .normal)
      let verb = Quiz.shared.verb
      quizView.verb.text = verb
      let translationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
      switch translationResult {
      case let .success(value):
        quizView.translation.text = value
      default:
        fatalError()
      }
      quizView.tense.text = Quiz.shared.tense.displayName
      quizView.pronoun.text = Quiz.shared.currentPersonNumber.pronoun
      quizView.score.text = String(Quiz.shared.score)
      quizView.progress.text = String(Quiz.shared.currentQuestionIndex + 1) + " / " + String(Quiz.shared.questionCount)
    }
    quizView.startRestartButton.pulsate()
    authenticate()
  }
  
  private func authenticate() {
    if !GameCenterManager.shared.isAuthenticated && !SettingsManager.getUserRejectedGameCenter() {
      if !SettingsManager.getDidShowGameCenterDialog() {
        showGameCenterDialog()
      }
      else {
        GameCenterManager.shared.authenticate()
      }
    }
  }
  
  private func showGameCenterDialog() {
    SettingsManager.setDidShowGameCenterDialog(true)
    let gameCenterController = UIAlertController(title: "Game Center", message: "Would you like Conjugar to upload your future scores to Game Center after your quiz? See how you stack up against the global community of conjugators.", preferredStyle: UIAlertControllerStyle.alert)
    let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.destructive) { (action) in
      SoundManager.play(.sadTrombone)
      SettingsManager.setUserRejectedGameCenter(true)
    }
    gameCenterController.addAction(noAction)
    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (action) in
      GameCenterManager.shared.authenticate()
    }
    gameCenterController.addAction(yesAction)
    present(gameCenterController, animated: true, completion: nil)
  }

  @objc func startRestart(sender: UIButton!) {
    SoundManager.play(.gun)
    Quiz.shared.start()
    quizView.startRestartButton.setTitle("Restart", for: .normal)
    [quizView.lastLabel, quizView.correctLabel, quizView.last, quizView.correct].forEach {
      $0.isHidden = true
    }
    quizView.showInProgressUI()
    quizView.startRestartButton.pulsate()
    quizView.conjugationField.becomeFirstResponder()
  }

  func scoreDidChange(newScore: Int) {
    quizView.score.text = String(newScore)
  }

  func timeDidChange(newTime: Int) {
    quizView.elapsed.text = newTime.timeString
  }

  func progressDidChange(current: Int, total: Int) {
    quizView.progress.text = String(current + 1) + " / " + String(total)
  }

  func questionDidChange(verb: String, tense: Tense, personNumber: PersonNumber) {
    quizView.verb.text = verb
    let translationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
    switch translationResult {
    case let .success(value):
      quizView.translation.text = value
    default:
      fatalError()
    }
    quizView.tense.text = tense.displayName
    quizView.pronoun.text = personNumber.pronoun
    quizView.conjugationField.becomeFirstResponder()
  }

  func quizDidFinish() {
    quizView.hideInProgressUI()
    quizView.startRestartButton.setTitle("Start", for: .normal)
    let randomApplause = arc4random_uniform(Sound.applauseCount) + 1
    switch randomApplause {
    case 1:
      SoundManager.play(.applause1)
    case 2:
      SoundManager.play(.applause2)
    case 3:
      SoundManager.play(.applause3)
    default:
      break
    }
    let resultsVC = ResultsVC()
    navigationController?.pushViewController(resultsVC, animated: true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = quizView.conjugationField.text else { return false }
    guard text != "" else { return false }
    quizView.conjugationField.resignFirstResponder()
    let (result, correctConjugation) = Quiz.shared.process(proposedAnswer: text)
    quizView.conjugationField.text = nil
    switch result {
    case .totalMatch:
      SoundManager.play(.chime)
    case .partialMatch:
      SoundManager.play(.chirp)
    case .noMatch:
      SoundManager.play(.buzz)
    }
    if let correctConjugation = correctConjugation, Quiz.shared.quizState == .inProgress {
      [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
        $0.isHidden = false
      }
      quizView.last.attributedText = text.coloredString(color: Colors.blue)
      quizView.correct.attributedText = correctConjugation.conjugatedString
    }
    else {
      [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
        $0.isHidden = true
      }
    }
    return true
  }
}

