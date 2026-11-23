//
//  VerbView.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import SwiftUI
import TipKit

struct VerbView: View {
  let verb: String
  /// How the learner reached the page, for `viewVerbView`. A later visit to the same page reports
  /// `resume` instead. See `VerbVisit`.
  let source: AnalyticsSource
  /// The cells that the search which opened the page matched, marked on the page. See
  /// `VerbDestination.marks`.
  let marks: Set<ConjugationCell>

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
  @State private var visit: VerbVisit?
  @State private var visibleSections: Set<VerbPageSection> = []
  @State private var hasAppeared = false
  @State private var hasScrolledToMark = false
  @State private var isOnScreen = false
  /// The tense article open in a sheet over the page, from the ⓘ beside a heading.
  @State private var article: Info?
  private let redLettersTip = RedLettersTip()
  private let scrollToBottomTip = ScrollToBottomTip()
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.scenePhase) private var scenePhase

  init(verb: String, source: AnalyticsSource, marks: Set<ConjugationCell> = []) {
    self.verb = verb
    self.source = source
    self.marks = marks
    let entry = VerbMap.shared.entry(for: verb)
    gloss = entry?.gloss ?? ""
    participio = Self.form(verb, .participio)
    gerundio = Self.form(verb, .gerundio)
    raizFutura = Self.form(verb, .raízFutura) + "-"
    isDefective = Conjugator.isDefective(infinitive: verb)
    typeOrParent = Self.typeOrParent(verb: verb, entry: entry)
    sections = Self.buildSections(verb: verb, marks: marks)
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

  /// The first card with a marked row, in the page's own order, which the page scrolls to when
  /// it opens. Nil when nothing is marked or only the header is.
  private var markedSectionID: String? {
    sections.first { $0.rows.contains(where: \.isMarked) }?.id
  }

  /// Whether any form on the page has a red letter, which the engine marks by writing it in
  /// uppercase. `RedLettersTip` has nothing to point at on a regular verb's page.
  private var hasRedLetters: Bool {
    let forms = sections.flatMap { $0.rows.map(\.form) } + [participio, gerundio, raizFutura]
    return forms.contains { $0.contains(where: \.isUppercase) }
  }

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: Layout.doubleDefaultSpacing) {
          metadataHeader
          if hasRedLetters {
            TipView(redLettersTip)
          }
          TipView(scrollToBottomTip)
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
              .reportsVisibility { sectionVisibilityChanged(.etymology, isVisible: $0) }
          }
          if example != nil || medievalExample != nil {
            exampleCard
              .reportsVisibility { sectionVisibilityChanged(.example, isVisible: $0) }
          }
        }
        .padding()
        // Cap the whole column to reading width and center it: the conjugation cards
        // are short, pronoun-keyed rows that read badly stretched across a 13" iPad,
        // and capping keeps the header/pills, the 2-up card grid, and the prose cards
        // sharing one tidy column. A no-op on iPhone (narrower than the cap).
        .readingWidth()
      }
      .onAppear {
        // Once only: returning to the page from another tab keeps the learner's place.
        guard !hasScrolledToMark, let markedSectionID else {
          return
        }
        hasScrolledToMark = true
        Task {
          proxy.scrollTo(markedSectionID, anchor: .top)
        }
      }
    }
    .sheet(item: $article) { info in
      TenseArticleSheet(info: info)
    }
    .background(Color.customBackground.ignoresSafeArea())
    .navigationTitle(ReflexivePronoun.citationForm(of: verb).capitalized)
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      isOnScreen = true
      beginVisit(source: hasAppeared ? .resume : source)
      hasAppeared = true
      unlockScrollTipIfDue()
    }
    .onDisappear {
      isOnScreen = false
      endVisit()
    }
    .onChange(of: scenePhase) {
      switch scenePhase {
      case .background:
        endVisit()
      case .active:
        if isOnScreen {
          beginVisit(source: .resume)
        }
      default:
        break
      }
    }
  }

  private func beginVisit(source: AnalyticsSource) {
    guard visit == nil else {
      return
    }
    let newVisit = VerbVisit(source: source, start: .now, visibleSections: visibleSections)
    visit = newVisit
    Current.analytics.signal(name: .viewVerbView, parameters: newVisit.viewParameters)
  }

  private func endVisit() {
    guard let visit else {
      return
    }
    Current.analytics.signal(name: .leaveVerbView, parameters: visit.leaveParameters(end: .now))
    self.visit = nil
  }

  // The scroll tip waits for a page visit after the red-letter tip was closed, rather than
  // replacing it in place the moment it closes. With tips switched off for screenshots, TipKit is
  // never configured, so this leaves its datastore alone.
  private func unlockScrollTipIfDue() {
    guard TipDisplay.tipsEnabled else {
      return
    }
    if case .invalidated = redLettersTip.status {
      ScrollToBottomTip.isUnlocked = true
    }
  }

  private func sectionVisibilityChanged(_ section: VerbPageSection, isVisible: Bool) {
    if isVisible {
      visibleSections.insert(section)
      visit?.reach(section)
      // A learner who reaches the etymology or the examples unprompted needs no advice.
      if section >= .etymology, TipDisplay.tipsEnabled {
        scrollToBottomTip.invalidate(reason: .actionPerformed)
      }
    } else {
      visibleSections.remove(section)
    }
  }

  /// The section whose arrival a tense's card marks: the first simple tense's card for `simple`,
  /// the first compound tense's for `compound`, and nil for every other card. Read from the
  /// page's own order, `ConjugationTable`, so that a reordering moves the marks with it.
  nonisolated static func section(markedBy tense: DisplayTense) -> VerbPageSection? {
    if tense == ConjugationTable.firstSimple {
      return .simple
    }
    if tense == ConjugationTable.firstCompound {
      return .compound
    }
    return nil
  }

  /// Whether the interface is Spanish, which picks the second names under each heading.
  private static var spanishInterface: Bool {
    Locale.current.language.languageCode?.identifier == "es"
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
        nonFiniteRow(DisplayTense.participio.titleCaseName, form: participio, isMarked: isMarked(.participio))
        nonFiniteRow(DisplayTense.gerundio.titleCaseName, form: gerundio, isMarked: isMarked(.gerundio))
        nonFiniteRow(DisplayTense.raízFutura.titleCaseName, form: raizFutura, isMarked: false)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func isMarked(_ tense: DisplayTense) -> Bool {
    marks.contains(ConjugationCell(tense: tense, personNumber: .none))
  }

  private func nonFiniteRow(_ label: String, form: String, isMarked: Bool) -> some View {
    HStack(spacing: Layout.defaultSpacing) {
      Text(label)
        .font(.subheadline)
        .foregroundStyle(.secondary)
      ConjugationText(form: form)
        .font(.body)
        .searchMark(isMarked)
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
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: Layout.defaultSpacing) {
          Text(Self.spanish(section.tense.titleCaseName))
            .font(.headline)
            .fontDesign(.serif)
            .foregroundStyle(Color.customYellow)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity, alignment: .leading)
          if let info = section.table.article {
            Button {
              Current.analytics.signal(name: .tapTenseArticle)
              article = info
            } label: {
              Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(Color.customBlue)
                // A 44-point target around a 17-point glyph, without making the heading taller.
                .padding(Layout.tapTargetInset)
                .contentShape(Rectangle())
                .padding(-Layout.tapTargetInset)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L.Verb.aboutThisTense))
          }
        }
        secondNamesLine(section.table)
      }

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
    .id(section.id)
    .reportsVisibility { isVisible in
      if let marked = Self.section(markedBy: section.tense) {
        sectionVisibilityChanged(marked, isVisible: isVisible)
      }
    }
  }

  /// "also preterite · pretérito perfecto simple" under a heading. VoiceOver hears each name as its
  /// own element, in its own language and without the "also", because one element cannot speak
  /// both English and Spanish.
  @ViewBuilder
  private func secondNamesLine(_ table: ConjugationTable) -> some View {
    let names = table.secondNames(spanishInterface: Self.spanishInterface)
    if !names.isEmpty {
      Text(Self.secondNamesText(names))
        .font(.footnote)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityRepresentation {
          VStack {
            ForEach(names, id: \.text) { name in
              Text(Self.attributed(name))
            }
          }
        }
    }
  }

  private static func secondNamesText(_ names: [ConjugationTable.SecondName]) -> AttributedString {
    var line = AttributedString("\(L.Verb.alsoKnownAs) ")
    for (index, name) in names.enumerated() {
      if index > 0 {
        line.append(AttributedString(" · "))
      }
      line.append(attributed(name))
    }
    return line
  }

  private static func attributed(_ name: ConjugationTable.SecondName) -> AttributedString {
    name.isSpanish ? spanish(name.text) : AttributedString(name.text)
  }

  /// Text that VoiceOver reads with a Spanish voice.
  private static func spanish(_ text: String) -> AttributedString {
    var attributed = AttributedString(text)
    attributed.languageIdentifier = "es"
    return attributed
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
        .searchMark(row.isMarked)
        .speakOnTapFlash(row.spokenText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private static func form(_ verb: String, _ tense: DisplayTense) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: .none, pronoun: .written) {
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
  /// with a defective/formless slot rendered blank. A page opened from a search for a vos form
  /// (hablás) shows vos as well as tú, whatever the setting, so that the mark has a row to sit
  /// on; likewise tú for a learner who chose vos.
  private static func buildSections(verb: String, marks: Set<ConjugationCell>) -> [ConjugationSection] {
    var secondSingular = Current.settings.secondSingularBrowse
    let hidden: [SecondSingularBrowse: DisplayPersonNumber] = [.tu: .secondSingularVos, .vos: .secondSingularTú]
    if let hiddenPerson = hidden[secondSingular], marks.contains(where: { $0.personNumber == hiddenPerson }) {
      secondSingular = .both
    }
    return ConjugationTable.all.map { table in
      let tense = table.tense
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
          isImperative: isImperative,
          isMarked: marks.contains(ConjugationCell(tense: tense, personNumber: personNumber))
        )
      }
      return ConjugationSection(table: table, rows: rows)
    }
  }

  /// One displayed slot: a defective verb's formless slot renders blank; any other
  /// failure renders blank rather than crash.
  private static func formOrBlank(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String {
    if case .success(let value) = TenseBridge.conjugate(infinitive: verb, tense: tense, personNumber: personNumber, pronoun: .written) {
      return value
    }
    return ""
  }
}

