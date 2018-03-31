//
//  VerbVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbVC: UIViewController {
  var verb: String = ""
  private var conjugationDataSource: ConjugationDataSource!
  
  var verbView: VerbView {
    return view as! VerbView
  }
  
  override func loadView() {
    let verbView = VerbView(frame: UIScreen.main.bounds)
    verbView.participio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
    verbView.raizFutura.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
    verbView.gerundio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
    verbView.translation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapEnglish(_:))))
    verbView.defectivo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapEnglish(_:))))
    guard verb != "" else { fatalError() }
    initNavigationItemTitleView()
    let translationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
    switch translationResult {
    case let .success(value):
      verbView.translation.text = value
    default:
      fatalError()
    }
    let gerundioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .gerundio, personNumber: .none)
    switch gerundioResult {
    case let .success(value):
      verbView.gerundio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let participioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .participio, personNumber: .none)
    switch participioResult {
    case let .success(value):
      verbView.participio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let raizFuturaResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .raizFutura, personNumber: .none)
    switch raizFuturaResult {
    case let .success(value):
      verbView.raizFutura.attributedText = value.conjugatedString + NSAttributedString(string: "-")
    default:
      fatalError()
    }
    if Conjugator.sharedInstance.isDefective(infinitive: verb) {
      verbView.defectivo.text = "Defective"
    }
    else {
      verbView.defectivo.text = "Not Defective"
    }
    
    let verbType = Conjugator.sharedInstance.verbType(infinitive: verb)
    switch verbType {
    case .regularAr:
      verbView.parentOrType.text = "Regular AR"
    case .regularEr:
      verbView.parentOrType.text = "Regular ER"
    case .regularIr:
      verbView.parentOrType.text = "Regular IR"
    case .irregular:
      guard let parent = Conjugator.sharedInstance.parent(infinitive: verb) else { fatalError() }
      if Conjugator.baseVerbs.contains(parent) {
        verbView.parentOrType.text = "Irregular"
      }
      else {
        verbView.parentOrType.text = "Irreg. ☛ \(parent)"
      }
    }
    view = verbView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    conjugationDataSource = ConjugationDataSource(verb: verb, table: verbView.table)
    verbView.setupTable(dataSource: conjugationDataSource, delegate: conjugationDataSource)
    verbView.table.reloadData()
  }
  
  private func initNavigationItemTitleView() {
    let titleLabel = UILabel.titleLabel(title: verb.capitalized)
    navigationItem.titleView = titleLabel
    titleLabel.isUserInteractionEnabled = true
    titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
  }
  
  @objc func tapSpanish(_ sender: UITapGestureRecognizer) {
    if let label = sender.view as? UILabel {
      Utterer.utter(label.attributedText?.string ?? label.text!)
    }
  }
  
  @objc func tapEnglish(_ sender: UITapGestureRecognizer) {
    if let label = sender.view as? UILabel {
      Utterer.utter(label.attributedText?.string ?? label.text!, locale: "en-US")
    }
  }
}
