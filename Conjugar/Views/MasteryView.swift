//
//  MasteryView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// What the Quiz tab's Mastery row pushes.
struct MasteryDestination: Hashable {}

/// What the practice record has made secure at the learner's level: the regular patterns, a grid
/// of endings by persons for each tense, then the key conjugations of the 50 most frequent
/// irregular verbs. It only shows. A verb here links to nothing, since opening a verb page is a
/// lookup, which would send the verb's key conjugations back to the first box.
struct MasteryView: View {
  @Environment(\.horizontalSizeClass) private var sizeClass

  private var isLarge: Bool {
    sizeClass == .regular
  }

  var body: some View {
    let mastery = Mastery.current()

    ScrollView {
      LazyVStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
        Text(L.Mastery.intro(level: mastery.level.localizedName))
          .font(isLarge ? .body : .subheadline)
          .foregroundStyle(Color.secondary)
          .fixedSize(horizontal: false, vertical: true)

        legend

        sectionHeader(
          L.Mastery.patterns,
          count: L.Mastery.count(mastered: mastery.masteredPatternCount, total: mastery.patternCount),
          description: L.Mastery.patternsDescription
        )
        .padding(.top, Layout.defaultSpacing)

        ForEach(mastery.patterns) { table in
          MasteryPatternTableView(table: table, isLarge: isLarge)
        }

        sectionHeader(
          L.Mastery.verbs,
          count: L.Mastery.count(mastered: mastery.masteredVerbCount, total: mastery.verbCount),
          description: L.Mastery.verbsDescription
        )
        .padding(.top, Layout.doubleDefaultSpacing)

        ForEach(mastery.verbs) { row in
          MasteryVerbRowView(row: row, isLarge: isLarge)
          Divider()
        }
      }
      .padding(Layout.doubleDefaultSpacing)
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(L.Mastery.title)
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      Current.analytics.signal(name: .viewMastery)
    }
  }

  private var legend: some View {
    FlowLayout(spacing: Layout.doubleDefaultSpacing) {
      ForEach(MasteryState.allCases, id: \.self) { state in
        HStack(spacing: 4) {
          MasteryMark(state: state)
            .accessibilityHidden(true)
          Text(state.label)
            .font(isLarge ? .body : .subheadline)
            .foregroundStyle(Color.customForeground)
        }
        .accessibilityElement(children: .combine)
      }
    }
  }

  private func sectionHeader(_ title: String, count: String, description: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(title)
          .font(isLarge ? .title2.bold() : .title3.bold())
          .foregroundStyle(Color.customForeground)
        Spacer()
        Text(verbatim: count)
          .font((isLarge ? Font.body : .subheadline).monospacedDigit())
          .foregroundStyle(Color.secondary)
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)

      Text(description)
        .font(isLarge ? .body : .subheadline)
        .foregroundStyle(Color.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

/// A tense's patterns: a column per person, with its pronoun above a mark for each ending. The
/// columns are what VoiceOver walks, so it reads a pronoun, then that person's three endings, each
/// mark naming its ending. The gerundio, which has no person, is one line.
private struct MasteryPatternTableView: View {
  let table: Mastery.PatternTable
  let isLarge: Bool
  @ScaledMetric(relativeTo: .title3) private var rowHeight: CGFloat = 28
  @ScaledMetric(relativeTo: .caption) private var headerHeight: CGFloat = 18

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(MasteryText.spanish(table.tense.displayName))
        .font(isLarge ? .title3.weight(.semibold) : .headline)
        .linguistic()
        .foregroundStyle(Color.customForeground)
        .accessibilityAddTraits(.isHeader)

      if table.personNumbers == [.none] {
        singleLine
      } else {
        grid
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
    .accessibilityIdentifier("mastery_tense_\(PracticeItem.tenseKey(for: table.tense) ?? table.tense.displayName)")
  }

  private var grid: some View {
    HStack(alignment: .top, spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        Color.clear
          .frame(width: 1, height: headerHeight)
        ForEach(table.rows) { row in
          Text(verbatim: MasteryText.ending(row.ending))
            .font((isLarge ? Font.body : .subheadline).monospaced())
            .foregroundStyle(Color.secondary)
            .frame(height: rowHeight)
        }
      }
      .padding(.trailing, Layout.defaultSpacing)
      .accessibilityHidden(true)

      ForEach(Array(table.personNumbers.enumerated()), id: \.offset) { index, personNumber in
        VStack(spacing: 0) {
          Text(MasteryText.spanish(MasteryText.pronoun(personNumber, in: table.tense)))
            .font(isLarge ? .subheadline : .caption)
            .foregroundStyle(Color.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(height: headerHeight)
          ForEach(table.rows) { row in
            MasteryMark(state: row.states[index])
              .font(isLarge ? .title2 : .title3)
              .frame(height: rowHeight)
              .accessibilityLabel(L.Mastery.patternMark(ending: MasteryText.ending(row.ending), state: row.states[index].label))
          }
        }
        .frame(maxWidth: .infinity)
        // Without a container, VoiceOver reads the grid by rows: every pronoun, then every -ar mark.
        .accessibilityElement(children: .contain)
      }
    }
  }

  private var singleLine: some View {
    HStack(spacing: Layout.tripleDefaultSpacing) {
      ForEach(table.rows) { row in
        HStack(spacing: 6) {
          Text(verbatim: MasteryText.ending(row.ending))
            .font((isLarge ? Font.body : .subheadline).monospaced())
            .foregroundStyle(Color.secondary)
            .accessibilityHidden(true)
          if let state = row.states.first {
            MasteryMark(state: state)
              .font(isLarge ? .title2 : .title3)
              .accessibilityLabel(L.Mastery.patternMark(ending: MasteryText.ending(row.ending), state: state.label))
          }
        }
      }
    }
  }
}

/// An irregular verb: its infinitive, its gloss, and a mark beside each key conjugation the level
/// asks, the irregular letters red as on the verb page.
private struct MasteryVerbRowView: View {
  let row: Mastery.VerbRow
  let isLarge: Bool

  var body: some View {
    let forms = KeyConjugation.forms(of: row.infinitive)
    let entry = VerbMap.shared.entry(for: row.infinitive)

    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline, spacing: Layout.defaultSpacing) {
        Text(MasteryText.spanish(entry?.citationForm ?? row.infinitive))
          .font(isLarge ? .title3 : .headline)
          .linguistic()
          .foregroundStyle(Color.customYellow)
        if let gloss = entry?.gloss, !gloss.isEmpty {
          Text(gloss)
            .font(isLarge ? .body : .subheadline)
            .foregroundStyle(Color.secondary)
        }
      }

      FlowLayout(spacing: Layout.doubleDefaultSpacing) {
        ForEach(row.keyConjugations) { mark in
          HStack(spacing: 4) {
            MasteryMark(state: mark.state)
            if let form = forms.first(where: { $0.key == mark.key.keyConjugation })?.form {
              Text(ConjugationText.attributedString(for: form))
                .linguistic()
            }
          }
          .font(isLarge ? .title3 : .body)
        }
      }
    }
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityIdentifier("mastery_verb_\(row.infinitive)")
  }
}

