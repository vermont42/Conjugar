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

  var count: Int {
    elements.count
  }

  /// Return to the start of a (optionally reshuffled) list for a new quiz.
  func restart(shuffle: Bool, using generator: inout some RandomNumberGenerator) {
    if shuffle {
      elements.shuffle(using: &generator)
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

/// Lets `Quiz` hold whichever generator it was given.
private struct AnyRandomNumberGenerator: RandomNumberGenerator {
  private var base: any RandomNumberGenerator

  init(_ base: any RandomNumberGenerator) {
    self.base = base
  }

  mutating func next() -> UInt64 {
    base.next()
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
  private(set) var lastLevel: QuizLevel = .initial
  private(set) var proposedAnswers: [String] = []
  private(set) var correctAnswers: [String] = []
  /// Each answered question's grade, as `process(proposedAnswer:)` gave it. The results screen
  /// reads these rather than regrading, because a reflexive-only verb accepts two answers and
  /// `correctAnswers` holds only the one shown.
  private(set) var results: [ConjugationResult] = []
  /// Each answered question's first attempt when it was a slip that earned a second, else nil.
  private(set) var firstAttempts: [String?] = []
  /// The slip that the question on screen waits on for its second attempt. A question gets one
  /// more attempt at most, so a second slip goes to the correction.
  private(set) var firstAttempt: String?
  /// The current spelling of the last answer when it was right in a retired one. See
  /// `QuizQuestion.currentSpelling(of:)`.
  private(set) var lastCurrentSpelling: String?
  /// The correction of a wrong answer, which holds the quiz on its question, with the clock
  /// stopped, until `continueAfterCorrection()`. A right answer advances at once.
  private(set) var correction: QuizCorrection?
  private(set) var questions: [Question] = []
  /// What the quiz under way, or last finished, asks about. See `QuizScope`.
  private(set) var scope = QuizScope.allVerbs
  private let regularAr = Cycler(VerbFamilies.regularArVerbs)
  private let regularIr = Cycler(VerbFamilies.regularIrVerbs)
  private let regularEr = Cycler(VerbFamilies.regularErVerbs)
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
      regularAr, regularIr, regularEr,
      irregularPresenteDeIndicativo, irregularPreterito, irregularRaizFutura,
      irregularParticipio, irregularImperfecto, irregularPresenteDeSubjuntivo,
      irregularGerundio, irregularTuImperativo, irregularVosImperativo
    ]
  }
  @ObservationIgnored private var timer: Timer?
  private let settings: Settings
  private let gameCenter: GameCenter
  @ObservationIgnored private var personRotation: [DisplayTense: Int] = [:]
  /// Which of the -ar, -er, and -ir lists gives the next regular verb, so that the three
  /// endings take turns.
  @ObservationIgnored private var regularTurn = 0
  /// Every random choice a quiz makes, so that a seed draws the same quiz in every process.
  @ObservationIgnored private var generator: AnyRandomNumberGenerator
  /// False leaves every list and order unshuffled and draws from a fixed seed, for tests and UI
  /// tests. A quiz made for a verb page's sheet copies it from `Current.quiz`.
  let shouldShuffle: Bool
  /// Whether this quiz started the Live Activity, which is one for the whole app. A quiz that did
  /// not, such as Test Me's in a sheet, must not update or end the tab's.
  @ObservationIgnored private var hasLiveActivity = false

  typealias Question = QuizQuestion

  var questionCount: Int {
    return questions.count
  }

  var verb: String {
    if questions.count > 0 {
      return questions[currentQuestionIndex].verb
    } else {
      return ""
    }
  }

  var tense: DisplayTense {
    if questions.count > 0 {
      return questions[currentQuestionIndex].tense
    } else {
      return .infinitivo
    }
  }

  /// The question on screen, or nil before a quiz has questions.
  var currentQuestion: Question? {
    questions.indices.contains(currentQuestionIndex) ? questions[currentQuestionIndex] : nil
  }

  var currentPersonNumber: DisplayPersonNumber {
    if questions.count > 0 {
      return questions[currentQuestionIndex].personNumber
    } else {
      return .none
    }
  }

  /// A `randomSource` makes every draw follow it. Without one, a shuffling quiz draws from the
  /// system's generator and any other from a fixed seed.
  init(settings: Settings, gameCenter: GameCenter, shouldShuffle: Bool = true, randomSource: (any RandomNumberGenerator)? = nil) {
    self.settings = settings
    self.gameCenter = gameCenter
    self.shouldShuffle = shouldShuffle
    if let randomSource {
      generator = AnyRandomNumberGenerator(randomSource)
    } else if shouldShuffle {
      generator = AnyRandomNumberGenerator(SystemRandomNumberGenerator())
    } else {
      generator = AnyRandomNumberGenerator(SplitMix64(seed: 0))
    }
  }

  /// Build the scope's questions at the learner's level and start the clock. The default scope,
  /// every verb, is the Quiz tab's quiz. A scope whose verbs give no question (an empty My Verbs)
  /// starts nothing, leaves the quiz as it was, and returns false.
  @discardableResult
  func start(scope: QuizScope = .allVerbs) -> Bool {
    let region = settings.region
    let level = settings.quizLevel
    #if DEBUG
    if let fixture = Quiz.fixtureRun, scope.verbs == nil {
      self.scope = scope
      lastRegion = region
      lastLevel = level
      clearAnswers()
      switch fixture {
      case .screenshot:
        startScreenshotFixture()
      case .grading:
        questions = Quiz.gradingFixture
        beginQuiz()
      case .frames:
        questions = Quiz.framesFixture
        beginQuiz()
      case .corrections:
        questions = Quiz.correctionsFixture
        beginQuiz()
      case .slips:
        questions = Quiz.slipsFixture
        beginQuiz()
      }
      return true
    }
    #endif
    let previousRegion = lastRegion
    let previousLevel = lastLevel
    // `personNumber(for:)` reads the region and the level, so they are set before the draw.
    lastRegion = region
    lastLevel = level
    var drawn: [Question]
    if let verbs = scope.verbs {
      drawn = scopedQuestions(verbs: verbs, count: scope.questionCount)
    } else {
      drawn = levelQuestions(count: scope.questionCount)
    }
    guard !drawn.isEmpty else {
      lastRegion = previousRegion
      lastLevel = previousLevel
      return false
    }
    if shouldShuffle {
      drawn.shuffle(using: &generator)
    }
    self.scope = scope
    clearAnswers()
    questions = drawn
    beginQuiz()
    return true
  }

  private func clearAnswers() {
    questions.removeAll()
    proposedAnswers.removeAll()
    correctAnswers.removeAll()
    results.removeAll()
    firstAttempts.removeAll()
  }

  /// The quiz over every verb: each question's tense drawn from the level by weight, its person
  /// the next of the tense's rotation, and its verb from the curated lists in `VerbFamilies`,
  /// regular and irregular in turn.
  private func levelQuestions(count: Int) -> [Question] {
    for cycler in allCyclers {
      cycler.restart(shuffle: shouldShuffle, using: &generator)
    }
    let pool = lastLevel.pool
    var questions: [Question] = []
    while questions.count < count, let entry = pool.weightedRandomElement(using: &generator) {
      let personNumber = personNumber(for: entry)
      let verb = listedVerb(for: entry.tense, personNumber, irregular: !questions.count.isMultiple(of: 2))
      questions.append(QuizQuestion(verb, entry.tense, personNumber))
    }
    return questions
  }

  /// The next verb of the list for the cell that the engine can ask it, skipping a defective
  /// verb's missing cells.
  private func listedVerb(for tense: DisplayTense, _ personNumber: DisplayPersonNumber, irregular: Bool) -> String {
    let cycler: Cycler
    if irregular {
      cycler = irregularCycler(for: tense, personNumber)
    } else {
      let endings = [regularAr, regularEr, regularIr]
      cycler = endings[regularTurn % endings.count]
      regularTurn += 1
    }
    for _ in 0..<cycler.count {
      let verb = cycler.next()
      if Quiz.canAsk(verb, tense, personNumber) {
        return verb
      }
    }
    return regularAr.next()
  }

  /// The curated list of verbs irregular in a cell. A tense built on another's stem takes that
  /// tense's list: the imperfectos and futuro de subjuntivo the pretérito's, the condicional the
  /// futuro's, and the commands other than tú's and vos's the presente de subjuntivo's. A compound
  /// tense is irregular in its participle.
  private func irregularCycler(for tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> Cycler {
    switch tense {
    case .presenteDeIndicativo:
      return irregularPresenteDeIndicativo
    case .pretérito, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo:
      return irregularPreterito
    case .imperfectoDeIndicativo:
      return irregularImperfecto
    case .futuroDeIndicativo, .condicional:
      return irregularRaizFutura
    case .presenteDeSubjuntivo, .imperativoNegativo:
      return irregularPresenteDeSubjuntivo
    case .imperativoPositivo:
      switch personNumber {
      case .secondSingularTú:
        return irregularTuImperativo
      case .secondSingularVos:
        return irregularVosImperativo
      default:
        return irregularPresenteDeSubjuntivo
      }
    case .gerundio:
      return irregularGerundio
    default:
      return irregularParticipio
    }
  }

  /// Questions about the given verbs only, in the level's tenses and never in a cell a verb lacks
  /// (a defective verb's) or vosotros in the Latin America region.
  ///
  /// A full-length quiz draws its tenses by weight as the tab's quiz does and puts the scope's
  /// verbs in them in turn, avoiding a repeated question where another verb can take the cell. A
  /// tense that none of the verbs has is left out. A shorter quiz, such as Test Me's three
  /// questions, asks distinct cells in different tenses instead, one tense at a time, the heavier
  /// tenses likelier to come first.
  private func scopedQuestions(verbs: [String], count: Int) -> [Question] {
    var pool = verbs.filter { VerbMap.shared.entry(for: $0) != nil }
    guard !pool.isEmpty, count > 0 else {
      return []
    }
    if shouldShuffle {
      pool.shuffle(using: &generator)
    }
    var asked: [Question] = []
    var nextVerb = 0

    /// A verb that can be asked in a cell, preferring one not already asked there, then the one
    /// asked least, then the next in turn. The turn passes to the verb after the one chosen, so a
    /// defective verb, which fits few cells, still gets its share of the cells it fits.
    func verb(for tense: DisplayTense, _ personNumber: DisplayPersonNumber, allowingRepeat: Bool) -> String? {
      var best: (offset: Int, isRepeat: Bool, count: Int)?
      for offset in 0..<pool.count {
        let candidate = pool[(nextVerb + offset) % pool.count]
        guard Quiz.canAsk(candidate, tense, personNumber) else {
          continue
        }
        let isRepeat = asked.contains { $0 == QuizQuestion(candidate, tense, personNumber) }
        guard allowingRepeat || !isRepeat else {
          continue
        }
        let count = asked.filter { $0.verb == candidate }.count
        if let current = best, (current.isRepeat ? 1 : 0, current.count) <= (isRepeat ? 1 : 0, count) {
          continue
        }
        best = (offset, isRepeat, count)
      }
      guard let best else {
        return nil
      }
      let chosen = pool[(nextVerb + best.offset) % pool.count]
      nextVerb = (nextVerb + best.offset + 1) % pool.count
      return chosen
    }

    if count >= QuizScope.fullLength {
      var entries = lastLevel.pool
      while asked.count < count, let entry = entries.weightedRandomElement(using: &generator) {
        // The rotation's person first, then the tense's others, for a verb that lacks it.
        let first = personNumber(for: entry)
        let personNumbers = personNumbers(for: entry)
        let start = personNumbers.firstIndex(of: first) ?? 0
        var placed: Question?
        for personNumber in personNumbers[start...] + personNumbers[..<start] {
          if let chosen = verb(for: entry.tense, personNumber, allowingRepeat: true) {
            placed = QuizQuestion(chosen, entry.tense, personNumber)
            break
          }
        }
        if let placed {
          asked.append(placed)
        } else {
          entries.removeAll { $0 == entry }
        }
      }
      return asked
    }

    let entries = shouldShuffle ? lastLevel.pool.weightedShuffled(using: &generator) : lastLevel.pool
    var cellsByTense: [[DisplayPersonNumber]] = entries.map { entry in
      let personNumbers = personNumbers(for: entry)
      return shouldShuffle ? personNumbers.shuffled(using: &generator) : personNumbers
    }
    var askedInRound = true
    while asked.count < count, askedInRound {
      askedInRound = false
      for index in entries.indices where asked.count < count {
        while !cellsByTense[index].isEmpty {
          let personNumber = cellsByTense[index].removeFirst()
          if let chosen = verb(for: entries[index].tense, personNumber, allowingRepeat: false) {
            asked.append(QuizQuestion(chosen, entries[index].tense, personNumber))
            askedInRound = true
            break
          }
        }
      }
    }
    return asked
  }

  /// The persons a quiz may ask in a level's tense: tú or vos by the setting, no vosotros in the
  /// Latin America region, no yo in a command, and none the level leaves out.
  private func personNumbers(for entry: QuizPoolEntry) -> [DisplayPersonNumber] {
    let tense = entry.tense
    if tense == .gerundio || tense == .participio {
      return [.none]
    }
    let secondSingular: DisplayPersonNumber = settings.secondSingularQuiz == .tu ? .secondSingularTú : .secondSingularVos
    var personNumbers: [DisplayPersonNumber]
    switch tense {
    case .imperativoPositivo, .imperativoNegativo:
      personNumbers = [secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    default:
      personNumbers = [.firstSingular, secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    }
    if lastRegion == .latinAmerica {
      personNumbers.removeAll { $0 == .secondPlural }
    }
    return personNumbers.filter(entry.asks)
  }

  /// Whether the engine gives the cell, which a defective verb's missing cells it does not.
  private static func canAsk(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> Bool {
    if case .success = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber) {
      return true
    }
    return false
  }

  /// Whether the quiz waits on its question for the learner to continue.
  var isHeld: Bool {
    correction != nil
  }

  /// Whether the question on screen waits for a second attempt after a slip. The clock runs on,
  /// since the learner is still answering.
  var isAwaitingSecondAttempt: Bool {
    firstAttempt != nil
  }

  /// The answers right on the second attempt, counted apart from `correctCount`.
  var secondAttemptCount: Int {
    results.filter { $0 == .secondAttemptMatch }.count
  }

  /// Whether the clock is counting, which it does only while a question waits for its answer.
  var isClockRunning: Bool {
    timer?.isValid ?? false
  }

  /// Reset the per-run counters and start the clock. Split out of `start()` so the
  /// screenshot fixture can build its own question list and then enter the quiz
  /// through exactly the same door.
  private func beginQuiz() {
    score = 0
    correctCount = 0
    currentQuestionIndex = 0
    elapsedTime = 0
    correction = nil
    firstAttempt = nil
    lastCurrentSpelling = nil
    quizState = .inProgress
    startTimer()
    // The Live Activity belongs to the tab's quiz. See `QuizScope.startsLiveActivity`.
    hasLiveActivity = scope.startsLiveActivity
    if hasLiveActivity {
      Current.liveActivities.start(
        level: lastLevel.rawValue,
        totalQuestions: questions.count,
        state: liveActivityState(isFinished: false)
      )
    }
  }

  /// Grades the answer to the question on screen. A first attempt that is a slip
  /// (`QuizQuestion.isSlip(_:)`) records nothing and returns nil, and the question waits for one
  /// more attempt with the clock running. Any other answer is recorded: a right one advances at
  /// once, earning half its points on a second attempt, and a wrong one holds the question with
  /// its correction and stops the clock.
  @discardableResult
  func process(proposedAnswer: String) -> ConjugationResult? {
    let question = questions[currentQuestionIndex]
    let correctAnswer: String
    let result: ConjugationResult
    if let answer = question.writtenAnswer {
      let isRight = question.grade(proposedAnswer) == .totalMatch
      if !isRight, firstAttempt == nil, question.isSlip(proposedAnswer) {
        firstAttempt = proposedAnswer
        return nil
      }
      correctAnswer = answer
      if isRight {
        result = firstAttempt == nil ? .totalMatch : .secondAttemptMatch
      } else {
        result = .noMatch
      }
      lastCurrentSpelling = isRight ? question.currentSpelling(of: proposedAnswer) : nil
    } else {
      // A quiz slot should always conjugate — VerbFamiliesTests pins every list
      // entry to VerbMap — but degrade gracefully rather than crash a learner
      // mid-quiz: log and score the question as a miss.
      quizLogger.error("Could not conjugate quiz slot \(self.verb) / \(self.tense.displayName)")
      correctAnswer = ""
      result = .noMatch
      lastCurrentSpelling = nil
    }
    proposedAnswers.append(proposedAnswer)
    correctAnswers.append(correctAnswer)
    results.append(result)
    firstAttempts.append(firstAttempt)
    firstAttempt = nil
    score += result.rawValue
    switch result {
    case .totalMatch:
      correctCount += 1
      advance()
    case .secondAttemptMatch:
      advance()
    case .noMatch:
      timer?.invalidate()
      correction = QuizCorrection(difference: question.difference(from: proposedAnswer))
    }
    return result
  }

  /// Leaves a held correction for the next question, or for the results after the last.
  func continueAfterCorrection() {
    guard quizState == .inProgress, isHeld else {
      return
    }
    correction = nil
    advance()
    if quizState == .inProgress {
      startTimer()
    }
  }

  private func advance() {
    if currentQuestionIndex < questions.count - 1 {
      currentQuestionIndex += 1
      if hasLiveActivity {
        Current.liveActivities.update(liveActivityState(isFinished: false))
      }
    } else {
      finish()
    }
  }

  private func finish() {
    timer?.invalidate()
    quizState = .finished
    // Unlocks the "Choose Your Level" tip, which is rule-gated on having
    // finished at least one quiz. Three questions on a verb's page are not one.
    if scope.questionCount >= QuizScope.fullLength {
      ChangeLevelTip.quizCompleted.sendDonation()
    }
    endLiveActivity()
    if scope.isRanked {
      let finalScore = score
      Task {
        await gameCenter.reportScore(finalScore)
      }
    }
  }

  func quit() {
    stop()
  }

  func stop() {
    timer?.invalidate()
    correction = nil
    firstAttempt = nil
    quizState = .finished
    endLiveActivity()
  }

  private func endLiveActivity() {
    guard hasLiveActivity else {
      return
    }
    hasLiveActivity = false
    Current.liveActivities.end(liveActivityState(isFinished: true))
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

  /// The next person a tense asks, in a rotation of its own over the persons it may ask
  /// (`personNumbers(for:)`), which carries over from one quiz to the next. One rotation for
  /// every tense would fall into step with a quiz's length, and a tense asked once a quiz, such
  /// as a command, would meet the same person every time.
  private func personNumber(for entry: QuizPoolEntry) -> DisplayPersonNumber {
    let personNumbers = personNumbers(for: entry)
    let index: Int
    if let last = personRotation[entry.tense] {
      index = last + 1
    } else {
      index = shouldShuffle ? Int.random(in: 0..<personNumbers.count, using: &generator) : 0
    }
    personRotation[entry.tense] = index
    return personNumbers[index % personNumbers.count]
  }
}

#if DEBUG
extension Quiz {
  /// A fixed question plan the tab's quiz asks instead of drawing one, named by the launch
  /// argument `-CONJUGAR_QUIZ_FIXTURE <name>`. DEBUG-gated, so it cannot be triggered in a
  /// release build no matter what arguments the process is launched with.
  enum Fixture: String {
    /// Deterministic screenshot mode, used by `scripts/take_screenshots.sh` for screens 5 (quiz
    /// mid-question) and 8 (results); see `docs/screenshot_playbook.md`.
    case screenshot
    /// Questions whose right answers can be typed more than one way, for trying the grading by
    /// hand. Each comment names an answer beside the shown one; the second-person questions
    /// assume the tú setting.
    case grading
    /// One question per kind of answer frame, whatever the settings: each person of a finite
    /// form, a compound tense, every command, the gerundio and participio, and a reflexive-only
    /// verb's frames.
    case frames
    /// Questions whose comments give a wrong answer that shows a kind of marking on the held
    /// correction: an accent, a red letter, a missing or extra letter, a swap, a frame's supplied
    /// word, and the nearest of two right answers. Most of these answers are slips, so each is
    /// typed twice to reach its correction.
    case corrections
    /// Questions whose comments give a near miss: a slip, which earns one more attempt, or an
    /// answer as near that is another cell of the verb, which goes to the correction at once.
    case slips
  }

  static var fixtureRun: Fixture? {
    UserDefaults.standard.string(forKey: "CONJUGAR_QUIZ_FIXTURE").flatMap(Fixture.init(rawValue:))
  }

  static let gradingFixture: [Question] = [
    QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular),      // yo hablo
    QuizQuestion("reír", .pretérito, .thirdSingular),                   // rió
    QuizQuestion("freír", .perfectoDeIndicativo, .firstSingular),       // he frito, yo he frito
    QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú),     // no hables
    QuizQuestion("arrepentir", .presenteDeIndicativo, .firstSingular),  // arrepiento
    QuizQuestion("satisfacer", .imperativoPositivo, .secondSingularTú), // satisface
    QuizQuestion("predecir", .futuroDeIndicativo, .firstSingular),      // predeciré
    QuizQuestion("huir", .pretérito, .firstSingular),                   // huí
    QuizQuestion("adecuar", .presenteDeIndicativo, .firstSingular),     // adecúo
    QuizQuestion("tener", .presenteDeIndicativo, .thirdPlural)          // ellos tienen, ustedes tienen
  ]

  static let framesFixture: [Question] = [
    QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular),           // yo [hablo]
    QuizQuestion("hablar", .presenteDeIndicativo, .secondSingularTú),        // tú [hablas]
    QuizQuestion("hablar", .presenteDeIndicativo, .secondSingularVos),       // vos [hablás]
    QuizQuestion("tener", .pretérito, .thirdSingular),                       // él [tuvo]
    QuizQuestion("ir", .futuroDeIndicativo, .firstPlural),                   // nosotros [iremos]
    QuizQuestion("comer", .imperfectoDeIndicativo, .secondPlural),           // vosotros [comíais]
    QuizQuestion("decir", .perfectoDeIndicativo, .thirdPlural),              // ellas [han dicho]
    QuizQuestion("hablar", .imperativoPositivo, .secondSingularTú),          // (tú) ¡[habla]!
    QuizQuestion("tener", .imperativoPositivo, .secondSingularVos),          // (vos) ¡[tené]!
    QuizQuestion("hacer", .imperativoPositivo, .thirdSingular),              // (usted) ¡[haga]!
    QuizQuestion("venir", .imperativoPositivo, .firstPlural),                // (nosotros) ¡[vengamos]!
    QuizQuestion("salir", .imperativoPositivo, .secondPlural),               // (vosotros) ¡[salid]!
    QuizQuestion("poner", .imperativoPositivo, .thirdPlural),                // (ustedes) ¡[pongan]!
    QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú),          // (tú) ¡no [hables]!
    QuizQuestion("ser", .imperativoNegativo, .thirdPlural),                  // (ustedes) ¡no [sean]!
    QuizQuestion("estar", .gerundio, .none),                                 // [estando]
    QuizQuestion("escribir", .participio, .none),                            // [escrito]
    QuizQuestion("arrepentir", .presenteDeIndicativo, .firstSingular),       // yo me [arrepiento]
    QuizQuestion("arrepentir", .perfectoDeIndicativo, .firstPlural),         // nosotros nos [hemos arrepentido]
    QuizQuestion("arrepentir", .imperativoPositivo, .secondSingularTú),      // (tú) ¡[arrepiéntete]!
    QuizQuestion("arrepentir", .imperativoNegativo, .thirdSingular)          // (usted) ¡no se [arrepienta]!
  ]

  static let slipsFixture: [Question] = [
    QuizQuestion("cantar", .condicional, .firstSingular),               // cantaria: accents only, another try
    QuizQuestion("tener", .presenteDeIndicativo, .firstSingular),       // tengp: one letter, another try
    QuizQuestion("ir", .futuroDeIndicativo, .firstSingular),            // ire: accents only, short as it is
    QuizQuestion("enseñar", .condicional, .thirdSingular),              // ensenaria: ñ and an accent
    QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú),     // hablez: one letter, beside the frame's "no"
    QuizQuestion("decir", .perfectoDeIndicativo, .thirdPlural),         // han dicjo: one letter in a compound
    QuizQuestion("hablar", .pretérito, .thirdSingular),                 // hablo: the presente, so a correction
    QuizQuestion("comer", .pretérito, .firstSingular),                  // comio: comió, the wrong person
    QuizQuestion("hablar", .presenteDeSubjuntivo, .firstSingular),      // hablé: the pretérito
    QuizQuestion("ser", .presenteDeIndicativo, .firstSingular)          // sot: too short for a one-letter slip
  ]

  static let correctionsFixture: [Question] = [
    QuizQuestion("hablar", .pretérito, .thirdSingular),                 // hablo: an accent, and the presente
    QuizQuestion("tener", .presenteDeIndicativo, .firstSingular),       // teno: a missing red letter
    QuizQuestion("arrepentir", .presenteDeIndicativo, .firstSingular),  // arepiento: a missing letter
    QuizQuestion("comer", .imperfectoDeIndicativo, .firstPlural),       // comíamoss: an extra letter
    QuizQuestion("vivir", .presenteDeIndicativo, .thirdPlural),         // vivne: a swap
    QuizQuestion("hablar", .imperativoNegativo, .secondSingularTú),     // hablas: the "no" is not marked
    QuizQuestion("freír", .participio, .none),                          // freido: freído, not frito
    QuizQuestion("decir", .perfectoDeIndicativo, .thirdPlural)          // han decido: a compound
  ]

  /// Where `exportFixtureAnswers()` writes the answer key the driver types back in.
  static var fixtureAnswersURL: URL? {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
      .appendingPathComponent("screenshot_fixture_answers.json")
  }

  /// A fixed, curated question plan for App Store screenshots.
  ///
  /// Deliberately *not* derived from `start()`'s level-driven draw: that draws from
  /// shuffled `Cycler`s, so the verbs — and therefore the per-question
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
  static let screenshotFixture: [Question] = [
    QuizQuestion("ser", .presenteDeIndicativo, .firstSingular),
    QuizQuestion("hablar", .presenteDeIndicativo, .thirdSingular),
    QuizQuestion("tener", .pretérito, .firstSingular),
    QuizQuestion("comer", .imperfectoDeIndicativo, .thirdPlural),
    QuizQuestion("hacer", .futuroDeIndicativo, .firstSingular),
    QuizQuestion("vivir", .condicional, .thirdSingular),
    QuizQuestion("ir", .presenteDeSubjuntivo, .firstPlural),
    QuizQuestion("poder", .pretérito, .thirdPlural),
    QuizQuestion("decir", .participio, .none),
    QuizQuestion("estar", .gerundio, .none),
    QuizQuestion("saber", .futuroDeIndicativo, .thirdSingular),
    QuizQuestion("querer", .perfectoDeIndicativo, .firstSingular)
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
  /// `QuizQuestion.grade(_:)` lowercases both sides before comparing, so this is
  /// not required for the answer to score as a `totalMatch`; it is here so the
  /// exported JSON is legible when a human debugs a bad cell, and so the typed text
  /// matches what a real learner would enter.
  func exportFixtureAnswers() {
    guard let url = Quiz.fixtureAnswersURL else {
      quizLogger.error("Screenshot fixture: no Documents directory")
      return
    }
    var payload: [[String: String]] = []
    for question in questions {
      let (verb, tense, personNumber) = (question.verb, question.tense, question.personNumber)
      switch TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber, pronoun: .written) {
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
