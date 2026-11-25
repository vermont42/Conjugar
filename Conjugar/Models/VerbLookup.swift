//
//  VerbLookup.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Foundation

/// What the Look Up a Verb shortcut says about a word, and where it then opens the app. It reads
/// the verb list's own `VerbSearch`, so the two cannot disagree.
nonisolated struct VerbLookup: Sendable {
  enum Finding: Equatable, Sendable {
    /// The word is this verb's infinitive ("tener", "arrepentirse", "anadir" for añadir), or one
    /// of its English senses in full ("eat" for comer). `sense` indexes the gloss that matched,
    /// which for a homonym found by its second sense is not the first: "station" is apostar's
    /// second.
    case verb(VerbMapEntry, sense: Int = 0)

    /// The word is this form of this verb: fue, of ir.
    case form(MatchedForm, of: VerbMapEntry)

    /// The word is neither a verb nor a form, but other kinds of match found verbs: part of an
    /// infinitive, or of a gloss.
    case otherMatches(first: VerbMapEntry, count: Int)

    /// Nothing matched, and this is the empty state's guess.
    case guess(VerbMapEntry, form: MatchedForm?)

    case nothing
  }

  /// At most this many verbs are named, so that a spoken answer stays short. The search that a
  /// several-verb answer opens shows them all.
  static let maxNamedVerbs = 4

  /// The kinds that answer the question "which verb is this word?". An exact English sense
  /// answers it as an infinitive does, because the verb list ranks it above a form: "come" is
  /// llegar's and venir's before it is comer's él come, and a lookup that named only comer would
  /// mislead a learner who meant the English word.
  private static let literalAnswerKinds: Set<VerbSearch.MatchKind> = [.exactInfinitive, .exactGlossSense, .conjugation]

  /// The kinds that answer when no literal kind does: the same questions, with accents and ñ
  /// folded away.
  private static let foldedAnswerKinds: Set<VerbSearch.MatchKind> = [.exactFoldedInfinitive, .foldedConjugation]

  /// Trimmed.
  let word: String
  let findings: [Finding]
  /// The second-singular persons the verb page hides, which the answer's cell names leave out
  /// where tú and vos share a form, as a search result's do.
  let hidden: Set<DisplayPersonNumber>

  /// A verb's page, when one verb answers, with the form marked; otherwise the verb list searched
  /// for the word, which shows every match and, failing them, the guess. Pronouns that the
  /// lookup strips (dímelo, se lo dije, me levanto) never count against the page, because they
  /// leave a form of one verb.
  let destination: URL?

  init(word: String, entries: some Sequence<VerbMapEntry>, hiding hidden: Set<DisplayPersonNumber>, index: ConjugationIndex = .bundled) {
    let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
    self.word = trimmed
    self.hidden = hidden
    let entries = Array(entries)
    let matches = VerbSearch.matches(for: trimmed, in: entries, index: index)

    // A folded infinitive or form answers only when nothing literal does: "se" answers with
    // saber's sé and ser's sé, since nothing is spelled "se", and "anadir" with añadir. So soñar,
    // typed with its ñ, opens soñar's page, though it folds to sonar.
    let literalAnswers = matches.filter { Self.literalAnswerKinds.contains($0.kind) }
    let answers = literalAnswers.isEmpty ? matches.filter { Self.foldedAnswerKinds.contains($0.kind) } : literalAnswers

    var findings: [Finding] = answers.prefix(Self.maxNamedVerbs).flatMap { match -> [Finding] in
      guard match.kind == .conjugation || match.kind == .foldedConjugation else {
        let sense = match.kind == .exactGlossSense ? VerbSearch.sense(of: match.entry, namedBy: trimmed) : nil
        return [.verb(match.entry, sense: sense ?? 0)]
      }
      let shown = MatchedForm.shown(match.forms, hiding: hidden)
      // "hablo" is hablar's hablo; its habló, which the list also names, was not what was typed.
      let named = match.kind == .conjugation ? shown.filter { !$0.isFolded } : shown
      return (named.isEmpty ? shown : named).map { .form($0, of: match.entry) }
    }
    if findings.isEmpty {
      if let first = matches.first {
        findings.append(.otherMatches(first: first.entry, count: matches.count))
      } else if let guess = VerbSearch.guess(for: trimmed, in: entries, index: index) {
        findings.append(.guess(guess.entry, form: guess.form))
      } else {
        findings.append(.nothing)
      }
    }
    self.findings = findings

    if answers.count == 1, let answer = answers.first {
      let form = findings.lazy.compactMap { finding -> MatchedForm? in
        if case let .form(form, _) = finding {
          return form
        }
        return nil
      }.first
      let infinitive = answer.entry.infinitive
      var match: String?
      var cells: [ConjugationCell]?
      if let form {
        let text = Self.markableText(of: form, on: infinitive, hiding: hidden)
        match = text
        cells = Self.cellsToName(for: form, on: infinitive, match: text, hiding: hidden)
      }
      destination = URL.verbDeeplink(infinitive, source: .lookup, match: match, cells: cells)
    } else {
      destination = URL.searchDeeplink(text: trimmed, source: .lookup)
    }
  }

  /// The text a verb link's `match` carries for `form`, which the page turns back into cells with
  /// `ConjugationMatch`. That reads cells only, so a form with pronouns joined (dímelo) or a
  /// participle's ending (hecha) is sent as the bare form of its first cell (di, hecho). Where
  /// that bare form is also another cell (levanta), `cellsToName` names the cells meant.
  static func markableText(of form: MatchedForm, on infinitive: String, hiding hidden: Set<DisplayPersonNumber>) -> String {
    if !ConjugationMatch.cells(of: infinitive, equalTo: form.text).isEmpty {
      return form.text
    }
    guard
      let cell = form.shownCells(hiding: hidden).first ?? form.cells.first,
      case let .success(bare) = TenseBridge.conjugate(infinitive: infinitive, tense: cell.tense, personNumber: cell.personNumber, pronoun: .omitted)
    else {
      return form.text
    }
    return bare.lowercased()
  }

  /// The cells a verb link names beside `match`, when `match` alone would mark cells that `form`
  /// is not: levántate's link carries levanta, which is also the presente's él, so it names the
  /// tú command too. Nil when `match` marks exactly `form`'s cells.
  static func cellsToName(for form: MatchedForm, on infinitive: String, match: String, hiding hidden: Set<DisplayPersonNumber>) -> [ConjugationCell]? {
    let cells = form.shownCells(hiding: hidden)
    return MatchedForm.marks(of: match, on: infinitive, hiding: hidden) == Set(cells) ? nil : cells
  }

  /// The answer as the shortcut speaks and shows it, one finding per line.
  func answer() -> String {
    findings.map { finding in
      switch finding {
      case let .verb(entry, sense):
        // A homonym found by its second sense is named by it, though its key conjugations are the
        // first sense's, which the page also shows: the engine conjugates a verb by its first
        // sense unless given a model.
        let gloss = entry.glosses.indices.contains(sense) ? entry.glosses[sense] : entry.gloss
        let heading = L.Lookup.verbWithGloss(infinitive: entry.citationForm, gloss: gloss)
        let keyConjugations = KeyConjugation.line(for: entry.infinitive)
        return keyConjugations.isEmpty ? heading : "\(heading): \(keyConjugations)"
      case .form(let form, let entry):
        return L.Lookup.form(form.text, cells: form.cellNames(hiding: hidden), infinitive: entry.citationForm)
      case .otherMatches(let first, let count):
        let firstVerb = L.Lookup.verbWithGloss(infinitive: first.citationForm, gloss: first.gloss)
        return count == 1
          ? L.Lookup.otherMatchesOne(word, verb: firstVerb)
          : L.Lookup.otherMatchesMany(word, count: count, verb: firstVerb)
      case .guess(let entry, let form):
        if let form {
          return L.Lookup.guessForm(word, form: form.text, infinitive: entry.citationForm)
        }
        return L.Lookup.guessVerb(word, infinitive: entry.citationForm)
      case .nothing:
        return L.Lookup.nothing(word)
      }
    }
    .joined(separator: "\n")
  }
}
