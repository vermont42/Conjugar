//
//  ReflexivePronoun.swift
//  Conjugar
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// How a verb that exists only as a pronominal verb is written. `verbModelMap.xml` flags 114
// such verbs `rx="1"` (arrepentir, abstener, atrever, quejar…) and stores them bare, and the
// engine conjugates them bare: arrepiento, a form no one uses. Spanish writes them with the
// reflexive pronoun, in one of two places:
//
//   - **Proclitic**, a separate word before a finite form: me arrepiento, me he arrepentido,
//     and after the "no" of a negative command, no te arrepientas.
//   - **Enclitic**, joined to the end of an affirmative command and the gerund: arrepiéntete,
//     arrepintámonos, arrepentíos, arrepintiéndose. The stress stays where it was, so the
//     longer word may need a written accent the bare form lacked (arrepiente → arrepiéntete),
//     or lose one it had (vos arrepentí → arrepentite). The nosotros command drops its -s
//     before nos (arrepintamos → arrepintámonos) and the vosotros command its -d before os
//     (arrepentid → arrepentíos).
//
// The participle and the future stem take no pronoun.
//
// The engine's own output stays bare, which keeps every oracle test and the corpus dumps as
// they were. Surfaces that show a form to a learner ask for `.written`.
nonisolated enum ReflexivePronoun: Sendable {
  /// The engine's form, with no pronoun: arrepiento. The default.
  case omitted
  /// For a reflexive-only verb, the form as Spanish writes it: me arrepiento, arrepiéntete.
  /// Any other verb's form is unchanged.
  case written

  /// The pronoun of a person: me, te, se, nos, os, se. Nil for `.none`.
  static func pronoun(for personNumber: DisplayPersonNumber) -> String? {
    switch personNumber {
    case .firstSingular:
      return "me"
    case .secondSingularTú, .secondSingularVos:
      return "te"
    case .thirdSingular, .thirdPlural:
      return "se"
    case .firstPlural:
      return "nos"
    case .secondPlural:
      return "os"
    case .none:
      return nil
    }
  }

  /// Whether `clitics`, joined to a form of `cell` in that order, can be Spanish, judged by the
  /// first of them against `pronoun(for:)`. On a command, te, os, and se are reflexive and must
  /// be the person's own: levántate is the tú command and levantaos the vosotros command, but
  /// hablá + se is no word. Any pronoun may join the gerund or the infinitive. Me and nos are
  /// free, because they are also objects that every command takes (dime, dinos, ayúdennos). So
  /// is a first pronoun followed by lo, la, los, or las, which is an indirect object: dáselo,
  /// dímelo. Rarer object uses of te, os, and se (ayúdeos) are refused, which costs less than
  /// marking a vos command for every imperfecto de subjuntivo in -se.
  static func encliticAgrees(_ clitics: [String], with cell: ConjugationCell) -> Bool {
    guard cell.tense == .imperativoPositivo, let first = clitics.first, reflexiveOnlyClitics.contains(first) else {
      return true
    }
    if clitics.count > 1, directObjectClitics.contains(clitics[1]) {
      return true
    }
    return pronoun(for: cell.personNumber) == first
  }

  private static let reflexiveOnlyClitics: Set<String> = ["te", "os", "se"]
  private static let directObjectClitics: Set<String> = ["lo", "la", "los", "las"]

  /// Whether the bundled map flags `infinitive` as reflexive-only.
  static func isReflexiveOnly(_ infinitive: String) -> Bool {
    VerbMap.shared.entry(for: infinitive)?.isReflexive ?? false
  }

  /// The infinitive as a dictionary cites it: arrepentirse for a reflexive-only verb, the bare
  /// infinitive for any other.
  static func citationForm(of infinitive: String) -> String {
    VerbMap.shared.entry(for: infinitive)?.citationForm ?? infinitive
  }

  /// The bare infinitive of a pronominal citation form, arrepentirse giving arrepentir, or nil
  /// when `text` does not end in an infinitive followed by "se".
  static func bareInfinitive(fromCitation text: String) -> String? {
    guard text.hasSuffix("se") else {
      return nil
    }
    let bare = String(text.dropLast(2))
    return ["ar", "er", "ir", "ír"].contains(where: { bare.hasSuffix($0) }) ? bare : nil
  }

  /// `form`, a bare form of the slot (irregularity-marked or not), with the reflexive pronoun
  /// placed as Spanish places it. The caller decides whether the verb takes one.
  static func attach(to form: String, tense: DisplayTense, personNumber: DisplayPersonNumber) -> String {
    guard !form.isEmpty else {
      return form
    }
    switch tense {
    case .infinitivo:
      return form + "se"
    case .translation, .participio, .raízFutura:
      return form
    case .gerundio:
      return enclitic("se", attachedTo: form)
    case .imperativoPositivo:
      guard let pronoun = pronoun(for: personNumber) else {
        return form
      }
      // The nosotros command drops its -s before nos, the vosotros command its -d before os.
      let droppedLetters = personNumber == .firstPlural || personNumber == .secondPlural ? 1 : 0
      return enclitic(pronoun, attachedTo: form, droppingLast: droppedLetters)
    case .imperativoNegativo:
      guard let pronoun = pronoun(for: personNumber) else {
        return form
      }
      let negation = "no "
      guard form.lowercased().hasPrefix(negation) else {
        return pronoun + " " + form
      }
      return String(form.prefix(negation.count)) + pronoun + " " + String(form.dropFirst(negation.count))
    case .presenteDeIndicativo, .pretérito, .imperfectoDeIndicativo, .futuroDeIndicativo, .condicional,
         .presenteDeSubjuntivo, .imperfectoDeSubjuntivo1, .imperfectoDeSubjuntivo2, .futuroDeSubjuntivo,
         .perfectoDeIndicativo, .pretéritoAnterior, .pluscuamperfectoDeIndicativo, .futuroPerfecto,
         .condicionalCompuesto, .perfectoDeSubjuntivo, .pluscuamperfectoDeSubjuntivo1,
         .pluscuamperfectoDeSubjuntivo2, .futuroPerfectoDeSubjuntivo:
      guard let pronoun = pronoun(for: personNumber) else {
        return form
      }
      return pronoun + " " + form
    }
  }

  /// `clitic` joined to the end of `word`, after dropping `droppingLast` letters, with the
  /// written accent the general rules then require on the syllable `word` stressed. Since the
  /// RAE's 2010 orthography, a verb with enclitics follows the general rules like any word, so
  /// dé + me is deme and está + te is estate. The case of each letter is kept, so the
  /// irregularity marking (uppercase) survives: arrepIEnte gives arrepIÉntete.
  static func enclitic(_ clitic: String, attachedTo word: String, droppingLast droppedLetters: Int = 0) -> String {
    var letters = Array(word)
    guard let stressed = stressedVowelIndex(in: letters) else {
      return String(letters.dropLast(droppedLetters)) + clitic
    }
    letters[stressed] = withAcute(letters[stressed], present: true)
    var joined = Array(letters.dropLast(droppedLetters)) + Array(clitic)
    let needsAccent = needsWrittenAccent(joined, stressedIndex: stressed)
    joined[stressed] = withAcute(joined[stressed], present: needsAccent)
    return String(joined)
  }

  /// Whether `letters`, whose stress falls on the vowel at `stressedIndex` (written there with
  /// an acute, so that it syllabifies as stressed), keeps the acute under the general rules.
  private static func needsWrittenAccent(_ letters: [Character], stressedIndex: Int) -> Bool {
    let lower = letters.map { Character($0.lowercased()) }
    // A stressed i or u beside a, e, or o is a hiatus, and the accent is what marks it:
    // arrepentíos, reírse.
    if "iu".contains(withAcute(lower[stressedIndex], present: false)) {
      let neighbors = [stressedIndex - 1, stressedIndex + 1].filter { lower.indices.contains($0) }
      if neighbors.contains(where: { isVowel(at: $0, in: lower) && strongVowels.contains(withAcute(lower[$0], present: false)) }) {
        return true
      }
    }
    let nuclei = syllableNuclei(in: lower)
    guard let position = nuclei.firstIndex(where: { $0.contains(stressedIndex) }) else {
      return false
    }
    let fromEnd = nuclei.count - 1 - position
    return fromEnd != naturalStressFromEnd(of: lower, nucleusCount: nuclei.count)
  }

  /// The vowel the word's stress falls on: a written accent's, else the general rules'. A word
  /// ending in a vowel, n, or s stresses its next-to-last syllable, and any other word its last.
  /// Within a diphthong, the strong vowel carries the stress (the e of ie), and between two weak
  /// vowels, the second (the i of ui).
  static func stressedVowelIndex(in letters: [Character]) -> Int? {
    let lower = letters.map { Character($0.lowercased()) }
    if let accented = lower.indices.first(where: { acuteVowels.contains(lower[$0]) }) {
      return accented
    }
    let nuclei = syllableNuclei(in: lower)
    guard !nuclei.isEmpty else {
      return nil
    }
    let fromEnd = naturalStressFromEnd(of: lower, nucleusCount: nuclei.count)
    let nucleus = nuclei[nuclei.count - 1 - fromEnd]
    return nucleus.first(where: { strongVowels.contains(lower[$0]) }) ?? nucleus.last
  }

  /// Which syllable, counted from the last (0), the general rules stress when no accent is
  /// written.
  private static func naturalStressFromEnd(of lower: [Character], nucleusCount: Int) -> Int {
    guard nucleusCount > 1, let last = lower.last else {
      return 0
    }
    let endsInVowelNOrS = "aeiouáéíóúü".contains(last) || last == "n" || last == "s"
    return endsInVowelNOrS ? 1 : 0
  }

  /// The vowels of each syllable, as indices into `lower`, first syllable first. Adjacent
  /// vowels share a syllable (a diphthong) unless both are strong, counting a weak vowel with
  /// an acute as strong (a hiatus). The u of que, qui, gue, and gui is silent and is no vowel.
  private static func syllableNuclei(in lower: [Character]) -> [[Int]] {
    var nuclei: [[Int]] = []
    var current: [Int] = []
    var currentHasPeak = false
    for index in lower.indices {
      guard isVowel(at: index, in: lower) else {
        if !current.isEmpty {
          nuclei.append(current)
          current = []
          currentHasPeak = false
        }
        continue
      }
      let isPeak = strongVowels.contains(lower[index]) || "íú".contains(lower[index])
      if isPeak && currentHasPeak {
        nuclei.append(current)
        current = []
        currentHasPeak = false
      }
      current.append(index)
      currentHasPeak = currentHasPeak || isPeak
    }
    if !current.isEmpty {
      nuclei.append(current)
    }
    return nuclei
  }

  private static func isVowel(at index: Int, in lower: [Character]) -> Bool {
    let letter = lower[index]
    guard "aeiouáéíóúü".contains(letter) else {
      return false
    }
    if letter == "u", index > 0, "qg".contains(lower[index - 1]), index + 1 < lower.count, "eiéí".contains(lower[index + 1]) {
      return false
    }
    return true
  }

  private static let strongVowels: Set<Character> = ["a", "e", "o", "á", "é", "ó"]
  private static let acuteVowels: Set<Character> = ["á", "é", "í", "ó", "ú"]

  /// `letter` with an acute added or removed, its case kept. Any other letter is returned as is.
  private static func withAcute(_ letter: Character, present: Bool) -> Character {
    let pairs: [(Character, Character)] = [
      ("a", "á"), ("e", "é"), ("i", "í"), ("o", "ó"), ("u", "ú"),
      ("A", "Á"), ("E", "É"), ("I", "Í"), ("O", "Ó"), ("U", "Ú")
    ]
    for (plain, accented) in pairs {
      if letter == plain || letter == accented {
        return present ? accented : plain
      }
    }
    return letter
  }
}
