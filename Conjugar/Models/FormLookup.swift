//
//  FormLookup.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// A form that a search matched, and the cells of the verb's page it fills: "fue" fills ser's
/// pretérito (él), and "dímelo" fills decir's imperativo positivo (tú).
nonisolated struct MatchedForm: Hashable, Sendable {
  /// As the app spells it, which is not always as typed: habló for "hablo", dímelo for "dimelo",
  /// "he hablado" for "yo he hablado".
  let text: String

  /// In the page's order. Never empty.
  let cells: [ConjugationCell]

  /// True when `text` equals the query only after folding accents (or ñ).
  let isFolded: Bool

  /// The cells to name and mark. Where tú and vos share a form in one tense (hablaste), the
  /// person that the verb page hides is left out, so that a learner who never chose vos does
  /// not read "(tú, vos)" on every line. A form that only the hidden person has (hablás) keeps
  /// it, and the page then shows that person.
  func shownCells(hiding hidden: Set<DisplayPersonNumber>) -> [ConjugationCell] {
    let all = Set(cells)
    return cells.filter { cell in
      guard hidden.contains(cell.personNumber), let counterpart = Self.secondSingularCounterpart[cell.personNumber] else {
        return true
      }
      return !all.contains(ConjugationCell(tense: cell.tense, personNumber: counterpart))
    }
  }

  /// The forms a result row names. A form found only by folding, every cell of which is a
  /// person the page hides, is left out when another form remains: "habla" names habla, not the
  /// vos command hablá, for a learner who never chose vos. "tenes" still names tenés, its only form.
  static func shown(_ forms: [MatchedForm], hiding hidden: Set<DisplayPersonNumber>) -> [MatchedForm] {
    let visible = forms.filter { !$0.isFolded || !$0.cells.allSatisfy { hidden.contains($0.personNumber) } }
    return visible.isEmpty ? forms : visible
  }

  private static let secondSingularCounterpart: [DisplayPersonNumber: DisplayPersonNumber] = [
    .secondSingularTú: .secondSingularVos,
    .secondSingularVos: .secondSingularTú
  ]

  /// "Presente de Subjuntivo (yo, él) · Imperativo Positivo (usted)", in the tense names the
  /// page uses. Persons go in parentheses, which a Spanish line needs no conjunction for.
  func cellNames(hiding hidden: Set<DisplayPersonNumber> = []) -> String {
    var groups: [(name: String, persons: [String])] = []
    for cell in shownCells(hiding: hidden) {
      let name = cell.tense.titleCaseName
      let person = Self.personName(of: cell)
      if let index = groups.firstIndex(where: { $0.name == name }) {
        groups[index].persons += person.map { [$0] } ?? []
      } else {
        groups.append((name, person.map { [$0] } ?? []))
      }
    }
    return groups
      .map { $0.persons.isEmpty ? $0.name : "\($0.name) (\($0.persons.joined(separator: ", ")))" }
      .joined(separator: " · ")
  }

  /// "hablo: Presente de Indicativo (yo)", the line a result row shows.
  func line(hiding hidden: Set<DisplayPersonNumber> = []) -> String {
    "\(text): \(cellNames(hiding: hidden))"
  }

  /// The page's pronouns, except that a command's third persons are usted and ustedes, whom a
  /// command addresses. Nil for the infinitive, the gerund, and the participle.
  static func personName(of cell: ConjugationCell) -> String? {
    guard cell.personNumber != .none else {
      return nil
    }
    let isCommand = cell.tense == .imperativoPositivo || cell.tense == .imperativoNegativo
    switch cell.personNumber {
    case .thirdSingular where isCommand:
      return "usted"
    case .thirdPlural where isCommand:
      return "ustedes"
    default:
      return cell.personNumber.pronoun
    }
  }
}

