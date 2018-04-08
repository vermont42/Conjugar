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
  private(set) var lastRegion: Region = .spain
  private(set) var lastDifficulty: Difficulty = .moderate
  private(set) var proposedAnswers: [String] = []
  private(set) var correctAnswers: [String] = []
  private(set) var questions: [(String, Tense, PersonNumber)] = []
  private var regularArVerbs = VerbFamilies.regularArVerbs
  private var regularArVerbsIndex = 0
  private var regularIrVerbs = VerbFamilies.regularIrVerbs
  private var regularIrVerbsIndex = 0
  private var regularErVerbs = VerbFamilies.regularErVerbs
  private var regularErVerbsIndex = 0
  private var allRegularVerbs = VerbFamilies.allRegularVerbs
  private var allRegularVerbsIndex = 0
  private var irregularPresenteDeIndicativoVerbs = VerbFamilies.irregularPresenteDeIndicativoVerbs
  private var irregularPresenteDeIndicativoVerbsIndex = 0
  private var irregularPreteritoVerbs = VerbFamilies.irregularPreteritoVerbs
  private var irregularPreteritoVerbsIndex = 0
  private var irregularRaizFuturaVerbs = VerbFamilies.irregularRaizFuturaVerbs
  private var irregularRaizFuturaVerbsIndex = 0
  private var irregularParticipioVerbs = VerbFamilies.irregularParticipioVerbs
  private var irregularParticipioVerbsIndex = 0
  private var irregularImperfectoVerbs = VerbFamilies.irregularImperfectivoVerbs
  private var irregularImperfectoVerbsIndex = 0
  private var irregularPresenteDeSubjuntivoVerbs = VerbFamilies.irregularPresenteDeSubjuntivoVerbs
  private var irregularPresenteDeSubjuntivoVerbsIndex = 0
  private var irregularGerundioVerbs = VerbFamilies.irregularGerundioVerbs
  private var irregularGerundioVerbsIndex = 0
  private var irregularTuImperativoVerbs = VerbFamilies.irregularTuImperativoVerbs
  private var irregularTuImperativoVerbsIndex = 0
  private var irregularVosImperativoVerbs = VerbFamilies.irregularVosImperativoVerbs
  private var irregularVosImperativoVerbsIndex = 0
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

  internal var currentPersonNumber: PersonNumber {
    if questions.count > 0 {
      return questions[currentQuestionIndex].2
    }
    else {
      return .none
    }
  }
  
  private init() {}
  
  internal func start() {
    lastRegion = SettingsManager.getRegion()
    lastDifficulty = SettingsManager.getDifficulty()
    questions.removeAll()
    proposedAnswers.removeAll()
    correctAnswers.removeAll()
    regularArVerbs.shuffle()
    regularIrVerbs.shuffle()
    regularErVerbs.shuffle()
    allRegularVerbs.shuffle()
    irregularPresenteDeIndicativoVerbs.shuffle()
    irregularPreteritoVerbs.shuffle()
    irregularRaizFuturaVerbs.shuffle()
    irregularParticipioVerbs.shuffle()
    irregularImperfectoVerbs.shuffle()
    irregularPresenteDeSubjuntivoVerbs.shuffle()
    irregularGerundioVerbs.shuffle()
    irregularTuImperativoVerbs.shuffle()
    irregularVosImperativoVerbs.shuffle()

    switch lastDifficulty {
    case .easy:
//      questions.append((allRegularVerb, .presenteDeIndicativo, personNumber()))
      [regularArVerb, regularArVerb, regularArVerb, regularIrVerb, regularIrVerb, regularIrVerb, regularErVerb, regularErVerb, regularErVerb].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...8 {
        questions.append((irregularPresenteDeIndicativoVerb, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...7 {
        questions.append((irregularRaizFuturaVerb, .futuroDeIndicativo, personNumber()))
      }
      [regularArVerb, regularArVerb, regularArVerb, regularIrVerb, regularIrVerb, regularErVerb, regularErVerb].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...7 {
        questions.append((irregularPreteritoVerb, .preterito, personNumber()))
      }
      for _ in 0...8 {
        questions.append((allRegularVerb, .preterito, personNumber()))
      }
    case .moderate:
      [regularArVerb, regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...3 {
        questions.append((irregularPresenteDeIndicativoVerb, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularRaizFuturaVerb, .futuroDeIndicativo, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularRaizFuturaVerb, .condicional, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .condicional, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularParticipioVerb, .perfectoDeIndicativo, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .perfectoDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularImperfectoVerb, .imperfectoDeIndicativo, personNumber()))
      }
      [allRegularVerb, allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .imperfectoDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPreteritoVerb, .preterito, personNumber()))
      }
      [regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .preterito, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPresenteDeSubjuntivoVerb, .presenteDeSubjuntivo, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .presenteDeSubjuntivo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularGerundioVerb, .gerundio, .none))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .gerundio, .none))
      }
      for _ in 0...1 {
        if SettingsManager.getSecondSingularQuiz() == .tu {
          questions.append((irregularTuImperativoVerb, .imperativoPositivo, .secondSingular))
        }
        else {
          questions.append((irregularVosImperativoVerb, .imperativoPositivo, .secondSingularVos))
        }
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .imperativoPositivo, personNumber(skipYo: true, skipTu: true)))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .imperativoNegativo, personNumber(skipYo: true, skipTu: true)))
      }
    case .difficult:
      for _ in 0...1 {
        questions.append((irregularGerundioVerb, .gerundio, .none))
      }
      [regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .gerundio, .none))
      }
      [regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPresenteDeIndicativoVerb, .presenteDeIndicativo, personNumber()))
      }
      for _ in 0...2 {
        questions.append((irregularPreteritoVerb, .preterito, personNumber()))
      }
      [regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .preterito, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularImperfectoVerb, .imperfectoDeIndicativo, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .imperfectoDeIndicativo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((irregularRaizFuturaVerb, .futuroDeIndicativo, personNumber()))
      }
      [allRegularVerb, allRegularVerb].forEach {
        questions.append(($0, .futuroDeIndicativo, personNumber()))
      }
      for _ in 0...1 {
        questions.append((allRegularVerb, .condicional, personNumber()))
      }
      questions.append((irregularRaizFuturaVerb, .condicional, personNumber()))
      for _ in 0...2 {
        questions.append((irregularPresenteDeSubjuntivoVerb, .presenteDeSubjuntivo, personNumber()))
      }
      [regularArVerb, regularIrVerb, regularErVerb].forEach {
        questions.append(($0, .presenteDeSubjuntivo, personNumber()))
      }
      questions.append((irregularPreteritoVerb, .imperfectoDeSubjuntivo1, personNumber()))
      questions.append((allRegularVerb, .imperfectoDeSubjuntivo2, personNumber()))
      questions.append((irregularPreteritoVerb, .futuroDeSubjuntivo, personNumber()))
      questions.append((allRegularVerb, .futuroDeSubjuntivo, personNumber()))
      if SettingsManager.getSecondSingularQuiz() == .tu {
        questions.append((irregularTuImperativoVerb, .imperativoPositivo, .secondSingular))
      }
      else {
        questions.append((irregularVosImperativoVerb, .imperativoPositivo, .secondSingularVos))
      }
      questions.append((allRegularVerb, .imperativoPositivo, personNumber(skipYo: true, skipTu: true)))
      questions.append((allRegularVerb, .imperativoNegativo, personNumber(skipYo: true, skipTu: true)))
      [.perfectoDeIndicativo, .preteritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto, .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1, .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo].forEach {
        questions.append((regularOrIrregularParticipioVerb, $0, personNumber()))
      }
    }
    questions = questions.shuffled().shuffled()
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
  
  private var regularOrIrregularParticipioVerb: String {
    let diceRoll = Int(arc4random_uniform(2))
    if diceRoll == 0 {
      return allRegularVerb
    }
    else /* diceRoll == 1 */ {
      return irregularParticipioVerb
    }
  }
  
  internal func process(proposedAnswer: String) -> (ConjugationResult, String?) {
    let correctAnswerResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: tense, personNumber: currentPersonNumber)
    switch correctAnswerResult {
    case let .success(correctAnswer):
      let result = ConjugationResult.compare(lhs: proposedAnswer, rhs: correctAnswer)
      proposedAnswers.append(proposedAnswer)
      correctAnswers.append(correctAnswer)
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
        score = Int(Double(score) * lastRegion.scoreModifier * lastDifficulty.scoreModifier)
        timer?.invalidate()
        quizState = .finished
        delegate?.quizDidFinish()
        GameCenterManager.shared.reportScore(score)
      }
      if result == .totalMatch {
        return (result, nil)
      }
      else {
        return (result, correctAnswer)
      }
    default:
      fatalError()
    }
  }
  
  @objc func eachSecond() {
    elapsedTime += 1
    delegate?.timeDidChange(newTime: elapsedTime)
  }

  private func personNumber(skipYo: Bool = false, skipTu: Bool = false) -> PersonNumber {
    personNumbersIndex += 1
    if personNumbersIndex == personNumbers.count {
      personNumbersIndex = 0
    }
    else if personNumbers[personNumbersIndex].pronoun == PersonNumber.secondPlural.pronoun && lastRegion == .latinAmerica {
      personNumbersIndex += 1
    }
    
    if (personNumbers[personNumbersIndex].pronoun == PersonNumber.firstSingular.pronoun && skipYo) || (personNumbers[personNumbersIndex].pronoun == PersonNumber.secondSingular.pronoun && skipTu) {
      return personNumber(skipYo: skipYo, skipTu: skipTu)
    }
    else {
      return personNumbers[personNumbersIndex]
    }
  }
  
  private var regularArVerb: String {
    regularArVerbsIndex += 1
    if regularArVerbsIndex == regularArVerbs.count {
      regularArVerbsIndex = 0
    }
    return regularArVerbs[regularArVerbsIndex]
  }

  private var regularIrVerb: String {
    regularIrVerbsIndex += 1
    if regularIrVerbsIndex == regularIrVerbs.count {
      regularIrVerbsIndex = 0
    }
    return regularIrVerbs[regularIrVerbsIndex]
  }

  private var regularErVerb: String {
    regularErVerbsIndex += 1
    if regularErVerbsIndex == regularErVerbs.count {
      regularErVerbsIndex = 0
    }
    return regularErVerbs[regularErVerbsIndex]
  }
  
  private var allRegularVerb: String {
    allRegularVerbsIndex += 1
    if allRegularVerbsIndex == allRegularVerbs.count {
      allRegularVerbsIndex = 0
    }
    return allRegularVerbs[allRegularVerbsIndex]
  }
  
  private var irregularPresenteDeIndicativoVerb: String {
    irregularPresenteDeIndicativoVerbsIndex += 1
    if irregularPresenteDeIndicativoVerbsIndex == irregularPresenteDeIndicativoVerbs.count {
      irregularPresenteDeIndicativoVerbsIndex = 0
    }
    return irregularPresenteDeIndicativoVerbs[irregularPresenteDeIndicativoVerbsIndex]
  }

  private var irregularRaizFuturaVerb: String {
    irregularRaizFuturaVerbsIndex += 1
    if irregularRaizFuturaVerbsIndex == irregularRaizFuturaVerbs.count {
      irregularRaizFuturaVerbsIndex = 0
    }
    return irregularRaizFuturaVerbs[irregularRaizFuturaVerbsIndex]
  }

  private var irregularParticipioVerb: String {
    irregularParticipioVerbsIndex += 1
    if irregularParticipioVerbsIndex == irregularParticipioVerbs.count {
      irregularParticipioVerbsIndex = 0
    }
    return irregularParticipioVerbs[irregularParticipioVerbsIndex]
  }
  
  private var irregularImperfectoVerb: String {
    irregularImperfectoVerbsIndex += 1
    if irregularImperfectoVerbsIndex == irregularImperfectoVerbs.count {
      irregularImperfectoVerbsIndex = 0
    }
    return irregularImperfectoVerbs[irregularImperfectoVerbsIndex]
  }
  
  private var irregularPreteritoVerb: String {
    irregularPreteritoVerbsIndex += 1
    if irregularPreteritoVerbsIndex == irregularPreteritoVerbs.count {
      irregularPreteritoVerbsIndex = 0
    }
    return irregularPreteritoVerbs[irregularPreteritoVerbsIndex]
  }
  
  private var irregularPresenteDeSubjuntivoVerb: String {
    irregularPresenteDeSubjuntivoVerbsIndex += 1
    if irregularPresenteDeSubjuntivoVerbsIndex == irregularPresenteDeSubjuntivoVerbs.count {
      irregularPresenteDeSubjuntivoVerbsIndex = 0
    }
    return irregularPresenteDeSubjuntivoVerbs[irregularPresenteDeSubjuntivoVerbsIndex]
  }
  
  private var irregularGerundioVerb: String {
    irregularGerundioVerbsIndex += 1
    if irregularGerundioVerbsIndex == irregularGerundioVerbs.count {
      irregularGerundioVerbsIndex = 0
    }
    return irregularGerundioVerbs[irregularGerundioVerbsIndex]
  }
  
  private var irregularTuImperativoVerb: String {
    irregularTuImperativoVerbsIndex += 1
    if irregularTuImperativoVerbsIndex == irregularTuImperativoVerbs.count {
      irregularTuImperativoVerbsIndex = 0
    }
    return irregularTuImperativoVerbs[irregularTuImperativoVerbsIndex]
  }

  private var irregularVosImperativoVerb: String {
    irregularVosImperativoVerbsIndex += 1
    if irregularVosImperativoVerbsIndex == irregularVosImperativoVerbs.count {
      irregularVosImperativoVerbsIndex = 0
    }
    return irregularVosImperativoVerbs[irregularVosImperativoVerbsIndex]
  }
}
