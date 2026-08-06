//
//  VerbBrowseView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct VerbBrowseView: View {
  static let englishTitle = "Verbs"

  @State private var sort: VerbSort = Current.settings.verbSort
  @State private var navigationPath = NavigationPath()
  @State private var searchText = ""
  @Environment(AppRouter.self) private var router
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  private let tryQuizTip = TryQuizTip()

  /// Both sort orders, computed once (mirrors the UIKit VC's `verbsBySort`).
  private static let verbsBySort: [VerbSort: [VerbMapEntry]] = {
    let entries = VerbMap.shared.entries.values
    return Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
  }()

  private var verbs: [VerbMapEntry] { Self.verbsBySort[sort] ?? [] }

  /// The current sort filtered by the search query, materialized into `@State` and
  /// recomputed only when `searchText` or `sort` changes — rather than as a
  /// computed property `body` scanned twice per render. Seeded to the initial sort's
  /// full list so the first frame isn't a "0 verbs" flash.
  @State private var filteredVerbs: [VerbMapEntry] = Self.verbsBySort[Current.settings.verbSort] ?? []

  /// Refilter for the current `searchText` + `sort`, firing the no-results sad trombone
  /// here — the one-shot search transition — instead of inside `body`. Matches infinitive
  /// **or** gloss case- and diacritic-insensitively (so `esta` finds `está`, `have` finds
  /// haber/tener).
  private func recomputeFilteredVerbs() {
    let results = BrowseSearch.results(in: verbs, query: searchText) { entry, query in
      entry.infinitive.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        || entry.gloss.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
    if results.isEmpty && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      Current.soundPlayer.play(Sound.randomSadTrombone, shouldDebounce: true)
    }
    filteredVerbs = results
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            Text(L.BrowseVerbs.verbCount(count: filteredVerbs.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
              .id("top")
              // Stable launch-screen leaf anchor for the ios-build-verify skill's
              // wait-for-render poll (FIRST_SCREEN_ID); a leaf, not a container, to
              // avoid SwiftUI AXTree identifier rollover onto descendants.
              .accessibilityIdentifier("browse_verb_count")

            if searchText.isEmpty {
              TipView(tryQuizTip)
                .padding(.horizontal)
                .padding(.top, Layout.defaultSpacing)
            }

            if !searchText.isEmpty && filteredVerbs.isEmpty {
              ContentUnavailableView(L.BrowseVerbs.searchNoResults, systemImage: "magnifyingglass")
                .padding(.top, Layout.tripleDefaultSpacing)
            } else if horizontalSizeClass == .regular {
              // iPad / regular width: reflow the rows into an adaptive grid of
              // carded cells (≈2 columns portrait, ≈3–4 landscape). The same
              // `navigationDestination(for: String)` renders the pushed `VerbView`.
              LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
                ForEach(filteredVerbs, id: \.infinitive) { entry in
                  NavigationLink(value: entry.infinitive) {
                    VerbGridCell(entry: entry)
                      .card()
                  }
                  .buttonStyle(.plain)
                  // Screenshot-driver anchor (scripts/take_screenshots.sh taps
                  // `verb_row_ser`). Both size-class branches carry it — the iPad
                  // renders this grid, the iPhone the stack below.
                  .accessibilityIdentifier("verb_row_\(entry.infinitive)")
                }
              }
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
            } else {
              LazyVStack(spacing: 0) {
                ForEach(Array(filteredVerbs.enumerated()), id: \.element.infinitive) { index, entry in
                  // A real `NavigationLink`: `.isButton` trait, press
                  // highlight, and stronger VoiceOver semantics than the old
                  // `.onTapGesture`. The stack's `navigationDestination(for: String)`
                  // already renders the pushed `VerbView`.
                  NavigationLink(value: entry.infinitive) {
                    VerbRowLabel(entry: entry)
                  }
                  .buttonStyle(.plain)
                  .accessibilityIdentifier("verb_row_\(entry.infinitive)")
                  .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
                  Divider().padding(.leading)
                }
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.verbSort = newValue
            recomputeFilteredVerbs()
            proxy.scrollTo("top", anchor: .top)
          }
          .onChange(of: searchText) { _, _ in
            recomputeFilteredVerbs()
          }
        }

        Divider()

        Picker(L.BrowseVerbs.sort, selection: $sort.animation(.snappy)) {
          ForEach(VerbSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .readingWidth()
        .padding()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .searchable(text: $searchText, prompt: L.BrowseVerbs.searchPrompt)
      .sensoryFeedback(.selection, trigger: sort)
      .navigationTitle(L.BrowseVerbs.localizedTitle)
      .navigationDestination(for: String.self) { verb in
        VerbView(verb: verb)
      }
      .onChange(of: router.pendingVerb, initial: true) { _, verb in
        guard let verb else { return }
        navigationPath.append(verb)
        router.pendingVerb = nil
      }
      .onAppear {
        Current.analytics.signal(name: .viewVerbBrowseView)
        Current.reviewPrompter.promptableActionHappened()
      }
    }
  }
}

/// The visual content of a verb row — serif gold infinitive + gloss with a blue
/// frequency-rank badge. Shared by Browse Verbs and the Model detail's
/// "verbs using this model" list.
struct VerbRowLabel: View {
  let entry: VerbMapEntry

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.infinitive)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)
        if !entry.gloss.isEmpty {
          Text(entry.gloss)
            .font(.subheadline)
            .foregroundStyle(Color.customForeground)
        }
      }

      Spacer()

      if let rank = entry.frequencyRank {
        Text(verbatim: "#\(rank)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.customBlue)
          .accessibilityHidden(true)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
    // Make the *entire* row a tap target. Without this, SwiftUI hit-tests only the
    // drawn glyphs (infinitive/gloss/rank), so taps on the transparent Spacer gap and
    // padding fall through — the row felt only partly tappable (and defeated
    // ios-build-verify's tap-to-drill-down on a verb). A content shape over the padded
    // frame claims the whole cell.
    .contentShape(Rectangle())
  }
}

/// The carded grid variant of a verb row for the iPad (regular-width) grid: the
/// same serif gold infinitive + gloss + rank as `VerbRowLabel`, but laid out to
/// fill a `.card()` cell (rank pulled up beside the infinitive, no row padding —
/// the card supplies it).
struct VerbGridCell: View {
  let entry: VerbMapEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline) {
        Text(entry.infinitive)
          .font(.title3)
          .fontDesign(.serif)
          .foregroundStyle(Color.customYellow)

        Spacer(minLength: Layout.defaultSpacing)

        if let rank = entry.frequencyRank {
          Text(verbatim: "#\(rank)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(Color.customBlue)
            .accessibilityHidden(true)
        }
      }

      if !entry.gloss.isEmpty {
        Text(entry.gloss)
          .font(.subheadline)
          .foregroundStyle(Color.customForeground)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}

#Preview {
  VerbBrowseView()
    .environment(AppRouter())
}
