//
//  BrowseVerbsUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/16/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class BrowseVerbsUIV: UIView {
  @UsesAutoLayout
  var table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    return tableView
  }()

  @UsesAutoLayout
  var filterControl: UISegmentedControl = {
    let control = UISegmentedControl(items: [
      Localizations.BrowseVerbs.Filter.irregular,
      Localizations.BrowseVerbs.Filter.regular,
      Localizations.BrowseVerbs.Filter.both
    ])
    control.selectedSegmentIndex = 0
    control.yellowfyText()
    return control
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [table, filterControl].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: filterControl.topAnchor, constant: -1.0 * Layout.defaultSpacing),
      filterControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      filterControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      filterControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(VerbCell.self, forCellReuseIdentifier: VerbCell.identifier)
  }

  func reloadTableData() {
    table.reloadData()
    table.setContentOffset(CGPoint.zero, animated: false)
  }
}
