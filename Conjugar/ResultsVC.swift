//
//  ResultsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ResultsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private var analyticsService: AnalyticsServiceable?
  private var quiz: Quiz?

  var resultsView: ResultsView {
    if let castedView = view as? ResultsView {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: ResultsView.self))
    }
  }

  convenience init(quiz: Quiz, analyticsService: AnalyticsServiceable) {
    self.init()
    self.quiz = quiz
    self.analyticsService = analyticsService
  }

  override func loadView() {
    let resultsView: ResultsView
    resultsView = ResultsView(frame: UIScreen.main.bounds)
    resultsView.setupTable(dataSource: self, delegate: self)
    navigationItem.titleView = UILabel.titleLabel(title: "Results")
    view = resultsView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    resultsView.difficulty.text = quiz.lastDifficulty.rawValue
    resultsView.region.text = quiz.lastRegion.rawValue
    resultsView.score.text = String(quiz.score)
    resultsView.time.text = quiz.elapsedTime.timeString
    analyticsService?.recordVisitation(viewController: "\(ResultsVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    return quiz.questions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let quiz = quiz else {
      fatalError("quiz was nil.")
    }
    guard let cell = resultsView.table.dequeueReusableCell(withIdentifier: ResultCell.identifier) as? ResultCell else {
      fatalError("Could not dequeue \(ResultCell.self).")
    }
    let row = indexPath.row
    let question = quiz.questions[row]
    cell.configure(verb: question.0, tense: question.1, personNumber: question.2, correctAnswer: quiz.correctAnswers[row], proposedAnswer: quiz.proposedAnswers[row])
    return cell
  }
}
