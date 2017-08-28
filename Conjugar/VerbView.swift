//
//  VerbView.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/18/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class VerbView: UIView {
  internal let translation: UILabel = { return UILabel() } ()
  internal let parentOrType: UILabel = { return UILabel() } ()
  private let participioLabel: UILabel = { return UILabel() } ()
  internal let participio: UILabel = { return UILabel() } ()
  private let gerundioLabel: UILabel = { return UILabel() } ()
  internal let gerundio: UILabel = { return UILabel() } ()
  private let raizFuturaLabel: UILabel = { return UILabel() } ()
  internal let raizFutura: UILabel = { return UILabel() } ()
  internal let defectivo: UILabel = { return UILabel() } ()
  
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  } ()
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    _ = [translation, parentOrType, participioLabel, participio, gerundioLabel, gerundio, raizFuturaLabel, raizFutura, defectivo].map {
      $0.font = Fonts.label
      $0.textColor = Colors.yellow
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    _ = [(participioLabel, "PP:"), (gerundioLabel, "Ger:"), (raizFuturaLabel, "RF:")].map {
      $0.0.text = $0.1
    }
    
    _ = [translation, participio, gerundio, raizFutura, defectivo].map {
      $0.isUserInteractionEnabled = true
    }
    
    _ = [table, translation, parentOrType, participioLabel, participio, gerundioLabel, gerundio, raizFuturaLabel, raizFutura, defectivo].map {
      addSubview($0)
    }
    
    if #available(iOS 11.0, *) {
      translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.wideSpacing).isActive = true
    } else {
      translation.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    translation.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      parentOrType.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Layout.defaultSpacing).isActive = true
    } else {
      parentOrType.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: Layout.safeTop).isActive = true
    }
    parentOrType.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    participioLabel.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    participioLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    participio.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    participio.leadingAnchor.constraint(equalTo: participioLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    gerundio.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    gerundio.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    gerundioLabel.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    gerundioLabel.trailingAnchor.constraint(equalTo: gerundio.leadingAnchor, constant: Layout.defaultSpacing * -1.0).isActive = true
    
    raizFuturaLabel.topAnchor.constraint(equalTo: participioLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    raizFuturaLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    raizFutura.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    raizFutura.leadingAnchor.constraint(equalTo: raizFuturaLabel.trailingAnchor, constant: Layout.defaultSpacing).isActive = true
    
    defectivo.topAnchor.constraint(equalTo: gerundio.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    defectivo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    table.topAnchor.constraint(equalTo: raizFuturaLabel.bottomAnchor, constant: Layout.defaultSpacing).isActive = true
    table.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    table.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    if #available(iOS 11.0, *) {
      table.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -1.0 * Layout.defaultSpacing).isActive = true
    } else {
      table.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: Layout.safeBottom).isActive = true
    }
  }
  
  func setupTable(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) {
    table.dataSource = dataSource
    table.delegate = delegate
    table.register(TenseCell.self, forCellReuseIdentifier: TenseCell.identifier)
    table.register(ConjugationCell.self, forCellReuseIdentifier: ConjugationCell.identifier)
  }
  
  func reloadTableData() {
    table.reloadData()
  }
}
