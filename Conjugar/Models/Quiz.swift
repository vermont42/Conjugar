//
//  Quiz.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import Observation
import os
import TipKit

nonisolated private let quizLogger = Logger(subsystem: "com.racecondition.Conjugar", category: "Quiz")

/// A shuffle-on-start, wrap-around cursor over one verb list. `next()` advances
/// the index first, so the first call returns element 1 and element 0 is reached
/// only after a full wrap.
private final class Cycler {
  private var elements: [String]
  private var index = 0

  init(_ elements: [String]) {
    self.elements = elements
  }

  /// Return to the start of a (optionally reshuffled) list for a new quiz.
  func restart(shuffle: Bool) {
    if shuffle {
      elements.shuffle()
    }
    index = 0
  }

  func next() -> String {
    index += 1
    if index == elements.count {
      index = 0
    }
    return elements[index]
  }
}

@MainActor
@Observable
class Quiz {
  private(set) var quizState: QuizState = .notStarted
  private(set) var elapsedTime: Int = 0
  private(set) var score: Int = 0
  private(set) var currentQuestionIndex = 0
  private(set) var correctCount = 0
  private(set) var lastRegion: Region = .spain
  private(set) var lastDifficulty: Difficulty = .moderate
  private(set) var proposedAnswers: [String] = []
  private(set) var correctAnswers: [String] = []
  private(set) var questions: [(String, DisplayTense, DisplayPersonNumber)] = []
  private let regularAr = Cycler(VerbFamilies.regularArVerbs)
  private let regularIr = Cycler(VerbFamilies.regularIrVerbs)
  private let regularEr = Cycler(VerbFamilies.regularErVerbs)
  private let allRegular = Cycler(VerbFamilies.allRegularVerbs)
  private let irregularPresenteDeIndicativo = Cycler(VerbFamilies.irregularPresenteDeIndicativoVerbs)
  private let irregularPreterito = Cycler(VerbFamilies.irregularPreteritoVerbs)
  private let irregularRaizFutura = Cycler(VerbFamilies.irregularRaizFuturaVerbs)
  private let irregularParticipio = Cycler(VerbFamilies.irregularParticipioVerbs)
  private let irregularImperfecto = Cycler(VerbFamilies.irregularImperfectivoVerbs)
  private let irregularPresenteDeSubjuntivo = Cycler(VerbFamilies.irregularPresenteDeSubjuntivoVerbs)
  private let irregularGerundio = Cycler(VerbFamilies.irregularGerundioVerbs)
  private let irregularTuImperativo = Cycler(VerbFamilies.irregularTuImperativoVerbs)
  private let irregularVosImperativo = Cycler(VerbFamilies.irregularVosImperativoVerbs)
  private var allCyclers: [Cycler] {
    [
      regularAr, regularIr, regularEr, allRegular,
      irregularPresenteDeIndicativo, irregularPreterito, irregularRaizFutura,
      irregularParticipio, irregularImperfecto, irregularPresenteDeSubjuntivo,
      irregularGerundio, irregularTuImperativo, irregularVosImperativo
    ]
  }
  @ObservationIgnored private var timer: Timer?
  private let settings: Settings
  private let gameCenter: GameCenter
  private let personNumbersWithTu: [DisplayPersonNumber] = [.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
  private let personNumbersWithVos: [DisplayPersonNumber] = [.firstSingular, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
  private var personNumbersIndex = 0
  private var shouldShuffle = true

  var questionCount: Int {
    return questions.count
  }

  var verb: String {
    if questions.count > 0 {
      return questions[currentQuestionIndex].0
    } else {
      return ""
    }
  }

  var tense: DisplayTense {
    if questions.count > 0 {
      return questions[currentQuestionIndex].1
    } else {
      return .infinitivo
    }
  }

  var currentPersonNumber: DisplayPersonNumber {
    if questions.count > 0 {
      return questions[currentQuestionIndex].2
    } else {
      return .none
    }
  }

  init(settings: Settings, gameCenter: GameCenter, shouldShuffle: Bool = true) {
    self.settings = settings
    self.gameCenter = gameCenter
    self.shouldShuffle = shouldShuffle
  }

  func start() {
    lastRegion = settings.region
    lastDifficulty = settings.difficulty
    questions.removeAll()
    proposedAnswers.removeAll()
    correctAnswers.removeAll()

    #if DEBUG
    if Quiz.isScreenshotFixtureRun {
      startScreenshotFixture()
      return
    }
    #endif
    for cycler in allCyclers {
      cycler.restart(shuffle: shouldShuffle)
    }

    switch lastDifficulty {
    case .easy:
//      questions.append((allRegular.next(), .presenteDeIndicativo, personNumber())) // useful for testing
      [regularAr.next(), regularAr.next(), regularAr.next(), regularIr.next(), regularIr.next(), regularIr.next(), regularEr.next(), regularEr.next(), regularEr.next()].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...8 {
        questions.append((irregularPresenteDeIndicativo.next(), .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...7 {
        questions.append((irregularRaizFutura.next(), .futuroDeIndicativo, personNumber()))
      }
      [regularAr.next(), regularAr.next(), regularAr.next(), regularIr.next(), regularIr.next(), regularEr.next(), regularEr.next()].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...7 {
        questions.append((irregularPreterito.next(), .pretérito, personNumber()))
      }
      for _ in 0...8 {
        questions.append((allRegular.next(), .pretérito, personNumber()))
      }
    case .moderate:
      [regularAr.next(), regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...3 {
        questions.append((irregularPresenteDeIndicativo.next(), .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularRaizFutura.next(), .futuroDeIndicativo, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularRaizFutura.next(), .condicional, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .condicional, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularParticipio.next(), .perfectoDeIndicativo, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .perfectoDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularImperfecto.next(), .imperfectoDeIndicativo, personNumber()))
      }
      [allRegular.next(), allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .imperfectoDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPreterito.next(), .pretérito, personNumber()))
      }
      [regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .pretérito, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPresenteDeSubjuntivo.next(), .presenteDeSubjuntivo, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .presenteDeSubjuntivo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularGerundio.next(), .gerundio, .none))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .gerundio, .none))
      }
      for _ in 0...1 {
        if settings.secondSingularQuiz == .tu {
          questions.append((irregularTuImperativo.next(), .imperativoPositivo, .secondSingularTú))
        } else {
          questions.append((irregularVosImperativo.next(), .imperativoPositivo, .secondSingularVos))
        }
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .imperativoPositivo, personNumber(skipYo: true, skipTu: true)))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .imperativoNegativo, personNumber(skipYo: true, skipTu: true)))
      }
    case .difficult:
      for _ in 0...1 {
        questions.append((irregularGerundio.next(), .gerundio, .none))
      }
      [regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .gerundio, .none))
      }
      [regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPresenteDeIndicativo.next(), .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPreterito.next(), .pretérito, personNumber()))
      }
      [regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .pretérito, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularImperfecto.next(), .imperfectoDeIndicativo, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .imperfectoDeIndicativo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularRaizFutura.next(), .futuroDeIndicativo, personNumber()))
      }
      [allRegular.next(), allRegular.next()].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((allRegular.next(), .condicional, personNumber()))
      }
      questions.append((irregularRaizFutura.next(), .condicional, personNumber()))
      for _ in 0...2 {
        questions.append((irregularPresenteDeSubjuntivo.next(), .presenteDeSubjuntivo, personNumber()))
      }
      [regularAr.next(), regularIr.next(), regularEr.next()].forEach {
        questions.append(($0, .presenteDeSubjuntivo, personNumber()))
      }
      questions.append((irregularPreterito.next(), .imperfectoDeSubjuntivo1, personNumber()))
      questions.append((allRegular.next(), .imperfectoDeSubjuntivo2, personNumber()))
      questions.append((irregularPreterito.next(), .futuroDeSubjuntivo, personNumber()))
      questions.append((allRegular.next(), .futuroDeSubjuntivo, personNumber()))
      if settings.secondSingularQuiz == .tu {
        questions.append((irregularTuImperativo.next(), .imperativoPositivo, .secondSingularTú))
      } else {
        questions.append((irregularVosImperativo.next(), .imperativoPositivo, .secondSingularVos))
      }
      questions.append((allRegular.next(), .imperativoPositivo, personNumber(skipYo: true, skipTu: true)))
      questions.append((allRegular.next(), .imperativoNegativo, personNumber(skipYo: true, skipTu: true)))
      [.perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo].forEach {
        questions.append((regularOrIrregularParticipioVerb, $0, personNumber()))
      }
    }
    if shouldShuffle {
      questions.shuffle()
    }
    beginQuiz()
  }

  /// Reset the per-run counters and start the clock. Split out of `start()` so the
  /// screenshot fixture can build its own question list and then enter the quiz
  /// through exactly the same door.
  private func beginQuiz() {
    score = 0
    correctCount = 0
    currentQuestionIndex = 0
    elapsedTime = 0
    quizState = .inProgress
    startTimer()
    LiveActivityManager.start(
      difficulty: lastDifficulty.rawValue,
      totalQuestions: questions.count,
      state: liveActivityState(isFinished: false)
    )
  }

  private var regularOrIrregularParticipioVerb: String {
    let diceRoll: Int
    if shouldShuffle {
      diceRoll = Int.random(in: 0..<2)
    } else {
      diceRoll = questions.count % 2
    }
    if diceRoll == 0 {
      return allRegular.next()
    } else /* diceRoll == 1 */ {
      return irregularParticipio.next()
    }
  }

  func process(proposedAnswer: String) -> (ConjugationResult, String?) {
    let correctAnswer: String
    let result: ConjugationResult
    switch TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: currentPersonNumber) {
    case let .success(answer):
      correctAnswer = answer
      result = ConjugationResult.compare(lhs: proposedAnswer, rhs: correctAnswer)
    case let .failure(error):
      // A quiz slot should always conjugate — VerbFamiliesTests pins every list
      // entry to VerbMap — but degrade gracefully rather than crash a learner
      // mid-quiz: log, score the question as a miss, and advance.
      quizLogger.error("Could not conjugate quiz slot \(self.verb) / \(self.tense.displayName): \(String(describing: error))")
      correctAnswer = ""
      result = .noMatch
    }
    proposedAnswers.append(proposedAnswer)
    correctAnswers.append(correctAnswer)
    if result != .noMatch {
      score += result.rawValue
    }
    if result == .totalMatch {
      correctCount += 1
    }
    if currentQuestionIndex < questions.count - 1 {
      currentQuestionIndex += 1
      LiveActivityManager.update(liveActivityState(isFinished: false))
    } else {
      score = Int(Double(score) * lastRegion.scoreModifier * lastDifficulty.scoreModifier)
      timer?.invalidate()
      quizState = .finished
      // Unlocks the "Change Quiz Difficulty" tip, which is rule-gated on having
      // finished at least one quiz.
      ChangeDifficultyTip.quizCompleted.sendDonation()
      LiveActivityManager.end(liveActivityState(isFinished: true))
      Task {
        await gameCenter.reportScore(score)
      }
    }
    if result == .totalMatch {
      return (result, nil)
    } else {
      return (result, correctAnswer)
    }
  }

  func quit() {
    stop()
  }

  func stop() {
    timer?.invalidate()
    quizState = .finished
    LiveActivityManager.end(liveActivityState(isFinished: true))
  }

  /// The Live Activity content state for the current quiz progress.
  private func liveActivityState(isFinished: Bool) -> QuizActivityAttributes.ContentState {
    QuizActivityAttributes.ContentState(
      currentQuestion: questions.isEmpty ? 0 : min(currentQuestionIndex + 1, questions.count),
      score: score,
      correctCount: correctCount,
      elapsedTime: Quiz.formatElapsed(elapsedTime),
      isFinished: isFinished
    )
  }

  /// Seconds → "m:ss".
  private static func formatElapsed(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
  }

  private func startTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.eachSecond()
      }
    }
  }

  private func eachSecond() {
    elapsedTime += 1
  }

  private func personNumber(skipYo: Bool = false, skipTu: Bool = false) -> DisplayPersonNumber {
    let personNumbers: [DisplayPersonNumber]
    switch settings.secondSingularQuiz {
    case .tu:
      personNumbers = personNumbersWithTu
    case .vos:
      personNumbers = personNumbersWithVos
    }
    personNumbersIndex += 1
    if personNumbersIndex == personNumbers.count {
      personNumbersIndex = 0
    } else if personNumbers[personNumbersIndex].pronoun == DisplayPersonNumber.secondPlural.pronoun && lastRegion == .latinAmerica {
      personNumbersIndex += 1
    }

    if (personNumbers[personNumbersIndex].pronoun == DisplayPersonNumber.firstSingular.pronoun && skipYo) || (personNumbers[personNumbersIndex].pronoun == DisplayPersonNumber.secondSingularTú.pronoun && skipTu) {
      return personNumber(skipYo: skipYo, skipTu: skipTu)
    } else {
      return personNumbers[personNumbersIndex]
    }
  }
}

