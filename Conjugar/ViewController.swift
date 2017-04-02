//
//  ViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  private let conjugator = Conjugator()
  
  override func viewDidLoad() {
      super.viewDidLoad()
      
      _ = ["hablar", "comer", "subir", "estar", "conocer", "reconocer", "morder", "promover", "llover", "kickar"].map {
          print("\n\($0):")
          fullyConjugate(infinitive: $0, tense: .presenteDeIndicativo)
      }
  }
    
  private func fullyConjugate(infinitive: String, tense: Tense) {
      _ = [PersonNumber.firstSingular, PersonNumber.secondSingular, PersonNumber.thirdSingular, PersonNumber.firstPlural, PersonNumber.secondPlural, PersonNumber.thirdPlural].map {
          conjugate(infinitive: infinitive, tense: tense, personNumber: $0)
      }
  }
    
  private func conjugate(infinitive: String, tense: Tense, personNumber: PersonNumber) {
    let result = conjugator.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber, region: .spain)
    switch result {
    case let .success(value):
        print(value)
    case .failure(.tooShort):
        print("Verb is too short.")
    case let .failure(.noSuchConjugation(personNumber)):
        print("There is no conjugation for the person/number combination \(personNumber.rawValue).")
    case let .failure(.invalidEnding(ending)):
        print("That verb has an invalid Spanish-verb ending, \(ending).")
    case let .failure(.personNumberAbsent(tense)):
      print("Person/number not specified for tense \(tense.rawValue).")
    case let .failure(.tenseNotImplemented(tense)):
        print("Tense \(tense.rawValue) is not implemented.")
    case let .failure(.defectiveForPersonNumber(personNumber)):
      print("Verb is defective for person/number \(personNumber).")
    }
  }
}

