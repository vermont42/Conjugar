//
//  ModelPracticeCard.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A verb model's practice: Verb Essentials over the model's verbs alone, and mixed with the
/// models the learner knows. A single-verb model says why it has neither. A model the exercise
/// cannot ask, such as a regular one, shows nothing.
struct ModelPracticeCard: View {
  let classNumber: String
  /// False where the row above the card already says so.
  var showsKnown = true
  @State private var session: ModelPracticeSession?
  @Environment(\.isBeneathQuiz) private var isBeneathQuiz

  private static let partnerPreviewCount = 4

  var body: some View {
    // Opened from a quiz's held correction, a model starts no second quiz over the first.
    if !isBeneathQuiz, let group = ModelPracticeGroup.group(classNumber) {
      let record = Current.practice.record
      let partners = group.mixPartners(in: record)
      let isMarkedKnown = showsKnown && group.isKnown(in: record)

      VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
        // A single-verb model has no pattern to practice, so only a known one has a first line.
        if group.offersPracticeAlone || isMarkedKnown {
          HStack {
            if group.offersPracticeAlone {
              Text(L.ModelPractice.heading)
                .font(.subheadline.bold())
                .foregroundStyle(Color.customForeground)
                .accessibilityAddTraits(.isHeader)
            }

            Spacer()

            if isMarkedKnown {
              Label(L.ModelPractice.known, systemImage: "checkmark.seal.fill")
                .font(.caption.bold())
                .foregroundStyle(Color.customYellow)
                .accessibilityIdentifier("model_practice_known")
            }
          }
        }

        if group.offersPracticeAlone {
          Text(group.verbs.count < ModelPracticeGroup.verbLimit ? L.ModelPractice.descriptionAll : L.ModelPractice.descriptionFrequent)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
            .fixedSize(horizontal: false, vertical: true)

          HStack(spacing: Layout.defaultSpacing) {
            Button {
              session = ModelPracticeSession(classNumber: classNumber, mode: .alone)
            } label: {
              Label(L.ModelPractice.alone, systemImage: "square.stack.3d.up")
            }
            .accessibilityHint(L.ModelPractice.aloneHint)
            .accessibilityIdentifier("model_practice_alone_button")

            Button {
              session = ModelPracticeSession(classNumber: classNumber, mode: .mixed)
            } label: {
              Label(L.ModelPractice.mixed, systemImage: "shuffle")
            }
            .disabled(partners.isEmpty)
            .accessibilityHint(L.ModelPractice.mixedHint)
            .accessibilityIdentifier("model_practice_mixed_button")
          }
          .buttonStyle(.bordered)
          .tint(Color.customYellow)

          Text(partners.isEmpty ? AttributedString(L.ModelPractice.mixedLocked) : Self.mixedNote(partners: partners))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("model_practice_mixed_note")
        } else {
          Text(L.ModelPractice.singleVerb)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("model_practice_single_verb_note")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .card()
      .sheet(item: $session) { session in
        QuizSheet(scope: .modelPractice(session))
      }
    }
  }

  /// "Mixed adds verbs of the models you know: tener, pensar, volver, sentir …", the first known
  /// models by their exemplars, which VoiceOver reads in Spanish.
  private static func mixedNote(partners: [ModelPracticeGroup]) -> AttributedString {
    let shown = partners.prefix(partnerPreviewCount).map(\.exemplar)
    let exemplars = shown.joined(separator: ", ") + (partners.count > shown.count ? " …" : "")
    var note = AttributedString(L.ModelPractice.mixedWith(exemplars))
    if let range = note.range(of: exemplars, options: .backwards) {
      note[range].languageIdentifier = "es"
    }
    return note
  }
}
