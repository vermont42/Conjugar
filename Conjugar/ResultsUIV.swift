//
//  ResultsUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/7/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ResultsUIV: UIView {
  let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.rowHeight = 120
    return tableView
  }()

  let difficulty = UILabel()
  let region = UILabel()
  let score = UILabel()
  let time = UILabel()
  let scoreLabel = UILabel()
  let timeLabel = UILabel()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [difficulty, region, score, time, scoreLabel, timeLabel].forEach {
      $0.textColor = Colors.yellow
      $0.font = Fonts.label
    }
    [table, difficulty, region, score, time, scoreLabel, timeLabel].forEach {
      $0.enableAutoLayout()
      addSubview($0)
    }
    [(scoreLabel, "Score:"), (timeLabel, "Time:")].forEach {
      $0.0.text = $0.1
    }

    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: difficulty.topAnchor, constant: Layout.defaultSpacing * -1.0),

      difficulty.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      difficulty.bottomAnchor.constraint(equalTo: score.topAnchor, constant: Layout.defaultSpacing * -1.0),

      region.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      region.bottomAnchor.constraint(equalTo: time.topAnchor, constant: Layout.defaultSpacing * -1.0),

      scoreLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      scoreLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing),

      timeLabel.trailingAnchor.constraint(equalTo: time.leadingAnchor, constant: Layout.defaultSpacing * -1.0),
      timeLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing),

      time.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      time.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing),

      score.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: Layout.defaultSpacing),
      score.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing),

      time.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      time.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(ResultCell.self, forCellReuseIdentifier: ResultCell.identifier)
  }

  func reloadTableData() {
    table.reloadData()
    table.setContentOffset(CGPoint.zero, animated: false)
  }
}
