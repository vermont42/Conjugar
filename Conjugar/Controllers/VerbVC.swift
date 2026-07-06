//
//  VerbVC.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class VerbVC: UIViewController {
  private let verb: String
  private var conjugationDataSource: ConjugationDataSource?

  var verbView: VerbUIV {
    if let castedView = view as? VerbUIV {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: VerbUIV.self))
    }
  }

  init(verb: String) {
    self.verb = verb
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    NSCoder.fatalErrorNotImplemented()
  }

  override func loadView() {
    let verbView = VerbUIV(frame: UIScreen.main.bounds)
    verbView.participio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.raízFutura.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.gerundio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.translation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEnglish(_:))))
    verbView.defectuoso.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEnglish(_:))))
    initNavigationItemTitleView()
    let entry = VerbMap.shared.entry(for: verb)
    verbView.translation.text = entry?.gloss ?? ""
    let gerundioResult = TenseBridge.conjugate(infinitive: verb, tense: .gerundio, personNumber: .none)
    switch gerundioResult {
    case let .success(value):
      verbView.gerundio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let participioResult = TenseBridge.conjugate(infinitive: verb, tense: .participio, personNumber: .none)
    switch participioResult {
    case let .success(value):
      verbView.participio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let raízFuturaResult = TenseBridge.conjugate(infinitive: verb, tense: .raízFutura, personNumber: .none)
    switch raízFuturaResult {
    case let .success(value):
      verbView.raízFutura.attributedText = value.conjugatedString + NSAttributedString(string: "-")
    default:
      fatalError()
    }
    if Conjugator.isDefective(infinitive: verb) {
      verbView.defectuoso.text = L.Verb.defective
    } else {
      verbView.defectuoso.text = L.Verb.notDefective
    }

    let verbType = Conjugator.verbType(infinitive: verb)
    switch verbType {
    case .regularAr:
      verbView.parentOrType.text = "\(L.Verb.regular) AR"
    case .regularEr:
      verbView.parentOrType.text = "\(L.Verb.regular) ER"
    case .regularIr:
      verbView.parentOrType.text = "\(L.Verb.regular) IR"
    case .irregular:
      if let classNumber = entry?.classNumber, let exemplar = ModelCatalog.exemplar(forClass: classNumber), exemplar != verb {
        verbView.parentOrType.text = L.Verb.irregularWithParent(exemplar: exemplar)
      } else {
        verbView.parentOrType.text = L.Verb.irregular
      }
    }
    view = verbView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    conjugationDataSource = ConjugationDataSource(verb: verb, table: verbView.table, secondSingularBrowse: Current.settings.secondSingularBrowse)
    guard let conjugationDataSource = conjugationDataSource else {
      fatalError("\(ConjugationDataSource.self) was nil.")
    }
    verbView.setupTable(dataSource: conjugationDataSource, delegate: conjugationDataSource)
    verbView.table.reloadData()
    Current.analytics.recordVisitation(viewController: "\(VerbVC.self)")
  }

  private func initNavigationItemTitleView() {
    let titleLabel = UILabel.titleLabel(title: verb.capitalized)
    navigationItem.titleView = titleLabel
    titleLabel.isUserInteractionEnabled = true
    titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapSpanish(_:))))
  }

  @objc func tapSpanish(_ sender: UITapGestureRecognizer) {
    if let label = sender.view as? UILabel {
      Utterer.utter(label.attributedText?.string ?? label.text ?? "")
    }
  }

  @objc func tapEnglish(_ sender: UITapGestureRecognizer) {
    if let label = sender.view as? UILabel {
      Utterer.utter(label.attributedText?.string ?? label.text ?? "", locale: "en-US")
    }
  }
}
