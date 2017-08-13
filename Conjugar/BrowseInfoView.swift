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
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  } ()
  
  private let difficultyLabel: UILabel = {
    let label = UILabel()
    label.text = "Filter Tenses by Difficulty"
    label.textAlignment = .center
    label.font = Fonts.smallBody
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  } ()
  
  internal let difficultyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["E", "E & M", "E, M, & D"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.translatesAutoresizingMaskIntoConstraints = false
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
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    table.bottomAnchor.constraint(equalTo: difficultyControl.topAnchor, constant: Layout.defaultSpacing * -1.0).isActive = true
    
    difficultyControl.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    difficultyControl.bottomAnchor.constraint(equalTo: difficultyLabel.topAnchor, constant: Layout.defaultSpacing * -1.0).isActive = true

    difficultyLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    if #available(iOS 11.0, *) {
      difficultyLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).isActive = true
    } else {
      difficultyLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).isActive = true
    }
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

