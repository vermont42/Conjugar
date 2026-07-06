//
//  BrowseModelsUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class BrowseModelsUIV: UIView {
  @UsesAutoLayout
  var table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    return tableView
  }()

  @UsesAutoLayout
  var sortControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ModelSort.allCases.map { $0.localizedDisplayName })
    control.selectedSegmentIndex = 0
    control.yellowfyText()
    return control
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [table, sortControl].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: sortControl.topAnchor, constant: -1.0 * Layout.defaultSpacing),
      sortControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      sortControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      sortControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(ModelCell.self, forCellReuseIdentifier: ModelCell.identifier)
  }

  func reloadTableData() {
    table.reloadData()
    table.setContentOffset(CGPoint.zero, animated: false)
  }
}
