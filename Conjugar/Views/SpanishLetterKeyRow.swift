//
//  SpanishLetterKeyRow.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The letters an English keyboard lacks, as a row of keys. The caller decides where a letter
/// goes, so that a field tracking its selection can insert at the cursor; the verb search
/// appends, and the quiz's answer field is to adopt the row as well.
struct SpanishLetterKeyRow: View {
  static let letters = ["á", "é", "í", "ó", "ú", "ü", "ñ"]

  let insert: (String) -> Void

  var body: some View {
    HStack(spacing: 6) {
      ForEach(Self.letters, id: \.self) { letter in
        Button {
          insert(letter)
        } label: {
          Text(Self.spanish(letter))
            .font(.title3)
            .linguistic()
            .frame(minWidth: 40, minHeight: 40)
        }
        // Seven .bordered keys overflow an iPhone, so the keys take the app's own tinted
        // rectangle, which has no padding of its own.
        .buttonStyle(LetterKeyButtonStyle())
        .accessibilityIdentifier("spanish_letter_key_\(letter)")
      }
    }
  }

  /// Tagged Spanish, so that VoiceOver names ñ as eñe rather than spelling it in English.
  private static func spanish(_ letter: String) -> AttributedString {
    var text = AttributedString(letter)
    text.languageIdentifier = "es"
    return text
  }
}

private struct LetterKeyButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(Color.customYellow)
      .background(Color.customYellow.opacity(configuration.isPressed ? 0.3 : 0.12), in: RoundedRectangle(cornerRadius: Layout.defaultSpacing))
      .overlay(RoundedRectangle(cornerRadius: Layout.defaultSpacing).strokeBorder(Color.customYellow.opacity(0.35), lineWidth: 1))
      .contentShape(Rectangle())
  }
}

#Preview {
  SpanishLetterKeyRow { _ in }
}
