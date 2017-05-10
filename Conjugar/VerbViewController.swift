//
//  VerbViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/10/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation
import UIKit

class VerbViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet var infinitivo: UILabel!
  @IBOutlet var parentOrType: UILabel!
  @IBOutlet var participio: UILabel!
  @IBOutlet var talloFuturo: UILabel!
  @IBOutlet var gerundio: UILabel!
  @IBOutlet var defectivo: UILabel!
  @IBOutlet var table: UITableView!
  var verb: String = ""
  
  override func viewDidLoad() {
    table.delegate = self
    table.dataSource = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard verb != "" else { fatalError() }
    infinitivo.text = verb
    let gerundioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .gerundio, personNumber: .none)
    switch gerundioResult {
    case let .success(value):
      gerundio.text = Tense.gerundio.shortDisplayName() + ": " + value
    default:
      fatalError()
    }
    let participioResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .participio, personNumber: .none)
    switch participioResult {
    case let .success(value):
      participio.text = Tense.participio.shortDisplayName() + ": " + value
    default:
      fatalError()
    }
    let talloFuturoResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: .talloFuturo, personNumber: .none)
    switch talloFuturoResult {
    case let .success(value):
      talloFuturo.text = Tense.talloFuturo.shortDisplayName() + ": " + value + "-"
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
      parentOrType.text = "Regular AR"
    case .regularEr:
      parentOrType.text = "Regular ER"
    case .regularIr:
      parentOrType.text = "Regular IR"
    case .irregular:
      guard let parent = Conjugator.sharedInstance.parent(infinitive: verb) else { fatalError() }
      parentOrType.text = "☛ \(parent)"
    }
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 21 //138
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = indexPath.row
    var personNumber: PersonNumber = .none
    let personNumbers: [PersonNumber] =  [.firstSingular, .secondSingular, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    var tense: Tense
    switch row {
    case 0:
      tense = .presenteDeIndicativo
    case 1...6:
      tense = .presenteDeIndicativo
      personNumber = personNumbers[row - 1]
    case 7:
      tense = .preterito
    case 8...13:
      tense = .preterito
      personNumber = personNumbers[row - 8]
    case 14:
      tense = .imperfectoDeIndicativo
    case 15...20:
      tense = .imperfectoDeIndicativo
      personNumber = personNumbers[row - 15]
    default:
      fatalError()
    }
    if personNumber == .none {
      let cell = table.dequeueReusableCell(withIdentifier: "TenseCell") as! TenseCell
      cell.configure(tense: tense.displayName())
      return cell
    }
    else {
      let cell = table.dequeueReusableCell(withIdentifier: "ConjugationCell") as! ConjugationCell
      var conjugation = ""
      let conjugationResult = Conjugator.sharedInstance.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
      switch conjugationResult {
      case let .success(value):
        conjugation = value
      default:
        fatalError()
      }
      cell.configure(tense: tense, personNumber: personNumber, conjugation: conjugation)
      return cell
    }
  }
}
