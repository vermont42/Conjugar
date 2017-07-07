//
//  ResultsViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/25/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var table: UITableView!
  @IBOutlet var difficultyLabel: UILabel!
  @IBOutlet var regionLabel: UILabel!
  @IBOutlet var scoreLabel: UILabel!
  @IBOutlet var timeLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    table.delegate = self
    table.dataSource = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    difficultyLabel.text = Quiz.shared.lastDifficulty.rawValue
    regionLabel.text = Quiz.shared.lastRegion.rawValue
    scoreLabel.text = String(Quiz.shared.score)
    timeLabel.text = Quiz.shared.elapsedTime.timeString
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return Quiz.shared.questions.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = table.dequeueReusableCell(withIdentifier: "ResultCell") as! ResultCell
    let row = indexPath.row
    let question = Quiz.shared.questions[row]
    cell.configure(verb: question.0, tense: question.1, personNumber: question.2, correctAnswer: Quiz.shared.correctAnswers[row], proposedAnswer: Quiz.shared.proposedAnswers[row])
    return cell
  }
}