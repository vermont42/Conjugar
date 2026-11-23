//
//  LiveActivities.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

/// Starts, updates, and ends the quiz Live Activity, which is one for the whole app. Quiz.swift
/// drives it through `Current.liveActivities`, and the widget extension only renders
/// `QuizActivityAttributes` (see QuizLiveActivity). `LiveActivitiesReal` uses ActivityKit, and
/// `LiveActivitiesSpy` records under unit tests. The simulator's test host grants real
/// activities, so tests that used ActivityKit would start hundreds of them and meet the
/// system's limit partway through a run.
protocol LiveActivities {
  /// Ends any activity already showing, then starts the quiz's. Does nothing when the learner
  /// has turned Live Activities off.
  func start(difficulty: String, totalQuestions: Int, state: QuizActivityAttributes.ContentState)
  func update(_ state: QuizActivityAttributes.ContentState)
  func end(_ state: QuizActivityAttributes.ContentState)
  /// Ends every quiz activity, which a launch does, since none survives its quiz.
  func endAll()
}
