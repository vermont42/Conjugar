//
//  QuizGradingTests.swift
//  ConjugarTests
//
//  Copyright © 2026 Josh Adams. All rights reserved.
//
//  What the quiz accepts as right: spacing and case, a leading subject pronoun, and the standard
//  variants of a cell.
//

import Foundation
import Testing
@testable import Conjugar

@Suite struct QuizGradingTests {
  private func grade(
    _ answer: String,
    _ verb: String,
    _ tense: DisplayTense,
    _ person: DisplayPersonNumber = .none
  ) -> ConjugationResult {
    QuizQuestion(verb, tense, person).grade(answer)
  }

  @Test func spacingAndCaseDoNotCount() {
    #expect(grade("  hablo ", "hablar", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("Hablo", "hablar", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("he   hablado", "hablar", .perfectoDeIndicativo, .firstSingular) == .totalMatch)
  }

  @Test func aLeadingPronounOfTheAskedPersonIsIgnored() {
    #expect(grade("yo hablo", "hablar", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("tú hablas", "hablar", .presenteDeIndicativo, .secondSingularTú) == .totalMatch)
    #expect(grade("tu hablas", "hablar", .presenteDeIndicativo, .secondSingularTú) == .totalMatch)
    #expect(grade("vos hablás", "hablar", .presenteDeIndicativo, .secondSingularVos) == .totalMatch)
    for pronoun in ["él", "el", "ella", "usted"] {
      #expect(grade("\(pronoun) habla", "hablar", .presenteDeIndicativo, .thirdSingular) == .totalMatch)
    }
    #expect(grade("nosotras hablamos", "hablar", .presenteDeIndicativo, .firstPlural) == .totalMatch)
    #expect(grade("vosotros habláis", "hablar", .presenteDeIndicativo, .secondPlural) == .totalMatch)
    for pronoun in ["ellos", "ellas", "ustedes"] {
      #expect(grade("\(pronoun) hablan", "hablar", .presenteDeIndicativo, .thirdPlural) == .totalMatch)
    }
    #expect(grade("yo he hablado", "hablar", .perfectoDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("yo me arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == .totalMatch)
    #expect(grade("yo arrepiento", "arrepentir", .presenteDeIndicativo, .firstSingular) == .totalMatch)
  }

  @Test func anotherPersonsPronounIsNotIgnored() {
    #expect(grade("tú hablo", "hablar", .presenteDeIndicativo, .firstSingular) == .noMatch)
    #expect(grade("yo habla", "hablar", .presenteDeIndicativo, .thirdSingular) == .noMatch)
    #expect(grade("yohablo", "hablar", .presenteDeIndicativo, .firstSingular) == .noMatch)
  }

  @Test func aCommandTakesNoPronoun() {
    #expect(grade("habla", "hablar", .imperativoPositivo, .secondSingularTú) == .totalMatch)
    #expect(grade("tú habla", "hablar", .imperativoPositivo, .secondSingularTú) == .noMatch)
    #expect(grade("no hables", "hablar", .imperativoNegativo, .secondSingularTú) == .totalMatch)
    #expect(grade("hablando", "hablar", .gerundio) == .totalMatch)
  }

  /// A missing accent is still not right. The second attempt that makes it a near miss is a
  /// later change; until then it keeps its half credit.
  @Test func aMissingAccentIsStillNotRight() {
    #expect(grade("hable", "hablar", .pretérito, .firstSingular) == .partialMatch)
    #expect(grade("yo hable", "hablar", .pretérito, .firstSingular) == .partialMatch)
    #expect(grade("tenes", "tener", .presenteDeIndicativo, .secondSingularVos) == .partialMatch)
    #expect(grade("bano", "bañar", .presenteDeIndicativo, .firstSingular) == .noMatch)
  }

  @Test func theTwoImperfectSubjunctivesDoNotStandInForEachOther() {
    #expect(grade("hablase", "hablar", .imperfectoDeSubjuntivo1, .firstSingular) == .noMatch)
    #expect(grade("hablara", "hablar", .imperfectoDeSubjuntivo2, .firstSingular) == .noMatch)
  }

