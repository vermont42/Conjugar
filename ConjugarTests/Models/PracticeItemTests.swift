//
//  PracticeItemTests.swift
//  ConjugarTests
//
//  Which item each question exercises, the items' permanent keys, and which key conjugations a
//  lookup schedules and a review asks.
//

import Testing
@testable import Conjugar

struct PracticeItemTests {
  private func item(_ verb: String, _ tense: DisplayTense, _ personNumber: DisplayPersonNumber) -> PracticeItem? {
    PracticeItem.exercised(by: verb, tense: tense, personNumber: personNumber)
  }

  private func key(_ verb: String, _ key: PracticeItem.Key) -> PracticeItem {
    .keyConjugation(infinitive: verb, key: key)
  }

  @Test func keysArePinned() {
    #expect(key("tener", .yoPresente).key == "key:tener:yo_presente")
    #expect(key("tener", .yoPretérito).key == "key:tener:yo_preterito")
    #expect(key("tener", .yoFuturo).key == "key:tener:yo_futuro")
    #expect(key("escribir", .participio).key == "key:escribir:participio")
    #expect(item("comer", .imperfectoDeIndicativo, .firstSingular)?.key == "pattern:imperfecto_de_indicativo:fs:er")
    #expect(item("hablar", .imperativoNegativo, .secondSingularVos)?.key == "pattern:imperativo_negativo:sv:ar")
    #expect(item("vivir", .gerundio, .none)?.key == "pattern:gerundio:ir")
    #expect(item("hablar", .participio, .none)?.key == "pattern:participio:ar")
  }

  @Test(arguments: [
    "key:tener:yo_presente",
    "key:arrepentir:participio",
    "pattern:imperfecto_de_indicativo:fs:er",
    "pattern:gerundio:ir",
    "pattern:participio:ar",
    "pattern:futuro_perfecto_de_subjuntivo:tp:ar"
  ])
  func keysRoundTrip(key: String) throws {
    let item = try #require(PracticeItem(key: key))
    #expect(item.key == key)
  }

  @Test(arguments: [
    "",
    "key:tener",
    "key::yo_presente",
    "key:tener:yo_imperfecto",
    "key:tener:yo_presente:extra",
    "pattern:preterito:fs",
    "pattern:preterito:fs:ur",
    "pattern::fs:ar",
    "pattern:a:b:c:ar",
    "other:tener:yo_presente"
  ])
  func unreadableKeysAreNil(key: String) {
    #expect(PracticeItem(key: key) == nil)
  }

  @Test func aPatternNamesItsCellAndEnding() throws {
    let pattern = try #require(item("comer", .imperfectoDeIndicativo, .secondPlural))
    #expect(pattern.cell == ConjugationCell(tense: .imperfectoDeIndicativo, personNumber: .secondPlural))
    #expect(pattern.ending == .er)
    #expect(pattern.infinitive == nil)
    let gerundio = try #require(item("vivir", .gerundio, .none))
    #expect(gerundio.cell == ConjugationCell(tense: .gerundio, personNumber: .none))
    #expect(PracticeItem.pattern(tenseKey: "nada", person: "fs", ending: "ar").cell == nil)
    #expect(PracticeItem.pattern(tenseKey: "preterito", person: "xx", ending: "ar").cell == nil)
  }

