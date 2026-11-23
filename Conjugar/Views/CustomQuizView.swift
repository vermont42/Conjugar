//
//  CustomQuizView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The pages a custom quiz's choice pushes onto the Quiz tab.
enum CustomQuizDestination: Hashable {
  case editor
  case models
}

/// Where the learner chooses a custom quiz's tenses and verbs. Each tap is kept at once, so the
/// choice survives leaving the page and relaunching.
struct CustomQuizEditor: View {
  private var custom: CustomQuiz {
    Current.settings.customQuiz
  }

  private var level: QuizLevel {
    Current.settings.quizLevel
  }

  private var myVerbs: [VerbMapEntry] {
    Current.learnerVerbs.myVerbs
  }

  var body: some View {
    List {
      Section {
        CustomQuizChoiceRow(title: L.CustomQuiz.byLevel, detail: level.localizedName, isSelected: custom.tenses.isEmpty) {
          Current.settings.customQuiz.tenses = []
        }
        .accessibilityIdentifier("custom_quiz_tenses_by_level")

        ForEach(CustomQuiz.choosableTenses, id: \.self) { tense in
          CustomQuizChoiceRow(
            title: tense.titleCaseName,
            titleIsSpanish: true,
            detail: Self.firstLevel(asking: tense).map { L.CustomQuiz.fromLevel($0.localizedName) },
            isSelected: custom.tenses.contains(tense)
          ) {
            Current.settings.customQuiz.tenses.formSymmetricDifference([tense])
          }
          .accessibilityIdentifier("custom_quiz_tense_\(CustomQuiz.key(for: tense))")
        }
      } header: {
        Text(L.CustomQuiz.tenses)
      } footer: {
        Text(L.CustomQuiz.tensesFooter)
      }
      .listRowBackground(Color.customCardBackground)

      Section {
        CustomQuizChoiceRow(title: L.CustomQuiz.byLevel, detail: CustomQuiz.levelVerbsDescription(level), isSelected: custom.verbSet == nil) {
          Current.settings.customQuiz.verbSet = nil
        }
        .accessibilityIdentifier("custom_quiz_verbs_by_level")

        ForEach(Self.verbSets(showsMyVerbs: !myVerbs.isEmpty || custom.verbSet == .myVerbs), id: \.self) { verbSet in
          CustomQuizChoiceRow(
            title: verbSet.title,
            detail: verbSet.detail(myVerbCount: myVerbs.count),
            isSelected: custom.verbSet == verbSet
          ) {
            Current.settings.customQuiz.verbSet = verbSet
          }
          .accessibilityIdentifier("custom_quiz_verbs_\(verbSet.key)")
        }

        NavigationLink(value: CustomQuizDestination.models) {
          HStack {
            Text(L.CustomQuiz.models)
              .foregroundStyle(Color.customForeground)
            Spacer()
            if case .collection(.model(let classNumber)) = custom.verbSet, let model = ModelInfo.byClassNumber[classNumber] {
              Text(Self.spanish(model.exemplar))
                .fontDesign(.serif)
                .foregroundStyle(Color.customYellow)
            }
          }
        }
        .accessibilityAddTraits(custom.verbSet?.isModel == true ? .isSelected : [])
        .accessibilityIdentifier("custom_quiz_verbs_models")
      } header: {
        Text(L.CustomQuiz.verbs)
      }
      .listRowBackground(Color.customCardBackground)
    }
    .scrollContentBackground(.hidden)
    .background(Color.customBackground)
    .navigationTitle(L.CustomQuiz.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  /// The narrowest band first, then every verb, then the lists.
  private static func verbSets(showsMyVerbs: Bool) -> [QuizVerbSet] {
    FrequencyBand.allCases.map(QuizVerbSet.band) + [.all] + (showsMyVerbs ? [.myVerbs] : [])
      + QuizVerbSet.patternCollections.map(QuizVerbSet.collection)
  }

  /// The level that adds the tense to the quiz.
  static func firstLevel(asking tense: DisplayTense) -> QuizLevel? {
    QuizLevel.allCases.first { $0.entry(for: tense) != nil }
  }

  static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}

/// The Models tab's models, in the Models tab's sort, one of which a custom quiz may ask about.
/// Choosing one returns to the choice.
struct CustomQuizModelList: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      ForEach(Current.settings.modelSort.sorted(ModelInfo.all)) { model in
        let verbSet = QuizVerbSet.collection(.model(model.classNumber))
        CustomQuizChoiceRow(
          title: model.exemplar,
          titleIsSpanish: true,
          detail: "\(L.Model.modelLabel(number: model.classNumber)) · \(L.BrowseVerbs.verbCount(count: model.verbs.count))",
          isSelected: Current.settings.customQuiz.verbSet == verbSet
        ) {
          Current.settings.customQuiz.verbSet = verbSet
          dismiss()
        }
        .accessibilityIdentifier("custom_quiz_model_\(model.classNumber)")
      }
      .listRowBackground(Color.customCardBackground)
    }
    .scrollContentBackground(.hidden)
    .background(Color.customBackground)
    .navigationTitle(L.CustomQuiz.models)
    .navigationBarTitleDisplayMode(.inline)
  }
}