  @Test(arguments: [
    // The spelling the 2010 Ortografía retired, beside the engine's current one.
    ("rió", "reír", DisplayTense.pretérito, DisplayPersonNumber.thirdSingular),
    ("rio", "reír", .pretérito, .thirdSingular),
    ("guié", "guiar", .pretérito, .firstSingular),
    ("hui", "huir", .pretérito, .firstSingular),
    ("huí", "huir", .pretérito, .firstSingular),
    ("fiás", "fiar", .presenteDeIndicativo, .secondSingularVos),
    ("fias", "fiar", .presenteDeIndicativo, .secondSingularVos),
    ("riáis", "reír", .presenteDeSubjuntivo, .secondPlural),
    ("no riáis", "reír", .imperativoNegativo, .secondPlural),
    ("ve", "ver", .imperativoPositivo, .secondSingularVos),
    // Participle doublets, alone and in compound tenses.
    ("frito", "freír", .participio, .none),
    ("freído", "freír", .participio, .none),
    ("he frito", "freír", .perfectoDeIndicativo, .firstSingular),
    ("sofrito", "sofreír", .participio, .none),
    ("provisto", "proveer", .participio, .none),
    ("habían desprovisto", "desproveer", .pluscuamperfectoDeIndicativo, .thirdPlural),
    ("imprimido", "imprimir", .participio, .none),
    ("reimprimido", "reimprimir", .participio, .none),
    ("inscripto", "inscribir", .participio, .none),
    ("hemos transcripto", "transcribir", .perfectoDeIndicativo, .firstPlural),
    // Other doublets.
    ("satisface", "satisfacer", .imperativoPositivo, .secondSingularTú),
    ("satisfaz", "satisfacer", .imperativoPositivo, .secondSingularTú),
    ("predeciré", "predecir", .futuroDeIndicativo, .firstSingular),
    ("prediré", "predecir", .futuroDeIndicativo, .firstSingular),
    ("contradeciría", "contradecir", .condicional, .thirdSingular),
    ("desdecirás", "desdecir", .futuroDeIndicativo, .secondSingularTú),
    ("adecúo", "adecuar", .presenteDeIndicativo, .firstSingular),
    ("adecuo", "adecuar", .presenteDeIndicativo, .firstSingular),
    ("evacúe", "evacuar", .presenteDeSubjuntivo, .thirdSingular),
    ("licúan", "licuar", .presenteDeIndicativo, .thirdPlural),
    ("agrio", "agriar", .presenteDeIndicativo, .firstSingular),
    ("expatria", "expatriar", .presenteDeIndicativo, .thirdSingular),
    ("repatrien", "repatriar", .presenteDeSubjuntivo, .thirdPlural),
    ("palío", "paliar", .presenteDeIndicativo, .firstSingular),
    ("historía", "historiar", .presenteDeIndicativo, .thirdSingular),
    ("vidrían", "vidriar", .presenteDeIndicativo, .thirdPlural),
    // Forms the engine already models.
    ("irgo", "erguir", .presenteDeIndicativo, .firstSingular),
    ("yergo", "erguir", .presenteDeIndicativo, .firstSingular),
    ("yazgo", "yacer", .presenteDeIndicativo, .firstSingular),
    ("yago", "yacer", .presenteDeIndicativo, .firstSingular),
    ("rayo", "raer", .presenteDeIndicativo, .firstSingular),
    ("roigo", "roer", .presenteDeIndicativo, .firstSingular),
    ("royo", "roer", .presenteDeIndicativo, .firstSingular),
    ("plugo", "placer", .pretérito, .thirdSingular),
    // The Río de la Plata's vos subjunctive.
    ("hablés", "hablar", .presenteDeSubjuntivo, .secondSingularVos),
    ("hables", "hablar", .presenteDeSubjuntivo, .secondSingularVos),
    ("tengás", "tener", .presenteDeSubjuntivo, .secondSingularVos),
    ("des", "dar", .presenteDeSubjuntivo, .secondSingularVos),
    ("no hablés", "hablar", .imperativoNegativo, .secondSingularVos),
    ("hayás hablado", "hablar", .perfectoDeSubjuntivo, .secondSingularVos)
  ])
  func aStandardVariantIsRight(answer: String, verb: String, tense: DisplayTense, person: DisplayPersonNumber) {
    #expect(grade(answer, verb, tense, person) == .totalMatch, "\(answer) for \(verb), \(tense.rawValue) \(person.rawValue)")
  }

