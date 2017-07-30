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
  private var safeBottomInset: CGFloat = 0.0
  
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  private func commonInit() {
    addSubview(table)
    let defaultSpacing: CGFloat = 8.0
    table.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    if #available(iOS 11.0, *) {
      table.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * defaultSpacing).isActive = true
    } else { // TODO: Delete this logic, safeBottomInset, and the associated init when iOS 11 goes live.
      table.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -1.0 * (safeBottomInset + defaultSpacing)).isActive = true
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
    table.register(InfoCell.self, forCellReuseIdentifier: InfoCell.identifier)
  }
  
  func reloadTableData() {
    table.reloadData()
    table.setContentOffset(CGPoint.zero, animated: false)
  }
}

