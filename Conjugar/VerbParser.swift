//
//  VerbParser.swift
//  Conjugar
//
//  Created by Joshua Adams on 4/30/17.
//  Copyright (c) 2017 Josh Adams. All rights reserved.
//

import Foundation

class VerbParser: NSObject, XMLParserDelegate {
  private var parser: XMLParser?
  private var buffer = ""
  private let verbTag = "verb"
  private var verbs: [String: [String: String]] = [:]
  private var currentVerb = ""
  private var currentConjugations: [String: String] = [:]
  static let parseError = "An error occurred during XML parsing."
  
  override init() {
    // TODO: Spit out list of verbs using VerbLoader to build XML file.
    super.init()
    if let url = Bundle.main.url(forResource: "verbs", withExtension: "xml") {
      parser = XMLParser(contentsOf: url)
      if parser == nil {
        return
      }
      parser?.delegate = self
    }
  }
  
  func parse() -> [String: [String: String]] {
    parser?.parse()
    return verbs
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
    if elementName == verbTag {
      if let currentVerb = attributeDict[Tense.infinitivo.rawValue] {
        self.currentVerb = currentVerb
      }
      else {
        fatalError("No infinitive specified.")
      }
      if let vt = attributeDict[VerbType.key] {
        currentConjugations[VerbType.key] = vt
      }
      else {
        fatalError("No verb type specified.")
      }
      if let ge = attributeDict[Tense.gerundio.rawValue] {
        currentConjugations[Tense.gerundio.rawValue] = ge
      }
      if let po = attributeDict[Tense.participio.rawValue] {
        currentConjugations[Tense.participio.rawValue] = po
      }
      if let rf = attributeDict[Tense.raizFutura.rawValue] {
        currentConjugations[Tense.raizFutura.rawValue] = rf
      }
      if let pe = attributeDict[Conjugator.parent] {
        currentConjugations[Conjugator.parent] = pe
      }
      if let tn = attributeDict[Tense.translation.rawValue] {
        currentConjugations[Tense.translation.rawValue] = tn
      }
      if let tr = attributeDict[Conjugator.trim] {
        currentConjugations[Conjugator.trim] = tr
      }
      if let st = attributeDict[Conjugator.stem] {
        currentConjugations[Conjugator.stem] = st
      }
      if let io = attributeDict[PersonNumber.secondSingular.rawValue + Tense.imperativoPositivo.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue + Tense.imperativoPositivo.rawValue] = io
      }
      if let iv = attributeDict[PersonNumber.secondSingularVos.rawValue + Tense.imperativoPositivo.rawValue] {
        currentConjugations[PersonNumber.secondSingularVos.rawValue + Tense.imperativoPositivo.rawValue] = iv
      }
      if let fs = attributeDict[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.firstSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = fs
      }
      if let ss = attributeDict[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = ss
      }
      if let sv = attributeDict[PersonNumber.secondSingularVos.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.secondSingularVos.rawValue + Tense.presenteDeIndicativo.rawValue] = sv
      }
      if let ts = attributeDict[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.thirdSingular.rawValue + Tense.presenteDeIndicativo.rawValue] = ts
      }
      if let fp = attributeDict[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.firstPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = fp
      }
      if let sp = attributeDict[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.secondPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = sp
      }
      if let tp = attributeDict[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.thirdPlural.rawValue + Tense.presenteDeIndicativo.rawValue] = tp
      }
      if let fs = attributeDict[PersonNumber.firstSingular.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.firstSingular.rawValue + Tense.preterito.rawValue] = fs
      }
      if let ss = attributeDict[PersonNumber.secondSingular.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue + Tense.preterito.rawValue] = ss
        currentConjugations[PersonNumber.secondSingularVos.rawValue + Tense.preterito.rawValue] = ss
      }
      if let ts = attributeDict[PersonNumber.thirdSingular.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.thirdSingular.rawValue + Tense.preterito.rawValue] = ts
      }
      if let fp = attributeDict[PersonNumber.firstPlural.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.firstPlural.rawValue + Tense.preterito.rawValue] = fp
      }
      if let sp = attributeDict[PersonNumber.secondPlural.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.secondPlural.rawValue + Tense.preterito.rawValue] = sp
      }
      if let tp = attributeDict[PersonNumber.thirdPlural.rawValue + Tense.preterito.rawValue] {
        currentConjugations[PersonNumber.thirdPlural.rawValue + Tense.preterito.rawValue] = tp
      }
      if let fs = attributeDict[PersonNumber.firstSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.firstSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] = fs
      }
      if let ss = attributeDict[PersonNumber.secondSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] = ss
        currentConjugations[PersonNumber.secondSingularVos.rawValue + Tense.imperfectoDeIndicativo.rawValue] = ss
      }
      if let ts = attributeDict[PersonNumber.thirdSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.thirdSingular.rawValue + Tense.imperfectoDeIndicativo.rawValue] = ts
      }
      if let fp = attributeDict[PersonNumber.firstPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.firstPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] = fp
      }
      if let sp = attributeDict[PersonNumber.secondPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.secondPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] = sp
      }
      if let tp = attributeDict[PersonNumber.thirdPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] {
        currentConjugations[PersonNumber.thirdPlural.rawValue + Tense.imperfectoDeIndicativo.rawValue] = tp
      }
      if let fs = attributeDict[PersonNumber.firstSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.firstSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] = fs
      }
      if let ss = attributeDict[PersonNumber.secondSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] = ss
        currentConjugations[PersonNumber.secondSingularVos.rawValue + Tense.presenteDeSubjuntivo.rawValue] = ss
      }
      if let ts = attributeDict[PersonNumber.thirdSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.thirdSingular.rawValue + Tense.presenteDeSubjuntivo.rawValue] = ts
      }
      if let fp = attributeDict[PersonNumber.firstPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.firstPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] = fp
      }
      if let sp = attributeDict[PersonNumber.secondPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.secondPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] = sp
      }
      if let tp = attributeDict[PersonNumber.thirdPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] {
        currentConjugations[PersonNumber.thirdPlural.rawValue + Tense.presenteDeSubjuntivo.rawValue] = tp
      }
      if let fs = attributeDict[PersonNumber.firstSingular.rawValue] {
        currentConjugations[PersonNumber.firstSingular.rawValue] = fs
      }
      if let ss = attributeDict[PersonNumber.secondSingular.rawValue] {
        currentConjugations[PersonNumber.secondSingular.rawValue] = ss
      }
      if let sv = attributeDict[PersonNumber.secondSingularVos.rawValue] {
        currentConjugations[PersonNumber.secondSingularVos.rawValue] = sv
      }
      if let ts = attributeDict[PersonNumber.thirdSingular.rawValue] {
        currentConjugations[PersonNumber.thirdSingular.rawValue] = ts
      }
      if let fp = attributeDict[PersonNumber.firstPlural.rawValue] {
        currentConjugations[PersonNumber.firstPlural.rawValue] = fp
      }
      if let sp = attributeDict[PersonNumber.secondPlural.rawValue] {
        currentConjugations[PersonNumber.secondPlural.rawValue] = sp
      }
      if let tp = attributeDict[PersonNumber.thirdPlural.rawValue] {
        currentConjugations[PersonNumber.thirdPlural.rawValue] = tp
      }
    }
  }

  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if elementName == verbTag {
      verbs[currentVerb] = currentConjugations
      currentConjugations = [:]
    }
  }
}
