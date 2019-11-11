//
//  VerbView.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbView: UIView {
  let translation = UILabel()
  let parentOrType = UILabel()
  let participio = UILabel()
  let gerundio = UILabel()
  let raízFutura = UILabel()
  let defectivo = UILabel()
  private let raízFuturaLabel = UILabel()

  let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.enableAutoLayout()
    return tableView
  }()

  required init(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    [translation, parentOrType, participio, gerundio, raízFuturaLabel, raízFutura, defectivo].forEach {
      $0.font = Fonts.label
      $0.textColor = Colors.yellow
      $0.enableAutoLayout()
    }
    raízFuturaLabel.text = "RF:"

    [translation, participio, gerundio, raízFutura, defectivo].forEach {
      $0.isUserInteractionEnabled = true
    }

    [table, translation, parentOrType, participio, gerundio, raízFuturaLabel, raízFutura, defectivo].forEach {
      addSubview($0)
    }

    translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).activate()
    translation.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    parentOrType.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).activate()
    parentOrType.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    participio.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: Layout.defaultSpacing).activate()
    participio.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    gerundio.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: Layout.defaultSpacing).activate()
    gerundio.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    raízFuturaLabel.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing).activate()
    raízFuturaLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()

    raízFutura.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing).activate()
    raízFutura.leadingAnchor.constraint(equalTo: raízFuturaLabel.trailingAnchor, constant: Layout.defaultSpacing).activate()

    defectivo.topAnchor.constraint(equalTo: gerundio.bottomAnchor, constant: Layout.defaultSpacing).activate()
    defectivo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()

    table.topAnchor.constraint(equalTo: raízFuturaLabel.bottomAnchor, constant: Layout.defaultSpacing).activate()
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).activate()
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).activate()
    table.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).activate()
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(TenseCell.self, forCellReuseIdentifier: TenseCell.identifier)
    table.register(ConjugationCell.self, forCellReuseIdentifier: ConjugationCell.identifier)
  }
}
