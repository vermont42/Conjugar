//
//  ModelCatalog.swift
//  Conjugar
//
//  Created by Joshua Adams on 6/13/26.
//  Copyright © 2026 Josh Adams. All rights reserved.
//

// Phase 6A — the **model catalog**: the single source of truth mapping each book
// class number (`"1"`, `"1-1"`, `"4B-1"`, `"7A"`, `"31-1"`, …) to its
// `VerbModel` (taxonomy §1: base + ordered features). Until now these ~95 models
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
// / 32 venir) because `ApocopatedImperative` already derives the accented
// imperative (satisfaz/supón/obtén/convén) and every other feature is
// prefix-invariant (§1 "ride for free"). Their class numbers alias the parent.
enum ModelCatalog {
  // MARK: - Lookup

  /// The `VerbModel` for a book class number, or `nil` if the number is unknown.
  static func model(forClass classNumber: String) -> VerbModel? {
    byClassNumber[classNumber]
  }

  /// Every class number the catalog resolves (the keys of the map). Used by the
  /// completeness test to assert Annex B's 106 numbers all resolve.
  static var classNumbers: Set<String> {
    Set(byClassNumber.keys)
  }

  /// The exemplar (model verb) for a book class number — the human-readable name
  /// the Verb screen shows in place of the legacy "parent verb" concept
  /// (reconocer → 7A → "conocer"). The prefix-accent alias classes (29-2, 30-1,
  /// 31-1, 32-1) name the parent exemplar they ride.
  static func exemplar(forClass classNumber: String) -> String? {
    exemplarByClassNumber[classNumber]
  }

  // MARK: - Shared build helpers (mirrors the test exemplars' helpers)

  /// Build a `LiteralSlotOverride` from `(slot, form)` pairs (the catch-all residue).
  private static func residue(_ pairs: [(EngineTense, String)]) -> LiteralSlotOverride {
    LiteralSlotOverride(overrides: pairs.map { (slot: $0.0, form: $0.1) })
  }

  /// A suppletive present-subjunctive stem (ser sea-, haber haya-, …): replace the
  /// whole stem in PS{all} only, leaving the (separately suppletive) PI 1s alone.
  private static func subjunctiveStem(_ whole: String) -> StemFeature {
    StemFeature(operation: .replaceWhole(whole), slots: Slot.isPresentSubjunctive)
  }

  /// `y-add` restricted to the §4.5 subj-from-1s slots (PI 1s + PS{all}) — the
  /// raer/roer **alternate** paradigm (rayo/raya, royo/roya).
  private static let yAddSubjunctive = StemFeature(operation: .append("y"), slots: Slot.isSubjFrom1s)

  // MARK: - Perfectly regular (1 / 2 / 3) and their orthographic sub-classes

  static let cantar = VerbModel(base: .ar)
  static let comer = VerbModel(base: .er)
  static let subir = VerbModel(base: .ir)

  // 1-x: -ar orthographic (§4.1) and accent (§4.2)
  static let tocar = VerbModel(base: .ar, features: [StemFinalConsonant.oCar])
  static let pagar = VerbModel(base: .ar, features: [StemFinalConsonant.oGar])
  static let averiguar = VerbModel(base: .ar, features: [StemFinalConsonant.oGuar])
  static let cazar = VerbModel(base: .ar, features: [StemFinalConsonant.oZar])
  static let aislar = VerbModel(base: .ar, features: [AccentStem.aStemI])
  static let aullar = VerbModel(base: .ar, features: [AccentStem.aStemU])
  static let descafeinar = VerbModel(base: .ar, features: [AccentStem.aStemI])
  static let rehusar = VerbModel(base: .ar, features: [AccentStem.aStemU])
  static let amohinar = VerbModel(base: .ar, features: [AccentStem.aStemI])
  static let ahincar = VerbModel(base: .ar, features: [AccentStem.aStemI, StemFinalConsonant.oCar])
  static let cabrahigar = VerbModel(base: .ar, features: [AccentStem.aStemI, StemFinalConsonant.oGar])
  static let enraizar = VerbModel(base: .ar, features: [AccentStem.aStemI, StemFinalConsonant.oZar])
  static let europeizar = VerbModel(base: .ar, features: [AccentStem.aStemI, StemFinalConsonant.oZar])
  static let actuar = VerbModel(base: .ar, features: [AccentStem.aU])
  static let enviar = VerbModel(base: .ar, features: [AccentStem.aI])

