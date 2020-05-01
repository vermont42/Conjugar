//
//  ResultsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ResultsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var resultsView: ResultsUIV {
    if let castedView = view as? ResultsUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: ResultsUIV.self))
    }
  }

  override func loadView() {
    let resultsView: ResultsUIV
    resultsView = ResultsUIV(frame: UIScreen.main.bounds)
    resultsView.setupTable(dataSource: self, delegate: self)
    navigationItem.titleView = UILabel.titleLabel(title: Localizations.Results.title)
    view = resultsView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    resultsView.difficulty.text = Current.quiz.lastDifficulty.rawValue
    resultsView.region.text = Current.quiz.lastRegion.rawValue
    resultsView.score.text = String(Current.quiz.score)
    resultsView.time.text = Current.quiz.elapsedTime.timeString
    Current.analytics.recordVisitation(viewController: "\(ResultsVC.self)")
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Current.quiz.questions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = resultsView.table.dequeueReusableCell(withIdentifier: ResultCell.identifier) as? ResultCell else {
      fatalError("Could not dequeue \(ResultCell.self).")
    }
    let row = indexPath.row
    let question = Current.quiz.questions[row]
    cell.configure(verb: question.0, tense: question.1, personNumber: question.2, correctAnswer: Current.quiz.correctAnswers[row], proposedAnswer: Current.quiz.proposedAnswers[row])
    return cell
  }
}
