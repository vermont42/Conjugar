//
//  ModelCatalog2.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/13/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Phase 6A — the **model catalog**: the single source of truth mapping each book
// class number (`"1"`, `"1-1"`, `"4B-1"`, `"7A"`, `"31-1"`, …) to its
// `VerbModel2` (taxonomy §1: base + ordered features). Until now these ~95 models
// lived only as test `static let`s; promoting them here makes the catalog the
// thing the tests exercise and the lookup the Phase-6 resolver will consult
// (verb → class number → catalog model → conjugate).
//
// The builds are the **canonical, complete** Phase-5/5b versions, copied verbatim
// from the proven, oracle-verified exemplars — never the Phase-4 scaffold partials
// (tenerSpEnd, decirSpJend, …), which stay test-only.
//
// Four classes were never built as test exemplars and are assembled here against
// the oracle (taxonomy §5): **4B-1 trocar**, **4B-5 desosar**, **4B-6
// avergonzar**, and **10 oír**. Four more — the prefix-accent compounds **29-2
// satisfacer / 30-1 suponer / 31-1 obtener / 32-1 convenir** — need no distinct
// model: they are byte-identical to their parents (29 hacer / 30 poner / 31 tener
// / 32 venir) because `ApocopatedImperative2` already derives the accented
// imperative (satisfaz/supón/obtén/convén) and every other feature is
// prefix-invariant (§1 "ride for free"). Their class numbers alias the parent.
enum ModelCatalog2 {
  // MARK: - Lookup

  /// The `VerbModel2` for a book class number, or `nil` if the number is unknown.
  static func model(forClass classNumber: String) -> VerbModel2? {
    byClassNumber[classNumber]
  }

  /// Every class number the catalog resolves (the keys of the map). Used by the
  /// completeness test to assert Annex B's 106 numbers all resolve.
  static var classNumbers: Set<String> {
    Set(byClassNumber.keys)
  }

  // MARK: - Shared build helpers (mirrors the test exemplars' helpers)

  /// Build a `LiteralSlotOverride2` from `(slot, form)` pairs (the catch-all residue).
  private static func residue(_ pairs: [(Tense2, String)]) -> LiteralSlotOverride2 {
    LiteralSlotOverride2(overrides: pairs.map { (slot: $0.0, form: $0.1) })
  }

  /// A suppletive present-subjunctive stem (ser sea-, haber haya-, …): replace the
  /// whole stem in PS{all} only, leaving the (separately suppletive) PI 1s alone.
  private static func subjunctiveStem(_ whole: String) -> StemFeature2 {
    StemFeature2(operation: .replaceWhole(whole), slots: Slot2.isPresentSubjunctive)
  }

  /// `y-add` restricted to the §4.5 subj-from-1s slots (PI 1s + PS{all}) — the
  /// raer/roer **alternate** paradigm (rayo/raya, royo/roya).
  private static let yAddSubjunctive = StemFeature2(operation: .append("y"), slots: Slot2.isSubjFrom1s)

  // MARK: - Perfectly regular (1 / 2 / 3) and their orthographic sub-classes

  static let cantar = VerbModel2(base: .ar)
  static let comer = VerbModel2(base: .er)
  static let subir = VerbModel2(base: .ir)