  // 2-x: -er orthographic
  static let vencer = VerbModel(base: .er, features: [StemFinalConsonant.oCz])
  static let coger = VerbModel(base: .er, features: [StemFinalConsonant.oGj])
  static let leer = VerbModel(base: .er, features: [IYHiatus.oYhiatus])
  static let empeller = VerbModel(base: .er, features: [AbsorbIAfterPalatal.oLlñ])
  static let tañer = VerbModel(base: .er, features: [AbsorbIAfterPalatal.oLlñ])
  static let romper = VerbModel(base: .er, features: [IrregularParticiple("romp", "roto")])

  // 3-x: -ir orthographic
  static let fruncir = VerbModel(base: .ir, features: [StemFinalConsonant.oCz])
  static let dirigir = VerbModel(base: .ir, features: [StemFinalConsonant.oGj])
  static let distinguir = VerbModel(base: .ir, features: [StemFinalConsonant.oGug])
  static let delinquir = VerbModel(base: .ir, features: [StemFinalConsonant.oQuc])
  static let bullir = VerbModel(base: .ir, features: [AbsorbIAfterPalatal.oLlñ])
  static let bruñir = VerbModel(base: .ir, features: [AbsorbIAfterPalatal.oLlñ])
  static let reunir = VerbModel(base: .ir, features: [AccentStem.aStemU])
  static let prohibir = VerbModel(base: .ir, features: [AccentStem.aStemI])
  static let abrir = VerbModel(base: .ir, features: [IrregularParticiple("abr", "abierto")])
  static let cubrir = VerbModel(base: .ir, features: [IrregularParticiple("cubr", "cubierto")])
  static let escribir = VerbModel(base: .ir, features: [IrregularParticiple("scrib", "scrito")])
  static let imprimir = VerbModel(base: .ir, features: [IrregularParticiple("imprim", "impreso", alternate: "imprimido")])
  static let pudrir = VerbModel(base: .ir, features: [IrregularParticiple("pudr", "podrido")])
  static let abolir = VerbModel(base: .ir, features: [DefectiveFeature.abolir])

  // MARK: - Diphthongs (§4.3): 4A / 4B / 5A / 5B

  static let pensar = VerbModel(base: .ar, features: [StemVowel.dIe])
  static let negar = VerbModel(base: .ar, features: [StemVowel.dIe, StemFinalConsonant.oGar])
  static let empezar = VerbModel(base: .ar, features: [StemVowel.dIe, StemFinalConsonant.oZar])
  static let errar = VerbModel(base: .ar, features: [StemVowel.dIeYe])

  static let mostrar = VerbModel(base: .ar, features: [StemVowel.dUe])
  // 4B-1 trocar = mostrar (d-ue) + o-car (c→qu): trueco/trueque/troqué.
  static let trocar = VerbModel(base: .ar, features: [StemVowel.dUe, StemFinalConsonant.oCar])
  static let colgar = VerbModel(base: .ar, features: [StemVowel.dUe, StemFinalConsonant.oGar])
  static let forzar = VerbModel(base: .ar, features: [StemVowel.dUe, StemFinalConsonant.oZar])
  static let agorar = VerbModel(base: .ar, features: [StemVowel.dUeGue])
  // 4B-5 desosar = d-ue-hue on an -ar base (deshueso); oler is the -er cousin (5B-2).
  static let desosar = VerbModel(base: .ar, features: [StemVowel.dUeHue])
  // 4B-6 avergonzar = d-ue-gue (GO→GÜE) + o-zar (Z→C): avergüenzo / avergüence / avergoncé.
  static let avergonzar = VerbModel(base: .ar, features: [StemVowel.dUeGue, StemFinalConsonant.oZar])

