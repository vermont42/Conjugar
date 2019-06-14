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

  var verbView: VerbView {
    if let castedView = view as? VerbView {
      return castedView
    } else {
      fatalError(fatalCastMessage(view: VerbView.self))
    }
  }

  init(verb: String) {
    self.verb = verb
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    UIViewController.fatalErrorNotImplemented()
  }

  override func loadView() {
    let verbView = VerbView(frame: UIScreen.main.bounds)
    verbView.participio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.raízFutura.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.gerundio.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapSpanish(_:))))
    verbView.translation.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEnglish(_:))))
    verbView.defectivo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEnglish(_:))))
    initNavigationItemTitleView()
    let translationResult = Conjugator.shared.conjugate(infinitive: verb, tense: .translation, personNumber: .none)
    switch translationResult {
    case let .success(value):
      verbView.translation.text = value
    default:
      fatalError()
    }
    let gerundioResult = Conjugator.shared.conjugate(infinitive: verb, tense: .gerundio, personNumber: .none)
    switch gerundioResult {
    case let .success(value):
      verbView.gerundio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let participioResult = Conjugator.shared.conjugate(infinitive: verb, tense: .participio, personNumber: .none)
    switch participioResult {
    case let .success(value):
      verbView.participio.attributedText = value.conjugatedString
    default:
      fatalError()
    }
    let raízFuturaResult = Conjugator.shared.conjugate(infinitive: verb, tense: .raízFutura, personNumber: .none)
    switch raízFuturaResult {
    case let .success(value):
      verbView.raízFutura.attributedText = value.conjugatedString + NSAttributedString(string: "-")
    default:
      fatalError()
    }
    if Conjugator.shared.isDefective(infinitive: verb) {
      verbView.defectivo.text = "Defective"
    } else {
      verbView.defectivo.text = "Not Defective"
    }

    let verbType = Conjugator.shared.verbType(infinitive: verb)
    switch verbType {
    case .regularAr:
      verbView.parentOrType.text = "Regular AR"
    case .regularEr:
      verbView.parentOrType.text = "Regular ER"
    case .regularIr:
      verbView.parentOrType.text = "Regular IR"
    case .irregular:
      guard let parent = Conjugator.shared.parent(infinitive: verb) else {
        fatalError("Parent verb not found.")
      }
      if Conjugator.baseVerbs.contains(parent) {
        verbView.parentOrType.text = "Irregular"
      } else {
        verbView.parentOrType.text = "Irreg. ☛ \(parent)"
      }
    }
    view = verbView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    conjugationDataSource = ConjugationDataSource(verb: verb, table: verbView.table, secondSingularBrowse: GlobalContainer.settings.secondSingularBrowse)
    guard let conjugationDataSource = conjugationDataSource else {
      fatalError("\(ConjugationDataSource.self) was nil.")
    }
    verbView.setupTable(dataSource: conjugationDataSource, delegate: conjugationDataSource)
    verbView.table.reloadData()
    GlobalContainer.analytics.recordVisitation(viewController: "\(VerbVC.self)")
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
