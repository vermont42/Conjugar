//
//  QuizDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

protocol QuizDelegate: class {
  func scoreDidChange(newScore: Int)
  func timeDidChange(newTime: Int)
  func progressDidChange(current: Int, total: Int)
  func questionDidChange(verb: String, tense: Tense, personNumber: PersonNumber)
  func quizDidFinish()
}