  // 1-x: -ar orthographic (§4.1) and accent (§4.2)
  static let tocar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oCar])
  static let pagar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGar])
  static let averiguar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oGuar])
  static let cazar = VerbModel2(base: .ar, features: [StemFinalConsonant2.oZar])
  static let aislar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let aullar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
  static let descafeinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let rehusar = VerbModel2(base: .ar, features: [AccentStem2.aStemU])
  static let amohinar = VerbModel2(base: .ar, features: [AccentStem2.aStemI])
  static let ahincar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oCar])
  static let cabrahigar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oGar])
  static let enraizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar])
  static let europeizar = VerbModel2(base: .ar, features: [AccentStem2.aStemI, StemFinalConsonant2.oZar])
  static let actuar = VerbModel2(base: .ar, features: [AccentStem2.aU])
  static let enviar = VerbModel2(base: .ar, features: [AccentStem2.aI])

  // 2-x: -er orthographic
  static let vencer = VerbModel2(base: .er, features: [StemFinalConsonant2.oCz])
  static let coger = VerbModel2(base: .er, features: [StemFinalConsonant2.oGj])
  static let leer = VerbModel2(base: .er, features: [IYHiatus2.oYhiatus])
  static let empeller = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
  static let tañer = VerbModel2(base: .er, features: [AbsorbIAfterPalatal2.oLlñ])
  static let romper = VerbModel2(base: .er, features: [IrregularParticiple2("romp", "roto")])

  // 3-x: -ir orthographic
  static let fruncir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oCz])
  static let dirigir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGj])
  static let distinguir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oGug])
  static let delinquir = VerbModel2(base: .ir, features: [StemFinalConsonant2.oQuc])
  static let bullir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])
  static let bruñir = VerbModel2(base: .ir, features: [AbsorbIAfterPalatal2.oLlñ])
  static let reunir = VerbModel2(base: .ir, features: [AccentStem2.aStemU])
  static let prohibir = VerbModel2(base: .ir, features: [AccentStem2.aStemI])
  static let abrir = VerbModel2(base: .ir, features: [IrregularParticiple2("abr", "abierto")])
  static let cubrir = VerbModel2(base: .ir, features: [IrregularParticiple2("cubr", "cubierto")])
  static let escribir = VerbModel2(base: .ir, features: [IrregularParticiple2("scrib", "scrito")])
  static let imprimir = VerbModel2(base: .ir, features: [IrregularParticiple2("imprim", "impreso", alternate: "imprimido")])
  static let pudrir = VerbModel2(base: .ir, features: [IrregularParticiple2("pudr", "podrido")])
  static let abolir = VerbModel2(base: .ir, features: [DefectiveFeature2.abolir])

  // MARK: - Diphthongs (§4.3): 4A / 4B / 5A / 5B

  static let pensar = VerbModel2(base: .ar, features: [StemVowel2.dIe])
  static let negar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oGar])
  static let empezar = VerbModel2(base: .ar, features: [StemVowel2.dIe, StemFinalConsonant2.oZar])
  static let errar = VerbModel2(base: .ar, features: [StemVowel2.dIeYe])

  static let mostrar = VerbModel2(base: .ar, features: [StemVowel2.dUe])
  // 4B-1 trocar = mostrar (d-ue) + o-car (c→qu): trueco/trueque/troqué.
  static let trocar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oCar])
  static let colgar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oGar])
  static let forzar = VerbModel2(base: .ar, features: [StemVowel2.dUe, StemFinalConsonant2.oZar])
  static let agorar = VerbModel2(base: .ar, features: [StemVowel2.dUeGue])
  // 4B-5 desosar = d-ue-hue on an -ar base (deshueso); oler is the -er cousin (5B-2).
  static let desosar = VerbModel2(base: .ar, features: [StemVowel2.dUeHue])
  // 4B-6 avergonzar = d-ue-gue (GO→GÜE) + o-zar (Z→C): avergüenzo / avergüence / avergoncé.
  static let avergonzar = VerbModel2(base: .ar, features: [StemVowel2.dUeGue, StemFinalConsonant2.oZar])

  static let perder = VerbModel2(base: .er, features: [StemVowel2.dIe])
  static let mover = VerbModel2(base: .er, features: [StemVowel2.dUe])
  static let cocer = VerbModel2(base: .er, features: [StemVowel2.dUe, StemFinalConsonant2.oCz])
  static let oler = VerbModel2(base: .er, features: [StemVowel2.dUeHue])
  static let resolver = VerbModel2(base: .er, features: [StemVowel2.dUe, IrregularParticiple2("solv", "suelto")])
  static let volver = VerbModel2(base: .er, features: [StemVowel2.dUe, IrregularParticiple2("volv", "vuelto")])

  // MARK: - Diphthongs and/or umlauts (§4.3/§4.4): 6A / 6B / 6C

  static let sentir = VerbModel2(base: .ir, features: [StemVowel2.dIe, StemVowel2.rEiWk])
  // 6A-1 erguir = two co-equal paradigms (ye / raise) in the stressed slots.
  static let erguir = VerbModel2(base: .ir,
    features: [StemVowel2.dIeYe, StemVowel2.rEiWk, StemFinalConsonant2.oGug],
    alternates: [[StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGug]])

  static let pedir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk])
  static let elegir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGj])
  static let seguir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, StemFinalConsonant2.oGug])
  static let ceñir = VerbModel2(base: .ir, features: [StemVowel2.rEiStr, StemVowel2.rEiWk, AbsorbIAfterPalatal2.oLlñ])
  // 6B-4 reír = subir + r-ei-str + r-ei-wk + collapse-ii + the hiatus-accent residue.
  static let reir = VerbModel2(base: .ir, features: [
    StemVowel2.rEiStr, StemVowel2.rEiWk,
    CollapseDoubleI2.collapse,
    residue([
      (.presenteDeIndicativo(.firstSingular), "río"), (.presenteDeIndicativo(.secondSingular), "ríes"),
      (.presenteDeIndicativo(.thirdSingular), "ríe"), (.presenteDeIndicativo(.firstPlural), "reímos"),
      (.presenteDeIndicativo(.thirdPlural), "ríen"),
      (.pretérito(.secondSingular), "reíste"), (.pretérito(.firstPlural), "reímos"),
      (.pretérito(.secondPlural), "reísteis"),
      (.presenteDeSubjuntivo(.firstSingular), "ría"), (.presenteDeSubjuntivo(.secondSingular), "rías"),
      (.presenteDeSubjuntivo(.thirdSingular), "ría"), (.presenteDeSubjuntivo(.thirdPlural), "rían"),
      (.imperativoAfirmativo(.secondSingular), "ríe"), (.imperativoAfirmativo(.secondPlural), "reíd"),
      (.participioPasado, "reído"),
    ]),
  ])

  static let dormir = VerbModel2(base: .ir, features: [StemVowel2.dUe, StemVowel2.rOuWk])
  static let morir = VerbModel2(base: .ir, features: [StemVowel2.dUe, StemVowel2.rOuWk, IrregularParticiple2("mor", "muerto")])

  // MARK: - 1st-singular -zco (§4.5): 7A / 7B

  static let conocer = VerbModel2(base: .er, features: [StemFeature2.zc])
  // 7A-1 yacer = zc primary + c→zg (yazgo) and c→g (yago, with apocopated yaz) alternates.
  static let yacer = VerbModel2(base: .er,
    features: [StemFeature2.zc],
    alternates: [
      [StemFeature2(operation: .swapSuffix(from: "c", to: "zg"), slots: Slot2.isSubjFrom1s)],
      [StemFeature2(operation: .swapSuffix(from: "c", to: "g"), slots: Slot2.isSubjFrom1s),
       ApocopatedImperative2(finalSwap: ("c", "z"))],
    ])
  // 7A-2 placer = zc primary + a representative archaic alternate slice (plegue/plega/plugo).
  static let placer = VerbModel2(base: .er,
    features: [StemFeature2.zc],
    alternates: [
      [StemFeature2.zc, residue([(.presenteDeSubjuntivo(.thirdSingular), "plegue")])],
      [StemFeature2.zc, residue([
        (.presenteDeSubjuntivo(.thirdSingular), "plega"), (.pretérito(.thirdSingular), "plugo"),
      ])],
    ])
  static let lucir = VerbModel2(base: .ir, features: [StemFeature2.zc])

  // MARK: - "Add -y except before -i" (§4.5): 8 / 18

  static let construir = VerbModel2(base: .ir, features: [StemFeature2.yAdd, IYHiatus2.oYhiatus])
  // 18 argüir = construir + güy→guy (a single paradigm; the "alternate" is orthographic).
  static let arguir = VerbModel2(base: .ir, features: [
    StemFeature2.yAdd, IYHiatus2.oYhiatus, DiaeresisDropBeforeY2.güyGuy,
  ])

  // MARK: - Irregular 1st-singular -go (§4.5): 9 / 10 / 11 / 12 / 13

  static let caer = VerbModel2(base: .er, features: [StemFeature2.g1ig, IYHiatus2.oYhiatus])
  // 9-1 raer = caer-build primary + a y-add alternate stack (rayo/raya).
  static let raer = VerbModel2(base: .er,
    features: [StemFeature2.g1ig, IYHiatus2.oYhiatus],
    alternates: [[yAddSubjunctive, IYHiatus2.oYhiatus]])
  // 9-2 roer = THREE PI-1s/PS variants: regular roo (primary), g1-ig roigo, y-add royo.
  static let roer = VerbModel2(base: .er,
    features: [IYHiatus2.oYhiatus],
    alternates: [[StemFeature2.g1ig, IYHiatus2.oYhiatus], [yAddSubjunctive, IYHiatus2.oYhiatus]])

  // 10 oír = subir + y-add + g1-ig + o-yhiatus, plus the present-1p / imperative-2p
  // hiatus accents (oímos / oíd) as literal residue — the two -i--initial -ir
  // endings the o-yhiatus accent slots (preterite/PP only) don't reach. g1-ig is
  // listed AFTER y-add so it wins in the overlapping subj-from-1s slots: PI 1s
  // oigo (not *oyo) and PS{all} oiga… (not *oya…), while y-add keeps the glide in
  // PI{2s,3s,3p}/IMP-2s (oyes/oye/oyen/oye). (Taxonomy §5 lists an `a-stem`, but
  // oír's stem "o" has no i/u for it to accent — it would be inert — so it is
  // omitted to keep the irregularity score honest; the real accents are the
  // residue below.)
  static let oir = VerbModel2(base: .ir, features: [
    StemFeature2.yAdd,
    StemFeature2.g1ig,
    IYHiatus2.oYhiatus,
    residue([
      (.presenteDeIndicativo(.firstPlural), "oímos"),
      (.imperativoAfirmativo(.secondPlural), "oíd"),
    ]),
  ])

  static let salir = VerbModel2(base: .ir, features: [StemFeature2.g1g, FutureEndings2.fDr, ApocopatedImperative2()])
  static let valer = VerbModel2(base: .er, features: [StemFeature2.g1g, FutureEndings2.fDr])
  static let asir = VerbModel2(base: .ir, features: [StemFeature2.g1g])

  // MARK: - Mixed patterns: 14 / 15 / 16 / 17

  // 14 ver = comer + wp-i + residue (veo/vea-, veía-, monosyllable veis).
  static let ver = VerbModel2(base: .er, features: [
    StemFeature2(operation: .append("e"), slots: Slot2.isSubjFrom1s),  // veo, vea-
    StemFeature2(operation: .append("e"), slots: Slot2.isImperfect),   // veía-
    PreteriteEndings2.wpI,
    IrregularParticiple2("v", "visto"),
    residue([
      (.presenteDeIndicativo(.secondPlural), "veis"),
      (.presenteDeIndicativo(.secondSingularVos), "ves"),
    ]),
  ])
  // 14-1 prever = ver's stem rebuilds + monosyllable→polysyllable accent residue.
  static let prever = VerbModel2(base: .er, features: [
    StemFeature2(operation: .append("e"), slots: Slot2.isSubjFrom1s),
    StemFeature2(operation: .append("e"), slots: Slot2.isImperfect),
    PreteriteEndings2.wpI,
    IrregularParticiple2("v", "visto"),
    residue([
      (.presenteDeIndicativo(.secondSingular), "prevés"), (.presenteDeIndicativo(.thirdSingular), "prevé"),
      (.presenteDeIndicativo(.thirdPlural), "prevén"),
      (.pretérito(.firstSingular), "preví"), (.pretérito(.thirdSingular), "previó"),
    ]),
  ])
  static let discernir = VerbModel2(base: .ir, features: [StemVowel2.dIe])
  static let jugar = VerbModel2(base: .ar, features: [StemVowel2.dUUe, StemFinalConsonant2.oGar])
  static let adquirir = VerbModel2(base: .ir, features: [StemVowel2.dIIe])

  // MARK: - Fundamentally irregular: 19–35

  // 19 ser = comer + pret-fue + residue (suppletive PI/IM, PS sea-, IMP sé).
  static let ser = VerbModel2(base: .er, features: [
    SuppletivePreterite2.fue,
    subjunctiveStem("se"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "soy"), (.presenteDeIndicativo(.secondSingular), "eres"),
      (.presenteDeIndicativo(.thirdSingular), "es"), (.presenteDeIndicativo(.firstPlural), "somos"),
      (.presenteDeIndicativo(.secondPlural), "sois"), (.presenteDeIndicativo(.thirdPlural), "son"),
      (.presenteDeIndicativo(.secondSingularVos), "sos"),
      (.imperfectoDeIndicativo(.firstSingular), "era"), (.imperfectoDeIndicativo(.secondSingular), "eras"),
      (.imperfectoDeIndicativo(.thirdSingular), "era"), (.imperfectoDeIndicativo(.firstPlural), "éramos"),
      (.imperfectoDeIndicativo(.secondPlural), "erais"), (.imperfectoDeIndicativo(.thirdPlural), "eran"),
      (.imperativoAfirmativo(.secondSingular), "sé"),
    ]),
  ])

  // 20 estar = cantar + sp-end(estuv) + residue (estoy + the stress-shift accents).
  static let estar = VerbModel2(base: .ar, features: [
    StemFeature2.strongPreterite(from: "est", to: "estuv"), PreteriteEndings2.spEnd,
    residue([
      (.presenteDeIndicativo(.firstSingular), "estoy"), (.presenteDeIndicativo(.secondSingular), "estás"),
      (.presenteDeIndicativo(.thirdSingular), "está"), (.presenteDeIndicativo(.thirdPlural), "están"),
      (.presenteDeSubjuntivo(.firstSingular), "esté"), (.presenteDeSubjuntivo(.secondSingular), "estés"),
      (.presenteDeSubjuntivo(.thirdSingular), "esté"), (.presenteDeSubjuntivo(.thirdPlural), "estén"),
      (.imperativoAfirmativo(.secondSingular), "está"),
    ]),
  ])

  // 21 haber = comer + sp-end(hub) + f-drope + residue (he/has/ha…, PS haya-).
  static let haber = VerbModel2(base: .er, features: [
    StemFeature2.strongPreterite(from: "hab", to: "hub"), PreteriteEndings2.spEnd,
    FutureEndings2.fDrope,
    subjunctiveStem("hay"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "he"), (.presenteDeIndicativo(.secondSingular), "has"),
      (.presenteDeIndicativo(.thirdSingular), "ha"), (.presenteDeIndicativo(.firstPlural), "hemos"),
      (.presenteDeIndicativo(.thirdPlural), "han"),
      (.imperativoAfirmativo(.secondSingular), "he"),
    ]),
  ])

  // 22 saber = comer + sp-end(sup) + f-drope + residue (PI 1s sé, PS sep-).
  static let saber = VerbModel2(base: .er, features: [
    StemFeature2.strongPreterite(from: "sab", to: "sup"), PreteriteEndings2.spEnd,
    FutureEndings2.fDrope,
    subjunctiveStem("sep"),
    residue([(.presenteDeIndicativo(.firstSingular), "sé")]),
  ])

  // 23 caber = comer + sp-end(cup) + f-drope + residue (PI 1s quepo, PS quep-).
  static let caber = VerbModel2(base: .er, features: [
    StemFeature2.strongPreterite(from: "cab", to: "cup"), PreteriteEndings2.spEnd,
    FutureEndings2.fDrope,
    subjunctiveStem("quep"),
    residue([(.presenteDeIndicativo(.firstSingular), "quepo")]),
  ])

  // 24 ir = subir + pret-fue + residue (voy/vas…, IM iba-, PS vaya-, ve/vamos, yendo).
  static let ir = VerbModel2(base: .ir, features: [
    SuppletivePreterite2.fue,
    subjunctiveStem("vay"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "voy"), (.presenteDeIndicativo(.secondSingular), "vas"),
      (.presenteDeIndicativo(.thirdSingular), "va"), (.presenteDeIndicativo(.firstPlural), "vamos"),
      (.presenteDeIndicativo(.secondPlural), "vais"), (.presenteDeIndicativo(.thirdPlural), "van"),
      (.imperfectoDeIndicativo(.firstSingular), "iba"), (.imperfectoDeIndicativo(.secondSingular), "ibas"),
      (.imperfectoDeIndicativo(.thirdSingular), "iba"), (.imperfectoDeIndicativo(.firstPlural), "íbamos"),
      (.imperfectoDeIndicativo(.secondPlural), "ibais"), (.imperfectoDeIndicativo(.thirdPlural), "iban"),
      (.gerundio, "yendo"),
      (.imperativoAfirmativo(.secondSingular), "ve"),
      (.imperativoAfirmativo(.firstPlural), "vamos"),
    ]),
  ])

  // 25 dar = cantar + wp-i + residue (doy, the monosyllable accents dé/dais/deis).
  static let dar = VerbModel2(base: .ar, features: [
    PreteriteEndings2.wpI,
    residue([
      (.presenteDeIndicativo(.firstSingular), "doy"), (.presenteDeIndicativo(.secondPlural), "dais"),
      (.presenteDeSubjuntivo(.firstSingular), "dé"), (.presenteDeSubjuntivo(.thirdSingular), "dé"),
      (.presenteDeSubjuntivo(.secondPlural), "deis"),
    ]),
  ])

  // 26 poder = comer + d-ue + sp-end(pud) + f-drope + residue (GER pudiendo).
  static let poder = VerbModel2(base: .er, features: [
    StemVowel2.dUe,
    StemFeature2.strongPreterite(from: "pod", to: "pud"), PreteriteEndings2.spEnd,
    FutureEndings2.fDrope,
    residue([(.gerundio, "pudiendo")]),
  ])

  // 27 querer = comer + d-ie + sp-end(quis) + f-drope (querr-).
  static let querer = VerbModel2(base: .er, features: [
    StemVowel2.dIe,
    StemFeature2.strongPreterite(from: "quer", to: "quis"), PreteriteEndings2.spEnd,
    FutureEndings2.fDrope,
  ])

  // 28 decir's shared core (digo, dij-, dir-, dicho) — reused by the sub-classes.
  private static let decirCore: [Feature2] = [
    StemVowel2.rEiStr, StemVowel2.rEiWk,
    StemFeature2.irregularFirstSingular(from: "dec", to: "dig"),
    StemFeature2.strongPreterite(from: "dec", to: "dij"), PreteriteEndings2.spJend,
    StemFeature2.contractedFuture(from: "dec", to: "di"), FutureEndings2.fContract,
    IrregularParticiple2("dec", "dicho"),
  ]
  static let decir = VerbModel2(base: .ir, features: decirCore + [residue([(.imperativoAfirmativo(.secondSingular), "di")])])
  // 28-1 predecir = decir − the irregular-tú literal (so tú is the regular predice).
  static let predecir = VerbModel2(base: .ir, features: decirCore)
  // 28-2 bendecir = decir − f-contract − PP − IMP residue (regular FU/CO/PP/tú; keeps dig-/dij-).
  static let bendecir = VerbModel2(base: .ir, features: [
    StemVowel2.rEiStr, StemVowel2.rEiWk,
    StemFeature2.irregularFirstSingular(from: "dec", to: "dig"),
    StemFeature2.strongPreterite(from: "dec", to: "dij"), PreteriteEndings2.spJend,
  ])

  // 29 hacer = comer + hag- + sp-end(hic) + f-contract(har) + residue. Keyed on the
  // end-anchored core `ac` (h-ac → h-ic), so satisfacer / deshacer ride free.
  static let hacer = VerbModel2(base: .er, features: [
    StemFeature2.irregularFirstSingular(from: "ac", to: "ag"),
    StemFeature2.strongPreterite(from: "ac", to: "ic"), PreteriteEndings2.spEnd,
    StemFeature2.contractedFuture(from: "ac", to: "a"), FutureEndings2.fContract,
    RunningStemConsonantSwap2.hizo,
    IrregularParticiple2("ac", "echo"),
    ApocopatedImperative2(finalSwap: ("c", "z")),
  ])
  // 29-1 rehacer = hacer + accent residue (rehíce / rehízo).
  static let rehacer = VerbModel2(base: .er, features: hacer.features + [residue([
    (.pretérito(.firstSingular), "rehíce"), (.pretérito(.thirdSingular), "rehízo"),
  ])])

  // 30 poner = comer + g1-g + sp-end(pus) + f-dr + residue (PP puesto, IMP pon).
  static let poner = VerbModel2(base: .er, features: [
    StemFeature2.g1g,
    StemFeature2.strongPreterite(from: "pon", to: "pus"), PreteriteEndings2.spEnd,
    FutureEndings2.fDr,
    IrregularParticiple2("pon", "puesto"),
    ApocopatedImperative2(),
  ])

  // 31 tener = comer + d-ie + g1-g + sp-end(tuv) + f-dr + apocopated tú (ten).
  static let tener = VerbModel2(base: .er, features: [
    StemVowel2.dIe,
    StemFeature2.g1g,
    StemFeature2.strongPreterite(from: "ten", to: "tuv"),
    PreteriteEndings2.spEnd,
    FutureEndings2.fDr,
    ApocopatedImperative2(),
  ])

  // 32 venir = subir + d-ie + r-ei-wk + g1-g + sp-end(vin) + f-dr + apocopated tú (ven).
  static let venir = VerbModel2(base: .ir, features: [
    StemVowel2.dIe,
    StemVowel2.rEiWk,
    StemFeature2.g1g,
    StemFeature2.strongPreterite(from: "ven", to: "vin"),
    PreteriteEndings2.spEnd,
    FutureEndings2.fDr,
    ApocopatedImperative2(),
  ])

  // 33 traer = comer + g1-ig(traig) + sp-jend(traj) + o-yhiatus (trayendo/traído).
  static let traer = VerbModel2(base: .er, features: [
    StemFeature2.g1ig,
    StemFeature2.strongPreterite(from: "tra", to: "traj"), PreteriteEndings2.spJend,
    IYHiatus2.oYhiatus,
  ])

  // 34 conducir (-ducir) = subir + zc + sp-jend(-duj).
  static let conducir = VerbModel2(base: .ir, features: [
    StemFeature2.zc,
    StemFeature2.strongPreterite(from: "conduc", to: "conduj"), PreteriteEndings2.spJend,
  ])

  // 35 andar = cantar + sp-end(anduv).
  static let andar = VerbModel2(base: .ar, features: [
    StemFeature2.strongPreterite(from: "and", to: "anduv"), PreteriteEndings2.spEnd,
  ])

  // MARK: - The class-number → model map

  // 106 entries: every distinct Model # in `docs/annex_b_verb_models.md`. The
  // prefix-accent compounds 29-2/30-1/31-1/32-1 alias their parents (no distinct
  // model — they ride hacer/poner/tener/venir by prefix-invariance).
  private static let byClassNumber: [String: VerbModel2] = [
    "1": cantar,
    "1-1": tocar, "1-2": pagar, "1-3": averiguar, "1-4": cazar,
    "1-5": aislar, "1-6": aullar, "1-7": descafeinar, "1-8": rehusar, "1-9": amohinar,
    "1-10": ahincar, "1-11": cabrahigar, "1-12": enraizar, "1-13": europeizar,
    "1-14": actuar, "1-15": enviar,

    "2": comer,
    "2-1": vencer, "2-2": coger, "2-3": leer, "2-4": empeller, "2-5": tañer, "2-6": romper,

    "3": subir,
    "3-1": fruncir, "3-2": dirigir, "3-3": distinguir, "3-4": delinquir,
    "3-5": bullir, "3-6": bruñir, "3-7": reunir, "3-8": prohibir,
    "3-9": abrir, "3-10": cubrir, "3-11": escribir, "3-12": imprimir,
    "3-13": pudrir, "3-14": abolir,

    "4A": pensar, "4A-1": negar, "4A-2": empezar, "4A-3": errar,
    "4B": mostrar, "4B-1": trocar, "4B-2": colgar, "4B-3": forzar,
    "4B-4": agorar, "4B-5": desosar, "4B-6": avergonzar,

    "5A": perder,
    "5B": mover, "5B-1": cocer, "5B-2": oler, "5B-3": resolver, "5B-4": volver,

    "6A": sentir, "6A-1": erguir,
    "6B": pedir, "6B-1": elegir, "6B-2": seguir, "6B-3": ceñir, "6B-4": reir,
    "6C": dormir, "6C-1": morir,

    "7A": conocer, "7A-1": yacer, "7A-2": placer, "7B": lucir,

    "8": construir,

    "9": caer, "9-1": raer, "9-2": roer,
    "10": oir, "11": salir, "12": valer, "13": asir,

    "14": ver, "14-1": prever, "15": discernir, "16": jugar, "17": adquirir, "18": arguir,

    "19": ser, "20": estar, "21": haber, "22": saber, "23": caber, "24": ir,
    "25": dar, "26": poder, "27": querer,
    "28": decir, "28-1": predecir, "28-2": bendecir,
    "29": hacer, "29-1": rehacer, "29-2": hacer,    // 29-2 satisfacer aliases hacer
    "30": poner, "30-1": poner,                     // 30-1 suponer aliases poner
    "31": tener, "31-1": tener,                     // 31-1 obtener aliases tener
    "32": venir, "32-1": venir,                     // 32-1 convenir aliases venir
    "33": traer, "34": conducir, "35": andar,
  ]
}
