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
  /// The seconds spent answering, across the session's rounds. It counts whether or not the
  /// quiz clock shows it, and stops while a correction holds the question.
  private(set) var elapsedTime: Int = 0
  private(set) var currentQuestionIndex = 0
  /// The rounds the session has begun: 1, then 2 after Ten More.
  private(set) var roundCount = 0
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
  @ObservationIgnored private var timer: Timer?
  private let settings: Settings
  private let gameCenter: GameCenter
  /// Nil reads `Current.practice`, which a world's quiz cannot be handed as the world is built.
  @ObservationIgnored private let practiceStore: PracticeStore?
  @ObservationIgnored private var personRotation: [DisplayTense: Int] = [:]
  /// Every random choice a quiz makes, so that a seed draws the same quiz in every process.
  @ObservationIgnored private var generator: AnyRandomNumberGenerator
  /// False leaves the order of a quiz's questions unshuffled and draws from a fixed seed, for
  /// tests and UI tests. A quiz made for a verb page's sheet copies it from `Current.quiz`.
  let shouldShuffle: Bool
  /// Whether this quiz started the Live Activity, which is one for the whole app. A quiz that did
  /// not, such as Test Me's in a sheet, must not update or end the tab's.
  @ObservationIgnored private var hasLiveActivity = false
  /// When the session began, for the duration that `quitQuiz` and `completeQuiz` send.
  @ObservationIgnored private var startDate = Date()
  /// Names this quiz's entry in `QuizAbandonment`, since a quiz in a sheet can run beside the
  /// Quiz tab's.
  @ObservationIgnored let abandonmentID = UUID().uuidString

  typealias Question = QuizQuestion

  /// How many questions after a wrong answer its re-ask comes, or sooner at the round's end.
  static let reaskGap = 3

  /// The questions the session's rounds have asked, re-asks not counted: 10, then 20 after Ten
  /// More, or 3 on a verb's page.
  var questionCount: Int {
    questions.filter { !$0.isReask }.count
  }

  /// The points the answer to the question at `index` earned: a re-ask's right answer earns half,
  /// on either attempt.
  func points(at index: Int) -> Int {
    guard results.indices.contains(index) else {
      return 0
    }
    let points = results[index].rawValue
    return questions[index].isReask ? min(points, ConjugationResult.secondAttemptMatch.rawValue) : points
  }

  var score: Int {
    results.indices.reduce(0) { $0 + points(at: $1) }
  }

  /// The most `score` could be once every question asked so far is answered.
  var maximumScore: Int {
    questions.reduce(0) { $0 + ($1.isReask ? ConjugationResult.secondAttemptMatch.rawValue : ConjugationResult.totalMatch.rawValue) }
  }

  /// The score of the first round's questions, re-asks not counted, which is all that a ranked
  /// session posts.
  var firstRoundScore: Int {
    questions.indices
      .filter { !questions[$0].isReask }
      .prefix(scope.questionCount)
      .reduce(0) { $0 + points(at: $1) }
  }

  /// Whether the round under way, or just finished, is a ranked session's first, the only round
  /// whose score is posted or sent.
  var isRankedRound: Bool {
    scope.isRanked && roundCount == 1
  }

  /// Right on the first attempt, re-asks not counted. A right second attempt is counted apart,
  /// in `secondAttemptCount`.
  var correctCount: Int {
    results.indices.filter { !questions[$0].isReask && results[$0] == .totalMatch }.count
  }

  /// The re-asks the session has asked.
  var reaskCount: Int {
    questions.filter(\.isReask).count
  }

  /// The re-asks answered right, on either attempt.
  var reaskCorrectCount: Int {
    results.indices.filter { questions[$0].isReask && results[$0] != .noMatch }.count
  }

  /// The question reached, re-asks not counted, which `quitQuiz` and `abandonQuiz` send. A re-ask
  /// is inserted only after a wrong answer, so a position that counted re-asks would tell how many
  /// answers were wrong, and no signal says how well a learner did.
  var questionReached: Int {
    questions.prefix(currentQuestionIndex + 1).filter { !$0.isReask }.count
  }

  /// The band of time since the session began, wall-clock, so a stay in the background counts.
  var durationBand: String {
    AnalyticsBand.quizDuration(Date().timeIntervalSince(startDate))
  }

  /// Whether the results offer Ten More: a finished round, not a quit, of a scope that continues.
  var canContinue: Bool {
    quizState == .finished && scope.continues && !questions.isEmpty && results.count == questions.count
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
  init(
    settings: Settings,
    gameCenter: GameCenter,
    shouldShuffle: Bool = true,
    randomSource: (any RandomNumberGenerator)? = nil,
    practice: PracticeStore? = nil
  ) {
    self.settings = settings
    self.gameCenter = gameCenter
    practiceStore = practice
    self.shouldShuffle = shouldShuffle
    if let randomSource {
      generator = AnyRandomNumberGenerator(randomSource)
    } else if shouldShuffle {
      generator = AnyRandomNumberGenerator(SystemRandomNumberGenerator())
    } else {
      generator = AnyRandomNumberGenerator(SplitMix64(seed: 0))
    }
  }

  /// Build the scope's questions at the learner's level, or at a practice set's, and start the
  /// clock. The default scope, every verb, is the Quiz tab's quiz. A scope whose verbs give no
  /// question (an empty My Verbs, or chosen tenses that none of its verbs has) starts nothing,
  /// leaves the quiz as it was, and returns false.
  @discardableResult
  func start(scope: QuizScope = .allVerbs) -> Bool {
    let region = settings.region
    let level = scope.level ?? settings.quizLevel
    #if DEBUG
    if let fixture = Quiz.fixtureRun, scope.verbs == nil, scope.custom == nil {
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
    var drawn = draw(scope)
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

  /// Where each answer is recorded and the due items come from.
  private var practice: PracticeStore {
    practiceStore ?? Current.practice
  }

  /// A round of the scope's questions at `lastLevel`, after the session's questions so far. The
  /// default quiz's rounds each mix in up to three items the practice record says are due
  /// (`QuizDraw.dueQuestions`); a quiz whose verbs or tenses were chosen asks only what was
  /// chosen.
  private func draw(_ scope: QuizScope, after prior: [Question] = []) -> [Question] {
    let pool = scope.pool(level: lastLevel)
    if let verbs = scope.verbs {
      return scopedQuestions(verbs: verbs, count: scope.questionCount, pool: pool, after: prior)
    }
    let band = scope.band(level: lastLevel)
    let due = scope.mixesDueItems ? dueQuestions(pool: pool, band: band) : []
    let drawn = mixedQuestions(count: scope.questionCount - due.count, pool: pool, band: band)
    return QuizDraw.mixing(due, into: drawn, using: &generator)
  }

  private func dueQuestions(pool: [QuizPoolEntry], band: FrequencyBand?) -> [Question] {
    QuizDraw.dueQuestions(for: practice.dueItems(), band: band, asks: { cell in
      pool.first { $0.tense == cell.tense }.map { personNumbers(for: $0).contains(cell.personNumber) } ?? false
    }, using: &generator)
  }

  /// The quiz over a band's verbs, the default quiz's over the level's: each question's tense
  /// drawn from the pool by weight and its person the next of the tense's rotation, then the
  /// verbs from the band, balanced (`QuizDraw`).
  private func mixedQuestions(count: Int, pool: [QuizPoolEntry], band: FrequencyBand?) -> [Question] {
    var cells: [ConjugationCell] = []
    while cells.count < count, let entry = pool.weightedRandomElement(using: &generator) {
      cells.append(ConjugationCell(tense: entry.tense, personNumber: personNumber(for: entry)))
    }
    return QuizDraw.questions(cells: cells, band: band, using: &generator)
  }

  /// Questions about the given verbs only, in the pool's tenses and never in a cell a verb lacks
  /// (a defective verb's) or vosotros in the Latin America region.
  ///
  /// A full-length quiz draws its tenses by weight as the tab's quiz does and puts the scope's
  /// verbs in them in turn, avoiding a repeated question where another verb can take the cell. A
  /// tense that none of the verbs has is left out. A shorter quiz, such as Test Me's three
  /// questions, asks distinct cells in different tenses instead, one tense at a time, the heavier
  /// tenses likelier to come first.
  ///
  /// A later round passes the session's questions so far as `prior`, so that its verbs take
  /// turns with the earlier rounds' and a cell already asked goes to another verb where one fits.
  private func scopedQuestions(verbs: [String], count: Int, pool tensePool: [QuizPoolEntry], after prior: [Question]) -> [Question] {
    var pool = verbs.filter { VerbMap.shared.entry(for: $0) != nil }
    guard !pool.isEmpty, count > 0 else {
      return []
    }
    if shouldShuffle {
      pool.shuffle(using: &generator)
    }
    var asked = prior.map { QuizQuestion($0.verb, $0.tense, $0.personNumber) }
    let target = asked.count + count
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

    if count >= QuizScope.roundLength {
      var entries = tensePool
      while asked.count < target, let entry = entries.weightedRandomElement(using: &generator) {
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
      return Array(asked.dropFirst(prior.count))
    }

    let entries = shouldShuffle ? tensePool.weightedShuffled(using: &generator) : tensePool
    var cellsByTense: [[DisplayPersonNumber]] = entries.map { entry in
      let personNumbers = personNumbers(for: entry)
      return shouldShuffle ? personNumbers.shuffled(using: &generator) : personNumbers
    }
    var askedInRound = true
    while asked.count < target, askedInRound {
      askedInRound = false
      for index in entries.indices where asked.count < target {
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
    return Array(asked.dropFirst(prior.count))
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

  /// The answers right on the second attempt, re-asks not counted, counted apart from
  /// `correctCount`.
  var secondAttemptCount: Int {
    results.indices.filter { !questions[$0].isReask && results[$0] == .secondAttemptMatch }.count
  }

  /// Whether the clock is counting, which it does only while a question waits for its answer.
  var isClockRunning: Bool {
    timer?.isValid ?? false
  }

  /// Reset the per-run counters and start the clock. Split out of `start()` so the
  /// screenshot fixture can build its own question list and then enter the quiz
  /// through exactly the same door.
  private func beginQuiz() {
    currentQuestionIndex = 0
    elapsedTime = 0
    roundCount = 1
    startDate = Date()
    beginRound()
  }

  /// Ten More: another round in the same session, offered by the results. The score, the clock,
  /// and the questions so far carry on, and the new questions are a fresh draw at the session's
  /// level, so that every round has the mix of a quiz's first. Returns false, changing nothing,
  /// when the results offer no Ten More or the draw gives no question.
  @discardableResult
  func continueSession() -> Bool {
    guard canContinue else {
      return false
    }
    var drawn = draw(scope, after: questions)
    guard !drawn.isEmpty else {
      return false
    }
    if shouldShuffle {
      drawn.shuffle(using: &generator)
    }
    currentQuestionIndex = questions.count
    questions += drawn
    roundCount += 1
    beginRound()
    return true
  }

  /// Starts the clock, the Live Activity, and the record of progress for the round from
  /// `currentQuestionIndex`.
  private func beginRound() {
    correction = nil
    firstAttempt = nil
    lastCurrentSpelling = nil
    quizState = .inProgress
    startTimer()
    // The Live Activity belongs to the tab's quiz. See `QuizScope.startsLiveActivity`.
    hasLiveActivity = scope.startsLiveActivity
    if hasLiveActivity {
      Current.liveActivities.start(level: lastLevel.rawValue, state: liveActivityState(isFinished: false))
    }
    recordProgress()
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
      // A quiz slot should always conjugate, since every draw asks the engine first, but
      // degrade gracefully rather than crash a learner mid-quiz: log and score the question
      // as a miss.
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
    // Recorded as it is given, so that a quiz quit after six questions has still practiced six.
    if !correctAnswer.isEmpty {
      practice.recordAnswer(to: question, isCorrect: result != .noMatch)
    }
    switch result {
    case .totalMatch, .secondAttemptMatch:
      advance()
    case .noMatch:
      timer?.invalidate()
      let willBeReasked = !question.isReask
      if willBeReasked {
        questions.insert(question.reasked(), at: min(currentQuestionIndex + 1 + Quiz.reaskGap, questions.count))
      }
      correction = QuizCorrection(difference: question.difference(from: proposedAnswer), willBeReasked: willBeReasked)
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
      recordProgress()
    } else {
      finish()
    }
  }

  private func finish() {
    timer?.invalidate()
    quizState = .finished
    clearProgress()
    // Unlocks the "Choose Your Level" tip, which is rule-gated on having
    // finished at least one quiz. Three questions on a verb's page are not one.
    if roundCount == 1, scope.continues {
      ChangeLevelTip.quizCompleted.sendDonation()
    }
    endLiveActivity()
    if isRankedRound {
      gameCenter.submitScore(firstRoundScore, level: lastLevel)
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
    clearProgress()
    endLiveActivity()
  }

  /// Where the quiz has reached, for the next launch to report should the app be left during it.
  private func recordProgress() {
    QuizAbandonment.record(
      QuizAbandonment.Entry(level: lastLevel.rawValue, source: scope.source.rawValue, questionNumber: questionReached),
      id: abandonmentID,
      getterSetter: Current.getterSetter
    )
  }

  private func clearProgress() {
    QuizAbandonment.clear(id: abandonmentID, getterSetter: Current.getterSetter)
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
      totalQuestions: questions.count,
      score: score,
      correctCount: correctCount,
      elapsedTime: settings.quizClock == .show ? Quiz.formatElapsed(elapsedTime) : nil,
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
  /// Deliberately *not* derived from `start()`'s level-driven draw: that draws at
  /// random, so the verbs — and therefore the per-question
  /// review rows on the results screen — would differ every run and between the
  /// `en` and `es` passes of the same sweep. A hand-picked list keeps the listing
  /// screenshots identical across all four device × language cells, and lets the
  /// rows show off a spread of tenses with verbs a browsing shopper recognizes.
  /// It holds one round, so that the results show what a learner's first ten do.
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
    QuizQuestion("tener", .pretérito, .firstSingular),
    QuizQuestion("comer", .imperfectoDeIndicativo, .thirdPlural),
    QuizQuestion("hacer", .futuroDeIndicativo, .firstSingular),
    QuizQuestion("vivir", .condicional, .thirdSingular),
    QuizQuestion("ir", .presenteDeSubjuntivo, .firstPlural),
    QuizQuestion("poder", .pretérito, .thirdPlural),
    QuizQuestion("decir", .participio, .none),
    QuizQuestion("estar", .gerundio, .none),
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
