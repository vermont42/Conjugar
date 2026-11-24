//
//  RecognitionChoicesView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// A Name the Form question's prompt, the form to name, its irregular letters in red. The verb and
/// its gloss are what the question asks for, so neither is shown.
struct RecognitionPromptView: View {
  let prompt: String

  var body: some View {
    VStack(spacing: 4) {
      Text(L.Recognition.promptHeading)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)

      ConjugationText(form: prompt)
        .font(.largeTitle.bold())
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .speakOnTapFlash(ConjugationText.plain(prompt))
        .accessibilityHint(L.Recognition.promptHeading)
        .accessibilityIdentifier("recognition_prompt")
    }
  }
}

/// The level's tenses under their moods' headings, then the chosen tense's persons, as chips. The
/// gerundio has no person, so the row of persons disappears for it, and a person the newly chosen
/// tense lacks, such as yo in a command, is cleared.
struct RecognitionChoicesView: View {
  let recognition: RecognitionQuestion
  @Binding var tense: DisplayTense?
  @Binding var personNumber: DisplayPersonNumber?
  /// True while a correction holds, when the choices stay as answered.
  let isLocked: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      heading(L.Recognition.tenseHeading)

      ForEach(moods, id: \.self) { mood in
        VStack(alignment: .leading, spacing: 6) {
          if let moodHeading = mood.heading {
            Text(Self.spanish(moodHeading))
              .font(.caption.bold())
              .foregroundStyle(.secondary)
              .accessibilityAddTraits(.isHeader)
          }

          FlowLayout(spacing: Layout.defaultSpacing) {
            ForEach(mood.tenses.filter { recognition.choice(for: $0) != nil }, id: \.self) { choice in
              chip(choice.recognitionChipName, spokenAs: choice.displayName, isSelected: tense == choice, identifier: "recognition_tense_\(choice.rawValue)") {
                choose(choice)
              }
            }
          }
        }
      }

      if let tense, let choice = recognition.choice(for: tense), !choice.personNumbers.isEmpty {
        heading(L.Recognition.personHeading)
          .padding(.top, 4)

        FlowLayout(spacing: Layout.defaultSpacing) {
          ForEach(choice.personNumbers, id: \.self) { person in
            let label = RecognitionQuestion.personLabel(person, in: tense)
            chip(label, spokenAs: label, isSelected: personNumber == person, identifier: "recognition_person_\(person.rawValue)") {
              personNumber = person
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .disabled(isLocked)
    .sensoryFeedback(.selection, trigger: tense)
    .sensoryFeedback(.selection, trigger: personNumber)
  }

  /// The moods the level asks a tense of.
  private var moods: [RecognitionMood] {
    RecognitionMood.allCases.filter { mood in
      mood.tenses.contains { recognition.choice(for: $0) != nil }
    }
  }

  private func choose(_ choice: DisplayTense) {
    tense = choice
    let persons = recognition.choice(for: choice)?.personNumbers ?? []
    if let personNumber, !persons.contains(personNumber) {
      self.personNumber = nil
    }
  }

  private func heading(_ text: String) -> some View {
    Text(text)
      .font(.subheadline.bold())
      .foregroundStyle(Color.customYellow)
      .accessibilityAddTraits(.isHeader)
  }

  private func chip(_ text: String, spokenAs spoken: String, isSelected: Bool, identifier: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(Self.spanish(text))
        .font(.subheadline)
        .fontDesign(.serif)
        .foregroundStyle(isSelected ? Color.customBackground : Color.customYellow)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isSelected ? Color.customYellow : Color.customYellow.opacity(0.08), in: Capsule())
        .overlay {
          Capsule()
            .strokeBorder(Color.customYellow.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
        }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    // A chip reads its tense's whole name, since its mood's heading is a separate element.
    .accessibilityLabel(Text(Self.spanish(spoken)))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityIdentifier(identifier)
  }

  /// Spanish text that VoiceOver reads in Spanish, whatever the device's language.
  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}
