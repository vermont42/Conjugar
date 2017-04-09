//
//  ViewController.swift
//  Conjugar
//
//  Created by Joshua Adams on 3/31/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import UIKit

// TODO: Add sentir, sentar, perder, pedir, crecer, lucir, conducir, huir, construir (like huir?), caer, oír, traer, jugar, adquirir, argüir, discernir, adquirir.
// When looking up an infinitive, accept, for example, "oir" for "oír" or "arguir" for argüir". Might need to add "accentless" forms for verbs. Could do this programatically.
// Add ability for user to get future/conditional stem.

class ViewController: UIViewController {
  private let conjugator = Conjugator()
  
  override func viewDidLoad() {
    super.viewDidLoad()
      
    _ = ["hablar", "comer", "subir", "ser", "ver", "ir", "haber", "saber", "caber", "poder", "querer", "poner", "tener", "venir", "salir", "valer", "decir", "hacer", "estar", "conocer", "reconocer", "morder", "mostrar", "mover", "promover", "beber", "vivir", "pensar", "dar", "llover", "gustar"].map {
        print("\n\($0):")
        print("\nparticipio")
        conjugate(infinitive: $0, tense: .participio, personNumber: .none)
        print("\ngerundio")
        conjugate(infinitive: $0, tense: .gerundio, personNumber: .none)
        print("\npresenteDeIndicativo")
        fullyConjugate(infinitive: $0, tense: .presenteDeIndicativo)
        print("\npreterito")
        fullyConjugate(infinitive: $0, tense: .preterito)
        print("\nimperfectoDeIndicativo")
        fullyConjugate(infinitive: $0, tense: .imperfectoDeIndicativo)
        print("\nfuturoDeIndicativo")
        fullyConjugate(infinitive: $0, tense: .futuroDeIndicativo)
        print("\ncondicional")
        fullyConjugate(infinitive: $0, tense: .condicional)
        print("\npresenteDeSubjuntivo")
        fullyConjugate(infinitive: $0, tense: .presenteDeSubjuntivo)
        print("\nimperfectoDeSubjuntivo1")
        fullyConjugate(infinitive: $0, tense: .imperfectoDeSubjuntivo1)
        print("\nimperfectoDeSubjuntivo2")
        fullyConjugate(infinitive: $0, tense: .imperfectoDeSubjuntivo2)
        print("\nfuturoDeSubjuntivo")
        fullyConjugate(infinitive: $0, tense: .futuroDeSubjuntivo)
        print("\nperfectoDeIndicativo")
        fullyConjugate(infinitive: $0, tense: .perfectoDeIndicativo)
        print("\npreteritoAnterior")
        fullyConjugate(infinitive: $0, tense: .preteritoAnterior)
        print("\npluscuamperfectoDeIndicativo")
        fullyConjugate(infinitive: $0, tense: .pluscuamperfectoDeIndicativo)
        print("\nfuturoPerfecto")
        fullyConjugate(infinitive: $0, tense: .futuroPerfecto)
        print("\ncondicionalCompuesto")
        fullyConjugate(infinitive: $0, tense: .condicionalCompuesto)
        print("\nperfectoDeSubjuntivo")
        fullyConjugate(infinitive: $0, tense: .perfectoDeSubjuntivo)
        print("\npluscuamperfectoDeSubjuntivo1")
        fullyConjugate(infinitive: $0, tense: .pluscuamperfectoDeSubjuntivo1)
        print("\npluscuamperfectoDeSubjuntivo2")
        fullyConjugate(infinitive: $0, tense: .pluscuamperfectoDeSubjuntivo2)
        print("\nfuturoPerfectoDeSubjuntivo")
        fullyConjugate(infinitive: $0, tense: .futuroPerfectoDeSubjuntivo)
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

