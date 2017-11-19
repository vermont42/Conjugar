//
//  BrowseVerbsView.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/16/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class BrowseVerbsView: UIView {
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.enableAutoLayout()
    return tableView
  } ()
  
  internal let filterControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Irregular", "Regular", "Both"])
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
    addSubview(table)
    addSubview(filterControl)
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).activate()
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    table.bottomAnchor.constraint(equalTo: filterControl.topAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    filterControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    filterControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    if #available(iOS 11.0, *) {
      filterControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
    }
    else {
      filterControl.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).activate()
    }
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

