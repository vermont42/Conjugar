//
//  ModelView.swift
//  Conjugar
//
//  The SwiftUI model-detail screen, replacing the UIKit ModelVC/ModelUIV/
//  ModelHeaderUIV. A carded header (gloss + tinted metadata pills + non-finite
//  forms), a horizontally-scrollable pronoun-by-tense conjugation grid whose
//  irregular spans render red (with a visible scroll indicator — audit §10), and
//  the "verbs using this model" list, each row linking to the native VerbView.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct ModelView: View {
  let model: ModelInfo
  /// Navigate to a verb (a tapped "verbs using this model" row). A closure rather
  /// than a `NavigationLink(value:)` because appending to the stack's path from the
  /// enclosing view reliably reaches its String destination from this pushed view.
  let onSelectVerb: (String) -> Void

  /// The grid's tense rows: the Spanish analogs of Conjuguer's five endings-grid
  /// tenses, plus futuro (Spanish concentrates irregularity in the future stem).
  static let gridTenses: [(label: String, tense: DisplayTense)] = [
    ("Ind. Presente", .presenteDeIndicativo),
    ("Imperativo", .imperativoPositivo),
    ("Pretérito", .pretérito),
    ("Futuro", .futuroDeIndicativo),
    ("Subj. Presente", .presenteDeSubjuntivo),
    ("Subj. Imperfecto", .imperfectoDeSubjuntivo1)
  ]

  /// The grid's person columns, in the book's row order.
  static let gridPersons: [DisplayPersonNumber] = [.firstSingular, .secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]

  private let gloss: String
  private let isDefective: Bool
  private let participio: String
  private let gerundio: String
  private let entries: [VerbMapEntry]

  init(model: ModelInfo, onSelectVerb: @escaping (String) -> Void) {
    self.model = model
    self.onSelectVerb = onSelectVerb
    gloss = VerbMap.shared.entry(for: model.exemplar)?.gloss ?? ""
    isDefective = Conjugator.isDefective(infinitive: model.exemplar)
    participio = Self.form(model.exemplar, .participio)
    gerundio = Self.form(model.exemplar, .gerundio)
    entries = model.verbs.compactMap { VerbMap.shared.entry(for: $0) }
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

        LazyVStack(spacing: 0) {
          ForEach(Array(entries.enumerated()), id: \.element.infinitive) { index, entry in
            VerbRowLabel(entry: entry)
              .contentShape(Rectangle())
              .onTapGesture { onSelectVerb(entry.infinitive) }
              .background(index.isMultiple(of: 2) ? Color.clear : Color.customYellow.opacity(0.03))
            Divider().padding(.leading)
          }
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(model.exemplar.capitalized)
    .navigationBarTitleDisplayMode(.large)
    .onAppear { Current.analytics.recordVisitation(viewController: "\(ModelView.self)") }
  }

  // MARK: - Header

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

  // MARK: - Conjugation grid

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
        ForEach(Self.gridTenses, id: \.label) { gridTense in
          GridRow {
            Text(gridTense.label)
              .font(.caption.weight(.semibold))
              .foregroundStyle(Color.customBlue)
              .gridColumnAlignment(.leading)
            ForEach(Self.gridPersons, id: \.self) { person in
              gridCell(tense: gridTense.tense, person: person)
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
  private func gridCell(tense: DisplayTense, person: DisplayPersonNumber) -> some View {
    if case .success(let form) = TenseBridge.conjugate(infinitive: model.exemplar, tense: tense, personNumber: person) {
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
