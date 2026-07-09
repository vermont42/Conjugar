//
//  VerbView.swift
//  Conjugar
//
//  The SwiftUI verb-detail screen, replacing the UIKit VerbVC/VerbUIV. Metadata
//  pills over conjugation-section cards with leading accent bars and a two-column
//  pronoun | form grid; irregular spans render red, Spanish forms are
//  serif, and every form speaks on tap. Reuses `ConjugationDataSource` to build
//  the exact same rows the UIKit screen showed.
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
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
        metadataHeader
        ForEach(sections) { section in
          conjugationCard(section)
        }
        if let etymology {
          etymologyCard(etymology)
        }
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(verb.capitalized)
    .navigationBarTitleDisplayMode(.large)
    .onAppear { Current.analytics.recordVisitation(viewController: "\(VerbView.self)") }
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
