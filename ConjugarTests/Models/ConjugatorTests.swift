//
//  ConjugatorTests.swift
//  ConjugarTests
//
//  Created by Joshua Adams on 9/4/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import XCTest
@testable import Conjugar

class ConjugatorTests: XCTestCase {
  func testBadInput() {
    var result = Conjugator.shared.conjugate(infinitive: "m", tense: .futuroDeIndicativo, personNumber: .firstSingular)
    switch result {
    case .failure:
      break
    default:
      XCTFail("One-letter words cannot be conjugated.")
    }

    result = Conjugator.shared.conjugate(infinitive: "tango 💃🏻", tense: .preterito, personNumber: .thirdPlural)
    switch result {
    case .failure:
      break
    default:
      XCTFail("Words not ending in ar, er, or ir cannot be conjugated.")
    }
  }

  func testThirdPersonSingularOnlyVerb() {
    VerbFamilies.thirdPersonSingularOnlyVerbs.forEach { verb in
      PersonNumber.allCases.forEach { personNumber in
        if ![.none, .thirdSingular].contains(personNumber) {
          let tense = Tense.conjugatedTenses[Int.random(in: 0 ..< Tense.conjugatedTenses.count)]
          if ![.imperativoPositivo, .imperativoNegativo].contains(tense) {
            let result = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
            switch result {
            case .success(let value):
              if value != Conjugator.defective {
                XCTFail("\(verb) should be defective for \(personNumber.pronoun), tense \(tense.displayName).")
              }
            default:
              XCTFail("\(verb) cannot be conjugated for \(personNumber.pronoun), tense \(tense.displayName).")
            }
          }
        }
      }
    }
  }

  // Use this snippet to generate conjugations for testing.

  //    let v = "hacer"
  //    for tense in Tense.conjugatedTenses {
  //      var output = "["
  //      for personNumber in PersonNumber.actualPersonNumbers {
  //        if personNumber == .firstSingular && (tense == .imperativoPositivo || tense == .imperativoNegativo) {
  //          continue
  //        }
  //        let result = Conjugator.shared.conjugate(infinitive: v, tense: tense, personNumber: personNumber)
  //        switch result {
  //        case let .success(value):
  //          output += "\"" + value + "\"" + (personNumber != .thirdPlural ? ", " : "],")
  //        default:
  //          fatalError()
  //        }
  //      }
  //      print(output)
  //    }

  func testRegularARVerb() {
    testVerb("rasar", participio: "rasado", gerundio: "rasando", raízFutura: "rasar", translation: "skim", conjugations: [
      ["raso", "rasas", "rasás", "rasa", "rasamos", "rasáis", "rasan"],
      ["rasé", "rasaste", "rasaste", "rasó", "rasamos", "rasastéis", "rasaron"],
      ["rasaba", "rasabas", "rasabas", "rasaba", "rasábamos", "rasabais", "rasaban"],
      ["rasaré", "rasarás", "rasarás", "rasará", "rasaremos", "rasaréis", "rasarán"],
      ["rasaría", "rasarías", "rasarías", "rasaría", "rasaríamos", "rasaríais", "rasarían"],
      ["rase", "rases", "rases", "rase", "rasemos", "raséis", "rasen"],
      ["rasara", "rasaras", "rasaras", "rasara", "rasáramos", "rasarais", "rasaran"],
      ["rasase", "rasases", "rasases", "rasase", "rasásemos", "rasaseis", "rasasen"],
      ["rasare", "rasares", "rasares", "rasare", "rasáremos", "rasareis", "rasaren"],
      ["💃🏻", "rasa", "rasá", "rase", "rasemos", "rasad", "rasen"],
      ["💃🏻", "no rases", "no rases", "no rase", "no rasemos", "no raséis", "no rasen"],
      ["hE rasado", "haS rasado", "haS rasado", "hA rasado", "hEmos rasado", "habéis rasado", "haN rasado"],
      ["hUBE rasado", "hUbiste rasado", "hUbiste rasado", "hUBO rasado", "hUbimos rasado", "hUbisteis rasado", "hUbieron rasado"],
      ["había rasado", "habías rasado", "habías rasado", "había rasado", "habíamos rasado", "habíais rasado", "habían rasado"],
      ["habRé rasado", "habRás rasado", "habRás rasado", "habRá rasado", "habRemos rasado", "habRéis rasado", "habRán rasado"],
      ["habRía rasado", "habRías rasado", "habRías rasado", "habRía rasado", "habRíamos rasado", "habRíais rasado", "habRían rasado"],
      ["haYa rasado", "haYas rasado", "haYas rasado", "haYa rasado", "haYamos rasado", "haYáis rasado", "haYan rasado"],
      ["hUbiera rasado", "hUbieras rasado", "hUbieras rasado", "hUbiera rasado", "hUbiéramos rasado", "hUbierais rasado", "hUbieran rasado"],
      ["hUbiese rasado", "hUbieses rasado", "hUbieses rasado", "hUbiese rasado", "hUbiésemos rasado", "hUbieseis rasado", "hUbiesen rasado"],
      ["hUbiere rasado", "hUbieres rasado", "hUbieres rasado", "hUbiere rasado", "hUbiéremos rasado", "hUbiereis rasado", "hUbieren rasado"]
    ])
  }

