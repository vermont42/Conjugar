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
        )
      ],
      gerundio: "teniendo",
      participio: "tenido",
      exampleSpanish: "No tengo tiempo que perder en estas discusiones.",
      exampleEnglish: "I have no time to lose on these arguments.",
      exampleAttribution: "— Benito Pérez Galdós, Fortunata y Jacinta (1887)",
      etymologySnippet: "Spanish ~tener~ comes from Latin ~tenēre~ (“to hold, keep, grasp”), from the Proto-Indo-European root *~ten-~ (“to stretch”) — holding conceived as keeping something taut in the hand.",
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
