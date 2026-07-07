//
//  SnapshotReader.swift
//  ConjugarWidget
//
//  Reads and decodes the JSON snapshot the app writes into the App Group container,
//  and supplies a static placeholder for the widget gallery / redacted states.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

nonisolated enum SnapshotReader {
  static func read() -> WidgetSnapshot? {
    guard
      let url = WidgetConstants.snapshotURL,
      let data = try? Data(contentsOf: url),
      let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    else {
      return nil
    }
    return snapshot
  }

  /// A representative snapshot used before the app has written a real one (widget
  /// gallery, placeholder, previews). "tener" — the archetypal irregular.
  static var placeholder: WidgetSnapshot {
    WidgetSnapshot(
      infinitive: "tener",
      gloss: "to have",
      frequencyRank: 8,
      paradigms: [
        WidgetParadigm(
          tenseDisplay: "Presente de Indicativo",
          conjugations: [
            WidgetConjugation(pronoun: "yo", form: "tenGO"),
            WidgetConjugation(pronoun: "tú", form: "tiEnes"),
            WidgetConjugation(pronoun: "él", form: "tiEne"),
            WidgetConjugation(pronoun: "nosotros", form: "tenemos"),
            WidgetConjugation(pronoun: "vosotros", form: "tenéis"),
            WidgetConjugation(pronoun: "ellos", form: "tiEnen")
          ]
        ),
        WidgetParadigm(
          tenseDisplay: "Pretérito",
          conjugations: [
            WidgetConjugation(pronoun: "yo", form: "tUVE"),
            WidgetConjugation(pronoun: "tú", form: "tUVIste"),
            WidgetConjugation(pronoun: "él", form: "tUVo"),
            WidgetConjugation(pronoun: "nosotros", form: "tUVImos"),
            WidgetConjugation(pronoun: "vosotros", form: "tUVIsteis"),
            WidgetConjugation(pronoun: "ellos", form: "tUVIeron")
          ]
        )
      ],
      gerundio: "teniendo",
      participio: "tenido",
      quizQuestion: WidgetQuizQuestion(
        infinitive: "tener",
        tenseDisplay: "Presente de Indicativo",
        pronoun: "yo",
        correctAnswer: "tenGO",
        wrongAnswers: ["teno", "tiEno", "tengué"],
        questionID: "placeholder"
      ),
      dateString: "2026-01-01"
    )
  }
}
