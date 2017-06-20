//
//  Quiz.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

internal class Quiz {
  private(set) var numberCorrect: Int = 0
  private(set) var quizState: QuizState = .notStarted
  private(set) var elapsedTime: Int = 0
  private(set) var score: Int = 0
  private(set) var currentQuestionIndex = 0
  private var questions: [(String, Tense, PersonNumber)] = []
  private var regularArVerbs = VerbFamilies.regularArVerbs
  private var regularArVerbsIndex = 0
  private var regularIrVerbs = VerbFamilies.regularIrVerbs
  private var regularIrVerbsIndex = 0
  private var regularErVerbs = VerbFamilies.regularErVerbs
  private var regularErVerbsIndex = 0
  private var irregularPresenteDeIndicativoVerbs = VerbFamilies.irregularPresenteDeIndicativoVerbs
  private var irregularPresenteDeIndicativoVerbsIndex = 0
  private var irregularRaizFuturaVerbs = VerbFamilies.irregularRaizFuturaVerbs
  private var irregularRaizFuturaVerbsIndex = 0
  private var irregularParticipioVerbs = VerbFamilies.irregularParticipioVerbs
  private var irregularParticipioVerbsIndex = 0
  private var timer: Timer?
  private var personNumbers: [PersonNumber] = [.firstSingular, .secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
  private var personNumbersIndex = 0
  internal weak var delegate: QuizDelegate? = nil
  static let shared = Quiz()
  
  internal var questionCount: Int {
    return questions.count
  }

  internal var verb: String {
    if questions.count > 0 {
      return questions[currentQuestionIndex].0
    }
    else {
      return ""
    }
  }
  
  internal var tense: Tense {
    if questions.count > 0 {
      return questions[currentQuestionIndex].1
    }
    else {
      return .infinitivo
    }
  }

  internal var personNumber: PersonNumber {
    if questions.count > 0 {
      return questions[currentQuestionIndex].2
    }
    else {
      return .none
    }
  }
  
  private init() {}
  
  internal func start(region: Region = .spain, difficulty: Difficulty = .easy) {
    questions.removeAll()
    regularArVerbs.shuffle()
    regularIrVerbs.shuffle()
    regularErVerbs.shuffle()
    _ = [regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()]].map {
      questions.append(($0, .presenteDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    irregularPresenteDeIndicativoVerbs.shuffle()
    for _ in 0...6 {
      questions.append((irregularPresenteDeIndicativoVerbs[getIrregularPresenteDeIndicativoVerbsIndex()], .presenteDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    irregularRaizFuturaVerbs.shuffle()
    for _ in 0...6 {
      questions.append((irregularRaizFuturaVerbs[getIrregularRaizFuturaVerbsIndex()], .futuroDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    _ = [regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()]].map {
      questions.append(($0, .futuroDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    irregularParticipioVerbs.shuffle()
    for _ in 0...6 {
      questions.append((irregularParticipioVerbs[getIrregularParticipioVerbsIndex()], .perfectoDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    _ = [regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularArVerbs[getRegularArVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularIrVerbs[getRegularIrVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()], regularErVerbs[getRegularErVerbsIndex()]].map {
      questions.append(($0, .perfectoDeIndicativo, personNumbers[getPersonNumbersIndex()]))
    }
    questions.shuffle()
    score = 0
    currentQuestionIndex = 0
    elapsedTime = 0
    quizState = .inProgress
    timer?.invalidate()
    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(Quiz.eachSecond), userInfo: nil, repeats: true)
    delegate?.questionDidChange(verb: questions[0].0, tense: questions[0].1, personNumber: questions[0].2)
    delegate?.scoreDidChange(newScore: 0)
    delegate?.timeDidChange(newTime: 0)
    delegate?.progressDidChange(current: 0, total: questions.count)
  }
  
  internal func process(proposedAnswer: String) -> ConjugationResult {
    let actualAnswerResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
    switch actualAnswerResult {
    case let .success(actualAnswer):
      let result = ConjugationResult.compare(lhs: proposedAnswer, rhs: actualAnswer)
      if result != .noMatch {
        score += result.rawValue
        delegate?.scoreDidChange(newScore: score)
      }
      if currentQuestionIndex < questions.count - 1 {
        currentQuestionIndex += 1
        delegate?.progressDidChange(current: currentQuestionIndex, total: questions.count)
        delegate?.questionDidChange(verb: questions[currentQuestionIndex].0, tense: questions[currentQuestionIndex].1, personNumber: questions[currentQuestionIndex].2)
      }
      else {
        timer?.invalidate()
        quizState = .finished
        delegate?.quizDidFinish()
      }
      return result
    default:
      fatalError()
    }
  }
  
  @objc func eachSecond() {
    elapsedTime += 1
    delegate?.timeDidChange(newTime: elapsedTime)
  }

  private func getPersonNumbersIndex() -> Int {
    let currentPersonNumbersIndex = personNumbersIndex
    personNumbersIndex += 1
    if personNumbersIndex == personNumbers.count {
      personNumbersIndex = 0
    }
    return currentPersonNumbersIndex
  }
  
  private func getRegularArVerbsIndex() -> Int {
    let currentRegularArVerbsIndex = regularArVerbsIndex
    regularArVerbsIndex += 1
    if regularArVerbsIndex == regularArVerbs.count {
      regularArVerbsIndex = 0
    }
    return currentRegularArVerbsIndex
  }

  private func getRegularIrVerbsIndex() -> Int {
    let currentRegularIrVerbsIndex = regularIrVerbsIndex
    regularIrVerbsIndex += 1
    if regularIrVerbsIndex == regularIrVerbs.count {
      regularIrVerbsIndex = 0
    }
    return currentRegularIrVerbsIndex
  }

  private func getRegularErVerbsIndex() -> Int {
    let currentRegularErVerbsIndex = regularErVerbsIndex
    regularErVerbsIndex += 1
    if regularErVerbsIndex == regularErVerbs.count {
      regularErVerbsIndex = 0
    }
    return currentRegularErVerbsIndex
  }

  private func getIrregularPresenteDeIndicativoVerbsIndex() -> Int {
    let currentIrregularPresenteDeIndicativoVerbsIndex = irregularPresenteDeIndicativoVerbsIndex
    irregularPresenteDeIndicativoVerbsIndex += 1
    if irregularPresenteDeIndicativoVerbsIndex == irregularPresenteDeIndicativoVerbs.count {
      irregularPresenteDeIndicativoVerbsIndex = 0
    }
    return currentIrregularPresenteDeIndicativoVerbsIndex
  }

  private func getIrregularRaizFuturaVerbsIndex() -> Int {
    let currentIrregularRaizFuturaVerbsIndex = irregularRaizFuturaVerbsIndex
    irregularRaizFuturaVerbsIndex += 1
    if irregularRaizFuturaVerbsIndex == irregularRaizFuturaVerbs.count {
      irregularRaizFuturaVerbsIndex = 0
    }
    return currentIrregularRaizFuturaVerbsIndex
  }

  private func getIrregularParticipioVerbsIndex() -> Int {
    let currentIrregularParticipioVerbsIndex = irregularParticipioVerbsIndex
    irregularParticipioVerbsIndex += 1
    if irregularParticipioVerbsIndex == irregularParticipioVerbs.count {
      irregularParticipioVerbsIndex = 0
    }
    return currentIrregularParticipioVerbsIndex
  }
}
