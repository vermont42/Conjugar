//
//  ModelUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/5/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import UIKit

class ModelUIV: UIView {
  @UsesAutoLayout var details = UILabel()
  @UsesAutoLayout var gloss = UILabel()

  @UsesAutoLayout
  var table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    return tableView
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [details, gloss].forEach {
      $0.font = Fonts.label
      $0.textColor = Colors.yellow
      $0.adjustsFontSizeToFitWidth = true
    }

    [table, details, gloss].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      details.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      details.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      details.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

      gloss.topAnchor.constraint(equalTo: details.bottomAnchor, constant: Layout.defaultSpacing),
      gloss.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      gloss.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

      table.topAnchor.constraint(equalTo: gloss.bottomAnchor, constant: Layout.defaultSpacing),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(VerbCell.self, forCellReuseIdentifier: VerbCell.identifier)
  }
}