private struct CustomQuizChoiceRow: View {
  let title: String
  var titleIsSpanish = false
  var detail: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(titleIsSpanish ? CustomQuizEditor.spanish(title) : AttributedString(title))
            .fontDesign(titleIsSpanish ? .serif : .default)
            .foregroundStyle(Color.customForeground)
          if let detail {
            // Color.secondary, since a button's .secondary derives from its tint, the app's red.
            Text(verbatim: detail)
              .font(.caption)
              .foregroundStyle(Color.secondary)
          }
        }
        Spacer()
        Image(systemName: "checkmark")
          .fontWeight(.semibold)
          .foregroundStyle(Color.customYellow)
          .opacity(isSelected ? 1 : 0)
          .accessibilityHidden(true)
      }
      .contentShape(Rectangle())
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

/// What a custom quiz asks: its tenses and its verbs, each the level's when left unchosen.
struct CustomQuizSummaryCard: View {
  let custom: CustomQuiz
  let level: QuizLevel
  var isLarge = false

  var body: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      row(
        L.CustomQuiz.tenses,
        value: custom.tenses.isEmpty
          ? AttributedString("\(L.CustomQuiz.byLevel): \(level.localizedName)")
          : CustomQuizEditor.spanish(custom.orderedTenses.map(\.titleCaseName).joined(separator: ", ")),
        isSpanish: !custom.tenses.isEmpty
      )
      row(
        L.CustomQuiz.verbs,
        value: AttributedString(custom.verbSet?.title ?? "\(L.CustomQuiz.byLevel): \(CustomQuiz.levelVerbsDescription(level))"),
        isSpanish: false
      )
    }
    .font(isLarge ? .title3 : .body)
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
    .accessibilityElement(children: .combine)
  }

  private func row(_ label: String, value: AttributedString, isSpanish: Bool) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.caption.bold())
        .foregroundStyle(Color.customYellow)
        .textCase(.uppercase)
      Text(value)
        .fontDesign(isSpanish ? .serif : .default)
        .foregroundStyle(Color.customForeground)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

extension QuizVerbSet {
  var title: String {
    switch self {
    case .all:
      return L.Quiz.allVerbs
    case .band(let band):
      return L.CustomQuiz.band(count: band.verbCount)
    case .collection(let collection):
      return collection.title
    case .myVerbs:
      return L.MyVerbs.title
    }
  }

  /// A row's second line: how many verbs the set holds, where its title does not say.
  func detail(myVerbCount: Int) -> String? {
    switch self {
    case .all:
      return L.BrowseVerbs.verbCount(count: VerbMap.shared.entries.count)
    case .myVerbs:
      return L.BrowseVerbs.verbCount(count: myVerbCount)
    case .collection(let collection):
      return L.BrowseVerbs.verbCount(count: collection.verbs.count)
    case .band:
      return nil
    }
  }

  var isModel: Bool {
    if case .collection(let collection) = self {
      return collection.isModel
    }
    return false
  }
}

extension CustomQuiz {
  /// "Beginner · 100 Most Frequent Verbs": the verbs a level's default quiz asks.
  static func levelVerbsDescription(_ level: QuizLevel) -> String {
    let verbs = level.band.map { L.CustomQuiz.band(count: $0.verbCount) } ?? L.Quiz.allVerbs
    return "\(level.localizedName) · \(verbs)"
  }
}
