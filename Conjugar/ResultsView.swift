//
//  ResultsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 8/7/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class ResultsView: UIView {
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.rowHeight = 120
    return tableView
  } ()

  internal let difficulty: UILabel = { return UILabel() } ()
  internal let region: UILabel = { return UILabel() } ()
  internal let score: UILabel = { return UILabel() } ()
  internal let time: UILabel = { return UILabel() } ()
  internal let scoreLabel: UILabel = { return UILabel() } ()
  internal let timeLabel: UILabel = { return UILabel() } ()

  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    _ = [difficulty, region, score, time, scoreLabel, timeLabel].map {
      $0.textColor = Colors.yellow
      $0.font = Fonts.label
    }
    _ = [table, difficulty, region, score, time, scoreLabel, timeLabel].map {
      guard let view = $0 as? UIView else { fatalError("Could not cast UIView to UIView.") }
      view.enableAutoLayout()
      addSubview(view)
    }
    _ = [(scoreLabel, "Score:"), (timeLabel, "Time:")].map {
      $0.0.text = $0.1
    }
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).activate()
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    table.bottomAnchor.constraint(equalTo: difficulty.topAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    
    difficulty.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    difficulty.bottomAnchor.constraint(equalTo: score.topAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    
    region.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    region.bottomAnchor.constraint(equalTo: time.topAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    
    scoreLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    if #available(iOS 11.0, *) {
      scoreLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    } else {
      scoreLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
    
    timeLabel.trailingAnchor.constraint(equalTo: time.leadingAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    if #available(iOS 11.0, *) {
      timeLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    } else {
      timeLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
    
    time.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    if #available(iOS 11.0, *) {
      time.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    } else {
      time.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
    
    score.leadingAnchor.constraint(equalTo: scoreLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()
    if #available(iOS 11.0, *) {
      score.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    } else {
      score.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
    
    time.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    if #available(iOS 11.0, *) {
      time.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    } else {
      time.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
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
