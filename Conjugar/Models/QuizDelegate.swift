//
//  QuizDelegate.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/17/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

protocol QuizDelegate: AnyObject {
  func scoreDidChange(newScore: Int)
  func timeDidChange(newTime: Int)
  func progressDidChange(current: Int, total: Int)
  func questionDidChange(verb: String, tense: DisplayTense, personNumber: DisplayPersonNumber)
  func quizDidFinish()
}
