//
//  LastQuizResult.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// The results of the last quiz round the learner saw, which the Quiz tab shows. It is kept on the
/// device beside the practice record and sent nowhere.
struct LastQuizResult: Codable, Equatable {
  /// What was quizzed. A kind, not a title, so that the tab names it in the app's current
  /// language.
  enum Kind: String, Codable {
    case allVerbs
    case collection
    case custom
    case mistakes
    /// A verb model's practice alone, its subject the class number.
    case modelAlone
    /// A verb model's practice mixed with the known models, its subject the class number.
    case modelMixed
    case myVerbs
    case practiceSet
    case recognition
    case review
    case verbEssentials
    case verbPage
  }

  static let storageKey = "lastQuizResult"

  let kind: Kind
  /// The infinitive of a verb page's quiz, the key of a collection's, or a model practice's class
  /// number.
  let subject: String?
  /// Nil for Review, My Mistakes, and a model's practice, which do not ask by level.
  let levelKey: String?
  let score: Int
  let correctCount: Int
  let secondAttemptCount: Int
  let questionCount: Int
  let date: Date

  var level: QuizLevel? {
    levelKey.flatMap(QuizLevel.init(rawValue:))
  }

  init(
    kind: Kind,
    subject: String? = nil,
    level: QuizLevel?,
    score: Int,
    correctCount: Int,
    secondAttemptCount: Int,
    questionCount: Int,
    date: Date
  ) {
    self.kind = kind
    self.subject = subject
    levelKey = level?.rawValue
    self.score = score
    self.correctCount = correctCount
    self.secondAttemptCount = secondAttemptCount
    self.questionCount = questionCount
    self.date = date
  }

  /// A Ten More round's results replace its first round's, so the tab shows the session so far.
  init(quiz: Quiz, date: Date = .now) {
    let kind = Kind(scope: quiz.scope)
    let subject: String?
    switch kind {
    case .collection:
      subject = quiz.scope.collectionKey
    case .verbPage:
      subject = quiz.scope.verbs?.first
    case .modelAlone, .modelMixed:
      subject = quiz.scope.modelPractice?.classNumber
    case .allVerbs, .custom, .mistakes, .myVerbs, .practiceSet, .recognition, .review, .verbEssentials:
      subject = nil
    }
    self.init(
      kind: kind,
      subject: subject,
      level: quiz.scope.recordSession == nil && quiz.scope.modelPractice == nil ? quiz.lastLevel : nil,
      score: quiz.score,
      correctCount: quiz.correctCount,
      secondAttemptCount: quiz.secondAttemptCount,
      questionCount: quiz.questionCount,
      date: date
    )
  }

  init?(json: String) {
    guard let data = json.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(LastQuizResult.self, from: data) else {
      return nil
    }
    self = decoded
  }

  var json: String? {
    (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
  }

  /// The quiz's name on the tab: "All Verbs", "-go Verbs", "tener".
  var title: String {
    switch kind {
    case .allVerbs:
      return L.Quiz.allVerbs
    case .collection:
      return subject.flatMap(VerbCollection.init(key:))?.title ?? L.Quiz.allVerbs
    case .custom:
      return L.CustomQuiz.title
    case .mistakes:
      return QuizRecordSession.mistakes.title
    case .modelAlone:
      return modelSession(.alone)?.title ?? L.ModelPractice.title
    case .modelMixed:
      return modelSession(.mixed)?.title ?? L.ModelPractice.title
    case .myVerbs:
      return L.MyVerbs.title
    case .practiceSet:
      return L.PracticeSet.title
    case .recognition:
      return L.Recognition.title
    case .review:
      return QuizRecordSession.review.title
    case .verbEssentials:
      return L.VerbEssentials.title
    case .verbPage:
      return subject.map { ReflexivePronoun.citationForm(of: $0) } ?? L.Quiz.allVerbs
    }
  }

  private func modelSession(_ mode: ModelPracticeSession.Mode) -> ModelPracticeSession? {
    guard let subject, ModelPracticeGroup.group(subject) != nil else {
      return nil
    }
    return ModelPracticeSession(classNumber: subject, mode: mode)
  }
}

extension LastQuizResult.Kind {
  /// A custom quiz over a collection counts as custom, since the learner chose it in the editor.
  init(scope: QuizScope) {
    if let session = scope.recordSession {
      switch session {
      case .review:
        self = .review
      case .mistakes:
        self = .mistakes
      }
    } else if let session = scope.modelPractice {
      switch session.mode {
      case .alone:
        self = .modelAlone
      case .mixed:
        self = .modelMixed
      }
    } else if scope.isVerbEssentials {
      self = .verbEssentials
    } else if scope.isRecognition {
      self = .recognition
    } else if scope.isPracticeSet {
      self = .practiceSet
    } else if scope.custom != nil {
      self = .custom
    } else if scope.source == .verbPage {
      self = .verbPage
    } else if scope.collectionKey != nil {
      self = .collection
    } else if scope.verbs != nil {
      self = .myVerbs
    } else {
      self = .allVerbs
    }
  }
}
