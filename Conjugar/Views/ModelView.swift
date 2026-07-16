//
//  ModelView.swift
//  Conjugar
//
//  The SwiftUI model-detail screen, replacing the UIKit ModelVC/ModelUIV/
//  ModelHeaderUIV. A carded header (gloss + tinted metadata pills + non-finite
//  forms), a horizontally-scrollable pronoun-by-tense conjugation grid whose
//  irregular spans render red (with a visible scroll indicator), and
//  the "verbs using this model" list, each row linking to the native VerbView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct ModelView: View {
  let model: ModelInfo
  /// Navigate to a verb (a tapped "verbs using this model" row). A closure rather
  /// than a `NavigationLink(value:)` because appending to the stack's path from the
  /// enclosing view reliably reaches its String destination from this pushed view.
  let onSelectVerb: (String) -> Void

  /// The grid's tense rows: five core tenses, plus futuro (Spanish concentrates
  /// irregularity in the future stem).
  static let gridTenses: [(label: String, tense: DisplayTense)] = [
    ("Ind. Presente", .presenteDeIndicativo),
    ("Imperativo", .imperativoPositivo),
    ("Pretérito", .pretérito),
    ("Futuro", .futuroDeIndicativo),
    ("Subj. Presente", .presenteDeSubjuntivo),
    ("Subj. Imperfecto", .imperfectoDeSubjuntivo1)
  ]

  /// The grid's person columns, in canonical order.
  static let gridPersons: [DisplayPersonNumber] = [.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  private let gloss: String
  private let isDefective: Bool
  private let participio: String
  private let gerundio: String
  private let entries: [VerbMapEntry]
  /// The 6×6 grid's conjugated forms, precomputed once in `init` — indexed
  /// `[tenseIndex][personIndex]` to parallel `gridTenses` / `gridPersons`, `nil` where a
  /// slot has no form. Previously `gridCell` re-conjugated all 36 slots on every `body`.
  private let gridForms: [[String?]]

  init(model: ModelInfo, onSelectVerb: @escaping (String) -> Void) {
    self.model = model
    self.onSelectVerb = onSelectVerb
    gloss = VerbMap.shared.entry(for: model.exemplar)?.gloss ?? ""
    isDefective = Conjugator.isDefective(infinitive: model.exemplar)
    participio = Self.form(model.exemplar, .participio)
    gerundio = Self.form(model.exemplar, .gerundio)
    entries = model.verbs.compactMap { VerbMap.shared.entry(for: $0) }
    gridForms = Self.gridTenses.map { gridTense in
      Self.gridPersons.map { person in
        if case .success(let form) = TenseBridge.conjugate(infinitive: model.exemplar, tense: gridTense.tense, personNumber: person) {
          return form
        }
        return nil
      }
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
        headerCard
        gridCard

        Text(L.Model.verbsUsing(count: model.verbs.count))
          .font(.caption.smallCaps())
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)

        verbsUsingList
      }
      .padding()
      // Cap the whole column to reading width and center it so the header, the
      // (already horizontally-scrollable) grid card, and the verbs list sit in one
      // tidy column instead of stretching across a 13" iPad. No-op on iPhone.
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(model.exemplar.capitalized)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      ExploreModelsTip().invalidate(reason: .actionPerformed)
      Current.analytics.recordVisitation(viewController: "\(ModelView.self)")
    }
  }

  /// The "verbs using this model" list. On regular width (iPad) it reflows into an
  /// adaptive grid of carded cells mirroring Browse Verbs; on compact width it stays
  /// the bare zebra-striped, divider-separated single column. Both paths keep the
  /// closure-based navigation (rather than `NavigationLink(value:)`) because appending
  /// to the enclosing stack's path from this pushed view reliably reaches the String
  /// destination.
  @ViewBuilder
  private var verbsUsingList: some View {
    if horizontalSizeClass == .regular {
      LazyVGrid(columns: BrowseLayout.listColumns, spacing: Layout.doubleDefaultSpacing) {
        ForEach(entries, id: \.infinitive) { entry in
          Button {
            onSelectVerb(entry.infinitive)
          } label: {
            VerbGridCell(entry: entry)
              .card()
          }
          .buttonStyle(.plain)
        }
      }
    } else {
      LazyVStack(spacing: 0) {
        ForEach(Array(entries.enumerated()), id: \.element.infinitive) { index, entry in
          // A `Button` wrapper gives these rows `.isButton` semantics and a press
          // highlight.
          Button {
            onSelectVerb(entry.infinitive)
          } label: {
            VerbRowLabel(entry: entry)
          }
          .buttonStyle(.plain)
          .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
          Divider().padding(.leading)
        }
      }
    }
  }

  private var headerCard: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      if !gloss.isEmpty {
        Text(gloss)
          .font(.title3)
          .foregroundStyle(Color.customForeground)
      }

      HStack(spacing: Layout.defaultSpacing) {
        Text(L.Model.modelLabel(number: model.classNumber))
          .metadataPill(tint: .customBlue)
        Text(verbatim: "\(model.irregularityPercent)%")
          .metadataPill(tint: ModelPalette.tint(forPercent: model.irregularityPercent))
        if isDefective {
          Text(L.Verb.defective).metadataPill(tint: .customRed)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        nonFiniteRow(DisplayTense.participio.titleCaseName, form: participio)
        nonFiniteRow(DisplayTense.gerundio.titleCaseName, form: gerundio)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private func nonFiniteRow(_ label: String, form: String) -> some View {
    HStack(spacing: Layout.defaultSpacing) {
      Text(label)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      ConjugationText(form: form)
        .font(.body)
        .speakOnTapFlash(ConjugationText.plain(form))
    }
  }

  private var gridCard: some View {
    ScrollView(.horizontal) {
      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Layout.doubleDefaultSpacing, verticalSpacing: 6) {
        GridRow {
          Text(verbatim: "")
          ForEach(Self.gridPersons, id: \.self) { person in
            Text(person.pronoun)
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color.customBlue)
          }
        }
        ForEach(Array(Self.gridTenses.enumerated()), id: \.element.label) { tenseIndex, gridTense in
          GridRow {
            Text(gridTense.label)
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color.customBlue)
              .gridColumnAlignment(.leading)
            ForEach(Array(Self.gridPersons.enumerated()), id: \.element) { personIndex, _ in
              gridCell(form: gridForms[tenseIndex][personIndex])
            }
          }
        }
      }
      .padding(.vertical, 4)
    }
    .scrollIndicators(.visible)
    .card()
  }

  @ViewBuilder
  private func gridCell(form: String?) -> some View {
    if let form {
      ConjugationText(form: form)
        .font(.subheadline)
        .speakOnTapFlash(ConjugationText.plain(form))
    } else {
      // A slot with no form (yo has no imperative; a defective verb's gaps).
      Text(verbatim: "—")
        .font(.subheadline)
        .foregroundStyle(.tertiary)
    }
  }

  private static func form(_ verb: String, _ tense: DisplayTense) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: .none) {
      return value
    }
    return ""
  }
}
