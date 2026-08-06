//
//  TutorTestView.swift
//  Conjugar
//
//  A batch harness for the conjugation tutor. Runs a fixed
//  set of queries (Spanish or English, chosen by the system language), one per
//  fresh session, and shows/share-exports the results — a quick way to eyeball
//  whether the on-device model + `ConjugationTool` behave across tenses, off-topic
//  redirects, and grammar-concept questions. Reached via the hidden triple-tap on
//  `TutorView`'s navigation title.
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

private struct TutorTestResult: Identifiable {
  let id = UUID()
  let index: Int
  let query: String
  let response: String
  let isError: Bool
}

struct TutorTestView: View {
  @State private var results: [TutorTestResult] = []
  @State private var currentIndex = 0
  @State private var isRunning = false

  @Environment(\.dismiss) private var dismiss

  private static let englishQueries = [
    "How do you conjugate hablar in the pretérito?",
    "What is the imperfecto of ir?",
    "Conjugate tener in the presente.",
    "What is the presente de subjuntivo of ser?",
    "What is the participio of hacer?",
    "Conjugate vivir in the futuro.",
    "How is dar conjugated in the present indicative?",
    "What is the pretérito of poder?",
    "Conjugate estar in the presente.",
    "What is the gerundio of decir?",
    "What is the imperative of venir?",
    "How do you say “I would have spoken” in Spanish?",
    "What is the difference between the pretérito and the imperfecto?",
    "How do you conjugate pizza?",
    "Tell me about the weather.",
    "What is the condicional of querer?",
    "Conjugate escribir in the pluscuamperfecto de indicativo.",
    "What is the futuro perfecto of salir?",
    "What is the condicional compuesto of deber?",
    "What is the imperfecto de subjuntivo of pedir?",
    "How do you conjugate llevar in the past?",
    "Conjugate comer in the presente.",
    "What is the pretérito of nacer?",
    "What is the condicional of poder?",
    "What is the participio of leer?",
    "What is the imperative of ir?",
    "Conjugate lavarse in the pretérito.",
    "What is the gerundio of dormir?",
    "Conjugate deber in the futuro.",
    "When do you use the subjunctive?"
  ]

  private static let spanishQueries = [
    "¿Cómo se conjuga hablar en el pretérito?",
    "¿Cuál es el imperfecto de ir?",
    "Conjuga tener en el presente.",
    "¿Cuál es el presente de subjuntivo de ser?",
    "¿Cuál es el participio de hacer?",
    "Conjuga vivir en el futuro.",
    "¿Cómo se conjuga dar en el presente de indicativo?",
    "¿Cuál es el pretérito de poder?",
    "Conjuga estar en el presente.",
    "¿Cuál es el gerundio de decir?",
    "¿Cuál es el imperativo de venir?",
    "¿Cuál es la forma «yo» de hablar en el condicional compuesto?",
    "¿Cuál es la diferencia entre el pretérito y el imperfecto?",
    "¿Cómo se conjuga pizza?",
    "Háblame del tiempo.",
    "¿Cuál es el condicional de querer?",
    "Conjuga escribir en el pluscuamperfecto de indicativo.",
    "¿Cuál es el futuro perfecto de salir?",
    "¿Cuál es el condicional compuesto de deber?",
    "¿Cuál es el imperfecto de subjuntivo de pedir?",
    "¿Cómo se conjuga llevar en el pasado?",
    "Conjuga comer en el presente.",
    "¿Cuál es el pretérito de nacer?",
    "¿Cuál es el condicional de poder?",
    "¿Cuál es el participio de leer?",
    "¿Cuál es el imperativo de ir?",
    "Conjuga lavarse en el pretérito.",
    "¿Cuál es el gerundio de dormir?",
    "Conjuga deber en el futuro.",
    "¿Cuándo se usa el subjuntivo?"
  ]

  private static var queries: [String] {
    Locale.current.language.languageCode?.identifier == "es" ? spanishQueries : englishQueries
  }

  private static var totalTestCount: Int {
    queries.count
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
          statusBanner

          ForEach(results) { result in
            resultCard(result)
          }
        }
        .padding(Layout.doubleDefaultSpacing)
        // Cap the batch-results column to a reading-width measure, centered. No-op on
        // iPhone (narrower than the cap).
        .readingWidth()
      }
      .background(Color.customBackground)
      .navigationTitle(Text(verbatim: "Tutor Tests"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(L.Alert.okay) {
            dismiss()
          }
        }
        if !isRunning && results.count == Self.totalTestCount {
          ToolbarItem(placement: .primaryAction) {
            ShareLink(item: shareReport)
          }
        }
      }
      .task {
        await runAllTests()
      }
    }
  }

  @ViewBuilder
  private var statusBanner: some View {
    if isRunning {
      HStack(spacing: Layout.defaultSpacing) {
        ProgressView()
        Text(verbatim: "Running test \(currentIndex) of \(Self.totalTestCount)…")
          .foregroundStyle(Color.customForeground)
          .font(.subheadline)
      }
    } else if results.count == Self.totalTestCount {
      let errorCount = results.filter(\.isError).count
      Text(verbatim: errorCount == 0
        ? "All \(Self.totalTestCount) tests complete."
        : "Done. \(errorCount) of \(Self.totalTestCount) returned errors.")
        .foregroundStyle(Color.customBlue)
        .font(.subheadline.weight(.semibold))
    }
  }

  private func resultCard(_ result: TutorTestResult) -> some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(verbatim: "#\(result.index)")
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.customBlue)

      Text(result.query)
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Color.customForeground)

      Text(result.response)
        .font(.caption)
        .foregroundStyle(result.isError ? Color.customRed : Color.customForeground)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(Layout.defaultSpacing + 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: Layout.cornerRadius)
        .fill(Color.customCardBackground)
        .shadow(radius: 1)
    )
  }

  private var shareReport: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    let date = dateFormatter.string(from: Date())
    var lines = ["Tutor Test Results — \(date)", ""]
    for result in results {
      lines.append("#\(result.index) \(result.query)")
      lines.append("Response: \(result.response)")
      lines.append("")
    }
    return lines.joined(separator: "\n")
  }

  private func runAllTests() async {
    guard Current.languageModelService.isAvailable else {
      results.append(TutorTestResult(
        index: 0,
        query: "Availability check",
        response: "Language model is not available.",
        isError: true
      ))
      Current.soundPlayer.play(.chirp, shouldDebounce: false)
      return
    }

    isRunning = true
    for (index, query) in Self.queries.enumerated() {
      currentIndex = index + 1
      Current.languageModelService.resetTutorSession()
      do {
        let response = try await Current.languageModelService.sendTutorMessage(query)
        results.append(TutorTestResult(
          index: index + 1,
          query: query,
          response: response,
          isError: false
        ))
        Current.soundPlayer.play(.chirp, shouldDebounce: false)
      } catch {
        results.append(TutorTestResult(
          index: index + 1,
          query: query,
          response: "Error: \(error.localizedDescription)",
          isError: true
        ))
        Current.soundPlayer.play(.chirp, shouldDebounce: false)
      }
    }

    isRunning = false
  }
}
