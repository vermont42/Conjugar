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
            } else {
              AdaptiveRows(
                search.models,
                id: \.classNumber,
                gridPadding: BrowseLayout.gridPadding(),
                // Screenshot-driver anchor (scripts/take_screenshots.sh taps `model_row_decir` and
                // `model_row_haber`). Keyed by exemplar, not by class number: class numbers contain
                // hyphens ("29-2"), and the driver's id predicate treats "-" as its prefix boundary,
                // so `model_row_29` would match `model_row_29-2`.
                accessibilityIdentifier: ("model_row_", \.exemplar)
              ) { model in
                navigationPath.append(CollectionRequest(collection: .model(model.classNumber), source: .tab))
              } label: { model in
                ModelRowLabel(model: model)
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

      AdaptiveRows(
        VerbCollection.featured,
        id: \.id,
        isStriped: false,
        gridPadding: BrowseLayout.gridPadding(top: 0),
        accessibilityIdentifier: ("collection_row_", \.key)
      ) { collection in
        navigationPath.append(CollectionRequest(collection: collection, source: .tab))
      } label: { collection in
        VerbCollectionRowLabel(collection: collection)
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

#Preview {
  ModelBrowseView()
    .environment(AppRouter())
}