/// ● mastered, ◐ learning, ○ not yet practiced. Each state has its own shape, not only its own
/// color, and VoiceOver reads its name.
private struct MasteryMark: View {
  let state: MasteryState

  var body: some View {
    Image(systemName: state.systemImage)
      .foregroundStyle(state == .notPracticed ? Color.secondary : Color.customYellow)
      .accessibilityLabel(state.label)
  }
}

private enum MasteryText {
  /// Text that VoiceOver reads with a Spanish voice.
  static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }

  static func ending(_ ending: RegularRoot) -> String {
    "-\(ending.practiceKey)"
  }

  /// A command's column names whom it addresses (usted, not él), as the quiz's frame does.
  static func pronoun(_ personNumber: DisplayPersonNumber, in tense: DisplayTense) -> String {
    if tense == .imperativoPositivo || tense == .imperativoNegativo {
      return personNumber.commandAddressee ?? personNumber.pronoun
    }
    return personNumber.pronoun
  }
}

extension MasteryState {
  var label: String {
    switch self {
    case .mastered:
      return L.Mastery.mastered
    case .learning:
      return L.Mastery.learning
    case .notPracticed:
      return L.Mastery.notPracticed
    }
  }

  var systemImage: String {
    switch self {
    case .mastered:
      return "circle.fill"
    case .learning:
      return "circle.lefthalf.filled"
    case .notPracticed:
      return "circle"
    }
  }
}