  /// Every cell a level asks, in each tense family, of a verb irregular there.
  @Test(arguments: [
    // The yo presente's stem, and the cells nearest it.
    ("tener", DisplayTense.presenteDeIndicativo, DisplayPersonNumber.firstSingular, PracticeItem.Key.yoPresente),
    ("tener", .presenteDeIndicativo, .secondSingularTú, .yoPresente),
    ("dormir", .presenteDeIndicativo, .thirdSingular, .yoPresente),
    ("tener", .presenteDeSubjuntivo, .firstPlural, .yoPresente),
    ("tener", .imperativoPositivo, .secondSingularTú, .yoPresente),
    ("hacer", .imperativoPositivo, .thirdSingular, .yoPresente),
    ("decir", .imperativoNegativo, .thirdPlural, .yoPresente),
    ("ser", .imperfectoDeIndicativo, .firstSingular, .yoPresente),
    ("ir", .imperfectoDeIndicativo, .thirdPlural, .yoPresente),
    // The yo pretérito's stem, and the gerundio, built on the third person's.
    ("tener", .pretérito, .firstSingular, .yoPretérito),
    ("pedir", .pretérito, .thirdSingular, .yoPretérito),
    ("tener", .imperfectoDeSubjuntivo1, .thirdSingular, .yoPretérito),
    ("tener", .imperfectoDeSubjuntivo2, .firstSingular, .yoPretérito),
    ("tener", .futuroDeSubjuntivo, .firstSingular, .yoPretérito),
    ("dormir", .gerundio, .none, .yoPretérito),
    // The yo futuro's.
    ("tener", .futuroDeIndicativo, .firstSingular, .yoFuturo),
    ("hacer", .condicional, .thirdPlural, .yoFuturo),
    // The participle's, which every compound tense is built on.
    ("escribir", .participio, .none, .participio),
    ("escribir", .perfectoDeIndicativo, .firstSingular, .participio),
    ("hacer", .pluscuamperfectoDeSubjuntivo2, .thirdSingular, .participio),
    // A spelling change is an item of its verb.
    ("buscar", .pretérito, .firstSingular, .yoPretérito),
    ("llegar", .presenteDeSubjuntivo, .firstSingular, .yoPresente),
    ("coger", .presenteDeIndicativo, .firstSingular, .yoPresente)
  ])
  func anIrregularCellExercisesTheKeyConjugationItIsBuiltOn(
    verb: String,
    tense: DisplayTense,
    personNumber: DisplayPersonNumber,
    expected: PracticeItem.Key
  ) {
    #expect(item(verb, tense, personNumber) == key(verb, expected))
  }

  @Test(arguments: [
    // An irregular verb's regular cells share their ending's pattern.
    ("tener", DisplayTense.imperfectoDeIndicativo, DisplayPersonNumber.firstSingular, "pattern:imperfecto_de_indicativo:fs:er"),
    ("tener", .presenteDeIndicativo, .firstPlural, "pattern:presente_de_indicativo:fp:er"),
    ("tener", .presenteDeIndicativo, .secondSingularVos, "pattern:presente_de_indicativo:sv:er"),
    ("tener", .perfectoDeIndicativo, .firstSingular, "pattern:perfecto_de_indicativo:fs:er"),
    ("pedir", .pretérito, .firstSingular, "pattern:preterito:fs:ir"),
    ("hablar", .imperfectoDeIndicativo, .firstSingular, "pattern:imperfecto_de_indicativo:fs:ar"),
    ("comer", .imperfectoDeIndicativo, .firstSingular, "pattern:imperfecto_de_indicativo:fs:er"),
    ("vivir", .futuroDeIndicativo, .thirdPlural, "pattern:futuro_de_indicativo:tp:ir"),
    ("hablar", .imperativoNegativo, .secondSingularTú, "pattern:imperativo_negativo:ss:ar"),
    // A defective verb's cells, where the engine gives them.
    ("abolir", .presenteDeIndicativo, .firstPlural, "pattern:presente_de_indicativo:fp:ir")
  ])
  func aRegularCellExercisesItsPattern(verb: String, tense: DisplayTense, personNumber: DisplayPersonNumber, expected: String) {
    #expect(item(verb, tense, personNumber)?.key == expected)
  }

  @Test func prefixedAndReflexiveOnlyVerbsHaveTheirOwnItems() {
    #expect(item("mantener", .presenteDeIndicativo, .firstSingular) == key("mantener", .yoPresente))
    #expect(item("arrepentir", .presenteDeIndicativo, .firstSingular) == key("arrepentir", .yoPresente))
    #expect(item("tener", .presenteDeIndicativo, .firstSingular) != item("mantener", .presenteDeIndicativo, .firstSingular))
  }

  @Test func aCellTheEngineDoesNotGiveExercisesNothing() {
    #expect(item("abolir", .presenteDeIndicativo, .firstSingular) == nil)
    #expect(item("noesverbo", .presenteDeIndicativo, .firstSingular) == nil)
  }

