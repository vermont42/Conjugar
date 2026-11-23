//
//  ModelBrowseView.swift
//  Conjugar
//
//  The SwiftUI Models list, replacing the UIKit BrowseModelsVC/BrowseModelsUIV/
//  ModelCell. Every verb model with a tinted irregularity-percent badge, sortable
//  Irregularity / Alphabetical / Number (persisted via Settings.modelSort), with a
//  count banner and animated sort + selection haptic. Mirrors VerbBrowseView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct ModelBrowseView: View {
  static let englishTitle = "Models"

  @State private var sort: ModelSort = Current.settings.modelSort
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(AppRouter.self) private var router
  private let exploreModelsTip = ExploreModelsTip()

  private static let modelsBySort: [ModelSort: [ModelInfo]] = {
    let models = ModelInfo.all
    return Dictionary(uniqueKeysWithValues: ModelSort.allCases.map { ($0, $0.sorted(models)) })
  }()

  private var models: [ModelInfo] { Self.modelsBySort[sort] ?? [] }

  /// The current sort filtered by the search query, materialized into `@State` and
  /// recomputed only when `searchText` or `sort` changes. Seeded to the initial
  /// sort's full list so the first frame isn't a "0 models" flash.
  @State private var filteredModels: [ModelInfo] = Self.modelsBySort[Current.settings.modelSort] ?? []

  /// Refilter for the current `searchText` + `sort`, firing the no-results sad trombone
  /// here — the one-shot search transition — instead of inside `body`. Matches the exemplar
  /// **or** the class number after `VerbSearch.fold`, the Verbs tab's folding, which drops case
  /// and every diacritic, ñ included, so that a query behaves alike in both tabs (`28` or `4B`
  /// finds a model by its class number, `hacer` by its exemplar). Unlike the Verbs tab, this one
  /// does not rank.
  private func recomputeFilteredModels() {
    let results = BrowseSearch.results(in: models, query: searchText) { model, query in
      let foldedQuery = VerbSearch.fold(query)
      return VerbSearch.fold(model.exemplar).contains(foldedQuery)
        || VerbSearch.fold(model.classNumber).contains(foldedQuery)
    }
    if results.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
    }
    filteredModels = results
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            // The featured collections lead the tab and step aside while a search is typed.
            if searchText.isEmpty {
              collectionsSection
                .id("top")
            }

            Text(L.BrowseModels.modelCount(count: filteredModels.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, searchText.isEmpty ? Layout.doubleDefaultSpacing : Layout.defaultSpacing)
              .id(searchText.isEmpty ? "models" : "top")

            if searchText.isEmpty {
              TipView(exploreModelsTip)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
            }

            if !searchText.isEmpty && filteredModels.isEmpty {
              ContentUnavailableView(L.BrowseModels.searchNoResults, systemImage: "magnifyingglass")
                .padding(.top, Layout.tripleDefaultSpacing)
            } else if horizontalSizeClass == .regular {
              // iPad / regular width: reflow the rows into an adaptive grid of
              // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
              // `navigationDestination(for: CollectionRequest)` renders the pushed `ModelView`.
              LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                ForEach(filteredModels, id: \.classNumber) { model in
                  NavigationLink(value: CollectionRequest(collection: .model(model.classNumber), source: .tab)) {
                    ModelGridCell(model: model)
                      .card()
                  }
                  .buttonStyle(.plain)
                  // Screenshot-driver anchor (scripts/take_screenshots.sh taps
                  // `model_row_decir` / `model_row_haber`). Keyed by *exemplar*,
                  // not by `id`/`classNumber`: class numbers contain hyphens
                  // ("29-2"), and the driver's id predicate treats "-" as its
                  // prefix boundary, so `model_row_29` would match
                  // `model_row_29-2`. Both size-class branches carry it.
                  .accessibilityIdentifier("model_row_\(model.exemplar)")
                }
              }
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
            } else {
              LazyVStack(spacing: 0) {
                ForEach(Array(filteredModels.enumerated()), id: \.element.classNumber) { index, model in
                  // A real `NavigationLink` — button semantics + press
                  // highlight; the stack's `navigationDestination(for: CollectionRequest)`
                  // renders the pushed `ModelView`.
                  NavigationLink(value: CollectionRequest(collection: .model(model.classNumber), source: .tab)) {
                    ModelRowLabel(model: model)
                  }
                  .buttonStyle(.plain)
                  .accessibilityIdentifier("model_row_\(model.exemplar)")
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
        .readingWidth()
        .padding()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(text: $searchText, prompt: L.BrowseModels.searchPrompt)
      .sensoryFeedback(.selection, trigger: sort)
      .navigationTitle(L.BrowseModels.localizedTitle)
      .navigationDestination(for: VerbDestination.self) { destination in
        VerbView(verb: destination.infinitive, source: destination.source)
      }
      .navigationDestination(for: CollectionRequest.self) { request in
        collectionPage(request)
      }
      .verbPageDestinations()
      // A `list` link, which can arrive before the tab first appears.
      .onChange(of: router.pendingCollection, initial: true) { _, request in
        guard let request else { return }
        navigationPath.append(request)
        router.pendingCollection = nil
      }
      .onAppear {
        Current.analytics.signal(name: .viewModelBrowseView)
        Current.reviewPrompter.promptableActionHappened()
      }
    }
    // A model page, a verb page, and the pages they lead to push onto this stack.
    .environment(\.verbPagePush, VerbPagePush { navigationPath.append($0) })
  }
}

