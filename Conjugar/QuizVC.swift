//
//  QuizVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class QuizVC: UIViewController, UITextFieldDelegate, QuizDelegate {
  var quizView: QuizUIV {
    if let castedView = view as? QuizUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: QuizUIV.self))
    }
  }

  override func loadView() {
    let quizView: QuizUIV
    quizView = QuizUIV(frame: UIScreen.main.bounds)
    quizView.startRestartButton.addTarget(self, action: #selector(startRestart), for: .touchUpInside)
    navigationItem.titleView = UILabel.titleLabel(title: Localizations.Quiz.localizedTitle)
    quizView.conjugationField.delegate = self
    view = quizView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    Current.quiz.delegate = self
    switch Current.quiz.quizState {
    case .notStarted, .finished:
      quizView.hideInProgressUI()
      quizView.startRestartButton.setTitle("Start", for: .normal)
    case .inProgress:
      quizView.showInProgressUI()
      quizView.startRestartButton.setTitle("Restart", for: .normal)
      let verb = Current.quiz.verb
      quizView.verb.text = verb
      let translationResult = Conjugator.shared.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
      switch translationResult {
      case let .success(value):
        quizView.translation.text = value
      default:
        fatalError("translation not found.")
      }
      quizView.tenseLabel.text = Current.quiz.tense.displayName
      quizView.pronoun.text = Current.quiz.currentPersonNumber.pronoun
      quizView.score.text = String(Current.quiz.score)
      quizView.progress.text = String(Current.quiz.currentQuestionIndex + 1) + " / " + String(Current.quiz.questionCount)
    }
    quizView.startRestartButton.pulsate()
    authenticate()
    Current.analytics.recordVisitation(viewController: "\(QuizVC.self)")
  }

    private func authenticate() {
        if !Current.gameCenter.isAuthenticated && Current.settings.userRejectedGameCenter {
            if !Current.settings.didShowGameCenterDialog {
                showGameCenterDialog()
            } else {
              Current.gameCenter.authenticate(onViewController: self, completion: nil)
            }
        }
    }

  private func showGameCenterDialog() {
    Current.settings.didShowGameCenterDialog = true
    let gameCenterController = UIAlertController(title: "Game Center", message: "Would you like Conjugar to upload your future scores to Game Center after your quiz? See how you stack up against the global community of conjugators.", preferredStyle: UIAlertController.Style.alert)
    let noAction = UIAlertAction(title: "No", style: UIAlertAction.Style.destructive) { _ in
      SoundPlayer.play(.sadTrombone)
      Current.settings.userRejectedGameCenter = true
    }
    gameCenterController.addAction(noAction)
    let yesAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.default) { _ in
      Current.gameCenter.authenticate(onViewController: self, completion: nil)
    }
    gameCenterController.addAction(yesAction)
    present(gameCenterController, animated: true, completion: nil)
  }

  @objc func startRestart() {
    SoundPlayer.play(.gun)
    Current.quiz.start()
    quizView.startRestartButton.setTitle("Restart", for: .normal)
    [quizView.lastLabel, quizView.correctLabel, quizView.last, quizView.correct].forEach {
      $0.isHidden = true
    }
    quizView.showInProgressUI()
    quizView.startRestartButton.pulsate()
    quizView.conjugationField.becomeFirstResponder()
    Current.analytics.recordQuizStart()
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
    let translationResult = Conjugator.shared.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
    switch translationResult {
    case let .success(value):
      quizView.translation.text = value
    default:
      fatalError()
    }
    quizView.tenseLabel.text = QuizUIV.tenseString + " " + tense.displayName
    quizView.pronoun.text = personNumber.pronoun
    quizView.conjugationField.becomeFirstResponder()
  }

  func quizDidFinish() {
    quizView.hideInProgressUI()
    quizView.startRestartButton.setTitle("Start", for: .normal)
    let applauseIndex = Int.random(in: 1...Sound.applauseCount)
    switch applauseIndex {
    case 1:
      SoundPlayer.play(.applause1)
    case 2:
      SoundPlayer.play(.applause2)
    case 3:
      SoundPlayer.play(.applause3)
    default:
      break
    }
    let resultsVC = ResultsVC()
    navigationController?.pushViewController(resultsVC, animated: true)
    Current.analytics.recordQuizCompletion(score: Current.quiz.score)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = quizView.conjugationField.text else { return false }
    guard text != "" else { return false }
    quizView.conjugationField.resignFirstResponder()
    let (result, correctConjugation) = Current.quiz.process(proposedAnswer: text)
    quizView.conjugationField.text = nil
    switch result {
    case .totalMatch:
      SoundPlayer.play(.chime)
    case .partialMatch:
      SoundPlayer.play(.chirp)
    case .noMatch:
      SoundPlayer.play(.buzz)
    }
    if let correctConjugation = correctConjugation, Current.quiz.quizState == .inProgress {
      [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
        $0.isHidden = false
      }
      quizView.last.attributedText = text.coloredString(color: Colors.blue)
      quizView.correct.attributedText = correctConjugation.conjugatedString
    } else {
      [quizView.lastLabel, quizView.last, quizView.correctLabel, quizView.correct].forEach {
        $0.isHidden = true
      }
    }
    return true
  }
}