/// Finds the verbs whose forms a query is, for search. A form may arrive as a learner meets it in
/// a sentence, so the lookup undoes what a sentence does to a form:
///
/// - A subject pronoun before it is dropped and narrows the persons: "yo hablo", "ella hable".
/// - A leading "no" and object or reflexive pronouns are dropped: "no hablo", "me levanto", "se
///   lo dije". "no hables" is first tried whole, as the imperativo negativo.
/// - Up to two pronouns joined to a command, a gerund, or an infinitive are split off, and the
///   accent that joining them added is removed: dímelo, levántate, diciéndole, vámonos.
/// - A participle with a feminine or plural ending (hecha, rotos, dichas) is read as its -o
///   form, but only as a participle.
/// - The last word of a compound tense ("he hablado", "habría dicho") finds the verb, and the
///   verb's own cells confirm the whole text. A periphrasis ("estoy hablando", "voy a comer")
///   that no cell confirms finds the verb of its last word, if that word is non-finite.
///
/// Every candidate is confirmed against the engine's own forms, so nothing merely shaped like a
/// form matches. Accents may be missing: a form that matches only after folding is marked so.
nonisolated enum FormLookup {
  /// The forms each verb matched, keyed by infinitive.
  static func forms(for query: String, index: ConjugationIndex = .bundled) -> [String: [MatchedForm]] {
    var words = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
    var persons: Set<DisplayPersonNumber>?
    if words.count > 1, let subject = subjectPersons[words[0]] {
      persons = subject
      words.removeFirst()
    }
    guard !words.isEmpty, words.allSatisfy({ $0.allSatisfy(\.isLetter) }) else {
      return [:]
    }
    let found = lookUp(words, index: index)
    guard let persons else {
      return found
    }
    return found.mapValues { forms in
      let narrowed = forms.compactMap { form -> MatchedForm? in
        let cells = form.cells.filter { persons.contains($0.personNumber) || $0.personNumber == .none }
        return cells.isEmpty ? nil : MatchedForm(text: form.text, cells: cells, isFolded: form.isFolded)
      }
      // "yo hablamos" is a slip in the pronoun, not a reason to find nothing.
      return narrowed.isEmpty ? forms : narrowed
    }
  }

  private static func lookUp(_ words: [String], index: ConjugationIndex) -> [String: [MatchedForm]] {
    guard let lastWord = words.last else {
      return [:]
    }
    guard words.count > 1 else {
      return oneWord(lastWord, index: index, tenses: nil)
    }
    let candidates = Set(oneWord(lastWord, index: index, tenses: nil, includingInfinitive: true).keys)
    let whole = confirmed(words.joined(separator: " "), candidates: candidates)
    guard whole.isEmpty else {
      return whole
    }
    var core = words[...]
    while core.count > 1, let first = core.first, first == "no" || clitics.contains(first) {
      core.removeFirst()
    }
    if core.count < words.count {
      let fromCore = core.count == 1
        ? oneWord(lastWord, index: index, tenses: nil)
        : confirmed(core.joined(separator: " "), candidates: candidates)
      if !fromCore.isEmpty {
        return fromCore
      }
    }
    return oneWord(lastWord, index: index, tenses: nonFiniteTenses, includingInfinitive: true)
  }

  private static let nonFiniteTenses: Set<DisplayTense> = [.infinitivo, .gerundio, .participio]
  private static let encliticTenses: Set<DisplayTense> = [.imperativoPositivo, .gerundio, .infinitivo]

  /// The forms `word` is, as written, folded, with pronouns joined, or as a participle with an
  /// ending. The infinitive itself is left to the infinitive search unless asked for; a pronoun
  /// joined to it (decirle) is a form here either way.
  private static func oneWord(
    _ word: String,
    index: ConjugationIndex,
    tenses: Set<DisplayTense>?,
    includingInfinitive: Bool = false
  ) -> [String: [MatchedForm]] {
    var found = FoundForms()
    func allows(_ cell: ConjugationCell) -> Bool {
      (tenses?.contains(cell.tense) ?? true) && (includingInfinitive || cell.tense != .infinitivo)
    }

    for spelling in index.spellings(of: word) {
      for entry in index.map.entries(for: spelling.form) {
        found.add(entry.infinitive, text: spelling.form, cells: entry.cells.filter(allows), isFolded: spelling.isFolded)
      }
    }

    for parse in encliticParses(of: word) {
      for base in parse.bases {
        for form in index.forms(folding: VerbSearch.fold(base)) {
          for entry in index.map.entries(for: form) {
            for cell in entry.cells where encliticTenses.contains(cell.tense) && (tenses?.contains(cell.tense) ?? true) {
              let joined = attach(parse.clitics, to: form, at: cell)
              guard VerbSearch.fold(joined) == VerbSearch.fold(word) else {
                continue
              }
              found.add(entry.infinitive, text: joined, cells: [cell], isFolded: joined != word)
            }
          }
        }
      }
    }

    for ending in participleEndings where word.hasSuffix(ending) && word.count > ending.count + 2 {
      let masculine = String(word.dropLast(ending.count)) + "o"
      for spelling in index.spellings(of: masculine) {
        for entry in index.map.entries(for: spelling.form) {
          let cells = entry.cells.filter { $0.tense == .participio && allows($0) }
          found.add(entry.infinitive, text: String(spelling.form.dropLast()) + ending, cells: cells, isFolded: spelling.isFolded)
        }
      }
    }
    return found.byInfinitive
  }

  private static let participleEndings = ["a", "os", "as"]

  static let clitics: Set<String> = ["me", "te", "se", "nos", "os", "lo", "la", "los", "las", "le", "les"]

  private struct EncliticParse {
    let clitics: [String]
    /// What the form may have been before the pronouns joined it: dímelo's "dí", vámonos'
    /// "vámo" with its dropped -s restored, levantaos' "levanta" with its -d.
    let bases: [String]
  }

  /// Every way to read the end of `word` as one or two pronouns: dímelo as dí + me + lo.
  private static func encliticParses(of word: String) -> [EncliticParse] {
    var parses: [EncliticParse] = []
    for last in clitics where word.hasSuffix(last) {
      let beforeLast = String(word.dropLast(last.count))
      parses.append(contentsOf: parse(base: beforeLast, clitics: [last]))
      for first in clitics where first != last && beforeLast.hasSuffix(first) {
        parses.append(contentsOf: parse(base: String(beforeLast.dropLast(first.count)), clitics: [first, last]))
      }
    }
    return parses
  }

  private static func parse(base: String, clitics: [String]) -> [EncliticParse] {
    // "di" and "ve" are the shortest commands; a lone letter before a pronoun is no form.
    guard base.count >= 2, let first = clitics.first else {
      return []
    }
    var bases = [base]
    if first == "nos" || first == "se" {
      bases.append(base + "s")
    }
    if first == "os" {
      bases.append(base + "d")
    }
    return [EncliticParse(clitics: clitics, bases: bases)]
  }

  /// `clitics` joined to `form` as Spanish joins them, with the accent the joined word needs.
  /// The nosotros command drops its -s before nos and se (démoselo), and the vosotros command
  /// its -d before os (levantaos), except ir's id (idos).
  static func attach(_ clitics: [String], to form: String, at cell: ConjugationCell) -> String {
    var dropped = 0
    if cell.tense == .imperativoPositivo, let first = clitics.first {
      if cell.personNumber == .firstPlural, first == "nos" || first == "se", form.hasSuffix("s") {
        dropped = 1
      }
      if cell.personNumber == .secondPlural, first == "os", form.hasSuffix("d"), form != "id" {
        dropped = 1
      }
    }
    return ReflexivePronoun.enclitic(clitics.joined(), attachedTo: form, droppingLast: dropped)
  }

  /// The cells of each candidate verb that the whole of `text` is, compound tenses and the
  /// imperativo negativo included, by the verb's own conjugations: exactly if any match, else
  /// with accents folded.
  private static func confirmed(_ text: String, candidates: Set<String>) -> [String: [MatchedForm]] {
    var found = FoundForms()
    for infinitive in candidates.sorted() {
      var isFolded = false
      var cells = ConjugationMatch.cells(of: infinitive, equalTo: text, accents: .exact)
      if cells.isEmpty {
        cells = ConjugationMatch.cells(of: infinitive, equalTo: text, accents: .folded)
        isFolded = true
      }
      // Group the cells by spelling: "habria dicho" might match more than one.
      var cellsBySpelling: [(text: String, cells: [ConjugationCell])] = []
      for cell in cells {
        let spelled = spelling(of: infinitive, at: cell, matching: text, accents: isFolded ? .folded : .exact)
        if let index = cellsBySpelling.firstIndex(where: { $0.text == spelled }) {
          cellsBySpelling[index].cells.append(cell)
        } else {
          cellsBySpelling.append((spelled, [cell]))
        }
      }
      for (spelled, cells) in cellsBySpelling {
        found.add(infinitive, text: spelled, cells: cells, isFolded: spelled != text)
      }
    }
    return found.byInfinitive
  }

  /// The cell's form as the app writes it, with the reflexive pronoun if that is what matched.
  private static func spelling(of infinitive: String, at cell: ConjugationCell, matching text: String, accents: ConjugationMatch.Accents) -> String {
    let target = ConjugationMatch.normalized(text, accents: accents)
    for pronoun in [ReflexivePronoun.omitted, .written] {
      if
        case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: cell.tense, personNumber: cell.personNumber, pronoun: pronoun),
        ConjugationMatch.normalized(form, accents: accents) == target
      {
        return form.lowercased()
      }
    }
    return text
  }

  /// Subject pronouns, written with or without their accents, and the persons each names.
  private static let subjectPersons: [String: Set<DisplayPersonNumber>] = {
    var persons: [String: Set<DisplayPersonNumber>] = [:]
    for word in ["yo"] { persons[word] = [.firstSingular] }
    for word in ["tú", "tu"] { persons[word] = [.secondSingularTú] }
    for word in ["vos"] { persons[word] = [.secondSingularVos] }
    for word in ["él", "el", "ella", "usted", "ud", "ud.", "vd", "vd."] { persons[word] = [.thirdSingular] }
    for word in ["nosotros", "nosotras"] { persons[word] = [.firstPlural] }
    for word in ["vosotros", "vosotras"] { persons[word] = [.secondPlural] }
    for word in ["ellos", "ellas", "ustedes", "uds", "uds.", "vds", "vds."] { persons[word] = [.thirdPlural] }
    return persons
  }()
}

