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
  private var safeBottomInset: CGFloat = 0.0
  
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  } ()
  
  internal let filterControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Irregular", "Regular", "Both"])
    control.selectedSegmentIndex = 0
    control.backgroundColor = Colors.black
    control.translatesAutoresizingMaskIntoConstraints = false
    control.tintColor = Colors.red
    return control
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  private func commonInit() {
    addSubview(table)
    addSubview(filterControl)
    let defaultSpacing: CGFloat = 8.0
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    table.bottomAnchor.constraint(equalTo: filterControl.topAnchor, constant: -1.0 * defaultSpacing).isActive = true
    filterControl.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    filterControl.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    if #available(iOS 11.0, *) {
      filterControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * defaultSpacing).isActive = true
    } else { // TODO: Delete this logic, safeBottomInset, and the associated init when iOS 11 goes live.
      filterControl.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -1.0 * (safeBottomInset + defaultSpacing)).isActive = true
    }
  }
  
  convenience init(frame: CGRect, safeBottomInset: CGFloat) {
    self.init(frame: frame)
    self.safeBottomInset = safeBottomInset
    commonInit()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
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

