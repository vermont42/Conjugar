//
//  Info.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//
//  Rewritten as a SwiftUI-native model during the SwiftUI migration (Step 4):
//  the heading renders separately and the body is parsed into `richTextBlocks`
//  (see RichText.swift) instead of the legacy `infoString` NSAttributedString.
//

import Foundation

/// Which list section an Info article belongs to. The `Tenses` section is what the
/// difficulty filter meaningfully narrows (the `About` articles are all `.easy`, so
/// they show under every filter level).
enum InfoSection {
  case about
  case tenses
}

struct Info: Hashable, Identifiable {
  var id: String { heading }
  let heading: String
  let difficulty: Difficulty
  let section: InfoSection
  let richTextBlocks: [RichTextBlock]

  private init(heading: String, difficulty: Difficulty, section: InfoSection, text: String) {
    self.heading = heading
    self.difficulty = difficulty
    self.section = section
    richTextBlocks = text.richTextBlocks
  }

  static let infos: [Info] = [
    Info(heading: L.Info.purposeAndUseHeading, difficulty: .easy, section: .about, text: L.Info.purposeAndUseText),
    Info(heading: L.Info.terminologyHeading, difficulty: .easy, section: .about, text: L.Info.terminologyText),
    Info(heading: "Presente de Indicativo", difficulty: .easy, section: .tenses, text: L.Info.presenteDeIndicativoText),
    Info(heading: "Futuro de Indicativo", difficulty: .easy, section: .tenses, text: L.Info.futuroDeIndicativoText),
    Info(heading: "Pretérito", difficulty: .easy, section: .tenses, text: L.Info.preteritoText),
    Info(heading: "Condicional", difficulty: .moderate, section: .tenses, text: L.Info.condicionalText),
    Info(heading: "Imperfecto de Indicativo", difficulty: .moderate, section: .tenses, text: L.Info.imperfectoDeIndicativoText),
    Info(heading: "Presente de Subjuntivo", difficulty: .moderate, section: .tenses, text: L.Info.presenteDeSubjuntivoText),
    Info(heading: "Imperfecto de Subjuntivo 1", difficulty: .difficult, section: .tenses, text: L.Info.imperfectoDeSubjuntivo1Text),
    Info(heading: "Imperfecto de Subjuntivo 2", difficulty: .difficult, section: .tenses, text: L.Info.imperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro de Subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.futuroDeSubjuntivoText),
    Info(heading: "Imperativo Positivo", difficulty: .moderate, section: .tenses, text: L.Info.imperativoPositivoText),
    Info(heading: "Imperativo Negativo", difficulty: .moderate, section: .tenses, text: L.Info.imperativoNegativoText),
    Info(heading: "Participio", difficulty: .moderate, section: .tenses, text: L.Info.participioText),
    Info(heading: "Gerundio", difficulty: .moderate, section: .tenses, text: L.Info.gerundioText),
    Info(heading: "Raíz Futura", difficulty: .easy, section: .tenses, text: L.Info.raizFuturaText),
    Info(heading: "Perfecto de Indicativo", difficulty: .moderate, section: .tenses, text: L.Info.perfectoDeIndicativoText),
    Info(heading: "Pretérito Anterior", difficulty: .difficult, section: .tenses, text: L.Info.preteritoAnteriorText),
    Info(heading: "Pluscuamperfecto de Indicativo", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeIndicativoText),
    Info(heading: "Futuro Perfecto", difficulty: .difficult, section: .tenses, text: L.Info.futuroPerfectoText),
    Info(heading: "Condicional Compuesto", difficulty: .difficult, section: .tenses, text: L.Info.condicionalCompuestoText),
    Info(heading: "Perfecto de Subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.perfectoDeSubjuntivoText),
    Info(heading: "Pluscuamperfecto de Subjuntivo 1", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeSubjuntivo1Text),
    Info(heading: "Pluscuamperfecto de Subjuntivo 2", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro Perfecto de Subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.futuroPerfectoDeSubjuntivoText),
    Info(heading: L.Info.questionsAndAnswersHeading, difficulty: .easy, section: .about, text: L.Info.questionsAndAnswersText),
    Info(heading: "Voseo", difficulty: .easy, section: .about, text: L.Info.voseoText),
    Info(heading: L.Info.creditsHeading, difficulty: .easy, section: .about, text: L.Info.creditsText)
  ]

  /// Find the Info whose heading matches `heading` (case-insensitive), for
  /// resolving a `%…%` cross-reference tapped in an article body.
  static func info(forHeading heading: String) -> Info? {
    infos.first { $0.heading.lowercased() == heading.lowercased() }
  }
}
