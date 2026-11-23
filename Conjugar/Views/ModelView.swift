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
  /// Where the page was opened, which `viewCollection` reports (Phase 16): `tab` from the Models
  /// tab's list, `verbPage` from a verb page's model pill, or a `list` link's source.
  let source: AnalyticsSource

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

  /// The grid's person columns, in canonical order, for a given second-singular
  /// preference. The second-singular column follows `Settings.secondSingularBrowse`
  /// exactly as `VerbView`'s rows do — tú, vos, or both — so a vos learner is not
  /// shown tú forms here after asking for vos everywhere else. `.both` yields a
  /// seven-column grid, which the card already scrolls horizontally.
  static func gridPersons(for secondSingular: SecondSingularBrowse) -> [DisplayPersonNumber] {
    var persons: [DisplayPersonNumber] = [.firstSingular]
    switch secondSingular {
    case .tu:
      persons.append(.secondSingularTú)
    case .vos:
      persons.append(.secondSingularVos)
    case .both:
      persons.append(contentsOf: [.secondSingularTú, .secondSingularVos])
    }
    persons.append(contentsOf: [.thirdSingular, .firstPlural, .secondPlural, .thirdPlural])
    return persons
  }

  /// Opens a tapped verb in whichever tab shows this page. See `VerbPagePush`.
  @Environment(\.verbPagePush) private var push
  /// The order of the verbs using this model. Not stored: the page always opens alphabetical.
  @State private var verbSort = VerbSort.alphabetical
  @State private var hasSignaledView = false
  /// The model as a collection (Phase 16), whose bar sits between the grid and the verbs.
  private let collection: VerbCollection
  /// The collection's verbs, for the bar's count. The same verbs as `entriesBySort`'s.
  private let collectionVerbs: [VerbMapEntry]

  private let gloss: String
  private let isDefective: Bool
  private let participio: String
  private let gerundio: String
  /// The verbs using this model, in each order, sorted once in `init`.
  private let entriesBySort: [VerbSort: [VerbMapEntry]]
  /// The person columns this instance renders, resolved from the browse setting in
  /// `init` — like `VerbView`'s row set, so both screens agree on tú/vos/both.
  private let gridPersons: [DisplayPersonNumber]
  /// The grid's conjugated forms, precomputed once in `init` — indexed
  /// `[tenseIndex][personIndex]` to parallel `gridTenses` / `gridPersons`, `nil` where a
  /// slot has no form. Previously `gridCell` re-conjugated every slot on each `body`.
  private let gridForms: [[String?]]

  init(model: ModelInfo, source: AnalyticsSource) {
    self.model = model
    self.source = source
    collection = .model(model.classNumber)
    gloss = VerbMap.shared.entry(for: model.exemplar)?.gloss ?? ""
    isDefective = Conjugator.isDefective(infinitive: model.exemplar)
    participio = Self.form(model.exemplar, .participio)
    gerundio = Self.form(model.exemplar, .gerundio)
    let entries = model.verbs.compactMap { VerbMap.shared.entry(for: $0) }
    entriesBySort = Dictionary(uniqueKeysWithValues: VerbSort.allCases.map { ($0, $0.sorted(entries)) })
    collectionVerbs = entries
    let persons = Self.gridPersons(for: Current.settings.secondSingularBrowse)
    gridPersons = persons
    gridForms = Self.gridTenses.map { gridTense in
      persons.map { person in
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
        VerbCollectionBar(collection: collection, title: L.VerbCollection.modelTitle(exemplar: model.exemplar), verbs: collectionVerbs)

        Picker(L.BrowseVerbs.sort, selection: $verbSort.animation(.snappy)) {
          ForEach(VerbSort.allCases, id: \.self) { order in
            Text(order.localizedDisplayName).tag(order)
          }
        }
        .pickerStyle(.segmented)
        .sensoryFeedback(.selection, trigger: verbSort)

        Text(L.Model.verbsUsing(count: model.verbs.count))
          .font(.caption.smallCaps())
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)

        VerbEntryList(entries: entriesBySort[verbSort] ?? [], showsLookedUp: true) { verb in
          push?(VerbDestination(infinitive: verb, source: .model))
        }
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
      Current.analytics.signal(name: .viewModelView)
      // A return from one of the model's verb pages is not another opening of the collection.
      if !hasSignaledView {
        hasSignaledView = true
        collection.signalView(source: source)
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
          ForEach(gridPersons, id: \.self) { person in
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
            ForEach(Array(gridPersons.enumerated()), id: \.element) { personIndex, _ in
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