  func testRegularERVerb() {
    testVerb("comer", participio: "comido", gerundio: "comiendo", raízFutura: "comer", translation: "eat", conjugations: [
      ["como", "comes", "comés", "come", "comemos", "coméis", "comen"],
      ["comí", "comiste", "comiste", "comió", "comimos", "comisteis", "comieron"],
      ["comía", "comías", "comías", "comía", "comíamos", "comíais", "comían"],
      ["comeré", "comerás", "comerás", "comerá", "comeremos", "comeréis", "comerán"],
      ["comería", "comerías", "comerías", "comería", "comeríamos", "comeríais", "comerían"],
      ["coma", "comas", "comas", "coma", "comamos", "comáis", "coman"],
      ["comiera", "comieras", "comieras", "comiera", "comiéramos", "comierais", "comieran"],
      ["comiese", "comieses", "comieses", "comiese", "comiésemos", "comieseis", "comiesen"],
      ["comiere", "comieres", "comieres", "comiere", "comiéremos", "comiereis", "comieren"],
      ["💃🏻", "come", "comé", "coma", "comamos", "comed", "coman"],
      ["💃🏻", "no comas", "no comas", "no coma", "no comamos", "no comáis", "no coman"],
      ["hE comido", "haS comido", "haS comido", "hA comido", "hEmos comido", "habéis comido", "haN comido"],
      ["hUBE comido", "hUbiste comido", "hUbiste comido", "hUBO comido", "hUbimos comido", "hUbisteis comido", "hUbieron comido"],
      ["había comido", "habías comido", "habías comido", "había comido", "habíamos comido", "habíais comido", "habían comido"],
      ["habRé comido", "habRás comido", "habRás comido", "habRá comido", "habRemos comido", "habRéis comido", "habRán comido"],
      ["habRía comido", "habRías comido", "habRías comido", "habRía comido", "habRíamos comido", "habRíais comido", "habRían comido"],
      ["haYa comido", "haYas comido", "haYas comido", "haYa comido", "haYamos comido", "haYáis comido", "haYan comido"],
      ["hUbiera comido", "hUbieras comido", "hUbieras comido", "hUbiera comido", "hUbiéramos comido", "hUbierais comido", "hUbieran comido"],
      ["hUbiese comido", "hUbieses comido", "hUbieses comido", "hUbiese comido", "hUbiésemos comido", "hUbieseis comido", "hUbiesen comido"],
      ["hUbiere comido", "hUbieres comido", "hUbieres comido", "hUbiere comido", "hUbiéremos comido", "hUbiereis comido", "hUbieren comido"]
      ])
  }

