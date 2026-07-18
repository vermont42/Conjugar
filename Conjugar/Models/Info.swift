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
  /// A locale-independent ASCII key for this article, stable across languages and
  /// across `heading` rewordings. `InfoBrowseView` renders it as the row's
  /// `accessibilityIdentifier` (`info_row_<stableKey>`), which is what the App
  /// Store screenshot driver navigates by — see `docs/screenshot-playbook.md`.
  ///
  /// It cannot be derived from `heading`: the About headings are localized
  /// (`L.Info.purposeAndUseHeading` → "Purpose and Use" / "Propósito y uso"), so a
  /// derived key would differ between `en` and `es` runs. The tense headings are
  /// hardcoded Spanish, but keying half the list one way and half another would be
  /// worse than spelling all of them out. Keep new keys `snake_case`, ASCII-only,
  /// and **hyphen-free** — the driver's id predicate treats "-" as a prefix
  /// boundary.
  let stableKey: String
  let difficulty: Difficulty
  let section: InfoSection
  let richTextBlocks: [RichTextBlock]

  private init(heading: String, stableKey: String, difficulty: Difficulty, section: InfoSection, text: String) {
    self.heading = heading
    self.stableKey = stableKey
    self.difficulty = difficulty
    self.section = section
    richTextBlocks = text.richTextBlocks
  }

  static let infos: [Info] = [
    Info(heading: L.Info.purposeAndUseHeading, stableKey: "purpose_and_use", difficulty: .easy, section: .about, text: L.Info.purposeAndUseText),
    Info(heading: L.Info.terminologyHeading, stableKey: "terminology", difficulty: .easy, section: .about, text: L.Info.terminologyText),
    Info(heading: "Presente de Indicativo", stableKey: "presente_de_indicativo", difficulty: .easy, section: .tenses, text: L.Info.presenteDeIndicativoText),
    Info(heading: "Futuro de Indicativo", stableKey: "futuro_de_indicativo", difficulty: .easy, section: .tenses, text: L.Info.futuroDeIndicativoText),
    Info(heading: "Pretérito", stableKey: "preterito", difficulty: .easy, section: .tenses, text: L.Info.preteritoText),
    Info(heading: "Condicional", stableKey: "condicional", difficulty: .moderate, section: .tenses, text: L.Info.condicionalText),
    Info(heading: "Imperfecto de Indicativo", stableKey: "imperfecto_de_indicativo", difficulty: .moderate, section: .tenses, text: L.Info.imperfectoDeIndicativoText),
    Info(heading: "Presente de Subjuntivo", stableKey: "presente_de_subjuntivo", difficulty: .moderate, section: .tenses, text: L.Info.presenteDeSubjuntivoText),
    Info(heading: "Imperfecto de Subjuntivo 1", stableKey: "imperfecto_de_subjuntivo_1", difficulty: .difficult, section: .tenses, text: L.Info.imperfectoDeSubjuntivo1Text),
    Info(heading: "Imperfecto de Subjuntivo 2", stableKey: "imperfecto_de_subjuntivo_2", difficulty: .difficult, section: .tenses, text: L.Info.imperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro de Subjuntivo", stableKey: "futuro_de_subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.futuroDeSubjuntivoText),
    Info(heading: "Imperativo Positivo", stableKey: "imperativo_positivo", difficulty: .moderate, section: .tenses, text: L.Info.imperativoPositivoText),
    Info(heading: "Imperativo Negativo", stableKey: "imperativo_negativo", difficulty: .moderate, section: .tenses, text: L.Info.imperativoNegativoText),
    Info(heading: "Participio", stableKey: "participio", difficulty: .moderate, section: .tenses, text: L.Info.participioText),
    Info(heading: "Gerundio", stableKey: "gerundio", difficulty: .moderate, section: .tenses, text: L.Info.gerundioText),
    Info(heading: "Raíz Futura", stableKey: "raiz_futura", difficulty: .easy, section: .tenses, text: L.Info.raizFuturaText),
    Info(heading: "Perfecto de Indicativo", stableKey: "perfecto_de_indicativo", difficulty: .moderate, section: .tenses, text: L.Info.perfectoDeIndicativoText),
    Info(heading: "Pretérito Anterior", stableKey: "preterito_anterior", difficulty: .difficult, section: .tenses, text: L.Info.preteritoAnteriorText),
    Info(heading: "Pluscuamperfecto de Indicativo", stableKey: "pluscuamperfecto_de_indicativo", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeIndicativoText),
    Info(heading: "Futuro Perfecto", stableKey: "futuro_perfecto", difficulty: .difficult, section: .tenses, text: L.Info.futuroPerfectoText),
    Info(heading: "Condicional Compuesto", stableKey: "condicional_compuesto", difficulty: .difficult, section: .tenses, text: L.Info.condicionalCompuestoText),
    Info(heading: "Perfecto de Subjuntivo", stableKey: "perfecto_de_subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.perfectoDeSubjuntivoText),
    Info(heading: "Pluscuamperfecto de Subjuntivo 1", stableKey: "pluscuamperfecto_de_subjuntivo_1", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeSubjuntivo1Text),
    Info(heading: "Pluscuamperfecto de Subjuntivo 2", stableKey: "pluscuamperfecto_de_subjuntivo_2", difficulty: .difficult, section: .tenses, text: L.Info.pluscuamperfectoDeSubjuntivo2Text),
    Info(heading: "Futuro Perfecto de Subjuntivo", stableKey: "futuro_perfecto_de_subjuntivo", difficulty: .difficult, section: .tenses, text: L.Info.futuroPerfectoDeSubjuntivoText),
    Info(heading: L.Info.questionsAndAnswersHeading, stableKey: "questions_and_answers", difficulty: .easy, section: .about, text: L.Info.questionsAndAnswersText),
    Info(heading: "Voseo", stableKey: "voseo", difficulty: .easy, section: .about, text: L.Info.voseoText),
    Info(heading: L.Info.creditsHeading, stableKey: "credits", difficulty: .easy, section: .about, text: L.Info.creditsText)
  ]

  /// Find the Info whose heading matches `heading` (case-insensitive), for
  /// resolving a `%…%` cross-reference tapped in an article body.
  static func info(forHeading heading: String) -> Info? {
    infos.first { $0.heading.lowercased() == heading.lowercased() }
  }
}
