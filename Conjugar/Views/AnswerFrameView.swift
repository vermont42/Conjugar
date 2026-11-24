//
//  AnswerFrameView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// An `AnswerFrame` drawn on one line: the words the learner does not type, then a rounded field
/// for the blank, then any closing punctuation, as in `(tú) ¡no [ ]!`. At accessibility text sizes
/// the leading words take a line of their own, so that the field keeps a usable width.
///
/// The field keeps its identity from one frame to the next, whether or not words precede it, so
/// that the keyboard keeps its focus as the questions change.
struct AnswerFrameView: View {
  let frame: AnswerFrame
  @Binding var text: String
  @Binding var selection: TextSelection?
  var isFocused: FocusState<Bool>.Binding
  let identifier: String
  /// Spanish that VoiceOver reads before the frame, such as the tense of a Verb Essentials row,
  /// which the screen shows above the field rather than in the frame.
  var spokenPrefix: String?
  let onSubmit: () -> Void
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    let layout = dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: Layout.defaultSpacing))
      : AnyLayout(HStackLayout(spacing: Layout.defaultSpacing))
    layout {
      if !frame.leading.isEmpty {
        frameText(frame.leading)
      }
      HStack(spacing: Layout.defaultSpacing / 2) {
        field
        if !frame.trailing.isEmpty {
          frameText(frame.trailing)
        }
      }
    }
    .font(.title3)
    .fontDesign(.serif)
  }

  private var field: some View {
    TextField(text: $text, selection: $selection, prompt: Text(L.Quiz.conjugation).foregroundStyle(.secondary)) {
      Text(verbatim: "")
    }
      .accessibilityLabel(spokenPrompt)
      .accessibilityIdentifier(identifier)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .submitLabel(.next)
      .focused(isFocused)
      .multilineTextAlignment(frame.leading.isEmpty ? .center : .leading)
      .padding()
      .background(Color.customForeground.opacity(0.06), in: RoundedRectangle(cornerRadius: Layout.cornerRadius))
      .overlay(
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
          .strokeBorder(isFocused.wrappedValue ? Color.customYellow : Color.customCardBorder, lineWidth: isFocused.wrappedValue ? 2 : 1)
      )
      .onSubmit(onSubmit)
  }

  /// The frame's words, each styled for what it is: whom a command addresses in the secondary
  /// color, and the subject pronoun, the supplied words, and the punctuation in the primary one.
  /// Hidden from VoiceOver, because the field's label reads the whole frame as one prompt.
  private func frameText(_ segments: [AnswerFrame.Segment]) -> some View {
    var pieces: [Text] = []
    var previous: AnswerFrame.Segment?
    for segment in segments {
      // ¡ sits against the word it opens, as in ¡no.
      if let previous, previous != .punctuation("¡") {
        pieces.append(Text(verbatim: " "))
      }
      switch segment {
      case .addressee(let addressee):
        pieces.append(Text(Self.spanish("(\(addressee))")).foregroundStyle(.secondary))
      case .pronoun(let word), .word(let word), .punctuation(let word):
        pieces.append(Text(Self.spanish(word)).fontWeight(.semibold).foregroundStyle(Color.customForeground))
      case .blank:
        break
      }
      previous = segment
    }
    return pieces.reduce(Text(verbatim: ""), +)
      .fixedSize()
      .accessibilityHidden(true)
  }

  /// "yo, blank", or "tú, no, blank", with the frame's Spanish read in Spanish, and with a prefix,
  /// "pretérito, yo, blank". A frame of only a blank keeps the field's plain name, after any
  /// prefix.
  private var spokenPrompt: Text {
    let parts = frame.spokenParts
    let prefix = spokenPrefix.map { [Text(Self.spanish($0))] } ?? []
    let pieces: [Text]
    if parts.contains(where: { $0 != nil }) {
      pieces = prefix + parts.map { part in
        part.map { Text(Self.spanish($0)) } ?? Text(L.Quiz.blank)
      }
    } else {
      pieces = prefix + [Text(L.Quiz.conjugation)]
    }
    return pieces.dropFirst().reduce(pieces[0]) { $0 + Text(verbatim: ", ") + $1 }
  }

  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}
