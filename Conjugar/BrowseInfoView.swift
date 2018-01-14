//
//  BrowseInfoView.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/30/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class BrowseInfoView: UIView {
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.enableAutoLayout()
    return tableView
  } ()
  
  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Filter Tenses by Difficulty"
    label.textAlignment = .center
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.enableAutoLayout()
    return label
  } ()
  
  internal let difficultyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["E", "E & M", "E, M, & D"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.enableAutoLayout()
    control.tintColor = Colors.red
    return control
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    _ = [table, difficultyLabel, difficultyControl].map {
      addSubview($0)
    }
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).activate()
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    table.bottomAnchor.constraint(equalTo: difficultyControl.topAnchor, constant: Layout.defaultSpacing * -1.0).activate()
    
    difficultyControl.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    difficultyControl.bottomAnchor.constraint(equalTo: difficultyLabel.topAnchor, constant: Layout.defaultSpacing * -1.0).activate()

    difficultyLabel.centerXAnchor.constraint(equalTo: centerXAnchor).activate()
    difficultyLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
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