struct ConjugationSection: Identifiable {
  let table: ConjugationTable
  let rows: [ConjugationDisplayRow]
  var tense: DisplayTense { table.tense }
  var id: String { table.id }
}

/// A tense's Info article, opened from the ⓘ beside its heading on the verb page. A link to
/// another article opens that article here, so the learner can follow the thread and still close
/// the sheet onto the same verb page.
private struct TenseArticleSheet: View {
  let info: Info
  @Environment(\.dismiss) private var dismiss
  @State private var path: [Info] = []

  var body: some View {
    NavigationStack(path: $path) {
      article(info)
        .navigationDestination(for: Info.self) { next in
          article(next)
        }
    }
  }

  private func article(_ info: Info) -> some View {
    InfoView(info: info) { path.append($0) }
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(L.Verb.closeArticle) {
            dismiss()
          }
        }
      }
  }
}

struct ConjugationDisplayRow: Identifiable {
  let index: Int
  let pronoun: String?
  let form: String
  let isImperative: Bool
  /// True for a cell that the search which opened the page matched.
  let isMarked: Bool
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

private extension View {
  /// A tint behind a form that the search which opened the page matched, which VoiceOver reads
  /// as a value of the form.
  @ViewBuilder
  func searchMark(_ isMarked: Bool) -> some View {
    if isMarked {
      background {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.customYellow.opacity(0.25))
          .padding(-4)
      }
      .accessibilityValue(Text(L.Verb.matchesSearch))
    } else {
      self
    }
  }

  /// A third of a section's first card on screen counts as reaching the section. A higher
  /// threshold could never be met by an etymology card taller than the screen.
  func reportsVisibility(_ action: @escaping (Bool) -> Void) -> some View {
    onScrollVisibilityChange(threshold: 0.3, action)
  }
}