  static let perder = VerbModel(base: .er, features: [StemVowel.dIe])
  static let mover = VerbModel(base: .er, features: [StemVowel.dUe])
  static let cocer = VerbModel(base: .er, features: [StemVowel.dUe, StemFinalConsonant.oCz])
  static let oler = VerbModel(base: .er, features: [StemVowel.dUeHue])
  static let resolver = VerbModel(base: .er, features: [StemVowel.dUe, IrregularParticiple("solv", "suelto")])
  static let volver = VerbModel(base: .er, features: [StemVowel.dUe, IrregularParticiple("volv", "vuelto")])

  // MARK: - Diphthongs and/or umlauts (§4.3/§4.4): 6A / 6B / 6C

  static let sentir = VerbModel(base: .ir, features: [StemVowel.dIe, StemVowel.rEiWk])
  // 6A-1 erguir = two co-equal paradigms (ye / raise) in the stressed slots.
  static let erguir = VerbModel(base: .ir,
    features: [StemVowel.dIeYe, StemVowel.rEiWk, StemFinalConsonant.oGug],
    alternates: [[StemVowel.rEiStr, StemVowel.rEiWk, StemFinalConsonant.oGug]])

  static let pedir = VerbModel(base: .ir, features: [StemVowel.rEiStr, StemVowel.rEiWk])
  static let elegir = VerbModel(base: .ir, features: [StemVowel.rEiStr, StemVowel.rEiWk, StemFinalConsonant.oGj])
  static let seguir = VerbModel(base: .ir, features: [StemVowel.rEiStr, StemVowel.rEiWk, StemFinalConsonant.oGug])
  static let ceñir = VerbModel(base: .ir, features: [StemVowel.rEiStr, StemVowel.rEiWk, AbsorbIAfterPalatal.oLlñ])
  // 6B-4 reír = subir + r-ei-str + r-ei-wk (re→ri) + a-i (ri→rí in STR) +
  // collapse-ii + o-yhiatus — all end-anchored, so the 6 compounds (freír, sonreír,
  // sofreír, refreír, desleír, engreír) conjugate on their own stem (frío, deslío)
  // rather than on a baked-in literal. The raise runs **before** a-i so the accent
  // lands on the raised i (río/ríe/ría). collapse runs **before** o-yhiatus so the
  // glide slots (PR{3s,3p}/GER/IS) drop the double-i (ri+ió→rió, ri+iendo→riendo)
  // instead of gliding (*riyó); o-yhiatus then supplies the hiatus accents on the
  // unraised-stem slots (reí­ste/reímos/reísteis/reído, plus reímos PI-1p / reíd
  // IMP-2p from its extended accent set). (The preferred frito/sofrito/refrito PP
  // variants are per-verb data, out of scope — Annex B fn15/22/24; freír now yields
  // the accepted regular freído.)
  static let reir = VerbModel(base: .ir, features: [
    StemVowel.rEiStr, StemVowel.rEiWk,
    AccentStem.aI,
    CollapseDoubleI.collapse,
    IYHiatus.oYhiatus
  ])

  static let dormir = VerbModel(base: .ir, features: [StemVowel.dUe, StemVowel.rOuWk])
  static let morir = VerbModel(base: .ir, features: [StemVowel.dUe, StemVowel.rOuWk, IrregularParticiple("mor", "muerto")])

  // MARK: - 1st-singular -zco (§4.5): 7A / 7B

