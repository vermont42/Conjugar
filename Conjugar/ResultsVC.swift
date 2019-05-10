//
//  ResultsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ResultsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  private let analyticsService: AnalyticsServiceable
  private let quiz: Quiz

  var resultsView: ResultsView {
    if let castedView = view as? ResultsView {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: ResultsView.self))
    }
  }

  init(quiz: Quiz, analyticsService: AnalyticsServiceable) {
    self.quiz = quiz
    self.analyticsService = analyticsService
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    UIViewController.fatalErrorNotImplemented()
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
    resultsView.difficulty.text = quiz.lastDifficulty.rawValue
    resultsView.region.text = quiz.lastRegion.rawValue
    resultsView.score.text = String(quiz.score)
    resultsView.time.text = quiz.elapsedTime.timeString
    analyticsService.recordVisitation(viewController: "\(ResultsVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return quiz.questions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = resultsView.table.dequeueReusableCell(withIdentifier: ResultCell.identifier) as? ResultCell else {
      fatalError("Could not dequeue \(ResultCell.self).")
    }
    let row = indexPath.row
    let question = quiz.questions[row]
    cell.configure(verb: question.0, tense: question.1, personNumber: question.2, correctAnswer: quiz.correctAnswers[row], proposedAnswer: quiz.proposedAnswers[row])
    return cell
  }
}
