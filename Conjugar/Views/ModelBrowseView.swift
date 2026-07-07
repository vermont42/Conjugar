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
import TipKit

struct ModelBrowseView: View {
  static let englishTitle = "Models"

  @State private var sort: ModelSort = Current.settings.modelSort
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  private let exploreModelsTip = ExploreModelsTip()

  private static let modelsBySort: [ModelSort: [ModelInfo]] = {
    let models = ModelInfo.all
    return Dictionary(uniqueKeysWithValues: ModelSort.allCases.map { ($0, $0.sorted(models)) })
  }()

  private var models: [ModelInfo] { Self.modelsBySort[sort] ?? [] }

  /// The current sort filtered by the search query, materialized into `@State` and
  /// recomputed only when `searchText` or `sort` changes (item 3). Seeded to the initial
  /// sort's full list so the first frame isn't a "0 models" flash.
  @State private var filteredModels: [ModelInfo] = Self.modelsBySort[Current.settings.modelSort] ?? []

  /// Refilter for the current `searchText` + `sort`, firing the no-results sad trombone
  /// here — the one-shot search transition — instead of inside `body`. Matches the exemplar
  /// **or** the class number case- and diacritic-insensitively (so `28` or `4B` finds a
  /// model by its book number, `hacer` finds it by exemplar).
  private func recomputeFilteredModels() {
    let results = BrowseSearch.results(in: models, query: searchText) { model, query in
      model.exemplar.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        || model.classNumber.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
    if results.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      SoundPlayer.playRandomSadTrombone()
    }
    filteredModels = results
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            Text(L.BrowseModels.modelCount(count: filteredModels.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
              .id("top")

            if searchText.isEmpty {
              TipView(exploreModelsTip)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
            }

            if !searchText.isEmpty && filteredModels.isEmpty {
              ContentUnavailableView(L.BrowseModels.searchNoResults, systemImage: "magnifyingglass")
                .padding(.top, Layout.tripleDefaultSpacing)
            } else {
              LazyVStack(spacing: 0) {
                ForEach(Array(filteredModels.enumerated()), id: \.element.classNumber) { index, model in
                  ModelRowLabel(model: model)
                    .contentShape(Rectangle())
                    .onTapGesture { navigationPath.append(model) }
                    .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
                  Divider().padding(.leading)
                }
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.modelSort = newValue
            recomputeFilteredModels()
            proxy.scrollTo("top", anchor: .top)
          }
          .onChange(of: searchText) { _, _ in
            recomputeFilteredModels()
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
      .searchable(text: $searchText, prompt: L.BrowseModels.searchPrompt)
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

      Text(verbatim: "\(model.irregularityPercent)%")
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