  static let conocer = VerbModel(base: .er, features: [StemFeature.zc])
  // 7A-1 yacer = zc primary + c→zg (yazgo) and c→g (yago, with apocopated yaz) alternates.
  static let yacer = VerbModel(base: .er,
    features: [StemFeature.zc],
    alternates: [
      [StemFeature(operation: .swapSuffix(from: "c", to: "zg"), slots: Slot.isSubjFrom1s)],
      [StemFeature(operation: .swapSuffix(from: "c", to: "g"), slots: Slot.isSubjFrom1s),
       ApocopatedImperative(finalSwap: ("c", "z"))]
    ])
  // 7A-2 placer = zc primary + a representative archaic alternate slice (plegue/plega/plugo).
  static let placer = VerbModel(base: .er,
    features: [StemFeature.zc],
    alternates: [
      [StemFeature.zc, residue([(.presenteDeSubjuntivo(.thirdSingular), "plegue")])],
      [StemFeature.zc, residue([
        (.presenteDeSubjuntivo(.thirdSingular), "plega"), (.pretérito(.thirdSingular), "plugo")
      ])]
    ])
  static let lucir = VerbModel(base: .ir, features: [StemFeature.zc])

  // MARK: - "Add -y except before -i" (§4.5): 8 / 18

  static let construir = VerbModel(base: .ir, features: [StemFeature.yAdd, IYHiatus.oYhiatus])
  // 18 argüir = construir + güy→guy (a single paradigm; the "alternate" is orthographic).
  static let arguir = VerbModel(base: .ir, features: [
    StemFeature.yAdd, IYHiatus.oYhiatus, DiaeresisDropBeforeY.güyGuy
  ])

  // MARK: - Irregular 1st-singular -go (§4.5): 9 / 10 / 11 / 12 / 13

  static let caer = VerbModel(base: .er, features: [StemFeature.g1ig, IYHiatus.oYhiatus])
  // 9-1 raer = caer-build primary + a y-add alternate stack (rayo/raya).
  static let raer = VerbModel(base: .er,
    features: [StemFeature.g1ig, IYHiatus.oYhiatus],
    alternates: [[yAddSubjunctive, IYHiatus.oYhiatus]])
  // 9-2 roer = THREE PI-1s/PS variants: regular roo (primary), g1-ig roigo, y-add royo.
  static let roer = VerbModel(base: .er,
    features: [IYHiatus.oYhiatus],
    alternates: [[StemFeature.g1ig, IYHiatus.oYhiatus], [yAddSubjunctive, IYHiatus.oYhiatus]])

  // 10 oír = subir + y-add + g1-ig + o-yhiatus — all end-anchored, so desoír /
  // entreoír conjugate on their own stem (desoímos / desoíd, not the base's literal).
  // g1-ig is listed AFTER y-add so it wins in the overlapping subj-from-1s slots: PI
  // 1s oigo (not *oyo) and PS{all} oiga… (not *oya…), while y-add keeps the glide in
  // PI{2s,3s,3p}/IMP-2s (oyes/oye/oyen/oye). o-yhiatus's extended accent set now
  // supplies the present-1p / imperative-2p hiatus accents (oímos / oíd) directly —
  // they used to be literal residue, which broke the prefix (oímos rode desoír).
  // (Taxonomy §5 lists an `a-stem`, but oír's stem "o" has no i/u for it to accent —
  // it would be inert — so it is omitted to keep the irregularity score honest.)
  static let oir = VerbModel(base: .ir, features: [
    StemFeature.yAdd,
    StemFeature.g1ig,
    IYHiatus.oYhiatus
  ])

  static let salir = VerbModel(base: .ir, features: [StemFeature.g1g, FutureEndings.fDr, ApocopatedImperative()])
  static let valer = VerbModel(base: .er, features: [StemFeature.g1g, FutureEndings.fDr])
  static let asir = VerbModel(base: .ir, features: [StemFeature.g1g])

  // MARK: - Mixed patterns: 14 / 15 / 16 / 17

