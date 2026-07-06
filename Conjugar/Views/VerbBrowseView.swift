//
//  VerbBrowseView.swift
//  Conjugar
//
//  The SwiftUI Browse Verbs list, replacing the UIKit BrowseVerbsVC/BrowseVerbsUIV/
//  VerbCell. All ~4,811 mapped verbs, sortable Frequency / Alphabetical (persisted
//  via Settings.verbSort), with a verb-count banner, animated sort + selection
//  haptic (audit §6), and two-line serif rows with a frequency-rank badge.
//  Ported/adapted from Konjugieren's VerbBrowseView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct VerbBrowseView: View {
  static let englishTitle = "Browse"

  @State private var sort: VerbSort = Current.settings.verbSort
  @State private var navigationPath = NavigationPath()

  /// Both sort orders, computed once (mirrors the UIKit VC's `verbsBySort`).
  private static let verbsBySort: [VerbSort: [VerbMapEntry]] = {
    let entries = VerbMap.shared.entries.values
    return Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
  }()

  private var verbs: [VerbMapEntry] { Self.verbsBySort[sort] ?? [] }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ScrollViewReader { proxy in
          ScrollView {
            Text(L.BrowseVerbs.verbCount(count: verbs.count))
              .font(.caption.smallCaps())
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal)
              .padding(.top, Layout.defaultSpacing)
              .id("top")

            LazyVStack(spacing: 0) {
              ForEach(Array(verbs.enumerated()), id: \.element.infinitive) { index, entry in
                VerbRow(entry: entry) { navigationPath.append(entry.infinitive) }
                  .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
                Divider().padding(.leading)
              }
            }
          }
          .onChange(of: sort) { _, newValue in
            Current.settings.verbSort = newValue
            proxy.scrollTo("top", anchor: .top)
          }
        }

        Divider()

        Picker(L.BrowseVerbs.sort, selection: $sort.animation(.snappy)) {
          ForEach(VerbSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .padding()
      }
      .background(Color.customBackground.ignoresSafeArea())
      .sensoryFeedback(.selection, trigger: sort)
      .navigationTitle(L.BrowseVerbs.localizedTitle)
      .navigationDestination(for: String.self) { verb in
        VerbView(verb: verb)
      }
      .onAppear {
        Current.analytics.recordVisitation(viewController: "\(VerbBrowseView.self)")
        Current.reviewPrompter.promptableActionHappened()
      }
    }
  }
}

private struct VerbRow: View {
  let entry: VerbMapEntry
  let navigate: () -> Void

  var body: some View {
    VerbRowLabel(entry: entry)
      .contentShape(Rectangle())
      .onTapGesture { navigate() }
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
        Text("#\(rank)")
          .font(.caption.monospacedDigit())
          .foregroundStyle(Color.customBlue)
          .accessibilityHidden(true)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
}

#Preview {
  VerbBrowseView()
}
