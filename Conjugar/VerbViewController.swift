//
//  VerbViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class VerbViewController: UIViewController {
  @IBOutlet var infinitivo: UILabel!
  @IBOutlet var parentOrType: UILabel!
  @IBOutlet var participio: UILabel!
  @IBOutlet var talloFuturo: UILabel!
  @IBOutlet var gerundio: UILabel!
  @IBOutlet var defectivo: UILabel!
  @IBOutlet var table: UITableView!
  var verb: String = ""
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard verb != "" else { fatalError() }
    infinitivo.text = verb
    let gerundioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .gerundio, personNumber: .none)
    switch gerundioResult {
    case let .success(value):
      gerundio.text = value
    default:
      fatalError()
    }
    let participioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .participio, personNumber: .none)
    switch participioResult {
    case let .success(value):
      participio.text = value
    default:
      fatalError()
    }
    let talloFuturoResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .talloFuturo, personNumber: .none)
    switch talloFuturoResult {
    case let .success(value):
      talloFuturo.text = value
    default:
      fatalError()
    }
    if Conjugator.sharedInstance.isDefective(infinitive: verb) {
      defectivo.text = "Defectivo"
    }
    else {
      defectivo.text = "No Defectivo"
    }
    
    let verbType = Conjugator.sharedInstance.verbType(infinitive: verb)
    switch verbType {
    case .regularAr:
      parentOrType.text = "Regular AR Verb"
    case .regularEr:
      parentOrType.text = "Regular ER Verb"
    case .regularIr:
      parentOrType.text = "Regular IR Verb"
    case .irregular:
      guard let parent = Conjugator.sharedInstance.parent(infinitive: verb) else { fatalError() }
      parentOrType.text = "☛ \(parent)"
    }
  }
}
