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
  private var safeBottomInset: CGFloat = 0.0
  
  internal let translation: UILabel = {
    let label = UILabel()
    label.isUserInteractionEnabled = true
    return label
  } ()
  
  internal let parentOrType: UILabel = {
    let label = UILabel()
    label.text = "Regular AR"
    return label
  } ()
  
  internal let participioLabel: UILabel = {
    let label = UILabel()
    label.text = "PP:"
    return label
  } ()
  
  internal let participio: UILabel = {
    let label = UILabel()
    label.isUserInteractionEnabled = true
    return label
  } ()
  
  internal let gerundioLabel: UILabel = {
    let label = UILabel()
    label.text = "Ger:"
    return label
  } ()
  
  internal let gerundio: UILabel = {
    let label = UILabel()
    label.isUserInteractionEnabled = true
    return label
  } ()
  
  internal let raizFuturaLabel: UILabel = {
    let label = UILabel()
    label.text = "Raíz Fut:"
    return label
  } ()
  
  internal let raizFutura: UILabel = {
    let label = UILabel()
    label.isUserInteractionEnabled = true
    return label
  } ()
  
  internal let defectivo: UILabel = {
    let label = UILabel()
    label.isUserInteractionEnabled = true
    return label
  } ()
  
  internal let table: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = Colors.black
    tableView.translatesAutoresizingMaskIntoConstraints = false
    return tableView
  } ()
  
  private func setupLabel(_ label: UILabel) {
    label.font = Fonts.subheading
    label.textColor = Colors.yellow
    label.translatesAutoresizingMaskIntoConstraints = false
  }
  
  required init(coder aDecoder: NSCoder) {
    fatalError("This class does not support NSCoding")
  }
  
  private func commonInit() {
    _ = [translation, parentOrType, participioLabel, participio, gerundioLabel, gerundio, raizFuturaLabel, raizFutura, defectivo].map {
      setupLabel($0)
    }
    _ = [table, translation, parentOrType, participioLabel, participio, gerundioLabel, gerundio, raizFuturaLabel, raizFutura, defectivo].map {
      addSubview($0)
    }
    let defaultSpacing: CGFloat = 8.0
    
    if #available(iOS 11.0, *) {
      translation.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: defaultSpacing).isActive = true
    } else { // TODO: Delete this logic, safeBottomInset, and the associated init when iOS 11 goes live.
      translation.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: (safeBottomInset + defaultSpacing)).isActive = true
    }
    translation.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      parentOrType.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: defaultSpacing).isActive = true
    } else { // TODO: Delete this logic, safeBottomInset, and the associated init when iOS 11 goes live.
      parentOrType.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: (safeBottomInset + defaultSpacing)).isActive = true
    }
    parentOrType.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    participioLabel.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: defaultSpacing).isActive = true
    participioLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    participio.topAnchor.constraint(equalTo: translation.bottomAnchor, constant: defaultSpacing).isActive = true
    participio.leadingAnchor.constraint(equalTo: participioLabel.trailingAnchor, constant: defaultSpacing).isActive = true
    
    gerundio.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: defaultSpacing).isActive = true
    gerundio.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    gerundioLabel.topAnchor.constraint(equalTo: parentOrType.bottomAnchor, constant: defaultSpacing).isActive = true
    gerundioLabel.trailingAnchor.constraint(equalTo: gerundio.leadingAnchor, constant: defaultSpacing * -1.0).isActive = true
    
    raizFuturaLabel.topAnchor.constraint(equalTo: participioLabel.bottomAnchor, constant: defaultSpacing).isActive = true
    raizFuturaLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
    
    raizFutura.topAnchor.constraint(equalTo: participio.bottomAnchor, constant: defaultSpacing).isActive = true
    raizFutura.leadingAnchor.constraint(equalTo: raizFuturaLabel.trailingAnchor, constant: defaultSpacing).isActive = true
     
    defectivo.topAnchor.constraint(equalTo: gerundio.bottomAnchor, constant: defaultSpacing).isActive = true
    defectivo.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
    
    table.topAnchor.constraint(equalTo: raizFuturaLabel.bottomAnchor, constant: defaultSpacing).isActive = true
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
    table.register(TenseCell.self, forCellReuseIdentifier: TenseCell.identifier)
    table.register(ConjugationCell.self, forCellReuseIdentifier: ConjugationCell.identifier)
  }
  
  func reloadTableData() {
    table.reloadData()
  }
}
