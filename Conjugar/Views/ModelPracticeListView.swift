//
//  ModelPracticeListView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// What the Quiz tab's hub pushes for its Verb Models row.
struct ModelPracticeDestination: Hashable {}

/// The verb models that can be practiced alone, the most used first, each opening onto its
/// practice. Each model's page offers the same practice below its collection bar.
struct ModelPracticeListView: View {
  @State private var expandedModels: Set<String> = []
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    let record = Current.practice.record

    ScrollView {
      LazyVStack(alignment: .leading, spacing: 0) {
        Text(L.ModelPractice.listIntro)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.bottom, Layout.defaultSpacing)

        ForEach(ModelPracticeGroup.practicedAloneByUse) { group in
          let isExpanded = expandedModels.contains(group.classNumber)

          VStack(alignment: .leading, spacing: 0) {
            ModelPracticeRowHeader(group: group, isKnown: group.isKnown(in: record), isExpanded: isExpanded)
              .contentShape(Rectangle())
              .accessibilityAddTraits(.isButton)
              .accessibilityIdentifier("model_practice_model_\(group.classNumber)")
              .onTapGesture {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                  if isExpanded {
                    expandedModels.remove(group.classNumber)
                  } else {
                    expandedModels.insert(group.classNumber)
                  }
                }
              }

            if isExpanded {
              ModelPracticeCard(classNumber: group.classNumber, showsKnown: false)
                .padding(.bottom, Layout.doubleDefaultSpacing)
            }

            Divider()
          }
        }
      }
      .padding()
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(L.ModelPractice.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

/// A model's row: its exemplar, a seal once it is known, and the exemplar's key conjugations with
/// their irregular letters in red, which show the pattern.
private struct ModelPracticeRowHeader: View {
  let group: ModelPracticeGroup
  let isKnown: Bool
  let isExpanded: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(spanish: group.exemplar)
          .font(.title3.bold())
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)

        if isKnown {
          Image(systemName: "checkmark.seal.fill")
            .font(.subheadline)
            .foregroundStyle(Color.customYellow)
            .accessibilityLabel(L.ModelPractice.known)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .accessibilityHidden(true)
      }

      ConjugationText(form: KeyConjugation.forms(of: group.exemplar).map(\.form).joined(separator: " · "))
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 12)
    .accessibilityElement(children: .combine)
  }
}