/// The forms found for each verb, merged so that one spelling appears once per verb.
private nonisolated struct FoundForms {
  private(set) var byInfinitive: [String: [MatchedForm]] = [:]

  mutating func add(_ infinitive: String, text: String, cells: [ConjugationCell], isFolded: Bool) {
    guard !cells.isEmpty else {
      return
    }
    var forms = byInfinitive[infinitive, default: []]
    if let index = forms.firstIndex(where: { $0.text == text }) {
      let merged = Set(forms[index].cells).union(cells)
      forms[index] = MatchedForm(text: text, cells: Self.inPageOrder(merged), isFolded: forms[index].isFolded && isFolded)
    } else {
      forms.append(MatchedForm(text: text, cells: Self.inPageOrder(Set(cells)), isFolded: isFolded))
    }
    // Literal spellings first, then each spelling by its first cell's place on the page.
    byInfinitive[infinitive] = forms.sorted { lhs, rhs in
      (lhs.isFolded ? 1 : 0, Self.pageIndex(lhs.cells[0]), lhs.text) < (rhs.isFolded ? 1 : 0, Self.pageIndex(rhs.cells[0]), rhs.text)
    }
  }

  private static func inPageOrder(_ cells: Set<ConjugationCell>) -> [ConjugationCell] {
    cells.sorted { pageIndex($0) < pageIndex($1) }
  }

  private static func pageIndex(_ cell: ConjugationCell) -> Int {
    pageIndexes[cell] ?? Int.max
  }

  private static let pageIndexes: [ConjugationCell: Int] = Dictionary(
    uniqueKeysWithValues: ConjugationMatch.allCells.enumerated().map { ($1, $0) }
  )
}
