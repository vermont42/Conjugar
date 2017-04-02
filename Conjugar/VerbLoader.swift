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
    hablar["fs" + "pr"] = "hablo"
    hablar["fp" + "pr"] = "hablamos"
    hablar["ss" + "pr"] = "hablas"
    hablar["sp" + "pr"] = "habláis"
    hablar["ts" + "pr"] = "habla"
    hablar["tp" + "pr"] = "hablan"
    hablar["ge"] = "hablando"
    hablar["po"] = "hablado"
    verbs["hablar"] = hablar

    var comer: [String: String] = [:]
    comer["fs" + "pr"] = "como"
    comer["fp" + "pr"] = "comemos"
    comer["ss" + "pr"] = "comes"
    comer["sp" + "pr"] = "coméis"
    comer["ts" + "pr"] = "come"
    comer["tp" + "pr"] = "comen"
    comer["ge"] = "comiendo"
    comer["po"] = "comido"
    verbs["comer"] = comer

    var subir: [String: String] = [:]
    subir["fs" + "pr"] = "subu"
    subir["fp" + "pr"] = "subimos"
    subir["ss" + "pr"] = "subes"
    subir["sp" + "pr"] = "subís"
    subir["ts" + "pr"] = "sube"
    subir["tp" + "pr"] = "suben"
    subir["ge"] = "subiendo"
    subir["po"] = "subido"
    verbs["subir"] = subir

    var estar: [String: String] = [:]
    estar["fs" + "pr"] = "estoy"
    estar["parent"] = "hablar"
    estar["trim"] = "habl"
    estar["stem"] = "est"
    verbs["estar"] = estar
    
    var conocer: [String: String] = [:]
    conocer["fs" + "pr"] = "conozco"
    conocer["parent"] = "comer"
    conocer["trim"] = "com"
    conocer["stem"] = "conoc"
    verbs["conocer"] = conocer
    
    var reconocer: [String: String] = [:]
    reconocer["parent"] = "conocer"
    reconocer["trim"] = ""
    reconocer["stem"] = "re"
    verbs["reconocer"] = reconocer

    var morder: [String: String] = [:]
    morder["fs" + "pr"] = "muerdo"
    morder["ss" + "pr"] = "muerdes"
    morder["ts" + "pr"] = "muerde"
    morder["tp" + "pr"] = "muerden"
    morder["parent"] = "comer"
    morder["trim"] = "com"
    morder["stem"] = "mord"
    verbs["morder"] = morder

    var promover: [String: String] = [:]
    promover["fs" + "pr"] = "promuevo"
    promover["ss" + "pr"] = "promueves"
    promover["ts" + "pr"] = "promueve"
    promover["tp" + "pr"] = "promueven"
    promover["parent"] = "comer"
    promover["trim"] = "com"
    promover["stem"] = "promov"
    verbs["promover"] = promover
    
    var llover: [String: String] = [:]
    llover["parent"] = "promover"
    llover["fs" + "pr"] = Conjugator.defective
    llover["ss" + "pr"] = Conjugator.defective
    llover["fp" + "pr"] = Conjugator.defective
    llover["sp" + "pr"] = Conjugator.defective
    llover["tp" + "pr"] = Conjugator.defective
    llover["trim"] = "prom"
    llover["stem"] = "ll"
    verbs["llover"] = llover
    
    return verbs
  }
}
