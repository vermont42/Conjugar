//
//  ViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = ["hablar", "comer", "subir"].map {
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
        let result = Verb.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber, region: .spain)
        switch result {
        case let .success(value):
            print(value)
        case .failure(.tooShort):
            print("Verb is too short.")
        case .failure(.noSuchConjugation):
            print("There is no conjugation for that verb/person/number combination.")
        case let .failure(.invalidEnding(ending)):
            print("That verb has an invalid Spanish-verb ending, \(ending).")
        case .failure(.tenseNotImplemented):
            print("That tense is not implemented.")
        }
    }
}

