//
//  ResultsVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class ResultsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var resultsView: ResultsView {
    return view as! ResultsView
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
    resultsView.difficulty.text = Quiz.shared.lastDifficulty.rawValue
    resultsView.region.text = Quiz.shared.lastRegion.rawValue
    resultsView.score.text = String(Quiz.shared.score)
    resultsView.time.text = Quiz.shared.elapsedTime.timeString
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Quiz.shared.questions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = resultsView.table.dequeueReusableCell(withIdentifier: ResultCell.identifier) as! ResultCell
    let row = indexPath.row
    let question = Quiz.shared.questions[row]
    cell.configure(verb: question.0, tense: question.1, personNumber: question.2, correctAnswer: Quiz.shared.correctAnswers[row], proposedAnswer: Quiz.shared.proposedAnswers[row])
    return cell
  }
}