  // 14 ver = comer + wp-i + residue (veo/vea-, veía-, monosyllable veis).
  static let ver = VerbModel(base: .er, features: [
    StemFeature(operation: .append("e"), slots: Slot.isSubjFrom1s),  // veo, vea-
    StemFeature(operation: .append("e"), slots: Slot.isImperfect),   // veía-
    PreteriteEndings.wpI,
    IrregularParticiple("v", "visto"),
    residue([
      (.presenteDeIndicativo(.secondPlural), "veis"),
      (.presenteDeIndicativo(.secondSingularVos), "ves")
    ])
  ])
  // 14-1 prever = ver's stem rebuilds + monosyllable→polysyllable accent residue.
  static let prever = VerbModel(base: .er, features: [
    StemFeature(operation: .append("e"), slots: Slot.isSubjFrom1s),
    StemFeature(operation: .append("e"), slots: Slot.isImperfect),
    PreteriteEndings.wpI,
    IrregularParticiple("v", "visto"),
    residue([
      (.presenteDeIndicativo(.secondSingular), "prevés"), (.presenteDeIndicativo(.thirdSingular), "prevé"),
      (.presenteDeIndicativo(.thirdPlural), "prevén"),
      (.pretérito(.firstSingular), "preví"), (.pretérito(.thirdSingular), "previó")
    ])
  ])
  static let discernir = VerbModel(base: .ir, features: [StemVowel.dIe])
  static let jugar = VerbModel(base: .ar, features: [StemVowel.dUUe, StemFinalConsonant.oGar])
  static let adquirir = VerbModel(base: .ir, features: [StemVowel.dIIe])

  // MARK: - Fundamentally irregular: 19–35

