//
//  ModelBrowseView.swift
//  Conjugar
//
//  The SwiftUI Models list, replacing the UIKit BrowseModelsVC/BrowseModelsUIV/
//  ModelCell. Every verb model with a tinted irregularity-percent badge, sortable
//  Irregularity / Alphabetical / Number (persisted via Settings.modelSort), with a
//  count banner and animated sort + selection haptic (audit §11). Mirrors
//  VerbBrowseView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct ModelBrowseView: View {
  static let englishTitle = "Models"

  @State private var sort: ModelSort = Current.settings.modelSort
  @State private var navigationPath = NavigationPath()

  private static let modelsBySort: [ModelSort: [ModelInfo]] = {
    let models = ModelInfo.all
    return Dictionary(uniqueKeysWithValues: ModelSort.allCases.map { ($0, $0.sorted(models)) })
  }()

  private var models: [ModelInfo] { Self.modelsBySort[sort] ?? [] }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            Text(L.BrowseModels.modelCount(count: models.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
              .id("top")

            LazyVStack(spacing: 0) {
              ForEach(Array(models.enumerated()), id: \.element.classNumber) { index, model in
                ModelRowLabel(model: model)
                  .contentShape(Rectangle())
                  .onTapGesture { navigationPath.append(model) }
                  .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
                Divider().padding(.leading)
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.modelSort = newValue
            proxy.scrollTo("top", anchor: .top)
          }
        }

        Divider()

        Picker(L.BrowseVerbs.sort, selection: $sort.animation(.snappy)) {
          ForEach(ModelSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .padding()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .sensoryFeedback(.selection, trigger: sort)
      .navigationTitle(L.BrowseModels.localizedTitle)
      .navigationDestination(for: ModelInfo.self) { model in
        ModelView(model: model) { verb in navigationPath.append(verb) }
      }
      .navigationDestination(for: String.self) { verb in
        VerbView(verb: verb)
      }
      .onAppear {
        Current.analytics.recordVisitation(viewController: "\(ModelBrowseView.self)")
        Current.reviewPrompter.promptableActionHappened()
      }
    }
  }
}

/// The visual content of a model row — serif gold exemplar + class number with a
/// tinted irregularity-percent capsule badge (audit §11 / C15).
struct ModelRowLabel: View {
  let model: ModelInfo

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(model.exemplar)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        Text(model.classNumber)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
      }

      Spacer()

      Text("\(model.irregularityPercent)%")
        .metadataPill(tint: ModelPalette.tint(forPercent: model.irregularityPercent))
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
}

/// Shared tint for an irregularity percentage: green (regular) → yellow → red
/// (highly irregular), so the badge's color scales with the number (audit §10/§11).
enum ModelPalette {
  static func tint(forPercent percent: Int) -> Color {
    switch percent {
    case ..<1:
      return .customGreen
    case 1..<40:
      return .customYellow
    default:
      return .customRed
    }
  }
}

#Preview {
  ModelBrowseView()
}
