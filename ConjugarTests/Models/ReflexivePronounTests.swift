//
//  ReflexivePronounTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//

import Testing
@testable import Conjugar

// A reflexive-only verb written as Spanish writes it: proclitic before a finite form,
// enclitic after an affirmative command and the gerund, with the accent enclisis requires.
// Expectations are lowercased unless a test is about the irregularity marking.
@Suite("ReflexivePronoun")
struct ReflexivePronounTests {
  static func written(_ infinitive: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String? {
    if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber, pronoun: .written) {
      return form.lowercased()
    }
    return nil
  }

  static func bare(_ infinitive: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> String? {
    if case let .success(form) = TenseBridge.conjugate(infinitive: infinitive, tense: tense, personNumber: personNumber) {
      return form.lowercased()
    }
    return nil
  }

  nonisolated static let finitePersons: [DisplayPersonNumber] = [
    .firstSingular, .secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural
  ]

  nonisolated static let reflexiveVerbs: [String] = VerbMap.shared.entries.values
    .filter(\.isReflexive)
    .map(\.infinitive)
    .sorted()

  @Test("arrepentirse's page reads as Spanish writes it", arguments: [
    (DisplayTense.presenteDeIndicativo, ["me arrepiento", "te arrepientes", "te arrepentís", "se arrepiente", "nos arrepentimos", "os arrepentís", "se arrepienten"]),
    (.pretérito, ["me arrepentí", "te arrepentiste", "te arrepentiste", "se arrepintió", "nos arrepentimos", "os arrepentisteis", "se arrepintieron"]),
    (.imperfectoDeIndicativo, ["me arrepentía", "te arrepentías", "te arrepentías", "se arrepentía", "nos arrepentíamos", "os arrepentíais", "se arrepentían"]),
    (.futuroDeIndicativo, ["me arrepentiré", "te arrepentirás", "te arrepentirás", "se arrepentirá", "nos arrepentiremos", "os arrepentiréis", "se arrepentirán"]),
    (.condicional, ["me arrepentiría", "te arrepentirías", "te arrepentirías", "se arrepentiría", "nos arrepentiríamos", "os arrepentiríais", "se arrepentirían"]),
    (.imperfectoDeSubjuntivo1, ["me arrepintiera", "te arrepintieras", "te arrepintieras", "se arrepintiera", "nos arrepintiéramos", "os arrepintierais", "se arrepintieran"]),
    (.imperfectoDeSubjuntivo2, ["me arrepintiese", "te arrepintieses", "te arrepintieses", "se arrepintiese", "nos arrepintiésemos", "os arrepintieseis", "se arrepintiesen"]),
    (.futuroDeSubjuntivo, ["me arrepintiere", "te arrepintieres", "te arrepintieres", "se arrepintiere", "nos arrepintiéremos", "os arrepintiereis", "se arrepintieren"]),
    (.perfectoDeIndicativo, ["me he arrepentido", "te has arrepentido", "te has arrepentido", "se ha arrepentido", "nos hemos arrepentido", "os habéis arrepentido", "se han arrepentido"]),
    (.pluscuamperfectoDeIndicativo, ["me había arrepentido", "te habías arrepentido", "te habías arrepentido", "se había arrepentido", "nos habíamos arrepentido", "os habíais arrepentido", "se habían arrepentido"]),
    (.futuroPerfectoDeSubjuntivo, ["me hubiere arrepentido", "te hubieres arrepentido", "te hubieres arrepentido", "se hubiere arrepentido", "nos hubiéremos arrepentido", "os hubiereis arrepentido", "se hubieren arrepentido"])
  ])
  func arrepentirseFiniteForms(tense: DisplayTense, expected: [String]) {
    #expect(Self.finitePersons.map { Self.written("arrepentir", tense, $0) } == expected)
  }

  @Test func arrepentirseSubjunctive() {
    #expect(Self.written("arrepentir", .presenteDeSubjuntivo, .firstSingular) == "me arrepienta")
    #expect(Self.written("arrepentir", .presenteDeSubjuntivo, .firstPlural) == "nos arrepintamos")
    #expect(Self.written("arrepentir", .presenteDeSubjuntivo, .secondPlural) == "os arrepintáis")
  }

  @Test func arrepentirseCommands() {
    let persons: [DisplayPersonNumber] = [.secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    #expect(persons.map { Self.written("arrepentir", .imperativoPositivo, $0) } == [
      "arrepiéntete", "arrepentite", "arrepiéntase", "arrepintámonos", "arrepentíos", "arrepiéntanse"
    ])
    #expect(persons.map { Self.written("arrepentir", .imperativoNegativo, $0) } == [
      "no te arrepientas", Self.bare("arrepentir", .imperativoNegativo, .secondSingularVos).map { "no te " + $0.dropFirst(3) },
      "no se arrepienta", "no nos arrepintamos", "no os arrepintáis", "no se arrepientan"
    ])
    // Yo has no command, with or without a pronoun.
    #expect(Self.written("arrepentir", .imperativoPositivo, .firstSingular) == nil)
  }

  @Test func arrepentirseNonFiniteForms() {
    #expect(Self.written("arrepentir", .gerundio, .none) == "arrepintiéndose")
    #expect(Self.written("arrepentir", .participio, .none) == "arrepentido")
    #expect(Self.written("arrepentir", .raízFutura, .none) == "arrepentir")
    #expect(ReflexivePronoun.citationForm(of: "arrepentir") == "arrepentirse")
  }

  @Test("enclitic accents in -ar, -er, and irregular verbs", arguments: [
    ("quejar", ["quéjate", "quejate", "quéjese", "quejémonos", "quejaos", "quéjense"], "quejándose"),
    ("atrever", ["atrévete", "atrevete", "atrévase", "atrevámonos", "atreveos", "atrévanse"], "atreviéndose"),
    ("abstener", ["abstente", "abstenete", "absténgase", "abstengámonos", "absteneos", "absténganse"], "absteniéndose"),
    ("dignar", ["dígnate", "dignate", "dígnese", "dignémonos", "dignaos", "dígnense"], "dignándose")
  ])
  func encliticAccents(infinitive: String, commands: [String], gerund: String) {
    let persons: [DisplayPersonNumber] = [.secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    #expect(persons.map { Self.written(infinitive, .imperativoPositivo, $0) } == commands)
    #expect(Self.written(infinitive, .gerundio, .none) == gerund)
  }

  /// A golden table of joined forms, whose accents the sweep below cannot see, since it compares
  /// through `SpellingComparison.fold`. One verb of each shape: -ear, both kinds of -iar, -uir, a ue and an
  /// ie diphthong, ü, qu, gu, e to i, a hiatus in -eír, and one-syllable commands. A reflexive-only
  /// verb is read as its page writes it; any other has its bare forms joined by `attach`, as a
  /// learner would write the reflexive.
  @Test("joined forms carry the accent Spanish writes", arguments: [
    ("contonear", ["contonéate", "contoneate", "contonéese", "contoneémonos", "contoneaos", "contonéense"], "contoneándose"),
    ("vanagloriar", ["vanaglóriate", "vanagloriate", "vanaglóriese", "vanagloriémonos", "vanagloriaos", "vanaglóriense"], "vanagloriándose"),
    ("enviar", ["envíate", "enviate", "envíese", "enviémonos", "enviaos", "envíense"], "enviándose"),
    ("huir", ["húyete", "huite", "húyase", "huyámonos", "huíos", "húyanse"], "huyéndose"),
    ("condoler", ["conduélete", "condolete", "conduélase", "condolámonos", "condoleos", "conduélanse"], "condoliéndose"),
    ("desentender", ["desentiéndete", "desentendete", "desentiéndase", "desentendámonos", "desentendeos", "desentiéndanse"], "desentendiéndose"),
    ("desvergonzar", ["desvergüénzate", "desvergonzate", "desvergüéncese", "desvergoncémonos", "desvergonzaos", "desvergüéncense"], "desvergonzándose"),
    ("acurrucar", ["acurrúcate", "acurrucate", "acurrúquese", "acurruquémonos", "acurrucaos", "acurrúquense"], "acurrucándose"),
    ("endomingar", ["endomíngate", "endomingate", "endomínguese", "endominguémonos", "endomingaos", "endomínguense"], "endomingándose"),
    ("comedir", ["comídete", "comedite", "comídase", "comidámonos", "comedíos", "comídanse"], "comidiéndose"),
    ("reír", ["ríete", "reíte", "ríase", "riámonos", "reíos", "ríanse"], "riéndose"),
    ("poner", ["ponte", "ponete", "póngase", "pongámonos", "poneos", "pónganse"], "poniéndose"),
    ("hacer", ["hazte", "hacete", "hágase", "hagámonos", "haceos", "háganse"], "haciéndose"),
    ("dar", ["date", "date", "dese", "démonos", "daos", "dense"], "dándose")
  ])
  func joinedForms(infinitive: String, commands: [String], gerund: String) {
    let persons: [DisplayPersonNumber] = [.secondSingularTú, .secondSingularVos, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
    func joined(_ tense: DisplayTense, _ person: DisplayPersonNumber) -> String? {
      if ReflexivePronoun.isReflexiveOnly(infinitive) {
        return Self.written(infinitive, tense, person)
      }
      return Self.bare(infinitive, tense, person).map {
        ReflexivePronoun.attach(to: $0, tense: tense, personNumber: person)
      }
    }
    #expect(persons.map { joined(.imperativoPositivo, $0) } == commands)
    #expect(joined(.gerundio, .none) == gerund)
  }

  /// The written form is the bare form with the pronoun placed: before it, after the "no" of a
  /// negative command, or joined to a command or gerund. Accents aside, nothing else changes.
  @Test("every reflexive-only verb places its pronoun in every slot", arguments: reflexiveVerbs)
  func everySlot(infinitive: String) {
    for tense in DisplayTense.conjugatedTenses {
      for person in Self.finitePersons {
        let written = Self.written(infinitive, tense, person)
        let bare = Self.bare(infinitive, tense, person)
        #expect((written == nil) == (bare == nil), "\(infinitive) \(tense) \(person)")
        guard let written, let bare, let pronoun = ReflexivePronoun.pronoun(for: person) else {
          continue
        }
        switch tense {
        case .imperativoPositivo:
          let dropped = person == .firstPlural || person == .secondPlural ? String(bare.dropLast()) : bare
          #expect(SpellingComparison.fold(written) == SpellingComparison.fold(dropped + pronoun), "\(infinitive) \(tense) \(person)")
        case .imperativoNegativo:
          #expect(written == "no \(pronoun) " + bare.dropFirst(3), "\(infinitive) \(tense) \(person)")
        default:
          #expect(written == "\(pronoun) \(bare)", "\(infinitive) \(tense) \(person)")
        }
      }
    }
    #expect(SpellingComparison.fold(Self.written(infinitive, .gerundio, .none) ?? "") == SpellingComparison.fold((Self.bare(infinitive, .gerundio, .none) ?? "") + "se"))
    #expect(Self.written(infinitive, .participio, .none) == Self.bare(infinitive, .participio, .none))
  }

  /// A joined command or gerund has exactly one written accent, on the syllable the bare form
  /// stressed, since every one of them now stresses its third syllable from the end or earlier,
  /// or (vos, vosotros) keeps a final stress the pronoun makes regular or marks as a hiatus.
  @Test("every joined form has at most one written accent", arguments: reflexiveVerbs)
  func oneAccent(infinitive: String) {
    let joined = [Self.written(infinitive, .gerundio, .none)]
      + Self.finitePersons.map { Self.written(infinitive, .imperativoPositivo, $0) }
    for form in joined.compactMap({ $0 }) {
      #expect(form.filter { "áéíóú".contains($0) }.count <= 1, "\(form)")
    }
  }

  @Test func otherVerbsAreUnchanged() {
    #expect(Self.written("hablar", .presenteDeIndicativo, .firstSingular) == "hablo")
    #expect(Self.written("levantar", .imperativoPositivo, .secondSingularTú) == "levanta")
    #expect(ReflexivePronoun.citationForm(of: "levantar") == "levantar")
  }

  @Test func theEngineDefaultStaysBare() {
    #expect(Self.bare("arrepentir", .presenteDeIndicativo, .firstSingular) == "arrepiento")
  }

  @Test func theMarkingSurvives() {
    let form = TenseBridge.conjugate(infinitive: "arrepentir", tense: .imperativoPositivo, personNumber: .secondSingularTú, pronoun: .written)
    #expect(form == .success("arrepIéntete"))
    let negative = TenseBridge.conjugate(infinitive: "arrepentir", tense: .imperativoNegativo, personNumber: .secondSingularTú, pronoun: .written)
    #expect(negative == .success("no te arrepIentas"))
  }

  @Test("enclisis follows the general accent rules", arguments: [
    ("me", "dé", 0, "deme"),
    ("te", "está", 0, "estate"),
    ("me", "di", 0, "dime"),
    ("te", "ríe", 0, "ríete"),
    ("se", "riendo", 0, "riéndose"),
    ("os", "reíd", 1, "reíos"),
    ("os", "levantad", 1, "levantaos"),
    ("nos", "vamos", 1, "vámonos"),
    ("me", "sigue", 0, "sígueme"),
    ("te", "quita", 0, "quítate"),
    ("se", "oyendo", 0, "oyéndose"),
    ("te", "pon", 0, "ponte"),
    ("te", "arrepIEnte", 0, "arrepIÉntete")
  ])
  func encliticRule(clitic: String, word: String, dropped: Int, expected: String) {
    #expect(ReflexivePronoun.enclitic(clitic, attachedTo: word, droppingLast: dropped) == expected)
  }

  @Test func bareInfinitiveFromCitation() {
    #expect(ReflexivePronoun.bareInfinitive(fromCitation: "arrepentirse") == "arrepentir")
    #expect(ReflexivePronoun.bareInfinitive(fromCitation: "reírse") == "reír")
    #expect(ReflexivePronoun.bareInfinitive(fromCitation: "base") == nil)
    #expect(ReflexivePronoun.bareInfinitive(fromCitation: "arrepentir") == nil)
  }

  @Test func searchFindsTheCitationFormAsItIsTyped() {
    let entries = VerbMap.shared.entries.values
    #expect(VerbSearch.matches(for: "arrepentirse", in: entries).first?.entry.infinitive == "arrepentir")
    #expect(VerbSearch.matches(for: "arrepentirs", in: entries).first?.entry.infinitive == "arrepentir")
    #expect(VerbSearch.matches(for: "arrepentir", in: entries).first?.entry.infinitive == "arrepentir")
  }

  @MainActor
  @Test func theQuizAcceptsTheFormWithAndWithoutItsPronoun() {
    func grade(_ answer: String, _ tense: DisplayTense = .presenteDeIndicativo, _ person: DisplayPersonNumber = .firstSingular) -> ConjugationResult {
      QuizQuestion("arrepentir", tense, person).grade(answer)
    }
    #expect(grade("me arrepiento") == .totalMatch)
    #expect(grade("arrepiento") == .totalMatch)
    #expect(grade("Me  arrepiento ") == .totalMatch)
    #expect(grade("te arrepiento") == .noMatch)
    #expect(grade("arrepientete", .imperativoPositivo, .secondSingularTú) == .noMatch)
    #expect(grade("arrepiéntete", .imperativoPositivo, .secondSingularTú) == .totalMatch)
    #expect(grade("arrepiente", .imperativoPositivo, .secondSingularTú) == .totalMatch)
  }

  @MainActor
  @Test func aVerbWithNoPronounHasOneAnswer() {
    let question = QuizQuestion("hablar", .presenteDeIndicativo, .firstSingular)
    #expect(question.grade("hablo") == .totalMatch)
    #expect(question.grade("me hablo") == .noMatch)
  }
}