// MARK: - App Store screenshot fixture (DEBUG only)

#if DEBUG
extension Quiz {
  /// Launch-argument switch that puts the quiz into deterministic screenshot mode:
  /// `xcrun simctl launch … -CONJUGAR_QUIZ_FIXTURE screenshot`. Used by
  /// `scripts/take_screenshots.sh` for screens 5 (quiz mid-question) and 8
  /// (results); see `docs/screenshot-playbook.md`.
  ///
  /// DEBUG-gated, so it cannot be triggered in a release build no matter what
  /// arguments the process is launched with.
  static var isScreenshotFixtureRun: Bool {
    UserDefaults.standard.string(forKey: "CONJUGAR_QUIZ_FIXTURE") == "screenshot"
  }

  /// Where `exportFixtureAnswers()` writes the answer key the driver types back in.
  static var fixtureAnswersURL: URL? {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
      .appendingPathComponent("screenshot_fixture_answers.json")
  }

  /// A fixed, curated question plan for App Store screenshots.
  ///
  /// Deliberately *not* derived from `start()`'s difficulty-driven generators: those
  /// draw from shuffled `Cycler`s, so the verbs — and therefore the per-question
  /// review rows on the results screen — would differ every run and between the
  /// `en` and `es` passes of the same sweep. A hand-picked list keeps the listing
  /// screenshots identical across all four device × language cells, and lets the
  /// rows show off a spread of tenses with verbs a browsing shopper recognizes.
  ///
  /// Two constraints on anything added here:
  /// - **No second-person slots.** `tú` vs. `vos` is a user setting
  ///   (`Settings.secondSingularQuiz`), and `vosotros` is suppressed in the Latin
  ///   America region — a second-person question would render differently depending
  ///   on settings the driver does not control.
  /// - **Every slot must conjugate.** `exportFixtureAnswers()` fails loudly rather
  ///   than exporting a blank answer, because a blank would be typed as an empty
  ///   string and scored as a miss, quietly ruining the results screenshot.
  static let screenshotFixture: [(String, DisplayTense, DisplayPersonNumber)] = [
    ("ser", .presenteDeIndicativo, .firstSingular),
    ("hablar", .presenteDeIndicativo, .thirdSingular),
    ("tener", .pretérito, .firstSingular),
    ("comer", .imperfectoDeIndicativo, .thirdPlural),
    ("hacer", .futuroDeIndicativo, .firstSingular),
    ("vivir", .condicional, .thirdSingular),
    ("ir", .presenteDeSubjuntivo, .firstPlural),
    ("poder", .pretérito, .thirdPlural),
    ("decir", .participio, .none),
    ("estar", .gerundio, .none),
    ("saber", .futuroDeIndicativo, .thirdSingular),
    ("querer", .perfectoDeIndicativo, .firstSingular)
  ]

