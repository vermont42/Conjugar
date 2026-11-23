//
//  RelatedVerbsView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// Pushes a value onto whichever navigation stack shows the verb page, so that the page's links work
/// in the Verbs tab and the Models tab alike. The stack needs a destination for the value's type:
/// `VerbDestination`, `ModelInfo`, or `RelatedVerbListDestination`.
struct VerbPagePush {
  let push: (any Hashable) -> Void

  func callAsFunction(_ value: some Hashable) {
    push(value)
  }
}

extension EnvironmentValues {
  @Entry var verbPagePush: VerbPagePush?
}

extension View {
  /// The destinations that a verb page, and the pages it leads to, can push.
  func verbPageDestinations() -> some View {
    // Only a verb page's model pill pushes a bare `ModelInfo`; the Models tab's rows push a
    // `CollectionRequest`, which names its source.
    navigationDestination(for: ModelInfo.self) { model in
      ModelView(model: model, source: .verbPage)
    }
    .navigationDestination(for: RelatedVerbListDestination.self) { destination in
      RelatedVerbListView(destination: destination)
    }
  }
}

/// Every verb built on one root, which a verb page's short list leads to.
struct RelatedVerbListDestination: Hashable {
  let root: String
  let verbs: [String]
}

/// The verb page's ways to other verbs, at the bottom of the page: a few verbs built on the same
/// base, and a few others of the same model.
struct RelatedVerbsView: View {
  let related: RelatedVerbs

  static let shortListLength = 6

  private var model: ModelInfo? {
    ModelInfo.byClassNumber[related.modelClassNumber]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(L.Verb.relatedHeading)
        .font(.headline)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isHeader)

      if !related.builtOnRoot.isEmpty {
        relation(
          title: L.Verb.builtOn(root: Self.citationForm(related.root)),
          verbs: related.builtOnRoot,
          all: RelatedVerbListDestination(root: related.root, verbs: related.builtOnRoot),
          count: related.builtOnRoot.count
        )
      }

      if let model, !related.modelRelatives.isEmpty {
        relation(
          title: L.Verb.conjugatedLike(exemplar: model.exemplar),
          verbs: related.modelRelatives,
          all: model,
          count: related.modelVerbCount
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardWithAccentBar(.customYellow)
  }

  /// A relation's caption, its first few verbs, and, when it has more, a chip that opens all of
  /// them: the full list for a base, and the model's page for a model.
  private func relation(title: String, verbs: [String], all: some Hashable, count: Int) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      FlowLayout(spacing: Layout.defaultSpacing) {
        ForEach(verbs.prefix(Self.shortListLength), id: \.self) { verb in
          RelatedChip(text: Self.citationForm(verb), isSpanish: true) { push in
            push(VerbDestination(infinitive: verb, source: .related))
          }
        }
        if verbs.count > Self.shortListLength {
          RelatedChip(text: L.Verb.allRelated(count: count), systemImage: "list.bullet", isSpanish: false, isBordered: true) { push in
            push(all)
          }
        }
      }
    }
  }

  /// The infinitive as the page titles it: arrepentirse for a reflexive-only verb.
  static func citationForm(_ infinitive: String) -> String {
    VerbMap.shared.entry(for: infinitive)?.citationForm ?? infinitive
  }
}

/// One verb, or the way to all of them, as a capsule. A verb is read in a Spanish voice.
private struct RelatedChip: View {
  let text: String
  var systemImage: String?
  let isSpanish: Bool
  var isBordered = false
  let action: (VerbPagePush) -> Void
  @Environment(\.verbPagePush) private var push

  var body: some View {
    Button {
      if let push {
        action(push)
      }
    } label: {
      label
        .font(.subheadline)
        .foregroundStyle(Color.customYellow)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.customYellow.opacity(0.1), in: Capsule())
        .overlay {
          Capsule().strokeBorder(Color.customYellow.opacity(isBordered ? 0.45 : 0), lineWidth: 1.5)
        }
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var label: some View {
    if let systemImage {
      Label(text, systemImage: systemImage)
    } else if isSpanish {
      Text(Self.spanish(text))
        .fontDesign(.serif)
    } else {
      Text(verbatim: text)
    }
  }

  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
  }
}

/// Every verb built on one root, by frequency or alphabetically.
struct RelatedVerbListView: View {
  let destination: RelatedVerbListDestination
  @Environment(\.verbPagePush) private var push
  @State private var sort = VerbSort.frequency

  private var entries: [VerbMapEntry] {
    sort.sorted(destination.verbs.compactMap { VerbMap.shared.entry(for: $0) })
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
        Picker(L.BrowseVerbs.sort, selection: $sort.animation(.snappy)) {
          ForEach(VerbSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: sort)

        VerbEntryList(entries: entries) { verb in
          push?(VerbDestination(infinitive: verb, source: .related))
        }
      }
      .padding()
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(L.Verb.builtOn(root: RelatedVerbsView.citationForm(destination.root)))
    .navigationBarTitleDisplayMode(.inline)
  }
}