  // 19 ser = comer + pret-fue + residue (suppletive PI/IM, PS sea-, IMP sé).
  static let ser = VerbModel(base: .er, features: [
    SuppletivePreterite.fue,
    subjunctiveStem("se"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "soy"), (.presenteDeIndicativo(.secondSingular), "eres"),
      (.presenteDeIndicativo(.thirdSingular), "es"), (.presenteDeIndicativo(.firstPlural), "somos"),
      (.presenteDeIndicativo(.secondPlural), "sois"), (.presenteDeIndicativo(.thirdPlural), "son"),
      (.presenteDeIndicativo(.secondSingularVos), "sos"),
      (.imperfectoDeIndicativo(.firstSingular), "era"), (.imperfectoDeIndicativo(.secondSingular), "eras"),
      (.imperfectoDeIndicativo(.thirdSingular), "era"), (.imperfectoDeIndicativo(.firstPlural), "éramos"),
      (.imperfectoDeIndicativo(.secondPlural), "erais"), (.imperfectoDeIndicativo(.thirdPlural), "eran"),
      (.imperativoAfirmativo(.secondSingular), "sé")
    ])
  ])

  // 20 estar = cantar + sp-end(estuv) + residue (estoy + the stress-shift accents).
  static let estar = VerbModel(base: .ar, features: [
    StemFeature.strongPreterite(from: "est", to: "estuv"), PreteriteEndings.spEnd,
    residue([
      (.presenteDeIndicativo(.firstSingular), "estoy"), (.presenteDeIndicativo(.secondSingular), "estás"),
      (.presenteDeIndicativo(.thirdSingular), "está"), (.presenteDeIndicativo(.thirdPlural), "están"),
      (.presenteDeSubjuntivo(.firstSingular), "esté"), (.presenteDeSubjuntivo(.secondSingular), "estés"),
      (.presenteDeSubjuntivo(.thirdSingular), "esté"), (.presenteDeSubjuntivo(.thirdPlural), "estén"),
      (.imperativoAfirmativo(.secondSingular), "está")
    ])
  ])

  // 21 haber = comer + sp-end(hub) + f-drope + residue (he/has/ha…, PS haya-).
  static let haber = VerbModel(base: .er, features: [
    StemFeature.strongPreterite(from: "hab", to: "hub"), PreteriteEndings.spEnd,
    FutureEndings.fDrope,
    subjunctiveStem("hay"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "he"), (.presenteDeIndicativo(.secondSingular), "has"),
      (.presenteDeIndicativo(.thirdSingular), "ha"), (.presenteDeIndicativo(.firstPlural), "hemos"),
      (.presenteDeIndicativo(.thirdPlural), "han"),
      (.presenteDeIndicativo(.secondSingularVos), "has"),  // voseo auxiliary: vos has hablado
      (.imperativoAfirmativo(.secondSingular), "he")
    ])
  ])

  // 22 saber = comer + sp-end(sup) + f-drope + residue (PI 1s sé, PS sep-).
  static let saber = VerbModel(base: .er, features: [
    StemFeature.strongPreterite(from: "sab", to: "sup"), PreteriteEndings.spEnd,
    FutureEndings.fDrope,
    subjunctiveStem("sep"),
    residue([(.presenteDeIndicativo(.firstSingular), "sé")])
  ])

  // 23 caber = comer + sp-end(cup) + f-drope + residue (PI 1s quepo, PS quep-).
  static let caber = VerbModel(base: .er, features: [
    StemFeature.strongPreterite(from: "cab", to: "cup"), PreteriteEndings.spEnd,
    FutureEndings.fDrope,
    subjunctiveStem("quep"),
    residue([(.presenteDeIndicativo(.firstSingular), "quepo")])
  ])

  // 24 ir = subir + pret-fue + residue (voy/vas…, IM iba-, PS vaya-, ve/vamos, yendo).
  static let ir = VerbModel(base: .ir, features: [
    SuppletivePreterite.fue,
    subjunctiveStem("vay"),
    residue([
      (.presenteDeIndicativo(.firstSingular), "voy"), (.presenteDeIndicativo(.secondSingular), "vas"),
      (.presenteDeIndicativo(.thirdSingular), "va"), (.presenteDeIndicativo(.firstPlural), "vamos"),
      (.presenteDeIndicativo(.secondPlural), "vais"), (.presenteDeIndicativo(.thirdPlural), "van"),
      (.presenteDeIndicativo(.secondSingularVos), "vas"),
      (.imperativoAfirmativo(.secondSingularVos), "andá"),  // voseo avoids *í; andá (per the legacy data)
      (.imperfectoDeIndicativo(.firstSingular), "iba"), (.imperfectoDeIndicativo(.secondSingular), "ibas"),
      (.imperfectoDeIndicativo(.thirdSingular), "iba"), (.imperfectoDeIndicativo(.firstPlural), "íbamos"),
      (.imperfectoDeIndicativo(.secondPlural), "ibais"), (.imperfectoDeIndicativo(.thirdPlural), "iban"),
      (.gerundio, "yendo"),
      (.imperativoAfirmativo(.secondSingular), "ve"),
      (.imperativoAfirmativo(.firstPlural), "vamos")
    ])
  ])

  // 25 dar = cantar + wp-i + residue (doy, the monosyllable accents dé/dais/deis).
  static let dar = VerbModel(base: .ar, features: [
    PreteriteEndings.wpI,
    residue([
      (.presenteDeIndicativo(.firstSingular), "doy"), (.presenteDeIndicativo(.secondPlural), "dais"),
      (.presenteDeIndicativo(.secondSingularVos), "das"),  // monosyllable: no accent, unlike the derived *dás
      (.imperativoAfirmativo(.secondSingularVos), "da"),   // likewise
      (.presenteDeSubjuntivo(.firstSingular), "dé"), (.presenteDeSubjuntivo(.thirdSingular), "dé"),
      (.presenteDeSubjuntivo(.secondPlural), "deis")
    ])
  ])

  // 26 poder = comer + d-ue + sp-end(pud) + f-drope + residue (GER pudiendo).
  static let poder = VerbModel(base: .er, features: [
    StemVowel.dUe,
    StemFeature.strongPreterite(from: "pod", to: "pud"), PreteriteEndings.spEnd,
    FutureEndings.fDrope,
    residue([(.gerundio, "pudiendo")])
  ])

  // 27 querer = comer + d-ie + sp-end(quis) + f-drope (querr-).
  static let querer = VerbModel(base: .er, features: [
    StemVowel.dIe,
    StemFeature.strongPreterite(from: "quer", to: "quis"), PreteriteEndings.spEnd,
    FutureEndings.fDrope
  ])

  // 28 decir's shared core (digo, dij-, dir-, dicho) — reused by the sub-classes.
  private static let decirCore: [ConjugationFeature] = [
    StemVowel.rEiStr, StemVowel.rEiWk,
    StemFeature.irregularFirstSingular(from: "dec", to: "dig"),
    StemFeature.strongPreterite(from: "dec", to: "dij"), PreteriteEndings.spJend,
    StemFeature.contractedFuture(from: "dec", to: "di"), FutureEndings.fContract,
    IrregularParticiple("dec", "dicho")
  ]
  static let decir = VerbModel(base: .ir, features: decirCore + [residue([(.imperativoAfirmativo(.secondSingular), "di")])])
  // 28-1 predecir = decir − the irregular-tú literal (so tú is the regular predice).
  static let predecir = VerbModel(base: .ir, features: decirCore)
  // 28-2 bendecir = decir − f-contract − PP − IMP residue (regular FU/CO/PP/tú; keeps dig-/dij-).
  static let bendecir = VerbModel(base: .ir, features: [
    StemVowel.rEiStr, StemVowel.rEiWk,
    StemFeature.irregularFirstSingular(from: "dec", to: "dig"),
    StemFeature.strongPreterite(from: "dec", to: "dij"), PreteriteEndings.spJend
  ])

  // 29 hacer = comer + hag- + sp-end(hic) + f-contract(har) + residue. Keyed on the
  // end-anchored core `ac` (h-ac → h-ic), so satisfacer / deshacer ride free.
  static let hacer = VerbModel(base: .er, features: [
    StemFeature.irregularFirstSingular(from: "ac", to: "ag"),
    StemFeature.strongPreterite(from: "ac", to: "ic"), PreteriteEndings.spEnd,
    StemFeature.contractedFuture(from: "ac", to: "a"), FutureEndings.fContract,
    RunningStemConsonantSwap.hizo,
    IrregularParticiple("ac", "echo"),
    ApocopatedImperative(finalSwap: ("c", "z"))
  ])
  // 29-1 rehacer = hacer + accent residue (rehíce / rehízo).
  static let rehacer = VerbModel(base: .er, features: hacer.features + [residue([
    (.pretérito(.firstSingular), "rehíce"), (.pretérito(.thirdSingular), "rehízo")
  ])])

  // 30 poner = comer + g1-g + sp-end(pus) + f-dr + residue (PP puesto, IMP pon).
  static let poner = VerbModel(base: .er, features: [
    StemFeature.g1g,
    StemFeature.strongPreterite(from: "pon", to: "pus"), PreteriteEndings.spEnd,
    FutureEndings.fDr,
    IrregularParticiple("pon", "puesto"),
    ApocopatedImperative()
  ])

  // 31 tener = comer + d-ie + g1-g + sp-end(tuv) + f-dr + apocopated tú (ten).
  static let tener = VerbModel(base: .er, features: [
    StemVowel.dIe,
    StemFeature.g1g,
    StemFeature.strongPreterite(from: "ten", to: "tuv"),
    PreteriteEndings.spEnd,
    FutureEndings.fDr,
    ApocopatedImperative()
  ])

  // 32 venir = subir + d-ie + r-ei-wk + g1-g + sp-end(vin) + f-dr + apocopated tú (ven).
  static let venir = VerbModel(base: .ir, features: [
    StemVowel.dIe,
    StemVowel.rEiWk,
    StemFeature.g1g,
    StemFeature.strongPreterite(from: "ven", to: "vin"),
    PreteriteEndings.spEnd,
    FutureEndings.fDr,
    ApocopatedImperative()
  ])

  // 33 traer = comer + g1-ig(traig) + sp-jend(traj) + o-yhiatus (trayendo/traído).
  static let traer = VerbModel(base: .er, features: [
    StemFeature.g1ig,
    StemFeature.strongPreterite(from: "tra", to: "traj"), PreteriteEndings.spJend,
    IYHiatus.oYhiatus
  ])

  // 34 conducir (-ducir) = subir + zc + sp-jend(-duj). The strong-preterite swap
  // anchors on the shared "duc" tail (not "conduc") so every -ducir verb rides it
  // (aducir → aduje, traducir → traduje) — the §1 end-anchored payoff.
  static let conducir = VerbModel(base: .ir, features: [
    StemFeature.zc,
    StemFeature.strongPreterite(from: "duc", to: "duj"), PreteriteEndings.spJend
  ])

  // 35 andar = cantar + sp-end(anduv).
  static let andar = VerbModel(base: .ar, features: [
    StemFeature.strongPreterite(from: "and", to: "anduv"), PreteriteEndings.spEnd
  ])

  // MARK: - The class-number → model map

  // 106 entries: every distinct Model # in `docs/annex_b_verb_models.md`. The
  // prefix-accent compounds 29-2/30-1/31-1/32-1 alias their parents (no distinct
  // model — they ride hacer/poner/tener/venir by prefix-invariance).
  private static let byClassNumber: [String: VerbModel] = [
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
    "33": traer, "34": conducir, "35": andar
  ]

  // MARK: - The class-number → exemplar-name map

  // Mirrors `byClassNumber` key-for-key (a test asserts every class number has an
  // exemplar), naming each model's exemplar verb with its dictionary spelling
  // (reír, oír, argüir). The alias classes 29-2/30-1/31-1/32-1 name the parent
  // exemplar whose model they ride.
  private static let exemplarByClassNumber: [String: String] = [
    "1": "cantar",
    "1-1": "tocar", "1-2": "pagar", "1-3": "averiguar", "1-4": "cazar",
    "1-5": "aislar", "1-6": "aullar", "1-7": "descafeinar", "1-8": "rehusar", "1-9": "amohinar",
    "1-10": "ahincar", "1-11": "cabrahigar", "1-12": "enraizar", "1-13": "europeizar",
    "1-14": "actuar", "1-15": "enviar",

    "2": "comer",
    "2-1": "vencer", "2-2": "coger", "2-3": "leer", "2-4": "empeller", "2-5": "tañer", "2-6": "romper",

    "3": "subir",
    "3-1": "fruncir", "3-2": "dirigir", "3-3": "distinguir", "3-4": "delinquir",
    "3-5": "bullir", "3-6": "bruñir", "3-7": "reunir", "3-8": "prohibir",
    "3-9": "abrir", "3-10": "cubrir", "3-11": "escribir", "3-12": "imprimir",
    "3-13": "pudrir", "3-14": "abolir",

    "4A": "pensar", "4A-1": "negar", "4A-2": "empezar", "4A-3": "errar",
    "4B": "mostrar", "4B-1": "trocar", "4B-2": "colgar", "4B-3": "forzar",
    "4B-4": "agorar", "4B-5": "desosar", "4B-6": "avergonzar",

    "5A": "perder",
    "5B": "mover", "5B-1": "cocer", "5B-2": "oler", "5B-3": "resolver", "5B-4": "volver",

    "6A": "sentir", "6A-1": "erguir",
    "6B": "pedir", "6B-1": "elegir", "6B-2": "seguir", "6B-3": "ceñir", "6B-4": "reír",
    "6C": "dormir", "6C-1": "morir",

    "7A": "conocer", "7A-1": "yacer", "7A-2": "placer", "7B": "lucir",

    "8": "construir",

    "9": "caer", "9-1": "raer", "9-2": "roer",
    "10": "oír", "11": "salir", "12": "valer", "13": "asir",

    "14": "ver", "14-1": "prever", "15": "discernir", "16": "jugar", "17": "adquirir", "18": "argüir",

    "19": "ser", "20": "estar", "21": "haber", "22": "saber", "23": "caber", "24": "ir",
    "25": "dar", "26": "poder", "27": "querer",
    "28": "decir", "28-1": "predecir", "28-2": "bendecir",
    "29": "hacer", "29-1": "rehacer", "29-2": "hacer",
    "30": "poner", "30-1": "poner",
    "31": "tener", "31-1": "tener",
    "32": "venir", "32-1": "venir",
    "33": "traer", "34": "conducir", "35": "andar"
  ]
}