  /// Build the fixed question plan, export its answer key, and start the quiz.
  func startScreenshotFixture() {
    questions = Quiz.screenshotFixture
    exportFixtureAnswers()
    beginQuiz()
  }

  /// Write `[{ "verb", "tense", "personNumber", "answer" }]` to
  /// `Documents/screenshot_fixture_answers.json`, which the driver reads via
  /// `simctl get_app_container … data` and types back one question at a time.
  ///
  /// Answers are lowercased to strip the engine's UPPERCASE irregularity encoding
  /// (`TenseBridge` returns `soY`, `habRá` — uppercase flags the irregular part).
  /// `ConjugationResult.compare` lowercases both sides before comparing, so this is
  /// not required for the answer to score as a `totalMatch`; it is here so the
  /// exported JSON is legible when a human debugs a bad cell, and so the typed text
  /// matches what a real learner would enter.
  func exportFixtureAnswers() {
    guard let url = Quiz.fixtureAnswersURL else {
      quizLogger.error("Screenshot fixture: no Documents directory")
      return
    }
    var payload: [[String: String]] = []
    for (verb, tense, personNumber) in questions {
      switch TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber) {
      case let .success(answer):
        payload.append([
          "verb": verb,
          "tense": tense.rawValue,
          "personNumber": personNumber.rawValue,
          "answer": answer.lowercased()
        ])
      case let .failure(error):
        // Loud on purpose: a silently-skipped slot would desynchronize the driver's
        // paste loop from the on-screen questions and every later answer would miss.
        quizLogger.error("Screenshot fixture: \(verb) / \(tense.displayName) failed to conjugate: \(String(describing: error))")
      }
    }
    do {
      try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]).write(to: url)
      quizLogger.info("Screenshot fixture: exported \(payload.count) answers to \(url.path)")
    } catch {
      quizLogger.error("Screenshot fixture: could not write \(url.path): \(String(describing: error))")
    }
  }
}
#endif