  @Test func aLookupSchedulesTheKeyConjugationsThatSomeIrregularCellIsBuiltOn() {
    // tenido is regular, so tener's participle has nothing to schedule.
    #expect(PracticeItem.keyConjugations(of: "tener") == [key("tener", .yoPresente), key("tener", .yoPretérito), key("tener", .yoFuturo)])
    #expect(PracticeItem.keyConjugations(of: "pensar") == [key("pensar", .yoPresente)])
    #expect(PracticeItem.keyConjugations(of: "pedir") == [key("pedir", .yoPresente), key("pedir", .yoPretérito)])
    #expect(PracticeItem.keyConjugations(of: "escribir") == [key("escribir", .participio)])
    #expect(PracticeItem.keyConjugations(of: "buscar").contains(key("buscar", .yoPretérito)))
    #expect(PracticeItem.keyConjugations(of: "hablar").isEmpty)
    #expect(PracticeItem.keyConjugations(of: "noesverbo").isEmpty)
  }

  @Test func aReviewAsksAnIrregularCellBuiltOnTheKeyConjugation() {
    #expect(Array(PracticeItem.irregularCells(of: "tener", builtOn: .yoPresente)).first == ConjugationCell(tense: .presenteDeIndicativo, personNumber: .firstSingular))
    // pedí is regular, so pedir's yo pretérito is reviewed as pidió.
    #expect(Array(PracticeItem.irregularCells(of: "pedir", builtOn: .yoPretérito)).first == ConjugationCell(tense: .pretérito, personNumber: .thirdSingular))
    #expect(Array(PracticeItem.irregularCells(of: "escribir", builtOn: .participio)).first == ConjugationCell(tense: .participio, personNumber: .none))
    #expect(Array(PracticeItem.irregularCells(of: "hablar", builtOn: .yoPresente)).isEmpty)
  }

  /// One verb of each kind the mapping must handle, and each frequent irregular verb: every cell
  /// that exercises a key conjugation is one a review of that key conjugation can ask, so a review
  /// always moves the item it was for, and the lookup schedules it.
  @Test(arguments: [
    "tener", "ser", "ir", "haber", "estar", "hacer", "decir", "poder", "poner", "venir", "dar", "ver", "saber",
    "querer", "salir", "pedir", "dormir", "pensar", "jugar", "buscar", "llegar", "coger", "seguir", "leer",
    "oír", "reír", "escribir", "romper", "mantener", "conducir", "conocer", "arrepentir", "abolir", "huir"
  ])
  func everyIrregularCellIsOneItsKeyConjugationsReviewCanAsk(verb: String) {
    let scheduled = PracticeItem.keyConjugations(of: verb)
    for key in PracticeItem.Key.allCases {
      for cell in key.cells {
        guard case let .keyConjugation(_, exercised)? = item(verb, cell.tense, cell.personNumber) else {
          continue
        }
        #expect(exercised == key, "\(verb) \(cell.code)")
        #expect(PracticeItem.irregularCells(of: verb, builtOn: key).contains(cell), "\(verb) \(cell.code)")
        #expect(scheduled.contains(self.key(verb, key)), "\(verb) \(cell.code)")
      }
    }
  }

  /// Every cell the quiz can ask belongs to exactly one key conjugation's family.
  @Test func everyAskedCellHasOneKeyConjugation() {
    let cells = PracticeItem.Key.allCases.flatMap(\.cells)
    #expect(Set(cells).count == cells.count)
    for tense in CustomQuiz.choosableTenses + [.participio] {
      #expect(PracticeItem.Key(tense: tense) != nil, "\(tense)")
      #expect(cells.contains { $0.tense == tense }, "\(tense)")
    }
  }

  @Test func everyAskedTensesKeyRoundTrips() {
    for tense in CustomQuiz.choosableTenses + [.participio] {
      let key = PracticeItem.tenseKey(for: tense)
      #expect(key.flatMap(PracticeItem.tense(forKey:)) == tense, "\(tense)")
    }
    #expect(PracticeItem.tenseKey(for: .infinitivo) == nil)
  }

  @Test func onlyIrregularVerbsAreReviewable() {
    #expect(PracticeItem.isReviewable("ir"))
    #expect(PracticeItem.isReviewable("tener"))
    #expect(PracticeItem.isReviewable("buscar"))
    #expect(PracticeItem.isReviewable("arrepentir"))
    #expect(!PracticeItem.isReviewable("hablar"))
    #expect(!PracticeItem.isReviewable("comer"))
    #expect(!PracticeItem.isReviewable("vivir"))
    #expect(!PracticeItem.isReviewable("noesverbo"))
  }
}
