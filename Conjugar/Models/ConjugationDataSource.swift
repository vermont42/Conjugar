//
//  ConjugationDataSource.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/15/18.
//  Copyright © 2018 Josh Adams. All rights reserved.
//

import UIKit

enum ConjugationRow {
  case tense(DisplayTense)
  case conjugation(DisplayTense, DisplayPersonNumber, String)
}

class ConjugationDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
  let rowCount: Int
  let verb: String
  weak var table: UITableView?
  var rows: [ConjugationRow] = []

  init(verb: String, table: UITableView, secondSingularBrowse: SecondSingularBrowse) {
    self.verb = verb
    self.table = table
    let tenses = DisplayTense.conjugatedTenses
    rowCount = tenses.reduce(0, { $0 + $1.conjugationCount(secondSingularBrowse: secondSingularBrowse) }) + tenses.count
    super.init()
    tenses.forEach { tense in
      self.rows.append(.tense(tense))
      if tense.hasYoForm {
        self.rows.append(.conjugation(tense, .firstSingular, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: .firstSingular)))
      }

      switch secondSingularBrowse {
      case .tu:
        self.rows.append(.conjugation(tense, .secondSingularTú, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: .secondSingularTú)))
      case .vos:
        self.rows.append(.conjugation(tense, .secondSingularVos, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: .secondSingularVos)))
      case .both:
        self.rows.append(.conjugation(tense, .secondSingularTú, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: .secondSingularTú)))
        self.rows.append(.conjugation(tense, .secondSingularVos, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: .secondSingularVos)))
      }
      [DisplayPersonNumber.thirdSingular, .firstPlural, .secondPlural, .thirdPlural].forEach { personNumber in
        self.rows.append(.conjugation(tense, personNumber, ConjugationDataSource.conjugation(verb: verb, tense: tense, personNumber: personNumber)))
      }
    }
  }

  /// The displayable form for one slot: a defective verb's formless slot renders
  /// as an empty string (a blank row, like the legacy engine's "df" sentinel);
  /// any other failure is a programming or data error.
  private static func conjugation(verb: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> String {
    switch TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber) {
    case let .success(value):
      return value
    case .failure(.noForm):
      return ""
    case let .failure(error):
      fatalError("No \(personNumber.pronoun) form found for tense \(tense.displayName) of \(verb): \(error).")
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
