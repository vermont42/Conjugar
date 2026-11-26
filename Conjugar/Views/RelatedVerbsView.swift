//
//  RelatedVerbsView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

/// The verb page's ways to other verbs, at the bottom of the page: a few verbs built on the same
/// base, and a few others of the same model.
struct RelatedVerbsView: View {
  let related: RelatedVerbs

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
          count: related.builtOnRoot.count,
          hasMore: related.builtOnRootHasMore
        )
      }

      if let model, !related.modelRelatives.isEmpty {
        relation(
          title: L.Verb.conjugatedLike(exemplar: model.exemplar),
          verbs: related.modelRelatives,
          all: model,
          count: related.modelVerbCount,
          hasMore: related.modelHasMore
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardWithAccentBar(.customYellow)
  }

  /// A relation's caption, its first few verbs, and, when it has more, a chip that opens all of
  /// them: the full list for a base, and the model's page for a model.
  private func relation(title: String, verbs: [String], all: some Hashable, count: Int, hasMore: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      FlowLayout(spacing: Layout.defaultSpacing) {
        ForEach(verbs.prefix(RelatedVerbs.shortListLength), id: \.self) { verb in
          RelatedChip(text: Self.citationForm(verb), isSpanish: true) { push in
            push(VerbDestination(infinitive: verb, source: .related))
          }
        }
        if hasMore {
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
      Text(spanish: text)
        .fontDesign(.serif)
    } else {
      Text(verbatim: text)
    }
  }
}