  @Test func aVariantStaysInItsOwnCell() {
    // The vos subjunctive is not tú's.
    #expect(grade("hablés", "hablar", .presenteDeSubjuntivo, .secondSingularTú) == .partialMatch)
    // satisface is a command only; the -deciré future belongs to predecir's family, not decir.
    #expect(grade("satisface", "satisfacer", .presenteDeIndicativo, .secondSingularTú) == .noMatch)
    #expect(grade("deciré", "decir", .futuroDeIndicativo, .firstSingular) == .noMatch)
    #expect(grade("bendiré", "bendecir", .futuroDeIndicativo, .firstSingular) == .noMatch)
    // A participle that is only an adjective is not a participle.
    #expect(grade("electo", "elegir", .participio) == .noMatch)
    #expect(grade("escripto", "escribir", .participio) == .noMatch)
  }

  @Test func aRetiredSpellingIsShownTheCurrentOne() {
    let rio = QuizQuestion("reír", .pretérito, .thirdSingular)
    #expect(rio.currentSpelling(of: "rió")?.lowercased() == "rio")
    #expect(rio.currentSpelling(of: "él rió")?.lowercased() == "rio")
    #expect(rio.currentSpelling(of: "rio") == nil)
    #expect(rio.currentSpelling(of: "ríó") == nil)
    #expect(QuizQuestion("reír", .imperativoNegativo, .secondPlural).currentSpelling(of: "no riáis")?.lowercased() == "no riais")
    // A doublet is right in its own right, not a spelling of the other.
    #expect(QuizQuestion("freír", .participio, .none).currentSpelling(of: "frito") == nil)
    #expect(QuizQuestion("hablar", .presenteDeSubjuntivo, .secondSingularVos).currentSpelling(of: "hablés") == nil)
  }

  @Test func theVoseoSubjunctiveIsTheVosotrosFormWithoutItsI() {
    #expect(StandardVariants.voseoSubjunctive(fromVosotros: "habléis") == "hablés")
    #expect(StandardVariants.voseoSubjunctive(fromVosotros: "durmáis") == "durmás")
    #expect(StandardVariants.voseoSubjunctive(fromVosotros: "deis") == "des")
    #expect(StandardVariants.voseoSubjunctive(fromVosotros: "hablen") == nil)
  }
}

/// The engine writes the spelling of the 2010 *Ortografía*.
@Suite struct OrthographyTests {
  @Test(arguments: [
    ("rió", "rio"), ("guió", "guio"), ("guié", "guie"), ("crié", "crie"), ("fiáis", "fiais"),
    ("fiás", "fias"), ("fiá", "fia"), ("huí", "hui"), ("huís", "huis"), ("fluís", "fluis"),
    ("riáis", "riais"), ("no riáis", "no riais"), ("FIÓ", "FIO"), ("fIó", "fIo")
  ])
  func aMonosyllableLosesItsAccent(old: String, current: String) {
    #expect(Orthography.currentSpelling(of: old) == current)
  }

  @Test(arguments: ["reí", "ríe", "guíe", "fío", "dé", "sé", "sonrió", "refrió", "averigüé", "argüí", "creí", "huía", "habló", "no dé"])
  func anyOtherFormKeepsItsAccent(form: String) {
    #expect(Orthography.currentSpelling(of: form) == form)
  }

