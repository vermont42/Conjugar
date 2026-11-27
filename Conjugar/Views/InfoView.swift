//
//  InfoView.swift
//  Conjugar
//
//  The Info-article detail screen: a serif gold title over reading-width body copy.
//  A tapped `%…%` term either opens an external URL or pushes the referenced Info
//  article via the `navigate` closure.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct InfoView: View {
  let info: Info
  /// Navigate to another Info article (a tapped `%…%` cross-reference).
  let navigate: (Info) -> Void

  var body: some View {
    ZStack {
      Color.customBackground
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text(info.heading)
            .font(.largeTitle.bold())
            .fontDesign(.serif)
            .foregroundStyle(Color.customYellow)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, Layout.defaultSpacing)
            .accessibilityAddTraits(.isHeader)

          namesBlock

          // The brand triad, echoing the app icon — a small decorative rule.
          HStack(spacing: 6) {
            Circle().fill(Color.customRed).frame(width: 4, height: 4)
            Circle().fill(Color.customYellow).frame(width: 4, height: 4)
            Circle().fill(Color.customBlue).frame(width: 4, height: 4)
          }
          .frame(maxWidth: .infinity)
          .padding(.bottom, Layout.doubleDefaultSpacing)
          .accessibilityHidden(true)

          RichTextView(blocks: info.richTextBlocks)
            .frame(maxWidth: Layout.readingWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Layout.doubleDefaultSpacing)
        .padding(.vertical, Layout.doubleDefaultSpacing)
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .onAppear { Current.analytics.signal(name: .viewInfoView) }
    .environment(\.openURL, OpenURLAction { url in handleInfoLink(url) })
  }

  /// The tense's names, for an article that a verb page's card opens. Empty for every other
  /// article, and for a tense that every system names as its heading does.
  private var names: [ConjugationTable.TenseName] {
    ConjugationTable.table(forArticle: info.stableKey)?.articleNames(spanishInterface: Self.spanishInterface) ?? []
  }

  /// Whether the interface is Spanish, whose articles name no tense in English.
  private static var spanishInterface: Bool {
    Locale.current.language.languageCode?.identifier == "es"
  }

  /// "English: preterite" over "Other names: pretérito perfecto simple · pretérito indefinido",
  /// centered under the heading. A Spanish article has only the second line.
  @ViewBuilder
  private var namesBlock: some View {
    let english = names.filter { !$0.isSpanish }
    let others = names.filter(\.isSpanish)
    if !names.isEmpty {
      VStack(spacing: 4) {
        if !english.isEmpty {
          namesLine(label: L.Info.englishNameLabel, names: english)
        }
        if !others.isEmpty {
          namesLine(label: L.Info.otherNamesLabel, names: others)
        }
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity, alignment: .center)
      .padding(.bottom, Layout.defaultSpacing)
    }
  }

  /// One line of names after its label. VoiceOver hears each name as its own element, in its own
  /// language, and the label with the first.
  private func namesLine(label: String, names: [ConjugationTable.TenseName]) -> some View {
    Text(Self.namesText(label: label, names: names))
      .fixedSize(horizontal: false, vertical: true)
      .accessibilityRepresentation {
        VStack {
          ForEach(Array(names.enumerated()), id: \.offset) { index, name in
            Text(index == 0 ? Self.labeled(label, Self.attributed(name)) : Self.attributed(name))
          }
        }
      }
  }

  private static func namesText(label: String, names: [ConjugationTable.TenseName]) -> AttributedString {
    var line = AttributedString()
    for (index, name) in names.enumerated() {
      if index > 0 {
        line.append(AttributedString(" · "))
      }
      line.append(attributed(name))
    }
    return labeled(label, line)
  }

  private static func labeled(_ label: String, _ text: AttributedString) -> AttributedString {
    AttributedString("\(label): ") + text
  }

  private static func attributed(_ name: ConjugationTable.TenseName) -> AttributedString {
    name.isSpanish ? AttributedString(spanish: name.text) : AttributedString(name.text)
  }

  private func handleInfoLink(_ url: URL) -> OpenURLAction.Result {
    let absolute = url.absoluteString
    if absolute.hasPrefix("http") {
      return .systemAction
    }
    let cleaned = absolute.removingPercentEncoding ?? absolute
    if let target = Info.info(forHeading: cleaned) {
      navigate(target)
      return .handled
    }
    // Unknown cross-reference: swallow the tap rather than let it fail loudly.
    return .handled
  }
}
