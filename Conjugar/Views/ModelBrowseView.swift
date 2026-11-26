//
//  ModelBrowseView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

/// The Models tab: the featured collections, then every verb model with a tinted
/// irregularity-percent badge, searchable and sortable by irregularity, alphabetically, or by
/// number (saved in `Settings.modelSort`).
struct ModelBrowseView: View {
  @State private var sort: ModelSort = Current.settings.modelSort
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(AppRouter.self) private var router
  private let exploreModelsTip = ExploreModelsTip()

  /// The search's text and order and the models they find, updated only when the text or the
  /// order changes. Seeded with the saved order's full list, so that the first frame is not a "0
  /// models" flash.
  @State private var search = ModelSearch(sort: Current.settings.modelSort)

  /// Refilters for the current text and order, and plays the sad trombone here, when the text
  /// changes to a failed query, rather than inside `body`.
  private func updateSearch() {
    if search.update(text: searchText, sort: sort) {
      Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
    }
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            // The featured collections lead the tab and step aside while a search is typed.
            if !search.isSearching {
              collectionsSection
                .id("top")
            }

            ListHeading(L.BrowseModels.modelCount(count: search.models.count))
              .padding(.horizontal)
              .padding(.top, search.isSearching ? Layout.defaultSpacing : Layout.doubleDefaultSpacing)
              .id(search.isSearching ? "top" : "models")

            if !search.isSearching {
              TipView(exploreModelsTip)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
            }

            if search.isSearching && search.models.isEmpty {
              ContentUnavailableView(L.BrowseModels.searchNoResults, systemImage: "magnifyingglass")
                .padding(.top, Layout.tripleDefaultSpacing)
            } else if horizontalSizeClass == .regular {
              // iPad / regular width: reflow the rows into an adaptive grid of
              // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
              // `navigationDestination(for: CollectionRequest)` renders the pushed `ModelView`.
              LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                ForEach(search.models, id: \.classNumber) { model in
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
                ForEach(Array(search.models.enumerated()), id: \.element.classNumber) { index, model in
                  // A real `NavigationLink` — button semantics + press
                  // highlight; the stack's `navigationDestination(for: CollectionRequest)`
                  // renders the pushed `ModelView`.
                  NavigationLink(value: CollectionRequest(collection: .model(model.classNumber), source: .tab)) {
                    ModelRowLabel(model: model)
                  }
                  .buttonStyle(.plain)
                  .accessibilityIdentifier("model_row_\(model.exemplar)")
                  .zebraStriped(index)
                  Divider().padding(.leading)
                }
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.modelSort = newValue
            updateSearch()
            proxy.scrollTo("top", anchor: .top)
          }
          .onChange(of: searchText) {
            updateSearch()
          }
        }

        Divider()

        SortPicker(selection: $sort)
          .readingWidth()
        .padding()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(text: $searchText, placement: BrowseLayout.searchPlacement, prompt: L.BrowseModels.searchPrompt)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .navigationTitle(L.BrowseModels.localizedTitle)
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
    .pushesVerbPages(onto: $navigationPath)
  }
}

extension ModelBrowseView {
  /// The featured collections: rows on iPhone, cards on iPad.
  private var collectionsSection: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      ListHeading(L.VerbCollection.heading)
        .padding(.horizontal)

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

/// The visual content of a model row: the serif gold exemplar and the class number, with a tinted
/// irregularity-percent capsule badge.
struct ModelRowLabel: View {
  let model: ModelInfo

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(model.exemplar)
          .serifTitle()
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
    // The whole row is the tap target. Without a content shape, SwiftUI hit-tests only the drawn
    // text and pill, and a tap in the gap between them, most of the row, opens nothing. The
    // iPad's cards need no shape, since `.card()`'s fill hit-tests on its own.
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
          .serifTitle()

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
