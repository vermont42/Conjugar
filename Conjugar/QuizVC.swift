//
//  QuizVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class QuizVC: UIViewController, UITextFieldDelegate, QuizDelegate {
  private var settings: Settings?
  private var quiz: Quiz?
  private var analyticsService: AnalyticsService?
  private var gameCenterManager: GameCenterManageable?

  var quizView: QuizView {
    if let castedView = view as? QuizView {
      return castedView
    } else {
      fatalError(fatalCastMessage(viewController: QuizVC.self, view: QuizView.self))
    }
  }

  convenience init(settings: Settings, quiz: Quiz, analyticsService: AnalyticsService, gameCenterManager: GameCenterManageable) {
    self.init()
    self.settings = settings
    self.quiz = quiz
    self.analyticsService = analyticsService
    self.gameCenterManager = gameCenterManager
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
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    quiz.delegate = self
    switch quiz.quizState {
    case .notStarted, .finished:
      quizView.hideInProgressUI()
      quizView.startRestartButton.setTitle("Start", for: .normal)
    case .inProgress:
      quizView.showInProgressUI()
      quizView.startRestartButton.setTitle("Restart", for: .normal)
      let verb = quiz.verb
      quizView.verb.text = verb
      let translationResult = Conjugator.shared.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
      switch translationResult {
      case let .success(value):
        quizView.translation.text = value
      default:
        fatalError("translation not found.")
      }
      quizView.tense.text = quiz.tense.displayName
      quizView.pronoun.text = quiz.currentPersonNumber.pronoun
      quizView.score.text = String(quiz.score)
      quizView.progress.text = String(quiz.currentQuestionIndex + 1) + " / " + String(quiz.questionCount)
    }
    quizView.startRestartButton.pulsate()
    authenticate()
    analyticsService?.recordVisitation(viewController: "\(QuizVC.self)")
  }

  private func authenticate() {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    guard let analyticsService = analyticsService else {
      fatalError("analyticsService was nil.")
    }
    guard let gameCenterManager = gameCenterManager else {
      fatalError("gameCenterManager was nil.")
    }
    if !gameCenterManager.isAuthenticated && settings.userRejectedGameCenter {
      if !settings.didShowGameCenterDialog {
        showGameCenterDialog()
      } else {
        gameCenterManager.authenticate(analyticsService: analyticsService, completion: nil)
      }
    }
  }

  private func showGameCenterDialog() {
    guard let settings = settings else {
      fatalError("settings was nil.")
    }
    guard let analyticsService = analyticsService else {
      fatalError("analyticsService was nil.")
    }
    guard let gameCenterManager = gameCenterManager else {
      fatalError("gameCenterManager was nil.")
    }
    settings.didShowGameCenterDialog = true
    let gameCenterController = UIAlertController(title: "Game Center", message: "Would you like Conjugar to upload your future scores to Game Center after your quiz? See how you stack up against the global community of conjugators.", preferredStyle: UIAlertControllerStyle.alert)
    let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.destructive) { action in
      SoundManager.play(.sadTrombone)
      settings.userRejectedGameCenter = true
    }
    gameCenterController.addAction(noAction)
    let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { action in
      gameCenterManager.authenticate(analyticsService: analyticsService, completion: nil)
    }
    gameCenterController.addAction(yesAction)
    present(gameCenterController, animated: true, completion: nil)
  }

  @objc func startRestart() {
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    SoundManager.play(.gun)
    quiz.start()
    quizView.startRestartButton.setTitle("Restart", for: .normal)
    [quizView.lastLabel, quizView.correctLabel, quizView.last, quizView.correct].forEach {
      $0.isHidden = true
    }
    quizView.showInProgressUI()
    quizView.startRestartButton.pulsate()
    quizView.conjugationField.becomeFirstResponder()
    analyticsService?.recordQuizStart()
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
    quizView.tense.text = tense.displayName
    quizView.pronoun.text = personNumber.pronoun
    quizView.conjugationField.becomeFirstResponder()
  }

  func quizDidFinish() {
    guard let analyticsService = analyticsService else {
      fatalError("analyticsService was nil.")
    }
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    quizView.hideInProgressUI()
    quizView.startRestartButton.setTitle("Start", for: .normal)
    let applauseIndex = Int.random(in: 1...Sound.applauseCount)
    switch applauseIndex {
    case 1:
      SoundManager.play(.applause1)
    case 2:
      SoundManager.play(.applause2)
    case 3:
      SoundManager.play(.applause3)
    default:
      break
    }
    let resultsVC = ResultsVC(quiz: quiz, analyticsService: analyticsService)
    navigationController?.pushViewController(resultsVC, animated: true)
    analyticsService.recordQuizCompletion(score: quiz.score)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    guard let text = quizView.conjugationField.text else { return false }
    guard text != "" else { return false }
    quizView.conjugationField.resignFirstResponder()
    let (result, correctConjugation) = quiz.process(proposedAnswer: text)
    quizView.conjugationField.text = nil
    switch result {
    case .totalMatch:
      SoundManager.play(.chime)
    case .partialMatch:
      SoundManager.play(.chirp)
    case .noMatch:
      SoundManager.play(.buzz)
    }
    if let correctConjugation = correctConjugation, quiz.quizState == .inProgress {
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
