//
//  Info.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

struct Info {
  let heading: String
  let difficulty: Difficulty
  let text: String
  let infoString: NSAttributedString

  private init(heading: String, difficulty: Difficulty, text: String) {
    guard let encodedHeading = heading.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
      fatalError("Could not URL encode heading \(heading).")
    }
    self.heading = encodedHeading
    self.difficulty = difficulty
    self.text = String(String.headingSeparator) + heading + String(String.headingSeparator) + "\n\n" + text
    infoString = self.text.infoString
  }

  static let infos: [Info] = [
    Info(heading: L.Info.purposeAndUseHeading, difficulty: .easy, text: L.Info.purposeAndUseText),
    Info(heading: L.Info.terminologyHeading, difficulty: .easy, text: L.Info.terminologyText),
    Info(heading: "Presente de Indicativo", difficulty: .easy, text: L.Info.presenteDeIndicativoText),
    Info(heading: "Futuro de Indicativo", difficulty: .easy, text: L.Info.futuroDeIndicativoText),
    Info(heading: "Pretérito", difficulty: .easy, text: L.Info.preteritoText),
    Info(heading: "Condicional", difficulty: .moderate, text: L.Info.condicionalText),
    Info(heading: "Imperfecto de Indicativo", difficulty: .moderate, text: L.Info.imperfectoDeIndicativoText),
    Info(heading: "Presente de Subjuntivo", difficulty: .moderate, text: L.Info.presenteDeSubjuntivoText),
    Info(heading: "Imperfecto de Subjuntivo 1", difficulty: .difficult, text: L.Info.imperfectoDeSubjuntivo1Text),
    Info(heading: "Imperfecto de Subjuntivo 2", difficulty: .difficult, text: L.Info.imperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro de Subjuntivo", difficulty: .difficult, text: L.Info.futuroDeSubjuntivoText),
    Info(heading: "Imperativo Positivo", difficulty: .moderate, text: L.Info.imperativoPositivoText),
    Info(heading: "Imperativo Negativo", difficulty: .moderate, text: L.Info.imperativoNegativoText),
    Info(heading: "Participio", difficulty: .moderate, text: L.Info.participioText),
    Info(heading: "Gerundio", difficulty: .moderate, text: L.Info.gerundioText),
    Info(heading: "Raíz Futura", difficulty: .easy, text: L.Info.raizFuturaText),
    Info(heading: "Perfecto de Indicativo", difficulty: .moderate, text: L.Info.perfectoDeIndicativoText),
    Info(heading: "Pretérito Anterior", difficulty: .difficult, text: L.Info.preteritoAnteriorText),
    Info(heading: "Pluscuamperfecto de Indicativo", difficulty: .difficult, text: L.Info.pluscuamperfectoDeIndicativoText),
    Info(heading: "Futuro Perfecto", difficulty: .difficult, text: L.Info.futuroPerfectoText),
    Info(heading: "Condicional Compuesto", difficulty: .difficult, text: L.Info.condicionalCompuestoText),
    Info(heading: "Perfecto de Subjuntivo", difficulty: .difficult, text: L.Info.perfectoDeSubjuntivoText),
    Info(heading: "Pluscuamperfecto de Subjuntivo 1", difficulty: .difficult, text: L.Info.pluscuamperfectoDeSubjuntivo1Text),
    Info(heading: "Pluscuamperfecto de Subjuntivo 2", difficulty: .difficult, text: L.Info.pluscuamperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro Perfecto de Subjuntivo", difficulty: .difficult, text: L.Info.futuroPerfectoDeSubjuntivoText),
    Info(heading: L.Info.questionsAndAnswersHeading, difficulty: .easy, text: L.Info.questionsAndAnswersText),
    Info(heading: "Voseo", difficulty: .easy, text: L.Info.voseoText),
    Info(heading: L.Info.creditsHeading, difficulty: .easy, text: L.Info.creditsText)
  ]
}