extension ModelBrowseView {
  /// The featured collections: rows on iPhone, cards on iPad.
  private var collectionsSection: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(L.VerbCollection.heading)
        .font(.caption.smallCaps())
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .accessibilityAddTraits(.isHeader)

      if horizontalSizeClass == .regular {
        LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
          ForEach(VerbCollection.featured) { collection in
            NavigationLink(value: CollectionRequest(collection: collection, source: .tab)) {
              VerbCollectionCard(collection: collection)
                .card()
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("collection_row_\(collection.key)")
          }
        }
        .padding(.horizontal)
      } else {
        LazyVStack(spacing: 0) {
          ForEach(VerbCollection.featured) { collection in
            NavigationLink(value: CollectionRequest(collection: collection, source: .tab)) {
              VerbCollectionRow(collection: collection)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("collection_row_\(collection.key)")
            Divider().padding(.leading)
          }
        }
      }
    }
    .padding(.top, Layout.defaultSpacing)
  }

  /// A featured collection opens its own page; a model's opens the model's page, whose bar makes
  /// it a collection.
  @ViewBuilder
  private func collectionPage(_ request: CollectionRequest) -> some View {
    if case .model(let classNumber) = request.collection, let model = ModelInfo.byClassNumber[classNumber] {
      ModelView(model: model, source: request.source)
    } else {
      VerbCollectionView(collection: request.collection, source: request.source)
    }
  }
}

/// The visual content of a model row — serif gold exemplar + class number with a
/// tinted irregularity-percent capsule badge.
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
    // Make the *entire* row a tap target — the same fix VerbRowLabel carries, and
    // for the same reason. Without it SwiftUI hit-tests only the drawn glyphs
    // (exemplar/class number on the left, percent pill on the right), so a tap
    // anywhere in the Spacer gap between them — most of the row — falls through and
    // the NavigationLink never fires. On iPhone that made model rows effectively
    // untappable except on their text; the iPad was unaffected because its grid
    // branch wraps each cell in `.card()`, whose fill hit-tests on its own.
    .contentShape(Rectangle())
  }
}

/// The carded grid variant of a model row for the iPad (regular-width) grid: the
/// same serif gold exemplar + class number + irregularity-percent pill as
/// `ModelRowLabel`, but laid out to fill a `.card()` cell (pill pulled up beside the
/// exemplar, no row padding — the card supplies it).
struct ModelGridCell: View {
  let model: ModelInfo

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        Text(model.exemplar)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)

        Spacer(minLength: Layout.defaultSpacing)

        Text(verbatim: "\(model.irregularityPercent)%")
          .metadataPill(tint: ModelPalette.tint(forPercent: model.irregularityPercent))
      }

      Text(model.classNumber)
        .font(.subheadline)
        .foregroundStyle(Color.customForeground)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

/// Shared tint for an irregularity percentage: green (regular) → yellow → red
/// (highly irregular), so the badge's color scales with the number.
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
    .environment(AppRouter())
}
