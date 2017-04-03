//
//  VerbLoader.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/2/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

struct VerbLoader {
    // TODO: Get the conjugations from an XML file.
  
  static func loadVerbs() -> [String: [String: String]] {
    var verbs: [String: [String: String]] = [:]

    var hablar: [String: String] = [:]
    hablar[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "hablo"
    hablar[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "hablas"
    hablar[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "habla"
    hablar[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "hablamos"
    hablar[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "habláis"
    hablar[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "hablan"
    hablar[Tense.gerundio.rawValue] = "hablando"
    hablar[Tense.participio.rawValue] = "hablado"
    verbs["hablar"] = hablar

    var comer: [String: String] = [:]
    comer[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "como"
    comer[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "comes"
    comer[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "come"
    comer[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "comemos"
    comer[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "coméis"
    comer[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "comen"
    comer[Tense.gerundio.rawValue] = "comiendo"
    comer[Tense.participio.rawValue] = "comido"
    verbs["comer"] = comer

    var subir: [String: String] = [:]
    subir[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "subu"
    subir[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "subes"
    subir[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "sube"
    subir[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "subimos"
    subir[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "subís"
    subir[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "suben"
    subir[Tense.gerundio.rawValue] = "subiendo"
    subir[Tense.participio.rawValue] = "subido"
    verbs["subir"] = subir

    var estar: [String: String] = [:]
    estar[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "estoy"
    estar[Conjugator.parent] = "hablar"
    estar[Conjugator.trim] = "habl"
    estar[Conjugator.stem] = "est"
    verbs["estar"] = estar
    
    var conocer: [String: String] = [:]
    conocer[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "conozco"
    conocer[Conjugator.parent] = "comer"
    conocer[Conjugator.trim] = "com"
    conocer[Conjugator.stem] = "conoc"
    verbs["conocer"] = conocer
    
    var reconocer: [String: String] = [:]
    reconocer[Conjugator.parent] = "conocer"
    reconocer[Conjugator.trim] = ""
    reconocer[Conjugator.stem] = "re"
    verbs["reconocer"] = reconocer

    var morder: [String: String] = [:]
    morder[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "muerdo"
    morder[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "muerdes"
    morder[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "muerde"
    morder[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "muerden"
    morder[Conjugator.parent] = "comer"
    morder[Conjugator.trim] = "com"
    morder[Conjugator.stem] = "mord"
    verbs["morder"] = morder

    var promover: [String: String] = [:]
    promover[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "promuevo"
    promover[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "promueves"
    promover[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = "promueve"
    promover[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = "promueven"
    promover[Conjugator.parent] = "comer"
    promover[Conjugator.trim] = "com"
    promover[Conjugator.stem] = "promov"
    verbs["promover"] = promover
    
    var llover: [String: String] = [:]
    llover[Conjugator.parent] = "promover"
    llover[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = Conjugator.defective
    llover[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = Conjugator.defective
    llover[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = Conjugator.defective
    llover[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = Conjugator.defective
    llover[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = Conjugator.defective
    llover[Conjugator.trim] = "prom"
    llover[Conjugator.stem] = "ll"
    verbs["llover"] = llover
    
    return verbs
  }
}
