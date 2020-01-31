//
//  VerbUIV.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbUIV: UIView {
  @UsesAutoLayout var translation = UILabel()
  @UsesAutoLayout var parentOrType = UILabel()
  @UsesAutoLayout var participio = UILabel()
  @UsesAutoLayout var gerundio = UILabel()
  @UsesAutoLayout var raízFutura = UILabel()
  @UsesAutoLayout var defectivo = UILabel()
  @UsesAutoLayout private var raízFuturaLabel = UILabel()

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
    [translation, parentOrType, participio, gerundio, raízFuturaLabel, raízFutura, defectivo].forEach {
      $0.font = Fonts.label
      $0.textColor = Colors.yellow
    }
    raízFuturaLabel.text = "RF:"

    [translation, participio, gerundio, raízFutura, defectivo].forEach {
      $0.isUserInteractionEnabled = true
    }

    [table, translation, parentOrType, participio, gerundio, raízFuturaLabel, raízFutura, defectivo].forEach {
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      translation.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      parentOrType.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing),
      parentOrType.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      participio.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: Layout.defaultSpacing),
      participio.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      gerundio.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: Layout.defaultSpacing),
      gerundio.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      raízFuturaLabel.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing),
      raízFuturaLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),

      raízFutura.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing),
      raízFutura.leadingAnchor.constraint(equalTo: raízFuturaLabel.trailingAnchor, constant: Layout.defaultSpacing),

      defectivo.topAnchor.constraint(equalTo: gerundio.bottomAnchor, constant: Layout.defaultSpacing),
      defectivo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      table.topAnchor.constraint(equalTo: raízFuturaLabel.bottomAnchor, constant: Layout.defaultSpacing),
      table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      table.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing)
    ])
  }

  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(TenseCell.self, forCellReuseIdentifier: TenseCell.identifier)
    table.register(ConjugationCell.self, forCellReuseIdentifier: ConjugationCell.identifier)
  }
}