  func testRegularIRVerb() {
    testVerb("subir", participio: "subido", gerundio: "subiendo", raízFutura: "subir", translation: "go up", conjugations: [
      ["subo", "subes", "subís", "sube", "subimos", "subís", "suben"],
      ["subí", "subiste", "subiste", "subió", "subimos", "subisteis", "subieron"],
      ["subía", "subías", "subías", "subía", "subíamos", "subíais", "subían"],
      ["subiré", "subirás", "subirás", "subirá", "subiremos", "subiréis", "subirán"],
      ["subiría", "subirías", "subirías", "subiría", "subiríamos", "subiríais", "subirían"],
      ["suba", "subas", "subas", "suba", "subamos", "subáis", "suban"],
      ["subiera", "subieras", "subieras", "subiera", "subiéramos", "subierais", "subieran"],
      ["subiese", "subieses", "subieses", "subiese", "subiésemos", "subieseis", "subiesen"],
      ["subiere", "subieres", "subieres", "subiere", "subiéremos", "subiereis", "subieren"],
      ["💃🏻", "sube", "subí", "suba", "subamos", "subid", "suban"],
      ["💃🏻", "no subas", "no subas", "no suba", "no subamos", "no subáis", "no suban"],
      ["hE subido", "haS subido", "haS subido", "hA subido", "hEmos subido", "habéis subido", "haN subido"],
      ["hUBE subido", "hUbiste subido", "hUbiste subido", "hUBO subido", "hUbimos subido", "hUbisteis subido", "hUbieron subido"],
      ["había subido", "habías subido", "habías subido", "había subido", "habíamos subido", "habíais subido", "habían subido"],
      ["habRé subido", "habRás subido", "habRás subido", "habRá subido", "habRemos subido", "habRéis subido", "habRán subido"],
      ["habRía subido", "habRías subido", "habRías subido", "habRía subido", "habRíamos subido", "habRíais subido", "habRían subido"],
      ["haYa subido", "haYas subido", "haYas subido", "haYa subido", "haYamos subido", "haYáis subido", "haYan subido"],
      ["hUbiera subido", "hUbieras subido", "hUbieras subido", "hUbiera subido", "hUbiéramos subido", "hUbierais subido", "hUbieran subido"],
      ["hUbiese subido", "hUbieses subido", "hUbieses subido", "hUbiese subido", "hUbiésemos subido", "hUbieseis subido", "hUbiesen subido"],
      ["hUbiere subido", "hUbieres subido", "hUbieres subido", "hUbiere subido", "hUbiéremos subido", "hUbiereis subido", "hUbieren subido"]
      ])
  }

  func testSer() {
    testVerb("ser", participio: "sido", gerundio: "siendo", raízFutura: "ser", translation: "be", conjugations: [
      ["soY", "ERes", "sOs", "ES", "sOmos", "sOis", "sOn"],
      ["FUI", "FUiste", "FUiste", "FUE", "FUimos", "FUisteis", "FUeron"],
      ["ERa", "ERas", "ERas", "ERa", "ÉRamos", "ERais", "ERan"],
      ["seré", "serás", "serás", "será", "seremos", "seréis", "serán"],
      ["sería", "serías", "serías", "sería", "seríamos", "seríais", "serían"],
      ["sEa", "sEas", "sEas", "sEa", "sEamos", "sEáis", "sEan"],
      ["FUera", "FUeras", "FUeras", "FUera", "FUéramos", "FUerais", "FUeran"],
      ["FUese", "FUeses", "FUeses", "FUese", "FUésemos", "FUeseis", "FUesen"],
      ["FUere", "FUeres", "FUeres", "FUere", "FUéremos", "FUereis", "FUeren"],
      ["💃🏻", "sÉ", "sé", "sEa", "sEamos", "sed", "sEan"],
      ["💃🏻", "no sEas", "no sEas", "no sEa", "no sEamos", "no sEáis", "no sEan"],
      ["hE sido", "haS sido", "haS sido", "hA sido", "hEmos sido", "habéis sido", "haN sido"],
      ["hUBE sido", "hUbiste sido", "hUbiste sido", "hUBO sido", "hUbimos sido", "hUbisteis sido", "hUbieron sido"],
      ["había sido", "habías sido", "habías sido", "había sido", "habíamos sido", "habíais sido", "habían sido"],
      ["habRé sido", "habRás sido", "habRás sido", "habRá sido", "habRemos sido", "habRéis sido", "habRán sido"],
      ["habRía sido", "habRías sido", "habRías sido", "habRía sido", "habRíamos sido", "habRíais sido", "habRían sido"],
      ["haYa sido", "haYas sido", "haYas sido", "haYa sido", "haYamos sido", "haYáis sido", "haYan sido"],
      ["hUbiera sido", "hUbieras sido", "hUbieras sido", "hUbiera sido", "hUbiéramos sido", "hUbierais sido", "hUbieran sido"],
      ["hUbiese sido", "hUbieses sido", "hUbieses sido", "hUbiese sido", "hUbiésemos sido", "hUbieseis sido", "hUbiesen sido"],
      ["hUbiere sido", "hUbieres sido", "hUbieres sido", "hUbiere sido", "hUbiéremos sido", "hUbiereis sido", "hUbieren sido"]
      ])
  }