  @Test func theEngineSpellsAsTheOrtografíaDoes() {
    func form(_ verb: String, _ tense: EngineTense) -> String? {
      try? Conjugator.conjugate(infinitive: verb, tense: tense).get()
    }
    #expect(form("reír", .pretérito(.thirdSingular)) == "rio")
    #expect(form("guiar", .pretérito(.firstSingular)) == "guie")
    #expect(form("fiar", .presenteDeIndicativo(.secondSingularVos)) == "fias")
    #expect(form("huir", .imperativoAfirmativo(.secondSingularVos)) == "hui")
    #expect(form("ver", .imperativoAfirmativo(.secondSingularVos)) == "ve")
    #expect(form("prever", .imperativoAfirmativo(.secondSingularVos)) == "prevé")
    #expect(form("sonreír", .pretérito(.thirdSingular)) == "sonrió")
  }

  @Test func everyFormStillListsTheRetiredSpellingLast() {
    let forms = try? Conjugator.conjugateAll(infinitive: "reír", tense: .pretérito(.thirdSingular)).get()
    #expect(forms == ["rio", "rió"])
  }
}

/// Commands are asked of every person but yo, tú included.
@MainActor
@Suite struct QuizPersonRotationTests {
  private func commandPersons(difficulty: Difficulty, region: Region, quizzes: Int) -> [DisplayTense: [DisplayPersonNumber: Int]] {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [
      Settings.difficultyKey: difficulty.rawValue,
      Settings.regionKey: region.rawValue,
      Settings.secondSingularQuizKey: SecondSingularQuiz.tu.rawValue
    ]))
    let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: false)
    var counts: [DisplayTense: [DisplayPersonNumber: Int]] = [:]
    for _ in 0..<quizzes {
      quiz.start()
      for question in quiz.questions where question.tense == .imperativoNegativo
        || (question.tense == .imperativoPositivo && !VerbFamilies.irregularTuImperativoVerbs.contains(question.verb)) {
        counts[question.tense, default: [:]][question.personNumber, default: 0] += 1
      }
      quiz.quit()
    }
    return counts
  }

  @Test func tuCommandsAreAskedAsOftenAsTheOthers() {
    for region in [Region.spain, .latinAmerica] {
      let expectedPersons: Set<DisplayPersonNumber> = region == .spain
        ? [.secondSingularTú, .thirdSingular, .firstPlural, .secondPlural, .thirdPlural]
        : [.secondSingularTú, .thirdSingular, .firstPlural, .thirdPlural]
      let counts = commandPersons(difficulty: .moderate, region: region, quizzes: 60)
      for tense in [DisplayTense.imperativoPositivo, .imperativoNegativo] {
        let byPerson = counts[tense] ?? [:]
        #expect(Set(byPerson.keys) == expectedPersons, "\(tense.rawValue) in \(region.rawValue): \(byPerson)")
        let total = byPerson.values.reduce(0, +)
        let fairShare = Double(total) / Double(expectedPersons.count)
        let tuCount = Double(byPerson[.secondSingularTú] ?? 0)
        #expect(abs(tuCount - fairShare) <= fairShare * 0.5, "tú is \(tuCount) of \(total) \(tense.rawValue) in \(region.rawValue)")
      }
    }
  }

  @Test func theDifficultQuizAsksANegativeTuCommand() {
    let counts = commandPersons(difficulty: .difficult, region: .spain, quizzes: 30)
    #expect((counts[.imperativoNegativo]?[.secondSingularTú] ?? 0) > 0)
  }

  @Test func aScopedQuizAsksANegativeTuCommand() {
    let settings = Settings(getterSetter: GetterSetterFake(dictionary: [Settings.difficultyKey: Difficulty.moderate.rawValue]))
    let quiz = Quiz(settings: settings, gameCenter: GameCenterFake(), shouldShuffle: false)
    quiz.start(scope: .myVerbs(["hablar", "comer", "vivir", "tener", "poner", "decir", "hacer", "salir", "venir", "ir"]))
    #expect(quiz.questions.contains { $0.tense == .imperativoNegativo && $0.personNumber == .secondSingularTú })
    quiz.quit()
  }
}
