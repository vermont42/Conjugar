//
//  BrowseInfoUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/30/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseInfoUIV: UIView {
  let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.enableAutoLayout()
    return tableView
  }()

  let difficultyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["E", "E & M", "E, M, & D"])
    control.selectedSegmentIndex = 0
    control.enableAutoLayout()
    control.yellowfyText()
    return control
  }()

  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Filter Tenses by Difficulty"
    label.textAlignment = .center
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [table, difficultyLabel, difficultyControl].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: difficultyControl.topAnchor, constant: Layout.defaultSpacing * -1.0),

      difficultyControl.centerXAnchor.constraint(equalTo: centerXAnchor),
      difficultyControl.bottomAnchor.constraint(equalTo: difficultyLabel.topAnchor, constant: Layout.defaultSpacing * -1.0),

      difficultyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      difficultyLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(InfoCell.self, forCellReuseIdentifier: InfoCell.identifier)
  }

  func reloadTableData() {
    table.reloadData()
    table.setContentOffset(CGPoint.zero, animated: false)
  }
}