  func testIr() {
    testVerb("ir", participio: "ido", gerundio: "Yendo", raízFutura: "ir", translation: "go", conjugations: [
      ["VOY", "VAS", "VAS", "VA", "VAMOS", "VAIS", "VAN"],
      ["FUI", "FUiste", "FUiste", "FUE", "FUimos", "FUisteis", "FUeron"],
      ["IBa", "IBas", "IBas", "IBa", "IBamos", "IBais", "IBan"],
      ["iré", "irás", "irás", "irá", "iremos", "iréis", "irán"],
      ["iría", "irías", "irías", "iría", "iríamos", "iríais", "irían"],
      ["VAYa", "VAYas", "VAYas", "VAYa", "VAYamos", "VAYáis", "VAYan"],
      ["FUera", "FUeras", "FUeras", "FUera", "FUéramos", "FUerais", "FUeran"],
      ["FUese", "FUeses", "FUeses", "FUese", "FUésemos", "FUeseis", "FUesen"],
      ["FUere", "FUeres", "FUeres", "FUere", "FUéremos", "FUereis", "FUeren"],
      ["💃🏻", "VE", "ANDÁ", "VAYa", "VAYamos", "id", "VAYan"],
      ["💃🏻", "no VAYas", "no VAYas", "no VAYa", "no VAYamos", "no VAYáis", "no VAYan"],
      ["hE ido", "haS ido", "haS ido", "hA ido", "hEmos ido", "habéis ido", "haN ido"],
      ["hUBE ido", "hUbiste ido", "hUbiste ido", "hUBO ido", "hUbimos ido", "hUbisteis ido", "hUbieron ido"],
      ["había ido", "habías ido", "habías ido", "había ido", "habíamos ido", "habíais ido", "habían ido"],
      ["habRé ido", "habRás ido", "habRás ido", "habRá ido", "habRemos ido", "habRéis ido", "habRán ido"],
      ["habRía ido", "habRías ido", "habRías ido", "habRía ido", "habRíamos ido", "habRíais ido", "habRían ido"],
      ["haYa ido", "haYas ido", "haYas ido", "haYa ido", "haYamos ido", "haYáis ido", "haYan ido"],
      ["hUbiera ido", "hUbieras ido", "hUbieras ido", "hUbiera ido", "hUbiéramos ido", "hUbierais ido", "hUbieran ido"],
      ["hUbiese ido", "hUbieses ido", "hUbieses ido", "hUbiese ido", "hUbiésemos ido", "hUbieseis ido", "hUbiesen ido"],
      ["hUbiere ido", "hUbieres ido", "hUbieres ido", "hUbiere ido", "hUbiéremos ido", "hUbiereis ido", "hUbieren ido"]
      ])
  }

