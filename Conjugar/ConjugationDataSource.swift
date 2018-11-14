//
//  ConjugationDataSource.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/15/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

enum ConjugationRow {
  case tense(Tense)
  case conjugation(Tense, PersonNumber, String)
}

class ConjugationDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
  let rowCount: Int
  let verb: String
  weak var table: UITableView?
  var rows: [ConjugationRow] = []

  init(verb: String, table: UITableView) {
    self.verb = verb
    self.table = table
    let tenses = Tense.conjugatedTenses
    rowCount = tenses.reduce(0, { $0 + $1.conjugationCount }) + tenses.count
    super.init()
    tenses.forEach { tense in
      self.rows.append(.tense(tense))
      if tense.hasYoForm {
        let yoResult = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: .firstSingular)
        switch yoResult {
        case let .success(value):
          self.rows.append(.conjugation(tense, .firstSingular, value))
        default:
          fatalError("No yo form found for tense \(tense.displayName).")
        }
      }

      let tuResult = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: .secondSingular)
      let tuConjugation: String
      switch tuResult {
      case let .success(value):
        tuConjugation = value
      default:
        fatalError("No tú form found for tense \(tense.displayName).")
      }
      let vosResult = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: .secondSingularVos)
      let vosConjugation: String
      switch vosResult {
      case let .success(value):
        vosConjugation = value
      default:
        fatalError("No vos form found for tense \(tense.displayName).")
      }
      switch SettingsManager.getSecondSingularBrowse() {
      case .tu:
        self.rows.append(.conjugation(tense, .secondSingular, tuConjugation))
      case .vos:
        self.rows.append(.conjugation(tense, .secondSingularVos, vosConjugation))
      case .both:
        self.rows.append(.conjugation(tense, .secondSingular, tuConjugation))
        self.rows.append(.conjugation(tense, .secondSingularVos, vosConjugation))
      }
      [PersonNumber.thirdSingular, .firstPlural, .secondPlural, .thirdPlural].forEach { personNumber in
        let result = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
        switch result {
        case let .success(value):
          self.rows.append(.conjugation(tense, personNumber, value))
        default:
          fatalError("No \(personNumber.pronoun) form found.")
        }
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return rowCount
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch rows[indexPath.row] {
    case .tense(let tense):
      guard let cell = table?.dequeueReusableCell(withIdentifier: TenseCell.identifier) as? TenseCell else {
        fatalError("Failed to dequeue cell for tense \(tense).")
      }
      cell.configure(tense: tense.titleCaseName)
      return cell
    case .conjugation(let tense, let personNumber, let conjugation):
      guard let cell = table?.dequeueReusableCell(withIdentifier: ConjugationCell.identifier) as? ConjugationCell else {
        fatalError("Failed to dequeue cell for tense \(tense), personNumber \(personNumber), and conjugation \(conjugation).")
      }
      cell.configure(tense: tense, personNumber: personNumber, conjugation: conjugation)
      return cell
    }
  }
}
