//
//  VerbView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI

struct VerbView: View {
  let verb: String

  private let gloss: String
  private let typeOrParent: String
  private let participio: String
  private let gerundio: String
  private let raizFutura: String
  private let isDefective: Bool
  private let sections: [ConjugationSection]
  private let etymology: String?
  private let example: Example?
  private let medievalExamples: [MedievalExample]
  @State private var medievalIndex: Int
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(verb: String) {
    self.verb = verb
    let entry = VerbMap.shared.entry(for: verb)
    gloss = entry?.gloss ?? ""
    participio = Self.form(verb, .participio)
    gerundio = Self.form(verb, .gerundio)
    raizFutura = Self.form(verb, .raízFutura) + "-"
    isDefective = Conjugator.isDefective(infinitive: verb)
    typeOrParent = Self.typeOrParent(verb: verb, entry: entry)
    sections = Self.buildSections(verb: verb)
    etymology = Etymology.text(for: verb)
    example = ExampleData.example(for: verb)
    let medieval = MedievalData.examples(for: verb)
    medievalExamples = medieval
    // Start on a random attestation so each visit varies; the cycle button advances from here.
    _medievalIndex = State(initialValue: medieval.indices.randomElement() ?? 0)
  }

  private var medievalExample: MedievalExample? {
    medievalExamples.indices.contains(medievalIndex) ? medievalExamples[medievalIndex] : nil
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
        metadataHeader
        if horizontalSizeClass == .regular {
          // iPad / regular width: two columns of conjugation cards side by side,
          // halving the vertical scroll. `conjugationCards` is the single content
          // builder shared with the compact path, so the two layouts can't drift.
          LazyVGrid(columns: BrowseLayout.detailColumns, alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
            conjugationCards
          }
        } else {
          conjugationCards
        }
        if let etymology {
          etymologyCard(etymology)
        }
        if example != nil || medievalExample != nil {
          exampleCard
        }
      }
      .padding()
      // Cap the whole column to reading width and center it: the conjugation cards
      // are short, pronoun-keyed rows that read badly stretched across a 13" iPad,
      // and capping keeps the header/pills, the 2-up card grid, and the prose cards
      // sharing one tidy column. A no-op on iPhone (narrower than the cap).
      .readingWidth()
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(verb.capitalized)
    .navigationBarTitleDisplayMode(.large)
    .onAppear { Current.analytics.signal(name: .viewVerbView) }
  }

  private var metadataHeader: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      if !gloss.isEmpty {
        Text(gloss)
          .font(.title3)
          .foregroundStyle(Color.customForeground)
      }

      HStack(spacing: Layout.defaultSpacing) {
        Text(typeOrParent).metadataPill(tint: .customYellow)
        if isDefective {
          Text(L.Verb.defective).metadataPill(tint: .customRed)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        nonFiniteRow(DisplayTense.participio.titleCaseName, form: participio)
        nonFiniteRow(DisplayTense.gerundio.titleCaseName, form: gerundio)
        nonFiniteRow(DisplayTense.raízFutura.titleCaseName, form: raizFutura)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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

  private func etymologyCard(_ text: String) -> some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(L.Verb.etymology)
        .font(.headline)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isHeader)

      EtymologyText(text: text)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private var exampleCard: some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(example != nil && medievalExample != nil ? L.Verb.exampleUses : L.Verb.exampleUse)
        .font(.headline)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isHeader)

      if let example {
        Text(example.es)
          .font(.body)
          .fontDesign(.serif)
          .foregroundStyle(Color.customForeground)
          .speakOnTapFlash(example.es)

        Text(example.en)
          .font(.callout)
          .foregroundStyle(.secondary)

        Text(example.provenance.attribution)
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .trailing)
      }

      if let medieval = medievalExample {
        medievalSection(medieval, showDivider: example != nil)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }

  private func medievalSection(_ medieval: MedievalExample, showDivider: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      if showDivider {
        Divider()
          .padding(.vertical, 4)
      }

      HStack {
        Text(L.Verb.medievalExample)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.customBlue)
          .accessibilityAddTraits(.isHeader)
        Spacer()
        if medievalExamples.count > 1 {
          Button {
            withAnimation {
              medievalIndex = (medievalIndex + 1) % medievalExamples.count
            }
          } label: {
            Image(systemName: "arrow.forward.circle")
              .foregroundStyle(Color.customRed)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(Text(L.Verb.nextMedievalExample))
        }
      }

      Text(medieval.reference)
        .font(.caption)
        .foregroundStyle(.secondary)

      Text(medieval.os)
        .font(.body)
        .fontDesign(.serif)
        .foregroundStyle(Color.customForeground)
        .speakOnTapFlash(medieval.os)

      Text(medieval.tr)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  /// Every tense's conjugation card, in order — the single content builder reused
  /// by the compact single column and the regular-width 2-up grid so they can never
  /// diverge.
  @ViewBuilder
  private var conjugationCards: some View {
    ForEach(sections) { section in
      conjugationCard(section)
    }
  }

  private func conjugationCard(_ section: ConjugationSection) -> some View {
    VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
      Text(section.tense.titleCaseName)
        .font(.headline)
        .fontDesign(.serif)
        .foregroundStyle(Color.customYellow)
        .accessibilityAddTraits(.isHeader)

      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Layout.doubleDefaultSpacing, verticalSpacing: 6) {
        ForEach(section.rows) { row in
          GridRow {
            Text(row.pronoun ?? "")
              .font(.body)
              .foregroundStyle(.secondary)
            formView(row)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardWithAccentBar(.customYellow)
  }

  @ViewBuilder
  private func formView(_ row: ConjugationDisplayRow) -> some View {
    if row.form.isEmpty {
      Text(verbatim: "—")
        .font(.body)
        .foregroundStyle(.tertiary)
    } else {
      ConjugationText(form: row.displayForm)
        .font(.body)
        .speakOnTapFlash(row.spokenText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private static func form(_ verb: String, _ tense: DisplayTense) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: .none) {
      return value
    }
    return ""
  }

  private static func typeOrParent(verb: String, entry: VerbMapEntry?) -> String {
    switch Conjugator.verbType(infinitive: verb) {
    case .regularAr:
      return "\(L.Verb.regular) AR"
    case .regularEr:
      return "\(L.Verb.regular) ER"
    case .regularIr:
      return "\(L.Verb.regular) IR"
    case .irregular:
      if let classNumber = entry?.classNumber,
         let exemplar = ModelCatalog.exemplar(forClass: classNumber),
         exemplar != verb {
        return L.Verb.irregularWithParent(exemplar: exemplar)
      }
      return L.Verb.irregular
    }
  }

  /// Build the displayed conjugation sections — one per tense, each a
  /// pronoun-ordered list of rows. Mirrors the row set the legacy
  /// `ConjugationDataSource` produced (yo where the tense has one, the tú/vos/both
  /// second-singular per `Settings.secondSingularBrowse`, then the plural persons),
  /// with a defective/formless slot rendered blank.
  private static func buildSections(verb: String) -> [ConjugationSection] {
    let secondSingular = Current.settings.secondSingularBrowse
    return DisplayTense.conjugatedTenses.map { tense in
      let isImperative = tense == .imperativoPositivo || tense == .imperativoNegativo
      var persons: [DisplayPersonNumber] = []
      if tense.hasYoForm {
        persons.append(.firstSingular)
      }
      switch secondSingular {
      case .tu:
        persons.append(.secondSingularTú)
      case .vos:
        persons.append(.secondSingularVos)
      case .both:
        persons.append(contentsOf: [.secondSingularTú, .secondSingularVos])
      }
      persons.append(contentsOf: [.thirdSingular, .firstPlural, .secondPlural, .thirdPlural])

      let rows = persons.enumerated().map { index, personNumber in
        ConjugationDisplayRow(
          index: index,
          pronoun: isImperative ? nil : personNumber.pronoun,
          form: formOrBlank(verb, tense, personNumber),
          isImperative: isImperative
        )
      }
      return ConjugationSection(tense: tense, rows: rows)
    }
  }

  /// One displayed slot: a defective verb's formless slot renders blank; any other
  /// failure renders blank rather than crash.
  private static func formOrBlank(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber) {
      return value
    }
    return ""
  }
}

struct ConjugationSection: Identifiable {
  let tense: DisplayTense
  let rows: [ConjugationDisplayRow]
  var id: String { tense.rawValue }
}

struct ConjugationDisplayRow: Identifiable {
  let index: Int
  let pronoun: String?
  let form: String
  let isImperative: Bool
  var id: Int { index }

  /// The form as displayed: imperatives are wrapped in ¡…!.
  var displayForm: String {
    isImperative ? "¡\(form)!" : form
  }

  /// What to speak on tap: pronoun + form for finite tenses, the bare form for
  /// imperatives, all lowercased.
  var spokenText: String {
    if let pronoun {
      return "\(pronoun) \(form)".lowercased()
    }
    return form.lowercased()
  }
}