  func testHacer() {
    testVerb("hacer", participio: "hECHo", gerundio: "haciendo", raízFutura: "haR", translation: "do, make", conjugations: [
      ["haGo", "haces", "hacés", "hace", "hacemos", "hacéis", "hacen"],
      ["hICE", "hIciste", "hIciste", "hIZO", "hIcimos", "hIcisteis", "hIcieron"],
      ["hacía", "hacías", "hacías", "hacía", "hacíamos", "hacíais", "hacían"],
      ["haRé", "haRás", "haRás", "haRá", "haRemos", "haRéis", "haRán"],
      ["haRía", "haRías", "haRías", "haRía", "haRíamos", "haRíais", "haRían"],
      ["haGa", "haGas", "haGas", "haGa", "haGamos", "haGáis", "haGan"],
      ["hIciera", "hIcieras", "hIcieras", "hIciera", "hIciéramos", "hIcierais", "hIcieran"],
      ["hIciese", "hIcieses", "hIcieses", "hIciese", "hIciésemos", "hIcieseis", "hIciesen"],
      ["hIciere", "hIcieres", "hIcieres", "hIciere", "hIciéremos", "hIciereis", "hIcieren"],
      ["💃🏻", "haZ", "hacé", "haGa", "haGamos", "haced", "haGan"],
      ["💃🏻", "no haGas", "no haGas", "no haGa", "no haGamos", "no haGáis", "no haGan"],
      ["hE hECHo", "haS hECHo", "haS hECHo", "hA hECHo", "hEmos hECHo", "habéis hECHo", "haN hECHo"],
      ["hUBE hECHo", "hUbiste hECHo", "hUbiste hECHo", "hUBO hECHo", "hUbimos hECHo", "hUbisteis hECHo", "hUbieron hECHo"],
      ["había hECHo", "habías hECHo", "habías hECHo", "había hECHo", "habíamos hECHo", "habíais hECHo", "habían hECHo"],
      ["habRé hECHo", "habRás hECHo", "habRás hECHo", "habRá hECHo", "habRemos hECHo", "habRéis hECHo", "habRán hECHo"],
      ["habRía hECHo", "habRías hECHo", "habRías hECHo", "habRía hECHo", "habRíamos hECHo", "habRíais hECHo", "habRían hECHo"],
      ["haYa hECHo", "haYas hECHo", "haYas hECHo", "haYa hECHo", "haYamos hECHo", "haYáis hECHo", "haYan hECHo"],
      ["hUbiera hECHo", "hUbieras hECHo", "hUbieras hECHo", "hUbiera hECHo", "hUbiéramos hECHo", "hUbierais hECHo", "hUbieran hECHo"],
      ["hUbiese hECHo", "hUbieses hECHo", "hUbieses hECHo", "hUbiese hECHo", "hUbiésemos hECHo", "hUbieseis hECHo", "hUbiesen hECHo"],
      ["hUbiere hECHo", "hUbieres hECHo", "hUbieres hECHo", "hUbiere hECHo", "hUbiéremos hECHo", "hUbiereis hECHo", "hUbieren hECHo"]
      ])
  }

  func testVerb(_ verb: String, participio: String, gerundio: String, raízFutura: String, translation: String, conjugations: [[String]]) {
    [(participio, Tense.participio), (gerundio, Tense.gerundio), (raízFutura, Tense.raízFutura), (translation, .translation)].forEach {
      let result = Conjugator.shared.conjugate(infinitive: verb, tense: $0.1, personNumber: .none)
      switch result {
      case let .success(value):
        XCTAssertEqual(value, $0.0)
      default:
        XCTFail("Unable to determine \($0.1.displayName) for \(verb).")
      }
    }

    for (tenseIndex, tense) in Tense.conjugatedTenses.enumerated() {
      for (personNumberIndex, personNumber) in PersonNumber.actualPersonNumbers.enumerated() {
        if personNumber == .firstSingular && (tense == .imperativoPositivo || tense == .imperativoNegativo) {
          continue
        }
        let result = Conjugator.shared.conjugate(infinitive: verb, tense: tense, personNumber: personNumber)
        switch result {
        case let .success(value):
          XCTAssertEqual(value, conjugations[tenseIndex][personNumberIndex], "\(personNumber.pronoun) \(tense.displayName)")
        default:
          XCTFail("Conjugation of \(verb) for tense \(tense.displayName), personNumber \(personNumber.pronoun) failed.")
        }
      }
    }
  }
}
