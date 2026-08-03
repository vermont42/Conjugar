# Introduction

This file contains a timeline of this project and will be used to eventually write a blog post about this project.

# Timeline

6/12/26: Kicked off the Conjugar parsimony project — bringing Conjuguer's
model-based representation of verb irregularities to the Spanish app Conjugar.

- **Tightened CLAUDE.md.** Fixed path/casing/number inconsistencies (`doc`→`docs`,
  `VerbModels`→`verbModels`, 6300→6320) and added a paragraph clarifying that the
  real win is the *model inheritance tree*, not the verb→model mapping.
- **Transcribed the book.** Converted Annex A (PDF pages 180–227 = book pages
  167–214) of `spanish_verbs_made_simpler.pdf` into a faithful Markdown
  reference, `docs/spanish_models.md`: all 35 verb-model classes plus ~60
  sub-classes, with full conjugation tables, footnotes, and the book's `+`/`*`/`†`
  markers. Corrected the book's "cubrir = to close" typo to "to cover."
- **Found the central design idea (in conversation).** The book's taxonomy —
  especially its "Fundamentally Irregular" bucket — is a *teaching* grouping, not
  an inheritance structure. For Conjugar we want our own taxonomy where *most*
  models have parents (e.g. `ser` and `haber` are children of `comer` with a few
  overrides; `dar` is `cantar` + ~3 overrides; `andar` is `cantar` + one).
- **Two structural decisions.** (1) Three independent regular roots — `cantar`
  (-ar), `comer` (-er), `subir` (-ir) — kept separate for tradition/clarity even
  though -er and -ir share most forms. (2) Use **feature composition** (base + a
  list of composable feature mix-ins) rather than Conjuguer's single-parent
  inheritance, because Spanish irregularities are orthogonal and combinatorial
  (e.g. `tener` = `comer` + diphthong + go-1s + dr-future + strong-preterite).
  Composition lets each irregularity be defined exactly once — the parsimony win.
- **Wrote the taxonomy.** `docs/spanish_taxonomy.md`: the composition model,
  derivation rules, slot vocabulary, the three roots' ending tables, a ~30-feature
  catalog (orthographic, accent, diphthong, -ir raising, 1s/subjunctive,
  preterite, future, participle), and a decomposition of all 35 book classes into
  base + features + residue. Also documented prefixed-verb handling (`reconocer`
  etc. ride free on the base model) and the "every feature must be anchored to the
  **end** of the stem" constraint that makes that work.
- **Studied Conjuguer's engine** (`verbModels.xml`, `VerbModel.swift`,
  `VerbModelParser.swift`, `Conjugator.swift`, `StemAlteration.swift`) to extract
  its conventions and decide where to diverge.
- **Resolved six design decisions** and agreed a build plan: build a *parallel*
  engine first (new models, `Conjugator`, XML), unit-tests only, UI later;
  verifying the transcription as a test **oracle** is Phase 0.

- **Verified the oracle.** Checked every cell of `docs/spanish_models.md` against
  the source PDF (pages 180–227), using the PDF's clean embedded text layer as an
  *independent* extraction path and adjudicating disagreements + all `+`-marker
  tables on the page images. Result: only **2 corrections** (the unaccented
  starred preterites in 2-4 empeller and 3-5 bullir — `*empellió`→`*empellio`,
  `*bullió`→`*bullio`); accents, diaeresis, `+`/`*`/`†` markers, blanks-vs-`—`,
  and all non-standard table shapes confirmed faithful. Wrote
  `docs/spanish_models_verification.md`. The oracle is now load-bearing.

- **Assessed the old engine** (`Conjugar.mig`) as a logic reference + differential
  oracle. Finding: it's a parent-inheritance + string-substitution machine with
  *almost no* accent/orthographic logic — all irregularity is hand-entered literal
  data in `verbs.xml`. The only reusable computed rule is the imperfect-subjunctive
  `nosotros` accent. It's brittle by construction and already buggy: 4 `-car` verbs
  (`buscar`, `platicar`, `sacar`, `tocar`) are misclassified as regular and produce
  e.g. `*tocé` instead of `toqué`. Decision: don't port logic (implement §4 fresh);
  keep the 214-verb diff only as a *non-gating, normalized, triaged* second opinion
  against the real oracle (book + RAE), logging old-engine disagreements as
  shipped-app bugs. Wrote `docs/old_engine_assessment.md`.

- **Added a voseo supplement to the oracle.** The book is peninsular (no `vos`),
  but the app supports it, so appended a clearly-labeled `# Voseo (supplement —
  not from the book)` section to `spanish_models.md` — RAE-sourced and aligned
  with the shipping app's `svpr`/`svio` slots. Key facts captured: `vos` differs
  from `tú` in only two slots (present 2s `-ás/-és/-ís`, imperative 2s
  `cantá/comé/subí`); the present 2s is **regular** and bypasses the diphthong
  (`vos tenés`, not *tienes*); the lone present irregular is `ser → sos`. Noted in
  the verification doc that this section is *not* part of the verified
  transcription. `PersonNumber2` will carry `vos` from the start.

- **Built the Phase 1 engine** (composition skeleton + three regular roots) in
  `Conjugar.mig`, alongside the old engine and all `2`-suffixed: `PersonNumber2`,
  `Tense2`, `RegularRoot2` (oracle §3 ending tables + voseo), `Feature2`
  (placeholder), `VerbModel2`, `Conjugator2` (validate → base → `stem + ending`
  with a last-wins composition seam), `Conjugator2Error`, plus `Conjugator2Tests`.
  Gate passes: 13 XCTest cases / 168 standalone assertions, 0 failures (full
  paradigms of cantar/comer/subir + voseo + validation). Registered the files via
  the `xcodeproj` gem (old-style project); committed + pushed on `migration`
  (`fa251ef`).

- **Wrote the next two prompts and reordered the plan.** Authored
  `prompts/phase-2-orthographic-accent-features.md` (implement the §4.1/§4.2
  features and the real `Feature2` slot-override API). Then, per a change of plan,
  decided to do the **groups→folders Xcode migration first** and wrote
  `prompts/migrate-groups-to-synchronized-folders.md` (convert the old-style
  project to `objectVersion 77` synchronized folders so new files auto-include
  without `project.pbxproj` edits). Updated the Phase 2 prompt to assume the
  migration is done (drop files into `Conjugar/Models/`; gem registration kept
  only as a fallback).

- **Ran the groups→folders migration.** Moved the ~89 flat app-target sources into real `Conjugar/{Analytics,Controllers,Models,Supporting,Views,UIViews,Utils}/` folders (xcodeproj gem, content-preserving renames; `Info.plist`/`LaunchScreen` kept flat), then "Convert to Folder" in Xcode 26.3 turned those + `ConjugarTests` into `PBXFileSystemSynchronizedRootGroup`s (`objectVersion` 54→**70**, not the 77 the prompt guessed — that's just what this Xcode emits). New files now auto-compile (proved: `Conjugar/Models/_SyncCheck.swift` built into the target with no `project.pbxproj` edit); two commits on `migration`, `Conjugator2Tests` green.

- **Phase 2 done — orthographic + accent features (§4.1/§4.2).** Designed `Feature2`'s end-anchored slot-override API (`applies(to:)` + `apply(stem:ending:tense:)`, threaded last-wins in `Conjugator2.compose`) and implemented all 13 features: the 8 stem-final consonant swaps (`StemFinalConsonant2`: o-car…o-quc), the two i/y junction features (`IYHiatus2` o-yhiatus — owns the i→y *and* the leíste/leímos/leído accents per Josh's call; `AbsorbIAfterPalatal2` o-llñ), and the unified accent feature (`AccentStem2`: a-i/a-u/a-stem). Added `conjugate(infinitive:tense:model:)`; 15 new full-paradigm tests (incl. ahincar/enraizar compositions and releer/reenviar prefix-invariance) green against the oracle — 28 total, 0 failures. Bonus: the new engine fixes the shipping app's `-car` bug (busqué/toqué, not *buscé/*tocé).

- **Wrote the Phase 3 prompt.** Authored `prompts/phase-3-stem-vowel-raising.md` (§4.3 diphthongs `d-ie`/`d-ue`/`d-i-ie`/`d-u-ue` + the spelled variants `d-ie-ye`/`d-ue-gue`/`d-ue-hue`, and §4.4 -ir raising `r-ei-wk`/`r-ei-str`/`r-ou-wk`), composing onto the Phase 2 machinery with no `Feature2` API change — just a new `WK` slot set and one parameterized stem-vowel feature. Confirmed the scope first: the diphthong and raise features interlock (sentir/pedir/dormir need both), the crux is the STR/WK present-subjunctive split (sentir: `sienta` vs `sintamos`), and the cross-phase combos Phase 2 deferred (negar/empezar/colgar/…) become the composition tests. Residue (morir/reír/erguir) deferred to Phase 5.

- **Phase 3 done — stem-vowel diphthongs + -ir raising (§4.3/§4.4).** Added the `WK` slot set to `Slot2` (PS{1p,2p}+PR{3s,3p}+GER+IS{all}, disjoint from STR) and one parameterized `StemVowel2` feature (`from: Character`, `to: String`, `slots: .str/.wk`) that covers all of §4.3+§4.4 — the spelled variants (`d-ie-ye`/`d-ue-gue`/`d-ue-hue`) are just a different `to` string, no `Feature2` API change. The STR/WK split makes the present-subjunctive split fall out for free (sentir: `sienta`…`sintamos`; discernir's WK stays regular as the control). 13 new full-paradigm tests — pensar/mostrar/perder/mover, errar/agorar/oler, adquirir/jugar, discernir, sentir/pedir/dormir (incl. GER), the cross-phase combos Phase 2 deferred (negar/empezar/colgar/forzar/cocer/elegir/seguir), ceñir bonus, and comprobar/repetir prefix-invariance — green against the oracle: 41 total, 0 failures.

- **Wrote the Phase 4 prompt.** Authored `prompts/phase-4-irregular-1s-preterite-future.md` (§4.5 `g1-g`/`g1-ig`/`zc`/`y-add` with bundled `subj-from-1s`, §4.6 `sp-end`/`sp-jend`/`wp-i`/`pret-fue`, §4.7 `f-drope`/`f-dr`/`f-contract`) — the first phase with **derivation rules** (one override → a whole tense: PI1s→PS, PR→IS, FU→CO). Worked the design from the oracle first: the crux is `subj-from-1s` *resetting* a prior diphthong via last-wins (tener → tengo/tenga, not `*tiengo`, while tienes/tiene/tienen keep the diphthong), `sp-end` being base-independent (andar/estar → anduve/anduviera, estuve — `-ie-` IS on an `-ar` base), `sp-jend`'s i-absorption (dijeron/dijera), and the `-uir` accent reconciliation (construir takes the i→y glide but *not* o-yhiatus's hiatus accents — construiste not `*construíste`). Two new machinery pieces called out: regular-stem access for the §4.5 reset, and a general end-anchored residue stem feature (strong/contracted stems); the per-verb residue catalog + full hard-verb assembly stays Phase 5. tener is the capstone test (whole phase in one verb, minus the IMP residue).

- **Phase 4 done — irregular 1s/subjunctive + strong preterites + future stems (§4.5/§4.6/§4.7).** Added the phase's two new pieces of machinery and the three derivation rules. (1) **Regular-stem access**: extended the `Feature2.apply` seam with `regularStem` (the base stem, captured by `compose` before any feature runs); Phase 2/3 features ignore it. (2) **A unified stem-rebuild feature** (`StemFeature2`, append/swapSuffix/replaceWhole from `regularStem`) that realizes both §4.5's productive `g1-g`/`g1-ig`/`zc`/`y-add` (bundled `subj-from-1s`) *and* the per-verb residue stems (strong preterite, contracted future, explicit 1s) — decision §6.4, "residue is a feature." Because it builds from the regular stem it **resets** a prior diphthong/raise in its slots (the last-wins crux: tener → tengo/tenga, not *tiengo, while tienes/tiene/tienen keep the diphthong). §4.6 endings: `PreteriteEndings2` (sp-end/sp-jend/wp-i, spanning PR{all}+IS{all} — base-independent, so andar→anduviera on an -ar base; sp-jend drops the i after j → dijeron/dijera) + `SuppletivePreterite2.fue` (ser/ir). §4.7: `FutureEndings2` (connector "" = f-drope → habré/querré; "d" = f-dr → tendré; f-contract = "" + a contracted-stem swap → haré/diré). Also reconciled `o-yhiatus`'s hiatus accents to fire **only after a strong vowel** so construir takes the i→y glide but not the accents (construiste/construido, not *construíste) while leer/caer/oír keep theirs (crux 5). 15 new tests — conocer/lucir/asir/caer/construir, salir/valer, andar/estar/tener-pret, conducir/decir-pret, dar/ver, ser/ir, haber/querer/poder, tener/poner, hacer/decir-fut, the **tener capstone** (whole phase in one verb) + venir (the raise/reset ordering) + detener/componer/reconocer prefix-invariance — green against the oracle: **56 total, 0 failures**. Feature precedence confirmed: stem-vowel must be listed before the §4.5 1s feature so its reset wins (venir: vengamos, not *vingamos).

- **Wrote two more prompts.** (1) `prompts/convert-tests-to-swift-testing.md` — a
  behavior-preserving migration of `Conjugator2Tests.swift` from XCTest to
  **idiomatic** Swift Testing (`import Testing`, `@Test`, `#expect`, struct suite,
  **required `@Test(arguments:)` parameterization** of the per-person paradigms via
  `zip(persons, expected)` / `(Tense2, String)` pairs, a single `expectForm`
  helper with `sourceLocation:`, shared `static let` models, `Issue.record` for the
  failure paths), scoped to just the new-engine file (the old-engine XCTest files
  coexist and will be removed with the old engine). **Sequenced before Phase 5** so
  the residue tests are written idiomatically from the start. (2)
  `prompts/phase-5-residue-assembly.md` — the final engine phase: the per-verb
  residue catalog + full assembly of oracle classes 19–35 and their sub-classes,
  plus the two deferred cross-cutting pieces — §4.8 irregular participles and the
  imperative derivation (usted/nosotros/ustedes from the computed PS; irregular tú
  ten/pon/sal/di/haz/ve; the monosyllable→polysyllable accent compounds
  obtén/supón/convén; ir's ve/vamos/yendo). Called out the new machinery (a
  general literal slot-override residue feature; the imperative control-flow
  change in `Conjugator2`; the participle attribute tied to the future
  irregularity score) and the cruxes (reuse computed PS for imperatives; scope
  irregular-tú to `.secondSingular` so vos/vosotros stay regular; hizo c→z; ser's
  voseo `sos`; abolir defectivity). Data entry (Phase 6) and UI remain after.
- **Converted `Conjugator2Tests` to Swift Testing.** Migrated the 56 XCTest
  methods to idiomatic Swift Testing (`@Suite` struct, `#expect`/`Issue.record`,
  a `static let` model catalog, paradigms as `@Test(arguments: zip(...))` and
  mixed-tense slots/the tener capstone as `(Tense2, String)` cases); 208 reported
  tests, 0 failures, coverage provably identical (1060 form-assertions + 2 failure
  paths, verified method-by-method against the original).
- **Extracted Annex B — the verb→model index (parallel work alongside Phase 5).**
  Converted Annex B (PDF pages 228–285 = book pages 215–272) of
  `spanish_verbs_made_simpler.pdf` into `docs/annex_b_verb_models.md`: all **4,818**
  verbs, each mapped to its model class, sub-class, and the book's model number
  (e.g. `apostar (1)` → `mostrar` 4B vs `apostar (2)` → `cantar` 1). Used
  `pdftotext -layout` rather than eyeballing 58 rendered pages: a small parser
  (`docs/_extract_annexb.py`, kept for reproducibility) splits the two-column
  layout, restores alphabetical order (full left column then right per page),
  normalizes the PDF's `fi`/`fl` ligatures, strips the 25 superscript footnote
  markers into a Note column (preserving the `(1)`/`(2)` homonym disambiguators),
  and reassembles all 25 footnotes. Verified: record count = 4,818 exactly, 0
  duplicate verbs, 0 malformed cells, spot-checked against the rendered pages.
  This is the easy-data-entry half of the project — once the Spanish model
  hierarchy exists, this table assigns a model to every verb.
- **Phase 5 — residue + full assembly of the irregular verbs (2026-06-12).** The
  final engine phase: every one of the ~95 oracle exemplars now conjugates fully.
  Added the residue machinery in `ResidueFeature2.swift` (all `Feature2`s, so the
  residue composes through the same last-wins seam) — `LiteralSlotOverride2` (the
  catch-all suppletive forms: soy/voy/he…, era-/iba-, dé, yendo/pudiendo),
  `IrregularParticiple2` (§4.8 PP as an **end-anchored stem swap** so componer→
  compuesto / descubrir→descubierto ride free, and it stays a distinct type for the
  future irregularity score), `ApocopatedImperative2` (irregular tú as the bare
  regular stem with the monosyllable→polysyllable accent shift *intrinsic* — so
  ten/pon/sal/ven and haz are one feature and detén/supón/convén/satisfaz fall out
  by prefix-invariance, **no per-compound residue**), `DefectiveFeature2` (abolir),
  and two tiny orthographic residues (`RunningStemConsonantSwap2` for hacer's hizo,
  prefix-invariant to satisfizo; `CollapseDoubleI2` for reír's ri+ió→rió). Wired the
  **imperative derivation** into `Conjugator2` (the one control-flow change:
  usted/nosotros/ustedes are the *computed* present subjunctive, then residue may
  override — ir's nosotros=vamos), added `Feature2.suppresses` (defective → a new
  `.noForm` error) and the `Slot2.isImperfect`/`isPresentSubjunctive` predicates.
  Assembled classes 19–35 + the derived/subtractive sub-classes (predecir,
  bendecir, rehacer, satisfacer, the obtén/supón/convén compounds) + the §4.8
  participle/defective classes (romper/abrir/cubrir/escribir/imprimir/pudrir/
  resolver/volver/morir/abolir) + ver/prever/reír as `VerbModel2` exemplars in the
  Swift Testing suite. Keyed hacer's swaps on the end-anchored core `ac` (not `hac`)
  so satisfacer/deshacer are prefix-invariant. **272 tests, 0 failures** on the real
  target (546 forms cross-checked first in a standalone `swiftc` driver). Bonus
  classes **erguir (6A-1)** and **argüir (18)** deferred (not gated). Next: Phase 6
  bulk data entry (the Annex B map), then UI.
- **Wrote `prompts/phase-5b-alternate-forms.md` — the engine addendum that closes
  the last gap.** A self-contained prompt for a fresh session to add the
  **alternate-forms representation** (a slot with >1 accepted form) — the
  cross-cutting mechanism Phases 1–5 deferred — and then finish the corner classes
  that need it. Frames the load-bearing decision (keep `conjugate -> Result<String>`
  byte-for-byte so the 272 tests stay green; add a parallel `conjugateAll ->
  Result<[String]>`) and the two kinds of alternate: **variant paradigms** (erguir
  yergo/irgo, raer raigo/rayo, roer/yacer's *three*) → an optional
  `VerbModel2.alternates: [[Feature2]]` of alternate feature stacks that
  `conjugateAll` composes and unions; **per-slot literal alternates** (two-form
  participles impreso/imprimido, frito/freído, the `-scripto` family) → surface the
  `IrregularParticiple2.alternate` field already stored but unused. Also specs the
  one new feature **argüir** needs — the **güy→guy** diaeresis drop, whose crux is
  that the cluster spans the stem↔ending seam — and the builds for 6A-1/7A-1/7A-2/
  9-1/9-2/18. Carries the 7 cruxes (keep the single-form API; dedup+order; score
  reads only the primary stack; N≥2 not just 2; oír is *not* an alternate class),
  the gate, and the `swiftc`/`xcodebuild` mechanics. This finishes the *engine*;
  Phase 6 (data entry) and UI still follow.

- **Phase 5b — alternate forms + the deferred corner classes (2026-06-13).** Closed
  the last engine gap: a verb slot with more than one accepted form. Kept the
  single-form API byte-for-byte (`conjugate -> Result<String>`, all prior tests
  untouched) and added a parallel `conjugateAll -> Result<[String]>` that returns
  `[primary] + alternates`, primary first, in book order, de-duplicated. Two kinds
  of alternate compose through the existing seam: **variant paradigms** via a new
  optional `VerbModel2.alternates: [[Feature2]]` (whole alternate feature stacks
  that `conjugateAll` composes through the *same* `conjugateOne` machinery and
  unions per slot — invisible to `conjugate` and to the §6.5 score, which still
  read only `model.features`), and **per-slot literal alternates** via the
  already-stored `IrregularParticiple2.alternate` (surfaced in the PP slot, with a
  shared `form(_:stem:)` helper so the alternate rides the same end-anchored
  coreSuffix swap). Built the deferred classes against the oracle: **18 argüir**
  (construir + the new **güy→guy** diaeresis-drop feature in `DiaeresisFeature2.swift`,
  whose crux is that the `güy` cluster spans the stem↔ending seam — `arguyó` =
  stem `argü` + `o-yhiatus` ending `yó` — handled by a guarded end-anchored fixup
  that drops the diaeresis before a `y` but never before `güi`); **6A-1 erguir**
  (primary sentir/`ye` stack + alternate pedir/raise stack — yergo/irgo in the
  stressed slots, one shared form `erguí`/`irguió`/`irgamos` in the unstressed
  ones); **9-1 raer** / **9-2 roer** (caer-build + a subj-from-1s `y-add` alternate;
  roer carries **three** PI-1s variants roo/roigo/royo, proving N≥2); **7A-1 yacer**
  (zc + c→zg + c→g stacks, the last also bearing the apocopated `yaz`); **7A-2
  placer** (primary `plazco` + a representative archaic slice plegue/plega/plugo,
  the full `plug-` preterite and complacer logged as out-of-scope minutiae); and the
  **two-form participles** imprimir `impreso/imprimido`, freír `frito/freído`, and
  the escribir `-scripto` family (inscribir → `inscrito/inscripto`). Also fixed a
  latent, never-tested bug surfaced by argüir: `isYAdd` now includes IMP{2s}, so a
  y-add verb's tú imperative keeps its glide (construir → **construye**, not
  `construe`; oír → oye; argüir → arguye) while voseo/vosotros stay regular. Engine
  built standalone first (`swiftc` driver, all checks green), then the real target:
  **303 tests, 0 failures** (the 272 prior + 31 new), incl. argüir's full paradigm
  and prefix-invariance (reargüir), erguir's both/shared split, the raer/roer/yacer
  variant sets, the participle pairs, and a degenerate-path check that `conjugateAll`
  returns exactly `[onlyForm]` for a regular verb and for tener. **The engine now
  covers every form the oracle lists for the ~95 exemplars, including alternates.**
  Next: Phase 6 bulk data entry (the Annex B verb→model map), then UI.
- **Wrote `prompts/phase-6-data-entry.md` — the easy-data-entry half.** A
  self-contained prompt for a fresh session to turn `docs/annex_b_verb_models.md`
  (4,818 verbs → book model number) into something the engine consults. Three
  pieces: (A) a **model catalog** in the app target keyed by class number (promote
  the ~95 oracle-verified exemplars out of the test file's `static let`s; build the
  few never-built classes — 4B-1 trocar, 4B-5 desosar, 4B-6 avergonzar, 10 oír —
  and alias the prefix-accent compounds 29-2/30-1/31-1/32-1 to their parents, since
  `ApocopatedImperative2` already derives satisfaz/supón/obtén/convén for free);
  (B) the **verb→model map** as a generated bundle resource (a reproducible
  extractor beside `_extract_annexb.py`, not 4,818 hand-typed lines), with a
  table-derived completeness test that all **106** distinct model numbers resolve,
  plus a **gloss-as-you-map** step — Annex B has no English glosses, so each verb
  gets one, sourced in priority order (oracle class headers → the old `verbs.xml`
  `tn` attribute → Annex B footnotes for the homonym senses → authored for the
  remaining ~4,500), the **oracle header winning any disagreement**, homonyms
  glossed distinctly, display-only and decoupled from conjugation; (C) **resolver**
  wiring so `conjugate(infinitive:tense:)` / `conjugateAll(...)` look up
  verb→class→model (keeping the `model:`-taking overloads untouched). Carries 8
  cruxes (the prefix payoff — one tener model serves detener/obtener/…; catalog ⊇
  every used number; marker stripping `(se)`/`(DEF)`/`(1)`; homonyms are genuinely
  two models; you can't eyeball 290k forms so the gate is a per-class sample +
  structural counts; canonical vs. scaffold models; the resource must actually
  ship; every verb glossed, distinctly for homonyms), the gate, and the
  `swiftc`/`xcodebuild` mechanics. Finishes the engine+data; UI is all that remains.
- **Phase 6A — the model catalog (2026-06-13).** Built `Conjugar/Models/ModelCatalog2.swift`,
  the single source of truth mapping each book class number (`"1"`, `"4B-1"`,
  `"31-1"`, …) to its `VerbModel2`. Promoted the ~95 oracle-verified exemplars out
  of the test file's `static let`s (the canonical Phase-5/5b builds, never the
  Phase-4 scaffold partials), assembled the four classes that were never test
  exemplars — **4B-1 trocar** (mostrar + o-car), **4B-5 desosar** (`d-ue-hue` on an
  -ar base → deshueso), **4B-6 avergonzar** (`d-ue-gue` + o-zar), **10 oír**
  (subir + `y-add` + `g1-ig` + `o-yhiatus`, with `g1-ig` ordered *after* `y-add` so
  it wins the subj-from-1s overlap → oigo/oiga not *oyo/*oya, plus the present-1p/
  imperative-2p hiatus accents oímos/oíd as literal residue, the two -i--initial
  -ir endings o-yhiatus's preterite-only accent slots don't reach; dropped the
  taxonomy's vestigial `a-stem`, inert on oír's vowelless "o" stem, to keep the
  §6.5 score honest) — and **aliased the prefix-accent compounds 29-2/30-1/31-1/
  32-1 to their parents** (hacer/poner/tener/venir): they need no distinct model
  because `ApocopatedImperative2` already derives satisfaz/supón/obtén/convén and
  every other feature is prefix-invariant (verified satisfecho/supuesto/obtuve/
  convino come out right on the compound stem). Refactored `Conjugator2Tests` so
  every model `static let` now *aliases* `ModelCatalog2.model(forClass:)` (the
  catalog is the thing under test); the Phase-4 tense-isolation scaffolds and the
  Phase-5b two-form-participle exemplars (freír/inscribir) stay local. Added the
  completeness invariant — a table-derived test asserting all **106** distinct
  Annex B model numbers resolve — plus full-paradigm tests for the four new builds
  and the four aliases. Verified standalone first (`swiftc` driver, 536 checks, 0
  failures), then the real target: **318 tests, 0 failures** (the 303 prior + 15
  new). Part A complete; B (the verb→model map + glosses) and C (resolver wiring)
  remain.
- **Phase 6 B/B2 — the verb→model map + glosses (2026-06-13).** Turned
  `docs/annex_b_verb_models.md` (4,818 verbs) into a shipped bundle resource the app
  loads. (B) Wrote a reproducible extractor `docs/_build_verbmap.py` that parses the
  Annex B table, strips the `(se)`/`(DEF)`/`(1)`/`(2)` markers to a bare `in` key,
  records reflexivity (`rx`), and emits an attribute-based XML
  (`Conjugar/Models/verbModelMap.xml`, mirroring Conjuguer's `verbs.xml`:
  `<verb in="abrir" cl="3-9" tn="open" />`) — **4,818 elements / 4,814 distinct
  infinitives**, the 4 homonyms carried as two elements each in **default-sense-first**
  order (crux 4: `aterrar` defaults to the regular "terrify" sense, not the book's
  first sense). Built the loader `VerbMap2.swift` (an `XMLParser` adapted from
  Conjuguer's `VerbParser`, collapsing homonym rows into one entry; loads from the
  app/test bundle or an explicit URL for the `swiftc` driver). (B2) **Glosses**: the
  oracle headers + old `verbs.xml` `tn` covered only 254; the remaining **4,556 were
  authored by a 16-agent background Workflow** (one subagent per 300-verb slice,
  writing straight to per-slice TSVs so the 4.5k glosses never entered the main
  context), then merged by the extractor — reflexive-only verbs glossed in their
  reflexive sense (arrepentir→repent, atrever→dare), homonyms glossed distinctly from
  the footnotes, **526 low-confidence ones flagged** to `docs/glosses_to_review.md`,
  the `(DEF)` verbs logged to `docs/def_worklist.md` (the `dg` hook reserved, not
  built). Schema reserves `tnr` (reflexive gloss) so the future UI can show
  ir/irse-style dual meanings with zero migration. Verified standalone (`swiftc`
  driver, 79 conjugation cases via map→catalog→model, all green) then the real
  target: **332 tests, 0 failures** (318 prior + 14 new `VerbMap2Tests`) — map loads
  from the bundle (crux 7), 0 glossless, all 106 class numbers resolve (table-derived
  from the resource, crux 2), marker-stripping, homonyms, a per-class sample, and the
  prefix payoff (detener/obtener/reconocer/descomponer/desdecir/prever/convenir/
  rehacer conjugate on their own stem). Extractor is byte-for-byte reproducible.
  **Surfaced a pre-existing Phase-5 engine defect** (logged in
  `docs/phase6_known_issues.md`, no data change needed): the `reír` (6B-4) and `oír`
  (10) catalog models use **literal** slot residue instead of end-anchored features,
  so ~8 prefixed compounds (freír/sonreír/…, desoír) lose their stem in the literal
  slots; the fix (end-anchored raise + accent) belongs to the C/engine session. C
  (wiring the no-`model:` resolver to consult the map) is all that remains of Phase 6.
- **Sequenced the finish (2026-06-13).** Split the remaining work into two sessions
  and wrote `prompts/fix-reir-oir-prefix-invariance.md` — a surgical engine fix
  (prerequisite to C) that replaces reír (6B-4) / oír (10) literal residue with
  end-anchored features: raise `e→i` + `AccentStem2.aI` (enviar's I→Í, applied to the
  raised i → río/ríes, prefix-invariant) + extend `IYHiatus2`'s accent slots to
  PI-1p/IMP-2p (oímos/oíd, reímos/reíd — a no-op for every other oYhiatus user) +
  the existing collapse. No new feature type; gets freír→frío/freído (the frito
  alternate stays out-of-scope per-verb data). Updated `prompts/phase-6-data-entry.md`
  with a STATUS banner (A + B/B2 done, the resolved Q1/Q2/Q3 decisions, C is the
  remaining work, the reír/oír fix is a prerequisite) and folded reír/sonreír/desoír
  into C's prefix-payoff crux + gate behind that prerequisite.
- **Fixed the reír/oír prefix-invariance defect (2026-06-13).** Rebuilt the `reír`
  (6B-4) and `oír` (10) catalog models end-anchored — deleted their `LiteralSlotOverride2`
  residue and composed the forms from features (`rEiStr`/`rEiWk` raise + `AccentStem2.aI`
  + `CollapseDoubleI2` + `IYHiatus2.oYhiatus`; collapse runs **before** o-yhiatus so the
  glide slots drop the double-i rather than gliding to *riyó). Extended `IYHiatus2`'s
  accent set to PI-1p/IMP-2p (oímos/oíd, reímos/reíd) — a verified no-op for every other
  o-yhiatus user (leer/caer/traer/raer/roer: -emos/-ed; construir/argüir: weak-u guard).
  All 14 compounds now conjugate on their own stem (freír→frío/frió/friendo/freído,
  desleír→deslío proving computed-not-prepended, desoír→desoímos/desoíd). 332 prior tests
  + new reír/oír paradigm & prefix-invariance cases all green (334 total, 0 failures);
  removed the VerbMap2Tests caveats and folded the compounds into its prefix-payoff gate.
  `docs/phase6_known_issues.md` marked resolved. C (the no-`model:` resolver) can now
  include reír/oír compounds in its gate.
- **Phase 6 C — wired the resolver into the conjugator (2026-06-13).** The
  no-`model:` entry points (`Conjugator2.conjugate(infinitive:tense:)` and
  `conjugateAll(...)`) now resolve a verb's model from the map instead of inferring a
  regular base from the ending: a new private `resolvedModel(for:base:)` consults
  `VerbMap2.shared` → `ModelCatalog2.model(forClass:)` (verb → default class number →
  catalog model), so an irregular verb conjugates correctly **by name alone** and a
  prefixed compound rides its base's model on its own end-anchored stem. The
  `model:`-taking overloads are untouched (the alternate-forms path and every paradigm
  test still call them directly). **Documented policies:** fallback = regular-by-ending
  for any verb outside the 4,818 (keeps every pre-Phase-6 no-`model:` test green; an
  unknown-but-regular verb still works — the `.unknownVerb` error was rejected as
  useless); homonym default = the everyday sense (`entry.classNumber`, the first sense —
  apostar→bet/apuesto, aterrar→terrify/aterro), both senses still retrievable via
  `VerbMap2` for the future UI; gloss is display-only, never read by the resolver. New
  `ConjugarTests/Models/Resolver2Tests.swift` replays VerbMap2Tests's per-class (~70)
  and prefix-payoff (~20) samples **through the verb name alone**, plus homonym
  defaults, the off-list fallback (`plopar`→plopo, asserting it's genuinely not in the
  map), invalid-input parity, a by-name == explicit-model consistency check across 10
  mapped verbs × 6 slots, and `conjugateAll`-by-name surfacing alternates (erguir
  yergo/irgo, roer roo/roigo/royo). Verified standalone first (`swiftc` driver), then
  the real target: **341 tests in 3 suites, 0 failures** (the 334 prior + the new
  resolver suite). **Phase 6 — and the entire engine+data half of the migration — is
  complete; only the UI remains.** (The optional non-gating old-engine differential
  cross-check was skipped.)

- **Gloss cleanup + worklist triage (2026-06-13).** Reviewed the two deferred
  Phase-6 review queues. `docs/def_worklist.md` (9 `(DEF)` verbs — acaecer/acontecer/
  atardecer/atañer/concernir/diluviar/granizar/soler/ventiscar) is correct and
  intentionally deferred: each is mapped to its conjugation model, defectivity left for
  the future `dg` defect-group pass (out of scope per the Phase-6 prompt), so no action.
  `docs/glosses_to_review.md` (526 model-authored low-confidence glosses, all
  display-only and decoupled from conjugation) is the human-review queue by design;
  scanning it, the only *objectively broken English* (non-words / misleading) were four:
  fixed in the slice TSVs and regenerated — abnegar deny→**renounce**, aburguesar
  embourgeois→**make bourgeois**, exorbitar exorbitate→**exceed**, usurar
  usure→**practice usury** (flags dropped; queue now **522**). The remaining ~522 are
  terse-but-plausible and stay flagged for Josh's eventual pass. Resource regenerated
  reproducibly (4,818 rows, 0 glossless); no test references the four verbs, so the
  334-test suite is unaffected.
- **Wrote `prompts/verify-glosses-workflow.md` (2026-06-13).** A self-contained prompt
  for a fresh session to run a **multi-agent `Workflow`** that verifies the ~4,556
  authored glosses against independent dictionary-grade consensus, auto-applies the
  defensible corrections, and emits a cited audit trail. Framed around the hard
  constraint that **Josh can't verify the Spanish himself** (~200 words, never formally
  studied — picked it up as an immigration lawyer, learned to *conjugate* building
  Conjugar): the workflow must be **self-validating** (confidence from multi-agent
  consensus + RAE/Wiktionary/WordReference citations, never "ask Josh"), gloss
  **blind-first** to avoid anchoring, web-ground the rare/technical/regional tail, and
  edit **only the authored `slice_*.tsv` layer in place** (oracle/old-xml/footnote
  glosses are read-only; flags clear only via in-place edits). Carries the gate
  (reproducible regen, every change cited, residual flags ≪ 522) and the Workflow
  mechanics (pipeline Phase 1, parallel N-checker Phase 2, single-step synthesis).
- **Incorporated the 4 legacy-app-only verbs (2026-06-13).** Diffed the shipping app's
  214-verb `verbs.xml` against the 4,818-verb map and found **4 neologisms** the 2010
  book predates, so absent from Annex B: **googlear** (google), **viralizar** (go viral,
  z→c → viralicé), **ustedear** (use usted), **aguachicolear** (steal water). Added an
  `EXTRA_VERBS` table to `docs/_build_verbmap.py` that appends them after the Annex B
  rows (all simple -ar: googlear/ustedear/aguachicolear = class 1, viralizar = 1-4
  cazar), so the map is now a **strict superset of both the book and the shipping app —
  no app verb regresses in the migration**. Map: **4,822 elements / 4,818 distinct
  infinitives**, 0 glossless, byte-for-byte reproducible. Updated `VerbMap2Tests`
  (count 4,814→4,818) + added legacy-verb presence/gloss/conjugation tests (incl.
  viralizar→viralicé via the map). **343 tests, 0 failures.**

# Cost & time accounting (for the blog)

**The headline (and the reason this project exists):** the Conjugar parsimony
rewrite — a *from-scratch composition conjugator* covering ~95 model classes plus
the **4,818-verb** verb→model map with glosses — was built in **~1 day** of
AI-assisted work: **~8.4 hours of active, hands-on time** spread across **~22 hours
of calendar time** (2026-06-12 09:57 → 06-13 08:08 PDT), over 16 Claude Code
sessions. **This rewrite would never have happened without AI assistance — there
simply wasn't time for it.** The comparison below makes that concrete.

**The Conjuguer baseline (the same work, by hand, in 2021).** Conjuguer's
verb-model framework and verb data entry are the closest prior-art yardstick — and
they took **~4 calendar months of part-time evenings/weekends**, per its own git
history (`/Users/josh/Desktop/workspace/Conjuguer`, branch `main`):
- **Verb-model creation** (`Conjuguer/Models/verbModels.xml`): initial commit
  **2021-01-05**; the systematic per-class commits (`add 1-2B`, `add 4-5A`, …,
  `add 5-1C, 5-27, 5-27A`) ran through **2021-03-26** (~11 weeks), with
  defective/archaic-verb support continuing into **July 2021** and final tweaks to
  **Dec 2021** — **93 commits** touching the file.
- **Verb data entry** (`Conjuguer/Models/verbs.xml`): **4** verbs on 2021-01-05 →
  **1,370** by 2021-03-26 → the bulk `add verbs` commits ran **2021-03-27 →
  2021-04-29** → **6,314** verbs by Dec 2021 (6,320 today) — **129 commits**.
- So the core French model+data effort spanned **January–April 2021**, part-time.
  (Git gives calendar dates, not hours — but the multi-month span is the point.)
  Conjugar's equivalent (a *more* capable engine — composition, not single-parent
  inheritance — plus 4,818 verbs with authored glosses) landed in a single day.

**The honest caveat: the 1-day figure rests on expertise already paid for.**
Comparing "1 day" to "4 months" is cheating a little, and the blog should say so.
Josh wasn't a fresh user prompting blind — he arrived with the hard-won conceptual
scaffolding from Conjuguer: that verb irregularities should be represented
*parsimoniously* via models, that models should **inherit/compose** rather than
repeat, that a handful of fully-regular models get conjugated in code, and that once
the model tree exists the per-verb mapping is trivial data entry. That knowledge is
exactly what's encoded in `CLAUDE.md`, `docs/spanish_taxonomy.md`, and the
carefully-sequenced phase prompts — and it is *the* expensive part. Someone meeting
Spanish-verb modeling for the first time would have burned much of their time just
*discovering* that a composition-based model tree is the right target, likely
flailing through naive representations first (one-file-per-verb, literal strings,
single-parent inheritance that can't express orthogonal irregularities) before
landing where Josh *started*. So the fair decomposition is:
- **Conjuguer (2021):** ~4 months part-time = *discovering the parsimonious approach*
  **+** *implementing it* **+** *the data entry*.
- **Conjugar (2026):** ~1 day = *implementing an approach already known* **+** *the
  data entry* — with the discovery cost already amortized.

What AI compressed dramatically was the **implementation and data-entry labor** once
the design was known — the from-scratch composition engine, the ~95 model builds, the
4,818-verb mapping, the gloss authorship, the test suites. What it did **not** do is
invent the parsimony insight; Josh brought that (the taxonomy doc and the phase
prompts are the receipts that he was doing the steering). That is arguably a *more*
credible and interesting claim than the raw speedup: **AI didn't replace the expert
judgment — it collapsed the gap between "I know how this should be built" and "it's
built and tested,"** turning a design Josh understood but *didn't have time to
execute* into a shipped thing. That is the precise sense in which "this would never
have happened without AI": not that he couldn't have figured it out (he already had),
but that the **execution time** was the blocker — and that's the part that went from
months to a day.

**Where the AI time/tokens went** (from the Claude Code session transcripts in
`~/.claude/projects/-Users-josh-Desktop-workspace-Migration/`; all 16 sessions were
launched from the `Migration` workspace, which drove the edits in `Conjugar.mig`).
"Active min" sums inter-event gaps with idle gaps >5 min dropped (best estimate of
hands-on time); a session's calendar span is much larger (it includes thinking-time
and time the human was away). All work ran on **`claude-opus-4-8`**.

| Phase / session | output tok | input tok | cache-write | cache-read | active min |
|---|--:|--:|--:|--:|--:|
| Kickoff, taxonomy, oracle transcription, Phase 1 engine | 159,977 | 7,907 | 406,133 | 6,663,821 | 70 |
| Oracle verification (Phase 0) | 202,112 | 11,698 | 555,541 | 21,761,004 | 88 |
| Groups→synchronized-folders migration | 96,458 | 10,571 | 314,484 | 17,457,137 | 41 |
| Phase 2 — orthographic/accent features | 98,163 | 10,105 | 193,742 | 9,551,651 | 28 |
| Phase 3 — stem-vowel raising | 95,263 | 10,791 | 190,233 | 4,383,301 | 20 |
| Phase 4 — 1s/preterite/future | 105,929 | 19,070 | 213,280 | 10,934,764 | 29 |
| Convert tests to Swift Testing | 109,936 | 8,534 | 164,069 | 3,914,929 | 11 |
| Phase 5 — residue + full assembly | 157,612 | 22,130 | 298,668 | 12,807,331 | 34 |
| Annex B extraction (parallel) | 29,487 | 3,277 | 61,541 | 1,537,921 | 11 |
| Planning / prompt authoring | 20,197 | 6,658 | 44,364 | 1,406,081 | 18 |
| Phase 5b — alternate forms | 116,427 | 20,289 | 236,429 | 15,779,540 | 53 |
| Phase 6A — model catalog | 78,904 | 14,351 | 319,077 | 6,082,585 | 20 |
| Phase 6B/B2 — verb→model map + glosses | 145,717 | 37,903 | 302,430 | 13,133,459 | 51 |
| reír/oír prefix-invariance fix | 32,281 | 13,108 | 114,846 | 4,104,773 | 12 |
| Phase 6C — resolver wiring | ~36,000 | ~18,000 | ~124,000 | ~4,600,000 | 15 |
| **main-thread total** | **~1,485,000** | **~215,000** | **~3,539,000** | **~134,131,000** | **~502** |
| gloss workflow (16 subagents) | 33,645 | 40,497 | 234,709 | 731,223 | ~2 (parallel) |
| **GRAND TOTAL** | **~1,518,000** | **~255,000** | **~3,774,000** | **~134,862,000** | — |

(An aborted 0-token "verify" session is omitted. Phase 6C figures are approximate —
this accounting was itself part of that session, so its counters were still rising
when measured.)

**How to read the token numbers:**
- **Output generated ≈ 1.52 M tokens** — the truest measure of work *produced*
  (every line of engine code, the taxonomy, the prompts, the test suites, the gloss
  authorship). ~1.48 M on the main thread + ~34 K from the gloss-workflow subagents.
- **Total tokens *processed* ≈ 140 M**, but **~135 M of that is cache *reads*** — the
  long conversation context re-read each turn, billed at ~10% of the input rate.
  Net *fresh* tokens (input + output + cache-writes) are only **~5.5 M**.
- **The 16-agent background gloss workflow** (Phase 6 B2, which authored the ~4,556
  glosses that had no oracle/`verbs.xml` source) is the one piece that ran as
  *subagents*, logged separately under
  `…/be8f5495-…/subagents/workflows/wf_50235957-5bf/agent-*.jsonl`. It contributed
  **~1.04 M total tokens** (~309 K fresh) in a ~2-minute parallel burst — cheap
  because each agent wrote its 300-verb slice straight to a TSV, never re-entering
  the main context.
- **Rough cost ≈ $390** at standard Opus rates (input \$15 / output \$75 /
  cache-write \$18.75 / cache-read \$1.50 per M tokens); output (~\$114) and
  cache-reads (~\$202) dominate. Treat as a ballpark — the exact `opus-4-8` price
  card isn't confirmed here.

**Caveat on "active time":** the ~8.4 h figure is derived from transcript
timestamps (gaps >5 min treated as idle); it is an estimate of engaged time, not a
billed wall-clock. The only hard numbers are the token counts and the calendar
span. Even taken loosely, the contrast holds: **~1 day, AI-assisted, vs. ~4 months,
by hand** — for a *more* capable result.

# Deferred work

- **Irregular-letter highlighting (the red "y" in *yo doy*).** The old app marks
  unexpected glyphs by hand-encoding them as **uppercase** in `verbs.xml`
  (`dOY`, `pIenso`, `llegUé`); `String.conjugatedString` then colors the
  contiguous uppercase run red and lowercases for display. The new engine
  (`Conjugator2`) returns bare lowercase strings with no such marking, so the
  capability is **not** preserved automatically — it must be re-added
  deliberately. Good news: the new architecture is *better* positioned for it.
  `compose` already captures `regularStem` (the regular baseline) before any
  feature runs, and every `Feature2` is a slot-scoped override — so the exact
  unexpected letters can be **computed** (diff the composed form against the bare
  regular root) consistently for all 4,818 verbs, rather than hand-curated for
  214 (the old hand-encoding already leaks artifacts like `toqUe`/`cueZo`/`neGUe`,
  per the verification doc). One policy decision to make when we get there:
  **(a)** highlight any letter differing from the regular baseline, or **(b)**
  highlight only letters touched by *substantive* features (stem-vowel, strong
  preterite, suppletive, irregular 1s…) while treating the pure orthographic/accent
  features (§4.1/§4.2) as silent — (b) matches the spirit of the old red-letter
  convention. **Deliberately deferred**: the policy depends on the final feature
  catalog, which Phase 5 (residue, irregular participles, imperative derivation)
  is still closing, and the only consumer is the UI layer (after Phase 6 data
  entry). Right time to design the "marked output" API (form + irregular character
  ranges, threaded through `compose`) is the seam between engine-complete and
  UI-start.
  - *Why this beats even Conjuguer.* Conjuguer uses the same uppercase=red
    convention (`ConjugationText.swift`), but there the capitals are **fused into
    the stem-alteration data** in `verbModels.xml` (e.g. `Ç`, `OIS*`, `VAIS*`,
    `ERr` in the `p` attribute do double duty: they drive the substitution *and*
    signal the color). Compact, but it welds highlight-correctness to hand-entered
    data — entered per-*model* (~95), so errors are rare but propagate to every
    inheriting verb. Conjugar's `Conjugator2` instead does pure lowercase
    composition with substitution fully decoupled from marking, so the highlight is
    *derived* (feature-vs-`regularStem` diff), not authored — this whole class of
    mis-coloring bug becomes structurally impossible, and the color can't drift
    from the conjugation because it's computed from it.
  - *Bonus — the derivation doubles as a family-wide auditor.* The same
    compute-the-irregular-letters logic can be pointed back at any app in the family
    that uses the fused-uppercase convention — old Conjugar (`verbs.xml`), Conjuguer
    (`verbModels.xml`), and the German app Konjugieren (`AblautGroups.xml`, same
    `|`-delimited alteration syntax + slot codes + `*` markers, with parent/child
    `ag` inheritance). For each model/group, derive the irregular glyphs from a diff
    against its parent, compare to the hand-entered capitals, and flag every
    disagreement as a suspected highlighting mistake. (Konjugieren is also the
    standing proof that this whole architecture generalizes past Romance: German
    strong-verb ablaut, with an oracle Josh derived from scratch since there's no
    *Verbs Made Simple(r)* for German.) Out of scope for this project, but recorded
    so the idea isn't lost.

Files created: `docs/spanish_models.md`, `docs/spanish_taxonomy.md`,
`docs/spanish_models_verification.md`, `docs/old_engine_assessment.md`,
`prompts/verify-spanish-models-oracle.md`,
`prompts/phase-2-orthographic-accent-features.md`,
`prompts/migrate-groups-to-synchronized-folders.md`,
`prompts/phase-3-stem-vowel-raising.md`,
`prompts/phase-4-irregular-1s-preterite-future.md`,
`prompts/convert-tests-to-swift-testing.md`,
`prompts/phase-5-residue-assembly.md`, `prompts/phase-5b-alternate-forms.md`,
`prompts/phase-6-data-entry.md`,
`prompts/fix-reir-oir-prefix-invariance.md`,
`prompts/verify-glosses-workflow.md`,
`docs/annex_b_verb_models.md`,
`docs/_extract_annexb.py`,
`docs/_build_verbmap.py`, `docs/glosses/*.tsv` (the authored gloss source the
extractor merges), `docs/phase6_known_issues.md`, and the regenerated outputs
`docs/glosses_to_review.md` / `docs/def_worklist.md` / `docs/glosses_missing.txt`.
In `Conjugar.mig`: the Phase 1 engine
files, the Phase 2 feature files (`OrthographicFeature2`, `AccentFeature2`) + the
Phase 3 feature file (`StemVowelFeature2`) + the Phase 4 feature files
(`StemFeature2`, `PreteriteFeature2`, `FutureFeature2`) + the Phase 5 residue file
(`ResidueFeature2`) + the Phase 5b diaeresis file (`DiaeresisFeature2`) + the
Phase 6A model catalog (`ModelCatalog2`) + the Phase 6B verb→model map
(`Conjugar/Models/verbModelMap.xml`, `Conjugar/Models/VerbMap2.swift`,
`ConjugarTests/Models/VerbMap2Tests.swift`) + the Phase 6C resolver tests
(`ConjugarTests/Models/Resolver2Tests.swift`; Phase 6C also edited
`Conjugar/Models/Conjugator2.swift`) + `Conjugator2Tests` (committed on
`migration`).
Files modified: `CLAUDE.md`, `docs/blog_notes.md`, `docs/spanish_models.md`.
---

## 2026-06-13 — Gloss verification, Phase 1 (blind gloss + compare)

Ran Phase 1 of the multi-agent gloss-verification workflow (`prompts/verify-glosses-workflow.md`)
as a background `Workflow`: a 16-slice pipeline, two agents per slice. Stage 1
("blind") read only `docs/glosses/phase1/blind_*.tsv` (infinitive + reflexive flag,
**no current gloss** — the anti-anchoring guarantee) and wrote a fresh terse gloss
to `blindout_*.tsv`. Stage 2 ("compare") — a *separate* agent — joined blind vs.
current and classified each verb `agree`/`replace`/`uncertain`, writing
`docs/glosses/phase1/verdicts_*.tsv`.

Result across all **4,556** authored glosses: **4,470 agree, 46 replace, 40
uncertain**. Verified structurally: every `verdicts_*.tsv` covers exactly its
slice's infinitives (set-equal) with the `current` column copied verbatim; only one
verb (`engurruñar`) slipped the blind stage but the compare stage still glossed it.
Caveat for Phase 2: the compare agents dropped the flag column on ~10 verbs, so the
flagged set must be re-derived from the authoritative `slice_*.tsv` col-3, not the
verdict flag column. Built the Phase 2 handoff `docs/glosses/phase1/phase2_candidates.tsv`
— the **549**-verb contested∪flagged union (46 replace, 40 uncertain, 522 flagged;
463 flagged verbs the blind pass would keep, 59 flagged that are also contested).
No slices edited yet (Phase 1 is read-only analysis); no engine/conjugation change.
Cost: 32 agents, ~684k subagent tokens, 169 tool calls, ~4.5 min wall.

## 2026-06-13 — Gloss verification, Phase 2 (adversarial grounded consensus)

Ran Phase 2 on the 549-verb contested∪flagged set as a background `Workflow`: 35
chunks of ~16 verbs, each verified by THREE independent diverse-lens checkers in
parallel — RAE-first (`dle.rae.es`→`es.wiktionary` fallback), Wiktionary/WordReference,
and morphology+everyday-vs-technical — then a per-chunk consensus agent reconciled
them. Checkers web-grounded the rare/technical tail and cited a dictionary URL +
the Spanish sense it supports; consensus rule = ≥2/3 on the same sense with ≥1
citation (rare verbs **must** carry a URL or get downgraded to flag).

Hit the monthly spend limit ~60% through (chunks 19-34 + all consensus failed);
Josh raised the cap to $120 and I **resumed via `resumeFromRunId`** — the 18 already-
completed checker chunks returned from journal cache, only the failed agents re-ran.

Result across 549 verbs: **468 keep, 80 replace, 1 residual flag** (`chamullar` —
mumble vs jabber vs sweet-talk, no majority sense). Consensus was strong: 517/549
unanimous 3/3, 32 at 2/3. Web-grounded ~518 of them with cited es/en-Wiktionary or
RAE URLs. One consensus row (`almohazar`→curry) was dropped by its agent and
reconstructed by hand from the unanimous 3/3 checker verdicts. The 80 replacements
fix real false-friends (`prevaricar` prevaricate→abuse one's office, `militar`
militate→serve in military, `depilar` depilate→remove hair), word-class slips
(`amanerar` mannerism→make mannered, `apellidar` surname→name), and the denominal/
technical tail (`opositar`→sit competitive exam, `banderillear`→place banderillas).

Outputs (all under `docs/glosses/phase1/phase2/`): `checks/{rae,wikt,morph}_chunk_*.tsv`
(105 checker files), `consensus/consensus_chunk_*.tsv` (35), and merged
`consensus_all.tsv` (549 rows, the Phase 3 handoff). No slices edited yet — Phase 3
applies the 80 replaces (minus any whose gloss is oracle/old-xml-sourced = out-of-
bounds, report-only), clears confirmed flags, and writes the audit report. Cost:
140 agents (cache-resumed), ~4.4M subagent tokens total across both runs, ~3.2k tool
calls, ~27 min wall over the two runs.

## 2026-06-13 — Gloss verification, Phase 3 (apply + audit)

Applied the Phase 2 consensus to the authored slices (no agents — a deterministic
Python pass; cheap). All 549 contested verbs are authored-layer (oracle/old-xml/
footnote split = 0), so **all 80 replacements applied cleanly** with zero out-of-
bounds slice edits. `_phase3_apply.py` rewrote `slice_*.tsv`: 80 glosses replaced,
**521 flags cleared** (confirmed by consensus), 1 flag kept (`chamullar`).

Regenerated `verbModelMap.xml`: 4,818 rows, 0 glossless, missing empty, homonyms
intact (8 senses), reflexive 113. **Flagged for review: 522 → 1.** Re-running the
script is byte-identical (reproducible). Gate checks: 0 `tn` starting "to "; spot-
checked replaces landed (depilar→remove hair, militar→serve in military, prevaricar→
abuse one's office, sesear→pronounce s for c).

One gate caveat surfaced + documented: **24 `tn`s carry a comma** — ALL from the
legacy `verbs.xml` (source 2, read-only), pre-existing two-sense glosses for common
verbs (`deber: owe, must`). A slice edit is a no-op there, and blind `terse()` would
drop the *better* sense for some (deber→"owe"), so they're **report-only** in the
"needs human decision" section, not auto-edited. The single-sense pick is an English
call Josh can make.

Deliverables: corrected `docs/glosses/slice_*.tsv`, regenerated `verbModelMap.xml`,
`docs/gloss_verification_report.md` (80 changes + 460 confirmed-flags + 1 residual +
24 out-of-bounds, all with citations/agreement counts), `docs/glosses_to_review.md`
shrunk to 1. Phase 3 token cost negligible (deterministic). Test gate: VerbMap2Tests.

## 2026-06-13 — Frequency ranks into the verb map (`fr` attribute)

Brought `docs/SpanishVerbFrequencyRanks.txt` (1,000 `infinitive,rank` lines, 1=top)
into `verbModelMap.xml` so the UI can show frequency the way Conjuguer does. Chose
to carry it as a new optional `fr` attribute on the existing `<verb>` rows rather
than a separate `frequencies.xml` (Conjuguer's approach) — the map already keys on
the bare infinitive, and the schema was designed for exactly this kind of optional
add-on. Like `tn`, `fr` is **display-only and can never affect a conjugation**.

Done through the build pipeline (the file is generated, "do not edit by hand"), not
by hand-editing the XML. `_build_verbmap.py` gained `load_frequency_ranks()` and
emits `fr="N"` when an infinitive is ranked, omitted otherwise (absence = outside
top 1000). Homonyms (apostar etc.) get the same `fr` on both rows — rank is per
spelling, not per sense. **981 of the 1,000 ranked verbs matched** a map row; the
19 misses are written to `docs/freq_unmatched.txt` for a human pass — almost all
corpus junk/non-verbs (también, están, aquí, iphone, on, á, ende, linear, pilar),
plus a few real-but-absent verbs worth a look (circular, quejar→quejarse?, egresar,
respectar, adir, rodrigar, paular, salgar, pablar, hacendar).

Swift side: `VerbMapEntry2` gained `frequencyRank: Int?`, parsed from `fr` in
`VerbMapParser2` (homonym merge keeps the first row's rank). Added a frequency-rank
test section to `VerbMap2Tests` (top ranks present, unranked verbs nil, exactly 981
distinct ranks in 1…1000). Next: surface it in the (future) Models/verb-browse UI,
mirroring Conjuguer's `VerbSort`/`VerbView`. Re-running the script is reproducible.

**Follow-up — closed 6 of the 19 gaps.** Reviewed `freq_unmatched.txt`: of the 19,
13 are corpus junk/non-verbs (también, están, aquí, á, on, iphone, ende, linear,
pilar, paular, rodrigar, salgar, pablar) and stay dropped. The other 6 are real
verbs Annex B simply omits, so I added them via a new `FREQ_GAP_VERBS` list in
`_build_verbmap.py` (same mechanism as the legacy neologisms): **circular** (510,
circulate), **quejar** (693, complain — reflexive), **egresar** (842, graduate, Lat.
Am.) are everyday; **respectar** (970), **adir** (985), **hacendar** (465) are rare.
Of those, **respectar and adir are defective** — recorded via a new `EXTRA_DEFECTIVE`
set so they land in `def_worklist.md` alongside the 9 Annex B defectives (11 total).
Defectivity is still **not enforced** by the engine (the engine over-generates their
missing forms for now); full defect-group support is a later phase, mirroring
Conjuguer. Map now: 4,828 elements / 4,824 distinct infinitives, **987 of 1,000
frequency-ranked**. Tests updated (counts + a frequency-gap suite). Reproducible.

## 2026-06-15 — Folded the Migration workspace into the repo

With the verbs and the new engine done, the parsimony work has reached the UI
phase, and the two-folder split (a non-git `Migration/` workspace driving edits in
the `Conjugar.mig` repo) had outlived its usefulness. Copied `docs/`, `prompts/`,
and `tools/` from `Migration/` into `Conjugar.mig/` so the repo is now the single
source of truth — development happens here exclusively. (`Migration/`'s own
`CLAUDE.md` stayed behind, since it described that workspace specifically.)

Fixed the references the move invalidated: a stale `.../Migration/docs` path comment
in `_build_verbmap.py`; a `cd .../Migration/docs` run line and the
"slices/report/blog live in the non-git Migration workspace" deliverable note in
`verify-glosses-workflow.md`; and the "(Migration workspace — not a git repo)"
qualifiers in the phase prompts' Deliverable sections — those docs now live in this
git repo and get committed alongside the code. The Python pipeline's relative paths
(`WORKSPACE = dirname(dirname(HERE))`, then rejoin `Conjugar.mig/...`) resolve
correctly from the new `Conjugar.mig/docs` location, so only the comment needed
touching. Left two dated, past-tense Migration references intact as historical
records: the token-accounting table here (it cites the real
`~/.claude/projects/-Users-josh-Desktop-workspace-Migration/` transcript path) and
the 6/12 oracle-prompt Q&A.

## 2026-06-15 — Smoke-tested the build/test commands in the new home

First session run from `Conjugar.mig` itself (rather than the old `Migration`
workspace), so the first order of business was confirming the project still
builds and tests cleanly from its new home using the commands now documented in
`CLAUDE.md`. **Build succeeded.** Ran the full unit-test surface — both the
**Swift Testing** new-engine suites (`Conjugator2Tests`, `Resolver2Tests`,
`VerbMap2Tests`): **348/348 passing** — and the **XCTest** legacy suites:
**52/53**, the lone failure being `TestGameCenterTests.testAuthenticate`, which
**passes in isolation** (it's an order-dependent flake in a Game Center test
stub, not a regression in any code under test — the new engine and data are
fully green). The `ConjugarUITests` target fails (6/6, can't locate the tab bar:
`QuizVCUITests.swift:48`), but those are UI tests, pre-existing and independent
of the migration. Net: the new home is a working build/test environment, and the
`CLAUDE.md` command incantations (explicit `-project`, iPhone 17 destination,
`-parallel-testing-enabled NO`, the mixed XCTest/Swift-Testing `-only-testing:`
formats) are correct as written.

While here, did some housekeeping on the freshly-folded-in `docs/`: gitignored
and pruned the gloss-pipeline scratch artifacts that had been committed wholesale
with the workspace fold (`docs/glosses/.bak_phase3/` backup slices, the
`phase1/phase2/chunks/` inputs, and the per-checker `phase2/checks/` +
`phase2/consensus/` chunk outputs — all regenerable and preserved in the
`Migration` backup), keeping the concatenated `consensus_all.tsv` deliverable.
Also gitignored Python `__pycache__`/`*.pyc` and the two commercial reference
PDFs (`*.pdf`) so they stay out of the eventual public `master` merge.

## 2026-06-15 — Removed the dead UI-test target

The `ConjugarUITests` target had been failing wholesale (6/6, couldn't find the
tab bar) and was never part of the migration's test strategy, so Josh deleted the
`ConjugarUITests/` folder. Deleting the folder leaves the Xcode project still
*defining* the target, so excised every `ConjugarUITests` reference from
`Conjugar.xcodeproj/project.pbxproj` by hand — the native target, its product
file reference + Products-group entry, the Sources/Frameworks/Resources build
phases, the target dependency + its container-item proxy, the two
`XCBuildConfiguration`s and their `XCConfigurationList`, the `TargetAttributes`
entry, and the `targets` list membership — plus the `TestableReference` in the
shared `Conjugar.xcscheme`. (The `xcodeproj` Ruby gem that drove earlier project
edits **can't be used here**: v1.23.0 chokes on `PBXFileSystemSynchronizedRootGroup`,
the objectVersion-70 synchronized-folder format this project adopted in the
groups→folders migration, so the edits were surgical hand-edits instead.)
`xcodebuild -list` now shows exactly two targets (`Conjugar`, `ConjugarTests`),
and the plain `test` command — no `-only-testing:` needed — runs clean: **XCTest
53/53 + Swift Testing 348/348, 0 failures**, with no UI-test phase attempted.

The deeper reasoning: over the years Josh has consistently found UI tests flaky
(this target was no exception — its failures were environmental, not real
regressions), so they earn their keep poorly. The plan for exercising Conjugar's
UI isn't XCUITest at all — eventually the `ios-build-verify` skill will drive the
actual UI. That, however, requires the app to be **fully converted to SwiftUI**
first (today only Settings is SwiftUI; the rest is programmatic UIKit), so it's
downstream of the UI-modernization phase that still follows the engine+data work.
Until then, removing the dead XCUITest target is pure subtraction — no coverage
lost, one less source of red.

## 2026-06-15 — Renamed the test doubles to Fowler-consistent names

Reworked the World DI layer's protocol conformances so the test doubles follow
Martin Fowler's test-double taxonomy (dummy/fake/stub/spy/mock) and — the practical
payoff — so related files finally **sort together in Xcode's Project Navigator**,
the `CatFancy-final` convention: protocol = plain noun, conformers = `<Protocol>Real`
for production and `<Protocol><FowlerType>` for the double. Six service protocols,
each double classified by what it actually does:

- **`GetterSetter`** (kept): `UserDefaultsGetterSetter`→`GetterSetterReal`,
  `DictionaryGetterSetter`→`GetterSetterFake` (a working in-memory dictionary = a
  **Fake**).
- **`CommunGetter`** (kept): `CloudCommunGetter`→`CommunGetterReal`,
  `StubCommunGetter`→`CommunGetterStub` (canned `Commun` objects = a **Stub**).
- **`GameCenterable`→`GameCenter`**: the GameKit class `GameCenter`→`GameCenterReal`,
  `TestGameCenter`→`GameCenterFake` (keeps a working auth-state machine — `authenticate`
  returns true-then-false — = a **Fake**).
- **`ReviewPromptable`→`ReviewPrompter`**: the struct `ReviewPrompter`→
  `ReviewPrompterReal`, `TestReviewPrompter`→`ReviewPrompterStub` (an empty no-op =
  a **Stub**).
- **`Locale`→`AnalyticsLocale`**: `RealLocale`→`AnalyticsLocaleReal`,
  `StubLocale`→`AnalyticsLocaleStub`.
- **`AnalyticsServiceable`→`AnalyticsService`** (not in the original ask — caught
  during the sweep): `TestAnalyticsService`→`AnalyticsServiceSpy` (an injectable
  `fire` closure records every event for test assertions = the textbook **Spy**). No
  production impl yet — a TelemetryDeck-backed `AnalyticsServiceReal` is still planned.

Two findings worth recording. (1) The `Locale` protocol **shadowed
`Foundation.Locale`** module-wide — the tell was `RealLocale` reaching for
`NSLocale.current` to dodge the collision. Renaming the protocol (to `AnalyticsLocale`,
Josh's call) clears the shadow. (2) Two renames are name *swaps*: the protocol takes a
name its concrete type already held (`GameCenterable`→`GameCenter`,
`ReviewPromptable`→`ReviewPrompter`), so the concrete type had to vacate to `…Real`
**before** the protocol could take the freed name — sequenced that way in both the text
pass and the `git mv`s.

Mechanics: a single ordered `perl` pass over every tracked `.swift` (word-boundary
matches where substrings would otherwise collide — `\bGameCenter\b` must not touch
`GameCenterable`/`TestGameCenter`/`GKGameCenter*`) renamed the types and references;
`git mv` renamed the 19 files (the four `…Tests` files included). Because the project
uses `PBXFileSystemSynchronizedRootGroup`s, the file renames needed **zero
`project.pbxproj` edits** — the synchronized groups auto-discover. Build succeeded;
**XCTest 53/53** and the full `test` action green (**TEST SUCCEEDED**, 0 failures); the
Swift Testing engine suites are untouched by the rename.

Checked and left out of scope (not behavior-protocol/double pairs): `Feature2` (an
engine strategy protocol with many domain conformers), the `QuizDelegate`/`InfoDelegate`
delegates, and `URLProtocolStub` (stubs Foundation's `URLSession`). Noted one stray:
`MockNavigationC` is actually a **Spy** (it records `pushedViewController`), so it's
mis-labeled under Fowler — flagged for a future cleanup. Also updated `CLAUDE.md`'s
architecture section to the new names.

**Follow-up (same session).** Codified the rule in `CLAUDE.md` (protocol = plain role
noun; `<Protocol>Real` + the Fowler-typed double; check for system-API shadowing; wire
into `World`) so new behavior protocols follow it, then applied the two loose ends:
(1) **dropped the `NSLocale.current` workaround** — with the shadow gone,
`AnalyticsLocaleReal` reads `Locale.current.language.languageCode` / `Locale.current.region`
directly; and (2) **renamed the mis-labeled `MockNavigationC`→`NavigationCSpy`** (a
`UINavigationController` subclass that records `pushedViewController` — a Fowler **Spy**,
not a mock; its two call sites in `BrowseVerbsVCTests`/`BrowseInfoVCTests` updated). The
SourceKit indexer briefly flagged `AnalyticsLocale` as unresolved mid-rename, a stale-index
artifact — a clean build disproved it. Rebuilt: **53/53 XCTest, 0 failures**
(`TEST SUCCEEDED`).

---

## Frequency-list cleanup + closing the top-990 coverage gap

Started from a raw corpus dump (`estenten23_fl6`) exported as `docs/verbs.csv`:
three header rows (`corpus`/`subcorpus`/`Item`) plus 1000 `"lemma",freq,relfreq`
rows. Rewrote it as a clean, sequentially **ranked** `verb,rank` file — `ser,1` …
`penetrar,990`. Pruning the corpus junk cost 13 lines: 3 export headers and 10
non-verbs embedded in the lemma list — adverbs (`tambien`, `aqui`), an inflected
form (`estan`), a brand (`iphone`), noise (`on`, `ende`), a noun (`pilar`), an
adjective (`linear`), and two lemmatizer artifacts (`pablar`, `paular`). Kept the
obscure-but-real verbs the corpus surfaced (`jamar`, `salgar`, `rodrigar`, `adir`,
`musicar`, `matear`, …); a UTF-8 BOM on line 1 initially smuggled `corpus` through
as rank 1, caught and re-ranked.

Then checked those 990 against the **new engine's** coverage — `verbModelMap.xml`
(4,828 entries), *not* the legacy `verbs.xml` (214 model verbs). Only **3** were
missing: `rodrigar` (stake plants), `salgar` (salt livestock), `matear` (drink
mate) — all regular, which is exactly why a hand-curated model map might skip them.
Added all three: `rodrigar`/`salgar` as `cl="1-2"` (regular `-gar`, g→gu before *e*,
like `pagar`/`cargar` — 160 such entries) and `matear` as `cl="1"` (regular `-ear`,
like `rodear` — 2,978 such entries), each inserted in alphabetical position with a
terse `tn` gloss. `rodrigar` and `salgar` turned out to sit at ranks 784 and 994 in
the existing `fr` scheme (sourced from `SpanishVerbFrequencyRanks.txt`) — two of that
scheme's 13 gaps — so they were restored with `fr="784"`/`fr="994"`; `matear` isn't
in that source, so it carries no `fr`. XML re-validated (`xmllint`), entry count
4,828 → 4,831, and the CSV-vs-engine diff now reports **full coverage of the top 990**.

---

## G-rating the verb data

The app is G-rated, so pulled the R-rated verbs out of the data. `chingar` (named in
the request) turned out to already be absent. Rather than eyeball 4,800+ Spanish
infinitives, scanned the **English `tn` glosses** in `verbModelMap.xml` for
vulgar/sexual/scatological terms (`shit`, `screw`, `fornicate`, `masturbate`,
`fondle`, `deflower`, `rape`, …), then did a second pass on notorious vulgar Spanish
verbs that might hide behind a *clean* gloss. **Removed 16:** `cagar`, `copular`,
`desflorar`, `desvirgar`, `erotizar`, `estuprar`, `eyacular`, `follar`, `fornicar`,
`joder`, `manosear`, `masturbar`, `mear`, `prostituir`, `putear`, `toquetear` — from
`verbModelMap.xml`, plus `joder` from `docs/verbs.csv` (re-ranked: now 989, ending
`penetrar,989`) and `docs/SpanishVerbFrequencyRanks.txt`.

The interesting part was what **not** to remove: many core verbs carry vulgar *dialectal*
slang but an innocent primary meaning + gloss, so they stayed — `coger` (grasp; the
Latin-American vulgar sense is dialectal), `correr` (run), `tirar` (throw), `penetrar`
(penetrate), `montar` (mount), `chupar` (suck), `clavar` (nail), `cascar` (crack),
`sobar` (rub). The rule that fell out: remove when the word is *inherently* profane
(`putear` ← *puta*) or its glossed meaning is sexual/scatological; keep when only a
dialectal slang sense is off-color. `xmllint` re-validated; entry count 4,831 → 4,815.

Left in but **flagged for Josh to decide** (borderline, not clearly R-rated):
`violar` (violate/rape — but the standard word for violating a law/right, rank ~678),
`seducir` (seduce — often figurative), `orinar`/`defecar` (clinical), `capar`/`castrar`
(veterinary), `circuncidar` (medical/religious), `mamar` (suckle).

---

## Status check: engine "done", plus fixing the fallout from the data edits

Assessed whether the new engine is finished. Verdict: the **engine** is — 4,811
distinct verbs, zero `TODO`/`FIXME`/`fatalError` markers, ~350 passing tests — but it
is **not wired into the app**: the UI still conjugates through the legacy `Conjugator`
(`verbs.xml`, 214 verbs) via `ConjugationDataSource`; `Conjugator2` is referenced only
by `Models/` + tests. Updated `CLAUDE.md` to say exactly that (engine complete;
app-integration is the remaining migration step) rather than a flat "done" that would
imply the app already uses it. Also corrected the stale count — the overview said
"more than 4,800"; actual distinct count is 4,811.

The earlier data edits (+3 coverage verbs, −16 R-rated) had silently invalidated two
`VerbMap2Tests` count assertions: distinct infinitives `4824 → 4811`, and ranked-verb
count `987 → 988` (the two frequency-gap fills rodrigar@784/salgar@994 added a rank
each; removing `joder` dropped one). Updated both assertions and their derivation
comments, then ran the three new-engine suites: **348 tests, TEST SUCCEEDED**. Lesson
worth a line in the post: a hand-edited data resource has a test contract, and
"add 3 / remove 16" quietly broke it two files away.

---

## Scoping the Conjugator2 app-migration (wrote a fresh-session prompt)

Wrote `prompts/migrate-app-to-conjugator2-and-sortable-browse.md` for a future session
to (A) move the app off the legacy `Conjugator`/`verbs.xml` onto `Conjugator2` and (B)
rebuild Browse Verbs as an all-verbs list sortable by Frequency/Alphabetical, modeled on
the Conjuguer French app. Kept it UIKit — the SwiftUI conversion is a later step.

Scoping surfaced the parts that make this more than a find-and-replace of
`Conjugator.shared`:
- **Tense-coverage gap (the crux).** `Tense2` only covers *simple* tenses + participle
  + gerundio; the app's conjugation grid also shows the **compound/perfect** tenses,
  `futuro de subjuntivo`, and `imperativo negativo`. A naïve swap silently drops rows.
  Recommended composing the compounds in-app (`haber` in tense T + participle) rather
  than extending the engine.
- **VerbVC's non-conjugation affordances** have no public Conjugator2 equivalent:
  `raízFutura`, `isDefective`, `verbType`, and especially `parent` — "parent verb" is a
  legacy modeling idea the class-number engine simply doesn't have, so that label needs
  a redesign. Enumerated each with a mapping (gloss ← `VerbMap2`, verbType ← class
  number) or a "add an accessor" note.
- **Voseo checked, not assumed:** `PersonNumber2` includes `secondSingularVos` and
  `ModelCatalog2` carries `ves`/`sos`, so vos is genuinely supported.
- The 7 remaining `Conjugator.shared` call sites (Quiz, QuizVC, VerbVC, data source,
  browse) are inventoried in the prompt as the migration checklist.

---

## Part A: the app now conjugates through Conjugator2 (legacy engine dormant)

Executed Part A of the migration prompt: **every app/UI call site is off
`Conjugator.shared`** — `ConjugationDataSource`, `Quiz`, `QuizVC`, `VerbVC`, and
`BrowseVerbsVC` now speak to the new engine. The legacy `Conjugator`/`verbs.xml` stay
in the target, compiling but unreferenced (retiring them is the agreed later cleanup).

**The bridge.** The UI is still structured around the legacy `Tense`/`PersonNumber`
vocabulary, so a new `TenseBridge` maps each legacy slot onto the new engine: the ten
simple tenses map case-for-case onto `Tense2`; the three tense families `Tense2`
deliberately doesn't model are composed at the bridge layer — the nine **compound
tenses** via a `CompoundTense` helper (haber in the matching simple tense + invariant
participle, reusing the legacy `haberTenseForCompoundTense()` table), **imperativo
negativo** as "no " + presente de subjuntivo, and **futuro de subjuntivo** derived from
the computed -ra imperfect subjunctive by an ending swap (hablara → hablare,
tuviéramos → tuviéremos) so strong preterite stems ride through for free. Defective
slots surface as `.noForm` and render as blank rows — the role the legacy `"df"`
sentinel used to play.

**Irregularity highlighting had to be reconstructed.** A one-day surprise: the legacy
engine's output strings *are* the highlighting — verbs.xml hand-encodes irregular
letters as UPPERCASE (`abIERTo`, `hE`, `tUVieron`) and `conjugatedString` renders that
as the red span. Conjugator2 emits plain lowercase, so a naïve swap silently loses a
signature UI feature. New `IrregularityMarker` recreates the encoding mechanically:
diff each form against the verb's **regular composition** (same verb, feature-less
model — an entry point the engine already had) and uppercase the differing span, word
by word so compound auxiliaries and participles mark independently. The mechanical
spans match the hand-authored ones remarkably often (`hE`, `hUbiera`, `vUELTo`,
`abIERTo`, `VAYamos`).

**New public accessors** for VerbVC's affordances: `Conjugator2.futureRoot` (future 1s
minus its invariant `-é`), `Conjugator2.isDefective` (any feature suppresses any slot),
`Conjugator2.verbType` (class 1/2/3 = regular AR/ER/IR, everything else irregular),
and `ModelCatalog2.exemplar(forClass:)` — the class-number → model-verb name that
replaces the legacy "parent verb" label (reconocer now shows "Irreg. ☛ conocer" via
the class-7A exemplar rather than a parent chain; a verb that *is* its class exemplar
just shows "Irregular").

**The throwaway parity test earned its keep.** Compared the bridged engine against the
legacy engine over all 213 legacy verbs × the full displayed grid (30,033 slots), then
deleted it as planned. It caught three real new-engine bugs before any user could:
1. **The -ducir family was broken by name** — conducir's strong-preterite feature
   anchored on `conduc`, which no *other* -ducir stem ends with, so `aducir` yielded
   *aduce* instead of *aduje*. Re-anchored on the shared `duc` tail (the end-anchored
   §1 payoff, properly applied); 8 verbs × 28 slots fixed.
2. **Voseo silently lost features in the tú-fallback tenses** — the slot sets exclude
   vos by design for the present/imperative, but that meant *dormas* for `duermas`,
   *caiste* for `caíste`, *ías* for `ibas`. Fixed in one place: `conjugateOne` now
   canonicalizes a vos slot to tú outside the presente de indicativo and affirmative
   imperative, so every feature rides along.
3. **Catalog voseo gaps** — haber lacked its irregular vos present (`has`, so compound
   vos rows read "habés hablado"), ir lacked `vas`/`andá`, dar lacked unaccented
   `das`/`da`. Added as residue literals, following the existing ser `sos` / ver `ves`
   pattern.
The remaining ~1,500 mismatches were all **legacy defects the new engine corrects**
(sampled and categorized): missing orthographic changes (*sacé* → `saqué`, *distinguo*
→ `distingo`), missing hiatus accents (*leiste/traido/ibamos* → `leíste/traído/íbamos`),
y-hiatus (*leió* → `leyó`), data typos (*abracemosa*, *juegua*, *adquire*, haber's
imperative *habe* → `he`, venir's *veniendo* → `viniendo`), wrong persons (*salga* for
ellas → `salgan`), and RAE-mandated accents legacy dropped (suponer tú imperative
*supon* → `supón`). Plus two deliberate modeling changes worth a blog paragraph: verbs
that were "defective by data" (gustar, llover, amanecer — third-person-only usage) now
conjugate fully, since the new engine reserves defectiveness for paradigm gaps (the
abolir class); and freír's primary participle is `freído` (frito is Annex-B per-verb
data, out of scope), roer's is `roo` (roigo/royo remain as alternates).

**Browse** now lists all 4,811 mapped verbs (regular = class 1/2/3, everything else
irregular) — Part B will replace the 3-way filter with Frequency/Alphabetical sorting.
Quiz answers grade through the bridge (its test double now answers via the bridge too,
since the legacy engine's known-wrong forms would fail an engine-vs-engine quiz).

Verified: full suite green (361 Swift Testing + all XCTest, including new
`TenseBridgeTests` and `Conjugator2AccessorsTests`), and drove the app in the
simulator — abnegar shows "Irreg. ☛ negar" with red `abniego`/`abnegué` spans and the
full compound table down to futuro perfecto de subjuntivo, abolir shows "Defective"
with correctly blank person rows, and the quiz graded *habran* as a partial match for
`habrán` with the irregular r in red.

## Part B: Browse Verbs is now an all-verbs list, sortable by Frequency / Alphabetical

Rebuilt the Browse tab around the new engine's verb map, mirroring the UX of my French
app Conjuguer's `VerbBrowseView` (adapted to Conjugar's programmatic UIKit, not
SwiftUI). The old 3-segment irregular/regular/both filter over ~214 verbs is gone;
Browse now lists **all 4,811 `VerbMap2` entries** with two sorts:

- **Frequency** (the default): ranked verbs first, ascending by `frequencyRank` —
  *ser* #1, *haber* #2, *tener* #3 — with the ~3,800 unranked verbs after the ranked
  block, alphabetized among themselves. The comparator replicates Conjuguer's
  nil-handling exactly.
- **Alphabetical**: locale-aware `compare(_:locale:)` with a Spanish locale, so *ñ*
  sorts as its own letter between *n* and *o* (a plain code-point compare would dump
  *ñoñear* after *obrar*; the test asserts this).

Implementation notes:

1. **`VerbSort`** (`Models/VerbSort.swift`) — a `CaseIterable` string enum
   (`.frequency` / `.alphabetical`) that owns both comparators and localized segment
   titles ("Frequency"/"Frecuencia", "Alphabetical"/"Alfabético"). `BrowseVerbsVC`
   precomputes both sorted arrays once in `loadView` (Conjuguer's `itemsBySort` idea);
   toggling the control just swaps which array backs the table and calls the existing
   `reloadTableData()`, which also resets scroll to top.
2. **Persistence** — a new `Settings.verbSort` (GetterSetter-backed UserDefaults,
   default `.frequency`), written on every segment change and read to select the
   initial segment. Same pattern as `secondSingularBrowse`.
3. **`VerbCell`** grew from a single centered infinitive to Conjuguer's row shape:
   yellow infinitive + blue gloss stacked at the leading edge, blue `#rank` at the
   trailing edge (omitted for unranked verbs). Spanish accessibility label kept.
4. Nothing references `Conjugator.shared.allVerbs/regularVerbs/irregularVerbs` anymore;
   the legacy engine is fully dormant (removal remains a separate cleanup).

Skipped for now: the optional `UISearchController` parallel to Conjuguer's
`.searchable` field — the sort requirement stood alone, and search is a clean
follow-up. Also worth a follow-up: the Info tab's "Purpose & Use" copy still describes
the old three-list Browse UI in both languages.

New tests: `VerbSortTests` (rank ordering, nil-rank alphabetization, Spanish collation,
ser-is-#1 over the real map), `SettingsTests` (verbSort default + round-trip), plus
updated `VerbCellTests` and `BrowseVerbsVCTests`. Full suite green (365 Swift Testing
tests + all XCTest suites). Drove it in the simulator with idb: frequency order shows
ser/haber/tener with ranks, tapping Alphabetical re-sorts instantly (*abajar* first,
*abandonar* keeps its #287 badge), the choice survives relaunch, and tapping *abajar* —
a verb the legacy engine never knew — pushes a fully rendered Conjugator2-powered verb
screen.

## Purpose & Use copy updated for the new Browse; run-in-simulator skill

The Info tab's "Purpose & Use" text still described the old Browse UI ("three lists
of Spanish verbs… swap these lists"). Rewrote that paragraph in both languages to
describe the new reality: thousands of verbs with English translations, frequency
ranks (ser is #1), and the Frequency/Alphabetical sort control. Amusing archaeology:
the English fallback copy existed in *two* places — `Info.swift` (the one actually
rendered) and an apparently vestigial duplicate in `Localizations.swift` — and they
had already drifted ("yellow button" vs. "red button"). Updated both, plus the
Spanish in the UTF-16 `Localizable.strings` (edited via a small Python script, since
the file's encoding defeats normal text tools).

Also captured the simulator-driving recipe from the Part B verification as a project
skill, `.claude/skills/run-in-simulator/SKILL.md`: resolve the built .app, pin one
booted-simulator UDID (several sims are named "iPhone 17"), simctl
install/launch/screenshot, tap with idb in points (screenshot pixels ÷ 3), and the
traps — the lingering launch screen, and the fact that `simctl spawn defaults write`
never reaches the app's sandboxed UserDefaults (change state through the UI instead).
Noted in CLAUDE.md that ios-build-verify will supersede this skill after the SwiftUI
conversion. Verified both localizations on-device: navigated Info → Purpose & Use in
English and (via `-AppleLanguages "(es)"`) in Spanish; markup, red/blue spans, and
the new sentences all render.

## The legacy engine is gone

With the app fully on Conjugator2 and display parity confirmed, deleted the legacy
engine: `Conjugator.swift`, `ConjugatorError.swift`, `VerbParser.swift`, the 214-verb
`verbs.xml`, and `ConjugatorTests.swift`. An audit first mapped every remaining
reference — all comments except one live call the `Conjugator.shared` grep never
caught: `ConjugationCell` still compared against `Conjugator.defective`, the legacy
"df" sentinel for defective slots. That check is dead on the new engine (the data
source renders a formless slot as an empty string), so it's simply removed.

What deliberately stays: `Tense.swift` and `PersonNumber.swift` (the vocabulary the
UI still speaks, bridged to `Tense2` by `TenseBridge`), `VerbType` (now fed by class
numbers), and `CompoundTense`. The app bundle now ships a single verb-data XML,
`verbModelMap.xml`. Full suite green (365 tests) and a simulator smoke test confirmed
Browse → verb screen works with only the new engine aboard. CLAUDE.md's project
overview now reads "migration done" instead of "not yet wired in."

## Renamed Tense → DisplayTense, Tense2 → EngineTense

With the legacy engine gone, the "2" suffix on `Tense2` no longer signaled
"the new one of two" — and plain `Tense` undersold what the type had become. The
new names state their roles: **`DisplayTense`** is the user-facing tense taxonomy
the UI and quiz speak — the full 16+ set, including the compound tenses, futuro de
subjuntivo, and imperativo negativo that the engine deliberately doesn't model.
**`EngineTense`** is what `Conjugator2` consumes: simple-tense-plus-person slots
like `.presenteDeIndicativo(.firstSingular)`. The architecture now reads directly
from the type names: UI speaks DisplayTense → `TenseBridge` maps it (routing
compounds through `CompoundTense`) → engine speaks EngineTense.

Mechanics worth noting: a word-boundary-aware perl rename (`\bTense2\b` first, then
`\bTense\b`) handled all 284 occurrences without touching `TenseBridge`,
`CompoundTense`, or `haberTenseForCompoundTense`, but two things needed manual
care — the `NSLocalizedString("Tense", …)` localization *key* had to stay "Tense"
(it's how the Spanish "Tiempo" is looked up), and the `TenseTests` class /
`tense2` locals followed up by hand. The rest of the `*2` family (`Conjugator2`,
`PersonNumber2`, `VerbMap2`…) keeps its names for now; those could get the same
treatment during the SwiftUI conversion.

## Renamed PersonNumber → DisplayPersonNumber, PersonNumber2 → EnginePersonNumber

Same split, same treatment as the tense rename: **`DisplayPersonNumber`** is the
UI/quiz person vocabulary; **`EnginePersonNumber`** is the engine's seven-person set
(including `secondSingularVos`) that rides inside `EngineTense` cases. `TenseBridge`'s
`personNumber2(for:)`/locals became `enginePersonNumber`. No localization keys were
at stake this time.

The rename surfaced a fun latent flake: `GameCenterFakeTests.testAuthenticate`
started failing intermittently in full-suite runs — first `authenticate()` on a
*fresh, local* fake "returned false," which the fake's code cannot do. Mechanism:
the test installed its fake into the global `Current.gameCenter`, and QuizVC /
SettingsView spawn fire-and-forget `Task`s that call
`Current.gameCenter.authenticate(...)` — a task lingering from an earlier test could
consume the fake's one "first authenticate" before the test's own call. Renaming
`PersonNumberTests`/`TenseTests` to `Display…` moved them earlier in XCTest's
alphabetical order, shifting timing just enough to expose the race. Fix: the test
exercises the local fake, so it simply no longer touches `Current`. Two consecutive
full-suite runs green.

## Dropped the `*2` suffixes — the engine's types get their real names

With the legacy engine gone, the "2" on the new engine's types no longer
distinguished anything, so the whole family lost it: `Conjugator2` → `Conjugator`,
`VerbModel2` → `VerbModel`, `ModelCatalog2` → `ModelCatalog`, `VerbMap2` →
`VerbMap`, `Conjugator2Error` → `ConjugatorError`, plus all 20-odd feature
conformers (`StemFeature`, `AccentStem`, `IYHiatus`, `DefectiveFeature`, …) and
the `Slot` slot-set namespace. Two names deviated from plain 2-dropping:
`Feature2` became **`ConjugationFeature`** (bare `Feature` is too generic to be
searchable or self-describing), and `Resolver2Tests` became
**`ConjugatorResolverTests`** (there is no `Resolver` type — the suite tests
`Conjugator`'s conjugate-by-name path, and the prefix parks it next to
`ConjugatorTests` in the navigator).

An amusing wrinkle of the prompt's inventory: seven "types" on the list
(`AccentFeature2`, `ResidueFeature2`, `OrthographicFeature2`, …) turned out to be
*file names only* — category files bundling several conformers. The greps
recommended by the prompt caught that immediately. Nineteen files were `git mv`'d
(file-system-synchronized groups meant zero pbxproj surgery), a word-boundary
perl handled the ~800 identifier occurrences, and the localization keys with a
real "2" in them (`imperfectoDeSubjuntivo2Text` = the -se variant) were protected
by the word-boundary approach plus an explicit audit. Comments that the blind
replace would have made circular ("the Conjugator → Conjugator2 migration") were
reworded by hand, including two stale "Suffixed `2` while it lives alongside…"
headers left in `EngineTense`/`EnginePersonNumber` from the earlier rename rounds.

Build green, full suite green twice (no ordering flake this time), swiftlint
steady at 132, and Browse → abajar renders the full grid in the simulator.

## The Models tab — browsing the engine's verb models, Conjuguer-style

Conjugar's French sibling Conjuguer has always had a tab Conjugar could not:
**Models**, a browsable list of every verb model with an irregularity badge, a
detail screen, and deep links to the verbs that use it. The legacy engine had no
model concept to browse; the new engine's `ModelCatalog` is exactly that concept.
So Conjugar now has a Models tab too, second from the left (Browse, **Models**,
Quiz, Info, Settings), reproducing Conjuguer's UX in Conjugar's UIKit idiom — a
new `BrowseModelsVC`/`BrowseModelsUIV`/`ModelCell` trio cloned from the Browse
Verbs pattern, plus a `ModelVC`/`ModelUIV` detail screen whose verb rows push the
regular Verb screen. Tab icon: the same `key.fill` SF Symbol Conjuguer uses.

Three decisions worth recording:

**Alias folding.** The catalog maps 106 class numbers, but four of them —
29-2 satisfacer, 30-1 suponer, 31-1 obtener, 32-1 convenir — are prefix-accent
aliases that ride their parents' models byte-for-byte (hacer, poner, tener,
venir). Rows for them would have duplicated their parents' exemplars in the
list, so they get no rows; their verbs fold into the parent row. The tab shows
**102 models**, and a test pins that number so a future catalog edit can't
silently change it.

**The computed irregularity score.** Conjuguer stores each model's irregularity
percent in its XML; Conjugar's models store nothing — but the score is
*computable*. `ModelInfo` conjugates each row's exemplar twice per slot — once
normally, once against a feature-less `VerbModel(base:)`, the same baseline the
irregularity highlighting diffs against — across all 65 engine slots (9
person-bearing tenses × 7 persons + participle + gerund) and counts differing
results, treating an error (a defective's formless slot) as a distinct value.
Classes 1/2/3 come out 0%; ir tops the list. The whole 102-exemplar computation
is a one-time ~13k-conjugation pass, imperceptible at tab load.

**The book-order comparator.** Conjuguer's Identifier sort leans on a stored
`position`; Conjugar's class numbers must sort themselves, and book order is not
string order ("2" < "10", "4A-2" < "4B", "4B" < "4B-1"). `ModelSort` parses each
number into (leading integer, letter suffix, sub-number) and compares
component-wise, with comparator edge cases pinned in tests.

The three sorts (Irregularity — the Conjuguer default — Alphabetical, and
Number) persist via `Settings.modelSort`, GetterSetter-backed like `verbSort`.
Everything is localized in English and Spanish. Search on the Models and Browse
lists remains a possible follow-up, as does making the Verb screen's
"Irreg. ☛ conocer" label tap through to the model's detail screen.

### Follow-up: the model detail now says *how* a model is irregular

Conjuguer's `ModelView` doesn't just badge a model with a percent — it shows the
irregularity itself: an endings grid with the deviant endings in red, plus a
stem-alterations card. Conjugar's first-pass detail screen showed only the
percent, so it got the same treatment, adapted to how Conjugar's models work.
Conjugar has no endings tables or stem-alteration metadata to render (its models
are feature stacks over stems), but it has something better: the engine can
conjugate the exemplar and mark exactly which spans deviate from the regular
composition — the same red marking the Verb screen uses. So the detail screen now
opens with Participio and Gerundio lines and a horizontally scrollable
pronoun-by-tense grid (yo through ellas × the Spanish analogs of Conjuguer's five
grid tenses — presente, imperativo, pretérito, subj. presente, subj. imperfecto —
plus futuro, because Spanish parks so much irregularity in the future stem, which
Conjuguer surfaced via its stem-alterations card instead). Red spans show the
deviation slot by slot: predecir's grid shows predIGo / predIJe / predIré / and
the model's signature *regular* tú imperative predice, uncolored. A model that
suppresses slots gets a "Defective" note in the header line, and defective slots
render blank in the grid. The grid and the verb count live in the table's header
view, so the whole thing scrolls away with the verb list — the list stays the
screen's single scrolling element even for class 1's thousands of verbs.

### Localization, modernized: `enum L` + a single `.xcstrings` catalog

Conjugar's localization was showing its age: string constants in a
`Localizations` enum whose accessors called `NSLocalizedString` — most keyed by
the English text itself (`NSLocalizedString("Start", …)`), a few by symbolic keys
— with Spanish living separately in a UTF-16 `es.lproj/Localizable.strings`, and
the long rich-text Info/tense bodies keeping their English inline in `Info.swift`.
The sibling apps Conjuguer and Konjugieren had already moved to the modern Xcode
setup, so Conjugar followed: a type-safe `enum L` backed by `String(localized:)`
and one `Localizable.xcstrings` string catalog holding **both** languages.

**`enum L`.** Keys now mirror the Swift path exactly — `L.Quiz.start` →
`String(localized: "Quiz.start")` — instead of leaning on English-as-key.
Parameterized strings became functions whose runtime key is built by
interpolation (`L.Model.numberAndPercent(model:percent:)` →
`"Model.numberAndPercent %@ %lld"`). The loose top-level strings that had no home
(`spain`, `easy`, `score`, `gotIt`, the gendered `both…`) got scoped into
`Region`, `Difficulty`, `Quiz`, `Alert`, `Both`. Two accessors shed their accents
for clean ASCII identifiers (`pretéritoText` → `preteritoText`), and one genuinely
dead body — a `purposeAndUseText` in the old enum that nothing referenced, the
live copy being inline in `Info.swift` — was dropped. `Info.swift` went from 918
lines to 60: all 28 rich-text bodies now resolve through `L.Info.*`, and no raw
`NSLocalizedString` survives anywhere.

**The catalog, without losing hours of translation.** The high-risk step was
folding the UTF-16 Spanish `.strings` and the scattered English bases into one
`.xcstrings` without dropping a single translation. This got **scripted**: read
the Spanish with `plutil -convert json` (never by hand — UTF-16, C-escapes, and
literal newlines are parser territory), assemble each entry from a reviewable
old-key → new-key mapping, and emit the JSON with a real serializer so `\"` and
`\n` come out right automatically. The builder printed a coverage report as its
own proof: all 97 legacy Spanish keys consumed, zero missing Spanish, zero
orphans. The build then compiled the catalog into `en.lproj` and `es.lproj`, and
spot-checks confirmed the wiring (`Quiz.start` → "Comenzar", the gendered
`Both.masculine`/`feminine` → "Ambos"/"Ambas" that the old file really did
distinguish).

**Plurals and positional specifiers, done properly.** The old code hard-coded
singular/plural pairs (`verbUsing`/`verbsUsing`, `oneRating`/`multipleRatings`)
and picked between them with `count == 1` checks. Those collapsed into xcstrings
plural **variations** (`one`/`other`, `%lld`) for both languages — one key, the
plural engine chooses. Ratings keep a separate `noRating` sentence selected at the
call site when `count == 0`, because CLDR maps `0 → other` for English and
Spanish, so a plural "zero" category would never fire. The one multi-argument
string became positional (`Model %1$@ · %2$lld%% irregular`) in both languages so
a translator can reorder.

**Project mechanics.** Conjugar's source folders are
`PBXFileSystemSynchronizedRootGroup`s, so `L.swift` and the new catalog — both
dropped into `Supporting/` — were auto-added to the target with no `project.pbxproj`
edit. Removing the legacy `Localizable.strings` still needed real pbxproj surgery,
though: it predated synchronized groups and was an explicit `PBXVariantGroup` with
build-file, file-reference, group, and resources entries to excise (leaving
`LaunchScreen.strings` alone). The hard-won editing tips — the Edit tool silently
un-escapes ASCII quotes in `.xcstrings`, Grep truncates its one-line-per-value
JSON, always `json.load`-validate after touching it — are now recorded in
`CLAUDE.md` for the next person.

---

## 2026-07-06 — Adopted Konjugieren's build settings ahead of the SwiftUI migration

Before converting the UIKit UI to SwiftUI, matched Conjugar's build settings to
the recently-built sibling app **Konjugieren**, so new SwiftUI is born under modern
concurrency instead of being retrofitted later. Four settings changed, structured
exactly like Konjugieren (project level vs. app vs. test target): min iOS
**17 → 26**, Swift **5 → 6**, `SWIFT_STRICT_CONCURRENCY = complete`,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, plus `SWIFT_APPROACHABLE_CONCURRENCY`
and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`. Doing the concurrency flip
*first* means the fixes land mostly on the layers that survive the migration (the
engine, the models, the services) rather than on the doomed UIKit VCs.

**The engine went fully `nonisolated` + `Sendable` — the right home for it.** With
MainActor-default isolation, everything is implicitly `@MainActor` unless it opts
out. The pure `Conjugator` engine (the feature-composition types, `Slot`,
`EngineTense`/`EnginePersonNumber`, `ModelCatalog`, `VerbModel`, `VerbMap`,
`CompoundTense`, `TenseBridge`, the UI vocabulary `DisplayTense`/
`DisplayPersonNumber`, `IrregularityMarker`) is deterministic value-type
computation with no UI, so it was marked `nonisolated` throughout and the
`ConjugationFeature` protocol made `: Sendable` — which propagates Sendability to
the `[any ConjugationFeature]` a `VerbModel` holds and thus to `ModelCatalog`'s
static exemplars. Stored slot-predicate closures became `@Sendable (EngineTense)
-> Bool`. `VerbMap` (a load-once XML cache) became `nonisolated ... @unchecked
Sendable`. Result: the engine is thread-agnostic and callable from anywhere,
future-proofing off-main conjugation, and its Swift Testing suites stay
parallel-friendly with no `@MainActor`. `MEMBER_IMPORT_VISIBILITY` also forced a
couple of transitive `import Foundation`s to become explicit.

**`SettingsView` modernized to `@Observable`.** Its `SelectionStore` was a
`@Published`-less `ObservableObject` whose Combine `objectWillChange` default is no
longer visible under `MEMBER_IMPORT_VISIBILITY`; it became an `@Observable` class
with `@State` at the call site — the Konjugieren-consistent, and actually-observing,
pattern. `Current` was made explicitly `@MainActor` so the DI container's isolation
is unambiguous across the app *and* test targets.

**The one real wall: an Xcode 26.3 isolated-deinit runtime bug.** Under
MainActor-default isolation every pure-Swift `@MainActor` class gets an *isolated
deinit*, and this toolchain's `swift_task_deinitOnExecutorImpl` double-frees when
**XCTest** deallocates such an object — so nine XCTest suites crashed on teardown
(largely via `World.deinit` releasing its `@MainActor` service members when a test
reassigns `Current`). It is test-infrastructure-only — the shipping app never
deallocates `World` (it's a `Current` singleton) — and Konjugieren avoids it purely
by using **Swift Testing** rather than XCTest. Confirmed structural: making one
service `nonisolated` just moves the crash to the next member, and `Quiz` (needs
`@MainActor` for its `Timer`/`#selector`/UI-delegate) is held by `World` and can't
be nonisolated. Chosen fix: convert the four *surviving* service suites
(`Settings`, `GetterSetterReal`, `ReviewPrompterReal`, `GameCenterFake`) to Swift
Testing now — they pass green — and leave the five *doomed* UIKit VC/View suites
(`BrowseModelsVC`, `BrowseVerbsVC`, `CommunVC`/`CommunViewModel`, `ModelVC`,
`SettingsView`) to be rewritten as Swift Testing during the SwiftUI migration that
deletes those VCs. (`AnalyticsServiceSpy`, a pure infrastructure spy, was made
`nonisolated` — its isolated deinit was the same bug and it has no reason to be
MainActor.)

**Verified end-to-end.** App and test targets build clean; SwiftLint clean; all
Swift Testing suites (engine, VerbMap, TenseBridge, the four converted service
suites) and the non-VC XCTest suites pass. Launched in the simulator: Browse Verbs
renders frequency-sorted with glosses, and tapping *tener* conjugates correctly
through the nonisolated engine — `yo tengo` / `tú tienes` / pretérito `yo tuve`
with the irregularity highlighting and `RF: tendr-` intact.

---

## SwiftUI migration, Step 0: the app skeleton and state model (2026-07-06)

Before touching a single color or screen, the migration's real risk had to be
retired: the app's *entry point*, *test-World injection*, *coexistence strategy*,
and *state model*. These are structural — get them wrong and every subsequent
screen inherits the mistake. Konjugieren, already fully SwiftUI, was the template
for all four.

**Entry point.** The custom `main.swift` (`UIApplicationMain` +
`NSClassFromString("TestingAppDelegate")`) is gone, replaced by an `@main enum
AppLauncher` that runs the real `ConjugarApp: App` normally but a minimal
`TestApp` placeholder scene under XCTest — Konjugieren's exact pattern. A trimmed
`AppDelegate` survives only via `@UIApplicationDelegateAdaptor`, for the hooks the
App lifecycle doesn't cover (UIKit appearance config, the UI-test launch-argument
`World` override, `Utterer` setup); it no longer creates a `UIWindow`, since
SwiftUI's `WindowGroup` now owns it.

**Test-World injection — the one real wrinkle.** The App lifecycle can't use the
old `main.swift` trick that selected `TestingAppDelegate` (which set `Current =
World.unitTest`). That selection moved into `World.chooseWorld()`: a *simulator*
process with the XCTest runtime loaded is a unit-test run and gets
`World.unitTest`; otherwise `.simulator`/`.device`. Confirmed green — the engine,
Settings, and Quiz suites all pass against the test world.

**Coexistence: SwiftUI-first from day one.** Rather than keep the UIKit
`MainTabBarVC` shell and bolt SwiftUI on with `UIHostingController` (the old
arrangement), the shell flipped to SwiftUI immediately: a new `MainTabView` with a
`TabView` of five tabs. `SettingsView` (already SwiftUI) drops straight in; the
four not-yet-migrated screens are hosted through a tiny `NavHostedVC`
`UIViewControllerRepresentable` that wraps each VC in a `UINavigationController` so
its `pushViewController` navigation keeps working. Each wrapper is retired — swapped
for a native `NavigationStack` — as its screen migrates, so no un-migration is ever
needed. (The launch-time "new communication" auto-present that `MainTabBarVC` did
is deliberately deferred to the CommunVC migration rather than bridge a
self-dismissing UIKit modal into a SwiftUI cover for a screen about to be rewritten.)

**DI unchanged.** No `@Environment` for the container — SwiftUI reaches the DI
services through the same `@MainActor Current` global the rest of the app uses, one
pattern everywhere.

**State model: `Quiz` becomes `@Observable`.** The flagship conversion.
`Models/Quiz.swift` is now an `@MainActor @Observable class`, its
`Timer.scheduledTimer(target:selector:)` replaced by the closure form
(`withTimeInterval:repeats:` + `MainActor.assumeIsolated`), with
`start`/`stop`/`pauseTimer`/`resumeTimer`. Its `QuizDelegate` is retained, marked
`@ObservationIgnored`, as a *transitional bridge*: the still-wrapped `QuizVC` and
the XCTest `QuizTests` drive the quiz through it until `QuizVC` becomes a SwiftUI
`QuizView` that observes the model directly (Step 4). Doing the model conversion
first — before the screen — is what lets that later swap be purely local.

**Verified end-to-end** in the simulator: the app launches into the SwiftUI
`TabView`; Browse Verbs renders frequency-sorted inside its wrapper and pushes
`VerbVC` (tener → `tenGo`/`tIenes`/`tUve`, `RF: tendr-`) on tap; the Quiz tab
starts a quiz (haber · él · presente de indicativo) whose **Elapsed** counter ticks
— proof the closure timer and the observable→delegate updates both fire. Build and
SwiftLint clean; the removed `MainTabBarVC`/`MainTabBarVCTests` took the last
`UITabBarController` code with them.

7/6/26: **SwiftUI migration Step 1 — the design system (light mode arrives).**
Conjugar shipped dark-only since 2017: `Colors.swift` hardcoded four fixed
`UIColor`s (red 193,0,29 · gold 205,165,27 · blue 85,135,255 · black), there were
**zero color assets**, and `Info.plist` pinned `UIUserInterfaceStyle = Dark` so the
whole app ignored the system appearance. Step 1 replaces that with an
appearance-aware palette, ported from sibling Konjugieren's asset-catalog approach
but seeded with Conjugar's own brand hues.

- **Eight light/dark colorsets** now live in `Assets.xcassets`: the seven Konjugieren
  roles (`customBackground`, `customForeground`, `customCardBackground`,
  `customCardBorder`, `customRed`, `customYellow`, `AccentColor`) plus a
  Conjugar-specific `customBlue` (its links). The trick light mode demands: a
  yellow-on-black scheme doesn't invert for free, so `customYellow` keeps Conjugar's
  bright gold (0xCDA51B) in dark mode but becomes a **darker, legible gold**
  (0x8A6600, ~5.2:1 on white) in light; `customBlue` likewise darkens to 0x1E56E0 for
  link contrast on white. Red stays identical in both (legible either way). Enabled
  `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES` so the colors
  surface as `Color.customYellow` / `UIColor.customYellow`, matching how the
  to-be-ported Konjugieren views reference them.
- **`Colors.swift` is now a thin adaptive bridge.** Its four legacy names
  (`red`/`yellow`/`blue`/`black`, still referenced by ~20 not-yet-migrated UIKit
  files) became `static let`s pointing at the generated `UIColor.custom*` symbols —
  so every old screen turns appearance-aware for free, with no edits to the VCs. Kept
  as `static let` (one cached instance) precisely so the cell tests that assert
  `textColor == Colors.yellow` by identity still pass. Added the newer semantic roles
  (`background`, `foreground`, `cardBackground`, `cardBorder`) for the SwiftUI work
  ahead. SwiftUI `Modifiers.swift` and `SettingsView` now read the generated symbols
  directly (`.customYellow`, `Color.customBackground`), retiring the last hardcoded
  `Color.black` background.
- **Unpinned the appearance.** Removed `UIUserInterfaceStyle = Dark` from `Info.plist`
  and switched `AppDelegate`'s nav/tab `barTintColor` from `UIColor.black` to the
  adaptive `Colors.background`, so bars follow the system too.

**Verified in the simulator, both appearances.** Dark mode is pixel-unchanged from
before (yellow-on-black Browse list). Light mode now renders white backgrounds with
dark-gold titles, darkened-blue glosses, and red interactive text — legible and still
recognizably Conjugar — across the UIKit Browse list and the SwiftUI Settings screen.
Build clean, SwiftLint clean (0 violations), the four color-sensitive cell suites
green.

7/6/26: **SwiftUI migration Step 2 — the UI audit, by mapping not fresh discovery.**
Conjugar's UIKit UI is nearly identical to the *pre-improvement* UI of its already-
audited siblings Konjugieren (German) and Conjuguer (French), so re-auditing a UI
we're about to delete would be wasted effort. Instead, `docs/conjugar-ui-issues.md`
**maps** Konjugieren's 24 audit items (`K#`) and Conjuguer's 30 (`C#`) onto Conjugar's
concrete screens, tagging each as direct/adapted, and fresh-audits only the screens the
siblings lack or lay out differently.

- **Before-screenshots** of every current UIKit screen (dark + light) were captured with
  the `run-in-simulator` skill and live in `docs/screenshots/` (git-ignored). They confirm
  the mapped findings: the ~90%-empty not-started Quiz, the seven-identical-rows in-progress
  Quiz with its invisible borderless answer field, the single-column verb conjugations, the
  centered Info/Settings section headers, and Step 1's light mode rendering correctly.
- **Foundations are half-built already.** Step 1 shipped `customCardBackground`/
  `customCardBorder` (the siblings' `customSurface` role) and a brand-colored `HeadingLabel`,
  so of Conjuguer's five "Batch A" primitives only **`customGreen`** (to de-overload red)
  and a `.card()` modifier + sensory-feedback/numeric-text helpers remain.
- **A false alarm, corrected during review:** the Model-detail conjugation grid (`ModelVC`)
  looks clipped at rest (screenshot `04` cuts "nosotr…" mid-word), and an early draft called
  it a layout bug. It isn't — the grid is a horizontal `UIScrollView`, and swiping reveals all
  six persons incl. vosotros/ellas (screenshot `04b`). The real, minor note is
  *discoverability*: the scroll indicator is disabled and nothing cues that more columns exist,
  so the SwiftUI port should signal the horizontal scroll. A reminder that a static screenshot
  isn't proof of a defect — check the source (and swipe) before crying bug.
- The audit closes with a sequencing table tying each screen's mapped items to Step 4's
  migration order (Info → lists → details → Commun → Quiz last).

7/6/26: **SwiftUI migration Step 3 — the shared design-system code (port + adapt).**
Before migrating any screen, built the reusable SwiftUI primitives the mapped audit
(`docs/conjugar-ui-issues.md`) leans on — ported and adapted from Konjugieren's
`Utils/Modifiers.swift`, all reading from Step 1's adaptive color assets so every one
is light/dark correct for free.

- **The one new color: `customGreen`.** Step 1 already shipped the surface/card tokens,
  so the audit's only missing colorset was a "correct" green — added as a light/dark
  `customGreen.colorset` (forest green on white, brighter green in dark) plus a
  `Colors.green` UIKit bridge. This de-overloads red, which today does CTA + destructive
  + link + error/irregularity all at once; going forward red retreats to error/irregular,
  green means "correct", and primary CTAs take the yellow accent.
- **`Modifiers.swift` grew from ~6 thin modifiers to the full primitive set:** `.card()` /
  `.cardWithAccentBar(_:)` / `.cardRim()` (the surface behind quiz cards, conjugation
  sections, results summaries, settings groups), `.linguistic()` (serif for Spanish
  linguistic content, K9/C-cross), `.readingWidth()` (comfortable measure for Info
  articles / conjugation columns), `.numeric()` (`monospacedDigit` + `.numericText()`
  content transition so ticking score/progress/elapsed stop jittering, C5/K6),
  `.metadataPill(tint:)` (tinted capsule badges for irregularity %, verb count, K12/C15),
  `.selectionFeedback(trigger:)` (sort-control haptic, K13/C19), and `.speakOnTapFlash`
  (tap-to-speak + brief flash, ported from Konjugieren's `SpeakOnTap`, wired to Conjugar's
  `Utterer`, K11/§4). Plus two `ButtonStyle`s — `PrimaryButtonStyle` (filled accent
  capsule, `lineLimit(1).minimumScaleFactor(0.7)` so large Dynamic Type shrinks instead of
  clipping "Start", §1/C6) and `LinkButtonStyle` (non-red link tint for Enable/Rate, §9).
- **`FontExtensions.swift` stays the type ramp**, plus a `heroNumeral` (large rounded
  numeral) for the Results score the audit wants promoted from a labeled line (§3/K6,C7).
  Serif itself is a `.linguistic()` modifier, not a font, matching how Konjugieren applies
  `.fontDesign(.serif)` inline. Added `Layout.doubleDefaultSpacing`, `.readingWidth`,
  `.cornerRadius` to back the new modifiers.
- **The existing `HeadingLabel`/`SubheadingLabel`/`BodyLabel`/`StandardButton`/
  `SegmentedPicker` were kept** (SettingsView still consumes them), but `BodyLabel` moved
  from all-gold to adaptive `customForeground` — the audit's §8 "reconsider all-gold body
  text". Verified on the live Settings screen (the one screen using the shared modifiers
  today) in both light and dark: gold headings over legible neutral body copy, no
  regression. Build clean, SwiftLint clean (0 violations). No screen wired to the new
  primitives yet — that's Step 4, which now has its whole toolbox ready.

7/6/26: **SwiftUI migration Step 4, screen 1 — Info (list + detail).** The first
UIKit screen retired for a native SwiftUI one. The old `BrowseInfoVC`/`InfoVC` pair
rendered marked-up articles by building an `NSAttributedString` (`String.infoString`)
for a `UITextView`; the port parses the same markup into a structured, SwiftUI-native
model instead — ported and adapted from sibling Konjugieren's rich-text pipeline.

- **A structured rich-text model + parser** (`Utils/RichText.swift`): the markup
  (`^…^` subheading, `~…~` bold, `%…%` link/cross-ref, `$…$` conjugation with
  uppercase = irregular) parses into `[RichTextBlock]` → `[TextSegment]` →
  `[ConjugationPart]`, which `RichTextView` renders as native `Text`. This is what lets
  body copy be adaptive-colored: subheadings stay serif gold, but body runs now render
  in `customForeground` (audit §8 "reconsider the all-gold body"), and irregular
  conjugation spans stay `customRed`. Konjugieren's `^`-for-emoji marker was dropped
  (Conjugar uses `^` for subheadings, has no emoji), and the link marker adapted from
  `‡` to Conjugar's `%`. Unterminated markers recover gracefully (`assertionFailure` +
  flush) rather than the reference's hard `fatalError`.
- **`Info` became a SwiftUI value model** (`Hashable, Identifiable`): heading renders
  separately as a serif gold `largeTitle`, and the body parses to `richTextBlocks`. Gave
  each article an `InfoSection` (`.about` / `.tenses`) so the list can be sectioned per
  audit §7 — "About" (Purpose & Use, Terminology, Q&A, Voseo, Credits) vs "Tenses"
  (everything else). The old percent-encoded-heading link machinery is gone; cross-refs
  resolve at tap time via `Info.info(forHeading:)`.
- **`InfoBrowseView`** — a sectioned `List` of left-aligned serif rows (replacing the
  centered UIKit cells), with the **difficulty filter moved into the Tenses section
  header** so its relationship to what it narrows is explicit (audit §7: the About
  articles are all `.easy`, so the filter only ever affects tenses). The rank-based
  filter reproduces the old thresholds exactly (Easy → 9 rows, +Moderate → 17, all → 28),
  still persisted through `Settings.infoDifficulty`, now with `.snappy` animation and a
  selection haptic. `InfoView` — serif gold title, reading-width body, the app's
  red/yellow/blue triad rule; a tapped `%…%` term opens an external URL
  (`.systemAction`) or drills into the referenced article (`navigationPath.append`,
  replacing the old pop-then-push).
- **Test debt retired.** Deleted `BrowseInfoVC`/`InfoVC`/`BrowseInfoUIV`/`InfoUIV`/
  `InfoCell`/`InfoDelegate` and their three crashing-prone XCTest suites
  (`BrowseInfoVCTests`, `InfoVCTests`, `InfoCellTests`); replaced them with a Swift
  Testing `InfoTests` suite (10 tests: model counts, difficulty thresholds, section
  partition, case-insensitive heading lookup, and the parser's subheading/bold/http-link/
  cross-ref/conjugation cases). Also dropped the now-dead `String.infoString` +
  markup-separator statics from `StringExtensions` (keeping `conjugatedString`/
  `coloredString`, still used by the not-yet-migrated Verb/Model/Quiz screens) and
  de-`InfoVC`'d `UIAlertControllerExtensionTests`.

**Verified in the simulator, both appearances.** The list reads as sectioned
About/Tenses cards with gold-labeled filter; tapping "E" narrows Tenses to the four easy
articles while About is untouched; the detail renders serif gold title + subheadings,
adaptive body copy, and bold inline terms — legible in light (darkened gold on white) and
dark alike. Build clean, SwiftLint clean (0 violations), `InfoTests` + the touched alert
suite green.

7/6/26: **SwiftUI migration Step 4, screen 2 — Browse Verbs + Verb detail.** Migrated
the verb-browse flow as one unit. The plan lists "browse lists" and "detail screens" as
separate steps, but the screens push each other (Browse → Verb, and later Model → Verb),
so migrating a list while its pushed detail stays UIKit would mean hosting a
push-capable VC inside SwiftUI navigation — messy and short-lived. Migrating each *flow*
end-to-end keeps navigation value-based and needs no un-migration.

- **A shared conjugation renderer** (`Views/ConjugationText.swift`): the SwiftUI
  equivalent of the legacy `String.conjugatedString` — takes an engine-marked form
  (uppercase = irregular) and renders native `Text` with the irregular span in
  `customRed`, serif. Reused by Verb now and Model/Quiz/Results later. Backed by making
  `String.parseConjugationToSegment` (from the Info work) internal.
- **`VerbView`** (replaces VerbVC/VerbUIV): a metadata header — gloss, an Irregular/
  parent or Regular-AR/ER/IR pill, a red "Defective" pill when defective, and the
  Participio / Gerundio / Raíz Futura non-finite forms — over one card **per tense** with
  a leading yellow accent bar, a serif gold tense heading, and a **two-column
  pronoun | form `Grid`** (audit §4). Irregular spans render red; every form speaks on tap
  (`.speakOnTapFlash`); defective slots show a muted "—". It reuses `ConjugationDataSource`
  to build the exact rows the UIKit table showed (same secondSingularBrowse handling,
  imperativo ¡…! wrapping, defective blanks), so conjugation parity is guaranteed.
- **`VerbBrowseView`** (replaces BrowseVerbsVC/BrowseVerbsUIV/VerbCell): all ~4,811 mapped
  verbs in a `LazyVStack`, a "4,811 verbs" small-caps count banner (audit §6, K14), two-
  line serif rows (gold infinitive + gloss + blue #rank badge), and the Frequency /
  Alphabetical segmented control pinned at the bottom — now with `.snappy` animated
  re-sort, scroll-to-top, a `.selection` haptic, and `Settings.verbSort` persistence
  intact. Both sort orders precompute once (`static let verbsBySort`, mirroring the old
  VC). New `L.BrowseVerbs.sort` / `verbCount` (pluralized) strings.
- **Coexistence note:** VerbVC/VerbUIV/VerbCell are **kept for now** — the still-UIKit
  ModelVC pushes VerbVC and its "verbs using this model" list dequeues VerbCell. They're
  deleted in the next unit (Browse Models + Model detail), where ModelView will link to
  the native VerbView instead. Deleted only BrowseVerbsVC/BrowseVerbsUIV and the crashing
  `BrowseVerbsVCTests`; added Swift Testing `ConjugationTextTests` (irregular-span
  coloring). Verb sorting stays covered by the existing `VerbSortTests`.

**Verified in the simulator, both appearances.** Browse shows the count banner and
frequency order (ser #1 · haber #2 · tener #3) with rank badges; tapping *ser* pushes a
VerbView whose Presente reads yo so**y** / tú **er**es / **es** and Pretérito **fu**i /
**fu**e with the irregular spans red, over accent-barred serif cards — legible in light
and dark. Build clean, SwiftLint clean (0 violations), new + touched suites green.

7/6/26: **SwiftUI migration Step 4, screen 3 — Browse Models + Model detail.** The
Models flow, migrated end-to-end (the Conjugar-specific tab the siblings lack). This
also retired the last verb-flow UIKit: with ModelView linking to the native VerbView,
`VerbVC`/`VerbUIV`/`VerbCell` were finally deleted.

- **`ModelBrowseView`** (replaces BrowseModelsVC/BrowseModelsUIV/ModelCell): the 102
  model rows — serif gold exemplar + class number + a **tinted irregularity-percent
  capsule** (green→yellow→red by magnitude, audit §11/C15) — with a "102 models" count
  banner and the Irregularity / Alphabetical / Number sort control pinned at the bottom
  (animated re-sort + selection haptic, `Settings.modelSort` persistence). `ModelPalette.
  tint(forPercent:)` is the shared percent→color scale.
- **`ModelView`** (replaces ModelVC/ModelUIV/ModelHeaderUIV): a carded header (gloss +
  a blue "Model N" pill + the tinted % pill + a red Defective pill when defective + the
  Participio/Gerundio non-finite forms), then the **horizontally-scrollable
  pronoun-by-tense conjugation grid** — Conjugar's answer to Conjuguer's endings card,
  showing *how* the model is irregular slot-by-slot with red spans — now with a **visible
  scroll indicator** to cue the swipe (audit §10). Below, the "N verbs use this model"
  banner (pluralized) and the verbs-using list, each row the shared `VerbRowLabel` linking
  to the native `VerbView`.
- **A navigation gotcha, fixed:** `NavigationLink(value:)` inside a *pushed* destination
  view (ModelView) did not reach the stack's root-registered `String` destination — the
  button pressed but nothing navigated (confirmed via `idb ui describe-all`: a real
  Button, no push). Appending to the stack's `NavigationPath` does work, so both the model
  rows and ModelView's verb rows now navigate via `navigationPath.append(...)` (a closure
  threaded into ModelView), matching VerbBrowseView's proven pattern.
- **Cleanup:** `ModelInfo` gained `Identifiable, Hashable` (id = class number) for
  navigation; `VerbRowLabel` was extracted from VerbBrowseView so Model reuses it. Deleted
  BrowseModelsVC/ModelVC/VerbVC + BrowseModelsUIV/ModelCell/ModelUIV/ModelHeaderUIV/
  VerbUIV/VerbCell and their five XCTest suites (incl. three of the crashing doomed set:
  BrowseModelsVCTests, ModelVCTests); re-pointed `UIViewControllerExtensionsTests` off the
  deleted VerbVC. `ConjugationDataSource`/`TenseCell`/`ConjugationCell` stay (VerbView
  reuses the data source; the Quiz screens still lean on the cells). New L strings
  `BrowseModels.modelCount` (plural) and `Model.modelLabel`.

**Verified in the simulator.** Models lists 102 rows irregularity-first with red %
badges; tapping *decir* opens a ModelView whose grid shows d**i**go / d**i**ce /
d**i**jo… with the future-stem d**i**ré across the scrollable pronoun columns; tapping the
*decir* row drills into the native VerbView — all inside the one Models NavigationStack.
Build clean, SwiftLint clean, model/verb/info suites green.

7/6/26: **SwiftUI migration Step 4, screen 4 — Commun (the CloudKit message modal).**
The rarely-seen, server-driven popup, and the piece whose launch-time auto-present was
deliberately deferred back in Step 0. Both are now done.

- **`CommunView`** (replaces CommunVC/CommunUIV): serif gold title, a **conditionally-
  omitted** image (the stub/absent image is a zero-size `UIImage()` — `hasImage` gates the
  view), and carded body copy on the app surface, with the type-specific buttons
  (okay / action / cancel) routed through the shared `PrimaryButtonStyle` /
  `LinkButtonStyle`, and a **discoverable toolbar dismiss** (a red ✕ in the cancellation
  slot) — audit §12. It reuses the existing `CommunViewModel` unchanged for the display
  logic (title/content/image/button visibility, per `Commun.CommunType`), and preserves
  the exact tap behaviors: close/okay/cancel dismiss + analytics; action plays applause,
  dismisses, then runs the commun's `action()` (open App Store / email / website).
- **Restored the launch-time presentation** in `MainTabView`: a `.task` fetches
  `Current.communGetter.getCommunication()` and, if no quiz is in progress and the
  identifier is newer than `Settings.lastCommunIdentifierShown`, presents it via
  `.fullScreenCover(item:)` and records it as shown — the SwiftUI equivalent of the old
  `MainTabBarVC.viewDidLoad` gate. `Commun` gained `Identifiable` (id = identifier) to
  drive the cover.
- Deleted CommunVC/CommunUIV and the crashing `CommunVCTests`; kept `CommunViewModel` (+
  `CommunViewModelTests`, still valid) and the `Commun`/`CommunGetter` model. Re-pointed
  `AnalyticsService.recordCommunVisitation` off the deleted `CommunVC` to `CommunView`.

**Verified in the simulator.** On a fresh install the simulator's `CommunGetterStub`
returns the "New Version" commun (id 2 > the −1 default) after its 2 s delay, and it
presents full-screen at launch: serif gold title, the flamenco-dancer image, the release
message, and a "Cool, I Have It" primary capsule (alreadyUpdated ⇒ okay-only). Tapping the
✕ dismisses back to Browse, and `lastCommunIdentifierShown` is bumped so it won't recur.
Build clean, SwiftLint clean.

7/6/26: **SwiftUI migration Step 4, screen 5 — Quiz + Results (the marquee redesign).**
The last and hardest screen, built on the Step-0 `@MainActor @Observable Quiz`. The
`QuizDelegate` is gone — the model's redundant `delegate?.…` callbacks were deleted and
the views observe the model's published state directly.

- **`QuizView`** (replaces QuizVC/QuizUIV). The old not-started screen was ~90% empty
  black with a lone red "Start" text button; now it's a **briefing** (§1): a pulsing
  graduation-cap glyph (Reduce-Motion-gated), a one-line description, the active
  Difficulty + Region as pills, and **Start** as a filled `PrimaryButtonStyle` capsule.
  The in-progress screen (§2) is a full rebuild: a `ProgressView` bar, a **hero question
  card** (serif verb, gloss subtitle, "pronoun · tense" ask), a **visible answer field**
  with a yellow focus ring (the old one was an invisible borderless `UITextField`), an
  unmissable answer **reveal** (✓/✗ icon + "Your Answer" / "Correct Answer" with the
  irregular span red) in a fixed-height slot, a de-emphasized Score/Elapsed status strip
  with `.numeric()` transitions, `.sensoryFeedback` success/warning/error haptics, and
  **Quit moved into the toolbar** (destructive role). The Game-Center-reconsider prompt
  became a SwiftUI `.alert`.
- **`ResultsView`** (replaces ResultsVC/ResultsUIV/ResultCell). The score is promoted to
  a **hero numeral** (`.heroNumeral`) color-coded by accuracy (green ≥80% / yellow ≥50% /
  red below, recomputed from the per-answer `ConjugationResult`) with a `.numericText()`
  transition, over a carded Difficulty/Region/Time summary (§3). Each result row is
  left-aligned and **labeled + color-coded**: a ✓/◐/✗ outcome glyph, the serif verb,
  "tense, person", "Your Answer" (blue when wrong), and "Correct Answer" with the red
  irregularity marking.
- **Retired the last test debt.** Deleted QuizVC/ResultsVC/QuizUIV/ResultsUIV/ResultCell/
  QuizDelegate and their XCTest suites; rewrote `QuizTests` as Swift Testing that drives
  the delegate-free model in a loop (answer each question correctly → assert the maxed
  score per region/difficulty). Converted the last of the five *doomed* isolated-deinit
  suites, **`SettingsViewTests`**, to Swift Testing. `fatalCastMessage` +
  `UIViewControllerExtension` were deleted as dead (no `UIViewController` subclasses
  remain in the app), and the now-unused `NavHostedVC` hosting bridge came out of
  `MainTabView` — **the app shell is 100% SwiftUI, no UIKit VC anywhere.**

**The whole test suite is green again** — `xcodebuild … test` = **TEST SUCCEEDED**, 397
Swift Testing tests in 16 suites + all XCTest suites, 0 failures, no teardown crashes (the
goal Step 4 set). **Verified the full quiz in the simulator:** the briefing → Start →
question card (evadir · yo · presente, focus-ringed field) → a wrong answer flashes the
red ✗ with "Correct Answer: evado" and advances the progress bar and elapsed clock →
finishing 50 questions pushes ResultsView with the red hero "0", the Easy/Latin
America/1:49 pills, and the color-coded rows (caber → c**up**imos, unir → uni**ó**). Build
clean, SwiftLint clean (0 violations).

**Step 4 is complete — Conjugar's UI is now entirely SwiftUI**, light/dark correct on
every screen, with the mapped audit (`docs/conjugar-ui-issues.md`) items delivered:
Info (§7/§8), Browse Verbs (§6), Verb detail (§4/§5), Browse Models (§11), Model detail
(§10), Commun (§12), and Quiz/Results (§1/§2/§3).

7/6/26: **Step 4 epilogue — deleted the last UIKit UI code.** With every screen SwiftUI,
the only UIKit left in the *UI* layer was vestigial: `VerbView` still reused the legacy
`ConjugationDataSource` (a `UITableViewDataSource`) just to build its row list, which kept
`ConjugationCell`/`TenseCell` alive as compile-only dependencies of a cell-rendering path
nothing called. Inlined that ~20-line row-building logic straight into
`VerbView.buildSections` (same yo/tú-vos-both/plural ordering, same defective-blank
handling), then deleted `ConjugationDataSource`, `ConjugationCell`, `TenseCell`, and their
two XCTest suites. `Conjugar/UIViews/` is now **empty** — the app target has no UIKit view
or view-controller code at all (only a handful of UIKit *extensions* for appearance config
remain). Full suite still green (397 Swift Testing + XCTest, TEST SUCCEEDED), SwiftLint
clean (128 files), and *tener* still renders every person (yo ten**g**o … vosotros tenéis,
pretérito t**uv**e…t**uv**ieron) with the red irregularity spans. Updated `CLAUDE.md`'s
View Architecture / Tab Structure / testing sections to describe the finished SwiftUI app.

7/6/26: **Search bars on Browse Verbs and Models.** The SwiftUI migration (Step 4)
deliberately deferred list search; this is the clean follow-up the audit called for
(`conjugar-ui-issues.md` §6/§11 flagged a search empty-state, and the Browse-rebuild note
named the missing search bar). Ported Conjuguer's one shared abstraction —
`Utils/BrowseSearch.swift`, a generic `enum BrowseSearch` with a single
`results(in:query:playSoundIfEmpty:matches:)` that both screens share: empty/whitespace
query returns the list unchanged, otherwise `filter { matches }`, and if an active query
finds nothing it plays the sad-trombone once. Adapted to Conjugar's static
`SoundPlayer.play(.sadTrombone)` (Conjuguer routes through `Current.soundPlayer`), left
`@MainActor` since it touches the UI sound helper, explicit `import Foundation`.

Wired `.searchable` into `VerbBrowseView` and `ModelBrowseView`: a `@State searchText`, a
`filteredVerbs`/`filteredModels` computed off the **current sort's** array (so sort +
search compose), and the **count banner + `ForEach`** now read the filtered array. Match
is **case- and diacritic-insensitive** (`range(of:options:[.caseInsensitive,
.diacriticInsensitive])`) so `esta` finds `está` and `SER` finds `ser`. Went with
scope-decision **(a)**: verbs match infinitive **or** gloss (a user finds "have" →
haber/tener, "insert" → introducir) — no `SearchScope` setting/UI (Conjuguer-parity (b)
noted as a further follow-up); models match exemplar **or** class number (typing `28`
finds decir/predecir/bendecir by book number). When a query is active and empty, a
`ContentUnavailableView(…searchNoResults, systemImage: "magnifyingglass")` replaces the
list. New localized strings (en + es): `BrowseVerbs.searchPrompt`/`.searchNoResults`,
`BrowseModels.searchPrompt`/`.searchNoResults`.

Tests: `ConjugarTests/Utils/BrowseSearchTests.swift` (Swift Testing, `@MainActor`) covers
the seam — empty/whitespace-query identity (order preserved), matches-only, no-match `[]`
(with `playSoundIfEmpty: false` to stay silent), and case/diacritic-insensitivity. Build
clean, SwiftLint clean (0 violations), full suite **TEST SUCCEEDED** (now 409 tests).
**Verified in the simulator, light and dark:** Browse `ten` → "94 VERBS" (tener, mantener,
… plus gloss hits like escuchar/listen), row tap still pushes `VerbView`, gibberish → "No
verbs found" + sad-trombone, clearing restores 4,811; Models `28` → the three decir
models, and the bottom Number sort re-sorts the filtered set with the query still active.

7/6/26: **Random sad trombone, ported from Conjuguer.** Conjugar had a single
`sadTrombone.mp3` / `case sadTrombone`; Conjuguer instead has four variations
(`sadTrombone1`–`4`) picked at random via `Sound.randomSadTrombone`, used at *every*
failure site (quiz wrong answer, Game Center failure, empty search). Brought that over.
Handy discovery: Conjugar's existing `sadTrombone.mp3` is **byte-identical** (same md5) to
Conjuguer's `sadTrombone1.mp3`, so it *is* variation 1 — I `git mv`'d it to
`sadTrombone1.mp3` and copied in `sadTrombone2/3/4.mp3` (no duplicate sound). The mp3s live
in the root `Conjugar/` group, which is **not** a `PBXFileSystemSynchronizedRootGroup`
(only the `Models/`, `Views/`, `Utils/`, … subfolders are), so the three new files needed
hand-added `PBXFileReference` + `PBXBuildFile` entries, the Sounds group children, and the
Resources build phase — mirroring the `applause1–3` template already in the project.

Rather than a `Sound.randomSadTrombone` computed var, I followed Conjugar's own idiom:
`SoundPlayer` already has a `static func playRandomApplause()`, so I added a parallel
`static func playRandomSadTrombone()` and pointed all four call sites
(`BrowseSearch`, `GameCenterReal`, and `QuizView`'s reject-Game-Center + quit paths) at it,
replacing the removed `.sadTrombone`. Build clean, SwiftLint clean (0 violations), full
suite **TEST SUCCEEDED** (403). Verified in the simulator: an empty search decodes and
plays an mp3 (system log shows `AudioQueueNewOutput … .mp3` + an mp3 AudioConverter at the
moment the filter empties) — and all four files are present in the built `.app` bundle.

7/6/26: **Debounced the search trombone.** Typing `foooooooo` fired a *burst* of
trombones, not one. Two compounding causes: (1) every empty-keeping keystroke re-runs the
filter, and (2) `filteredVerbs`/`filteredModels` is a computed property with a side effect
(`playRandomSadTrombone()` lives inside `BrowseSearch.results`), and SwiftUI reads it
several times per render (count banner + the `if` empty-check + the `ForEach`), so a single
keystroke could fire it multiple times. Conjuguer never hit this because its
`SoundPlayerReal.play` debounces — a `minSoundInterval` gate on `instantOfLastPlay`. Ported
that: `SoundPlayer.play` gained a `shouldDebounce: Bool = false` parameter (a 1.0 s gate
since the last play) and stamps `instantOfLastPlay` on every play; `playRandomSadTrombone()`
now calls with `shouldDebounce: true`. Default `false` leaves every other call site (chime,
applause, quiz sounds) unchanged. Build/lint/tests green (403); verified in the simulator by
capturing the audio log while typing `foooooooo` — **exactly one** `.mp3` audio-queue start
for the whole burst (was up to ~one per keystroke-times-render before).

7/6/26: **Ported the on-device conjugation tutor from Conjuguer, in Spanish.** Conjuguer
(the French sibling) has a chat tutor backed by Apple's on-device `SystemLanguageModel`
(`FoundationModels`), grounded by a `Tool` that looks up real conjugations from the app's
own engine so the model never invents forms. Brought the whole feature across and adapted it
to Spanish and to Conjugar's engine + design system.

New files (all in `PBXFileSystemSynchronizedRootGroup` folders, so no `project.pbxproj`
edit): `Models/LanguageModelService.swift` (protocol, `TutorMessage`,
`LanguageModelUnavailability`), `Models/LanguageModelServiceReal.swift` (the
`@Observable` service wrapping `SystemLanguageModel(guardrails: .permissiveContentTransformations)`
+ the `ConjugationTool`), `Models/LanguageModelServiceDummy.swift` (test/unavailable double),
`Models/TutorChatHistory.swift` (JSON-string persistence), and `Views/TutorView.swift` (the
chat screen). Wired a `languageModelService` + a shared `getterSetter` onto `World`
(`Real`/`Dummy` per world), an `L.Tutor` scope into `L.swift`, 13 `Tutor.*` keys (en+es)
into `Localizable.xcstrings`, and a live-availability tutor **section** at the top of
`InfoBrowseView`.

Adaptation notes vs. the French original:
- **Prompt is localized by *system language*, not UI locale.** `LanguageModelServiceReal`
  keeps two hand-written instruction blocks and picks Spanish when
  `Locale.current.language.languageCode == "es"`, English otherwise — this steers what
  language the model *answers in*, independent of the app's `.xcstrings` UI localization.
  The Spanish block tells the model to always answer in Spanish and never translate forms
  to English; both blocks teach the Spanish tense vocabulary (pretérito vs. imperfecto,
  the two imperfecto-de-subjuntivo forms, the compounds, etc.).
- **Grounding tool rewired to Conjugar's engine.** Conjuguer's tool called `Conjugator` +
  `Verb.verbs`; Conjugar's engine is different, so `ConjugationTool.performLookup` validates
  the verb with `VerbMap.shared.entry(for:)` and conjugates through
  `TenseBridge.conjugate(infinitive:tense:personNumber:)`, iterating a textbook person set
  (imperatives drop `yo` and use usted/ustedes). Because Conjugar's whole engine is
  `nonisolated`, the tool's `nonisolated` `call` invokes it directly — no `@MainActor` hop
  (Conjuguer needed one). A `displayTense(forName:)` matcher folds accents/hyphens and maps
  either Spanish or English tense names (however the model phrases them) onto `DisplayTense`,
  most-specific compound/subjunctive phrases first so "presente de subjuntivo" isn't
  swallowed by "presente". Marked forms are lowercased to strip the red-irregularity
  UPPERCASE encoding before handing them to the model.
- **Kept the over-refusal workaround.** The on-device model sometimes refuses conjugation
  content; the retry-with-fresh-session loop and `isLikelyRefusal` heuristic came across,
  extended with Spanish refusal phrases ("no puedo ayudarte", "soy un modelo de lenguaje",
  …). A persistent refusal falls back to the localized `L.Tutor.unableToAnswer`.
- **Design-system swaps.** Conjuguer's `.funButton()`/`Color.customSurface`/
  `Current.soundPlayer.play(.chirp)` became `PrimaryButtonStyle`/`Color.customCardBackground`/
  `SoundPlayer.play(.chirp)` (chirp.mp3 already ships), and appearance is recorded via the
  existing `Current.analytics.recordVisitation`.
- **Availability is live.** The service polls `SystemLanguageModel.availability` every 5 s
  and is `@Observable`, so `InfoBrowseView`'s tutor section flips between a tappable
  `NavigationLink` (brain icon → `TutorView`) and a reason row on its own — tapping the
  "Apple Intelligence not enabled" reason deep-links to Settings.

Build clean, SwiftLint clean (0 violations). Verified in the simulator: the Info tab shows
the new **Conjugation Tutor** section with the correctly-localized unavailable reason
("Apple Intelligence is still getting ready.") — the expected state on a simulator with no
on-device model; the full chat path needs a real Apple-Intelligence device to exercise. (The
`SystemLanguageModel`/`@available(iOS 26)` code trips a swarm of bogus SourceKit
"only available in macOS 26 / cannot find type" diagnostics during editing — all noise from
the stale whole-project index; `xcodebuild` compiles it cleanly.)

7/6/26 (follow-up): **Added the batch harness** (`Views/TutorTestView.swift`), ported from
Conjuguer. It runs a fixed set of ~30 queries — Spanish or English, chosen by
`Locale.current` like the prompt — each in a fresh session, and renders/`ShareLink`-exports
the results (tenses, off-topic redirects like "how do you conjugate pizza?", and
grammar-concept questions such as "when do you use the subjunctive?"). Reached by the same
hidden gesture as the original: a **triple-tap on the tutor's navigation title**, wired via a
`.principal` toolbar item with `.onTapGesture(count: 3)`. Unlike Conjuguer's, this one is
**not** behind `#if DEBUG` — Josh is happy for it to ship, so the gesture and harness are
present in release builds too. Hardcoded harness strings use `Text(verbatim:)` to stay out of
the string catalog; the on-Conjugar swaps are the usual `customSurface →
customCardBackground`, `Current.soundPlayer.play(.chirp) → SoundPlayer.play(.chirp)`, and
`L.Navigation.done → L.Alert.okay`. Build + SwiftLint clean. Note the harness (and the whole
chat path) can only be *exercised* on a real Apple-Intelligence device — in the simulator the
tutor reports unavailable, so `runAllTests()` short-circuits to its "Language model is not
available." row and the tutor screen isn't even reachable from the Info tab.

7/6/26: **Ported Conjuguer's widget suite to Conjugar** (a WidgetKit app-extension target,
the app's first). Conjuguer's design is the thing worth copying: the widget extension never
runs the conjugation engine or loads `verbModelMap.xml` — instead the **app** precomputes a
JSON "snapshot" (verb of the day + a daily quiz question), writes it into an **App Group**
container, and the widget is a thin renderer that only decodes it. That keeps the extension
engine-free and tiny.

What shipped, at full parity with the French app:

- **Verb of the Day** widget — `systemSmall` / `systemMedium` / `systemLarge` plus the Lock
  Screen `accessoryRectangular` / `accessoryInline`. Refreshes at local midnight.
- **Interactive Quiz** widget — a tap-to-answer question via an `AppIntent`
  (`AnswerQuizIntent`) with a deterministic, question-id-seeded answer shuffle so the layout
  is stable across timeline reloads; flips to a correct/incorrect state (answer stored in the
  shared `UserDefaults` suite, keyed to the question).
- **Two Control Center controls** — Quick Quiz (`OpenQuizIntent`) and Random Verb
  (`OpenRandomVerbIntent`); each stashes a `conjugar://` deeplink the app drains on activation.
- **Quiz Live Activity** with full **Dynamic Island** (expanded/compact/minimal), driven by
  the app from `Quiz.swift` via a new `LiveActivityManager`.

Structure: a `Shared/` folder (a `PBXFileSystemSynchronizedRootGroup` added to **both** the
app and widget targets) holds the `Codable` `WidgetSnapshot`, `WidgetConstants` (App Group id
`group.biz.joshadams.Conjugar`, file/key names), `WidgetL` localization accessors,
`QuizActivityAttributes`, and the two control intents. The `ConjugarWidget/` folder is the
extension. `Conjugar/Utils/WidgetSnapshotWriter.swift` is the one place the engine is invoked
for widget purposes — it picks a date-seeded verb of the day from the frequency-ranked verbs
and conjugates paradigms + a quiz question through `VerbMap` + `TenseBridge` (marked forms, so
the widget colors irregular letters just like the app's `ConjugationText`).

Spanish adaptations vs. the French original: Conjuguer's Verb of the Day shows an etymology
snippet and an example sentence, which Spanish verbs don't carry yet. Per Josh's call, the
large widget instead shows **extra tenses** (presente + pretérito + futuro paradigms, plus
gerundio/participio), with **TODOs** in `WidgetSnapshot`, `LargeWidgetView`, and
`WidgetSnapshotWriter` to trim back to just the presente and surface etymology/examples once
that data exists.

Deeplinks: registered the `conjugar://` URL scheme + `NSSupportsLiveActivities` in the app
Info.plist; a small `AppRouter` turns `conjugar://verb/<infinitive>` (or `verb/random`) and
`conjugar://quiz/start` into a tab switch plus a pending navigation the Browse/Quiz screens
consume (`MainTabView` now owns a `TabView(selection:)` with `.tag`s + `.onOpenURL`, and
refreshes the snapshot on launch/active).

Gotchas hit along the way: (1) `nonisolated struct` can't wrap an `AppIntent` that has
`@Parameter` property wrappers (Swift-6-mode error) — `AnswerQuizIntent` drops the keyword and
relies on the widget target's default nonisolated isolation. (2) `AppIntent` `title` /
`@Parameter(title:)` metadata is extracted at compile time and can't reference `WidgetL`, so
those use inline `"Widget.*"` literals with English `defaultValue`s. (3) `VerbSort` is a plain
`@MainActor` enum (default isolation), so the `nonisolated` `WidgetSnapshotWriter` sorts the
ranked verbs inline instead of via `VerbSort.frequency.sorted(...)`. (4) Widget colors are
hardcoded dynamic copies of the app's `customForeground`/`customRed` so the extension needs no
shared asset catalog. The extension target was added by hand-editing `project.pbxproj`
(objectVersion 70): new app-extension `PBXNativeTarget`, synchronized groups for
`ConjugarWidget` + the shared `Shared`, an "Embed Foundation Extensions" copy phase, the App
Group in both entitlements. App + widget build clean; note the widget can only be *exercised*
on a device / booted simulator home screen, and Live Activities need a real device.

## TipKit onboarding tips (ported from Conjuguer)

Brought over Conjuguer's TipKit support to nudge new users toward the app's main features.
`Conjugar/Models/ConjugarTips.swift` defines four `Tip`s and a `TipDisplay.tipsEnabled` master
switch (a `Bool`, `true` by default): flip it to `false` before capturing screenshots and — since
TipKit displays nothing until `Tips.configure()` runs — every `TipView`/`.popoverTip` in the app
stays hidden with no per-call-site changes. `ConjugarApp.init()` calls `Tips.configure()` only
when the switch is on; because `AppLauncher` launches `ConjugarApp` only outside XCTest, the
unit-test process never touches TipKit.

The four tips, adapted from the French original for Spanish:
- **TryQuizTip** — an inline `TipView` atop Browse Verbs (hidden while searching), invalidated
  when a quiz starts (`QuizView.startQuiz`).
- **ExploreModelsTip** — an inline `TipView` atop the Models list, invalidated on first
  `ModelView` appearance.
- **ChangeDifficultyTip** — a `.popoverTip` on the Settings difficulty picker, rule-gated on a
  `quizCompleted` `Tips.Event` that `Quiz` donates when a quiz finishes (so it only appears once
  the user has played), and invalidated when they change difficulty.
- **EnableGameCenterTip** — Conjuguer's arcade-game tip has no Spanish analog, so it became a
  `.popoverTip` on the Settings "Enable Game Center" button, inviting users to compete on the
  leaderboards.

Strings live in `L.Tips` (+ en/es in `Localizable.xcstrings`). Gotcha: TipKit's `Tip.title` /
`.message` requirements are `nonisolated`, but the project's `SWIFT_DEFAULT_ACTOR_ISOLATION =
MainActor` makes the `L.Tips` accessors MainActor-isolated by default, which won't satisfy them —
so the `L.Tips` accessors are marked `nonisolated static var` (exactly as Conjuguer does it). App
builds clean and the full test suite still passes; tips can only be *seen* on a booted
simulator/device since TipKit needs the configured, running app.

## Swapping the simulator tooling to the `ios-build-verify` skill

The interim `run-in-simulator` skill (a hand-rolled `simctl` + `idb` recipe) was written
before the SwiftUI migration to give the agent a way to drive the UIKit app. Now that every
screen is SwiftUI, we swapped to the purpose-built **`ios-build-verify`** Claude Code skill —
a plugin-marketplace skill that wraps `xcodebuild` (through `xcbeautify`) for builds and
**AXe** for simulator observation/HID dispatch, all behind named scripts driven by a
per-project `.claude/ios-build-verify.config.sh`.

Setup was mostly introspection: bundle id and scheme come straight out of the pbxproj (the
project has a second `ConjugarWidgetExtension` scheme, so scheme can't be guessed — but the
app scheme is `Conjugar`). Two adopter-side friction points, both documented in the skill's
SKILL.md, showed up on this real app:

- **Greenfield accessibility identifiers.** The app had *zero* `.accessibilityIdentifier`
  calls, but the skill's launch step polls `describe-ui` for a known `FIRST_SCREEN_ID` to
  confirm the app rendered. Fix: add one stable **leaf** anchor — `browse_verb_count` on the
  Browse tab's verb-count banner. It has to be a leaf, not a container, because SwiftUI rolls
  a parent's identifier onto every descendant in the AXTree.
- **Five-tab pill.** The shipped tab-pill centroid detector is calibrated for the canonical
  3-tab floating pill; Conjugar's 5-tab pill under-segments (it detected 3). So
  `MAIN_TABS_COORDS` is measured by hand off a screenshot (pixels ÷ 3 → logical points) and
  verified by tapping each of the five tabs and screenshotting that the right screen loads.

Verified end-to-end: `calibrate.sh` built and launched the app (the `browse_verb_count`
anchor confirmed render), then a tap through Models / Quiz / Info / Settings each highlighted
the correct tab. A stable symlink (`~/.claude/skills/ios-build-verify` → the versioned plugin
cache) keeps the terminal path from rotting on plugin updates. CLAUDE.md's *Build and Test
Commands* and *Running the App in the Simulator* sections now name the skill as the default
path, with raw `xcodebuild` demoted to a diagnostic fallback and `run-in-simulator` kept as a
no-AXe fallback.

## Settings, rebuilt to the design system (+ a breathing Start button)

SettingsView was the last screen still wearing its pre-migration clothes: a hand-rolled
`ZStack`/`ScrollView` of `HeadingLabel`/`SubheadingLabel`/`BodyLabel` modifiers and bare
segmented pickers, with a manual yellow title instead of the nav bar. Taking cues from the
**ios-design-agent-skill** audit and the sibling apps (Conjuguer, Konjugieren), it now speaks
the same visual language as the rest of the app:

- **Grouped cards.** A `NavigationStack` + large title over a scroll of `card()`s, one per
  concern — Region, Quiz (difficulty + tú/vos), Browse (tú/vos), and an actions card (Game
  Center, Rate or Review). Settings are grouped by the feature they affect rather than dumped
  in one long column.
- **Tinted SF Symbol headings.** Each section leads with a role-colored glyph — a blue
  `globe.americas.fill` for Region, a yellow `speedometer` for Difficulty, a green
  `graduationcap.fill` for the quiz pronoun, blue `books.vertical.fill` for browse — over a
  bold `.title3` yellow heading, a `.callout` explanation in secondary, and `GradientDivider`s
  splitting sections that share a card.
- **A new design-system primitive.** `GradientDivider` (a hairline that fades in from and out
  to transparent, ported from Konjugieren) landed in `Utils/`, and `TintedCapsuleButtonStyle`
  joined `Modifiers.swift` — a subtle tinted-capsule secondary action (keyed to its section's
  color) for "Enable" and "Rate or Review", lighter than the filled `PrimaryButtonStyle` CTA.
- **Motion & polish.** Segmented changes fire a `.selectionFeedback` haptic; the whole measure
  is `readingWidth()`-constrained for iPad; a small serif "Conjugar · vX (build)" footer closes
  the screen. The `@Observable SelectionStore` bridge stays because `Settings` is still a plain
  class, not `@Observable`.
- **Filename typo fixed.** The file was `SetttingsView.swift` (three t's) since 2019; it's now
  `SettingsView.swift`. The synchronized `Views/` group meant no `project.pbxproj` edit.

Separately, the Quiz screen's Start button borrows Conjuguer's subtle "breathing" pulse — a
`phaseAnimator` gently scaling it 1.0 ↔ 1.1 (0.9 s ease-in-out), suppressed under Reduce
Motion. It draws the eye to the primary action without the jarring >1.5× scale jumps the
design skill warns against.

## Clearing the iOS 26 deprecation & concurrency warnings

A pass to zero out the 12 build warnings that surfaced once the deployment target moved to
iOS 26:

- **`UIRequiresFullScreen` removed.** Deprecated in iOS 26 (and ignored in a future release);
  dropped from `Conjugar/Info.plist`. The app was already portrait-locked via
  `UISupportedInterfaceOrientations`, so behavior is unchanged.
- **StoreKit review prompt modernized.** `SKStoreReviewController.requestReview(in:)`
  (deprecated since iOS 18) became `AppStore.requestReview(in:)` in `ReviewPrompterReal`.
- **Game Center leaderboard UI de-deprecated.** `GKGameCenterViewController` and its
  `GKGameCenterControllerDelegate` were deprecated in iOS 26. `GameCenterReal.showLeaderboard()`
  now calls `GKAccessPoint.shared.trigger(state: .leaderboards)`, dropping the delegate
  conformance and the `gameCenterViewControllerDidFinish(_:)` method entirely. Tradeoff: it
  opens the dashboard on the leaderboards page rather than pushing the specific `leaderboardID`.
- **`RatingsFetcher` made concurrency-clean.** Under `SWIFT_DEFAULT_ACTOR_ISOLATION =
  MainActor`, the `URLSession` completion (a `@Sendable` closure running off the main actor)
  couldn't touch the type's MainActor-isolated statics or `L`. Fix: mark the pure statics
  (`errorMessage`, the URLs, `stubData`) `nonisolated`, mark the whole localization enum
  `nonisolated L` (it's just `String(localized:)` accessors — inherently actor-agnostic), and
  make the `completion` parameter `@escaping @Sendable`. The `fetchRatingsDescription` function
  itself stays MainActor so it can still read `Current.session`.

Result: `Build Succeeded` with no warnings; RatingsFetcher and GameCenter suites green.

## A full-codebase review before the next round of work

With the migration functionally complete, I had Claude do a max-effort review of the whole
codebase — app target, widget extension, `Shared/`, tests, build settings, and the string
catalog — looking for bugs, smells, duplication, outdated API use, and concurrency gotchas.
Baseline first: the full suite passed (403 tests, 0 failures) and SwiftLint reported zero
violations. The deliverable is `prompts/code-review-recommendations.md`: twenty ranked
recommendations plus a seven-step implementation sequence.

The headline finding was humbling: **Game Center has been inert for years**. The gate in
the quiz screen reads `guard !isAuthenticated, userRejectedGameCenter` — inverted, so only
users who *declined* Game Center ever get authenticated — and the condition was ported
faithfully from the UIKit-era `QuizVC`, where it dates back to a 2019-era commit. Stacked
on top: `Current.parentViewController` is never assigned (so the GameKit login sheet would
present on a detached `UIViewController()`), and `authenticate` wraps GameKit's long-lived,
multi-shot `authenticateHandler` in a `withCheckedContinuation` — a resumed-twice crash
waiting to happen. The fix is a small rewrite, not a patch.

Number two was the kind of bug only a data-driven review catches: `VerbFamilies`, the
hand-curated quiz lists, contains **`manecer`** — not in the 4,816-verb map and not standard
Spanish — so the new engine's regular fallback happily teaches a wrong subjunctive
(*"maneza"*) in roughly one Difficult quiz in twelve. `helar` (a 4A stem-changer, *hiela*)
sits in the *regular* -ar list, and `esconder` appears twice. The recommendation pairs the
three one-line fixes with a guard test pinning every list entry to the verb map — the
existing `QuizTests` couldn't catch this because it compares the engine's answers to the
engine's answers.

The rest of the top ten: browse search filters 4,811 verbs twice per keystroke *inside
`body`* — and plays the sad trombone as a side effect of view evaluation;
`applicationDidBecomeActive` never fires under the SwiftUI scene lifecycle (a trap for the
planned TelemetryDeck integration); InfoView's iPad reading-width conditional is inverted;
the tutor's tool-call counter is a `nonisolated(unsafe)` static shared across sessions; the
review-prompt date round-trips through a locale-fragile `DateFormatter` and a `Date()`
frozen at launch; the quiz widget's "deterministic" answer shuffle seeds from Swift's
per-process-random `Hasher`; and `CommunGetterReal` compares app versions as `Double`s
("2.10" < "2.9"). There's also a satisfying deletion queue — roughly 500 lines of dead
UIKit-era utilities (`conjugatedString`, `UsesAutoLayout`, appearance helpers, test relics)
that survived the migration only as fossils, plus dead members like `Quiz.pauseTimer` and
`World.parentViewController`.

Nothing in the engine itself drew blood: the feature-composition core, the resolver, the
bridge, and the widget snapshot pipeline all came through clean — the oracle-pinned test
suites are doing their job.

7/7/26: Started working through the code-review recommendations. **Phase 1 — the
data-and-one-liner bug fixes**, the batch of small, independent, high-confidence
corrections meant to land while the tree is quiet.

- **`VerbFamilies` data bugs (item 2).** The hand-curated quiz lists taught wrong
  Spanish. `manecer` isn't in the 4,811-verb map and isn't standard Spanish — it was a
  truncation of `amanecer` (whose dawn/dusk partner `anochecer` sits right beside it in
  the list), so I restored the intended verb rather than deleting the slot. `helar`
  (a 4A stem-changer, *hiela*) and — a fourth bug the guard test surfaced that the review
  hadn't named — `andar` (class 35, irregular pretérito *anduve*) were both misfiled in
  the *regular* -ar list, where the quiz drills them as regular drills (directly, and via
  `allRegularVerbs`, which feeds the pretérito/imperfecto/… questions); removed both. And
  the duplicate `esconder` in the -er list was skewing its round-robin cycle; removed one.
- **The guard test (item 2).** A new `VerbFamiliesTests` Swift Testing suite pins the
  lists to `VerbMap.shared`: every entry must resolve in the map, every `regular…` list
  must contain only verbs of its own regular class (-ar → 1, -er → 2, -ir → 3, comparing
  the *leading* class digit so orthographic variants like `buscar`@1-1 still pass), and no
  list may repeat an entry. This is the test `QuizTests` structurally can't be — it
  compares the engine's answer to the engine's own output, so it verifies self-consistency,
  not linguistic truth. Writing the intent down as a test is also what caught `andar`.
- **InfoView reading width (item 5).** The iPad conditional was inverted — regular size
  class got `.infinity`, removing the very measure cap `Layout.readingWidth` exists for, so
  article text sprawled the full window on iPad. Replaced with the standard unconditional
  `.frame(maxWidth: readingWidth)` + `.frame(maxWidth: .infinity)` pair the sibling screens
  use, and dropped the now-unused `horizontalSizeClass` environment read.
- **Review-prompt bookkeeping (item 7).** `Settings.lastReviewPromptDate` now stores a
  bare `timeIntervalSince1970`, retiring the locale-fragile `DateFormatter` (whose `'Z'`
  was a literal and whose `HH` could misparse under a 24-hour override). `ReviewPrompterReal`
  reads `Date()` at call time via an injected `() -> Date` seam instead of freezing `now`
  when `World.device` is built at launch, and it now receives `World.device`'s `Settings`
  instance rather than constructing a second one over the same UserDefaults keys.
- **Widget bugs (item 8).** The Quiz widget's "deterministic" answer shuffle seeded from
  `Hasher`, which is randomly seeded per process — and the extension is killed and
  respawned between renders, so the order visibly jumped on every relaunch. Swapped in a
  stable FNV-1a hash of the question id (keeping the nice SplitMix64 `SeededRNG`). Both
  timeline providers computed the next refresh as `startOfDay + 86_400`, which lands an
  hour off on DST-change days; now they add one *calendar* day.
- **Version compare (item 9).** `CommunGetterReal` parsed app and cloud versions as
  `Double`, so `"2.10"` read as older than `"2.9"` and any patch version (`"2.8.1"`)
  failed to parse and dropped the commun. Now compares the dotted strings with
  `.numeric`. (Needed an explicit `import Foundation` under `MEMBER_IMPORT_VISIBILITY`.)
- **Diacritic folding (item 20).** `ConjugationResult.compare` folded the five accented
  vowels but not `ü`, so *averigüé* vs *averigüe* scored `noMatch` instead of
  `partialMatch`; added `("ü","u")`, leaving `ñ` strict (a distinct letter). Extended the
  existing `ConjugationResultTests` with both the ü-partial and ñ-strict cases.

All green after the batch: build succeeds, the full suite is **406 tests / 0 failures**
(up from 403 — the three new guard tests), SwiftLint reports 0 violations.

## Phase 2 — the post-migration dead-code purge (item 10)

7/7/26: The SwiftUI migration left a fossil record behind — UIKit helpers, a font
table, property wrappers, and test relics that no shipping code path touched. This is
one sweeping deletion commit: zero behavior change, and it shrinks everything the later
phases have to edit. Every target below was confirmed unreferenced by a project-wide
search *before* deletion — the point of a dead-code purge is that "looks dead" isn't
good enough.

- **Whole files deleted (app target).** `StringExtensions.swift`
  (`conjugatedString`/`coloredString`/`replaceFirstOccurence` — superseded by
  `RichText`/`ConjugationText`, referenced now only in comments), its lone consumer
  `NSAttributedStringExtension.swift` (the `+`/`+=` operators), `UILabelExtension`
  (`titleLabel`), `UISegmentedControlExtension` (`yellowfyText` — no callers at all),
  `UIViewExtensions` (`pulsate` + `setAccessibilityLabelInSpanish`, kept alive only by
  its own test), `NSCoderExtension` (`fatalErrorNotImplemented`), `UsesAutoLayout` (the
  property wrapper, kept alive only by its own test), and `Fonts.swift` (the UIFont
  table — its only remaining references were the two dead files above and the dead
  test-support VC).
- **Whole files deleted (test target).** `TestingAppDelegate` +
  `TestingRootViewController` (the `@objc` delegate selection died with `main.swift`
  during the migration), `NavigationCSpy` (referenced by nothing), the test-only
  `UIColorExtension` (a `UIColor ==` used only by already-gone tests), and the
  tests-of-dead-code `UsesAutoLayoutTests` / `UIViewExtensionsTests`.
- **Partial deletions.** `FontExtensions` lost `heading`/`subheading`/`smallBody` (their
  only users were the deleted `Modifiers` labels) but keeps `button` (button styles) and
  `heroNumeral` (Results score). `Modifiers.swift` lost the five brand-type-label
  modifiers `HeadingLabel`/`SubheadingLabel`/`BodyLabel`/`StandardButton`/`SegmentedPicker`
  — never applied via `.modifier(...)`; their "kept for SettingsView" comment predated
  the SettingsView rebuild. `UIAlertControllerExtension` lost the dead `okTitle()` static
  (its `showMessage` stays — Game Center still calls it until item 1). `Quiz` lost
  `pauseTimer`/`resumeTimer` (no callers since the VC lifecycle went away), `DisplayTense`
  lost `conjugationCount(secondSingularBrowse:)` (legacy table-row math), `DisplayPersonNumber`
  lost `actualPersonNumbers`, and `VerbFamilies` lost the unreferenced
  `thirdPersonSingularOnlyVerbs`.
- **Held back for their owning phase.** `World.parentViewController` and the rest of
  `UIAlertControllerExtension` are still read by `QuizView`/`SettingsView` and
  `GameCenterReal`; they die with the Game Center rewrite (item 1, Phase 3), not here —
  Phase 2's contract is *zero behavior change*.
- **Xcode housekeeping was free.** Every source group (`Utils`, `Models`, `Views`,
  `Supporting`, `ConjugarTests`, …) is a `PBXFileSystemSynchronizedRootGroup`, so
  removing a file auto-removes it from the target — no `project.pbxproj` surgery. Also
  corrected CLAUDE.md, whose "`@UsesAutoLayout` survives for AppDelegate" sentence was
  stale (the wrapper is now gone).

Green after the purge: build succeeds, **406 tests / 0 failures**, SwiftLint 0 violations
across the remaining 149 source files.

## Phase 3 — the Game Center rewrite (item 1, folding in items 19 + the last of 10)

Game Center had been **inert for every user for years**, with a latent crash waiting for
the day it wasn't. Four interlocking bugs, fixed as one coherent rewrite modeled on the
sibling app Konjugieren's already-correct `GameCenterReal`.

- **The gate was inverted.** `QuizView.maybePromptGameCenter` authenticated *only* users
  whose settings said `userRejectedGameCenter == true` — i.e. only people who had said
  **No** ever got prompted (and then got force-authenticated on every Quiz visit), while a
  fresh install could never reach the dialog at all. The bug traces back to commit
  `cc4a651`; it predates the migration by years. Rather than fix the guard in place, the
  decision now lives in a pure, `nonisolated` `GameCenterPrompt.decision(isAuthenticated:
  userRejected:didShowDialog:)` returning `.doNothing` / `.showDialog` / `.authenticate`,
  and its four-row truth table is pinned by `GameCenterPromptTests`. Extracting it out of a
  private `View` method is what makes the corrected logic testable — and the guard-rail
  against a silent re-inversion (item 19).

- **`withCheckedContinuation` wrapped a multi-shot handler.** GameKit invokes
  `authenticateHandler` repeatedly for the life of the process (foregrounding, sign-in/out).
  The old code resumed a *checked* continuation from inside it, so the second invocation
  that reached a `resume` was a fatal "continuation resumed twice"; conversely the
  present-the-login-VC branch never resumed, leaking the continuation and hanging the
  caller's `Task` forever. `GameCenterReal` is now `@MainActor @Observable`, installs the
  handler **exactly once** (guarded by `didInstallHandler`), and treats it as a stream:
  it publishes `isAuthenticated` from `GKLocalPlayer.local.isAuthenticated`, fires the
  applause + analytics only on the false→true transition, and never re-assigns the handler.

- **The login sheet was presented on a detached VC.** `World.parentViewController` was
  declared but never assigned, so both call sites fell back to `?? UIViewController()` —
  presenting GameKit's sheet on a view controller that's in no window hierarchy silently
  does nothing. The handler now presents against the live window via the scene-aware
  `UIApplication.topViewController()`. With that, `World.parentViewController` is deleted,
  `UIViewController` is dropped from the `GameCenter` protocol (its **last** UIKit type),
  and `authenticate()` becomes a fire-and-forget `func authenticate()` — no view
  controller in, no `Bool` out.

- **Leaderboard ID raced / swallowed errors.** The ID was loaded in a fire-and-forget
  `Task`, so a `reportScore` racing right after auth submitted to `[""]`; on failure it
  became the sentinel `"ERROR"`, and `reportScore`'s `catch {}` swallowed everything. It's
  now loaded **lazily and cached** on first submit, `nil` until then, with both the load and
  the submit failures logged through `os.Logger` instead of discarded.

- **The failure path stopped using a UIKit alert on a detached VC.** `UIAlertController.
  showMessage(...)` was the only remaining consumer of `UIAlertControllerExtension`, so the
  extension (and its test-of-dead-code `UIAlertControllerExtensionTests`) — the last of the
  Phase 2 dead-code purge, held back because item 1 still used it — are deleted. Following
  the Konjugieren port, unauthenticated/error outcomes are now *logged*, and GameKit
  presents its own login sheet; the only Game-Center dialog left is QuizView's SwiftUI
  opt-in prompt. (SettingsView's Enable button hides on the next `onAppear` rather than the
  instant auth settles — reactive hiding waits on Settings observability, Phase 4 / item 11.)

- **The fake's semantics were straightened** (item 19): `GameCenterFake.authenticate()` is
  now idempotent — it authenticates the player — instead of the surprising "return `false`
  when already authenticated" artifact of the old `-> Bool` signature.

Green after the rewrite: build succeeds, **411 tests / 0 failures** (the new
`GameCenterPrompt` suite plus the reworked fake tests, net of the deleted dead-code test),
SwiftLint 0 violations. The live sign-in flow can only be exercised on a physical device —
the simulator Worlds use `GameCenterFake` — so the No→don't-nag / Yes→authenticate /
Settings-Enable→re-opt-in paths still want a device pass before shipping.

## Phase 4 — Settings observability (item 11) + became-active analytics (item 4)

Two Settings-adjacent fixes landed together so all the churn stayed in one window.

**`Settings` is now `@MainActor @Observable`.** It had been a plain class, so any view
that read a setting got no invalidation when it changed. The classic symptom: the Quiz
briefing's difficulty/region pills (`QuizView` reads `Current.settings.difficulty/region`
directly in `body`) only updated if something *else* happened to re-render the screen —
change the difficulty in the Settings tab, flip back to Quiz, and the pill could still show
the old value. Marking `Settings` `@Observable` fixes this for free: SwiftUI's Observation
tracking picks up the property reads during `body` even though `Current.settings` is a
global, not a `@State`/`@Bindable` the view owns.

**The `SelectionStore` bridge is gone.** That `@Observable` shim existed *only* to supply
the observability `Settings` lacked — `SettingsView` copied four settings into it in
`.onAppear` (via a nilable `current: World?`) and mirrored changes back through `didSet`.
Now the pickers bind straight to the real thing: `@Bindable private var settings =
Current.settings`, `$settings.region` / `$settings.difficulty` / etc. The store class, the
copy-in dance, and the `current` back-reference all deleted.

**~90 lines of clone-stamped persistence collapsed.** Every setting used to carry a
hand-copied `didSet`-guard-persist block *and* a read-or-seed-default `init` stanza. Those
are now funneled through two small `static` helper families — `read(_:_:default:)` and
`persist(_:_:_:_:)` — overloaded for string-backed `RawRepresentable` enums (Region,
Difficulty, the sorts, …) plus tiny `Int`/`Bool`/`Date` adapters. Each property's `didSet`
is a one-liner and each `init` assignment is a one-liner. (The helpers are `static` on
purpose: calling an *instance* method on a not-yet-fully-initialized `self` during `init` is
illegal, so `read` takes the `getterSetter` as a parameter instead.) Behavior is preserved:
the change-guard still skips no-op writes, and a missing key still seeds its default; the
one deliberate nuance — a present-but-unparseable value falls back to the default without a
rewrite — matches the pre-refactor code.

**`applicationDidBecomeActive` never fired — moved to `scenePhase`.** Under the SwiftUI
`WindowGroup` lifecycle the app adopts scenes, and UIKit delivers activation to the *scene*,
not the app delegate, so `AppDelegate.applicationDidBecomeActive` (and its
`recordBecameActive()` call) was dead. Harmless today because analytics is a print-only spy,
but a trap for the planned TelemetryDeck integration — launch/activation counts would have
been silently zero. The call now rides `MainTabView`'s existing `onChange(of: scenePhase)`
`.active` branch, which actually runs; the empty delegate lifecycle stubs
(`applicationWillResignActive`, `applicationDidEnterBackground`, …) went with it.

Green: build succeeds, **411 tests / 0 failures**, SwiftLint 0 violations. `SettingsTests`
and `SettingsViewTests` (both already Swift Testing, since a `@MainActor @Observable`
deallocated by XCTest would hit the Xcode 26.3 isolated-deinit double-free) pass unchanged.

## Phase 5 — View-layer hygiene (items 3, 13, 14)

Three view-layer cleanups that don't change what any screen *does*, only how much work
it does to do it — filtering, appearance config, and launch-path conjugation.

**Browse search: filter once, into `@State`, with the sound out of `body`.** The two browse
screens (`VerbBrowseView`, `ModelBrowseView`) had a `filteredVerbs`/`filteredModels`
*computed property* that scanned all ~4,811 entries with two case/diacritic-insensitive
`.range(of:)` probes each — and `body` read it *twice* per render (the count banner and the
`ForEach`), so every keystroke ran the full scan twice on the main thread. Worse, the shared
`BrowseSearch.results` helper played the sad trombone *as a side effect of view evaluation*
— the canonical SwiftUI anti-pattern, papered over with a 1-second `SoundPlayer` debounce
because `body` runs several times per keystroke. Now the filtered list is materialized into
`@State`, recomputed only in `.onChange(of: searchText)` / `.onChange(of: sort)`, and seeded
to the initial sort's full list so the first frame isn't a "0 verbs" flash. `BrowseSearch`
became a pure `nonisolated` function (the no-results sound moved to the caller's `.onChange`
handler — the one-shot search transition, where it belongs), so its unit suite dropped
`@MainActor` and the `playSoundIfEmpty` parameter. Per-keystroke work is halved and render is
side-effect-free.

**The legacy UIKit appearance layer, verified on-device-simulator and mostly deleted.**
`AppDelegate` had `configureTabBar()`/`configureNavBar()` setting `barTintColor`, `tintColor`,
and `titleTextAttributes` — pre-iOS-13 appearance APIs. Rather than guess, I screenshotted the
running app on iOS 26 and looked: the selected tab was system-**blue** (not the yellow
`tintColor` asked for), the large nav titles were **white**, and a detail screen's back chevron
was **white** — every one of those lines is inert under the Liquid-Glass bars, and the nav-bar
one even round-tripped `NSAttributedString.Key.foregroundColor` through its own `rawValue` for
no effect. Both methods deleted. The *one* appearance that does matter — yellow segmented-control
titles, visible on the Browse/Models sort pickers and every Settings picker — was being set from
`SettingsView.init`, which SwiftUI re-runs on every `MainTabView` body evaluation. Moved it to a
single `AppDelegate` call at launch; before/after screenshots are pixel-identical, so nothing
visible regressed and `SettingsView` no longer needs an `init`.

**Launch-path conjugation moved off-main, date-gated, and cached.** `WidgetSnapshotWriter.refresh()`
parses the 231 KB `verbModelMap.xml`, sorts ~1,000 ranked verbs, runs ~50 conjugations, encodes
JSON, writes the App Group file, and calls `reloadAllTimelines()` — and it ran synchronously on
the MainActor from `MainTabView.task` at launch *and again on every foreground activation*. Both
call sites now wrap it in `Task.detached` (everything it touches is already `nonisolated`/`Sendable`),
so the map parse no longer blocks post-launch taps. And `refresh()` is now date-gated: it reads the
`dateString` of the snapshot already on disk and, when it matches today, skips the rewrite *and* the
`reloadAllTimelines()` — the widget content changes once a day, so spending WidgetKit's refresh
budget on every activation was pure waste. Separately, `ModelView` was re-conjugating all 36 grid
slots (6 tenses × 6 persons) on every `body` evaluation; those forms are now precomputed once in
`init` into a `[[String?]]` the grid just reads.

Green: build succeeds, **411 tests / 0 failures**, SwiftLint 0 violations. The refactored
`BrowseSearchTests` (now nonisolated, calling the pure filter) pass unchanged.

---

## Phase 6 — Quiz + services internals (items 12, 15, 16, 6)

This was the "make the internals honest" pass: four unrelated bits of debt in `Quiz` and the
audio/tutor services, none user-visible on a good day, all traps for the next person to touch them.

**`Quiz` stops fighting itself (item 12).** The quiz carried thirteen near-identical cycling
accessors — `regularArVerb`, `irregularPreteritoVerb`, … — each a five-line `index += 1; wrap;
return` block paired with its own `…Index` var, plus a 13-line shuffle block and a 12-line
index-reset block in `start()` (which, incidentally, forgot to reset one of the thirteen). All of
it was one abstraction: a `Cycler` cursor (`restart(shuffle:)` + `next()`) that preserves the
original stepping exactly (advance-first, so the first draw is element 1 and element 0 is reached
only after a wrap). `Quiz` now holds `let regularAr = Cycler(VerbFamilies.regularArVerbs)` etc. and
an `allCyclers` array, so both the shuffle and reset blocks collapse to one loop that can't skip a
list. `settings`/`gameCenter`, stored as optionals and then `fatalError`-guarded in three places
despite the initializer always setting them, became non-optional `let`s — three crash paths gone.
`questions.shuffled().shuffled()` (one uniform shuffle was always enough) became `questions.shuffle()`.
And `process()`'s `default: fatalError()` — which would crash a learner mid-quiz if the engine ever
returned `.failure` for a quiz slot — now logs the slot and scores the question as a miss, still
appending to `proposedAnswers`/`correctAnswers` and advancing so the run finishes cleanly. (The
`VerbFamilies`↔`VerbMap` guard test from Phase 1 makes that branch "can't happen," but degrading
beats crashing.)

**The tutor stops polling forever (item 15).** `LanguageModelServiceReal` started an unconditional
`while true { sleep 5s; re-check availability }` loop in `init` — for the whole app lifetime, on
every launch, even for users who never open the Info tab, and it kept polling after availability
settled. It exists so the Info-tab entry point can flip live between "tappable" and "Apple
Intelligence not enabled," which only matters while that screen is visible. The loop is now behind
`startAvailabilityMonitoring()` / `stopAvailabilityMonitoring()`, driven by `InfoBrowseView`'s
`onAppear`/`onDisappear`, and it self-terminates the moment the model reports available (the common
transition is one-way). The `LanguageModelServiceDummy` no-ops both.

**The tool-call counter loses its `nonisolated(unsafe)` (item 6).** `ConjugationTool` capped tool
calls per turn with a `nonisolated(unsafe) private static var callCount`, incremented from wherever
the FoundationModels runtime invokes the tool and zeroed from the MainActor before each send — an
unsynchronized read-modify-write across actors that the annotation merely silenced, and *global*, so
a chat and the `TutorTestView` batch shared one counter. It's now a per-instance
`OSAllocatedUnfairLock(initialState:)` (reference semantics, so it survives the struct being copied
by the runtime), reset through the single tool instance the service now reuses across sessions. Same
per-message cap, no race, no global sharing.

**One audio-session owner, deliberately `.ambient` (item 16).** `Utterer.setup` set the shared
`AVAudioSession` to `.playback` **with** `.mixWithOthers`; `SoundPlayer`'s lazy `init` later set
`.playback` **without** it. Last writer won on the shared session, so the first quiz chime would
reconfigure it and stop the user's podcast — and `.playback` plays through the silent switch, wrong
for a study app's feedback chirps. `Utterer` is now the sole owner, configured once at launch to
`.ambient` (mix with other audio *and* respect the silent switch — the right contract, and speech
still works under it). `SoundPlayer` no longer touches the category; its `print`-on-error became a
`Logger`, and its `Int.random(in: 0...count-1)` sound picks became `randomElement()`.
`Utterer.settings` shed its optional + `fatalError` for a non-optional injected default. The
2016-vintage `SoundPlayer.play(.silence)` workaround after each utterance was left in place pending a
physical-device check — it's cheap and removing it risks a speech-audio regression I can't verify in
the simulator.

Green: build succeeds, **411 tests / 0 failures**, SwiftLint 0 violations. `QuizTests`' six
region/difficulty perfect-run score invariants — the safety net for the `Cycler` rewrite — pass
unchanged.

---

## Phase 7 (item 17, in progress) — tab-bar modernization: `Tab` API + new dancer/bull glyphs

**The `.tabItem`/`.tag` pair became `Tab(_:image:value:)` builders (item 17).** `MainTabView`'s
`TabView` used the soft-deprecated (since iOS 18) `.tabItem { Label(...) } .tag(...)` pattern on each
of the five screens. On an iOS-26-only app there's no reason to stay on it, so each screen is now a
`Tab(title, image:/systemImage:, value:) { screen }` builder keyed on the existing `AppTab: Hashable`
selection value. Behaviourally identical — all five tabs render in order (verified on-simulator:
Browse · Models · Quiz · Info · Settings) — but it reads cleaner and unlocks the newer tab-bar
behaviours. Staged deliberately against the *current* bitmap assets so it builds green ahead of the
glyph swap; replacing the dancer/bull is now a one-word `image:` → `systemImage:` change on two lines.

**New dancer + bull glyphs sourced to fix the SF-Symbols weight mismatch.** Four tabs used custom
PNG line-art (dancer/bull/question-mark/gear) while Models used the solid SF Symbol `key.fill`; the
dancer and bull in particular are hairline single-weight outlines that read visibly thinner than the
system glyphs beside them. Rather than regenerate them with a raster image model (wrong tool — no
vector output, no controllable stroke weight), the plan is Apple's **custom-symbol** pipeline: bring
clean monoline SVGs into the SF Symbols app, normalise to a Regular-weight stroke, export `.symbol`
files that render identically to real SF Symbols. Two royalty-free line icons were chosen from the
Noun Project and downloaded as SVG under **CC BY 3.0** (the free, attribution-required tier):

- **Bull** (Quiz) — *bull* by **taash5studio**, full-body standing pose (preserves the current
  composition, heavier even stroke).
- **Flamenco dancer** (Browse) — *flamenco dance* by **Amethyst Studio**, the classic arm-raised
  ruffled-dress pose.

**Credits updated ahead of the swap.** The Info-tab `^Icons^` credits (`Info.creditsText` in
`Localizable.xcstrings`, both `en`/`es`) previously credited the outgoing dancer (Borja Santos Lobo)
and bull (Saeful Muslim) under CC BY-**SA** 3.0. Those two lines now credit **Amethyst Studio** and
**taash5studio** under CC BY 3.0 (Attribution only), naming the Noun Project as source — the license
these new glyphs actually ship under. Catalog re-validated as JSON after the edit.

Still outstanding for item 17: produce the two `.symbol` files in the SF Symbols app (a hands-on GUI
step, plus the artists' SVGs already on disk), drop them into `Assets.xcassets`, flip the two
`image:` args to `systemImage:`, and delete the `Browse`/`Quiz`/`Dancer` bitmap imagesets. Build
green after the refactor; SwiftLint clean.

**Update — three tabs converted to stock SF Symbols, whole bar pinned to one outline family.**
Info and Settings didn't need custom art at all: the `?`-in-triangle and gear map onto stock
`info.circle` and `gearshape`, and Models' solid `key.fill` became the outline `key` for consistency.
That surfaced a platform gotcha worth writing down: **iOS tab bars auto-substitute the `.fill`
variant of any SF Symbol**, so `key`/`info.circle`/`gearshape` all rendered *filled* — clashing with
the outline line-art dancer/bull. Setting `.environment(\.symbolVariants, .none)` on the `TabView`
does **not** fix it (the tab-bar chrome renders its labels outside that environment). The fix that
works is the explicit-label `Tab(value:content:label:)` initializer with `.symbolVariants(.none)`
pinned on the `Label` itself — verified on-simulator, one symbol at a time. All three symbol tabs now
use that form and render outline, matching the custom glyphs. The two bitmaps (`Info`, `Settings`
imagesets) were deleted, and the now-obsolete "Mariela Peña created the gear and question-mark icons"
credit was removed from `Info.creditsText` (both `en`/`es`, catalog re-validated). The stock outline
symbols now double as the on-screen **stroke-weight reference** for the pending dancer/bull custom
symbols: match `key`/`gearshape`'s Regular-weight stroke, not an arbitrary thickness. Build green;
SwiftLint clean.

**Update — the dancer and bull custom symbols, generated by script (no vector editor).**
Item 17 is done: Browse and Quiz now use custom SF Symbols (`dancer`/`bull`) spliced from the two
Noun Project line icons into a `gearshape` template exported from SF Symbols.app. No vector editor
was needed — a Python script parses each artwork's true bbox (sampling the Béziers), fits it to the
reference glyph's bbox in every weight/scale slot, and emits the `.symbolset`. Three things the
iteration surfaced, worth remembering:

- **The symbol compiler honours `fill`, not `stroke`.** Adding a stroke to thicken the line art did
  nothing even at 16 template units (~20% of cap height). Weight has to come from *geometry*: the
  script dilates the fill by unioning several offset copies on a small radius (a disk-approximation
  Minkowski sum). `GROW=1` template unit matched `key`/`gearshape` cleanly; `GROW≥2` closed the line
  art's internal gaps and turned it to a blob.
- **`<defs>`/`<use>` *is* honoured** — defining the dilated art once and referencing it per slot took
  the dancer symbol from **3.2 MB to 90 KB** (bull 34 KB) with identical rendering.
- **Custom symbols use `image:`, not `systemImage:`**, and aren't subject to the tab bar's `.fill`
  auto-substitution, so they render their line art as-is and needed no `symbolVariants` override.

Final tab bar: dancer · key · bull · info.circle · gearshape — one outline family at matched weight.
The old `Browse`/`Quiz`/`Dancer` bitmap imagesets are deleted; credits already point at the new
artists (CC BY 3.0). Build green, SwiftLint clean, verified on-simulator.

The bull is rendered at 1.2× (a per-symbol scale in the generator) so it fills the slot like
`key`/`gearshape` and its legs/horns read clearly; the dilation is computed against the scaled size,
so the stroke stays weight-matched to the stock symbols rather than growing with it. The generator
and its source SVGs live in `scripts/` (`make_symbols.py`, `symbol-sources/`) so the symbols are
reproducible from source.

---

## Phase 7, part 2 — accessibility, test depth, and the polish grab-bag (items 18, 19-remainder, 20)

Item 17 (the `Tab` API + unified icons) closed the modernization work earlier in Phase 7; this pass
finishes the phase with accessibility, test depth, and a long tail of micro-cleanups.

**Item 18 — rows that are actually buttons, and Spanish that VoiceOver pronounces as Spanish.** The
browse/detail lists navigated on a bare `.onTapGesture`, which gives a tap target none of a button's
semantics: no `.isButton` trait, no press highlight, weaker VoiceOver. Browse Verbs and Models now
use `NavigationLink(value:)` (their `navigationDestination`s already handle `String`/`ModelInfo`),
and `ModelView`'s "verbs using this model" rows — whose closure-based navigation is deliberate —
wrap that closure in a `Button`. All three take `.buttonStyle(.plain)` so the visual stays identical
while the semantics upgrade. The bigger win is speech: the retired UIKit app tagged conjugations
with `accessibilitySpeechLanguage` es, so VoiceOver said *hablo* with Spanish vowels; the SwiftUI
screens had lost that, reading Spanish forms with English pronunciation. `ConjugationText` now stamps
`languageIdentifier = "es"` on the whole attributed form, restoring Spanish pronunciation across the
Verb, Model, and Results screens. (Under `MEMBER_IMPORT_VISIBILITY` that attribute needs an explicit
`import Foundation` — the transitive SwiftUI import no longer leaks it.) And because the tap-to-hear
gesture is deliberately skipped under VoiceOver, `speakOnTapFlash` now also exposes a named
`.accessibilityAction(named: L.Accessibility.speak)` ("Speak" / "Pronunciar") so VoiceOver users get
the same pronounce-aloud affordance.

**Item 19 — pinning Spanish truth, not the engine's own answer.** The guard test (Phase 1) and the
Game Center gating tests (Phase 3) already landed; what was missing was golden coverage of the quiz
*content*. `QuizTests` only proves self-consistency — it scores a run by comparing each answer to the
same engine output the quiz asked for — so a mis-conjugating engine would still pass. The new
`QuizGoldenFormsTests` drives 58 (verb, tense, person) triples, one batch per `VerbFamilies` list
paired with the tense that list is quizzed at, and compares the **lowercased** (marking-stripped)
engine output to hand-written, independently-known Spanish. Lowercasing is the trick that keeps the
assertion about *letters* (linguistic truth) rather than the engine's UPPERCASE irregularity
encoding. All 58 matched on the first run — confirming both the hand-written forms and the engine.
Alongside it: `SettingsViewTests` swapped its vacuous `body is (any View)` (true by construction) for
a real crash smoke test (`_ = body`), and `QuizTests` now iterates **both** `shouldShuffle` values so
the deterministic run pins reproducible content while the shuffled run still exercises that path.

**Item 20 — the grab-bag.** Deleted the junk `""` string-catalog key (auto-extracted from unlabeled
`Picker("")`/`TextField("")`) and gave those six controls explicit `Text(verbatim: "")` labels so it
can't regenerate. Rewrote `RatingsFetcher` from a completion handler + `JSONSerialization` dictionary
walk to `ratingsDescription() async -> String?` over `URLSession.data(for:)` + a `Decodable`
response; `SettingsView` now calls it from a `.task` and shows a new `Settings.ratingsUnavailable`
message on failure instead of a silently-empty row, and the hardcoded Spanish exhortation moved into
a `Settings.beFirst` catalog key (kept Spanish in both localizations by design, so the mixed-language
flavor is now visible to translation). Smaller ones: `AppRouter` uses `url.host()` instead of the
soft-deprecated `url.host`; the widget target gains `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`
to match app+test — which promptly surfaced three latent missing `import WidgetKit`s in the widget
views (exactly the kind of transitive-import rot the flag exists to catch); the unused
`aps-environment` entitlement is dropped (the commun fetch polls at launch, nothing registers for
push); and explanatory comments now pin the persisted-raw-value contract on both `SecondSingular*`
enums and the deliberately mixed-gender `él`/`ellas` pronoun pairing. `RatingsFetcherTests` was
adapted to the async API but kept as XCTest on purpose — it mutates the global `Current`, and
XCTest's serial execution keeps that from racing the other `Current`-reassigning suite, which a
parallel Swift Testing suite would not. The diacritic-identifier cleanup stays opportunistic: retired
`expectatiön` in the rewritten test file, left the rest where they sit until those files are touched.

Build green, 412 tests / 0 failures, SwiftLint clean. Phase 7 is complete.

## Etymology pipeline scaffolding (Spanish)

Stood up the data pipeline for per-verb etymologies, mirroring the sibling apps Conjuguer
(French) and Konjugieren (German) — a `VerbView` feature that shows a short, bilingual
etymology below the conjugations. This checkpoint lays the *foundation*: it populates no
etymologies yet, it creates the machinery to generate and load them.

- **Work-list** (`prompts/etymology-verbs.json`, 988 verbs): built straight from the
  frequency ranks already baked into `verbModelMap.xml` (the `fr` attribute, sourced from
  `docs/SpanishVerbFrequencyRanks.txt`). One entry per infinitive, `gloss` from the `tn`
  display-gloss, homonyms (e.g. `apostar` — *bet; station*) collapsed to a single row. The
  1..1000 rank sequence has gaps, hence 988, not 1000.
- **`Etymology.swift`**: a `nonisolated`, load-once cache (an `NSLock`-guarded
  `@unchecked Sendable` class, the `VerbMap` pattern — kept engine-adjacent rather than
  `@MainActor` like Conjuguer's, so the lookup composes with the nonisolated engine). Reads
  the bundled `Etymologies.json`, keyed language → infinitive → text, device language with
  English fallback. `Models/` is a synchronized root group, so the new `.swift` and `.json`
  needed no `project.pbxproj` edit and the JSON auto-bundles.
- **`Etymologies.json`**: seeded with one hand-authored, tilde-parity-checked entry
  (`estar` — the direct Spanish reflex of the `stāre`/`*steh₂-` chain used as Conjuguer's
  vetted worked example), so the pipeline has a file to accumulate into.
- **`prompts/etymology-pipeline.md`** + **`run-etymology-pipeline.md`**: the Spanish port of
  Conjuguer's generation pipeline — parallel `general-purpose` subagents, transcript
  extraction, a markup validator (even tilde counts, en/es parity, no ASCII quotes, recon
  asterisk placement), merge-through-`json.dumps`, progress reporting. Spanish-specific
  adaptations: `en`/`es` (not `fr`), pretérito indefinido register, `« »` guillemets,
  es.Wiktionary/DLE/Corominas as primary sources with en.Wiktionary for the PIE chain, an
  Arabism accuracy note, and a select set of rare defectives (yacer, abolir, placer, asir,
  balbucir, atañer) beyond the ranked 988.

The pipeline also carries **deep-dive guidance for `ser` and `haber`** — the two most-used
verbs get the fuller three-paragraph treatment Conjuguer gives `être`/`avoir`, and since the
Latin origins align, most of the reference text lifts whole-cloth. `haber` reuses `avoir`'s
`habēre` chain, the "English *have* is not a cognate" point, and the German-`haben` /
`*keh₂p-` / Sprachbund payoff, then pivots on the Spanish-specific twist (Spanish ceded
possession to `tener` and leveled the old `ser`/`haber` auxiliary split, generalizing `haber`
— `hay` < `ha` + locative `y`). `ser` keeps `être`'s suppletion framing but swaps the donor
verbs: `esse` (present/imperfect), `sedēre` "to sit" (the infinitive `ser` itself + future/
subjunctive), and `fuī` (the preterite it shares wholesale with `ir`).

Remaining lifecycle step (deliberately not in this checkpoint): wiring the `~…~`→bold
renderer and an etymology card into `VerbView`, then running the pipeline across sessions to
fill the 988. Build green, JSON valid.

### Etymology UI (VerbView card)

Wired the display half. `VerbView` now shows an **etymology card below the conjugation
sections** whenever `Etymology.text(for:)` has an entry (verbs without one — the vast
majority until the pipeline runs — render nothing, no empty card). The card reuses the
serif-yellow section heading of the tense cards (`L.Verb.etymology` → "Etymology" /
"Etimología", added to `L.swift` + the catalog) over a plain `.card()`, so it reads as a
peer section without stealing a tense's accent bar.

The renderer is a new **`EtymologyText`** view (mirroring `ConjugationText`'s dedicated-view
pattern) with its **own** minimal parser — deliberately *not* the Info `richTextBlocks`
parser — so etymology prose can contain a stray `%`, `$`, or `^` without it being misread as
Info markup. It splits on the bold marker `~`, toggling `.stronglyEmphasized` (which composes
with Dynamic Type rather than pinning a font), and passes every `*` through verbatim so a
reconstruction asterisk (`*~steh₂-~`) renders literally. Matches Conjuguer's
`String.etymologyAttributedString` approach, adapted to Conjugar's post-migration
system-font stack.

Verified on-device-sim by deep-linking `conjugar://verb/estar`: the seeded `estar` card
renders with correct bold forms, literal reconstruction asterisks, the `₂` subscript, and
the `\n\n` paragraph gap; `hablar` (no entry) shows no card. Five Swift Testing cases cover
the renderer (bold spans, asterisk pass-through, paragraph preservation, unmarked
round-trip, marker-stripping). Build green, SwiftLint clean, tests pass.

## Etymology pipeline — batch 1 (ranks 1–51)

Ran the first real generation batch of the Spanish etymology pipeline: 50 verbs, the
50 smallest-remaining usage ranks (1–51, minus the pre-seeded `estar`), covering the
absolute core of the language — `ser`, `haber`, `tener`, `poder`, `hacer`, `decir`, `ir`,
`dar`, `ver`, `deber`, `pasar`, `querer`, `saber`, `poner`, `llevar`, `dejar`, `conocer`,
`creer`, `tratar`, `hablar`, `venir`, `vivir`, `mantener`, `abrir`, `crear`, and the rest.
Five `general-purpose` subagents × 10 verbs, launched in parallel, each returning a bilingual
(en/es) JSON block. `Etymologies.json` now holds **51/988** ranked verbs in both languages.

- **`ser` and `haber` got the three-paragraph deep-dive treatment** (matching Conjuguer's
  `être`/`avoir`). `haber` lands the Spanish payoff: possession ceded to `tener`, the old
  `ser`/`haber` auxiliary split leveled to universal `haber`, and `hay` < medieval `ha` +
  locative `y` (< `ibī`). `ser` swaps `être`'s donors for the Spanish three — `esse`
  (present/imperfect), `sedēre` "to sit" (the infinitive `ser` itself + future/subjunctive),
  `fuī` (the preterite shared wholesale with `ir`). `ir` got the parallel suppletion story
  (`īre` + `vādere` + `fuī`), so the two entries cross-reference cleanly.
- **Disputed origins were hedged, not laundered** — exactly the pitfall the pipeline warns
  about. `tomar` (« de origen incierto », Corominas' `autumāre` vs. Walsh's `domāre`),
  `buscar` (`bosque` vs. Celtic `*boudi`), `trabajar` (the `tripalium` torture-frame story,
  flagged as debated rather than asserted), `llegar` (the nautical "fold the sails" path),
  and `considerar` (the `sīdus`/"observe the stars" hypothesis, paired with `desear` <
  `dēsīderāre`) all carry their hedge in both languages.
- **A subagent caught two source errors**: en/es.Wiktionary wrongly call English *leave* a
  cognate of `dejar` (it's Germanic — used *lax*/*relax*/*slack* instead), and `salir` was
  kept clear of the false `sal`/*salt*/*sauce* conflation.
- **Step 4 markup validation passed clean on the first try** — all 100 (verb, lang) values:
  even tilde counts, en/es tilde parity, no ASCII quotes, real paragraph breaks, no misplaced
  reconstruction asterisks.

**Pipeline friction (fed back into the lessons):** two of the five subagents emitted their
JSON with **real literal newlines inside the string values** (as the prompt's "use real line
breaks" instruction invites), which the Step 3 extractor's `json.loads(text)` rejects with
`Invalid control character`. Fix: parse the transcript text with `json.loads(text,
strict=False)`, which accepts control characters inside strings; the re-serialization to
`/tmp/etym_g*.json` then normalizes them to `\n`. Added this to the pipeline's Lessons.

Next: `necesitar` (rank 52).

## Etymology pipeline — batch 2 (ranks 52–101)

Second generation batch: 50 verbs, ranks 52–101 — the next tier of high-frequency verbs
(`necesitar`, `mostrar`, `lograr`, `comenzar`, `establecer`, `leer`, `pedir`, `producir`,
`obtener`, `gustar`, `convertir`, `escribir`, `recordar`, `entender`, `sentir`, `terminar`,
`decidir`, `formar`, `jugar`, `reconocer`, `entrar`, `comprar`, `pagar`, `dirigir`, and the
rest). Five `general-purpose` subagents × 10, launched in parallel, each returning a bilingual
(en/es) JSON block. `Etymologies.json` now holds **101/988** ranked verbs in both languages.

- **Step 4 markup validation passed clean on the first try again** — all 100 (verb, lang)
  values: even tilde counts, en/es parity, no ASCII quotes, real paragraph breaks, no
  misplaced reconstruction asterisks. No re-dispatches needed; every agent returned both
  languages for all ten verbs.
- **Disputed origins hedged, not laundered**, as the pipeline demands: `ganar` (Corominas'
  Gothic `*ganan` "to covet" — explicitly *not* the same word as `guadagnare` < Frankish
  `*waidanjan`, a distinction Corominas insists on); `perder`'s `-dere` (the traditional
  `dare` < PIE `*deh₃-` vs. the newer `*dʰeh₁-` analysis); `señalar`/`signum` (PIE `*sek-`
  "cut" vs. `*sekʷ-` "follow"); `cambiar`'s Celtic `*kambos` "curved" semantic bridge;
  `forma`'s contested link to Greek `morphḗ` by metathesis; and `evitar`, whose `vītāre` the
  entry honestly lands as genuinely uncertain ("an honest etymology sometimes ends in a
  shrug").
- **Memorable payoffs that are actually settled**: `empezar`'s Celtic heart (`pieza` <
  Gaulish `*pettyā`), `recordar` = "to bring back through the heart" (`cor`, cognate with
  English *heart*), `desarrollar` = literally "un-roll a scroll," `pedir` < `petere` where
  "to ask" and "to attack" were one verb (launch yourself at what you want), `pagar` <
  `pācāre` "to pacify" (appease a creditor → pay him; and `apagar` = "make peace with a
  flame"), `acabar` < `cabo` < `caput` "head" (cognate with English *head*), and `mejorar`'s
  suppletion (`mejor` < `melior`, unrelated to `bueno`, like English good/better).
- **No pipeline friction this run.** The `strict=False` fix from batch 1 handled the couple of
  agents that again used literal newlines in their JSON values; Step 3 extraction, Step 4
  validation, and the merge all ran without incident.

Next: `intentar` (rank 102).

## Etymology pipeline — batch 3 (ranks 102–151)

Third generation batch: 50 verbs, ranks 102–151 (`intentar`, `servir`, `aplicar`,
`compartir`, `referir`, `mirar`, `alcanzar`, `continuar`, `elegir`, `iniciar`, `sacar`,
`construir`, `enviar`, `cerrar`, `preguntar`, `aprender`, `celebrar`, `desear`, `caer`,
`morir`, `nacer`, `sufrir`, `escuchar`, `responder`, `vender`, `proponer`, and the rest).
Five `general-purpose` subagents × 10, launched in parallel, each returning a bilingual
(en/es) JSON block. `Etymologies.json` now holds **151/988** ranked verbs in both languages.

- **Step 4 markup validation passed clean on the first try yet again** — all 100 (verb, lang)
  values: even tilde counts, en/es parity, no ASCII quotes, real paragraph breaks, no
  misplaced reconstruction asterisks. No re-dispatches needed.
- **Disputed origins hedged, not laundered**, as the pipeline demands: `sacar` (Corominas'
  favored Gothic `sakan` "to quarrel/sue" vs. the competing `saccus` "sack" account — the
  vivid win-by-lawsuit image explicitly flagged as hypothesis); `alcanzar` (Vulgar Latin
  `*incalciāre` "tread on the heels," with the `al-` prefix reshaping itself uncertain —
  Latin `ad`, the contraction `al`, or Arabic `al-`); `cerrar`'s `s-` > `c-` shift (Corominas'
  proposal via `cercar`, not settled fact); `preguntar`'s sailor's-sounding-pole image
  (`contus`, the traditional-but-not-certain account); `celebrar`/`celeber` (the appealing
  link to `celer` "swift" is *not* established — origin left unknown); `desear`/`dēsīderāre`
  (the charming "star" etymology, `dē-` + `sīdus`, offered as one proposal since some reject
  the `sīdus` connection); and `proponer`, where the entry declines to claim French `proposer`
  / English `propose` descend phonologically from `prōpōnere` (they belong to the `poser` <
  `pausāre` family that merely merged in sense) and flags the `po-` + `sinere` split as a
  reconstruction.
- **Memorable payoffs that are actually settled**: `aplicar`/`plicāre` "to fold" — the same
  root that, via folding a ship's sails on nearing shore, gave `llegar` "to arrive";
  `mirar` < `mīrārī` "to marvel," a blood relative of English *smile*, its wonder drained
  into plain "to look" but preserved in `milagro`/`maravilla`; `acompañar` < `companio`, the
  "bread-fellow" (`com-` + `pānis`); `responder` < `spondēre`, a pledge sworn over a
  libation, source of `esposo`/`esposa` *and* `esposas` "handcuffs" (both the bound ones);
  `añadir`'s doubly-redundant "to it" (`in-` piled on `ad-` + `dare`, both already "to");
  `informar` = literally "to put into form," with the `forma`/`horma` doublet; and `caer` <
  `cāsus` "a falling," behind `caso`, `casualidad`, `ocaso`, and grammatical "case."
- **No pipeline friction this run.** One agent (group 5) appended a prose "notes" block after
  its JSON, tripping `json.loads` with `Extra data`; the documented `raw_decode` recovery
  grabbed the first object cleanly. The `strict=False` fix again absorbed agents' literal
  newlines. Otherwise Step 3 extraction, Step 4 validation, and the merge ran without incident.

Next: `definir` (rank 152).

## Etymology pipeline — batch 4 (ranks 152–251)

Fourth generation batch, and the first to scale up to a **full 100 verbs**: ranks 152–251
(`definir`, `interesar`, `observar`, `entregar`, `contener`, `declarar`, `ocupar`,
`constituir`, `descubrir`, `sentar`, `subir`, `soler`, `significar`, `tocar`, `marcar`,
`crecer`, `avanzar`, `resolver`, `suceder`, `traer`, `comer`, `obligar`, `adquirir`,
`lanzar`, `proteger`, `cubrir`, `exponer`, `faltar`, `correr`, `comprender`, `controlar`,
`defender`, `poseer`, `bajar`, `mover`, `imponer`, `surgir`, `elevar`, `diseñar`, `meter`,
`valer`, `levantar`, `otorgar`, and the rest). Ten `general-purpose` subagents × 10,
launched in two parallel messages of five, each returning a bilingual (en/es) JSON block.
`Etymologies.json` now holds **251/988** ranked verbs in both languages.

- **Batch size doubled without incident.** Ten agents ran cleanly in parallel; no compaction,
  no lost transcripts. Confirms the pipeline's "3–5 × ~8" guidance is conservative — 10 × 10
  works when the batch is split across two send messages.
- **New friction: half the agents copied ASCII quotes from the worked example.** Groups 1, 6,
  and 7 (30 English entries) used straight `"…"` for glosses instead of the required curly
  `"…"`, because the subagent-prompt's worked example itself rendered them as ASCII (the
  pipeline file's example uses real curly quotes, but they flattened when pasted into the
  Agent-tool prompt string). The Step 4 `ASCII " in prose` check caught all 30; a mechanical
  paired-quote substitution (`"([^"]*)"` → `"…"`) fixed them and re-validation passed clean.
  **Lesson for next run: paste real curly quotes `" "` / guillemets `« »` into the worked
  example, or the agents mirror whatever they see.**
- **Extraction gotcha re-confirmed:** the Step 3 default `raw_decode` runs in *strict* mode,
  which silently drops any agent that emitted real literal newlines (4 of 10 this batch →
  "0 verbs"). Re-running just those with `json.JSONDecoder(strict=False)` recovered all of
  them. The scan-all-objects extractor needs `strict=False` **by default**, not as a fallback.
- **Disputed origins hedged, not laundered:** `soler` (De Vaan rejects the traditional
  `*swe-dʰh₁-` "set as one's own" for a phonological reason — a following `ē` should block
  `swe-` > `so-`; origin left unsettled); `tocar` (Germanic *or* onomatopoeic, no secure PIE
  root); `marcar` (native denominal vs. Italian loan, both over a Germanic `*markō`); `planta`
  (`*pleh₂-` "flat" vs. `*pleh₂k-` "to strike", unresolved); `causa` (possibly non-IE, perhaps
  Etruscan); `bassus` behind `bajar` ("of uncertain origin" — Oscan? Celtic? Greek `bathýs`?);
  `frons` behind `enfrentar` (De Vaan: "no plausible etymology"); `fallere` behind `faltar`;
  and `obligar`'s coda on the ancient `religiō` dispute (Lactantius' `religāre` "to bind" vs.
  Cicero's `relegere` "to reread", never settled).
- **Memorable payoffs that are actually settled:** `ser`-relative `sedēre` "to sit" surfacing
  under `sentar`, `poseer` (`potis` "master" + `sedēre` = "to sit as master over"), and
  `situar`; `ocupar`/`aceptar`/`comer` all riding the `capere`/`have`-is-not-`habēre` false-
  cognate note; `elevar`/`llevar` and `colocar`/`colgar` as learned/inherited doublets from
  one Latin verb; `avanzar`'s intrusive English `d` (`advance`, a scribal misreading of `av-`
  as `ad-`); `declarar`'s `clārus`, a *sound* word ("loud, ringing") that crossed to light
  ("clear, bright"); `depender`/`pesar`/`pensar` all hanging from `pendēre`; and `controlar` <
  `contre-rôle`, the counter-register wheel (`rota`) that also spun off `role`.

Next: `invitar` (rank 252).

7/9/26: Fixed a partial-tap-target bug in Browse Verbs.

- **Symptom.** Only the drawn glyphs of a verb row (infinitive, gloss, rank badge)
  were tappable; the transparent `Spacer` gap and the row's padding fell through, so
  the cell felt only partly tappable and drilling into a verb sometimes missed.
- **Cause.** `VerbRowLabel`'s `HStack` had no explicit content shape, so SwiftUI
  hit-tested only its opaque subviews — the `NavigationLink` wrapping it inherited the
  same holey target.
- **Fix.** One line: `.contentShape(Rectangle())` on the padded row frame in
  `VerbBrowseView.swift`, declaring the whole cell as the tap area.
- **Verified in the simulator.** Tapping the previously-dead empty right-of-center gap
  of the "poder" row now `describe_ui`-resolves to a full-width `Button "poder, can"`
  (frame x:0, width:402) and navigates to the Poder detail screen. This also unblocks
  ios-build-verify's tap-to-drill-down on a verb.

## Etymology pipeline — batch 5 (ranks 252–351)

Fifth generation batch, a second **full 100 verbs**: ranks 252–351 (`invitar`, `importar`,
`armar`, `concluir`, `modificar`, `destinar`, `brindar`, `describir`, `seleccionar`,
`asociar`, `encargar`, `apuntar`, `viajar`, `repetir`, `echar`, `componer`, `negar`,
`acudir`, `asistir`, `encantar`, `quitar`, `conectar`, `romper`, `estimar`, `separar`,
`agradecer`, `contribuir`, `fijar`, `emitir`, `adaptar`, `conducir`, `cuidar`, `costar`,
`abandonar`, `andar`, `caber`, `emplear`, `preferir`, `enseñar`, `impedir`, `introducir`,
`ejercer`, `guardar`, `imaginar`, `matar`, `valorar`, `derivar`, `mandar`, `animar`, `amar`,
`ejecutar`, `trasladar`, `interpretar`, `retirar`, `revelar`, `advertir`, `sorprender`,
`cometer`, `someter`, `manejar`, `luchar`, `medir`, and the rest). Ten `general-purpose`
subagents × 10, launched in two parallel messages of five, each returning a bilingual
(en/es) JSON block. `Etymologies.json` now holds **351/988** ranked verbs in both languages.

- **Cleanest batch yet — zero Step 4 issues across 200 strings.** No odd tildes, no en/es
  count mismatches, no ASCII quotes, no misplaced reconstruction asterisks. The batch-4 lesson
  paid off: the worked example pasted into every subagent prompt this run carried **real curly
  quotes `“ ”` and guillemets `« »`**, so no agent copied ASCII `"` glosses (batch 4 had 30 to
  fix). Confirms agents mirror the example's literal characters.
- **Extraction ran strict=False by default** (the other batch-4 lesson), so all 10 transcripts
  parsed on the first pass — no "0 verbs" false-empties to re-run.
- **Rich crop of doublets — one Latin verb, two Spanish reflexes:** `invitar`/`convidar` (learned
  vs. patrimonial from `invītāre`); `completar`/`cumplir` and `fijar`'s `fijo`/`hito` (learned vs.
  the `f-` > silent `h-` popular form); `emplear`/`implicar`; `respetar`/`respectar`; `animar`'s
  `ánima`/`alma`; `cobrar`/`recuperar`; `someter`/`cometer` as near-rhyming `sub-`/`com-` + `mittere`.
- **Disputed origins hedged, not laundered:** `invitar` (three rival deep roots — `invocāre`,
  De Vaan's `*weyh₁-`, older `velle` — all marked as competing); `andar` (`ambulāre` reduction vs.
  `*ambitāre`, unsettled, with the cognate family flagged as holding *only* under the `ambulāre`
  hypothesis); `matar` (Corominas's `mattus` "stunned" → the striking `matto` "crazy" kinship,
  explicitly a hypothesis); `acudir` (Corominas's `recudir` < `recutere` "favored" account);
  `estimar` (the `aes`+"cut" = "copper-minter" story De Vaan calls "not very credible");
  `retirar` (Corominas: `tirar`'s origin "deeply obscure" — Germanic `teran`? Parthian `tir`
  "arrow"? — both speculative); `interpretar` (the memorable `pretium` "price-setter between
  strangers" gloss marked contested); `amar` (Lallwort `*am-` vs. De Vaan's `*h₂emh₃-` "to grasp");
  `manejar` (Corominas rejects the folk `manus`+`agere` parse); `luchar`'s `lujo`/`lujuria` link
  ("by the traditional account").
- **Memorable payoffs that are actually settled:** `echar` < `iactāre`, a spectacular sound-change
  (`ject-` re-borrowed learnedly as `sujeto`/`proyecto`); `brindar` from German `bring dir's`
  "I bring it to you," carried home by Landsknechte after the 1527 Sack of Rome (Covarrubias 1611);
  `derivar`'s `rīvālis` = neighbors quarreling over the same `rīvus` (stream); `negar`'s hidden "no"
  in `negōtium` = `nec` + `ōtium` "not-leisure" → `negocio`; `guardar`'s `ward`/`guard` doublet (one
  Germanic word, native to English *and* looped back through French); `imaginar`'s `imāgō` as the
  wax ancestral death-mask; `impedir` "to shackle the feet" against `expedīre` "to free them."

Next: `contemplar` (rank 352).

## Etymology pipeline — batch 6 (ranks 352–452)

Sixth generation batch, a third **full 100 verbs**: ranks 352–452 (`contemplar`, `comparar`,
`complicar`, `incrementar`, `dormir`, `actualizar`, `divertir`, `investigar`, `invertir`,
`hallar`, `detectar`, `combinar`, `acordar`, `votar`, `aclarar`, `conservar`, `contratar`,
`admitir`, `coincidir`, `rechazar`, `tirar`, `transmitir`, `convocar`, `abordar`, `vestir`,
`acusar`, `cargar`, `reclamar`, `disminuir`, `caracterizar`, `oír`, `nombrar`, `dividir`,
`rodear`, `experimentar`, `orientar`, `justificar`, `autorizar`, `cruzar`, `regular`, `parar`,
`caminar`, `cortar`, `detallar`, `satisfacer`, `ajustar`, `salvar`, `conceder`, `apreciar`,
`fabricar`, `intervenir`, `fundar`, `consumir`, `atacar`, `descargar`, `sugerir`, `alejar`,
`dudar`, `gestionar`, `precisar`, `casar`, `favorecer`, `calificar`, `convencer`, `dictar`,
`beneficiar`, `grabar`, `involucrar`, `constar`, `sonar`, `percibir`, `destruir`, `insistir`,
`adelantar`, `contestar`, `cantar`, `llenar`, `condenar`, `criticar`, `implementar`, `durar`,
`montar`, `recurrir`, `clasificar`, `distribuir`, `confiar`, `vencer`, `saltar`, `concentrar`,
`calcular`, `prohibir`, `oponer`, `coger`, `optar`, `parir`, `devolver`, `corregir`, `pintar`,
`liberar`, `asignar`). Ten `general-purpose` subagents × 10, launched in two parallel messages
of five, each returning a bilingual (en/es) JSON block. `Etymologies.json` now holds
**451/988** ranked verbs in both languages.

- **Second clean batch in a row — zero Step 4 issues across 200 strings.** No odd tildes, no
  en/es count mismatches, no ASCII quotes, no misplaced reconstruction asterisks. Curly-quote/
  guillemet example + `strict=False` extraction remain the two habits that keep the run smooth.
- **Fertile doublet crop again:** `comparar`/`comprar` (learned vs. patrimonial from `comparāre`);
  `fabricar`/`fragua` (culto `fábrica` vs. sound-worn `fragua`, and its verb `fraguar`);
  `dividir`'s `individuo`; `cruzar`'s religious `cruzada` vs. geometric `crucero`; `pintar`'s
  earthy line vs. bookish `pigmento`/`pictórico`; `liberar`'s `libre`/`libertad` family (with the
  false-friend caution that `libro` is *not* a relative — a homonymous `liber` "tree-bark").
- **False friends flagged in both languages:** `actualizar` (Spanish `actual` = "current," not
  English "actual"); `consumir` vs. the constantly-confused `consumar` (< `consummāre` < `summa`,
  unrelated); `grabar` vs. `gravar` "to tax" (< `gravāre`, same sound, alien root); `casar`'s legal
  homonym "to quash" (< `cassāre` "annul"); `cortar`'s `corte` "court" belonging to `cohors`, not
  `curtus`.
- **Disputed origins hedged, not laundered:** `tirar` (Vulgar Latin `*tīrāre`, "one of the murkiest
  cases in Romance" — Germanic source vs. Corominas's Parthian `tir` "arrow" from Roman military
  slang, both explicitly proposals, with the "throw = flight of a Parthian shaft" flourish marked
  suggestive-not-proven); `invertir`'s financial sense (a debated 17th-c. semantic loan from Italian
  `investire`, distinct from the clean "reverse" descent from `vertere`); `hallar` (< `afflāre`
  "to blow toward" — Corominas's hound-scent path favored but not certain); `favorecer` (`favēre`'s
  deep root genuinely split, `*bʰeh₂-`/`*bʰuH-` vs. `*gʷʰew-` "to worship," the striking Slavic link
  left open); `condenar` (`damnum`'s `*deh₂p-` sacrifice-root uncertain); `atacar` (Italian
  `attaccare`'s Germanic-stake origin disputed in detail); `durar`, `optar`, `distribuir`, `calcular`,
  `asignar`, `precisar`, `prohibir` — each with its unsettled or unknown deep root marked as such.
- **Memorable payoffs that are actually settled:** `oír`'s `obedecer` = "to lend one's ear toward"
  (< `oboedīre`); `votar`'s hidden wedding — Latin plural `vōta` "the vows" → `boda`; `contestar`'s
  `testis` = `*tri-sth₂-` "the third one standing" (the impartial witness); `dudar`'s "two minds"
  (`dubitāre` ← `duo`), with English `doubt`'s silent `b` a Renaissance fossil of the very letter
  Spanish dropped; `sonar`'s loveliest cognate, English `swan` = "the sounding/singing bird";
  `caminar`'s Celtic `camminus` (the loan that displaced Latin's own word for "road," now the
  pilgrim's `Camino`); `rechazar`/`cazar` and the English `chase`/`catch` doublet from one
  `*captiāre`; `satisfacer` = `satis` + `facere`, kin to English `sad` ("sated, full") via `*seh₂-`.

Next: `fallecer` (rank 453).

---

## Etymology pipeline — batch 7 (ranks 453–553)

Seventh generation batch, a fourth **full 100 verbs**: ranks 453–553 (`fallecer`, `discutir`,
`acumular`, `robar`, `acreditar`, `disputar`, `fortalecer`, `escoger`, `formular`, `reforzar`,
`demandar`, `titular`, `hacendar`, `editar`, `figurar`, `resaltar`, `escapar`, `sustituir`,
`despertar`, `distinguir`, `bastar`, `articular`, `desempeñar`, `traducir`, `inscribir`, `pegar`,
`apostar`, `tender`, `reservar`, `consolidar`, `beber`, `solucionar`, `localizar`, `renovar`,
`prometer`, `fomentar`, `esconder`, `lucir`, `acoger`, `personalizar`, `gastar`, `inspirar`,
`liderar`, `financiar`, `tardar`, `mezclar`, `atraer`, `designar`, `activar`, `dominar`,
`arrancar`, `soportar`, `difundir`, `enfocar`, `competir`, `desplazar`, `alimentar`, `circular`,
`prevenir`, `reportar`, `cuestionar`, `equivocar`, `atravesar`, `contactar`, `diferenciar`,
`perseguir`, `impartir`, `coordinar`, `ignorar`, `inaugurar`, `estrenar`, `rendir`, `administrar`,
`padecer`, `asesinar`, `convenir`, `motivar`, `ahorrar`, `influir`, `verificar`, `acostumbrar`,
`encabezar`, `amenazar`, `juzgar`, `suspender`, `enterar`, `programar`, `carecer`, `especificar`,
`mediar`, `proyectar`, `repartir`, `remitir`, `opinar`, `configurar`, `gobernar`, `pronunciar`,
`combatir`, `atribuir`, `dotar`). Ten `general-purpose` subagents × 10, launched in two parallel
messages of five, each returning a bilingual (en/es) JSON block. `Etymologies.json` now holds
**551/988** ranked verbs in both languages.

- **Third clean batch running — zero Step 4 issues across 200 strings.** No odd tildes, no en/es
  count mismatches, no ASCII quotes, no misplaced reconstruction asterisks, all 100 en/es tilde
  counts matched. The curly-quote/guillemet worked example plus `strict=False` extraction stay the
  two habits that keep the run frictionless.
- **A true homonym handled as one entry, two origins:** `apostar` — the "bet" sense (< `appōnere`,
  the stake *placed* on the table, via `apuesta`) and the "station/post" sense (< `posta` <
  `posita`, via Italian `posto`), separate paths that both descend from `pōnere` "to place." One
  key, both accounts given, exactly as the homonym rule prescribes.
- **Doublet crop again:** `escoger`/`coger` (learned-ish vs. worn-down reflexes of `colligere`);
  `acumular`/`colmar` (culto `cúmulo` vs. metathesized `colmo`, `¡el colmo!`); `localizar`'s
  `local`/`lugar` from one `locālis`; `designar`/`diseñar` from `dēsignāre`; `traducir`'s Renaissance
  coinage (Leonardo Bruni misreading Aulus Gellius c. 1400, displacing `trasladar`).
- **False friends flagged in both languages:** `soportar` = "to endure," not English "support"
  (« no lo puedo soportar »); `reservar`'s caution that `servāre` "to guard" is *not* the source of
  `servir` (< `servus`); `editar`'s two Latin `ēdere` (give-out vs. eat), only the first the ancestor.
- **Arabism + Germanic loans, cited only where sourced:** `ahorrar` < Andalusi Arabic `ḥurr` "free"
  (to free a slave → to spare an expense → to save money); `robar`/`ropa` from Germanic war-booty
  (`*raubōn`, the `rob`/`robe` pairing mirrored in English); `gastar`'s `vastāre`×Germanic `*wōstijan`
  blend for the initial `g-` (Corominas); `liderar`, a 20th-c. denominal from English `leader`
  (`líder` admitted by the RAE only in 1970).
- **Disputed origins hedged, not laundered:** `arrancar` ("genuinely disputed," three competing
  accounts — Occitan `ranc` battle-line vs. Latin `ēruncāre` "to weed" vs. rejected Gothic `*wrankjan`);
  `distinguir` (traditional `*steyg-` "prick" vs. de Vaan's "push/thrust"); `asesinar` (the Marco-Polo
  hashish story marked disputed against the rival "Hasan's men"); `estrenar`'s goddess `Strēnia`;
  `personalizar`'s `persōna` ← Etruscan `phersu` (the `per-`+`sonāre` "sound-through-the-mask" gloss
  called out as folk etymology); `combatir`'s Gaulish `battuere`; `atribuir`'s `tribus`←`trēs`;
  `opinar`, `remitir`, `pronunciar`, `tardar`, `inspirar`, `atraer`, `carecer`, `fluere` (`influir`)
  — each unsettled deep root marked as such rather than asserted.
- **Memorable payoffs that are actually settled:** `fallecer`'s euphemism (`fallere` "to trip" →
  "to fail" → "to run out" → "to die," English's "pass away" impulse); `esconder`'s buried `*dʰeh₁-`
  linking *hide* and *make* (`hacer`, English `do`); `circular`'s astronomy debut (Kepler's optical
  `focus`/`enfocar` "little hearth," `hogar` from `focārium`); `influir`'s astrological `influentia`
  (the stellar "flowing-in" that also named `influenza`); `gobernar` ← Greek `kybernáō` "to steer,"
  the same helmsman Wiener drew `cybernetics` from in 1948; `administrar`'s irony (a `minister` is
  by origin the "lesser one," `minus`, opposite of `magister`); `figurar`/`configurar` sharing
  `*dʰeyǵʰ-` "to knead clay" with English `dough`.

Next: `temer` (rank 554).

---

## Deleting the device-model table (DeviceUtility) ahead of TelemetryDeck

The old analytics stack hand-maintained a ~100-line `switch` that mapped raw device
identifiers (`iPhone17,3`) to marketing names (`iPhone 16`) — `Analytics/DeviceUtility.swift`,
a `UIDevice.modelName` extension. Its *only* consumer was `AnalyticsService.recordBecameActive()`,
which stuffed the model name into the became-active event payload. Every new iPhone/iPad
generation meant another manual edit to keep the table current.

TelemetryDeck (the planned analytics backend) reports device model identifiers natively, so
the table is redundant the moment that integration lands. Deleted it now, ahead of the
integration: removed `DeviceUtility.swift`, its `DeviceUtilityTests.swift`, and the
`modelKey: modelName` parameter from `recordBecameActive()`, which now sends only the locale.
Dropping the lone `UIDevice` use also let `AnalyticsService.swift` shed its `import UIKit`.
Both files lived in a synchronized group, so no `project.pbxproj` edit was needed. Build green.

## Auditing the cold-launch widget-deeplink race (no fix needed)

Conjuguer, the French sibling, had a bug: force-quit the app, tap a Verb-of-the-Day widget,
and it opened the verb *browse* list instead of the individual verb. It happened because
Conjuguer loads its ~6,300 verbs asynchronously (`Task.detached`), so on a cold launch the
widget's deeplink reached the router *before* the parse finished; the router then switched the
tab unconditionally, landing on the Verbs list with a nil verb. Two ingredients were required:
(a) an async verb load that can still be in flight when the deeplink arrives, and (b) a router
that changes navigation state even when the entity lookup fails.

Audited Conjugar for the same defect and found it structurally immune on both axes:

- **No observable-empty window (a absent).** Conjugar's `VerbMap.shared` is a *synchronous*
  lazy static — `static let shared = VerbMap()` whose `private init()` parses `verbModelMap.xml`
  inline with `XMLParser`. Swift initializes a lazy `static let` exactly once, on first access,
  blocking until done, so the map is never seen empty. There is no `Task.detached` fill-later
  step for the deeplink to outrun.
- **Guarded routing (b absent).** `AppRouter.handle(url:)` calls `open(verb:)` only inside the
  `verb/random`-non-nil or `entry(for:) != nil` branches; a miss changes neither `selectedTab`
  nor `pendingVerb`.
- **Race-free consumer.** `VerbBrowseView` reads `router.pendingVerb` via
  `.onChange(of:initial: true)`, so a deeplink that set it before the view existed (the cold-launch
  case) is still consumed on first appearance, and the pushed verb resolved against the same
  synchronous `VerbMap.shared`.

Because the race requires a verb store that can be observed empty — which a synchronous lazy
static cannot be — the Conjuguer symptom can't reproduce here. The lazy-synchronous `VerbMap`
plus guarded routing is already the robust design, so no code change was made; recorded the
outcome and stopped.

## Spanish etymology pipeline — batch 8 (ranks 554–655)

Ran another 100-verb batch of the Spanish etymology generator: 10 parallel general-purpose
subagents × 10 verbs, split across two launch messages of five agents each. Zero context
compaction, zero lost transcripts, and — for the first time across a full 100 — the Step 4
markup validator reported **OK on the first pass**: no odd/mismatched tildes, no stray ASCII
quotes (every agent used curly `“ ”` / guillemets `« »`), no missing-language returns. All 100
en/es tilde counts matched. `Etymologies.json` now holds **651 / 988 ranked verbs** in both
languages; next up is `educar` (rank 656).

The batch surfaced a good crop of the kind of detail this feature exists for: `ser`-adjacent
suppletion echoes (`resistir`/`existir`/`estar` all tracing to *~steh₂-~*, "holding one's
ground"); the `conjugar` payoff hiding inside `juntar` (both from *~yewg-~*, "to yoke"); Arabic
`al-` fossils (`almacenar` ← *al-makhzan*, cousin of English *magazine*); Viking seafaring in
`equipar` (← Old Norse *skipa*, "to fit out a ship"); and the `negociar` = *nec-ōtium*
("not-leisure") etymological joke, with `ocio` as its exact opposite. Disputed origins were
hedged rather than laundered throughout — `quemar` (Corominas rejects a straight *cremāre*
descent), `regalar` (French *gale* vs. the seductive-but-contested *regalis* "treat like a
king"), `bailar`, `gritar` (the *Quirites* folk etymology flagged as such), `marchar`,
`derrotar` — exactly the cases the pipeline's confident-voice warning targets.

## Spanish etymology pipeline — batch 9 (ranks 656–757)

Another 100-verb batch of the Spanish etymology generator: 10 parallel general-purpose
subagents × 10 verbs, launched in a single message. Zero context compaction, zero lost
transcripts, and — for the second batch running — the Step 4 markup validator reported **OK on
the first pass**: no odd/mismatched tildes, no `~~`/`~*` slips, no stray ASCII quotes (every
agent used curly `“ ”` / guillemets `« »`), no missing-language returns. All 100 en/es tilde
counts matched. `Etymologies.json` now holds **751 / 988 ranked verbs** in both languages; next
up is `apretar` (rank 758).

The batch turned up a fine set of the surprising-detail payoffs this feature exists for:
`enamorar`'s `amāre` traced to an expressive nursery *Lallwort* rather than a secure PIE root;
`apartar` → `apartheid` (the same small "to a part" word behind a grim political coinage);
`felicitar`'s `fēlīx` meaning "fruitful/suckling" (root *~dʰeh₁(y)-~*) before it meant "happy",
kin to `hembra` and `hijo`; `respaldar` hiding a Greek `spáthē` ("broad blade") in the flat of
the shoulder; `apagar`/`pagar` as doublets both meaning "to bring to peace" (`pācāre`); and the
`sancionar` auto-antonym ("ratify" and "penalize" at once). Disputed origins were hedged rather
than laundered throughout — `aguantar` (RAE's "quizá" Italian-glove nautical route), `dibujar`
(irregular phonology on the Old French wood-carving etymon), `retomar`/`tomar` (Rajna–Corominas
`autumāre`, explicitly unproven), `embarazar` (pre-Roman `baraça`, DLE "quizá"), `optimizar`
(`ops` vs. de Vaan's `ob`), `alegrar` (`alacer`'s disputed PIE root), `perdonar` (which side
calqued `forgive`/`vergeben`) — exactly the cases the pipeline's confident-voice warning targets.

## Spanish etymology pipeline — batch 10 (ranks 758–809)

A 50-verb batch: 5 parallel general-purpose subagents × 10 verbs, one launch message. No
context compaction, no lost transcripts. Step 4 flagged exactly **one** issue — the `documentar`
Spanish had an agent self-correction artifact baked into the string (`~doctrine~ y así —perdón—:
~doctrina~`), which showed up as an en/es tilde mismatch (44 vs 46); a one-line replace removed
the phantom `~doctrine~` and the stray "perdón" aside, and re-validation was clean. Everything
else passed on the first pass: matched tilde counts across all 50, curly quotes / guillemets
throughout, no missing-language returns. `Etymologies.json` now holds **801 / 988 ranked verbs**
in both languages; next up is `charlar` (rank 810).

The payoff details this batch: `aburrir` and English `abhor` being *literally the same Latin
verb* (`abhorrēre`, "to shrink back") — boredom as fossilized loathing, cooled down through the
reflexive; `ser`-root cousins `restar`/`estar` both from *steh₂-* ("to stand"), so subtraction is
asking "what stands left"; `expandir`/`spawn` as doublets (a spreading empire and a spawning fish
share `expandere`); `alojar` bottoming out in Frankish *laubja*, a shelter woven from *leaves*;
`compensar`/`pesar`/`pensar` as three children of `pēnsāre` ("to weigh" → "to think"); `fumar`
vs. patrimonial `humo` showing the Castilian `f-`→`h-` split on one root; and `admirar` reaching,
through *smey-*, the same Indo-European root as English `smile`. Disputed origins were hedged not
laundered — `agarrar`'s `garra` (Gaulish "leg" vs. Andalusian-Arabic "handful"),
`rodrigar`/`rodrigón` (Corominas rejects the tempting `Rodrigo` link; `rīdica`/`rudis`
contested), `respirar`'s `spīrāre` (onomatopoeic per De Vaan vs. a debated PIE *(s)peys-*),
`equilibrar`'s `libra` and `empujar`'s `impulsāre`-vs.-`pujar` derivation — plus two false-friend
catches the agents flagged rather than asserted: English `flow` is *not* cognate with `fluere`,
and `have` is *not* cognate with `haber`-family words. The lone friction (a subagent's `—perdón—`
self-edit surviving into the JSON) got written back to the pipeline's Lessons.

## Spanish etymology pipeline — batch 11 (ranks 810–913)

A full 100-verb batch: 10 parallel general-purpose subagents × 10 verbs, launched in a single
message. To keep the orchestrator's context lean, each subagent's fully self-contained prompt
was written to a `/tmp` file and the Agent tool simply told it to *read* its file and follow it —
so the 10 KB rules-and-worked-example block was never held in the main context ten times over.
Zero context compaction, zero lost transcripts. Step 4 flagged **nothing at all** — all 100
verbs passed on the first pass: matched en/es tilde counts across the board, curly quotes /
guillemets throughout, no missing-language returns, no reconstruction-asterisk slips. Cleanest
batch yet. `Etymologies.json` now holds **901 / 988 ranked verbs** in both languages; next up is
`reconstruir` (rank 914).

The payoff details this batch clustered on **doublets and semantic drift**: `hundir` and `fundir`
are the same Latin `fundere` ("to pour") inherited twice — the popular `f-`→`h-` "to sink" beside
the semi-learned "to melt/cast"; likewise `doblar`/`duplicar` (from `duplāre`/`duplicāre`),
`librar`/`liberar`, `nombrar`/`nominar`, and `rezar`/`recitar` — the humble prayer-verb and the
theatrical one are twins, both from `recitāre`. Standout narratives: `emocionar` — when `emotion`
first appeared it named not a feeling but a *public disturbance*, even a riot, and only later
migrated inward; `brillar` "to shine" literally *began as the name of a gemstone* (`beryl`, from
an Indian source), the same `bēryllus` giving German `Brille` "eyeglasses"; `apellido` (surname)
and `apelar` (to appeal) both spring from `appellāre`, calling someone by name; Spanish
`desesperado` sailed abroad to become English `desperado`; a `contraste` was once the official
assayer who tested gold and silver against a standard; and `secuestrar` drifted from a Roman
legal term (property held by a neutral third party) to "kidnap" — the violent sense only recorded
by the Academy in 1884. Disputed origins were hedged not laundered — `susto`/`asustar` (the
Academy's `suscitāre` vs. Corominas's onomatopoeic `¡sst!`), `callar` (Greek `khalân`, via Greek
not inherited Latin), `chocar` (French `choquer` vs. an echoic origin), `avalar` (`à val` "at the
foot" vs. Arabic `ḥawāla`), `riesgo`/`arriesgar` (Corominas rejects Arabic `rizq`, favors the
cliff `risco`), `fracasar` (the `conquassāre`+`fra-` blend flagged as proposed), plus `charlar`,
`picar` (and its uncertain `pícaro` link), and `largus`/`alargar` (no confident PIE root) marked
expressive-or-uncertain. Two clean false-friend catches the agents surfaced rather than asserted:
Spanish `libro` is **not** from `līber` "free" but from a homonym meaning tree-bark, and the
`draw`↔`trahere` link behind `trazar` is judged phonetically impossible. Nothing fed back to the
pipeline's Lessons — the run hit no new friction.

## Comment sweep — stripping the modernization project's provenance citations

The modernization work left a paper trail in the comments: pointers to the Fable audit's
numbered suggestions (`item 19`), the build plan's phases (`Phase 6A`), the Spanish-verb
reference book and its taxonomy (`taxonomy §4.5`, `oracle §3`, `Annex B`, "the 2010 book"),
the cross-app UI audit codes (`audit §4`, `K11 / C15`), and "ported from Conjuguer /
Konjugieren" sibling-app notes. Useful while the project was in flight; noise in a shipping
codebase, coupling the code to documents that don't live in the repo. `AccentFeature.swift`
had already been done by hand as the worked example: strip the citation token, then judge the
residual comment on its own merits — keep it (trimmed) if what's left is real domain knowledge
or durable rationale, delete the whole thing if all that remains is "a past edit happened."

The sweep touched **89 files** — every engine feature file, the model catalog and vocabulary,
the Utils service seam, all the SwiftUI views, the Supporting layer, the test suites, and
(after a scope check) the widget extension and its Shared code. It was comment-only by
construction: the final `git diff` gate confirmed the only non-`//` lines that changed were two
`case str`/`case wk` trailing comments, code tokens untouched. Both the app+widget build and
the test-target build stayed green; SwiftLint clean.

The judgment split roughly as the spec predicted. The **engine files trimmed, rarely deleted** —
those `taxonomy §4.7` comments carry genuine grammatical mechanics ("one future-stem override
drives the whole future *and* conditional"), so the section number came off and the linguistics
stayed. **Utils skewed toward deletion** — "Straightened per item 19: …" and "Off-main (item 14):
…" were pure change-narration once the citation left, so they went entirely. Every `// MARK:`
was deleted outright (a blanket rule, ~150 of them), and "the book" got rephrased where it was
load-bearing (`book class number` → `class number`, `book's row order` → `canonical order`)
rather than left dangling. Two scope calls went to Josh: the widget/`Shared` directories (outside
the spec's stated glob but full of "Ported from Conjuguer" headers) got swept in, and the
external-book references in the test comments (`Annex B` as the canonical verb-set name, "the
2010 book") got the book citations stripped and `Annex B` rephrased to "the class taxonomy" while
the in-repo `_build_verbmap.py` generator reference — legitimate data provenance for how the
shipped resource is built — stayed. In-repo cross-references ("Mirrors VerbBrowseView"), legacy
old-engine comparisons, and `(see CLAUDE.md)` were left alone: those point *inside* the repo,
which is the whole distinction the sweep is drawing.

## Etymology content batch 12 (ranks 914–953)

Ran another pass of the Spanish etymology pipeline (`prompts/etymology-pipeline.md`): 40 verbs
(ranks 914–953 — `reconstruir` through `adorar`), five parallel `general-purpose` subagents of
eight verbs each, each researching from es.Wiktionary / DLE / Corominas for the Spanish descent
and en.Wiktionary for the PIE chain and cognates, and writing parallel English + Spanish entries.
Every entry cleared the Step 4 markup validator on the first pass (even tilde counts, en/es
tilde parity, curly-quote/guillemet discipline, no stray emphasis asterisks) — no re-dispatch
needed. `Etymologies.json` now covers **941/988** ranked verbs; next up is `decretar` (rank 954),
leaving 47 ranked plus the six select verbs.

A batch highlight was how many of these carry a hidden physical image: `recalcar` ("to stress")
is literally to tamp a point in underfoot (from `calx`, "heel"); `exagerar` is to heap earth ever
higher into a mound (`agger`); `penetrar` reaches the innermost storeroom the household gods
guarded. The subagents also held the line on disputed origins — `pillar`, `batir`, `secar`,
`desestimar`, and `adorar` all hedge their contested etymons ("the leading guess rather than a
proven fact," "of uncertain origin") instead of laundering them into confident narrative, which
is the pipeline's single biggest accuracy risk. One process note: stale `/tmp/etym_g*.json` files
from the previous session's batch 11 were still on disk and got swept into the glob-driven merge,
but the re-merge was fully idempotent (the `git diff` showed exactly 80 insertions = 40 verbs ×
2 languages, no existing entry touched) since those files were batch 11's own source.

## Etymology content batch 13 (ranks 954–1000 + the six select verbs) — pipeline COMPLETE

The final etymology pass: the last 47 ranked verbs (`decretar` through the tail of the top-1000)
plus the six rare-but-wanted **select verbs** (`yacer`, `abolir`, `placer`, `asir`, `balbucir`,
`atañer`) — 53 in all, seven parallel `general-purpose` subagents (six of eight, one of five),
launched in two messages of four and three. Every one of the 53 cleared the Step 4 markup
validator on the first pass again — 106 values, zero tilde-parity or quote defects — so no
re-dispatch. With this merge **`Etymologies.json` covers all 988 ranked verbs and all 6 select
verbs: 994 entries in each of `en` and `es`. The generation pipeline is done.** What remains is
the separate UI task the pipeline doc flagged: `Etymology.swift` already loads the file, but
nothing yet renders it under the conjugations in `VerbView` (a `~…~`→bold attributed-string
renderer plus an etymology card).

The select verbs were the most fun to end on, because their defectiveness *is* the story and the
subagent wove it in: `abolir` was historically defective (only the `-i-`-initial endings, so never
*`abole`*); `placer` still surfaces its archaic strong preterite `plugo`/`pluguieron` in fossils
like `pluguiera a Dios`; `asir` technically has the `-g-` present `asgo` but speakers dodge it for
`agarrar`/`coger`; `balbucir` is propped up by regular `balbucear`; `atañer` lives almost only in
the third person (`eso no te atañe`). `asir` also gave the batch its sharpest disputed-origin note
— Corominas derives it from `asa` (« handle », Latin `ansa`) and explicitly *rejects* the Old
French `saisir` account, a refutation the subagent carried into both languages rather than
laundering. This batch merged with no stale-file interference (the previous session's `/tmp`
leftovers had been cleaned up), and the git diff was exactly 53 verbs added with the sole
incidental change being the former last-key `vulnerar` gaining a trailing comma.

## Example-uses corpus — source identification & licensing (step 1)

Kicked off the "example uses" feature, Conjugar's port of the per-verb example sentences that
Conjuguer and Konjugieren already ship. The Conjuguer model (see `~/Desktop/VerbView.png`) is the
target: each usage-ranked verb shows one modern-prose example, and — where one genuinely exists —
a nested *medieval* example with a tap-through to all medieval examples for that verb (Conjuguer
nests *Chanson de Roland* lines). The Conjuguer pipeline is the one to copy because it moved the
expensive work off the LLM: pre-conjugate every verb with the app's own engine, index the corpus
deterministically by whole generated word-form, and let subagents do only the select/translate
judgment (`../Conjuguer/docs/literature-example-corpus.md`).

Step 1 was pure research: identify the sources and nail down licensing before fetching anything.
Four parallel `general-purpose` subagents each took a tier (medieval / literature / government /
technology) and came back with PD-verified, URL-level source lists. Findings, now written up in
`docs/example-corpus-sources.md`:

- **Medieval — the *Chanson de Roland* analogue is the *Cantar de Mio Cid* (c. 1200).** Same role
  (Castilian national epic, ~3,730 verses, anonymous), PD worldwide. Clean plain text: the
  Menéndez Pidal 1913 *normalized* edition on the Internet Archive (`poemademiocid00men`, full-text
  TXT) — the normalized layer keeps medieval morphology (*ferir*, *aduxo*, *connusco*) but with
  consistent spelling, the sweet spot for form-matching. Delightful bonus: there's a literal
  Iberian *Roland* cousin, the ~100-line *Roncesvalles* fragment (Navarro-Aragonese, PD via
  Menéndez Pidal's 1917 *RFE* article) — too short to carry coverage, perfect as a "Roland cousin"
  garnish. The engineering wrinkle is Old→Modern Castilian normalization (f-→h-, ç→c/z, u↔v/i↔j,
  apocope + enclitic splitting, and a hand table for strong preterites *sopo→supo, ovo→hubo,
  dixo→dijo*) — and the payoff lands exactly where matching is hardest, on the vivid irregulars the
  app already models richly.
- **Literature — an 8-work PD starter set**, weighted to 19th-c. peninsular realism (Galdós
  *Fortunata y Jacinta* as anchor, plus Clarín, Pardo Bazán, Valera, Alarcón, Blasco Ibáñez) whose
  forms match modern Spanish best, with *Don Quijote* kept as a flagged supplement (17th-c.
  orthography). All clear in both US and Spain (life+80) by decades; Project Gutenberg `.txt.utf-8`
  is the clean channel.
- **Government — official texts are statutorily PD**: Spain Art. 13 TRLPI and Mexico Art. 14 LFDA
  both exclude laws/decrees/official acts from copyright (the exact analogue of the Swiss Art. 5
  URG basis the French app used), so any BOE/DOF legal text is zero-obligation. Agency reports add
  attribution-only reuse (INE = CC BY 4.0, Spain PSI regime, Argentina CC BY 4.0).
- **Technology — the one gap.** Unlike Switzerland's PD NCSC guides, Spain's best consumer how-to
  (INCIBE/OSI, AEPD) is CC BY-**NC**-SA — the NC clause blocks a shipped commercial app, and
  CCN-CERT is all-rights-reserved. Commercial-safe fallbacks are CC BY-SA community/vendor docs
  (Mozilla SUMO, GNOME/Ubuntu, Wikilibros) and attribution-only PSI gov tech prose (España Digital
  2026), with the mitigation that short utilitarian instructions ("Haga clic en Aceptar") fall
  below the originality threshold anyway.

The feature slots cleanly onto existing infrastructure: `VerbMap.frequencyRank` already supplies
the 989-verb ranked set, and the etymology feature (`Etymologies.json` + the `nonisolated`
load-once `EtymologyCache`, with its card pending in `VerbView`) is the exact template for the
examples' bundled JSON, loader, and UI placement. Left four owner-level decisions open in the
manifest (tech-tier risk posture, medieval supplements beyond the Cid, Latin American inclusion,
and whether to fetch + build the pipeline next) rather than presuming them.

## Example-uses corpus — fetch + form-dump backbone (step 1 build)

With the sources chosen (Cid + Berceo *Milagros* + *Libro de buen amor* for the medieval tier;
8-work PD literature set; PD/CC-BY government; digital-policy + planned CC-BY-SA vendor docs for
technology; LatAm included), fetched the corpus and stood up the deterministic backbone of the
pipeline.

A fifth research pass nailed down Latin American government attribution and produced one useful
correction: DANE (Colombia) is **CC BY 4.0**, *not* BY-SA — so all three LatAm sources (Mexico
Libre Uso MX, Colombia DANE, Argentina argentina.gob.ar/INDEC) are attribution-only and
commercial-friendly, no share-alike anywhere. A single paste-ready credits page satisfies every
obligation across Spain + the three countries; it lives in `docs/example-corpus-sources.md`.

**Fetched 21 source texts** into `corpus/originals/` (gitignored, re-fetchable, mirroring
Conjuguer's corpus policy): 3 medieval, 8 literature, 5 government, 5 technology. Project
Gutenberg's `.txt.utf-8` endpoint gave clean literature; the Cid came from the archive.org
Menéndez Pidal 1913 OCR and Berceo from a PDF (both need apparatus-stripping later); the
government/technology PDFs were `pdftotext`'d. Three fetches missed (Fernán González — only
lending-restricted editions; INEGI/INDEC stats PDFs — non-extractable) and are noted as
gaps to backfill.

The backbone is the **form-dump**: `ConjugarTests/Models/CorpusFormsDumpTests.swift`, a disabled
build-time tool (Conjugar's port of Conjuguer's `CorpusFormsDumpTests`) that rides the test target
to reuse the app's authoritative engine. It conjugates every verb through `TenseBridge` across all
20 conjugatable tenses × 7 persons (both tú and vos, so voseo is harvested), lowercases the
`IrregularityMarker` UPPERCASE red-highlight encoding back to the plain surface form, and — for
compounds and imperativo negativo — keeps only the last word (participle / subjunctive), so the
dropped `haber`/"no" don't turn every "he …" into a false hit. It writes
`corpus/working/forms.json` (**ranked: 52,166 forms → 988 verbs**) and `forms_all.json` (**all:
254,328 forms → 4,811 verbs**). Both tests pass in ~26 s. The payoff of matching whole *generated*
forms rather than stem-grepping is immediate in the spot-checks: `voy→ir`, `supe→saber`,
`dicho→decir`, `tuviéramos→tener`, and — the vivid one — `fue`/`fui` correctly map to **both**
`ir` and `ser`, the shared-suppletion detail the `ser` etymology makes a point of. Homographs get
recorded under every candidate verb; context-disambiguation is the mining step's job.

The SourceKit `No such module 'Testing'` diagnostic on the new file is the usual stale-index false
positive — `xcodebuild` compiled and ran it cleanly. Next: the `grokked/` Old→Modern Castilian
canonicalizer for the medieval tier, the Python index builder, the subagent mining workflow, and
the `ExampleUses.swift` loader + `VerbView` cards.

## Example-uses corpus — cruft removal

Josh flagged that the retrieved sources carried the classic boilerplate — Project Gutenberg's
license header/footer, and the running headers/footers/page-numbers that PDFs repeat on every
page — the kind of thing that derails a mining agent. Wrote a tracked, idempotent cleaner
(`corpus/working/clean_corpus.py`, fed by a now-tracked `fetch_corpus.sh` so raw→clean is
reproducible) and swept all 21 files. Handlers by source type: Gutenberg (slice between the
`*** START ***`/end markers — including the *older* `End of Project Gutenberg's <title>` footer
form that a first pass missed on two Galdós files); PDF-paginated (frequency-detect the recurring
per-page running headers/footers and drop them, plus `Página N`, bare page numbers, and dotted
TOC leaders); and the Cid OCR (slice to the poem body, drop the modern intro, the `CANTAR DEL
DESTIERRO` running headers, the back índice, the Internet Archive front matter, and the printer's
colophon).

Two surprises surfaced along the way, both real pollution rather than mere boilerplate. First,
**Doña Perfecta (PG 15725)** — the edition the literature research had picked as "the Spanish
one" — turned out to be a *Heath annotated student edition*: pervasive inline `=markup=`, margin
line-numbers, an English critical introduction, and a huge English `NOTES`+`VOCABULARY` apparatus
(the `=11= 17 =a más de largo=: 'besides being long.'` glossary). Not worth salvaging, so it was
dropped for clean Spanish-only **Marianela (48818)** — still Galdós, so no loss of coverage.
Second, **El sombrero de tres picos (PG 29506)** is annotated the same way, but its Spanish story
body is pristine, so the cleaner slices the body out from between the English front and back
matter — keeping Alarcón in the set. The one bug worth remembering: the first slice cut *El
sombrero* down to three lines, because the edition's own contents page near the top lists
"NOTES"/"VOCABULARY", so "first NOTES" matched the table-of-contents entry, not the real
back-matter section — fixed by cutting at the *last* occurrence, with a sanity guard against ever
slicing a body down to nothing.

A global grep now finds zero Gutenberg boilerplate, zero English annotated-apparatus, and zero
PDF running-header/`Página N` cruft across the corpus. What deliberately remains is *content*, not
cruft, and belongs to the next (`grokked/`) stage: the medieval editions still carry their modern
editorial introductions and footnotes, which must be fenced off from the medieval index so they
don't feed modern Spanish forms into the "Cid example" lookups.

## Example-uses corpus — credits (creditsText)

Added an `^Example Uses^` / `^Ejemplos de Uso^` section to the app's credits
(`Info.creditsText` in `Localizable.xcstrings`, both `en` and `es`), inspired by Conjuguer's
example-sentence credits block but reflecting Conjugar's actual corpus and Conjugar's own markup
(`^heading^`, `~emphasis~`, `%url%` rather than Conjuguer's backtick/`‡` conventions). It is
organized by license, exactly matching the 21 sources assembled: the eight public-domain literary
works (Galdós, Clarín, Pardo Bazán, Valera, Alarcón, Blasco Ibáñez, Cervantes) via Project
Gutenberg; the three public-domain medieval works (Cid via the Internet Archive, Berceo, Libro de
buen amor); Spain/Mexico/Colombia official texts that statute excludes from copyright (Art. 13
TRLPI, Art. 14 LFDA, Art. 41 Ley 23/1982); and the attribution-licensed government reports (INE
and DANE under CC BY 4.0 with the license URL, Spain's Ley 37/2007 reuse for MITECO/Mitma/España
Digital, Argentina's argentina.gob.ar under CC BY 4.0). A final `~AI-authored examples and
translations.~` paragraph credits Claude (Opus 4.8) as the author of the translations and of the
fallback example sentences for verbs no open corpus uses verbally — set up now so the attribution
ships with the feature. Every fetched source is PD, CC BY 4.0, or open public-sector reuse
(attribution-only) — none carry NC or share-alike — so the credits need no copyleft caveat; if the
deferred CC BY-SA vendor how-to docs (Mozilla SUMO, GNOME/Ubuntu) are later added for the
consumer-imperative register, a share-alike credit gets added with them.

Edited the catalog through `python3`/`json.dump` (never the Edit tool, per the `.xcstrings`
ASCII-quote foot-gun), inserted before the `^Icons^` section in each language, verified balanced
`^`/`~`/`%` markup with no stray ASCII quotes, validated the JSON, and confirmed a clean
`build_app.sh`.

## Example-uses — session handoff plan

Wrote `prompts/example-uses-pipeline.md`, a self-contained plan a fresh session can execute to
finish the feature without this session's context. It records the starting state (sources chosen,
21-text corpus fetched + cleaned, form-dump done, credits done) and lays out the six remaining
chunks: the `grokked/` medieval prep (isolate verse from modern apparatus + the Old→Modern
canonicalizer with the strong-preterite exception table + the reflex-only attachment policy), the
`build_corpus_index.py` port plus a medieval index over `forms_all.json`, the subagent
select/translate mining workflow with its output schemas, tail rescue + Claude-authored residue,
and the app-side integration (Example/MedievalExample models + loaders mirroring
`Etymology`/`EtymologyCache`, and the two `VerbView` cards in the same slot as the now-wired
etymology card). It points at Conjuguer's build scripts and app models as working templates and at
`docs/example-corpus-sources.md` for the full source/license/attribution detail.

## Example-uses — steps A & B: medieval prep + corpus indices

Executed steps A and B of `prompts/example-uses-pipeline.md`: the deterministic *retrieval* half
of the example-mining pipeline, so the later subagent mining step only has to select + translate
pre-found candidate lines rather than read whole novels and medieval epics.

**A3 — the Old→Modern Castilian canonicalizer (`corpus/working/oldspanish.py`).** Medieval verse
is spelled in 12th–14th-c. Castilian (*ferir, fazer, dixo, ovo, auer, connusco*), which never
matches the engine's modern conjugation tables directly, so the canonicalizer reduces *both* the
corpus token and every generated modern form to a shared, deliberately-lossy key and compares
canonical↔canonical. Symmetric letter rules (f-→h-, then initial h-→∅, ç→z, ss→s, intervocalic
consonantal u→b, x→j, j/y→i, v→b, accent-stripping while preserving ñ) plus a hand-built
strong-preterite/suppletive exception table (~150 high-frequency entries — *sopo→supo, ovo→hubo,
dixo→dijo, tovo→tuvo, priso→prendió, connusco→conocer, cavalgar→cabalgar*) and enclitic/apocope
splitting (`díxol`→`díxo`, `tornós`→`tornó`, `diz`→`dize`). A built-in self-test confirms 18/18
reflex pairs collide.

**A1/A2 — verse isolation (`corpus/working/grok_medieval.py` → tracked `corpus/grokked/`).** The
three editions still carried their modern editorial apparatus, which had to be kept out of the
medieval index (injecting modern forms into "medieval example" lookups is the tier's single
biggest correctness risk). The Cid (a messy Menéndez-Pidal-1913 OCR with footnotes and headings
interleaved line-by-line) is separated block-by-block: drop any blank-separated block that carries
a modern-scholarly apparatus marker (`v. N`, `p. N`, `comp.`, a 4-digit cross-ref, a single-quoted
gloss, a clean editorial "Cid"), *and* require every kept block to show at least one
medieval-orthography marker (the positive test that catches marker-less footnote *continuation*
prose), with a final per-line modern-lexeme filter. Verse numbers come from a running counter
snapped monotonically to the OCR's own marginal numbering, with cantar assignment by
Menéndez-Pidal range → `Cantar {I,II,III}, v. N` (endpoint lands on v. 3718 vs the true 3730).
Berceo's clean cuaderna vía is grouped into blank-separated stanzas → `estrofa N` (912 stanzas vs
the canonical 911); the Libro de buen amor's Cejador edition prints its own `[N]` copla markers,
read straight off → `copla N` (1725 of 1728). Result: 3242 Cid + 3652 Berceo + 7271 LBA verse
lines, zero detectable modern-prose leaks, emitted as `<slug>.txt` for inspection plus a combined
`medieval_verses.json` ref map.

**B1 — modern-tier index (`build_corpus_index.py` → `corpus_index.json`).** Port of Conjuguer's
builder: one tokenizing pass per literature/government/technology source, whole-token lookup in
`forms.json`, candidates gathered per work then merged round-robin with a per-verb rotating lead
work so the first candidate is spread across the eight novels (Galdós/Clarín/Pardo Bazán/…), with
government then technology as fallback. **977 of 988 ranked verbs covered (98.9%)**; the 11
zero-coverage verbs are modern journalism/sport lexemes (*debutar, empatar, protagonizar*) bound
for tail rescue / authored residue.

**B2 — medieval index (`build_medieval_index.py` → `medieval_index.json`).** Reflex-only matching
over the grokked verse using the canonicalizer + `forms_all.json` (all 4,811 verbs, since medieval
reflexes routinely fall outside the ranked 988): a verse line attaches to a verb only when it
genuinely contains that verb's own ancestor form. Over-merged canonical keys (shared by >8 verbs)
are dropped; candidates are ranked most-distinctively-verbal first and capped per verb. **1,048
verbs get ≥1 medieval example — 444 usage-ranked plus 604 "medieval-only special" verbs** (the
unranked archaic reflexes, e.g. *yantar, aducir, catar, trovar, lidiar*, that step F will also give
a modern example + etymology). Spot-checks confirm the reflex fidelity: *connusco→conocer,
priso→prender, firiendo→herir, aduxieron→aducir, oviéronla→haber* all resolve correctly. Both
index JSONs are regenerable intermediates (gitignored); the scripts and the hand-verified
`grokked/` verse are tracked. Remaining: steps C (mining), D (tail rescue), E (app UI), F (future).

## Example-uses — step C: mining (select + translate) COMPLETE

Step C is the LLM middle of the example-uses pipeline: turn the deterministic candidate indices
(built in step B) into finished, translated example entries. Following the etymology pipeline's
parallel-subagent pattern, both indices were sharded ~30 verbs/shard
(`build_examples.py shard {modern|medieval}` → gitignored `corpus/working/shards/`) and one
`general-purpose` subagent (Sonnet) mined each shard, reading only its slice and writing its own
`mined_*.json`. **33 modern shards + 35 medieval shards = ~68 subagents.** Each subagent's job was
judgment the deterministic index can't do: pick the earliest genuinely *verbal* candidate (rejecting
same-spelled nouns/adjectives — *vino* the wine, *cena* the dinner, *como* the adverb), re-open the
source to recover the clean full sentence, and translate it.

**Modern (`ExampleUses.json`, dual-written to `corpus/json/` + `Conjugar/Models/`): 888 of 977
verbs placed.** Source balance came out literature-dominant with government/technology as fallback,
spread across all eight novels (Galdós's *Fortunata* 191 + *Marianela*, Clarín's *Regenta*, Pardo
Bazán's *Pazos*, Valera's *Pepita* 101, Cervantes 91, Alarcón's *Sombrero* 67, Blasco Ibáñez's
*Barraca*; ~69 from the gov/tech tiers). The 89 unplaced verbs are **not** step-C failures — they
are the noun-collision tail the plan routes to step D: the index's tokenizer surfaced only the
dominant wrong-POS homograph (*comer*→*como*, *caminar*→*camino*, *partir*→*parte*, *viajar*→*viaje*,
*juntar*→*junto*), and the subagents correctly refused to pass a noun off as a verb. Those go to
tail rescue (re-mine gov/tech tiers) + authored residue in step D.

**Medieval (`MedievalExamples.json`, same dual-home): 695 verbs with ≥1 example, 2,139 verse lines**
(LBA 1047 / Berceo 658 / Cid 434), arrays capped at 5 best-per-verb for the tap-through. The
subagents enforced the reflex-only rule a second time (dropping *ferir*-attaches-to-*herir* look-alikes
that were really a different verb/noun), cleaned the Cid's residual OCR garble (*£id/Qid*→*Cid*,
stray marginal-number fragments, caesura-bracket artifacts) **without** modernizing spelling, and
left the citations untouched. Final spot-checks are clean: *cavalgan→cabalgar, Feridlos→herir,
yantando→yantar, Trobáronlo→trovar, aduxieron→aducir, Díxoles→decir, ovieron→haber*, and zero
residual Cid garble across all 434 kept Cid lines. Crucially this includes the 604 "medieval-only
special" verbs, so step F already has its `MedievalExamples.json` arrays and only needs to add a
modern example + etymology.

Mechanics worth keeping: subagents *writing their own* `mined_*.json` (rather than returning JSON
for transcript extraction) made aggregation a trivial `build_examples.py aggregate` glob-and-merge
with markup/quote validation, and made the whole mine **idempotent and shard-resumable** — a mid-run
pause (five-hour window exhausted) resumed by simply re-launching the shards with no file yet, and
one Sonnet shard that died on a mid-response API error was re-run in isolation. Remaining: D (tail
rescue + authored residue), E (app-side `Example`/`MedievalExample` models + `VerbView` cards), F
(future-plans verbs).

## Example-uses — step D: tail rescue + authored residue COMPLETE (988/988 modern coverage)

Step D closes the modern tier: it places the 100 ranked verbs that step C left null. The split
turned out clean — **89 had corpus candidates but all were wrong-POS, 11 had no candidate at all** —
and D resolved to **61 rescued from the corpus + 39 Claude-authored = 988/988 ranked verbs with a
modern example**, dual-written to `corpus/json/ExampleUses.json` + `Conjugar/Models/ExampleUses.json`.

**Tail rescue (`build_tail_index.py`, ported from Conjuguer).** The main index fills each verb's
five slots *literature-first, in line order*, so a verb whose surface form equals a common noun
drains all five with noun uses (*cocinar*→*cocina*, *dudar*→*duda*, *sumar*→*suma*, *forzar*→*fuerza*,
*viajar*→*viaje*) and comes back null even when genuine verbal uses exist elsewhere. The tail builder
re-mines exactly the uncovered verbs, ranking candidates by a Spanish `verbalness` score: infinitive
and gerund (`-ando/-iendo`, incl. enclitic `-ándolo`) score highest, participles next, the
noun-shaped present forms score 0 and sink. The **key fix over a naïve port** was a *split per-doc
cap*: the article *una* (a form the engine legitimately maps to *unir*) appears hundreds of times per
novel and, under a single gather cap, filled the whole quota before the rare *unir/uniendo* was ever
scanned — so *unir*, a rank-43 verb, looked absent. Capping score-0 collisions at 2/doc while
gathering verbal forms generously (20/doc) surfaced the real uses. Result: **70 verbs got a
distinctively-verbal candidate; 30 had none** (their only corpus occurrences are adjectival
participles the engine doesn't emit, like *documentada* / *archivados*, or substring artifacts).

The 70 rescuable verbs were sharded (3 × ≤30) and mined by three parallel `general-purpose`
subagents with a *stricter* rejection rule than step C — because the candidate list is pre-ranked
verbal-first, a lingering noun/adjective/homograph at the top is a red flag. The subagents correctly
nulled **9** where every candidate was a decoy: *jamar*←*jamás* (adverb), *salgar*←*salga* (of
*salir*), *hacendar*←*haciendo* (of *hacer*), *regular*/*violado* (adjectives), *licenciado* (noun),
*acondicionado* / *especializado* (lexicalized participles), and an English *catalogue* in a quoted
passage. **61 placed** (e.g. *unir*, *viajar*, *comer*, *cocinar*, *curar*, *secar*, *forzar*,
*caminar*, *sumar*, *argumentar* — mostly infinitives/gerunds pulled from the novels, plus
administrative infinitives from the gov/tech tiers).

**Authored residue (39).** The 9 tail-nulls + 30 never-verbal verbs get an **original Claude (Opus
4.8) sentence**, each flagged `"source": "Claude (Opus 4.8)"`, `"line": null` so AI authorship is
explicit and never attributed to a corpus, documented in `docs/authored-examples.md` (mirroring
Conjuguer). Every authored sentence uses a genuinely verbal form and an assert in `write_authored.py`
checks the `token` actually occurs in the sentence and that no ASCII double-quote can corrupt the
JSON. These are the app's rarer verbs — *adir* (accept an inheritance), *salgar* (salt livestock),
*rodrigar* (stake vines), *seriar* (mass-produce), *hacendar*, *respectar* — plus common verbs whose
corpus form is only ever the noun (*documentar*, *entrevistar*, *archivar*, *donar*, *numerar*).

Mechanics: the tail and authored files (`mined_tail_*.json`, `mined_authored.json`) share the mined
shard schema, so `build_examples.py aggregate modern` just globs them alongside the step-C
`mined_modern_*.json` and re-merges — the union is clean because the three key-sets are disjoint
(modern-placed / tail-rescued / authored). Re-running aggregation is idempotent and rebuilds all 988
from the shards. Remaining: E (app-side `Example`/`MedievalExample` models + `VerbView` cards), F
(future-plans verbs).

---

## Example uses, step E: app-side Swift integration (the cards ship)

The corpus work from steps A–D produced two bundled JSONs — `ExampleUses.json` (988/988 ranked
verbs, one modern-prose example each) and `MedievalExamples.json` (695 verbs → 2,139 Old-Spanish
lines). Step E wired them into the app, mirroring the etymology feature exactly (the same
`nonisolated`, load-once, `@unchecked Sendable` cache pattern used by `EtymologyCache`/`VerbMap`).

**Models** (`Conjugar/Models/`, all `nonisolated`): `Example` (`es`/`en`/`source`/`token`/`line`,
with a `provenance` computed property), `MedievalExample` (`work`/`ref`/`os`/`tr`, plus `workTitle`
and a `reference` that prepends the poem title to the emitted citation), and `ExampleSource` — an
enum that maps a raw source filename onto its attribution. Public-domain literature and the
AI-authored tail get a fixed `— Author, Title (year)` credit (proper nouns, not localized);
government/statistics sources get a localized `Fuente:/Source: <body>` line naming the issuing body.
The source list and wording track the `^Example Uses^` credits already in the string catalog.

**Loaders** `ExampleData.example(for:)` / `MedievalData.examples(for:)` are carbon copies of
`Etymology`/`EtymologyCache`: `NSLock`-guarded, load-once, `nonisolated` so the MainActor `VerbView`
reads them synchronously in `init`. Both JSONs sit in `Conjugar/Models/`, which is a
`PBXFileSystemSynchronizedRootGroup` — so, like `Etymologies.json`, they were auto-bundled with no
`project.pbxproj` edit.

**`VerbView`** gained one `exampleCard` in the same slot as `etymologyCard`, shown when the verb has
either a modern or a medieval example. It renders the Spanish sentence in the serif "language" face
(speaks on tap), the muted English translation, and a right-aligned attribution. When a medieval
example exists, a nested `medievalSection` follows a divider: a blue "Medieval Spanish" heading, the
citation (`Cantar de mio Cid, Cantar I, v. 14`), the Old-Spanish verse (medieval spelling kept
intact — *sodes*, *ferir*, *dixo*), and its translation. Verbs with more than one medieval
attestation get a red cycle button (`arrow.forward.circle`) that advances through them; the view
starts on a random index so each visit varies, like Conjuguer's chanson section. The three ways
Conjugar differs from Conjuguer are all handled: bare-infinitive keys (no `extraLetters`), the
`TenseBridge`/`Conjugator` engine, and three medieval works rather than one poem (hence the `work`
field and `workTitle` mapping).

**Localization**: six new `L.Verb` accessors (`exampleUse`/`exampleUses`, `medievalExample`,
`nextMedievalExample`, `exampleSource(body:)`, `exampleSourceClaude`) with `en`+`es` entries added to
`Localizable.xcstrings` via `python3`/`json.dump` (never the Edit tool — the ASCII-quote foot-gun).

**Verification**: `ExampleDataTests` (Swift Testing, `nonisolated`, 8 tests) covers JSON decode +
lookup, the reference/work-title formatting, and every `ExampleSource` branch (literature /
government / Claude / unknown-fallback). Full suite: **427 tests, 0 failures.** Drove the built app
in the simulator — opened *ser* (modern example from *La Regenta* + 5 medieval Cid attestations),
confirmed the card renders correctly in dark mode and the cycle button advances the medieval example
(*v. 14 → v. 69*, "…sodes ardida lança!"). Remaining: F (non-ranked verbs with a medieval example
also get a modern example + etymology).

---

## Example uses, step F — non-ranked medieval verbs get a modern example + an etymology (2026-07-10)

Step F closes out the example-uses feature. The `MedievalExamples.json` file covers **695** verbs,
but only **343** of those are in the usage-ranked 988 — the other **352** are *medieval-only* verbs
(mostly archaic: *yantar, aducir, heder, trovar, cabalgar, guerrear, esquilmar*…). They already
showed a medieval attestation in `VerbView`, but had no modern example and no etymology. F fills
both gaps for all 352, reusing the machinery from steps C–E and the etymology pipeline unchanged.

**Modern examples.** These verbs are *unranked*, so they never entered `corpus_index.json` (built
off `forms.json`, ranked-only). A step-F analogue, `build_special_index.py`, keys off
`forms_all.json` (all 4,811 verbs) instead, restricted to the 352-verb work-list
(`prompts/example-uses-stepF-verbs.json`) — one tokenizing pass over the same modern corpus, same
round-robin author balance. It found candidates for **329/352** (23 zero-coverage). Eleven
`general-purpose` subagents (30-verb shards, `mine_special_prompt.md`) each picked the earliest
genuine *verbal* use — rejecting the many noun/adjective homographs these archaic verbs collide with
(*culpa* not *culpar*, *razón* not *razonar*, *peligro* not *peligrar*) — re-opened the source for a
clean sentence, and translated it. **282** landed; **47** came back null (homograph-only) and joined
the 23 zero-coverage as the **70** Claude-authored residue (`write_authored_special.py`, flagged
`source: "Claude (Opus 4.8)"`, `line: null`, exactly like step D's 39). `build_examples.py` grew a
`special` shard-kind and now globs `mined_special_*` / `mined_special_authored*` into its modern
aggregate, so one re-run rebuilds **988 → 1340** verbs (1231 corpus + 109 authored), dual-written.

**Etymologies.** The 351 not-yet-covered verbs (yacer was already a select verb) ran straight
through `prompts/etymology-pipeline.md`: 44 groups of 8, one subagent each (four launch waves), each
writing a validated `etym_NNN.json`. Three agents died on a transient *connection-closed* API error
mid-write and were simply relaunched — the per-group files make that a clean retry. The Step-4
markup validator (even tilde counts, en/es tilde parity, no ASCII quotes, `*~root~` order,
paragraph breaks) passed **0 problems** across all 351, and the merge took `Etymologies.json`
**994 → 1345** (`en` and `es`).

**No app-side work.** Step E already wired `ExampleData` / `MedievalData` / `Etymology` into
`VerbView` keyed by bare infinitive, and Browse Verbs lists all 4,811 verbs — so the 352 new rows
just appear. Build **Succeeded**, full suite **427 tests / 0 failures**, and a data spot-check
confirmed *yantar / aducir / heder / trovar* each resolve a modern example, their medieval
attestations, and an etymology. The example-uses pipeline (A–F) is now complete.

**Gloss fix — *desvelar* homonymy.** Reading the freshly written *desvelar* etymology surfaced a
mismatch: the etymology's second paragraph stresses that *desvelar* is a homonym with two unrelated
etyma — "reveal/unveil" (from *des-* + *velar* ← Latin *vēlum*) and "keep awake/lose sleep" (from
Latin *ēvigilāre*) — yet the shipped gloss showed only "reveal." The phase-1 gloss adjudication had
already flagged this (`verdicts_af.tsv:193` note "reveal / keep awake") but it never reached the
slice or the XML. Fixed the `tn` in `verbModelMap.xml` and the `slice_af.tsv` row to
**"reveal, keep awake"** — a single comma gloss, matching the house style of the 24 existing
two-sense glosses (`come, turn to`; `admit, accept`), rather than a two-line homonym split. The
homonym split (as for *apostar*/*asolar*/*aterrar*) exists to give senses *different conjugation
classes*; both senses of *desvelar* are regular class-1, so a comma gloss is the right encoding and
`glosses[0]` still defaults to "reveal," correct for modern usage.

**Etymology copy-edit sweep — throat-clearing removed.** A pass over all 1,345 etymologies
(en + es) to delete *method* throat-clearing while preserving genuine acknowledgments of
uncertainty. The distinction: "the deeper root is uncertain / disputed / debated" stays; the
editorial tail that follows it — "so it is best to stop the firm chain at Latin rather than force a
root onto it," "so the deeper root is best left open," "así que conviene dejarla abierta," "es más
prudente no fijarla," "so enjoy it as a possibility, not a fact" — goes. A tightened detector (with
`conviene notar` / `conviene no confundir` factual notes excluded) found **~52 verbs** carrying it;
each trailing recommendation clause was trimmed with a per-edit regex asserted to match exactly once,
keeping the preceding uncertainty statement and fixing punctuation (dangling em-dashes, spaced
guillemets) at the cut. Two fully-meta sentences (*despertar*'s "The tangled Latin ancestry is a
caution worth stating plainly…", *trocar*'s "…is best held as a hypothesis, not a fact") were deleted
outright as redundant with the uncertainty already stated; two ("*The safest statement is that* the
second half is uncertain", "Because the accounts diverge, the deep root *is best left open*") were
minimally reworded to plain uncertainty. A re-run of the detector after the edits reported **0**
residual instances. **101 throat-clearing edits.**

**Small etymology fixes (same pass).** *desvelar*-adjacent tidy-ups requested by Josh: *empatar*'s
`en.Wiktionary` → "English Wiktionary" (and the Spanish body's `en.Wiktionary` → "el Wiktionary en
inglés"); the analogous `es.Wiktionary` in *tomar* → "the Spanish Wiktionary" / "el Wiktionary en
español"; *disolver*'s second English sentence capitalized (`~solvere~` → `~Solvere~` at sentence
start, same class of fix as *visar*'s *Viser*); and *repasar* gained the closer French cognate
`~repasser~` — the exact re-+passer compound, which even shares the "go back over / iron" senses with
Spanish *repasar* — beside the English *repass*.

**Etymology sweep — sentence-initial capitalization.** Every etymology (en + es) routinely opens
sentences with a lowercase italic headword ("~bajar~ descends…", "~velar~ es la forma…"), the same
slip caught earlier one-off in *visar* (*Viser*) and *disolver* (*Solvere*). A sweep capitalized the
first letter inside the markup at every genuine sentence start — **929 fixes (439 en / 490 es)**. The
work was in the segmenter: split only on real boundaries, suppressing abbreviations (`i.e.`, `e.g.`,
`a. C.`, siglo `s. III`, single-letter initials) and interior `¡…!` / `¿…?` via balanced-punctuation
tracking, and skipping reconstructed forms (`*~weyd-~`, lowercase by convention). An independent
leak-check for capitalizations landing after an abbreviation returned **0** real hits (one flagged
case was verified a correct boundary — the period after "…i.e. competent." legitimately ends its
sentence). Accent-preserving (`~ánimo~` → `~Ánimo~`). Data-only; display-decoupled.

7/11/26: Kicked off the **built-in game** — a Donkey-Kong-inspired flamenco/bull game
(spec in `prompts/game.md`): a flamenco dancer ascends ladder-linked platforms toward a
bull that hurls country-flag "barrels" and holds a kidnapped bullfighter; capes are the
"hammer" power-up. Launched from Settings like the sibling apps. This session was
**research + design only** — no game code yet.

- **Studied all three in-house games.** RaceRunner (2017, SpriteKit) is the only one with
  real **frame animation** — arrays of `SKTexture` cycled by
  `SKAction.animate(timePerFrame: 0.1)` at 10 fps, 10 jogger / 11 horse frames in east/west
  sets, the horses **traced from Muybridge's "The Horse in Motion."** Konjugieren and
  Conjuguer (2026) share one **pure-SwiftUI "house architecture"** — `@Observable GameState`,
  a `TimelineView(.animation)` → `.onChange(of: timeline.date)` **delta-time loop**,
  value-type `Codable` structs, AABB `rectsIntersect`, `GameState+*` mechanic files,
  `.fullScreenCover` from Settings — and, notably, **neither has any frame animation**
  (static `Image`/emoji/`Shape` moved with `.position()` + `scaleEffect(x: ±1)` facing
  mirror + `sin(sineTime)` pulse). Conjuguer's **press-and-hold buttons**
  (`DragGesture(minimumDistance: 0)` → intent booleans consumed by the loop as `speed·dt`)
  are the control model to extend to 4 directions + jump + cape.

- **Answered the three research questions** (`docs/game_design_research.md`): (1) **Blender
  is the right tool**, as the render stage of a **pre-rendered-3D-sprite** pipeline
  (model → rig → animate → orthographic render → sprite sheet), scriptable and
  Claude-drivable via **blender-mcp**. (2) Animation = **skeletal rigging** (an *armature*
  is the "wireframe" Josh half-remembered; *ragdoll* is physics, not authored dance) — the
  dancer gets near-free motion from **Mixamo** (auto-rig + free, royalty-free walk/jump/**dance**
  mocap), while the **bull is the quadruped cost-center** (Rigify or a pre-rigged Sketchfab
  bull, hand-keyed). (3) **Gemini can't do frame-exact cycles** (no alpha channel, proportion
  drift between calls, non-uniform grids — confirmed by a first-hand Nano-Banana-Pro
  write-up), so it's for **stills** (bullfighter, capes, backgrounds, HUD), concept/turnaround
  sheets, and seeding image-to-3D; the flags are real flags, not generated.

- **Recommended architecture:** stay **pure SwiftUI** (match the siblings) and add frame
  animation, which drops into the ZStack model as an `Image(frames[i])` indexed by a
  dt-advanced phase — RaceRunner's flipbook idea in the sibling idiom. The new Donkey-Kong
  systems (platforms/gravity/ladders/jump, flag "barrels", cape "hammer", 5-ascent + final
  bullfight) are all simple dt-integration + AABB.

- **Stack settled (Josh's follow-up).** **Pure SwiftUI, SpriteKit dropped** — it's not de
  jure deprecated (SceneKit was soft-deprecated at WWDC 2025 → RealityKit; SpriteKit wasn't
  named) but it's neglected and shipped **iOS 26 framerate regressions**, so Josh's "de
  facto deprecated" read is fair. His key question — does SwiftUI stay performant with frame
  animation? — is **yes**: the game frame-animates only ~2 actors at once (dancer + bull),
  and the sole real cost is image *decode*, removed by pre-decoding frames or drawing
  `context.resolve()`-cached images in a `Canvas`. The escalation ladder (ZStack →
  `Canvas`+`TimelineView` → `.drawingGroup()`) is all pure SwiftUI — OctopusKit hits 5,000
  sprites at 60 fps on a 2018 iPhone XS, orders of magnitude beyond this game. §2.2 of the
  research doc was rewritten from a "when to use SpriteKit" section into this analysis.

- **Palette is a gift.** Conjugar's existing `customRed` **#C1001D** + gold `customYellow`
  **#CDA51B** map almost one-to-one onto a matador/bull/flamenco theme; art-direct the whole
  game around red + gold, rendered with a flat/toon shader tuned to the app's hex.

- **Music & SFX.** Music: CC0 **Signature Sounds "Spanish Guitar Loops"** (zero friction, no
  credit) or CC-BY **casimps1 "Vaguely Spanish Guitar"** (one credit line) — CC0/CC-BY are
  App-Store- and AGPL-safe; avoid CC-BY-NC. **SFX reuse the siblings' `Current.soundPlayer`
  sets**, gap-filled from **Pixabay** (commercial-OK, no-attribution license). **Josh then
  chose CC-BY** as the *project-wide* asset bar (not just music): it leads with a composed
  CC-BY flamenco track (casimps1 / BFCMUSIC) over CC0 loops, and also unlocks a pre-rigged
  CC-BY Sketchfab bull and CC-BY sound effects — at the cost of one **Credits/Acknowledgements
  screen** (TASL lines) plus an **`asset-licenses/`** paper-trail folder in the repo.

- **Deliverable:** `docs/game_design_research.md` — codebase synthesis, the asset/animation
  pipeline, phased plan, open decisions, and sources. Next step: a **placeholder-art SwiftUI
  prototype** to de-risk the Donkey-Kong feel, then a one-action end-to-end pipeline test
  (dancer walk cycle: Gemini concept → image-to-3D → Mixamo → Blender render → imagesets).

## The game — phase 1: placeholder-art prototype ships (2026-07-11)

Built the **playable placeholder-art prototype** (plan in `prompts/game_prototype.md`) — the
Donkey-Kong feel is proven with zero real art, and, crucially, so is the **frame-animation
machinery** that this whole game exists to add over the siblings.

- **Architecture mirrors the siblings exactly.** `@MainActor @Observable final class GameState`
  driven by `GeometryReader → TimelineView(.animation) → ZStack`, tick via
  `.onChange(of: timeline.date) { update(currentTime:) }`, with the Conjuguer dt guard
  (`rawDt > 0, rawDt < 1`) + `min(rawDt, 1/30)` clamp. Entities are value-type structs;
  logic is split across `GameState+Physics/+Flags/+Animation` extensions (so state they touch
  is internal, not private). Files: `Conjugar/Models/Game/{GameModels,GameState,
  GameState+Physics,GameState+Flags,GameState+Animation}.swift` + `Views/GameView.swift`.
  Models/ and Views/ are `PBXFileSystemSynchronizedRootGroup`s, so no `project.pbxproj` edit.

- **The point of the prototype — the flipbook works.** Player and bull "sprites" render as their
  **current frame *number*** in a tinted box: `currentFrame = Int(phase·fps) % count + 1`,
  fps 10, advanced by dt. On screen you literally watch the bull's number cycle **1→6** as it
  paces (walk cycle) and the player's cycle **1↔2** idle / **1→6** walking — the exact index
  logic real sprite frames plug into later (`Text("\(frame)")` → `Image(frames[frame-1])`, a
  one-line swap). Per-action counts: player idle 2 / walk 6 / climb 4 / jump 3 / cape 4; bull
  idle 2 / walk 6 / throw 5. Facing is a `◀`/`▶` chevron (never mirror a digit).

- **Donkey-Kong systems, all dt-integration + AABB.** 6 red girders with **staggered zig-zag
  blue ladders** (SwiftUI primitives, Conjugar palette on black); gravity + platform-snap;
  ladder climb (press up/down at a ladder → `climbing`, gravity off); jump as a one-shot
  impulse (re-armed on release). The bull throws **flag "barrels"** every 2 s that tumble and
  cascade platform-to-platform in the DK zig-zag (alternating roll direction + drop point per
  level). **Cape pickups** cape the player for 8 s (flag contact smashes instead of hurting).
  **4-pip heart health**, −1 per flag hit (25 %, 1 s i-frames); health 0 **or** reaching the
  bull → `reset()`. Quit (`xmark.circle.fill`) dismisses the `.fullScreenCover`. Controls are
  Conjuguer's press-and-hold idiom: a 4-way D-pad + jump, each a `DragGesture(minimumDistance:
  0)` flipping an intent boolean the loop consumes.

- **Launch + L10n.** A **Game** card in `SettingsView` (existing `settingSection` +
  `TintedCapsuleButtonStyle`) → `.fullScreenCover { GameView() }`. Added `enum L.Game`
  (title/description/play/quit/health/jump/move·) + `Game.*` keys to `Localizable.xcstrings`
  (en+es, via `python3` per the ASCII-quote foot-gun; validated).

- **Verified in the simulator** (build → Settings → Play → drive it): platforms/ladders,
  bull pacing + cycling frames + facing flips, player walk/idle + movement + **ladder climb**
  (caught mid-ascent), flags cascading every level, and health→reset all confirmed. One tuning
  fix fell out of play-testing: `climbTolerance` 26 → **34** pt, because the player kept
  overshooting the ladder and couldn't grab it. **13 Swift Testing cases**
  (`ConjugarTests/Models/GameStateTests.swift`, `@MainActor @Suite`) cover frame wrapping,
  AABB, platform snap, jump gating, ladder enter/climb, flag damage, cape smash/pickup, and
  bull-reset — all green. Build green, SwiftLint clean.

- **Simulator gotcha (not a bug):** country-flag emoji and 🧣 render as tofu `?` boxes in the
  iOS simulator (no glyphs); they show as real flags/scarf on device. The bullfighter 🤺
  renders fine. Doesn't affect the mechanic — the flags still spawn, tumble, and collide.

- **Also noted (pre-existing, unrelated):** the Settings tab crashes in the simulator via the
  ratings `.task` → stub-`URLSession` metrics collection (SIGILL, zero Conjugar frames in the
  stack) — independent of the game; worked around only to screenshot, then reverted.

- **Next:** phase 2 — the one-action end-to-end asset pipeline (dancer walk cycle) to validate
  the toolchain, then swap `Text("\(frame)")` for `Image(...)`.

### Game prototype — feel tweaks (round 2)

After play-testing the prototype, a pass of control/feel fixes:

- **Controls slimmed and pushed clear of the field.** D-pad buttons 52 → 40 pt and the whole
  cluster dropped to a `Layout.defaultSpacing` bottom margin, so the up arrow no longer overlaps
  the bottom girder. **Jump moved to the inverse corner** (bottom-trailing) and vertically
  centered against the D-pad via an `HStack(alignment: .center)` + `Spacer()`; shrunk 20 %
  (64 → 51 pt). Restyled from a solid red disc to the **same translucent fill as the D-pad
  (0.18) with a solid yellow ring**, so it reads as one control family.
- **Contextual climb arrows.** The up/down buttons now appear only when a climb is actually
  possible — new `GameState.canClimbUp`/`canClimbDown` (grounded & within `climbTolerance` of a
  ladder whose base/top is on the player's level, or already climbing). Absent buttons collapse
  to a clear same-size slot so the cross never reflows. A defensive `if !canClimbUp { movingUp =
  false }` in the tick clears a stranded intent when a held button vanishes mid-press (its
  gesture may never fire `.onEnded`). Verified on device-sim: walking onto the bottom ladder
  makes the up arrow pop in, down stays hidden (player is at the ladder's foot).
- **Player halved vertically** (`playerHeight` 60 → 30; number font 26 → 18 to fit the flatter
  box) — reads more like a sprite, less like a domino.
- **Jump is dodge-only.** `jumpImpulse` 520 → 360, dropping the max hop to ≈ v²/2g ≈ 46 pt —
  comfortably under the ~80–105 pt inter-platform gap on every screen size, so you can hop a
  rolling flag but never skip a level (climbing stays the only way up).
- All 13 `GameStateTests` still green; build + SwiftLint clean. (Same simulator gotchas as
  before: flag/scarf emoji render as tofu, and the Settings ratings `.task` still SIGILLs — the
  latter only worked around to reach the game for screenshots, then reverted.)

### Game sound & music — porting Conjuguer's freeze-proof audio architecture

Wired sound effects + looping flamenco music into the game, but the real work was porting
Conjuguer's **performance-safe** audio stack so the app never reintroduces the launch stall /
in-game freeze that Conjuguer already debugged and fixed (the "AI Doomers Are Wrong" blog
story). The recipe, from Conjuguer commits **`9bb4f3e`** (perf) and **`270052a`** (debounce):

- **Replaced the static, main-thread `SoundPlayer`** — which lazily created each `AVAudioPlayer`
  *on the main thread on first play* (literally the anti-pattern the blog describes) — with a
  **protocol-injected** `Current.soundPlayer` seam: `SoundPlayer` (protocol) + `SoundPlayerReal`
  + `SoundPlayerDummy`, wired into `World` (Real on device/simulator, **Dummy** in
  unitTest/uiTest so tests never touch CoreAudio). Migrated every existing call site
  (`Utterer`, `GameCenterReal`, `QuizView`, the browse views, the tutor views, `CommunView`)
  and deleted the static class.
- **Everything expensive is off-main.** The audio stack is warmed at launch via
  `Task.detached` (a silent primer player — the first `AVAudioPlayer` cold-starts the whole
  process-wide audio stack ~1.5 s); SFX are pre-decoded + `prepareToPlay`'d off-main at game
  start (`warmUpSounds`, keyed off `Sound: CaseIterable`); the blocking `play()` (~20–80 ms
  audio-server round trip) is dispatched to a concurrent `playbackQueue`; and per-sound debounce
  clocks (`instantOfLastPlayBySound`) keep a chatty non-debounced SFX from resetting a debounced
  one's window. Ported `GlyphWarmer` too — the first draw of a large **flag emoji** stalls the
  render thread ~0.5 s, and this game *rains* flag emoji, so they're pre-rasterized off-main at
  game start.
- **Decision B — one session owner.** Unlike Conjuguer, `Utterer` remains the single
  `AVAudioSession` owner (configured once as `.ambient` — respect the silent switch, mix with
  the user's music), so the ported `SoundPlayerReal.setup()` **drops** Conjuguer's
  `AudioSession.configure()` and only warms the stack; `Current.soundPlayer.setup()` runs
  *after* `Utterer.setup` at launch.
- **Reused SFX from the siblings** (Pixabay-sourced, no attribution required): `pop` (jump),
  `soccerKick` (flag hit), `chomp` (cape smash), `shieldActivate` (cape pickup), `cow` (bull
  bellow on throw); plus existing `chirp` (debounced low-volume rung-tick while climbing),
  `randomApplause` (reach the bull), `randomSadTrombone` (health 0). Music is a gapless
  `numberOfLoops = -1` player with a 2 s fade-in, started in `GameState.configure()` and stopped
  in `GameView.onDisappear`.
- **Music track:** *"Vaguely Spanish Guitar"* by Clarence Simpson (casimps1), ccMixter, **CC BY
  3.0**. Credited in `Info.creditsText` (en + es, new **Game Music** TASL block + **Game
  Sounds** courtesy note; the "Sound Jay" block's "all sounds" was corrected to "original
  sounds"), with deeds in a new **`asset-licenses/`** folder. The audio DI seam was landed with
  a silent placeholder `flamencoLoop.mp3` (ffmpeg `anullsrc`) so the build was green and the
  mechanism fully wired independently of the asset; Josh then dropped the real 2:55 track in
  place (same path, no Xcode/pbxproj change) and it loops gaplessly via `numberOfLoops = -1`.
- Added a Swift Testing `SoundPlayer` suite (Current uses the Dummy in the test world; the Dummy
  absorbs every call; `Sound.allCases` covers the new game cases). Build + SwiftLint green.

**Follow-up tuning & fixes (audio + game feel):**

- **Mix balance:** music bumped 0.25 → 0.30 (+20 %); the bull's `cow` bellow dropped to
  `volume: 0.5` (it fires every ~2 s, so half-volume keeps it from dominating).
- **Cape expiry telegraph.** The cape power-up now runs **5 s solid, then a 2 s blink** before
  expiring (`capeDuration` 8 → 7; new `isCapeVisible` flashes the overlay ~5×/s during the final
  `capeBlinkDuration` seconds while `isCaped` — and thus the flag-smashing gameplay — stays true
  the whole time). Classic "invincibility about to end" flicker.
- **Honest flag hitbox.** Flag↔player collision now uses a tighter `flagHitSize` (20 vs the 30 pt
  drawn box) — flag emoji sit inside transparent glyph padding, so the full box registered
  phantom hits on jumps that had visually cleared the flag. Now a jump whose arc doesn't touch
  the flag costs no health, exactly as it looks. (Jump impulse unchanged, so you still can't skip
  a level.) Covered by two new `GameStateTests`.
- **SF Symbol fix.** The Settings "Game" card's icon was `figure.flamenco` — **not a real SF
  Symbol** (8,539 in the on-device manifest; that isn't one), so it rendered blank. Swapped to
  `figure.dance` (a dancer — on-theme for flamenco, and distinct from the Game Center card's
  `gamecontroller.fill`).

---

## Blender → 2D-sprite toolchain, proven on the dancer walk cycle (2026-07-11)

Stood up the 3D→2D-sprite pipeline that replaces the game prototype's numbered-frame
placeholders with real rendered animation, and proved it end-to-end on **one action** —
the player's **walk cycle** — now animating in the running app.

- **Toolchain (`tools/blender/`).** `brew`-installed Blender 4.5 LTS, ImageMagick, uv.
  `render_sprites.py` is a headless Blender script: imports a Mixamo FBX, clears the
  default scene, frames the character with an **auto-fitting orthographic side camera**
  (mesh bounds sampled across the *action's* frame range so a stride/jump never clips),
  lights it (key sun + world ambient), sets **EEVEE Next + transparent film + RGBA PNG**,
  and renders **N evenly-sampled frames** (half-open `[start,end)` so the loop-closing
  duplicate is dropped). Parameterized `--actor/--action/--frames/--size/--view/--ortho/
  --toon`. `pack_or_rename.sh` crops every frame to one **common bounding box** (union of
  content across frames — tight, drift-free) and renames to the game's 1-based
  `dancer_walk_N.png` convention (or packs a sheet). Full `README.md`; renders + raw FBX
  are git-ignored (Mixamo's raw-asset restriction, public/AGPL repo).
- **blender-mcp (bonus).** Registered `uvx blender-mcp`, vendored the addon under
  `tools/blender/blender-mcp/`, and smoke-tested a cube render both via the addon socket
  and the in-session MCP tools. Not needed for the dancer (headless CLI suffices); it
  earns its keep later for sourcing the bull (Sketchfab/image-to-3D).
- **The asset.** Mixamo stock **X Bot** + **Walking** clip (In-Place, 30 fps, With Skin),
  driven in-browser via Claude-in-Chrome; rendered to **6** side-profile frames (matching
  `playerFrameCounts[.walk]`), cropped to 109×169, dropped into a new
  `Assets.xcassets/Game/` group. Logged in `asset-licenses/`.
- **The seam swap.** `GameView.playerSprite` now renders
  `Image("dancer_walk_\(playerFrame)")` for the `.walk` action (kept the numbered-box
  fallback for the other, not-yet-rendered actions and for the bull). The sprite overhangs
  the 44×30 collision box, feet aligned to its bottom, and mirrors by `playerFacing`
  (native render faces left → mirror when walking right). Verified in the simulator: the
  dancer walks with real frames, correct facing both directions, while every other actor
  still shows numbers — the whole pipeline proven on one action.
- **Fixed a pre-existing, simulator-only crash surfaced along the way.**
  `URLProtocolStub.startLoading()` delivered response *data* but never a `URLResponse`;
  under the async `URLSession.data(for:)` path the simulator's task-metrics collection
  (`didFinishCollectingMetrics`) then trapped with **SIGILL**, crashing the Settings tab
  (its ratings lookup uses the stub session) — and thus blocking the game's only entry
  point. Added the missing `client?.urlProtocol(self, didReceive:…)` (the canonical
  Paul-Hudson stub shape). Device was never affected (`World.device` uses the real
  `URLSession.shared`); `RatingsFetcherTests` stay green.

Next: fill out the dancer's other actions (idle/climb/jump/cape/victory), then the bull.

## The dancer's other four actions — the player is fully sprite-animated (2026-07-11)

Ran the proven toolchain across the dancer's remaining four actions, so **every** player
state now renders real frames — no numbered-box placeholder is left for the player (only
the bull still shows one).

- **Four more Mixamo clips, same X Bot.** Exported `idle` ("Breathing Idle"), `climb`
  ("Climbing Ladder"), `jump` ("Jump"), `cape` ("Taunt") — all In-Place / 30 fps / With
  Skin, driven in-browser via Claude-in-Chrome — onto the *same* X Bot character as the
  walk, so scale matches. Rendered through `render_sprites.py` at `--frames` matching
  `playerFrameCounts` exactly (idle 2, climb 4, jump 3, cape 4), side view, `--size 192`,
  then `pack_or_rename.sh` union-cropped each. 13 new imagesets in `Assets.xcassets/Game/`.
- **One height, per-action width.** Every action's union crop came out ~169 px tall
  (In-Place keeps the figure the same height); only width varies with limb spread (idle
  34, cape/walk 109, jump 119). So `GameView` was generalized to hold **one visual height**
  and derive each action's **width** from its own aspect ratio — the character stays one
  size with feet aligned as the action changes. The `.walk`-only special-case became a
  `spriteActions` set + `actionName`/`dancerWidth`/`dancerMirror` helpers; the numbered box
  survives only as a safety net.
- **Climb doesn't mirror.** The renders face left and mirror when facing right — except
  `climb`, which stays un-mirrored (a symmetric ladder pose shouldn't flip). Side view was
  enough for all five; the ladder climb reads fine in profile, so no front/back special-case.
- **A human debugging trick made verification tractable.** Driving the running game to
  screenshot each action, the fast ones were nearly impossible to catch — a jump's airborne
  window is ~0.5 s and every capture landed a frame late. Josh's idea: **slow the whole
  simulation down.** Added a `CONJUGAR_GAME_TIME_SCALE` launch env var (a single multiplier
  on the loop's `dt`) — at 10× slow the half-second jump lasts five seconds, trivially
  caught; refined to 5× plus a `CONJUGAR_GAME_DISABLE_FLAGS` flag for a calm field. Both
  default off (no effect on normal play) and ship as debug affordances. With them, all five
  actions were verified live via `conjugar://game`: idle stands, walk strides (both
  facings), jump hangs mid-arc, climb grips the ladder, cape strikes the fists-up
  smash-ready stance.

- **Re-angling the climb to a back view.** The first pass rendered all five actions in
  side profile, and the climb *worked* — but a side-on figure on a vertical ladder reads
  oddly, like it's clinging to the rungs sideways. The conventional platformer read is the
  character's **back** as they climb *away* up the ladder. The render harness already had a
  `--view back` flag (camera on −Y looking +Y), so this was a one-flag re-render:
  `--view side` → `--view back`, still 4 frames. The "Climbing Ladder" clip reads cleanly
  from behind — back of the head and shoulders, arms reaching up alternately to the rungs,
  legs stepping — no off-axis three-quarter nudge needed. Two surprises: (1) the back
  silhouette is *narrower* than the side one (70 px vs 82 px union-crop width) because the
  arms tuck up close to the body instead of reaching out in a side stride, so the single
  code change was `dancerWidth(.climb)`'s aspect `82/169 → 70/169`; and (2) the
  un-mirrored rule still holds — a back view is left–right symmetric just as the profile
  was, so `dancerMirror` still returns `1` for climb. Verified live via `conjugar://game`
  (walk to the bottom-right ladder, hold up): the dancer now climbs the rungs seen from
  behind, feet on the ladder, same character size; walk and jump unchanged.

Next: the custom flamenco-dancer mesh (replace the X Bot mannequin), the toon/palette pass,
then the bull (the quadruped cost-center).

- **The bull, Phase 1: sourcing the quadruped (no Mixamo this time).** The player went
  fully sprite-animated for free because Mixamo hands you a rigged biped plus royalty-free
  mocap. None of that exists for a four-legged bull — Mixamo is biped-only — so the bull's
  first job was just *finding a rigged mesh we're allowed to ship*. Drove Sketchfab through
  Claude-in-Chrome: filtered to Downloadable + Animated, then tightened the license facet to
  **CC BY / CC BY-SA / CC0 only** — which was the important move, because it instantly
  dropped several nice-looking cow/bull models that turned out to be CC-BY-**ND** (no
  derivatives) or Sketchfab "Standard"/"Editorial" — none of which permit re-posing-and-
  rendering inside a public AGPL app. Read each finalist's license *off its own model page*
  (the authoritative source), and shortlisted three CC-BY quadrupeds spanning a real
  trade-off: a stylized low-poly "Spanish Bull" (best game look, but one baked clip), a
  realistic "Bull" (clean, low-poly), and **Leo_Aguiar's "Simple Rigged Bull"** — realistic,
  heavier (60.7k tris), but explicitly built on **Blender's Rigify Basic Quadruped meta-rig**.
  Presented all three (previews + license) and Josh picked the Rigify one — the safe bet,
  since the hard part of Phase 2 is a *bespoke hand-keyed throw* and a real editable
  quadruped rig removes the rigging risk. Download needs a (free) Sketchfab login; Josh
  authenticated with an Epic Games account (the auth step is deliberately his — Claude
  doesn't create accounts or type credentials). The "Original format" FBX pull was a happy
  surprise: it preserved **both** the source metarig (49 bones) *and* the full generated
  Rigify control rig (381 bones — IK/FK, tweak/DEF/ORG/MCH) plus the baked `rigAction`
  (frames 1–105). Saved as the git-ignored `tools/blender/source/bull.blend`; logged full
  provenance + the required CC-BY attribution in `asset-licenses/sketchfab-bull.txt` before
  a single frame gets rendered. One caveat noted for Phase 2: FBX bakes animation per-frame
  and drops Rigify's constraints/drivers, so the imported control rig is a bone hierarchy
  without live IK — but the intact metarig means Phase 2 can just *regenerate* a working
  Rigify rig if direct DEF-bone keying gets awkward.

## The bull is a real bull now — idle/walk/throw hand-keyed, the last numbered box is gone (2026-07-11)

Phases 2–7 of the bull plan: turn Phase 1's rigged Sketchfab bull ("Simple Rigged
Bull" by Leo_Aguiar, CC BY 4.0, a Rigify Basic Quadruped) into the game's three
flipbooks — **idle (2), walk (6), throw (5)** — and wire them into
`GameView.bullSprite`, retiring the game's **last numbered-box placeholder**. Player
*and* bull are rendered sprites now.

- **The dead-controls discovery, confirmed.** Phase 1 warned that FBX transport drops
  Rigify's constraints/drivers; in Blender the imported control rig indeed has **0 bone
  constraints, 0 drivers, 0 widgets** — posing the `*_ik`/`torso`/`hips` "controls" moves
  nothing. But the mesh is skinned to the `DEF-` bones and the model's baked clip keys them
  *directly*, which is why the baked idle still deforms the mesh. So I keyed the **`DEF-`
  deform bones** directly (Path B), quaternion channels, and never touched the Rigify
  regeneration path (Path A) — it wasn't needed for three short, 60-px-tall actions.

- **idle was free; walk + throw were hand-keyed.** The model's baked `rigAction` (frames
  1–105) is a subtle **standing sway**, not a walk — so idle is just two samples of it. There
  was **no bonus baked walk** the master plan had hoped for. The **walk** is a cyclic
  diagonal quadruped gait: sinusoidal thigh swing on the four `DEF-*thigh` bones (rear and
  `front`), with a phase-offset knee bend on the `DEF-*shin` bones, all In-Place. The
  **throw** is a bespoke 5-frame head-toss: the `DEF-spine.008..011` neck→head chain rears
  the head **up** (windup) then thrusts it **down/forward** (a goring release), timed to the
  0.5 s `bullThrowDuration`, with a front-leg brace for weight.

- **Authoring in the render's own view.** Blender's **Right Ortho** = `render_sprites.py`'s
  `--view side` (head-left; the game mirrors the sprite by `bullFacing`), so what I posed is
  exactly what shipped. One FBX per action (exported with that action active) sidesteps
  multi-action export ambiguity; the harness's half-open `[start,end)` sampling meant nudging
  the walk to a 7-frame loop-close and the throw to a 6-frame hold so the 6 and 5 *distinct*
  frames land cleanly (and the throw's **release frame** survives the crop).

- **The subtlety that bit once: constant scale, not constant height.** The dancer keeps a
  constant on-screen *height* because all its crops are the same pixel height. The bull's
  throw rears the head up, so its union crop is much taller (114 px vs the walk's 92). My
  first wiring pinned a constant `bullVisualHeight` — and the bull visibly **shrank ~19 %
  every time it threw**, because the taller crop scaled the whole body down. The fix keys off
  a fact about the renderer: it auto-fits ortho by the bull's constant body *length* (every
  action crops ~170 px wide), so **one render pixel is the same world size in every action**.
  `GameView` now maps crop-px → screen at one constant `bullScale`, deriving per-action
  width, height, *and* feet-offset — the body stays one size while the reared head genuinely
  extends upward on a throw.

- **First render was too polite.** The initial throw's head motion was so subtle that on the
  device it was nearly indistinguishable from the walk (the crop was only ~2 px taller). I
  roughly doubled the head-pitch amplitude — full windup ≈ 58° up, release ≈ 65° down — and
  re-ran just the throw through the pipeline. Now it reads unmistakably as a windup-then-gore
  in the running game, in sync with each flag the bull hurls.

Verified live via `conjugar://game` (flags **on**, `CONJUGAR_GAME_TIME_SCALE=0.2` to catch
the 0.5 s throw): the bull patrols the top girder as a rendered bull, feet planted, mirror
flipping at each turn; the throw plays windup→release when it hurls a flag; and there is **no
numbered box anywhere** — both actors are sprites. Credited Leo_Aguiar under a new
`^Game Art^` / `^Arte del Juego^` section in the Credits screen (Info ▸ Credits), CC BY 4.0
with the model URL.

7/11/26: Cel/toon palette pass — re-shaded the dancer and bull sprites from
photoreal-grey to a drawn cel look in Conjugar's palette, so both actors read as one
hand-styled game.

- **Decision baked in up front: dancer = GOLD, bull = RED, black outline on both.**
  The dancer is the hero, so it pops gold (`customYellow` #CDA51B) on the dark field;
  the bull is the antagonist, red (`customRed` #C1001D). The bull sits *on* the red
  girders, so a black cel outline is required to separate it — and the same outline
  goes on the dancer so the two match. No new frames, no new imagesets, no new source
  models: this was a pure re-render + re-shade of the 8 actions (32 frames) already
  shipping, swapping the PNGs inside the existing imagesets.

- **Flat → real cel material.** `render_sprites.py`'s `--toon` used to apply a flat,
  single-colour Principled material. I upgraded it to the cel node graph the plan
  called for: `Diffuse (white) → Shader to RGB → ColorRamp (Constant, 2 stops) →
  Emission → Output`. The white diffuse + Shader-to-RGB turn scene lighting into a 0–1
  luminance the constant-interpolation ramp quantizes into flat bands; the ramp *stops*
  carry the palette (shadow = base × 0.55, lit = base), so the whole mesh stays one hue
  and only the bands do the shaping. EEVEE-only (Shader-to-RGB is an EEVEE node), so
  `--toon` now aborts loudly if the engine isn't EEVEE instead of silently falling back
  to Workbench (which would erase the look).

- **A flat cel exposes colour bugs a photoreal render hides.** First red bull came out
  hot magenta-pink, not #C1001D. Two fixes, both about colour management. (1) Blender
  4.5 defaults to the **AgX** view transform, which desaturates/shifts saturated reds —
  I set **Standard** for toon renders so the palette hex passes through. (2) The
  `PALETTE` fractions are **sRGB**, but a Blender colour socket is **linear**, so feeding
  the raw value renders it too bright (0.757 sRGB → 0.89 on output = pink). Converting
  sRGB→linear before assigning the ramp stops means Standard's linear→sRGB output lands
  back on the exact hex. After both, the bull's lit band samples to **(193, 0, 29) =
  #C1001D** on the nose, gold to #CDA51B.

- **The outline is Freestyle, not the Solidify inverted-hull the plan sketched.** The
  plan's `--outline` was a flipped-normal Solidify shell with a black back-face material.
  Under this build's **EEVEE-Next** it just wouldn't behave — a 4-variant probe
  (flip×cull, offset ±1, thickness sweep) either culled the silhouette rim away (no
  outline at all) or swallowed the whole figure in black. Rather than keep fighting the
  culling/offset ambiguity I switched to **Freestyle** silhouette line rendering:
  deterministic, and its thickness is directly in **output pixels** — which is exactly
  what you tune against. 2px reads as a crisp cel edge; 3.5px merges the interior contour
  lines into a black blob. I confirmed 2px holds by downscaling the 192px render to the
  real ~168px on-screen size (56pt × 3×) and to a worst-case 60px.

- **The #1 trap the plan flagged is real: the outline moves the crop boxes.** But not the
  way you'd fear. Freestyle draws the line *outside* the mesh bounds, so the renderer's
  ortho auto-fit — and therefore the **body's** rendered pixel size — is unchanged; the
  union-crop just grew a uniform **~+4px** on every dimension from the line poking past
  the silhouette. `pack_or_rename.sh` re-cropped all 8 actions; I recorded every new
  `WxH` and re-derived the `GameView.swift` constants: each `dancerWidth(_:)` aspect
  refreshed to its new `cropW/cropH`, `dancerVisualHeight` bumped **56 → 57.3** (× 173/169)
  to hold the character *body* at its prior on-screen size, and `bullCrop(_:)` updated to
  the new dims with `bullScale` left alone (the bull was already body-constant; the +4px
  is just outline margin). Both actors end up body-constant with a thin outline around —
  consistent, feet still planted (the outline wraps under the shoe).

- **Verified live in `conjugar://game`** (flags on, `CONJUGAR_GAME_TIME_SCALE=0.2`): gold
  dancer and red bull, both cel-shaded with a crisp black edge; the bull's outline cleanly
  separates it from the red girders (the whole point). Drove the dancer live through idle,
  walk (correctly mirrored to face travel), jump (airborne pose), and up a ladder (climb,
  back-view, non-mirrored); the bull's throw cycled windup→gore. No clipping from the
  fatter silhouette, sizes right relative to each other and the platforms.

- **No credits/license change** — same source models (dancer = Mixamo X Bot, bull =
  Leo_Aguiar CC BY 4.0), just re-shaded. `asset-licenses/` untouched.

---

## Rendered-realistic dancer spike — a go/no-go art decision (2026-07-11)

A deliberately-throwaway spike (not a ship): before committing further to the flat
gold/red cel look, answer with *two pictures* whether a **Vainglory-style
rendered-realistic** dancer is enough better — **at the game's real ~57pt sprite size**
(`GameView.dancerVisualHeight = 57.3`) — to justify pivoting the whole art direction.
Deliverable = one honest comparison artifact + a go/no-go. Result published as an HTML
Artifact; nothing wired, `--toon` untouched, no imageset swaps.

**Recommendation: NO-GO on a full pivot; the look wins but the pivot isn't worth it yet.**
Bank the realistic render as a menu/marketing hero; keep the cel look in-game; revisit only
if a real mesh is commissioned. Reasons below.

- **The look genuinely wins at 57pt — and it survives shrinking.** I baked a *true-pixel*
  comparison (not DPI-dependent CSS scaling): cel dancer vs realistic dancer at exactly 57
  and 114px tall. Even at 57px the realistic dancer is a legible, colourful, posed figure on
  a warm ground; the cel dancer is a flat gold silhouette. The plan's size-truth held: what
  carries at 57pt is **rim/back light, colour-blocking + clean AA, silhouette/pose, and the
  lit atmospheric ground** — *not* fine texture, which vanishes anyway. Honest caveat baked
  into the artifact: today's cel dancer is a bare gold **mannequin** (X Bot), so part of the
  gap is that the shipped art is minimal — a *costumed* cel would close some of it, but not
  the lighting/ground part.

- **Sourcing the mesh is where it breaks — the load-bearing finding.** All three free-tier
  Rodin generations produced unusable blobs: text-to-3D (dance pose) → an incoherent
  boot+ruffle column; text-to-3D (A-pose) → a ruffle ring where the head goes; **image-to-3D**
  from a clean Gemini concept → right gold/red colours with a real head/arms, but single-image
  reconstruction has no side/back data so it extruded a **flat cardboard slab** — and the game
  renders *side-on*, where a slab is a plank. A shippable realistic dancer therefore needs a
  hand-made/commissioned mesh (or paid higher-fidelity gen) — a real, un-budgeted line item,
  not a free step. *(Blender MCP gotcha: Rodin/Sketchfab/PolyHaven are all off by default in
  the BlenderMCP sidebar panel; each needs its checkbox + a key. Rodin's "Set Free Trial API
  Key" button unblocks text/image-to-3D with no account.)*

- **The concept image, by contrast, is trivial and excellent.** One `gemini-image` prompt
  (gold gown, red ruffle trim, dynamic pose, warm key + cool rim, bloom, moody lit plaza with
  bokeh + haze + contact shadow) produced a premium, on-brand hero on the first try. It *is* a
  legitimate exemplar of the target look — but it's a **2D render, not a riggable asset**, so it
  can't become the 8 in-game actions. That gap (look is cheap, riggable character is dear) is the
  whole cost story.

- **`--realistic` mode added to `render_sprites.py`** — the near-inverse of `--toon`, kept a
  separate flag: **keeps** the mesh's PBR materials (doesn't clear slots), a 3-point + **rim**
  rig (warm key / cool fill / bright rim-back, area lights for soft shadow; the rim replaces the
  cel outline), **AgX** view transform (the opposite of the cel path's Standard), EEVEE-Next
  raytracing/AO/soft-shadow, a **compositor Glare (Bloom)** node (EEVEE-Next removed
  `eevee.use_bloom`, so bloom is strictly a compositor pass now — which is what the plan wanted),
  **no** Freestyle outline, 512px. Guarded so it never silently lands on Workbench (no PBR) and
  never falls back mid-render. Tuned the rig on one frame: first pass blew out (key 1400W →
  600W, key:fill ~6:1, rim 1500W).

- **Engine reality re-confirmed: only `BLENDER_EEVEE_NEXT` headless — no Cycles** (the engine
  enum has exactly one entry on this build). EEVEE-Next is enough to decide (AO, soft shadow,
  raytraced GI, compositor bloom), but every frame is a full lit render, not a flat blit.

- **Bull bonus (a pivot is both actors).** The bull is already a real mesh, so I ran
  `bull_idle.fbx` through `--realistic`: clear step up — sculpted form, soft contact shadow, cool
  rim — even though the FBX carried no texture (reads as marble; a red PBR skin would put it
  on-brand). Confirms both the look direction *and* that the bull, too, would need re-lighting +
  re-rendering across idle/walk/throw.

- **If "go" (out of scope here):** discard the cel/outline work; source a real costumed mesh; rig
  + animate all 8 actions (dancer idle/walk/climb/jump/cape + bull idle/walk/throw), each re-lit
  and re-rendered; **restyle the whole environment** — load-bearing, not optional, since premium
  characters orphaned on the flat-black red-girder field would look *worse* than the cel sprites.
  So a "go" is really "go on characters **and** world."

Raw meshes + concept/hero PNGs stay under `tools/blender/source/` (git-ignored). The
`--realistic` code and the comparison artifact are the only keepers, and only if Josh wants the
experiment retained.

## 2026-07-12 — Bull cel accents ($0, no purchase): flat-red blob → bull with character (paid-asset spike, Phase 0 Part A)

Phase 0 Part A of the paid-asset spike (`prompts/game_paid_dancer_bull_spike.md`): give the
bull character *for free*, before spending anything on the dancer. The bull's *shape* was never
the problem — it only read as a red blob because `--toon` filled the whole 30k-vert mesh with
**one flat material** (`apply_cel_material` clears every slot and appends a single cel material).
The fix is a **re-skin, not a new asset**: partition that one material into a few cel regions.

- **`--accents` (bull-only) added to `render_sprites.py`.** Refactored the cel node-graph into a
  reusable `build_cel_material(name, rgba, bands)`; `apply_bull_accents` builds a **body + muzzle
  + hooves + horn + eye** palette and assigns each polygon a material slot by region. Body stays
  red (rendered `--bands 3` so a lit highlight band gives the back/shoulder volume — the biggest
  "not-flat" win); muzzle / hooves / eye are base × 0.35 deep-maroon (a shadowed snout, grounded
  hooves, a small eye dot per flank); the **horn** is the fork.
- **Region selection = rest-pose local centroid boxes.** Membership is tested on each poly's
  undeformed `vertices[i].co` (stable across frames — the armature deforms at eval time), so the
  ivory horn and dark muzzle correctly **follow the head as it rears in the throw**, and the dark
  hooves follow the legs mid-stride. Boxes were measured from `bull_idle.fbx` with throwaway probe
  scripts (bull runs along Y: muzzle at −Y ≈ −1.68, rear +Y; Z up: hooves z ≈ 0, back z ≈ 1.6;
  `--view side` shows the +X flank). Documented as the one fragility if the mesh is ever swapped.
- **Art-direction fork, decided by Josh: ivory horn.** Rendered baseline / ivory-horn / all-dark
  variants and downscaled to 64 & 96 px. The verdict was unambiguous — at on-screen size the
  **ivory (bone) horn is the only accent that clearly reads**, and it's *the* bull signifier; the
  dark muzzle + hooves add a face and grounded feet; the highlight band adds volume. The all-dark
  variant is a more cohesive pure-red villain but loses the horn. Ivory it is (on-brand — the app
  icon likewise puts a non-body accent, gold, on red). Both ship behind `--horn-style ivory|dark`.
- **Zero `GameView` changes — a true re-skin.** Accents touch only materials, not the silhouette,
  so the union-crop boxes are byte-identical to the shipped bull (idle 168×91 / walk 174×97 /
  throw 174×118). Re-rendered all three actions, copied the 13 PNGs into `Assets.xcassets/Game/`,
  built, and **live-verified** via `conjugar://game` (flags-off, time-scale 0.2): the bull reads
  with real form — ivory horn, lit back, dark muzzle/hooves. Screenshot in `docs/screenshots/`.

- **Horn-box correction (the "Oregon" bug).** The first horn region (`y<-1.15, z>1.25`, no X
  gate) flooded the whole central forehead, so the ivory read as a ragged amorphous patch on the
  brow — Josh's words: "the northwest corner of Oregon, flipped." A focused re-probe showed the
  actual horns are the **two side protrusions** at |x| ≈ 0.45 (y ≈ −1.55, z ≈ 1.30), sweeping
  forward+down to a point. The fix is an **off-center gate**: `y<-1.38 ∧ z>1.15 ∧ |x|>0.28` — the
  |x| test is what separates the horns from the central muzzle/brow (1829 horn polys vs 7906
  before). Now the ivory lands on the thin forward horn and reads as an unmistakable horn tip at
  64 px, on the black field, and correctly tracks the head down into the goring pose on the throw.

- **Black-background correction (the real legibility bug).** Live on device the head *still*
  read poorly — Josh: "lack of contrast between the black horn and black background." The dark
  muzzle (base × 0.35) sat at the head's silhouette **edge**, and against the game's near-pure-
  black field — over which the black Freestyle outline is itself invisible — the whole front of
  the head vanished into the void, horn and all. The rule this taught: the silhouette is defined
  *only* where a light/red fill meets black, so **edge** regions (muzzle, horn, back) must stay
  red/light and only **interior** regions (the eye, on the red cheek) may go dark. Fix: **dropped
  the dark muzzle — the head stays body-red** (reads on black like the body), the **ivory horn is
  the lone light accent** (pops on black, made slightly bolder), and the **dark eye** moved to
  interior-on-red so it reads as a face. Verified live: the head is now a clearly-defined red bull
  head with an eye + horn, not a black void. (A dark muzzle *would* help on a light/red bg — but
  the bull is never on one; the accent scheme is background-specific.)
- **Polish pass on Josh's high-res look.** Two more device notes: the eye had been over-enlarged
  (radius 0.12 → 553 polys) into a black *blob* ("what is that dot?") — shrunk to radius 0.085 (14
  polys), a small neat eye. And the hooves at base × 0.35 read as near-black against the field —
  lightened to **base × 0.60**, clearly darker than the body but still visibly maroon, not black.
- **Horn-reads-as-a-speck fix + a 25% bigger bull.** On a *real iPhone* (not the sim) the
  tip-only ivory horn rendered as a lone ~3 px white speck at the game's ~60 pt bull height —
  it read as a glitch, not a horn (my 200–400 % sim zooms had flattered it). Two changes: (1)
  widened the horn region back+down to the **whole horn base** (`y<−1.22 ∧ z>1.08 ∧ |x|>0.24`,
  4053 polys vs 2251) so the ivory is a clear **pair of horns**, not a dot — the |x| gate still
  keeps it off the central forehead; (2) Josh spotted headroom in the top gap, so **`GameView.
  bullScale` 0.653 → 0.816 (+25 %)** — a bigger bull that gives the small-geometry horn + eye the
  pixels to read. That's visual-only: collision is `GameState.bullSize`, and the per-action feet
  offset re-derives from `bullHeight`, so the feet stay planted. Live-verified on the bigger bull:
  the horns and eye now read at play size, feet on the platform, clear of the HUD.
- **The real horn fix was RESOLUTION, not shape (device-only bug).** The bigger bull exposed that
  the horn still read as a blocky/smudgy speck *on a physical iPhone* — because the sprites were
  rendered at `--size 192` (a ~168 px-wide crop) but the enlarged bull displays at ~410 px @3x, so
  `.interpolation(.none)` was upscaling ~2.4× and turning the few horn pixels to mush. Fix: render
  the **bull at `--size 512`** (source ≈ the @3x display size → crisp horns) and switch the bull
  `Image` to **`.interpolation(.high)`** (the dancer already used smooth; nearest-neighbor *frays
  the outline into spikes* when downscaling 512→display). One more trap: bumping `--outline-width`
  to 5 to keep the on-screen edge thickness made Freestyle draw **hair-like contour spikes** at 512
  — kept the default width 2 (a thinner but clean edge). Re-derived the crop constants for the
  512/width-2 render (idle 436×230, walk 452×248, throw 452×306) and dropped `bullScale` 0.816 →
  **0.314** to hold the +25 % on-screen size (436 × 0.314 ≈ 137 pt, = old 168 × 0.816). Only the
  bull needed 512: the dancer displays near 1:1 from its 192 render, so it stays. Live-verified: a
  crisp bull, two clear ivory horns, no spikes.

**Outcome / spike status:** the bull half of the Definition of Done ("reads as *a bull with
character* at 57 pt, Phase 0 free-fix") is **met for $0** — no marketplace bull or commission
needed (Phase 0 Part C not triggered). `--toon`/`--realistic` code unchanged elsewhere. Still
open: the **dancer** (the real point of the spike — Phase 1 marketplace shortlist + Phase 2
paid-AI lottery). For those, the plan is free accounts on CGTrader / TurboSquid / Sketchfab / Fab
now, buy per-asset only on a winner; defer any paid-AI (Meshy/Tripo/Rodin-Pro) until Phase 1
stalls, since rig topology — not texture — is the failure mode AI-gen keeps hitting.

## 2026-07-12 — Dancer spike Phase 1: marketplace shortlist (the flamenco mesh)

- **Drove CGTrader / TurboSquid / Sketchfab / Fab via Claude-in-Chrome** to shortlist a
  game-usable **flamenco-dancer** mesh that clears the app-icon floor (female + red ruffled
  dress + dynamic pose at 57 pt). Full shortlist in `docs/dancer_shortlist.md`.
- **The whole market has exactly one game-usable flamenco character:** Animod's "Flamenco
  Dancer" — a woman in a tiered **red ruffled dress**, hair-in-a-bun-with-a-flower, cream
  skin, clean **A-pose**; textured FBX (+MAX), 21k tris, **Royalty-Free (no AI)** so it's
  app-embeddable. It shows up on all three stores (CGTrader **$6.99** sale / TurboSquid
  $9.99 / Sketchfab). It is **not pre-rigged**, so Phase 3 = Mixamo auto-rig, and the
  floor-length tiered skirt is the one deform risk to watch. **Recommended buy.**
- **Everything else is a non-starter:** 3D-print STL figurines (`.stl`, no rig/topology),
  dress-only assets, statues/decor, or mocap **animation** packs (Fab was *all* mocap, no
  mesh). A few rigged "female dancer" hits sit behind CGTrader's **18+ gate** — but on
  inspection that's *not* erotic content: they're **Adobe Fuse** base figures (nude base body
  under separate garments) whose preview set includes a base-body topology render, which the
  store auto-flags. The clean "RIGGED Ballerina" is wholesome and well-rigged; its real
  disqualifier is the **tutu (wrong costume)**, not the rating.
- **No pre-rigged flamenco/Spanish female dancer in a dress exists** — exactly the scarcity
  the spike predicted. The rig-de-risk path (buy a rigged base + retexture) only offers
  ballerina/cheerleader costumes that won't read as a gown, so it's dispreferred; the
  documented backup is the **$5 "Bustier Ruffled Flamenco Spanish Skirt Dress"** (FBX/OBJ,
  PBR, derivative-retexture explicitly licensed) skinned onto a base rig, else Fiverr.
- **Handoff:** Josh buys Candidate A (I don't run checkout), drops the FBX in
  `tools/blender/source/`, then Phase 3 runs the cheap 57 pt `--toon` idle acceptance render
  against `icon1024.png` before any animation/rigging investment.

## 2026-07-12 — Dancer spike Phase 2: paid-AI lottery (free-trial pull = same failure)

- **Fired one image-to-3D pull** feeding the clean `dancer_concept_front.png` (gold gown, red
  ruffles, A-pose) to **Rodin** via BlenderMCP — the key is still the **free-trial** tier
  (paid needs Josh to paste a paid key or auth Meshy/Tripo, which I can't do). Added a
  `bbox_condition [1,2,5]` hint to bias an upright figure and counter the prior "flat slab."
- **Textures improved, topology did not.** Framed head-on it *looks* like a coherent dancer in
  a gold gown with red trim — much better skin/cloth than the prior blobs. But the side profile
  exposed the truth: a **detached lower body floating beside the dress, a long needle-spike
  artifact, and stray floating bits** (a red ball by the head). Non-manifold, fragmented, limbs
  not attached → **would fail Mixamo auto-rig.** Deleted it.
- **Verdict: the lottery came up empty, same failure mode as the prior spike** — exactly the
  risk the plan named ("paid gen has better textures but rig topology is still the failure
  mode"). Two independent AI-gen attempts on a ruffled-dress figure now both die on riggable
  topology. Strong evidence the *paid* tier would buy nicer textures on the same broken mesh.
- **Recommendation:** don't spend on paid AI; put the money into **Candidate A** (the $6.99
  Animod marketplace mesh) + Mixamo. Left open for Josh: if he still wants the paid shot, he'd
  need to auth Meshy.ai / Tripo3D in Chrome or paste a paid Rodin key, and I'd drive it.

## 2026-07-12 — Dancer spike Phase 3 gate: the 57 pt acceptance test PASSES

- **Bought + landed Candidate A.** Josh purchased the Animod "Flamenco Dancer" on CGTrader
  ($6.99, Royalty-Free no-AI); extracted `Flamenco_Dancer.fbx` (single mesh, 21k tris) + its
  39-file texture set into `tools/blender/source/` (git-ignored). License logged in
  `asset-licenses/cgtrader-flamenco-dancer.txt`.
- **Ran the cheap gate first (no rig needed).** The FBX ships in ~A-pose, so one frame through
  the *existing* pipeline — `render_sprites.py --toon --color gold --outline --frames 1
  --size 192` (front & side) — is the whole acceptance test. `--toon` overrides materials, so
  the missing-texture-path warnings are irrelevant; this is a silhouette/read test.
- **Result: PASS.** At true 57 pt (and 8× zoom) the render reads **unmistakably as a woman in
  a tiered flamenco dress** — bodice, cinched waist, flared ruffled skirt, dark hair — vs the
  genderless X-Bot mannequin it replaces. Side-by-side vs the app icon saved to
  `docs/screenshots/dancer_accept_57pt_vs_icon.png`. Differences from the icon are the intended
  ones: **gold** (established hero color) not the icon's red, and a static A-pose (dynamic pose
  arrives with Mixamo). **The spike's core thesis is confirmed: fix the mesh, keep the pipeline
  — one good riggable dancer through `--toon` clears the floor.**
- **Still ahead (full Phase 3):** Mixamo auto-rig → animate the 8 actions (idle/walk/climb/
  jump/cape) → re-derive `pack_or_rename.sh` crop constants → wire into `GameView`. The open
  risk stays the **floor-length tiered skirt through Mixamo** (weights to the legs; may split on
  walk/climb) — that's the next gate, tested once rigged. Optional polish: add **red ruffle
  trim** to hit the "gold gown + red ruffle" target from the palette note.

## 2026-07-12 — Dancer Phase 3 rigging: Mixamo auto-rig FAILS, but the mesh is already rigged

- **Mixamo auto-rig can't rig the dancer** — and the failure was instructive. Three uploads
  died with *"unable to map your existing skeleton"* before I found the real cause: (1) the
  vendor FBX ships **with its own skeleton**, so Mixamo took the "map a rigged character" path
  and failed; (2) after stripping the skeleton the first clean FBX still carried **57
  blend-shape (facial-morph) deformers** that Mixamo also read as a rig; (3) even a truly bare
  FBX failed — **Blender's binary FBX is misread by Mixamo**. An **OBJ** finally reached the
  Auto-Rigger. Then the auto-rigger itself **bounced off the marker step**: the **floor-length
  tiered skirt gives the legs no separate silhouette**, so it can't resolve two legs. (Lesson:
  Mixamo needs leg separation; a full skirt defeats marker-based auto-rig. OBJ > FBX for
  Blender→Mixamo.)
- **The reprieve: the model is ALREADY rigged, Mixamo-compatibly.** Inspecting the vendor
  skeleton: **63 bones with exact Mixamo names** (`Hips, Spine1-3, LeftUpLeg, LeftLeg,
  LeftFoot, RightUpLeg, …`) — and **the skirt mesh (`MASkirt_03`) is skinned to the hip + leg
  bones** (vgroups Hips/LeftUpLeg/LeftLeg/RightUpLeg/RightLeg). So we never needed Mixamo's
  auto-rigger; we can pose/animate the existing rig directly, and Mixamo mocap can be
  **retargeted** onto it because the bone names already match.
- **Skirt walk test = PASS (the spike's biggest unknown, resolved).** Posed the legs into a
  full mid-stride split on the existing rig and rendered `--toon` front + side
  (`docs/screenshots/dancer_stride_skirt_test.png`). The tiered skirt **swings and stretches as
  a coherent gown — it does NOT tear into "pants" between the legs.** The floor-length dress is
  viable for locomotion. So the dancer path is a go; remaining work is producing the 8 action
  clips on the existing rig (retarget Mixamo mocap, or hand-key like the bull) — no auto-rig.

## 2026-07-12 — Dancer walk cycle: retargeted Mixamo mocap → PASS

- **Path that worked:** don't auto-rig — retarget onto the vendor's existing Mixamo-named rig.
  Drove Mixamo (in-browser) to download **"Walking (In Place)"** on the X Bot, then in Blender
  retargeted it onto the dancer's rig. Because rest poses differ (dancer = A-pose, Mixamo =
  T-pose), a naive local-rotation copy would break the arms; instead used **world-space
  COPY_ROTATION constraints per bone (+ COPY_LOCATION on Hips) then `nla.bake`** — robust to
  rest-pose mismatch, no bone stretch. 52 bones baked across the 32-frame cycle.
- **Result: a clean walking flamenco dancer.** Rendered through the existing `--toon --color
  gold --outline` side view: the gown reads as a dancer walking in profile and **the
  floor-length tiered skirt sways as a coherent mass** — the spike's central risk, now shown
  working in actual motion, not just a static pose. Filmstrip + GIF in
  `docs/screenshots/dancer_walk_filmstrip.png` / `dancer_walk.gif`.
- **Two integration notes for the full pass:** (1) frame 1 of the render is the FBX **bind/rest
  pose** (T-pose) bleeding in — skip it (render frames 2-N or trim the action's first frame);
  (2) `render_sprites --start/--end` mis-sampled (re-showed the rest pose) — investigate before
  the final multi-action render; default-range sampling works.
- **Perf gotchas hit:** macOS has no `timeout` binary (silently no-ops a wrapped command — use
  the tool timeout); and a per-frame/per-bone `view_layer.update()` retarget is too slow (2 min
  timeout) — the constraint+`nla.bake` route is the fast, correct one.
- **Status:** walk validated. Remaining Phase 3: retarget idle/climb/jump/cape the same way,
  render all, re-derive `pack_or_rename.sh` crop constants, wire into `GameView`, verify live.

## 2026-07-12 — Dancer walk, CORRECTED: retarget was a mirage; hand-keyed walk is the real one

- **The earlier "retargeted walk PASS" was wrong** (caught by Josh: every frame looked
  identical). Diagnosing revealed *two* traps: (1) the exported action range was **[1,1557]**,
  not [1,32] — the vendor rig carried its own long baked animation, so `nla.bake` with
  `use_current_action=True` kept frames 33-1557 as a **static hold**; `render_sprites` then
  sampled 8 frames across all 1557 and landed almost entirely in that hold → identical frames.
  Fixed by `animation_data_clear()` + `use_current_action=False` → clean [1,32]. (2) With a
  clean range the real retarget frames were **broken** — arms splayed into a T-pose — because
  world-space `COPY_ROTATION` assumes matching rest poses, but the dancer rests in **A-pose**
  and Mixamo in **T-pose**. Restricting the retarget to legs/spine (same in A & T) and leaving
  arms at rest *still* misaligned the root (the two armatures have different base orientations).
- **Resolution: hand-key the walk** (like the bull). Reused the proven `worldX_rot` leg-swing
  from the stride test — swing `LeftUpLeg/RightUpLeg` about world-X in opposite phase, bend the
  shins, subtle hip bob; arms stay at the elegant A-pose rest. A **6-frame** cycle (matching
  `playerFrameCounts[.walk]`). First pass over-strode (shoes flew out past the hem as detached
  blobs); dropped thigh swing 25°→14°, shin 48°→26° for a graceful glide where the feet just
  peek at the hem. Renders through `--toon --color gold --outline` as a clean walking flamenco
  dancer; the floor-length skirt sways as a coherent mass. `docs/screenshots/dancer_walk_*`.
- **Takeaway for the remaining actions:** Mixamo mocap **retarget is not viable** onto this
  A-pose-rest rig without proper rest-pose correction; **hand-keying on the existing rig is the
  reliable path** (idle/climb/jump/cape next), exactly as the bull was done.

## 2026-07-12 — Dancer walk finalized: "animate the gown" (feet hidden)

- **Detached-feet problem = inherent to a floor-length gown side-on.** The legs live inside
  the skirt, so only the *shoes* poke below the hem; any real stride swings a shoe past the hem
  and it reads as a detached blob (Josh flagged this). A subtle stride hid it but read as a
  gentle glide.
- **Direction decided by Josh: hide the feet, animate the gown.** Removed the shoe mesh
  (`HeA_MltherShoesA_01`); the walk is now a clean **gown + torso** — subtle leg motion still
  drives the skirt (skinned to the legs) so the hem swishes + a small body bob, but nothing
  pokes out below the hem and nothing detaches. This is the **house style for all dancer
  actions** now (a stylized floating-gown dancer). 6-frame cycle,
  `docs/screenshots/dancer_walk_*`.
- **Remaining Phase 3:** hand-key idle/climb/jump/cape in the same gown style (no feet), render
  all through `--toon`, re-derive `pack_or_rename.sh` crop constants, wire into `GameView`,
  verify live. Climb/jump will be gown-and-body gestures (no legs on rungs) — consistent with
  the chosen stylization.

## 2026-07-12 — Walk wired into GameView + verified live

- Rendered the feet-hidden gown walk as 6 `dancer_walk_*` frames, union-cropped via
  `pack_or_rename.sh` (**box 122×226**), installed into the `dancer_walk_1..6.imageset`s, and
  updated `GameView.dancerWidth(.walk)` aspect **113/173 → 122/226**. Build succeeds; the
  SourceKit "cannot find GameState/PlayerAction" spam is the usual same-module false positive.
- **Live-verified** via `conjugar://game` (time-scale env, flags off): holding right, the player
  now renders as the **gold flamenco gown dancer** walking on the platform, correctly planted
  and sized (~57 pt), replacing the X-Bot mannequin. Screenshot `20260712-111531-walk-a.png`.
  Idle/climb/jump/cape still show the old mannequin (only walk was wired, per Josh's request) —
  so idle↔walk visibly swaps figure until those are done.
- **Remaining:** hand-key idle/climb/jump/cape in the feet-hidden gown style, render + crop +
  wire each, then a consistency pass so standing and moving match.

## 2026-07-12 — Dancer finished: idle / jump / cape / climb hand-keyed in the gown style

- **The last four player actions are now the flamenco gown, not the X-Bot mannequin.** Wrote
  `tools/blender/gen_dancer_action.py` — one parametrized generator that imports the purchased
  gown, deletes the feet, hand-keys an action on the vendor's own 63-bone Mixamo-named rig, and
  bakes `source/dancer_<action>_gown.fbx`. Rendered each through the same `--toon --color gold
  --outline` path as the walk, union-cropped, installed, and updated `GameView.dancerWidth`.
  - **idle** (2, side) — gentle breathe/hip-bob; **jump** (3, side) — crouch → rise → apex with
    a Hips-Z lift, gown trailing as a cone; **cape** (4, side) — overhead flamenco arm flourish
    with a skirt sway; **climb** (4, **back view**) — arm-over-arm reach from behind.
- **Two bugs paid for, now documented in the blender README so they don't regress:**
  1. **Rotating a leg bone pushed the bare-legs mesh out below the hem as thin gold strands.**
     The skirt is skinned to the leg *bones*, not the leg *mesh*, so deleting `YF7_Leg_02` (on
     top of the shoe mesh) keeps the hem sway but removes the strands. Feet fully hidden.
  2. **The rotation helper pivoted about the world origin, not the bone's head** — invisible at
     the walk's ~15° leg angles, catastrophic at the cape/climb's 125–155° arm raises (the hand
     swung on a huge arc through the body → the arm rendered as a long dangling strand). Fixed by
     preserving each bone's translation so it rotates about its own head (proper FK).
  3. **Climb frames 1 and 3 were identical** (opposite-phase `sin`, and `sin 0 == sin π`), so the
     arm-over-arm only showed in half the frames — quarter-phased the two arms (`sin` vs `cos`)
     so all four frames differ.
- **Consistency pass holds.** All five gown crops land at ~225–229 px tall (vs the old
  mannequin's ~173), so at the constant `dancerVisualHeight = 57.3` they read at one size with
  the hem glued to the platform — standing ↔ walking ↔ climbing no longer pops between figures.
- **Live-verified all five in `conjugar://game`** (slowed 5×, flags off): idle standing, walk
  mid-stride (mirrored), jump airborne as a cone, climb from behind on a ladder, and cape (after
  collecting the 🧣 pickup) as the arms-raised flourish. Build green. Raw FBX/textures stay
  git-ignored; only the 13 PNGs + `gen_dancer_action.py` ship.

## 2026-07-12 — Cape reworked: a held muleta (swing while still, hold-in-front while walking)

- **Reframed the cape from a worn overlay to a held prop** (Josh's vision): the dancer holds
  a red muleta in front of her — **swinging it up and down while standing still**, and
  **holding it out in front while walking**. Replaced the earlier arms-raised "flourish" cape.
- **Two new caped animations, hand-keyed** (`gen_dancer_action.py`): `cape` (4, standing swing)
  and a new `capeWalk` (6, hold-in-front over the shipped walk's leg cadence). Added a
  scripted **muleta** mesh — a flared red cloth that hangs down+forward — that is **keyframed to
  the hand midpoint each frame** (not skinned), so the arm swing carries the cape up and down.
- **Two-material cel render:** `render_sprites.py --cape` paints the `Muleta` mesh **red** and
  everything else **gold** (same trick as the bull accents), so the cape stays in the cel look
  and moves with her hands. `pack_or_rename` boxes: cape **152×225**, capeWalk **155×227** —
  wider than the other actions (the muleta juts forward), same ~226 height.
- **Axis gotcha:** the arms first swung the cape *behind* her. Probed the rig — front is **−Y**,
  and **negative** world-X swings the arm up-and-**forward** (positive throws it back). Flipped
  the sign; measured, didn't guess.
- **Game state:** added `PlayerAction.capeWalk` (`playerFrameCounts` 6) and a branch in
  `derivedPlayerAction` — `isCaped && walking → .capeWalk`, else `walking → .walk`; standing +
  caped → `.cape`. Retired the little 🧣-emoji overlay on the player (the cape is in the sprite
  now); the about-to-expire warning is now a **flash of the whole caped pose** (`isCaped &&
  !isCapeVisible → opacity 0.4`), preserving the blink signal without a separate glyph.
- **Live-verified** in `conjugar://game`: collected the pickup, stood → muleta swings in front;
  walked → muleta held out front, correctly mirrored by facing; let it lapse → reverts to the
  plain gown walk (expiry works). Build green. The platform 🧣 pickup stays an emoji for now.

## 2026-07-12 — Cape pickup: the muleta replaces the 🧣 "ribbon" on the map

- Swapped the platform cape pickup from the 🧣 emoji to a **rendered red muleta** (new
  `gen_muleta_pickup.py` builds the standalone cloth; `render_sprites.py --cape` paints it
  red), so the collectible matches the muleta the dancer carries. Standalone it needed real
  cloth character to read (a flat trapezoid looked like a flag), so the mesh got a flared body,
  a top fold, a forward curl, and a scalloped hem.
- Drawn at **60% of capeSize, sitting on the platform** (per Josh) so it matches the carried
  cape's apparent size; the collision box stays the full capeSize centered on `cape.y`, so
  collection is unchanged.

## 2026-07-12 — Brick platforms: a dotted gold "mortar" line

- Added a thin **dotted yellow line along each platform's top edge** (the walking surface, per
  Josh) so the red girders read as courses of brick rather than flat bars. Implemented as an
  explicitly-framed `HLine` shape `.position`ed at `platform.rect.minY`, dashed gold
  (`customYellow`, `dash [2,4]`, round cap). Two dead ends first: a bare `Path` with absolute
  coords in the `ZStack` silently didn't render (a `Shape` only lays out reliably inside its
  own frame), and `.overlay(alignment: .top)` on the flexible rectangle ignored the alignment
  (kept drawing at the bottom) — an explicit `.frame` + `.position` is what works.

## 2026-07-12 — Dancer walk "gait bob": a 1-pixel per-frame lift so she's not a ghost

- **Problem (Josh):** the walking dancer glides with zero vertical motion, reading as a
  ghost. Real bipeds trace a shallow arc while walking, but the platform gap is too short
  for a true parabola — and the feet are glued to the platform, so a large vertical
  excursion would visibly lift her off the brick. **A parabola isn't practical here; a
  small per-frame nudge is.**
- **Implemented** in `GameView.dancerWalkBob(_:frame:)`: a lift profile indexed by the
  1-based walk frame, added to `dancerFeetOffset` (negative y = up). Starting profile is
  **`0 0 0 1 1 1`** (frames 1–3 flat, 4–6 raised `dancerWalkBobHeight = 1` pt). The
  alternate to try if this reads wrong is `[0, 1, 0, 1, 0, 1]` — just edit
  `dancerWalkBobProfile`. Applies to both `.walk` and `.capeWalk` (shared 6-frame cadence).
- Build green; live-verified the walk still renders planted and correctly sized. The bob is
  1 pt (3 device px) — deliberately subtle, judged in motion rather than a static frame.

## 2026-07-12 — Matador goal figure: the kidnapped bullfighter is a sprite now

The game is Donkey-Kong-shaped: the flamenco **dancer** is the player, the **bull** is the
antagonist on the top platform, and — per `prompts/game.md` — "next to the bull is a
bullfighter that the bull kidnapped." That bullfighter had been a placeholder **🤺 fencer
emoji**. He's now a real rendered sprite standing beside the bull, matching the dancer/bull's
cel look. He is a **static, single-frame GOAL figure** — no animation, no in-game rig, just one
`Image("matador")`.

- **Sourced the male counterpart to the dancer.** CGTrader vfxsinghbu **"Matador - Bullfighter
  Rigged"** (#5905689, $42.50, CGTrader Royalty-Free / no-AI) — a Daz **Genesis 8 Male**, same
  store/license lane as the dancer. Because Genesis-8 separates the outfit into distinct garment
  meshes, the render needed a new **`--matador` per-garment cel mode** in `render_sprites.py`
  (`MATADOR_MESH_COLORS`): jacket/pants **blue** (dominant — so he's neither the gold dancer nor
  the red bull), vest/montera **gold**, socks **pink**, shoes **dark-red = the bull's hoof color**
  (a deliberate quote), shirt cream, body skin. New palette hues `blue/pink/skin/cream` joined
  the existing `gold/red`.
- **The pose fought the rig.** The Daz figure ships with **IK constraints** that override FK, so
  posing the arms did nothing until `gen_matador.py` **cleared all 255 pose-bone constraints**
  and re-posed the arms **hands-on-hips in pure FK**. Same script drops ~25 junk objects + the
  cape, hides the heavy vendor hair, and repositions/scales the **montera** onto the head. Three
  tweak rounds with Josh to land it: hands-on-hips (not "holding reins"), a solid montera, and
  the montera raised so the eyes + a little forehead show.
- **`--view back` = the FACE.** The Genesis-8 model faces **−Y**, so the front-on render is
  `--view back` (front-facing goal figure — hence, unlike the side-rendered dancer/bull, he is
  **never mirrored** in `GameView`).
- **Rendered at `--size 512`** (the bull's resolution lesson: he displays fairly large next to
  the bull, so 512 + `.interpolation(.high)` keeps the face/montera/outline crisp on device).
  Union-crop **188×452** from `pack_or_rename.sh` → `matador.imageset`. As always the crop box
  drives the `GameView` size constants — don't guess.
- **Placement (`GameView`).** Replaced the `Text(GameState.bullfighterEmoji)` block with a
  `matadorSprite`: constant `matadorVisualHeight = 74` pt, width from the render aspect (like the
  dancer), a feet offset so his shoes plant on the top girder's surface. He sits at the existing
  `bullfighterX = w*0.72`, to the right of the bull (`w*0.4`) — captive beside captor. Verified
  live in `conjugar://game` (screenshot: `docs/screenshots/matador-beside-bull.png`).
- **Emoji cleanup.** With the matador and cape both rendered sprites now, the placeholder-art
  constants `bullfighterEmoji` (🤺) and `capeEmoji` (🧣) and their glyph-warms were deleted;
  only the flag emojis remain as emoji (the "Placeholder art" MARK is gone).
- **Credits: none, by design.** The bull is credited in the Info ▸ Credits "Game Art" section
  *because CC BY requires it*. The matador — like the **dancer**, its CGTrader Royalty-Free
  sibling — requires **no attribution**, so it gets no credit line, matching the dancer's
  treatment exactly. License logged at `asset-licenses/cgtrader-matador.txt` with the Genesis-8
  render-only note; raw `.blend/.fbx/.rar` stay git-ignored (only the PNG ships).
- **Follow-ups, deliberately not built here** (a `// TODO(matador escape beat)` marks the spot):
  the full design has the bull **escape upward carrying the bullfighter** the first four times
  the player summits, then a final fight scene. Wiring the matador to ride along with the bull's
  escape — and the fight — is later work. Today he's a static goal figure. He's also fully
  rigged, so a future *animated* matador can restore the Daz IK targets (`lHand_IK`/`rHand_IK`)
  or hand-key FK like the dancer, then render N frames through `render_sprites.py --matador`.

## 2026-07-13 — Real flamenco game music: three Pond5 tracks in, placeholder out

- **The bland placeholder is gone.** The game's background loop was "Vaguely Spanish Guitar"
  (Clarence Simpson / casimps1, CC-BY via ccMixter). Replaced with three purchased **Pond5**
  royalty-free flamenco tracks — Pond5's Content License permits commercial use with **no
  attribution required**, so the CC-BY credit block was swapped for a short courtesy note (both
  `en` and `es` in `Localizable.xcstrings`).
- **Gameplay now loops "Flamenco Adventure."** The 25.1 MB / 2:22 WAV master was encoded to a
  192 kbps / 44.1 kHz stereo MP3 (~3.4 MB) and **overwritten in place** at
  `Conjugar/flamencoLoop.mp3` — the enum raw value `Music.gameLoop = "flamencoLoop"` and the
  existing `GameState → startMusic(.gameLoop)` call are unchanged, so gameplay music swapped with
  **zero project-file churn**. The filename is now legacy (holds Flamenco Adventure), documented
  in the `Music.swift` comment.
- **Two more tracks staged for features that don't exist yet.** "Spanish Tension" (→
  `Music.onboarding`, for the future onboarding flow *and* game-end scene) and "Spanish Guitar
  Standoff" (→ `Music.bossFight`) are bundled but **unwired** — those scenes aren't built. Spanish
  Tension's WAV had ~6 s of trailing silence (audio ends at 2:08.7, confirmed via
  `silencedetect`); trimmed to 129 s during encode. All three at 192 kbps: masters 25/39/7.5 MB →
  MP3 3.4/3.1/1.0 MB.
- **New synchronized `Conjugar/Audio/` group.** The root `Conjugar/` folder isn't a
  `PBXFileSystemSynchronizedRootGroup` (its MP3s are explicit pbxproj refs), so the two staged
  tracks went into a new synchronized `Audio/` group (fresh UUID registered in the group section,
  the app target's `fileSystemSynchronizedGroups`, and the `Conjugar` navigator group). Verified
  both land in the built `.app` bundle.
- **Masters kept out of git.** Pristine WAVs copied to a git-ignored `audio-sources/` folder;
  only the committed MP3s ship. CLAUDE.md gained a "Game music" section documenting the enum, the
  bundled-but-unwired tracks, and the planned onboarding wiring
  (`startMusic(.onboarding)`/`stopMusic()` on the onboarding view's appear/disappear).
- **Toolchain gotcha (this machine).** `ffmpeg` was DYLD-broken — linked against
  `libx265.215.dylib` (x265 4.1) after a Homebrew upgrade to 4.2 (`.216`). Ran it with
  `DYLD_LIBRARY_PATH=/usr/local/Cellar/x265/4.1/lib` (dyld matches the missing lib by leaf name)
  — no Homebrew surgery. `ffprobe` still aborts; `afinfo` handled probing.
- **Fixed a stale test.** `SoundPlayerTests.dummyAbsorbsEveryCall` still called the old
  argument-less `startMusic()` (never updated when the API was generalized to
  `startMusic(_ music: Music)` in the prior session) — updated to `startMusic(.gameLoop)`. Full
  suite green: 445 tests, 25 suites. Game verified live via `conjugar://game`.

## Onboarding flow (2026-07-13)

Ported Conjuguer's first-launch onboarding tour to Conjugar and adapted it to the app's
yellow design system and Spanish content.

- **`OnboardingView`** — a paged `TabView(.page)` cover with the auto page-dots, a
  bounce-on-appear icon, a yellow heading, body copy, and a per-sheet CTA. Sheets: a
  welcome sheet keyed by the **custom `bull` symbol** (the Quiz tab's icon, standing in for
  Conjuguer's wineglass), the four content sheets (Browse 4,811 verbs / Verb Models / Quiz /
  Deep-Dive Articles — the last now naming Spanish-language works, from the *Cantar de mío
  Cid* to García Márquez), a **conditional AI-tutor sheet** shown only when
  `languageModelService.isAvailable` (never in the simulator), and a new **game-preview
  sheet** keyed by the **custom `dancer` symbol** whose "Play the Game" CTA launches the
  under-development matador game. The final sheet shows the animated **"Get Started"** button
  below the dots. Top-right **Skip** (first run) / **Dismiss** (reshow). Styled yellow
  throughout — gradient, headings, buttons — per the brand.
- **Presentation.** First launch: `MainTabView` trips a `router.showOnboarding` cover once,
  gated by a new `Settings.hasSeenOnboarding` flag and the `OnboardingDisplay.onboardingEnabled`
  screenshot kill switch (mirroring `TipDisplay.tipsEnabled`). Reshow: a yellow **"Show
  Onboarding"** card on the Settings tab presents it with `isReshow: true` (never touching the
  flag). The game-preview CTA defers the game launch to each cover's `onDismiss` so two
  full-screen covers never contend for the anchor.
- **Music.** Wired the long-staged `Music.onboarding` ("Spanish Tension"): it starts on the
  view's `.onAppear` and **fades out** on dismiss via a new `SoundPlayer.stopMusic(fadeDuration:)`
  — the graceful counterpart to `startMusic`'s existing fade-in (the old `stopMusic()` hard-stop
  remains for the game). The delayed hard-stop captures the fading player so a game loop started
  right after onboarding is never cut off.
- **The `@Environment(AppRouter.self)`-in-a-cover trap.** `OnboardingView` first read the router
  from the environment like the sibling tab screens — which **crashed at runtime** ("No Observable
  object of type AppRouter found") because a `.fullScreenCover`'s content does *not* inherit a
  custom `.environment(_:)` object the way a direct tab child does. Fix: pass `AppRouter` in
  explicitly (to `OnboardingView`, and to `SettingsView` so it can forward it). Tab children
  (`InfoBrowseView`'s tutor deep-link) still read it from the environment, matching
  `VerbBrowseView`/`QuizView`. Verified end-to-end in the simulator: first-launch present, all
  page CTAs, the Settings reshow (the reported crash), and the game launch.

## Alternate app icons: a bull, a dancer, and a matador (2026-07-13)

Ported Conjuguer's alternate-app-icon feature to Conjugar and gave it a Spanish cast.
The Settings tab grew an **App Icon** card — a 2×2 grid of tappable thumbnails — offering
four icons: three new **photorealistic** icons (a fearsome **bull**, a **flamenco dancer**
mid-*zapateado* with castanets, and a **matador** in his gold-embroidered *traje de luces*,
hands on hips), plus the original flat-vector dancer retained as **Classic** for nostalgia.
Each new icon has a **light and a dark appearance variant**, on a subtly yellow-tinged field
(charcoal for dark, cream for light) with the Spanish red-and-gold carried bold on the dancer's
dress and the matador's suit.

- **How the images were made.** Drafted six Gemini-image prompts (bull/dancer/matador × light/dark)
  with explicit hex palettes, ran each three times, and picked winners. The dancer prompts fed a
  **cropped reference photo** (a Sevilla flamenco performance, arms raised, eyes closed) through
  Gemini's image-conditioned `--edit` mode — borrowing the *pose and ecstatic expression* while
  rendering a new, non-identifiable dancer. All three concepts ended up **tightly cropped** (bull
  head, dancer upper-body, matador waist-up), which reads far better than a full figure at ~120px
  and gives the set visual cohesion. Two framing lessons from the human in the loop: cropping the
  matador's *legs* is deliberate and fine, but cropping his *hands or hat* looks amputated — so the
  final matador prompt explicitly demands the full montera and both hands stay inside the frame.
- **Corner cleanup.** Gemini intermittently renders "iOS app-icon composition" as a literal
  rounded-rectangle with **white corners**. Rather than reroll good images, a small
  `numpy`/`scipy` script flood-fills the corner-connected bright blob and inpaints it with the
  neighboring background via a nearest-neighbour EDT — with a **background-adaptive threshold**
  (`(bg_brightness + 255) / 2`, ≈131 on the dark field, ≈215 on cream) so it catches the pure-white
  corners without eating the cream background, and a size guard that no-ops on full-bleed images.
- **The wiring** mirrors Conjuguer: an `AppIcon` enum (`bull`/`dancer`/`matador`/`classic`) maps each
  case to its `.appiconset` name (`alternateIconName`, nil for the primary) and a preview imageset;
  `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES` exposes the three alternate iconsets (Xcode
  auto-generates the `CFBundleAlternateIcons` plist entries); `Settings.appIcon` persists the choice
  and calls `UIApplication.setAlternateIconName` on change (guarded to no-op when already correct, so
  no spurious system alert). Because the app icon isn't loadable by name at runtime, each icon ships a
  separate **preview imageset** (light/dark) for the Settings thumbnail; the app can't reuse the
  appiconset for the picker.
- **Verified** in the simulator: the card renders all four thumbnails with correct light/dark variants
  and localized labels, and tapping a thumbnail moves the yellow selection ring reactively.
  `setAlternateIconName` itself throws `Input/output error` on the **Simulator** (a known limitation) —
  the guard confirms `supportsAlternateIcons` is true and the plist/asset config is correct, so the
  live swap needs a **real device** to confirm end-to-end (identical to Conjuguer's shipping mechanism).
  New `en`/`es` strings for the card title, description, and the four icon names.

## Boss-fight ideation: the dance-off (2026-07-13)

The game's finale was always going to be a confrontation with the bull, but Toreo por
Amor is family-friendly — so the fifth-summit boss became a **dance-off**: out-dance the
bull and he releases the matador, impressed. This session was pure ideation — three
candidate mechanics written up in `docs/boss_fight_ideas.md`, plus a visual pitch with
in-world mock screens published as a Claude artifact
(https://claude.ai/code/artifact/b03c6684-7748-43d8-8e99-ba8bcd10f6f8) — for Josh to
pick a winner before any implementation.

- **Research first.** Drove `conjugar://game` live via ios-build-verify; cataloged the
  sibling games with subagents (Konjugieren's four special mechanics, Conjuguer's five
  threats and its RobotBoss "telegraph → phases → celebratory payoff" template — the
  house recipe is *recognizable arcade trope × cultural theme × juicy feedback*);
  studied the dance-battle canon (Bust a Groove's button-sequence dancing and
  Enthusiasm meter, Space Channel 5's call-and-response verbs, Rhythm Heaven's
  audio-first "teach the beat before testing it" lessons); and mined flamenco itself,
  whose own vocabulary names the mechanics better than game jargon: the **llamada**
  (the stomp that means "your turn!"), **jaleo** (¡Olé!/¡Bien!/¡Uy! crowd shouts as the
  judgment tiers), **zapateado** (percussive footwork), and **duende** — the win meter.
  Also measured the staged boss track: "Spanish Guitar Standoff" is a 42.7 s seamless
  loop, which shaped all three round structures.
- **The three concepts.** **1 · La Llamada** — an echo duel (Simon × Space Channel 5):
  the bull dances a phrase move by move, cue icons popping above him, and the player
  dances it back on the D-pad, which morphs into a "dance pad" during the boss (its
  up/down slots are free — no ladders on the tablao). **2 · Lluvia de Rosas** — a pocket
  DDR: the crowd rains 🌹🎵👏 down three lanes toward a stage line, charted to the track
  and judged against the *music playhead* rather than the frame clock (drift-free), with
  an occasional 🔥 rest-note you must let pass. **3 · El Tablao** — lit-floor footwork:
  tiles flash under the bull's hooves as he walks his pattern, and the player answers
  the path with the walk/jump controls she's practiced for five levels — zero new
  buttons, cheapest art.
- **Shared staging** so the choice blocks nothing else: girders cross-fade to a tablao
  stage, a tug-of-war **Duende meter** (dancer vs. bull) replaces hearts, floating jaleo
  pops give feedback, nobody ever gets hurt (a failed round just rewinds while the bull
  showboats), and every concept ends with the bull's **bow** → matador freed → the
  planned end scene on `Music.onboarding`.
- **Recommended La Llamada** — the truest dance-*off* (an opponent who can lose
  graciously, on a track literally named a standoff), with an upgrade path: graft
  Concept 2's on-beat judgment into round 3 as hard mode, repurpose El Tablao's tiles as
  a level-5 climb gimmick, and ship a cheap first playable (big cue icons + reused bull
  bursts) before hand-keying the bull's two new dance actions in Blender.

**Update, same day:** Josh picked **La Llamada** ("funner, codes more as a dance-off" —
he'd been leaning Concept 2 before the mocks). Sixteen open questions were answered in
one pass — the notable calls: full bull fidelity up front (hand-keyed stomp/rear/bow
rather than an icon-led v1), a minimal end scene *included* and scored by
`Music.onboarding` (pulling a slice of item 4 forward), boss gated on the *first* summit
until the five-level escape structure exists, relaxed compás-bar timing (memory is the
challenge; on-beat bonuses deferred to a future hard mode), hearts hidden during the
duel with free retries and no lose state, a new Pixabay SFX pack (castanets, palmas,
crowd olé, snort), and Spanish jaleo strings in **both** localizations — the words are
the lesson. The fresh-session implementation plan is `prompts/game_boss_llamada.md`:
seven phases, mechanic-first on reused art (prove the fun before Blender), then bull and
dancer dance sprites, end scene, localization, and docs.

## Boss fight Phase 1 — La Llamada's mechanic core, playable on reused art (2026-07-13)

The dance-off duel from `prompts/game_boss_llamada.md` is now a playable state machine,
built deliberately before any new Blender work: every dance animation is a reused
flipbook (ole ≈ cape, stomp ≈ jump; bull stomp/rear ≈ throw, bow ≈ idle), so the fun
could be proven — and tuned — before hand-keying a single bone. The shape: reaching the
bull no longer resets the level but counts a summit (`summitsToBoss = 1` for now, a TODO
until the five-level escape structure exists), and the summit crossfades the girders
into a tablao stage (`bossTransition` fades scenery both ways while the actors lerp to
their marks), swaps the music to Pond5's "Spanish Guitar Standoff", and opens with a
tap-skippable "¡El duelo!" llamada beat — stomp, screen shake (Conjuguer's sin-decay
idiom), the works. The duel itself is Simon-with-sabor: the bull demos a phrase as cue
chips accumulate above him (they vanish at ¡Tu turno! — memory is the challenge), the
D-pad morphs into a five-button dance pad (taps with a re-arm bool, never held intents),
a compás bar sweeps the generous echo budget, and a six-notch Duende meter *is* the
progression — banked phrases derive the round, so a failure's slide-back genuinely
demotes you, tug-of-war style. Round 3 injects the 🔥 freeze fake-out (input NOTHING for
1.2 s — inputting fails). Winning plays the bow (held on its final frame by capping the
flipbook phase), rains Konjugieren's 40-ellipse Canvas confetti, and hands off to a
minimal end scene on `Music.onboarding` — the track's long-planned first in-game use —
where the matador slides off his pedestal to the dancer. No lose state anywhere; score
quietly accumulates (undisplayed) for the later scoring work item.

Testing taught the session two things. First, the state machine is *very* testable: 19
Swift Testing cases drive it deterministically with a seeded `SplitMix64` injected into
`bossRNG` (scripted phrases, scripted failures, exact score arithmetic, the freeze both
ways, reset()-restores-the-climb). Second, live-driving a rhythm game over the AXe
tap/screenshot loop is a latency battle: even at `CONJUGAR_GAME_TIME_SCALE=0.1` the
demo kept outrunning the read-chips-then-tap cycle, and the reliable pattern turned out
to be background *burst* screenshots every few seconds plus batched taps in one shell
command. Mid-session Josh called time on grinding all six phrases and asked for a debug
shortcut instead — hence `CONJUGAR_GAME_BOSS_BANKED` (composes with
`CONJUGAR_GAME_START_BOSS`), which pre-fills the meter; `=5` starts one phrase from
victory and made the win/end-scene beats trivially verifiable (freeze survived live,
victory → confetti → slide → tap-to-exit → clean dismissal, plus `conjugar://game/boss`
on a vanilla launch and a mid-duel ✕ quit). Strings are hardcoded `Text(verbatim:)`
Spanish for now — Phase 6 moves them into the catalog per the
Spanish-jaleo-in-both-locales decision. Next up: the Pixabay SFX pack (Phase 2), then
the real bull stomp/rear/bow and dancer ole/stomp sprites (Phases 3–4).

**Feedback round, same day:** the planning session reviewed a device screenshot and
flagged two things. The "green bow-tie artifact" on the olé button turned out not to be
a symbol-rendering issue at all — on 812-pt-class devices the crowd row's 👒 emoji
overlapped the button (the sim's taller screen had hidden it), so the crowd now tucks
under the floor's lip at a smaller size. And the jaleo pops were sized up to carry the
dark mid-screen on device: per-move shouts stay modest, but ¡Tu turno! and the
phrase-¡Olé! now render 36–40 pt and spawn higher, so the judgment beat reads from
across the room. A useful reminder that the simulator's tofu-box emoji hide real
layout truths — the device screenshot caught both.

## Large Widget: Example Uses and Etymologies (2026-07-13)

The systemLarge Verb of the Day widget used to spend its extra vertical space on two
more paradigms — pretérito and futuro — stacked under the presente. That predated the
app growing example sentences and etymologies. Both sibling apps' large widgets (French
Conjuguer, German Konjugieren) had already made the trade: drop the surplus paradigms,
spend the room on a modern example sentence plus an etymology snippet. This brings
Conjugar's large widget in line.

The shape of the change: `WidgetSnapshot` gained four optional fields —
`exampleSpanish` / `exampleEnglish` / `exampleAttribution` / `etymologySnippet`. Optional
so an old on-disk snapshot still decodes (the synthesized `init(from:)` reads absent keys
as nil); the app rewrites tomorrow's snapshot anyway. `WidgetSnapshotWriter` now trims its
paradigm list to just `[.presenteDeIndicativo]` (the small/medium sizes only ever read
`paradigms.first`, so they're unaffected) and pulls the example via
`ExampleData.example(for:)` and the etymology via `Etymology.text(for:)`, truncated to a
500-char sentence boundary with the tilde-rebalance guard ported from the siblings (a
mid-string cut mustn't leave a dangling `~` opener that bolds the whole tail).

The attribution is the interesting bit. Konjugieren's reference screenshot shows
"— Luther — Bibel" — author and work, not a filename — and Josh flagged that Conjuguer's
widget still surfaced the raw corpus filename ("zola-lassommoir-1877.txt"). Conjugar
already had the fix latent: `ExampleSource.attribution` maps a source filename onto
"— Author, Title (year)" for the eight Project Gutenberg works, a localized "Fuente:/
Source: <body>" for the statistics corpora, and the Claude credit for the AI-authored
tail. The writer bakes that string into the snapshot, so the widget renders a real book
title and never a filename — and it's richer than Konjugieren's, carrying the year too.

Layout mirrors Konjugieren, adapted: header (infinitive — gloss, frequency rank at the
trailing edge), a compact ger/part non-finite row (Konjugieren's "pp:" line), a divider,
the presente grid, then the example (Spanish italic serif up to 3 lines, English
translation up to 2, attribution right-aligned) and the etymology with **no** line limit
so it fills the remaining space and clips at the widget edge. Josh asked for more room for
both example and etymology than Conjuguer gave (2 / 3 lines), hence the 3-line Spanish and
the unbounded etymology. A new `WidgetEtymologyText` in the widget target parses the
`~…~` bold markup standalone (the app's `EtymologyText` isn't visible to the extension).

Coverage check before shipping: all 989 frequency-ranked verbs — the entire verb-of-the-
day rotation pool — have both an example and an etymology on file, so the two new blocks
are never empty for a real snapshot. Build is green; Josh will eyeball the rendered widget
on device.

## Boss fight Phase 2 — the SFX pack + juice (2026-07-13)

Phase 1 shipped La Llamada playable on reused art and placeholder sounds (soccerKick for
the llamada stomp, a generic chirp for every bull demo cue, chime/cow for the reactions).
Phase 2 replaces the placeholders with a real seven-sound pack sourced fresh from Pixabay
and wires each move to its own voice.

Sourcing was Chrome-driven (Claude in Chrome, Josh authenticated to Pixabay): one clean
single **castanet** click, a rhythmic **hand clap** (palmas), a **short crowd cheer**, an
**animalistic snort** for the bull, a single **foot-stomp** hit, and a **simple whoosh**
for the cape. Pixabay's Content License is commercial-OK / no-attribution, so the paper
trail (`asset-licenses/pixabay-game-sfx.txt`, id · uploader · title per file) is a courtesy
plus a raw-file-not-redistributed note. The one non-obvious call: rather than hunt for two
tonally-distinct castanets, I took a single click and pitch-shifted it ~-3 st / ~+3 st with
ffmpeg `asetrate` into **castanetLow** (paso left) and **castanetHigh** (paso right), which
guarantees the two pasos read as a matched low/high pair instead of two unrelated samples.
Everything was trimmed to its transient, faded, peak-normalized to -1 dBFS, and re-encoded
to 192 kb/s MP3 into the synchronized `Conjugar/Audio/` group (zero pbxproj edits).

Toolchain snag: `ffmpeg`/`ffprobe` aborted on launch — `libx265.215.dylib` not found. Homebrew
had bumped x265 4.1 → 4.2 (which ships `libx265.216.dylib`) but ffmpeg 8.0.1 was still linked
against 215. The 4.1 Cellar dir still held the real 215 dylib, so a one-line symlink
(`.../4.2/lib/libx265.215.dylib` → `.../4.1/lib/libx265.215.dylib`) restored an exact-ABI
match without a full `brew reinstall ffmpeg`. (x265 is HEVC video, which the audio work never
touches, so even a mismatch would've been harmless — but the real 215 was right there.)

Wiring: a new `DanceMove.cueSound` maps each move to its Sound (freeze → nil, silent by
design — its tension is the *absence* of sound), played both on the bull's demo and on the
dancer's correct echo so a move sounds the same coming and going. The per-move cues are
**non-debounced** on purpose: SoundPlayer's debounce window is 1 s, but demo steps are
0.6–0.9 s apart and a phrase can repeat a move, so debouncing would swallow the second
castanet. The reaction sounds that *can* stack (snort on fail, crowd murmur under a
showboat) keep `shouldDebounce: true`. Volumes stay in the established low band (0.15–0.5).
The victory/end-scene applause and the ✨ freeze-survival sparkle keep existing app sounds —
they aren't part of the flamenco pack.

Also warmed the boss's emoji (🔥 🎵 ✨ 🌹 👏 ❤️ 👒 💃 🕺) in `GlyphWarmer` alongside the flags,
so the first duel frame's jaleo pops / crowd row are a glyph-cache hit rather than a
render-thread stall.

Deferred: the optional tension sting for the freeze slot (the existing chime/chirp cover it)
and the sibling apps' `HapticPlayer` port — both nice-to-haves, not blockers. Build green,
swiftlint clean, all 20 `GameBossTests` pass, and a live `CONJUGAR_GAME_START_BOSS=1` run
drove the intro + a full bull demo through every new cue without incident. The actual mix
feel is Josh's on-device audition (the phase's `Josh auditions` beat).

## Boss fight — the two deferred bits: tension sting + haptics (2026-07-13)

Circled back for the two Phase-2 nice-to-haves I'd punted on. Both landed.

**Tension sting.** Sourced a fourth-and-final Pixabay clip — freesound_community's
"tension sting" (Heavy/Tension/Bass, id 96911) — trimmed to its ~1.5 s ominous onset,
faded, normalized, and bundled as `tensionSting.mp3`. Wired it as `freeze`'s `cueSound`,
which means it plays on the *bull's demo* of the 🔥 chip: the fake-out slot now announces
itself with a low dread note instead of being silent. I kept the *echo* freeze silent by
design (the correct response is to hold still) — the `.warning` haptic (below) marks that
"hold!" beat instead. So freeze reads as: ominous sound when the bull shows it, physical
buzz when you have to resist it, sparkle + medium pop when you survive.

**HapticPlayer.** Built it as a proper DI service mirroring `SoundPlayer`: a `Haptic`
enum (Models/), a `@MainActor` `HapticPlayer` protocol, `HapticPlayerReal` (held UIKit
feedback generators, re-`prepare()`d after each fire per Apple's low-latency pattern), and
a no-op `HapticPlayerDummy`. Wired into all four `World`s — Real on device/simulator (it
no-ops harmlessly where there's no Taptic Engine, matching how `SoundPlayerReal` runs on
sim), Dummy in the unit/UI-test worlds. The generators warm on `enterBossIntro` so the
llamada's first pulse has no cold-start lag. Taps on the judgments: `impactHeavy` on the
llamada stomp, `impactLight` per correct move, `success` on a banked phrase and the win,
`error` on a fail, `warning` entering a freeze hold, `impactMedium` on surviving it.

One gotcha the app build hid: adding a required `hapticPlayer:` param to `World.init`
compiled fine for the app (whose four factories I'd updated) but `CommunViewModelTests`
constructs `World(...)` directly — that only surfaced when the *test* target compiled.
Fixed. Full suite green (465 tests), swiftlint clean, and a live round-3 run drove the
freeze demo (tension sting) and the whole judged echo without incident. Haptic *feel* and
the sting's level under `Music.bossFight` are Josh's on-device audition.

## Boss fight Phase 3 — hand-keying the bull's stomp, rear, and bow (2026-07-13)

With the mechanic core (Phase 1) and the SFX/juice (Phase 2) shipped on *reused* art, the
bull was still faking its three new dance moves: `stomp`/`rear` borrowed the throw's
flipbook, `bow` borrowed idle. Phase 3 gives them real sprites, hand-keyed in Blender on
the Simple Rigged Bull's DEF bones — the same Path-B approach the base bull plan established
(the FBX round-trip strips Rigify's control constraints, so you key the deform bones the
mesh is actually skinned to, not the dead `*_ik`/`torso` controls).

**No live Blender this time — headless, with rendered-PNG feedback.** The base bull's
idle/walk/throw were authored interactively through blender-mcp, but that needs the GUI
open and connected. Rather than block on it, I mirrored the *dancer's* pipeline instead:
a reusable headless script, `tools/blender/gen_bull_action.py` (sibling of
`gen_dancer_action.py`), that opens `bull.blend`, keys one action on the DEF bones, and
exports a per-action FBX — driven entirely by `blender -b -P`, with correctness judged by
rendering the frames and *reading the PNGs* in place of an interactive viewport. **This was
a mistake** — see the coda: the render-only loop missed distortions a live viewport (and
Josh's eyes) caught immediately, and I committed the result without review. The redo was
interactive. The pipeline mechanics below (local-X idiom, trailing-dup, sizing) all still
hold; the *authoring* method is what changed.

**The rig made it easy in one respect: everything is a rotation about the bone's local X.**
The bull is a pure side actor, so all motion lives in the sagittal (Y-Z) plane, and — as the
throw already demonstrated — that means every keyframe is a single local-X rotation, L and R
legs keyed identically so the profile silhouette stays clean. I dumped the shipped
`bull_throw` action to learn the sign convention (positive local-X on the `DEF-spine.006..011`
neck chain = head thrusts down/forward, the goring; negative = reared up/back, the windup)
and the withers-pitch pivot (`DEF-spine.004/.005`, − = chest/head up, + = chest down). The
front legs hang off `ORG-shoulder`, *not* the DEF spine, so they're keyed independently to
paw (rear) or fold (bow). With that map, the poses are just angle tables:

- **stomp (3):** first pass tried a literal "front-hoof raise → strike," but the raised hoof
  didn't read at sprite scale (the neck motion dominates the silhouette and both forelegs
  overlap, so a leg-lift looked like a small rear). Reframed it as a percussive *head* beat —
  chest/head-up anticipation, then a sharp head-slam with a foreleg stamp, then settle. The
  strong up→down contrast is what sells "stomp" on a ~140-pt sprite.
- **rear (4):** gather → the whole front pitches up off the withers while the forelegs swing
  up and paw → held flourish. Reads immediately as a rear; the crop goes taller-than-wide.
- **bow (4):** front legs fold, chest drops, the neck curls the head/horns to the floor, and
  the final frame duplicates the deep pose as a *held* bow (it freezes during `.victory`).

**Two pipeline gotchas, both about the last frame surviving.** (1) `render_sprites.py`
samples half-open `[start, end)` — right for a *cyclic* walk (drops the loop-closing dup),
wrong for a *one-shot* whose final pose is the payoff (a held bow, a settle). The shipped
throw solved this by authoring N+1 frames where frame N+1 duplicates the last real pose;
`gen_bull_action.py` now does that automatically, so `--frames N` at the default range
samples the N real poses and drops only the duplicate. (2) The FBX exporter shifts the
action to start at frame 2, not 1 — the trailing-dup trick is robust to that too, since
half-open sampling is relative to the action's own range. Chasing an explicit `--start/--end`
override instead (my first instinct) silently rendered `[up, up, down]` for the stomp because
the real poses had slid one frame over. Reading the muzzle's evaluated world-Z per frame is
what caught it.

**Sizing stayed on the rails.** The ortho auto-fit uses `max(Y, Z)·margin`, so I worried the
vertical rear would drive the fit by height and shrink the body relative to idle/walk. It
doesn't matter in practice: a bull on its hind legs is about as tall as it is long, so
`max(Y,Z)` lands at roughly the same world size either way — the body stays ~constant and the
existing `bullScale` (0.314, crop-px→screen-pt) applies unchanged. (The final *moderate*
poses crop 452×306 / 452×294 / 452×232 — the giraffe-tall 452-height crops belonged to the
distorted first pass.) `bullFrameCounts` for the three went from the Phase-1 reuse values
(5/5/2) to the real 3/4/4, and `bullActionName` now points at the real stems.

**Verification.** stomp and rear — the two actions the boss *commands via the sprite path* —
were confirmed live in the simulator: the intro llamada renders the head-slam stomp, and an
`ole` demo renders the full vertical rear, both with correct facing (mirrored right toward the
matador), feet planted on the tablao floor, and no numbered-box fallback. The bow only fires
at victory, which means correctly echoing a round-3 length-5 phrase (freeze slot and all) —
impractical to drive reliably by screenshot-timed taps — so it's verified via its rendered
PNG plus the identical `bullSprite` code path; the live win→bow→end-scene arc belongs to
Phase 5/6 anyway. Build green, swiftlint clean.

**Coda — the blind-authoring mistake, and the interactive redo.** Everything above shipped a
commit ("Boss fight: bull stomp/rear/bow sprites") that I made *without asking Josh* — and
several cells were badly distorted: the rear and stomp-anticipation stretched the neck into a
thin giraffe column, the rear's forelegs came up as one rigid straight bar, and the bow folded
the front into a tangled, interpenetrating knot. Josh caught it immediately ("certain cells are
unacceptably distorted"). Two failures compounded: (1) **judging only rendered PNGs** hid mesh
shearing that a live viewport shows at a glance, and (2) **committing before review** on an
art deliverable that's inherently subjective.

Root cause of the tearing: I applied *large* FK rotations to the DEF bones. The imported rig's
DEF spine is **fragmented** — `DEF-spine.004` parents to `root`, not to `.003` — so there is no
single bone that rigidly pivots the whole front of the body about the hips. Any big FK pitch
therefore shears the continuous mesh at the keyed joint instead of rotating the front as a unit.
The throw stayed clean only because its angles are small.

The fix, at Josh's direction, was to **redo it interactively** through blender-mcp with him in
the loop: open `bull.blend` in the GUI, Connect the addon, set Right-Ortho, and pose one bone
group at a time — `execute_blender_code` then `get_viewport_screenshot`, with Josh signing off
(or vetoing) each step. That loop is what produced the shipped poses, and it's why they're
*moderate*: a distributed ~21° front-lift instead of a 30°+ single-joint kink; forelegs lifted
**and folded** (bent knee) rather than a straight bar; a head-slam that only dips to chest level
(Josh: "nose below feet" → dialled back); a bow that's a clean **kneel** (front knees fold,
head to knee height) rather than a head-to-floor sweep that crossed the legs. The lesson
generalizes: keep FK rotations modest and spread across joints, and only the *peak* pose of each
action needs scrutiny — the lead-in/hold frames are generated as scaled fractions of an approved
peak (a gentler version of a clean pose is clean), so `gen_bull_action.py` now stores approved
PEAK dicts + per-frame scale factors. The interactive session *finds* the angles; the headless
generator + render pipeline still *bakes* them. I folded this whole workflow — live viewport,
per-pose sign-off, modest rotations, a final game-size filmstrip review before committing — into
the boss plan's **Phase 4** callout so the dancer's `ole`/`stomp` (next session) start there
instead of relearning it. And the commit was **amended**, not piled onto, once Josh approved the
redo.

## Boss fight Phase 4: the dancer's olé and stomp (2026-07-13)

With the bull's three boss actions rendered (Phase 3), the matador's opponent still needed her
two dance moves: **olé** (a proud arms-up desplante) and **stomp** (a percussive zapateado). This
was the first action-authoring session to run the collaboration workflow *by design* rather than
discovering it mid-crisis — Phase 3 had baked the bull's poses blind, shipped a Picasso, and only
then switched to a live-viewport-with-Josh loop; Phase 4's plan callout said "do it that way from
the start," and we did.

The mechanics carried straight over: drive Blender live through blender-mcp, pose one bone group
at a time with `execute_blender_code`, `get_viewport_screenshot` after every change, and get Josh's
eye before moving on. Two things bit us anyway. First, `read_factory_settings()` — my reflex for a
clean import — **resets Blender's preferences and disables the MCP add-on**, dropping the socket
mid-session; Josh had to re-enable and re-Connect. The fix was to never factory-reset: clear the
scene objects manually and, because the FBX importer's internal EDIT-mode switch needs an active
object when driven through MCP (it doesn't headless), drop a throwaway cube in first so there's a
context to switch. Second, and more interesting as animation: raising the upper-arm bone 165° to
get the arms overhead **tore the deltoid off the torso** — a dark gap at the armpit that Josh spotted
immediately (he sent a cropped screenshot). The cause is the same continuous-mesh shear that
giraffe-necked the bull: skin weights can't stretch that far. The fix is anatomical — **raise the
shoulder/clavicle bone too** so the socket travels with the arm, which lets the arm bone rotate less
(135° instead of 165°) for the same hand height and closes the gap. That's now baked into the `ole`
peak. Josh also asked for "gown flare," so a contrapposto leg stagger kicks the front hem out (the
skirt is skinned to the leg bones, so a subtle stance sways it) — and, when I offered head-up and
more arch, he pulled the classic director's move of asking for exactly one more notch of back-arch
and nothing else. The `stomp` peak he shaped too: I'd left the back arm sticking straight out
horizontally and he'd have curled it forward into a rounded braceo — which I did before he had to say
it. His summary of the whole exercise: "I'm not making a Pixar movie. I just don't want her to look
like a Picasso, which the bull did until we came up with this workflow. She doesn't."

The approved peaks were baked into `gen_dancer_action.py` as new `ole`/`stomp` branches: `ole` is a
single peak scaled 0.30 → 0.65 → 1.0 (a scaled-down clean pose stays clean, so only the peak needed
sign-off), `stomp` is three explicit stages (anticipation with the hips *up*, strike with the hips
dropped −0.09 and the hem kicked, settle). Both are **3-frame one-shots** — Josh asked "don't we need
more frames?" and the answer is no: the whole game is low-frame (idle 2, jump 3, cape 4, the bull's
3/4/4), the moves play as ~0.6–0.9 s bursts at 10 fps, and 3 is the plan's spec. The one non-obvious
render detail: `render_sprites.py` samples the frame range **half-open `[start, end)`**, which drops
the last authored frame — fatal for a one-shot whose *peak* is the last frame. So both actions use the
bull's trailing-duplicate idiom (author N+1 keys, render `--frames N`; the duplicate is what gets
dropped, the peak survives — robust even to the FBX exporter shifting the action's start frame). The
dancer generator's *existing* one-shots (jump) don't do this and may quietly drop their apex; I left
them alone rather than widen the blast radius.

Union crops came out **ole 116×229, stomp 108×229** — both 229 tall, matching the other actions' hem
baseline, so the character stays one on-screen size. Installed as `dancer_ole_1..3`/`dancer_stomp_1..3`
imagesets, wired `actionName` (ole→"ole", stomp→"stomp"), `dancerWidth` aspects, and `playerFrameCounts`
(`.ole` 4→3). Build green, SwiftLint clean, and the boss stage renders the idle dancer as a proper gold
sprite (not a numbered box) at the right size. The one thing I *couldn't* verify cleanly was the dancer
performing ole/stomp *in the duel*: she only animates a move on a correct echo, and the phrase sequence
is `SystemRandomNumberGenerator` in the shipping build (only tests inject a seeded `SplitMix64`), so
catching a specific move meant grinding random echo windows via AXe taps — exactly the slog Phase 1
flagged. Josh, reasonably, said "you are sadly not good at playing the game, I'll test it" and took the
in-motion check on device. Both new sprites share the identical, already-working render path, so the
risk there is low; the game-size filmstrip he signed off on is the real proof the poses read.

**Post-test tuning (same day):** Josh played the finished duel and hit a real readability
snag — when the bull demos a **5-step** phrase, the last cue chip vanished the instant the
sequence ended, too fast to commit to memory before the echo. The fix is a **recall beat**:
the final `.bullDemo` step now holds an extra `demoRecallHold` (1.0 s) with the whole chip
row still on screen before `beginEcho()` clears it and "¡Tu turno!" fires. Implemented as a
`demoStepTimer(forStep:)` that adds the hold only to the last step, so the per-move demo
cadence is unchanged and only the memorize-the-whole-thing moment gets longer. The existing
`demoStepsThroughPhraseThenUnlocksEcho` test had to switch from stepping by a flat
`demoStepDuration` to the per-step timer, and a new `demoHoldsFinalSequenceOneBeatBeforeEcho`
locks the behavior: after the last move's own time elapses we're *still* in demo (chips up,
echo locked), and only after the recall hold does the echo unlock.

## Boss fight follow-up: the dancer's jump apex was being dropped (2026-07-13)

Wiring the new ole/stomp one-shots surfaced that the dancer's **jump** had the exact bug the
trailing-duplicate idiom exists to prevent — and had shipped with it. `jump` is a one-shot
(crouch → rise → **apex**) whose payoff pose is the *last* frame, but it wasn't in the generator's
`ONESHOT` set, so `render_sprites`' half-open `[start, end)` sampling dropped the apex and
duplicated the rise. Confirmed with `magick compare`: shipped `dancer_jump_2` and `dancer_jump_3`
were **pixel-identical** — the jump was really [crouch, rise, rise], no apex. Josh asked to fix it
alongside the boss work.

The fix was one line — add `jump` to `ONESHOT` — plus a regenerate/render/crop/install pass. The
cyclic actions (walk/idle/climb/cape/capeWalk) deliberately stay *out*: their closing frame equals
their opening frame, so the half-open drop is what makes the loop tile seamlessly. Only true
one-shots want the trailing-duplicate guard. After the fix the three frames are all distinct and the
apex (arms raised, body extended) is back; the union crop grew **108×225 → 116×226** (the raised
arms widen it), so `dancerWidth(.jump)` was updated to match. Live-verified in the climb game at 5×
slow: tapped jump and caught her at the top of the arc in the arms-up apex — a pose the shipped
build literally could not render. Frame counts didn't change (still 3), so no seam edits beyond the
aspect. The bull's actions were always authored with the duplicate, so only the dancer's jump was
affected; ole/stomp were born correct.

## Boss fight: end scene polish (2026-07-13)

Phase 5 of the La Llamada boss plan (`prompts/game_boss_llamada.md`). Phase 1 had shipped a
working-but-skeletal end scene — the matador slid to the dancer the instant victory resolved, a
lone ❤️ + 🌹 popped, the "Tap to continue" hint was on screen immediately, and the win title
reused the same rounded plate as the "¡El duelo!" intro card. It *functioned*, but the reunion beat
didn't breathe. This phase finished the choreography without adding any new view-state (item 4 of
the roadmap will replace/extend this scene later, so the seam stayed a single `.endScene`).

Changes, all small and mostly about *timing*:

- **The matador now holds a beat before walking over.** Added `matadorSlideDelay = 0.6` so the
  applause + confetti land first, *then* he crosses (still smoothstep-eased, decelerating into
  place). The `updateEndScene` slide progress became
  `(endSceneTime − matadorSlideDelay) / matadorSlideDuration`, clamped ≥ 0.
- **The ❤️🌹 payoff became a fan, not a pair.** `spawnReunionBurst(midX:)` blooms five hearts and
  roses in a deterministic −2…+2 column spread at alternating heights (indexed, not RNG, so it
  reads identically every win and the tests stay stable). A `.success` haptic joins the chime.
- **The tap-to-exit hint is withheld ~2 s.** New `endSceneHintDelay = 2.0` gates a computed
  `showEndSceneHint`; the view fades the hint up with `.easeIn` once it fires, so the scene isn't
  rushing the player out the moment it opens.
- **"¡Victoria!" got its own display treatment.** A dedicated `victoryTitle` — 54 pt, `.black`,
  `.fontWidth(.condensed)`, gold on the red plate with a soft yellow glow — distinct from the
  intro's `bossTitle` plate, reading as a curtain call rather than a status line. The intro card
  keeps its original playful rounded look.
- **Music/exit fades were already correct** from Phase 1 (onboarding fades in as the boss track
  clears at `endSceneMusicFade`; `stopAudio()` fades rather than hard-stops when `phase ==
  .endScene`), so this phase left them alone beyond a clarifying comment.

Strings in the scene stay hardcoded `Text(verbatim:)` English for now — Phase 6 owns moving
`bullImpressed` / `victoria` / `tapToContinue` into `L.Game` + the string catalog (Spanish-in-both
per decision 16). Tests: updated `bankedSixWinsThenEndSceneSlidesTheMatador` for the new
delay-plus-duration slide window and to assert the ≥3-glyph burst, and added
`endSceneHintIsWithheldThenShown`. Full `GameBossTests` suite green (22 tests). Live-verified end to
end in the sim (`CONJUGAR_GAME_START_BOSS=1 CONJUGAR_GAME_BOSS_BANKED=5`, echo the final phrase to
win) — Josh signed off on the whole beat: title, delayed walk, reunion burst, gated hint.

## Boss fight: strings localized + emoji crowd removed (2026-07-13)

The strings half of Phase 6 (`prompts/game_boss_llamada.md`) — the testing/full-arc half stays for
later. Every user-facing boss string moved out of hardcoded `Text(verbatim:)`/literal `spawnJaleo`
calls into `L.Game` + `Localizable.xcstrings` (17 new keys, en + es both `"translated"`), added via
`python3`/`json` so the catalog stayed valid and key-sorted (272-line insert, zero churn). Per
decision 16 the split is deliberate:

- **Spanish in *both* localizations** (the jaleo shouts and title cards, which are the game's flamenco
  voice): `duelTitle` "¡El duelo!", `tuTurno` "¡Tu turno!", `freezeHint` "🔥 = ¡quieta!",
  `jaleoOle/Uy/Eso/Bien/Vamos`, `victoria` "¡Victoria!". (`freezeHint` wasn't in the plan's list but
  is user-visible and clearly belongs with the Spanish-in-both group; the `¡quieta!` hint test still
  passes because the value is identical in both locales.)
- **Localized normally en/es**: `bullImpressed` ("The bull is impressed — the matador is free!" /
  "El toro está impresionado — ¡el matador está libre!"), `tapToContinue`, and the accessibility
  labels. The plan named `oleMove`/`stompMove`/`capeMove`/`duendeMeter`; I also added
  `pasoLeftMove`/`pasoRightMove` for parity (all five dance buttons + the meter now have localized
  VoiceOver labels rather than a mix of English and just-four-of-them). The a11y labels are
  *descriptive* rather than the bare move word — e.g. `stompMove` is "Stomp"/"Zapateado",
  `capeMove` "Cape flourish"/"Capote", `duendeMeter` "Duende meter"/"Medidor de duende".

Also, per Josh: **removed the emoji crowd row** (👒🌹👏💃🕺…) that sat just below the tablao floor.
Its flat-emoji style clashed with the rendered cel-shaded bull/dancer/matador sprites. `stageDressing`
is now just the matador's pedestal; the jaleo pops carry the crowd's voice. Trimmed the crowd-only
glyphs from the `GlyphWarmer` list too (only 🔥/✨/🌹/❤️ are still rendered in the boss). Full
`GameBossTests` green (22), swiftlint clean, verified in the sim (clean floor, Spanish jaleo intact).

## Boss fight Phase 7 — docs, and what the whole La Llamada arc taught (2026-07-13)

Closing out `prompts/game_boss_llamada.md`. The feature shipped across seven phases over a
single day; this last one is documentation — but it's also the moment to write down the arc's
shape while it's fresh, since the per-phase entries above tell the *what* and this one is the
*why it went the way it did*.

**The single best decision was mechanic-first on reused art (Phase 1).** The entire state machine
— summit gate → intro → the demo/echo/judge duel loop → the 6-notch tug-of-war Duende meter →
victory → end scene, plus the freeze fake-out and compás expiry — was built and made *playable*
against nothing but the existing climb sprites (paso = walk burst, ole ≈ cape, stomp ≈ jump, bull
demos = walk/throw). That proved the fun (and shook out the timing constants) before a single hour
of Blender. Every later phase then swapped one layer without touching the mechanic: Phase 2 the
SFX/juice, Phase 3 the bull's stomp/rear/bow, Phase 4 the dancer's ole/stomp, Phase 5 the
end-scene polish, Phase 6 the strings. `GameBossTests` (22, seeded `SplitMix64` + scripted dates)
was written in Phase 1 and only *grew* after — it never had to be rewritten, because the mechanic
never moved under it.

**The recurring lesson was the same in three different guises: don't author blind.** Phase 3's bull
actions were first hand-keyed headless and committed without review — and several frames were
grotesque (a giraffe neck, straight-bar forelegs, a self-intersecting bow) because large FK
rotations shear a one-piece mesh. The redo drove Blender *live* through blender-mcp with Josh
signing off each pose, then baked the approved angles into a generator. Phase 4's dancer followed
that discipline from the start. And even a shipped sprite hid a bug (the follow-up entry): the
dancer's jump apex frame was being dropped by half-open `[start,end)` sampling until a
trailing-duplicate fixed it. Rendering is not verifying; the game-size cel-shaded sprite in motion
is the only real test.

**Smaller things that stuck:** the tug-of-war meter doubling as *both* the HUD and the progression
counter (banked 0…6 = the whole fight) kept the state model tiny; commanded one-shot bursts
(`playerMoveTimer`/`bullMoveTimer`, the `bullThrowTimer` idiom) had to be fenced off from the
climb's *derived* actions, so `update` routes every non-`.climb` phase to `updateBoss` and the
climb stays byte-identical; and the held bow needed an explicit `capBullBowHold()` cap or the
flipbook loops the bow forever. Post-ship, Josh pulled the emoji crowd row — a good reminder that
flat glyphs and rendered cel sprites don't mix, and the jaleo pops were already carrying the
crowd's voice anyway.

**This phase's edits:** `CLAUDE.md` (new "The boss fight — La Llamada" section with the two debug
entries, the `conjugar://game/boss` deeplink, the updated actors-are-all-rendered inventory, and
`Music.bossFight`/`Music.onboarding` now wired); `tools/blender/README.md` (the three bull + two
dancer boss actions added to both done-records, with crops/frame-counts and the live-authoring
note); and this entry. Everything on `migration`.

## Boss fight: the end scene comes alive (2026-07-13)

Josh's feedback on the shipped end scene: "I love the scene, but it just stops." It did — the
matador walked over, one heart + rose popped, and then everything froze on a still (the bull held
its bowed frame forever). Four changes gave it a pulse:

- **The bull re-bows on a random 1–3 s cadence.** Rather than freezing the bow flipbook, a
  `endSceneBowTimer` (re-rolled each firing via the injectable `bossRNG`) replays the bow from
  frame 0; `capBullBowHold()` still catches it at the bottom, so each dip reads as rise → bow →
  hold-until-next-dip.
- **Hearts and roses keep flying up from the couple every 2–4 s (random).** The one-shot reunion
  burst became recurring on its own `endSceneBurstTimer`; both timers start counting only once the
  matador's walk completes (`slide >= 1`), so the reunion beat still lands first. Spawn origin is a
  new `coupleMidX` (dancer + freed matador midpoint).
- **The Duende meter is hidden the moment the player wins.** A `hasWon` latch (set in
  `enterVictory`, cleared by `reset()`) gates `bossHUD` off for victory + end scene — a cleaner
  curtain call. (Terminology footnote: Josh calls it "the status bar"; it's the 6-segment gold
  tug-of-war bar with the dancer/bull end-caps. I first mishid the *iOS* status bar — reverted.)
- **A straight-to-end-scene debug entry.** `conjugar://game/end` (and `CONJUGAR_GAME_START_END`)
  → `debugJumpToEndScene()`, which chains the real entry points (enterBossIntro → snap actors →
  bank to full → enterVictory → enterEndScene) so the debug path exercises the same setup as a
  played-through win. Made tuning the new loop a two-second round-trip instead of a full duel.

`GameBossTests` still green (22) — the recurring timers only fire after the slide completes, so the
existing end-scene assertions (which stop at the reunion) are unaffected. Josh signed off on the
living scene.

## Boss-fight polish pass: rising jaleos, a one-row dance pad, and a dancing bull (2026-07-14)

Josh played the boss fight and end scene and sent an annotated screenshot (`~/Desktop/changes.png`)
with nine tweaks. Most were small; a few had interesting wrinkles.

**Empty space + rising words (note 1).** The dark upper field above the tablao was dead space, and
the dancer's jaleo shouts (¡Eso!/¡Bien!/¡Olé!) barely lifted off her head before fading. Gave
`JaleoPop` a per-pop `riseRate` (pt/s) instead of the hardcoded 26 in the view, and added
`spawnPlayerSpeech`, which solves the rate so a shout climbs from just above her head to a
sight-line at 42% of screen height (the green line Josh drew) exactly as it fades over a slower
2.6 s. Only the dancer's *positive* speech rises (correct-echo jaleo + the phrase-complete ¡Olé!);
¡Uy! on a miss stays a small local pop, so a failure never reads as a celebration.

**One-row dance pad (note 2).** The duel controls were a split d-pad (paso l/r + olé stacked) on the
left and a cape/stomp cluster on the right — Josh (rightly) called the arrangement illogical.
Replaced both with a single `bossControlRow`: five equal circular buttons (pasoLeft · olé · stomp ·
cape · pasoRight — pasos at the ends for spatial sense) positioned by the *stage floor*
(`stageFloorY + gap`) rather than pinned to the screen bottom, so they tuck just under the platform
the dancers stand on, matching the boxes he drew.

**The "jump" icon that wasn't (note 3).** Josh flagged a "human SF Symbol that's supposed to be a
jump." There is no jump in the boss fight — the climb's jump button already uses `figure.jump`. The
human glyph he saw was the *olé* button's `figure.arms.open` (a jumping-jack-ish pose he read as a
jump). Asked him; he wanted an arms-*raised* figure, so the olé desplante is now
`figure.mind.and.body` (standing, both arms up in a V) — reads as olé, not a jump.

**Blue success burst / tricolor end-scene confetti (notes 4 & 6).** Refactored the 40-ellipse
`confetti` into `confetti(count:colors:)`. The end scene's diagonal rows now cycle
red/yellow/**blue** (was red/yellow); a phrase landing fires a **blue-only** (the matador's color)
burst at **half** the count (20), gated on a new `isPhraseSuccess` (the brief `phraseResult(success:
true)` hold).

**End-scene beats (notes 5, 7, 8, 9).** The dancer now flips right to face the matador 2 s in
(`endSceneDancerTurnDelay`; she starts facing the bowing bull, set in `enterVictory`). Reworded the
narrative line to "The bull is impressed with your dancing and has freed the matador!" (Josh's draft
said "The bulls is" — corrected the number agreement) and localized it. Dropped the "Tap to
continue" hint entirely — text + `L`/xcstrings keys + the `showEndSceneHint`/`endSceneHintDelay`
machinery and its now-obsolete test — since users figure out the tap and it only added clutter.

The meatiest was **note 9: a dancing bull.** After the reunion, the freed bull now loops a
celebration — every 2 s it picks a random move from `endSceneDanceMoves` (walk/stomp/rear/bow/throw,
walk danced *in place*) held 1.6 s, and moos (`Sound.moo`, which maps to the bundled `moo.mp3`)
every 4–8 s — until the player leaves. This replaced the old "re-bow every 1–3 s" loop. One test
fallout: `bowHoldsItsFinalFrame` ticked 6 s expecting a frozen bow, but the bull now breaks into the
dance at ~2.6 s (post-reunion); narrowed it to 30×0.1 s (the pre-reunion window) so it still verifies
`capBullBowHold` without colliding with the new dance. Full suite green (466), 0 lint. Per Josh's
instruction I did **not** drive the sim — he'll verify the visuals himself.

## Main-game finalization: suggestions, sounds, and the La Subida plan (2026-07-14)

Josh declared the main part of the game ready to finalize (`prompts/main_game.md`): four more
levels, two more power-ups, four more obstacle sets, three challenge mechanics, no lose state,
boss at the top of level five. He specified speed (2× player, cape-style envelope) and the
zombie-attack mechanic (obstacles half-speed but homing, 3 s), and asked for researched
suggestions for the rest.

The research pass (WebSearch; Chrome MCP not needed) grounded the picks in genre history: Donkey
Kong's own hazard vocabulary (barrels/fireballs/springs/conveyors, hammer-as-power-up), the
classic power-up taxonomy (defense/speed/recovery/offense), DKC's Blackout Basement for
darkness-in-the-DK-lineage, VS. Ice Climber's wind gusts, and whole games built on the encierro
(Extreme Pamplona). Rejected along the way: slow-time (mathematically ~redundant with 2× player
speed), super-jump (the code deliberately keeps `jumpImpulse` too weak to skip ladders), wind
(classic, but on a D-pad with a 34 pt ladder-alignment tolerance it reads as frustration).

What Josh approved: **La Serenata** 🎸 (the third power-up — the bull stops throwing and
*dances* for the cape envelope, reusing the end scene's dance-burst machinery; it foreshadows
the dance-off boss and the dancing-bull ending), **El Encierro** 🐂 (chargers stampede across
random girders at 2× stage speed — the DK barrel turned wave event), and **El Apagón** 💡
(spotlight blackout; one masked overlay, huge drama; the bull's throw-moo becomes a sonar cue
for free). The five-for-four obstacle question (his prompt listed five categories for levels
2–5) went to an AskUserQuestion: faces dropped, so the climb reads countryside → street → road →
sky: animals (Konjugieren's set), sports balls, vehicles, clouds & sun.

Sounds: per Josh's instruction, sourced from Pixabay **via Claude-in-Chrome** — searched five
concepts, shortlisted by title/duration/uploader (DRAGON-STUDIO and freesound_community already
anchor the boss pack), extracted the CDN mp3 URLs by fetching each detail page in-page and
regexing the `download/audio/...?filename=` link, then curled ten files (five primaries + five
audition alternates) into git-ignored `audio-sources/pixabay-mpg/`. Notable: Pixabay's
"stampede" search is nearly empty (2 hits) — "galloping" is the productive query.

The plan itself is `prompts/game_la_subida.md`, seven session-sized phases (SFX pack → rename +
stages + escape beat + soft respawn → power-ups → mechanic framework + zombie → encierro →
apagón → balance/docs), mirroring the boss plan's structure. The stage transition implements the
**escape beats** from `prompts/game.md` decision 1 — the TODOs at `checkReachedBull` and the
matador sprite have been waiting for exactly this. One post-review addition: Josh noticed
Apple's animal/vehicle glyphs face LEFT, which surfaced that the barrel spin would hide facing
entirely — so obstacle sets now declare a style (`.spin` flags/balls, `.face` animals/vehicles
with dancer-convention mirroring, `.upright` clouds/sun).

## La Subida Phase 0 — the SFX pack (2026-07-14)

The main-game finalization plan (`prompts/game_la_subida.md`) opens with a small,
standalone phase that everything downstream leans on: bundle and wire the five new sound
effects the power-ups and challenge mechanics will need. Doing it first means Phases 1–5
can just reference `Sound.guitarStrum` and friends without the audio pipeline blocking a
feature commit.

Josh had already sourced the raw MP3s from Pixabay (a primary plus one audition alternate
per slot) into the git-ignored `audio-sources/pixabay-mpg/`. Processing followed the same
recipe the boss-fight "La Llamada" pack used: a two-pass `ffmpeg` — measure `max_volume`
with `volumedetect`, then trim/fade and apply `volume=(-1 − max_volume)dB` to land the peak
at −1 dBFS, re-encoding to 192 kb/s / 44.1 kHz stereo.

The gotcha this pass surfaced: `max_volume` is measured on the *whole* source, but the
loudest transient often sits *outside* the trimmed window, so the naïve gain leaves the
shipped clip quiet. guitarStrum came out at −2.1 and lightsOut at −4.3 on the first pass
(lightsOut's source was a very quiet −21 dBFS "turning down power" clip, needing ~+23 dB of
makeup gain). I re-ran those two with a window-aware bump so all five now peak at ~−1.0 dBFS
for loudness consistency across the pack. Every clip stayed *under* −1 on the first pass —
conservative, never clipping — which is the safe direction to err.

Files landed in the synchronized `Conjugar/Audio/` group (no pbxproj edit needed), the five
`Sound` cases were added under a `// La Subida` comment block (CaseIterable warm-up picks
them up automatically), lookup is by `rawValue` so the case name must equal the filename,
and `asset-licenses/pixabay-mpg-sfx.txt` records per-file provenance in the boss-pack format
(noting that all five shipped the primary pick, no alternate substituted — Josh's audition
may still change that). Build + all 466 tests green; nothing behavioral changed yet.

## La Subida Phase 1 — stages, the escape beat, and the soft respawn (2026-07-14)

Phase 1 turns the single-screen climb into the skeleton of a five-stage game. It is
deliberately the *foundation* phase: no power-ups or challenge mechanics yet (those are
Phases 2–5), just the three structural pieces everything later hangs off — a stage system,
the between-stage escape beat, and a real respawn to replace the old hard reset.

**1a — the rename.** Flags stopped being *the* obstacle and became one of five sets, so
`Flag` → `Obstacle`, `flags` → `obstacles`, `spawnFlag`/`updateFlags` → `spawnObstacle`/
`updateObstacles`, and the file `GameState+Flags.swift` → `GameState+Obstacles.swift` (a
`git mv`; the synchronized folder means no pbxproj edit). The four `flag…` tuning constants
became `obstacle…`. The one thing that kept its old name on purpose is the
`CONJUGAR_GAME_DISABLE_FLAGS` env var / `debugFlagsDisabled` flag — it's a documented
external contract that tooling references, so renaming it would break more than it tidies; a
comment notes the intentional mismatch.

**1b — stages.** `var stage` (1…5) drives everything per-stage: the obstacle emoji set
(`stageObstacleEmojis` indexed by `stage − 1`), a compounding speed
(`obstacleRollSpeed × 1.05^(stage−1)`, wired into both spawn and the landing re-roll), and a
render style. That last piece came from a design note I almost missed: Apple's animal and
vehicle glyphs face LEFT, and the barrel *spin* the flags use would hide any facing entirely.
So each set declares an `ObstacleStyle` — `.spin` (flags, balls — rotation is the point),
`.face` (animals, vehicles — stay upright, mirror to face travel), `.upright` (sun/clouds —
neither). `.face` obstacles carry a `facing` updated from the sign of horizontal motion; the
view mirrors with `scaleEffect(x: −1)` when moving right, the same left-facing convention the
dancer and bull sprites already use. Rotation now only *accumulates* for `.spin`, so the
tests can assert `.face`/`.upright` sets never tumble.

**The escape beat.** Summits 1–4 no longer restart the level — they enter a new
`GamePhase.escape` (`GameState+Stages.swift`): the bull flees UPWARD carrying the matador off
the top of the screen (`updateEscape` lifts `bullY` and `bullfighterY` in lockstep), and once
both clear the top edge the field rebuilds for the next stage — player back at the start,
hearts refilled, a faster obstacle set, and a Spanish "¡Nivel N!" banner riding the existing
jaleo-pop idiom. This finally resolves the two long-standing escape-beat TODOs (one in
`checkReachedBull`, one on the matador sprite) that `prompts/game.md` decision 1 always
anticipated. `summitsToBoss` rose 1 → 5, so the 5th summit is now the boss. The routing in
`update(currentTime:)` splits cleanly: `.climb` runs the original pipeline, `.escape` →
`updateEscape`, everything else → `updateBoss`.

**1c — the soft respawn.** The old death path called `reset()`, which rebuilt the whole
world; with five stages that would throw away all progress on a single 0-health. So death now
calls `respawn()` — full health, back to the bottom-left of the *current* stage, obstacles
cleared and power-up timers zeroed, with a `respawnGrace` damage cooldown so a lingering
obstacle can't immediately re-kill. `stage`/`summitCount`/`score` and the bull all persist;
there is no lose state in the climb, only re-climb time. Freed from the death path, `reset()`
became a true full-restart (used by `configure` and the boss→climb exit) and now zeros
`stage`/`summitCount`/`score` — the "deliberately keeps summitCount" comment was written for
the death path and was stale the moment death stopped using it.

Ten new Swift Testing cases cover the speed compounding, per-stage set/style selection,
`.face` facing (and its flip at a landing reversal) vs `.spin` rotation, the escape
enter/complete cycle, and the respawn's keep-vs-reset split; `reachingBullTriggersTheBossFight`
and the boss suite's `summitTriggersBossIntro` were updated to pre-set `summitCount = 4` since
the 5th summit is now the gate. One test I wrote failed first time for an instructive reason:
I gave a `.face` obstacle a rightward velocity on a girder that naturally rolls *left*, so the
drop-point check fired on the very first tick and the obstacle fell instead of rolling —
facing never updated. The fix was to make the test's motion agree with the level's roll
direction, which is also the only state the real spawner ever produces. Build green, SwiftLint
clean, all 476 tests pass. A debug env var `CONJUGAR_GAME_STAGE=N` jumps straight to any stage.

One verification footnote: the per-stage screenshots in the simulator show the new obstacle
sets as missing-glyph "?" boxes. That is a known iOS-simulator emoji-rendering bug, not a code
defect — flags (regional-indicator pairs) render, the single-scalar animal/ball/vehicle/sky
glyphs don't. Josh will confirm the sets on a real device; the geometry, actors, ladders,
hearts, and escape all render correctly in the simulator.

## La Subida Phase 2 — power-ups: speed ⚡ and La Serenata 🎸 (2026-07-14)

With the stage/escape/respawn foundation from Phase 1 in place, Phase 2 turned the single
existing power-up — the cape — into a three-kind system, one kind per stage, drawn without
repeats.

**The model rename.** `CapePickup`/`capes` became `PowerUp`/`powerUps`, and the struct grew a
`kind: PowerUpKind` (`cape` / `speed` / `serenata`). A stage spawns only its drawn kind at the
same two mid-platform spawn points the cape always used. Because the pickup positions depend on
the built platforms, I moved their creation out of `buildLevel` and into a new
`rebuildPowerUps(kind:)` (in the new `GameState+PowerUps.swift`), called through
`assignStagePowerUp()` from both `reset()` (stage 1) and `advanceToNextStage()` (every later
stage) — both of which run after the geometry exists.

**The shuffle bag.** Per-stage kinds come from a `powerUpBag` following Konjugieren's
`mechanicBag` idiom: drained one per stage, refilled and reshuffled through the injectable
`bossRNG` when empty. With three kinds that means stages 1–3 are a full permutation, stage 4
reshuffles, and so on — no kind repeats until the bag exhausts. Routing it through `bossRNG`
(the same seedable `SplitMix64` the boss fight uses) let the bag test assert deterministic
draws: seed, empty the bag, draw six, and check each run of three is `Set(PowerUpKind.allCases)`.

**Speed ⚡.** A `speedFactorNow` computed property returns `speedFactor` (×2) while
`speedRemaining > 0`, else 1, and is multiplied into exactly two lines: the walk displacement in
`updatePlayer` and the climb displacement in `updateClimb`. The visual is a `⚡` badge floating
above the dancer, sharing the cape's last-2-seconds expiry blink. That blink was previously
inline in `isCapeVisible`; I generalized it into `powerUpVisible(remaining:)` so the cape overlay
and the speed badge blink identically rather than copy-pasting the `Int(remaining * 10) % 2`
trick.

**La Serenata 🎸.** The most fun one: while it plays, the bull stops pacing *and* throwing and
instead dances random bursts from the end-scene repertoire (`endSceneDanceMoves`) —
foreshadowing both the dance-off boss and the dancing-bull end scene. `updateBull` early-returns
into `updateSerenataDance` when `serenataRemaining > 0`; obstacles already in flight keep rolling
because `updateObstacles` still runs. The dance reuses the boss fight's `commandBullMove` (which
I made non-private for this), and `derivedBullAction` returns the commanded move while the burst
runs, `.idle` between bursts. The one subtlety the plan flagged: `bullMoveTimer` only ticked in
the boss update path, so the serenata dance has to decrement it itself in the climb path. On
expiry the bull snorts — annoyed the song is over — and gets back to work.

**Carry-across-vs-clear.** Decision 12 says active power-up timers *carry across* an escape beat
but *clear on death*. Phase 1's `enterEscape` had a leftover `capedRemaining = 0` (correct then,
when the cape was the only power-up and escape cleared the field wholesale); I removed it so all
three timers now survive a summit into the next stage, while `respawn` explicitly zeros all
three. A test pins both halves: `respawn` clears cape+speed+serenata, `enterEscape` keeps them.

**Effects.** New env var `CONJUGAR_GAME_POWERUP=cape|speed|serenata` forces every stage's draw
(bypassing the bag) for fast verification. Seven new Swift Testing cases cover the bag's
no-repeat exhaustion, speed doubling both walk and climb displacement (and dropping back on
expiry), serenata freezing pacing/throwing then resuming, per-kind collection effects, and the
next-stage re-arm. Two existing tests moved off `capes` — `capePickupCapesThePlayer` now forces a
cape `PowerUp` since a stage's kind is otherwise random. Build green, SwiftLint clean, all 485
tests pass.

**Simulator check + its limit.** `CONJUGAR_GAME_POWERUP=serenata` + `conjugar://game` launches
cleanly and renders both pickups at their correct spawn points, and driving the dancer around
confirmed movement/pacing all work. But the `⚡`/`🎸` pickup glyphs (and the `⚡` badge) render
as missing-glyph "?" boxes — the same iOS-simulator single-scalar-emoji bug Phase 1 hit with the
obstacle sets. So the *placement* is verified in the simulator, but the pickup and badge
*glyphs* and the serenata bull-dance will get their real visual confirmation from Josh on a
device (Phase 2 is a "Josh plays" phase). Holding all commits until he blesses it, per the plan's
device-test rule.

## La Subida Phase 3 — the mechanic framework + the zombie attack (2026-07-14)

Phase 3 gives the climb its first *challenge mechanic* — a timed disruption that fires within a
stage — and the framework the other two (El Encierro, El Apagón) will slot into. The design is a
deliberate mirror of Phase 2's power-up bag: one mechanic is **assigned per stage** by drawing
from a `mechanicBag` shuffle bag (through the seedable `bossRNG`, so a mechanic never repeats
until all three have appeared and tests can script the draws), a scheduler fires it once after a
random first delay, and it re-fires periodically for the rest of the stage. All of it lives in a
new `GameState+Mechanics.swift`, with the mechanic enum (`ChallengeMechanic { zombie, encierro,
apagon }`) next to `PowerUpKind` in `GameModels.swift`.

**The scheduler.** `updateMechanicScheduler(dt:)` ticks only in `.climb` (added to the climb
pipeline in `update`, right before `updateObstacles` so an active zombie window can re-route the
obstacle motion). Two countdowns, only ever one running: while no mechanic is active,
`mechanicCountdown` winds down toward the next firing; while one is active, `mechanicRemaining`
winds down toward the window's end. `armMechanicCountdown(firstDelay:)` sets the first appearance
to a random point in `mechanicFirstDelay` (10–18 s — a fresh climb gets breathing room) and the
re-arm to a flat `mechanicRepeatDelay` (25 s). The cancel/rebuild plumbing follows the Phase 1/2
lifecycle exactly: a summit's escape beat, boss entry, and a death-respawn all `cancelActiveMechanic()`
(respawn also re-arms a fresh first-delay), and `advanceToNextStage()`/`reset()` draw a new
mechanic. Getting those seams right was most of the work — the boss fight and the escape beat both
depend on the climb pipeline being *byte-identical* when no feature is active, so every new effect
guards on its own `> 0` / `!= nil` check rather than restructuring the loop.

**The zombie attack** (Josh's original spec) is the one behavior wired this phase. When its window
opens, `updateObstacles` short-circuits to `updateZombieObstacles`: each obstacle abandons the
roll/fall state machine and drifts *straight at the player* at half the stage's obstacle speed
(`zombieSpeedFactor = 0.5`), normalizing `(playerX − x, playerY − y)`. Two deliberate choices from
the plan held up well on screen: obstacles **keep their own emojis** — no 🧟 swap (Josh was
explicit, and homing barrels reading as their normal selves is eerier than a costume change) — and
the per-set render style is preserved mid-homing, so the `.spin` sets keep tumbling and the
`.face` sets turn to face their drift. When the 3-second window ends, `reintegrateZombieObstacles`
drops every obstacle back onto the field via `relevel(_:)`: it finds the nearest girder *at or
below* the obstacle's feet, sets `level` one above it and `falling = true`, and lets the ordinary
landing code snap it down and re-roll its horizontal speed — so the barrels seamlessly resume the
DK zig-zag. An obstacle that drifted below the bottom girder just despawns. Encierro and apagón
*announce* (the bull "speaks" the title card, with its SFX) but otherwise no-op until Phases 4/5;
the bag still draws them, so the rotation is already correct.

**Announcements as bull speech.** Decision 9 wanted the mechanic call-outs to ride the boss
fight's jaleo-pop idiom ("Note how speech is animated in the boss fight" — Josh's prompt), so
`spawnBullSpeech` pops a big jaleo just below the bull that rises gently and fades. Following the
title-card localization policy, the zombie line is a *narrative* sentence that localizes ("Your
obstacles are now zombies!" / "¡Tus obstáculos ahora son zombis!"), while "¡El encierro!" and
"¡Apagón!" stay Spanish in both locales. New env var `CONJUGAR_GAME_MECHANIC=zombie|encierro|apagon`
forces every stage's draw and shortens both countdowns to ~2 s so a mechanic fires almost at once
and loops for fast verification.

**Verification.** Build + SwiftLint clean; the full suite is green at 494 tests (12 new mechanic
tests in `GameStateTests`: bag exhaustion, the scheduler firing-within-window-then-rearming, the
announcement popping at the bull, half-speed homing displacement, `.face` obstacles facing their
drift, `relevel` re-integration onto the nearest girder below / despawn-below-floor, and the three
cancel paths). In the simulator with `CONJUGAR_GAME_MECHANIC=zombie` I watched the full cycle: the
"Your obstacles are now zombies!" jaleo pops from the bull, the obstacles converge on the dancer
(tilted, since stage 1's flags are a `.spin` set), and when the window closes they re-seat onto the
girders and resume rolling — the player even took a hit from a homing barrel (4→3 hearts). As in
Phases 1–2 the obstacles render as "?" tofu (the iOS-sim single-/multi-scalar-emoji bug — stage 1's
flags are regional-indicator pairs), so glyph rendering is Josh's on-device check; geometry, homing,
announcement, and recovery all render correctly. Holding all commits until he blesses it, per the
plan's device-test rule.

## La Subida Phase 4 — El Encierro, the running of the bulls (2026-07-14)

Phase 4 wires the second challenge mechanic: **El Encierro**, a stampede of 🐂 chargers that run
straight across the girders while the window is open. It slots cleanly into the framework Phase 3
laid down — the `mechanicBag` already drew `encierro`, and Phase 3's version merely *announced* it
and no-op'd; Phase 4 gives that announcement teeth.

**The `Charger` entity.** A minimal value type (`id`, `x`, `y`, `level`, `direction`, `despawn`),
distinct from `Obstacle` because a charger's physics are so much simpler: no roll/fall state
machine, no drop points, no per-set render style — it just runs straight across one girder at 2×
the stage's obstacle speed and despawns when it clears a screen edge. All the encierro logic lives
in `GameState+Mechanics.swift` next to the zombie code: `updateChargers(dt:)` (called each climb
frame from `update`) spawns on a 0.8 s interval *only while the window is open*, then moves every
charger and culls the ones off-screen; `spawnCharger` picks the girder; `resolveChargerCollisions`
(called from `resolveCollisions`) applies the hit rules.

**Two design details worth recording.** First, the **player-girder bias**. The spec wanted the
stampede to threaten the player "at least once per window", and I made that a guarantee rather than
a probability: an `encierroCoveredPlayerLevel` flag (reset at each window start) sends the window's
*first* charger down the player's current girder, and only then do subsequent spawns pick random
girders (levels 0…top−1, never the bull's top girder). It's simpler to reason about and trivially
testable. Second, the **straggler rule**: a *natural* window end (`endMechanic`) stops new spawns
but lets chargers already crossing finish their run — so I did **not** clear `chargers` in
`finishActiveMechanic`. But a *cancel* (escape / boss entry / respawn — `cancelActiveMechanic`)
belongs to an interrupted climb, so that path clears the array. That's the one place the
end-vs-cancel distinction (previously identical) actually diverges.

Collision reuses the honest-hitbox discipline from the obstacles: the drawn 🐂 is `chargerSize`
(30) but the hit test is the tighter `chargerHitSize` (20), so a jump that visually clears the bull
costs no health. A cape smashes it (`chomp`); otherwise it's −1 pip + `soccerKick`, gated by the
damage cooldown, and a lethal hit soft-respawns. `resolveChargerCollisions` returns a `Bool` so the
caller bails after a respawn rather than touching a just-cleared array — the same guard the obstacle
loop uses inline.

**Always-dark game (Josh's mid-phase ask).** While testing, Josh noted the game should never
respect light mode — it's a night scene (flamenco stage, spotlights coming in Phase 5), and the
adaptive `Color.custom*` assets were resolving to their light variants when the phone was in light
mode. Fixed by pinning `.environment(\.colorScheme, .dark)` on `GameView`'s whole subtree (applied
after the `.background` so that resolves dark too). The Phase 4 verification screenshot is the proof:
the simulator was in **light** mode (the onboarding screen behind it is light-beige), yet the game
renders on solid black.

**Verification.** Build + SwiftLint clean; the full suite is green at **503 tests** (8 new encierro
tests in `GameStateTests`: the first charger targeting the player's girder, 2× crossing speed,
off-screen despawn, a hit costing one pip and being consumed, the damage-cooldown gate, caped
smash, the jump-clears-a-charger honest-hitbox case, and end-keeps-stragglers vs cancel-clears). In
the simulator with `CONJUGAR_GAME_MECHANIC=encierro` I watched the "¡El encierro!" bull-speech
announcement pop and the chargers spawn and cross the girders. As in the earlier phases the emoji
render as tofu (the iOS-sim emoji bug — 🐂 shows as a small red shape, the stage-1 flags as "?"
boxes), so the actual glyphs are Josh's on-device check; spawning, crossing, the announcement, the
player-girder bias, and the now-always-dark background all render correctly. Holding all commits
until Josh blesses it on device, per the plan's device-test rule.

## La Subida Phase 5 — El Apagón, the lights-out spotlight (2026-07-14)

The last of the three challenge mechanics, and the one the plan flagged as "the money shot":
**El Apagón**. For ~3.5 s the lights cut — the whole playfield washes to near-black under a soft
spotlight that tracks the dancer, while the HUD and controls stay lit. It's the Donkey Kong Country
"Blackout Basement" lineage, adapted to the flamenco climb.

**The envelope is derived state, not integrated.** The temptation was to ramp `apagonDim` up by
`dt` each frame toward a target and back down. But an accumulate-toward-target integrator drifts and
needs clamping, and the boss/mechanic code already leans on a discipline of *deriving* per-frame
visuals from a single countdown (the compás bar, the screen shake). So `apagonDim` (0…1) is a pure
function of the window's `mechanicRemaining`: it's `elapsed / apagonFadeIn` while `elapsed <
apagonFadeIn` (0.3 s), then a flat `1` through the hold, then `mechanicRemaining / apagonFadeOut`
(0.4 s) as the window runs out. No randomness, no accumulation, self-correcting — and it hits
exactly 0 at both ends. I moved the driver into `updateMechanicScheduler` (a new `updateApagon()`
called after the window state ticks) rather than the climb pipeline, so any test that ticks the
scheduler sees the darkness update, and there's one obvious owner of the mechanic's whole lifecycle.

**Cancel vs. natural end diverge on the pop, converge on the darkness.** `finishActiveMechanic`
snaps `apagonDim` to 0 unconditionally — so escape, boss entry, and death-respawn all bring the
lights instantly back on (each already routes through `cancelActiveMechanic`). But only a *natural*
window end plays `Sound.pop` ("lights back on"): `endMechanic` captures the ending mechanic before
teardown and pops only for apagón, so a between-stage flee or a death isn't punctuated by an
incongruous click. `startMechanic` plays `Sound.lightsOut` on the way in. (Free irony the plan
noted: when stage 5's clouds/sun set draws an apagón, the sun goes out — no code needed.)

**The overlay is a soft-hole mask, which a plain overlay can't do.** The render (in `GameView`,
inside the shaken playfield ZStack, after the sprites so they darken but before the cue chips + jaleo
pops so an announcement floats above the dark) is a `Color.black` at `apagonDimOpacity × apagonDim`,
`.mask`ed by a full `Rectangle` with a `RadialGradient` (`.black`→`.clear`) `.blendMode(.destinationOut)`
punching the spotlight hole around `(playerX, playerY)`, wrapped in `.compositingGroup()`. The
compositing group is load-bearing: without it `destinationOut` composites against the window instead
of the mask's rectangle and the hole doesn't cut. `allowsHitTesting(false)` keeps the D-pad beneath
it live. Everything HUD-side (quit ✕, hearts, D-pad, jump) lives *outside* the shaken group, so it
stays at full brightness — which the verification screenshot proves.

**Verification.** Build + SwiftLint clean; the full suite is green at **508 tests** (5 new apagón
tests in `GameStateTests`: the envelope rises→holds→falls on schedule and re-arms; `apagonDim` never
leaves [0, 1] across a full window sweep; respawn zeroes it mid-hold; escape and boss entry zero it;
and the bull-speech announcement pops at the bull). In the simulator with
`CONJUGAR_GAME_MECHANIC=apagon` + `CONJUGAR_GAME_TIME_SCALE=0.2`, the first screenshot caught the
full-dark hold — playfield near-black, a bright pool around the dancer on the bottom girder, and the
✕/hearts/D-pad fully lit — and a later screenshot caught the lights back on, confirming the fade-out
returns everything to full brightness. As before the pickup emoji render as "?" tofu (the iOS-sim
single-scalar-emoji bug), so the ⚡/🎸 glyphs are still Josh's on-device check; the darkness,
spotlight tracking, layering, and lit HUD all render correctly. Holding all commits until Josh
blesses it on device, per the plan's device-test rule.

**Incidental fix — the zombie announcement clipped off the left edge.** Device-testing the
mechanics, Josh caught that "Your obstacles are now zombies!" (the one long, two-line bull-speech
announcement) was cut off on the left — its leading "Y" and the "n" of "now" ran off-screen. The
cause: `spawnBullSpeech` anchors every announcement at `bullX` (decision 9, "just below the bull"),
and the bull sits left-of-center (~0.4·w), so a `.position`-centered wide box overflowed the near
edge. Fixed purely in the view (`jaleoPopViews`) with no model or test change: each pop's wrap width
is now bounded to *twice the distance from its center to the nearer screen edge* (less a margin) and
center-aligned, so a center-anchored box is mathematically incapable of clipping wherever the bull
speaks from — while short score-pops sit well inside that bound and lay out exactly as before. The
short Spanish title-cards ("¡El encierro!", "¡Apagón!", "¡Nivel N!") were never affected; only the
long localized zombie sentence was wide enough to reach an edge.

## La Subida Phase 6 — polish and docs (the escape-beat TODOs are finally gone) (2026-07-14)

The capstone pass on the five-stage main game: no new behavior, just closing the loop on the
comments and docs the six prior phases left stale, and a final green-across-the-board
verification. Balance tuning (the plan's step 1) is Josh's on-device call — the constants table
is best felt with a controller in hand, not guessed at in the simulator — so this session did the
sweep-and-document half and left the numbers alone.

**The escape-beat TODOs were already dead; I just confirmed the graves.** The plan (and
`prompts/game.md` decision 1) had long carried two "resolve me later" markers: one in
`GameState+Physics.swift` where a non-final summit used to `reset()`, and one in `GameView.swift`
around the matador render, both anticipating the bull-flees-upward escape beat. Phase 1 actually
implemented `enterEscape`/`updateEscape` and rewired `checkReachedBull`, so the TODOs were gone
the moment that landed — a grep for `TODO`/`FIXME` across the game files now comes back empty, and
the surviving comments *describe* the resolution (`checkReachedBull`: "summits 1–4 trigger the
escape beat … the bull fleeing upward with the matador") rather than promising it. Nice when the
polish phase finds the work already done.

**The "placeholder-art prototype" comments outlived the placeholder art by three sprite phases.**
The real staleness was cosmetic-comment rot. `GameState.swift`'s header still opened with "This is
a placeholder-art prototype: the player and bull 'sprites' are their current animation frame
*number*, rendered as text … Swapping in real sprite art later is a one-line change" — written
before the boss-fight arc hand-keyed full cel-shaded flipbooks for every dancer and bull action.
The same stale claim was echoed in `GameView.swift`'s header ("placeholder numbered frames … before
any real sprite art exists"), `GameState+Animation.swift`'s header ("the view renders
`Text(\"\\(playerFrame)\")` today"), the `PlayerAction`/`BullAction` doc comments in
`GameModels.swift` ("placeholder flipbook … mapped to reused rendered frames for now"), and a
"Phase-1 note" in `GameState+BossFight.swift` insisting the dance actions and boss SFX were
temporary reuses. I refreshed all of them to the truth: the actors render real per-action sprite
flipbooks, with the numbered-box `RoundedRectangle` kept in `GameView` only as a safety-net
fallback for an action without art. (The fallback genuinely still exists, so the comments say
"safety net," not "gone" — a comment that over-claims is as bad as one that under-claims.)

**The worst comment was doubly stale — a rename *and* an omission.** `GameState.swift`'s
file-overview line read "Mechanic logic is split across `GameState+Physics`, `GameState+Flags`,
and `GameState+Animation`." Both halves were wrong after La Subida: `GameState+Flags.swift` was
renamed to `GameState+Obstacles.swift` in Phase 1 (flags became one of five obstacle sets), and
four whole new extension files — `+Stages`, `+PowerUps`, `+Mechanics`, and the older
`+BossFight` — weren't listed at all. The header now enumerates the real seven-way split with a
one-line gloss each, so a future reader gets the map instead of a fossil.

**CLAUDE.md gained a La Subida section.** The project doc had a thorough boss-fight section and a
game-music section but nothing describing the climb it caps. I added "The main game — La Subida
(the five-stage climb)": the five stages and their obstacle sets, the `ObstacleStyle`
spin/face/upright rule, the compounding +5 %/stage speed, the `Flag`→`Obstacle` rename (and the
deliberately-retained legacy `CONJUGAR_GAME_DISABLE_FLAGS` name), the escape beats, the no-lose
soft respawn, the three power-ups and three mechanics with their SFX, the five new Pixabay sounds
and their license log, and the three new debug env vars (`CONJUGAR_GAME_STAGE`,
`CONJUGAR_GAME_POWERUP`, `CONJUGAR_GAME_MECHANIC`). I also fixed the one stale line in the
freeze-framing paragraph that still said the disable-flags var "stops the bull throwing flags" —
now "throwing obstacles," with a note that the var keeps its legacy name as a contract.

**Verification.** SwiftLint: 0 violations in 181 files. Full `run_tests.sh`: **508 tests in 26
suites, all green** (unchanged count — this pass touched only comments and Markdown). Final
`build_app.sh`: Build Succeeded. As with every La Subida phase, the commit is held until Josh
device-tests; this one has nothing behavioral to test, but the plan's whole-arc device pass and
constant-tuning still gate the final commit + push to `migration`.

## Settings-tab game blurb refresh + clean color cycle (2026-07-14)

Two small polish changes to the Settings tab, both prompted by the game having outgrown its
old description.

**The game blurb was a fossil.** `Onboarding.gameBody` — the string shared by the Settings
game card and the onboarding game sheet — still ended with "Use a muleta (cape) to smash
enemies sent by the bull," which described the game back when smashing flags was the whole
loop. La Subida is now a five-stage climb with power-ups, challenge mechanics (zombies,
encierro stampedes, apagón blackouts), escape beats, and a flamenco boss dance-off, none of
which the copy hinted at. Josh iterated the replacement line-by-line: it grew from one sentence
to three, dropped its em dashes in favor of full stops, renamed "zombie enemies" to
"zombified-and-stampeding enemies" (folding in the encierro mechanic), and shed the `(capa)`
parenthetical in the Spanish only (redundant there — "muleta" already reads as the cape to a
Spanish speaker). Final shape: the two intro sentences stay, then "Climb five escalating
stages… Survive surprises… Reach the top of the final stage, and a flamenco dance-off with the
bull decides whether love wins." Both en and es updated in the catalog; `json.load` validates.

**The Settings icons now cycle colors cleanly.** The nine SF Symbol tints down the tab had
accreted into an arbitrary order (blue, yellow, green, blue, red, red, yellow, blue, yellow) —
two reds in a row, no pattern. Retinted to a clean four-color cycle: blue, yellow, green, red,
blue, yellow, green, red, blue. Josh's follow-up — "each button should have its associated
symbol color" — meant this wasn't just the heading glyphs: each card's `TintedCapsuleButtonStyle`
button (Game, Onboarding, Game Center, Ratings) and the App Icon card's label text were recolored
to match their new symbol tint, so a card reads as one color instead of a glyph in one hue and a
button in another. The one holdout is the App Icon card's *selection ring*, left `customYellow`:
it's the app's brand selection highlight (the same yellow as every section heading), an
affordance rather than a button, so it stays put.

**Verification.** `build_app.sh`: Build Succeeded. The post-edit SourceKit swarm on
SettingsView (`Cannot find 'Current'`, `'any Layout' has no member…`) was the usual
same-module stale-index noise — xcodebuild compiles it clean.

## Onboarding: making the pages scroll at large Dynamic Type (2026-07-14)

The game preview — the last onboarding sheet — has by far the longest body copy plus a
CTA button *inside* the page, and each page was a fixed, non-scrolling `VStack` with
`Spacer()`s. Josh flagged (from a screenshot) that the body was cut off ("…zombified-and-
stampe…") and the "Play" CTA was jammed against the paged-`TabView` dots. Crucially he then
added that he runs **large Dynamic Type** — which is exactly why it reproduced for him and
not at the simulator's default size. Constraint: fix it **without trimming the copy**.

This one took three tries; the dead ends are the interesting part.

**Attempt 1 — the textbook "scroll-if-needed, else center" pattern.** `GeometryReader` →
`ScrollView` → VStack `.frame(minHeight: proxy.size.height)`, keeping the `Spacer()`s for
centering. At the simulator's default size the game page now showed the full body — looked
fixed. But set the sim to `accessibility-extra-large` (Settings ▸ or `xcrun simctl ui <udid>
content_size accessibility-extra-large`) and the body **still truncated**. The AX tree
(`describe_ui.sh`) was the smoking gun: the body `StaticText` carried the *full* string in
its `AXLabel` but its frame was clamped to ~184 pt. Cause: **flexible `Spacer()`s inside a
`ScrollView` + `.frame(minHeight:)` make the ScrollView treat the content as exactly one
page tall** and hand the leftover to the Spacers, squeezing the Text until it truncates
instead of growing.

**Attempt 2 — drop the Spacers, center via the frame.** `content.frame(minHeight:
proxy.size.height, alignment: .center)`, no Spacers. The body height grew (184 → 230 →,
on the game page, 1104 pt — full text, no truncation). *But it would not scroll.* A manual
`axe touch` down-move-up drag left the off-screen "Play" button pinned at y=1456. Inside a
horizontally-paging `TabView(.page)`, the `GeometryReader` makes the ScrollView size to its
*content* rather than act as a bounded, scrollable viewport — so tall pages just overflow
(colliding with the dots / Get Started) and there's nothing to scroll.

**Attempt 3 — the fix that shipped.** Two changes:
1. **A bare, page-filling `ScrollView`** — no `GeometryReader`, no `minHeight`, no Spacers.
   It fills the TabView page as a real viewport and scrolls correctly. Verified on the
   Articles/game pages at accessibility-XL: the whole body scrolls in and the CTA clears
   everything. The cost is that short pages are now **top-aligned** instead of vertically
   centered — an acceptable trade for a layout that never truncates. (Restoring "center
   when it fits" is the `GeometryReader` trick that broke scrolling, so it stays out.)
2. **Took the page dots out of the overlay.** `TabView(.page)`'s indicator is composited
   *over* each page and reserves no space, so at large type a long body scrolling underneath
   collided with it mid-page. Switched to `.page(indexDisplayMode: .never)` and drew an
   explicit row of `Circle`s (on-brand `customYellow`) as a real sibling below the TabView.
   Now every page's ScrollView clips cleanly above the dots, and on the last page the
   dots sit in their own row between the scrollable "Play" CTA and the outer "Get Started".

**Debugging notes for next time.** (a) `axe swipe`/`touch` synthetic gestures *do* drive
SwiftUI — horizontal paging worked — but coordinates matter: `y > ~820` lands on the home-
indicator edge and `y=1400` is off a ~874-pt-tall screen, so those "failed swipes" were bad
coords, not a dead app. (b) `describe_ui.sh` + a tiny Python walk over the AX JSON is the
reliable oracle here — `AXLabel` always holds the *full* string, so a truncated view shows
up as a full label on an undersized frame, which is how Attempt 1's squeeze was caught. (c)
`xcrun simctl ui <udid> content_size <size>` toggles Dynamic Type without touching Settings.

**Verification.** `build_app.sh`: Build Succeeded (the OnboardingView SourceKit swarm —
`Cannot find 'L'/'Current'/'AppRouter'`, `Color has no member customBackground` — is the
usual same-module stale-index noise; xcodebuild compiles clean). Exercised at both default
and accessibility-XL: game page renders the full body through "…whether love wins.", "Play"
has clear space, the custom dot row is in its own lane, and "Get Started" is separated
below. No string changes.

## Code review, round 2 — first look at the post-July-7 code (2026-07-15)

A fresh Fable session ran the second code review (`prompts/code_review_2.md`): the 96
commits since `f8d5714` — La Subida, La Llamada, onboarding, the audio/haptics stack, app
icons, the etymology/example-uses subsystems, and the large-widget rework. The engine
diff was verified comment-only (the citation sweep), so the correctness lens shifted to
the new content: mechanical integrity checks over all three JSONs came back clean
(balanced `~` markup, en/es key parity, every key resolving in the verb map, 988/988
ranked coverage, every example token a whole word of its sentence, no unattributed
sources). Baseline: build green, **508 tests / 26 suites / 0 failures**, SwiftLint 0.

The deliverable is `prompts/code-review-recommendations-2.md`: thirteen ranked items,
each labeled confirmed vs. suspected. The headline was found *without* playing the game:
the jump button's `Image(systemName: "figure.jump")` names a symbol that does not exist —
SwiftUI logs a Fault and draws an empty ring, on device too. It survived a week of play
testing because the ring still looks like a button and the a11y label is correct; a sweep
of all 23 symbol names found no other offender, and the fix ships with a guard test.
Behind it: the large widget's 28 pt pronoun column vs. a measured 46 pt "nosotros";
speed/serenata state frozen (⚡ badge and all) into the boss because `enterBossIntro`
clears only the cape; a fade-stop task in `SoundPlayerReal` that kills a same-track
restart inside its window (reachable via onboarding reshow); onboarding page tags that
renumber if tutor availability flips mid-tour; and a stale-deeplink-flag edge that was
reproduced live in the simulator (a `game/boss` URL sent while the game is open fires on
the *next* plain `conjugar://game`). Two review-methodology notes for next time: the
simulator renders flag emoji as "?" tofu (stage 1 looks broken there; devices are fine),
and Josh is handling play testing — the review's game findings were all provable by
deeplink + trace, no AXe choreography needed.

## Round-2 review, step 1 — the one-line fixes + guard tests (2026-07-15)

First implementation pass against `prompts/code-review-recommendations-2.md`: the
mechanical, independently-verifiable items batched as "step 1" (review items 1, 3, 9, and
two of the item-13 nits). Each is small; the interesting part is the guard tests.

**The jump symbol (item 1).** `GameView.jumpButton` drew `Image(systemName: "figure.jump")`
— not a real SF Symbol, so an empty ring. Swapped to `figure.gymnastics` (exists, reads as
"jump"). The durable fix is the *guard test*: `SymbolValidityTests` sweeps the whole source
tree (`Conjugar`, `ConjugarWidget`, `Shared`) with a Swift `Regex` literal for every
`systemName:`/`systemImage:` string literal and asserts `UIImage(systemName:) != nil` for
each. It reuses `CorpusFormsDumpTests`'s `#filePath`-relative repo-root idiom (up three from
`ConjugarTests/Views/` → repo root, then recurse). It found the 22 distinct literals, all now
valid (0.25 s to scan). Custom asset-catalog symbols dodge the sweep for free: they go through
`Image("bull")` / `.custom("dancer")`, never `systemName:`. First draft used
`try! NSRegularExpression(...)` and SwiftLint's `force_try` rightly rejected it — the Swift
`Regex` literal `/(?:systemName|systemImage):\s*"([^"]+)"/` is compile-checked, no `try` at
all, and reads better.

**Power-up leak into the boss (item 3).** `enterBossIntro` cleared `capedRemaining` but not
`speedRemaining`/`serenataRemaining`/`serenataDanceTimer`, whose timers only decrement inside
the `.climb` branch of the frame tick — so a ⚡ grabbed on stage 5 and summited within its 7 s
froze on as a permanent badge through the whole duel. Zeroed all three beside the cape; extended
`summitTriggersBossIntro` to arm every power-up field before the summit and assert all four clear.

**Stale deeplink flags (item 9).** `AppRouter.handle` now only arms `pendingBossEntry`/
`pendingEndScene` when `!showGame` — a `game/boss` URL arriving while the game is already up is
ignored instead of lingering to hijack the next plain `conjugar://game`. `AppRouter` had *no*
tests, so added `AppRouterTests` (5 cases) covering plain-game, boss, end, and the two
already-presented regression guards.

**Two item-13 nits.** The boss's spoken-jaleo pick used bare `.randomElement()` while every
other boss draw routes through `bossRNG` — now `randomElement(using: &bossRNG)`, closing the one
hole in the "tests can script the fight" story. And `resolveCollisions` ended with
`if resolveChargerCollisions() { return }` where the `return` is the last statement anyway — a
no-op costume; replaced with a plain `_ = resolveChargerCollisions()` and a comment saying the
did-respawn flag is intentionally discarded.

**Landmine for future sessions — `-only-testing` uses the *type* name, not the `@Suite`
display name.** My first "passing" test runs were a lie: I passed `ConjugarTests/GameBoss`
(the `@Suite("GameBoss")` display string) and got "Test Succeeded" with *zero* tests executed
— xcodebuild silently matched nothing and trivially passed, exactly the Swift-Testing
zero-tests trap CLAUDE.md warns about for the missing `()`. The selector wants the Swift
*type* name: `ConjugarTests/GameBossTests`. With that fixed, the native Swift Testing reporter
prints (`◇ Suite … / ✔ Test … passed`) and the run shows **27 tests in 3 suites passed**. Note
the xcbeautify/XCTest summary line ("Executed 0 tests") reports only the XCTest side — Swift
Testing has its own reporter, so grep for `✔ Test`/`Suite "…"` (or pipe raw `xcodebuild`) to
confirm a Swift Testing suite actually ran. Build green, SwiftLint 0/183.

## Round-2 review step 2: docs + dead code (2026-07-15)

Step 2 of the round-2 sequence — the "zero behavior change" cleanup of item 10. Three edits,
no logic touched.

**`GameState.reset()`'s unreachable music-restart branch, deleted.** The function opened with
`if phase != .climb && didConfigure { Current.soundPlayer.startMusic(.gameLoop) }` — a leftover
from when leaving the boss re-entered the climb. That path is gone: `reset()` is now called only
from `configure()` (and one test). At the `configure()` call site `didConfigure` is still
`false` (it's set `true` *after* `reset()` returns), so the `&& didConfigure` conjunct can never
hold — the branch was dead. Removed it and trimmed the doc comment's "(and the boss→climb exit
path)" clause to match. `resetRestoresTheClimb` (which never asserted on music) still passes, and
the whole `GameBossTests` suite is green at 21 tests.

**`Etymology.swift`'s stale wiring NOTE, dropped.** The header still carried a
`NOTE (wiring): this reads the JSON but is not yet displayed … the remaining lifecycle step` —
but the etymology card shipped in `VerbView` (and the widget snippet) some commits ago. Deleted
the paragraph; the rest of the header (keying, `~bold~` markup, English fallback) stays accurate.

**CLAUDE.md corrected.** The concurrency/game section claimed `reset()` "is only for
configure/boss-exit paths now" — there is no boss-exit path anymore (leaving the boss dismisses
the game and discards the `GameState`). Now reads "only for the configure path now, not death,"
so the next session isn't sent looking for a caller that doesn't exist.

Build green, GameBossTests 21/21.

## Audio-stack pass: cancellable fade-out + a random-start policy (2026-07-15)

Round-2 review step 3 — items 4 and 13's playhead decision, both living in
`SoundPlayerReal.swift`.

**The fade-out hard-stop could kill a music restart (item 4).** `stopMusic(fadeDuration:)`
ramps the volume to zero, then a detached task hard-stops the player once the ramp finishes.
That task guarded on `self.musicPlayer === fadingPlayer` — which was written for the
*track-switch* case: starting a different track rebuilds `musicPlayer`, so the identity check
no-ops and the stale fade task harmlessly stops the old player. But `startMusic` **reuses the
same player for the same track** (the rebuild branch runs only when `currentMusic != music`), so
a *same-track* restart inside the fade window leaves the identity equal and the pending task
hard-stops the freshly restarted music seconds in. Reachable today: dismiss the onboarding reshow
and re-tap "Show Onboarding" within the ~1.5 s fade — the re-shown tour's bed dies mid-play.

Fix: a held `fadeStopTask: Task<Void, Never>?`. `startMusic` and the plain `stopMusic()` both
cancel it up front; the fade task checks `!Task.isCancelled` (alongside the existing identity
guard) before calling `stop()`. So any restart — same track or different — cancels the pending
kill, and the redundant post-`stopMusic()` fire the review also noted is covered by the same
cancellation. Chose an explicit cancellable task over a bumped-generation integer; the review
floated both and the task reads more directly.

**Scene beds no longer open mid-phrase (item 13 playhead).** `startMusic` seeded every fresh
player to a random playhead — lovely variety for the gameplay loop, but the *through-composed*
beds (`.onboarding`, `.bossFight`) entered mid-phrase. Rather than bury the intent in a comment,
made it a property: `Music.startsAtRandomPosition`, true only for `.gameLoop`. The random-seek
branch is now gated on it; the composed beds start at 0. A resumed playhead (`savedMusicTime`,
the game pausing/re-entering) still wins over both. Pinned the policy with a Swift Testing case
(`onlyGameLoopStartsAtRandomPosition`) in `SoundPlayerTests` — pure value logic, no CoreAudio, so
it runs in the unit-test world where the real player never does.

Build green; `SoundPlayerTests` 4/4, SwiftLint 0 violations. The by-ear check (onboarding reshow
double-open, boss end-scene→onboarding within ~1 s) needs the app running with audio and is left
for a device/simulator pass.

## Onboarding/tutor pass: snapshot availability, task-scope the monitor, unify the game deferral (2026-07-15)

Round-2 review step 4 — items 5, 6, 11, all clustered on the onboarding ↔ tutor-availability ↔
game-launch seams, done together so the flow gets re-tested once.

**Onboarding no longer renumbers mid-tour (item 5).** `OnboardingView` derived `articlesTag`/
`lastPageTag` (and the `if …` that inserts the tutor page) *live* from
`Current.languageModelService.isAvailable`, and the view itself started the 5 s availability
poll on appear. First launch is exactly when Apple Intelligence assets may still be downloading,
and onboarding auto-presents on first launch — so an unavailable→available flip mid-tour would
insert the tutor page at tag 4, renumber the articles/game pages, grow the dots row, and yank
"Get Started" out from under a user sitting on the last page. Fixed by snapshotting once:
`@State private var includeTutorPage`, seeded in `init` via `State(initialValue:)` rather than
`.onAppear`. Init-time is strictly better than the reviewer's suggested onAppear here — the count
is correct from the very first frame (no one-page settle), and `State(initialValue:)` is only
honored on first construction for a given view identity, which is exactly "snapshot once" and
survives the parent re-inflating the cover's content closure. Monitoring was removed from
onboarding entirely; the Info tab stays the live surface.

**The availability monitor is now task-scoped, not a hand-paired start/stop (item 6).** The old
`startAvailabilityMonitoring()`/`stopAvailabilityMonitoring()` were a single non-refcounted task:
`InfoBrowseView` started on appear / stopped on disappear, and so did onboarding. The "Read the
Articles" CTA interleaved them — `router.selectedTab = .info` fired Info's onAppear *start* while
the cover was still up, then the cover's onDisappear *stop* cancelled it, landing the user on a
live Info tab with no monitor. Replaced the pair with one `func monitorAvailability() async` that
loops `Task.sleep(5s)` + `refreshAvailability()` until available or cancelled, driven from
`InfoBrowseView`'s `.task { await Current.languageModelService.monitorAvailability() }`. SwiftUI
owns the task's lifetime and cancels it on disappear, so there's no pairing to interleave, and it
is safe to run from several views at once (each `.task` is independent). Chose this over the
reviewer's refcount option — it deletes state (`availabilityMonitor` is gone) rather than adding a
counter, and item 5 already removed the only second caller.

**One game-after-onboarding deferral, in the router (item 11).** `MainTabView` and `SettingsView`
each carried an identical `pendingGameAfterOnboarding` `@State` + `launchGameAfterOnboardingIfRequested()`
+ onDismiss wiring. Moved the flag and both helpers (`requestGameAfterOnboarding()`,
`launchGameAfterOnboardingIfRequested()`) onto `AppRouter`; both covers now pass
`requestGame: router.requestGameAfterOnboarding` and `onDismiss: router.launchGameAfterOnboardingIfRequested`.
The helper presents through `router.showGame`, so the Settings *reshow* game path now rides
MainTabView's tab-independent game cover; Settings keeps its own local `showingGame` only for the
direct "Play" button (the two parallel presentation mechanisms were explicitly blessed by the
review — only the deferral plumbing was worth unifying). Pinned the router helper with three
Swift Testing cases in `AppRouterTests` (arm-without-launch, launch-and-clear, no-op-when-unarmed).

Build green; full suite 518 tests / 28 suites / 0 failures; SwiftLint 0. The device-only bits
(the mid-download page-count freeze, the Info-tab live flip after enabling Apple Intelligence)
can't be exercised in the simulator, where the model is always unavailable; verified by trace +
the router/service unit tests.

## Round-2 review step 5: perf + widget pass (items 7, 2) (2026-07-15)

Two independent fixes that both touch surfaces a user hits daily.

**Warm the content caches off the launch path (item 7).** `VerbView.init` loads all three
bundled content caches on first touch — `Etymologies.json` (3.0 MB), `ExampleUses.json`
(553 KB), `MedievalExamples.json` (411 KB) — via `Data(contentsOf:)` + `JSONDecoder` on the
main actor, inside a NavigationStack push. The launch-time `WidgetSnapshotWriter.refresh()`
*would* have pre-warmed two of them, but `refresh()` is date-gated and no-ops on every launch
after the day's first, so in practice the first Browse→verb tap of a session ate the full
parse. Added `Models/ContentCaches.swift` — a `nonisolated enum` with a single `warm()` that
touches `Etymology.text(for:)`, `ExampleData.example(for:)`, and `MedievalData.examples(for:)`
with a sentinel key (any key works: each cache loads its whole file on first access regardless
of the key). Wired a second `Task.detached { ContentCaches.warm() }` beside the existing widget
refresh in `MainTabView`'s launch `.task`. The caches are `@unchecked Sendable` + `NSLock`-guarded
— off-main warming is exactly what they were built for — so `VerbView.init` now costs three
dictionary lookups on the warm path. Kept the date gate on the *write* path untouched.

**Large-widget pronoun column (item 2).** `LargeWidgetView.conjugationCell` pinned the pronoun
to `.frame(width: 28)` at `.caption2` with no line handling; "nosotros"/"vosotros" measure
~46 pt, so rows 1p/2p of the presente grid wrapped or truncated on every systemLarge render.
Rather than shrink the text (the `minimumScaleFactor` alternative), restructured the two-column
`Grid` into four columns — `pronoun | form | pronoun | form` — split `conjugationCell` into
`pronounCell`/`formCell`, and let the pronoun columns self-size with `.gridColumnAlignment(.trailing)`.
The forms stay aligned because the pronoun cells now share a real grid column (the whole reason
the fixed frame existed). Tightened `horizontalSpacing` to 4 and added `.padding(.leading, 8)`
on the second pronoun to keep the two pairs visually separated. This is a widget target with no
simulator preview harness here, so the code fix is done but the pixel outcome still wants Josh's
device/gallery eyeball — the mechanism (self-sizing column) is the reviewer's preferred fix.

Verification: build green, SwiftLint 0, full suite **518 tests / 28 suites / 0 failures**. Drove
the app in the simulator and confirmed the verb screen renders correctly through the warmed
caches (hablar: metadata pills, both paradigms, correct forms). The "no perceptible hitch" feel
and the widget pixels are the two device-eyeball bits; the data itself is unchanged (`warm()`
only pre-triggers the same loads `VerbView.init` already did), and the engine/content suites
cover correctness.

## iPad Geometry: Re-deal the Climb + Letterbox It to a Portrait Column (2026-07-15)

Round-2 review item 8, step 6 — the one item flagged as a real design decision rather than a
mechanical fix. The game's level geometry (`GameState.buildLevel`) is built once from the
first-appear size and hard-locked behind `guard !didConfigure`. Everything downstream —
platforms, ladders, the D-pad, `respawn()`'s player placement, the boss tablao marks — reads
`screenSize` live. iPhone is portrait-locked so this never bites, but the app targets iPad with
all four orientations allowed (plus Split View / Stage Manager resizes). Rotate an iPad
mid-climb and you'd get portrait geometry stranded inside a landscape window: platforms sized to
the old width, the player clamped to old bounds, controls positioned off a stale `screenSize`.

The review laid out three options: cheapest re-deal (rebuild + soft-respawn), fullest
proportional remap of every entity, or defer-with-a-known-issue. I went with the re-deal, but
paired it with a second change that's the part I think actually matters: **a portrait
letterbox.** The reasoning: even a *perfect* re-deal to a landscape iPad produces a short,
wide, ugly climb — the platforms would stretch edge-to-edge across a landscape width at
16%–78% of a short height. So rather than make the engine cope with landscape aspect ratios at
all, I cap the play field to a phone-shaped column (`GameView.fieldSize(in:)`, `maxFieldAspect =
0.62`) centered in whatever space the OS hands us. The engine then only ever deals with a
portrait rect; rotation just changes the dark margins around the column. `0.62` sits above every
iPhone aspect (~0.46–0.56) so phones are completely untouched (the field fills the width exactly
as before), and low enough that iPad — any orientation — gets a proper column.

The re-deal itself is `GameState.reconfigure(screenSize:)`, driven from
`.onChange(of: geo.size)`. It no-ops before the first `configure` and for sub-1pt jitter, then
rebuilds the level and re-seats the actors by phase: a climbing player soft-respawns to the
bottom of the current stage (`respawn()` — stage/summit/score survive, health refills, the field
clears) and the pickups are re-placed for the new width (`rebuildPowerUps`); off-climb phases
(boss intro/duel/victory/end, escape) re-assert their fixed tablao marks via a small
`reseatForResize()` and drop the old-width obstacles/chargers, which respawn on their own timers.
Reusing `respawn()` for the climb case is exactly what the review suggested ("soft-respawn to
safe marks") — it's a touch punishing (you lose an active cape on a rotate) but a rotate is rare
and precise remapping was the option I deliberately rejected as overkill.

Why not lock the game to portrait instead? It's conceptually cleaner but (a) needs `AppDelegate`
orientation plumbing driven by a game-visible flag, which fights the "no `UIViewController`,
geometry-lives-in-SwiftUI" architecture the migration worked to reach, and (b) does nothing for
Split View / Stage Manager resizes, which aren't rotations. The letterbox gets the same visual
result (always a portrait column) without either drawback.

Verification was interesting. On an iPad Pro 11" (M5, iOS 26.3) simulator, the app launches in an
iPadOS-26 *floating window* that's itself portrait-shaped — so its aspect never exceeds the cap
and the field just fills the window in both orientations. That confirmed the below-cap branch
(iPhone-identical behavior) and, crucially, that `reconfigure` re-deals cleanly: I rotated the
device to landscape and back twice, and each time the platforms rebuilt evenly, ladders
reconnected, the bull/matador re-seated at the top and the dancer respawned to the bottom
platform — no stale, clipped, or drifted geometry, no crash. What the sim *couldn't* show is the
above-cap branch's actual margins, because the M-series windowing never gives the app a
landscape-*wide* frame; that needs a true fullscreen-landscape size, which is what Josh will
eyeball on a real iPad. (Amusing side note: `simctl io screenshot` captures the raw display
buffer, so a rotated sim comes out sideways in the PNG — had to `sips -r 90` to read it.)

Tests: added `reconfigureRebuildsGeometryForNewSizeAndReseatsPlayer` (rotate to a wider/shorter
field → platforms span the new width, player re-seated in-bounds on the bottom platform, pickups
re-placed) and `reconfigureIsANoOpForAnUnchangedSize` to `GameStateTests`. Full suite green.

## Plot Twist: Conjugar Wasn't a Native iPad App at All (2026-07-15)

Follow-up to the iPad-geometry note above, and a good lesson in trusting docs over a
convenient simulator result. After I shipped the re-deal + letterbox fix and "verified" it on an
iPad Pro M5 simulator, Josh loaded a build on his *real* iPad and sent a screenshot: the game
sat in a small centered rectangle with fat black bars all around and a **zoom button** (the
diagonal-arrows control) in the corner. That's the unmistakable signature of an **iPhone app
running in iPad compatibility mode** — not a native iPad app.

Digging into `project.pbxproj`: the app target `biz.joshadams.Conjugar` had
`TARGETED_DEVICE_FAMILY = 1` (iPhone only). The `1,2` values I'd have found with a naive grep
belong to the *project-level default* and the *widget extension*, not the app. So CLAUDE.md's
framing and the round-2 review's item 8 both asserted "the app targets iPad (device family 1,2)"
— and both were wrong about the app target. In compatibility mode iOS hands an iPhone-only app a
**fixed iPhone-sized canvas**; rotating the iPad just re-letterboxes it. The app never receives a
native iPad orientation change, so the stale-geometry bug item 8 describes literally cannot
occur on the shipping app. My fix, however correct, was solving a problem the real app didn't
have.

Why did the *simulator* fool me? iPadOS 26's new windowing ran the iPhone-only app in a
*resizable window* that genuinely resized on rotation — so `reconfigure` fired and the level
re-dealt, exactly as if it were native. The sim showed dynamic behavior the real device (classic
fixed compat mode) never would. Two different iPad app-compat models, and I happened to test on
the one that masked the issue. (Amusingly, `simctl io screenshot` also captures the raw portrait
display buffer regardless of device orientation, so my landscape shots came out sideways and no
amount of `sips -r` rotation put the status bar where it belonged — I finally gave up on pixels
and read the truth out of the accessibility tree, which reports frames in real points:
`AXFrame {{0,0},{680,1210}}` told me unambiguously the app window was portrait.)

Presented Josh the fork: stay iPhone-only (revert my fix as inert, correct the docs) or go
native iPad (keep the fix, but every screen needs work). He chose native — he's already done the
per-screen iPad audit for the sibling apps Conjuguer and Konjugieren and will mirror it here in
separate sessions. So: flipped the app target's `TARGETED_DEVICE_FAMILY` to `1,2` (both Debug
and Release, app target only — the widget was already `1,2`). Rebuilt and reinstalled on the sim:
the app now launches with a **native iPad layout** (Browse renders as a proper iPad list, no zoom
button, no compat letterbox) and the AX window frame is a real resizable geometry rather than a
fixed iPhone canvas. Full suite still green (520 tests). The game's letterbox + `reconfigure`
are now genuinely load-bearing.

Logged the whole arc as review **item 15** (the cross-cutting native-iPad screens audit) and
corrected item 8's premise inline. The wide-area letterbox — a centered portrait column with big
side margins on a true fullscreen-landscape iPad — still awaits a real-device eyeball, because
the M-series sim only ever hands the app a portrait window (aspect 0.56, below my 0.62 cap, so
the field just fills the width and the cap never triggers). The math is deterministic; Josh has
the hardware.

## App Icon: Collapsed to a Single 1024 (iPad Warnings Fix) (2026-07-15)

Immediate fallout from making the app universal (family `1,2`): Xcode threw two asset warnings —
"A 76x76@2x app icon is required for iPad" and "A 83.5x83.5@2x app icon is required for iPad."
The `AppIcon.appiconset` was the classic all-sizes layout: 27 explicit PNGs, every one declared
`"idiom" : "iphone"`, plus the 1024 marketing icon. No iPad-idiom slots → actool flags the two
missing iPad primary sizes the moment the target gains the iPad idiom.

Two ways to fix it: hand-generate the iPad PNGs and add `ipad`-idiom entries, or switch to Xcode's
**single-size app icon** — one 1024×1024 image (`"idiom" : "universal", "platform" : "ios"`) that
actool downsizes to every slot for every idiom at build time. Checked the existing set first: the
"left-to-right" / "right-to-left" language-direction variants were **byte-identical** to their base
images (same md5 — an artifact of whatever generator made them 9 years ago), so they carried no
information to preserve. That made the single-size route a pure win. Rewrote `Contents.json` to the
lone universal entry pointing at the existing `icon1024.png` (already 1024², no alpha, App Store
clean) and `git rm`'d the 26 now-unreferenced PNGs.

Result: build is warning-free (was 2), and the bundle now ships `AppIcon76x76@2x~ipad.png` (152²)
alongside the iPhone `AppIcon60x60@2x.png` (120²). The universal source covers every other size
actool needs (including the 167px iPad-Pro icon) without a declared slot to go missing — which is
exactly why the warnings can't come back. The alternate app icons (Bull/Dancer/Matador/Classic) are
independent image sets and were untouched (no warnings for them). Net: 28 files in the iconset → 2.

## iPad Rotation: Re-seating the Bull and the Matador (2026-07-15)

Two more landscape-rotation position bugs Josh caught on the real iPad, both the same root
cause the earlier re-deal note only partly addressed: a handful of actor positions are *stored*
(`bullX/bullY`, `bullfighterX/bullfighterY`) rather than recomputed each frame, so `reconfigure`
has to re-derive every one of them — and I'd missed two.

1. **Climb: the bull hung below the top platform.** `respawn()` (my climb re-deal path) re-places
   the player, and `buildLevel()` re-places the matador (`bullfighterX/Y`), but neither touches
   `bullX/bullY` — those are set once per stage. So after a landscape rebuild the bull kept its
   old-platform Y and sank below the new (higher, shorter-field) top girder. Fix: a
   `reseatClimbBull()` that restores `bullY` to the top platform surface and clamps `bullX` into
   the new pacing range (`updateBull`'s bounds), preserving its horizontal progress.

2. **Boss: the matador floated to the top instead of standing on his pedestal.** `reseatForResize()`
   re-seated the boss actors, but for the matador it used `bullfighterHomeX/Y` — the *climb* home
   on the top platform — instead of `matadorStageX/matadorStageY`, his boss mark on the pedestal.
   In landscape the top-platform Y is way up high, so he appeared floating mid-air. One-line fix:
   seat him at `matadorStage`. (The pedestal graphic itself is a computed property off `screenSize`,
   so it had already reflowed correctly — the matador was just placed on the wrong shelf.)

The through-line: anything positioned by a *stored* coordinate needs an explicit re-seat in
`reconfigure`; only the computed-property positions (the pedestal, the stage-X fractions) self-heal.
Added a boss-rotation regression test (`reconfigureDuringBossReseatsMatadorOnItsPedestal`) and
extended the climb test to assert the bull lands on the top platform within its pacing bounds.
Verified on the iPad Pro 11" sim: rotate mid-climb → bull stands on the girder; rotate mid-duel →
matador stands on his pedestal. Full suite 521 green. (The M-series sim still only hands the app a
portrait window even in landscape, but the height change on rotation is enough to fire `reconfigure`
and exercise the re-seats — the bug reproduced and the fix holds.)

## Round-2 review step 7: guillemet normalization + a convention-pinning test (item 12) (2026-07-15)

Item 12 was pure content hygiene: the offline etymology-generation pipeline had been setting
Spanish glosses with *French*-style guillemet spacing — `« ser »` with inner padding — where
Spanish typography wants them closed, `«ser»`. It sat directly under the conjugations on every
verb screen and in the widget, so a Spanish-reading eye would register it the way an English eye
registers « this ». The counts matched the review exactly: **1,335 of 1,345** `es` entries had the
spaced form; the `en` table had its own smaller wobble — **61** entries reached for guillemets
where the rest of the table uses curly double quotes (60 spaced + 1 unspaced), and **1** `es` entry
(`alimentar`) used curly quotes where the rest of Spanish uses guillemets.

The normalization rule split by language: `es` folds onto **closed guillemets** (`«\s+`→`«`,
`\s+»`→`»`, and stray `“…”`→`«…»`); `en` folds onto **curly double quotes** (`«\s*`→`“`, `\s*»`→`”`),
dropping the inner padding as it converts. Net: 1,335 `es` + 61 `en` entries rewritten.

The care went into *proving the diff touched nothing but quotes and quote-adjacent whitespace*,
since it's a ~24 KB shrink across a 2.9 MB file and `git blame` will live with it. Method that paid
off: before any edit, a no-op `json.dumps(..., ensure_ascii=False, indent=2)` round-trip reproduced
the file **byte-for-byte**, which locked in the exact serialization settings (raw UTF-8, 2-space
indent, no trailing newline) — so the real diff couldn't smuggle in a re-encoding. After the edit,
a "letters" check (strip all four quote glyphs *and* all whitespace, compare) confirmed **zero**
actual-text changes, and a space-integrity check confirmed no double-spaces or grown space counts
crept in. Balance held (guillemets/curly quotes matched per entry) and every `~bold~` marker stayed
paired.

A first skeleton check *looked* alarming — 1,376 entries "differing" — but that was the check being
too crude: it counted the legitimately-removed inner-padding space (`fault »:` → `fault”:`) as a
change. The whitespace-blind "letters" check is the honest one, and it came back clean.

Pinned it with `EtymologyQuoteConventionTests` (`ConjugarTests/Models/`, reads the source-tree JSON
via the `#filePath`-relative repo-root idiom `SymbolValidityTests`/`CorpusFormsDumpTests` already
use): `es` must have no inner-padded guillemets and no curly quotes; `en` must have no guillemets.
Now a future generation batch that drifts back to `« ser »` fails a test instead of shipping.

Re-learned the test-runner trap the hard way: the first `--only-testing ConjugarTests/EtymologyQuoteConvention`
(the `@Suite("…")` *display* name) printed `Test Succeeded` while running **zero** tests — the
selector segment must be the Swift **type** name, `EtymologyQuoteConventionTests`. The tell is the
Swift Testing reporter's `✔ Test run with N tests …` line: absent on the first try, present
(`2 tests in 1 suite`) once the selector was right. Full suite **523 green**, SwiftLint clean.
Left `en`'s 60-entry mixed-convention count as the review noted it and did not chase the English
paragraphs that legitimately vary prose — only the quote glyphs were normalized.

## Default app icon → photoreal DancerIcon; legacy becomes ClassicIcon (2026-07-15)

Fresh installs were still defaulting to the original flat-vector dancer (the primary
`AppIcon` asset). Josh asked to promote the photorealistic flamenco `DancerIcon` to the
default and keep the old flat-vector art around under a new name.

The app already had a full alternate-icon feature (ported from Conjuguer): an `AppIcon`
enum (`bull`/`dancer`/`matador`/`classic`) driving `UIApplication.setAlternateIconName`,
a Settings picker with per-icon preview imagesets, and
`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES` so every `.appiconset` ships as
an alternate. The *primary* icon is whichever set `ASSETCATALOG_COMPILER_APPICON_NAME`
names — it was `AppIcon`, and the enum case whose `alternateIconName` is `nil`
(`.classic`) mapped to it.

So the swap was four coordinated edits, no new art needed (`DancerIcon.appiconset`
already existed with light/dark variants):

1. `git mv AppIcon.appiconset → ClassicIcon.appiconset` (Josh chose *ClassicIcon*, not
   *LegacyIcon* — it lines up with the existing `.classic` case). The nested
   `Contents.json` references only `icon1024.png`, so no edit inside it, and appiconsets
   aren't individually listed in `project.pbxproj`, so the rename needs no pbxproj churn.
2. `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon → DancerIcon` (both Debug + Release).
3. `AppIcon.swift`: `.dancer.alternateIconName` → `nil` (it's the primary now),
   `.classic.alternateIconName` → `"ClassicIcon"`.
4. `Settings.appIconDefault` `.classic → .dancer` so fresh installs pick the new primary.

Build confirms the swap the clean way: the asset compiler emplaces the DancerIcon PNGs
under iOS's fixed primary filenames (`AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png`)
*and* under the `DancerIcon*`/`ClassicIcon*` alternate names — the canonical "AppIcon*"
output name is just iOS's slot for whatever the primary happens to be, not our asset.

One nuance left alone by design: `setAppIcon` runs only from `didSet`, never at launch
(a deliberate choice to avoid the system "you changed your icon" alert), so an *existing*
user who was on `classic` with a nil OS alternate will now see DancerIcon until they
re-pick. Reconciling that at launch would trip the alert, so not worth it — the request
was specifically about fresh-install default. No test pinned the old default; full build
green, SwiftLint clean.

## An olé glyph drawn in code — round-2 review item 14 / step 8 (2026-07-15)

The boss pad's olé button (and its cue chip) had been wearing `figure.mind.and.body` —
a seated-meditation pose that prompted a "what does this button mean?" during the round-2
review. Item 14's plan: a custom symbol of the arms-up-V desplante, ideally derived from
the game's own `dancer_ole_3` peak frame. Josh asked whether Claude could draw the icon
directly or would need a raster tool (GIMP MCP, or Blender as with the game sprites). It
turned out no external tool was needed: a custom SF Symbol is an SVG *template* — text —
and the repo's `dancer`/`bull` symbolsets already established the exact scaffold (one
`<defs>` art group of filled paths + 27 per-weight/scale `<use>` transforms).

The naive route failed informatively. A marching-squares trace of the sprite's alpha
channel (pure numpy/PIL, subpixel-interpolated, Douglas-Peucker-simplified) produced a
faithful silhouette that was **unreadable at glyph size**: dancer_ole_3's arms join
overhead against the hair, so a solid silhouette has no negative space — at 34 px (the cue
chip's on-device glyph height) it read as a melting chess pawn. The shipped fix is a
*sculpted* glyph in the SF `figure.*` idiom — detached head dot (plus bun), uniform-width
round-capped arms opened into the V the review specified, and the sprite's measured
proportions everywhere else (the hips-left/head-right sway, the waist, the three-tier
skirt with its left-sweeping train, scalloped hem). Parts are authored as Catmull-Rom
outlines and offset ribbons, rasterized, unioned, and re-traced into clean contours —
topology headaches (arm/torso overlaps, head+bun union) dissolve in the raster round-trip.
Iteration was visual: PIL renders at 34/58/120/260 px on chip-colored mocks, eyeballed
frame by frame (v1 blob → v2 fused head → v3 crisp tiers → v4 buried arm roots).

The final art is normalized into the dancer art group's exact bounding box, so splicing
it into a copy of dancer.svg inherits every variant's transform and the family metrics
(≈117 % of cap height, small baseline descent) untouched — `ole.symbolset` is that one
generated file plus Contents.json; actool accepted it first try. In code, the review's
"hoist" suggestion became `DanceGlyph` + `DanceMove.glyph` (identity single-sourced in the
model, beside `cueSound`) and one `GameView.moveIcon(_:spriteSide:)` builder consumed by
both `moveChip` and the pad row — the two sites can no longer diverge. A companion
`SymbolValidityTests` case resolves every move's glyph (`UIImage(named:)` for the catalog
assets, which the item-1 `systemName:` sweep can't see; a missing asset fails with exactly
the silent-empty-render the sweep was built against). A second session reviewing the
preview sheet suggested a plain template imageset instead of the symbolset ("the
multi-weight pipeline is overkill for fixed styling") — kept the symbolset anyway: it *is*
a template asset, but one that font-scales, so the call sites treat olé identically to the
SF symbols beside it, no per-site frame sizing.

Verified in the iPhone 17 sim via `CONJUGAR_GAME_START_BOSS=1` + the game deeplink: the
pad renders the new figure at parity with its triangle/shoeprint neighbors, and a
screenshot burst across reroll-sampled phrases (ignored echoes reroll fresh demos) caught
an olé cue chip live — chip and button showing the same figure, which is the whole point:
the cue now literally previews the pose the dancer strikes. Full suite 524 green,
SwiftLint 0. The glyph pipeline scripts live only in the session scratchpad; the shipped
SVG is the artifact, and this note plus the sprite are enough to regenerate.

## Boss-fight shout overlap: ¡Vamos! under ¡Olé! (2026-07-15)

A screenshot from the boss fight (`overlap.png`) showed two jaleo shouts stacked directly
on top of each other — a per-move "¡Vamos!" sitting under the phrase-success "¡Olé!",
rendered as an illegible smear. Root cause was a spawn collision in
`handlePlayerMove`/`succeedPhrase` (`GameState+BossFight.swift`): completing the *last*
move of a phrase first spawned a per-move shout (one of ¡Eso!/¡Bien!/¡Vamos!) via
`spawnPlayerSpeech` at `(playerX, playerY − …)`, then `advanceEcho` immediately routed to
`succeedPhrase`, which spawned "¡Olé!" via the *same* `spawnPlayerSpeech` at the *same*
anchor. Two pops, same position, same instant → they float up as one overlapping blob.
Fix: suppress the per-move shout on the final move (`step + 1 < phraseSequence.count`) and
let the ¡Olé! carry the celebration. Non-final moves are unchanged; no test touched the
per-move shout, so nothing to update. Build green.

## Native iPad, phase 0 + first list grid (2026-07-16)

Kicked off the per-screen iPad layout work (round-2 review item 15). The plan is
`prompts/ipad-plan.md`; this session took the recommended first bite — the shared
foundation plus the flagship visual win — leaving the rest of the screen passes for
later sessions.

The sibling apps (Conjuguer, Konjugieren) were the blueprint: no `NavigationSplitView`,
no idiom/`UIDevice` gating, no custom top bar. On iPadOS 26 the plain `TabView { Tab }`
already promotes itself to the centered top pill for free — the only real work is
per-screen content that reads `@Environment(\.horizontalSizeClass)` and swaps a
single-column list for a `LazyVGrid` on regular width, with long-form text capped to a
reading measure. Konjugieren is the closest structural match to Conjugar's Browse (same
`ScrollViewReader` + zebra `LazyVStack` + bottom sort picker + count banner), so its
`VerbBrowseView` was the direct model.

**Phase 0 (shared components).** New `Views/BrowseLayout.swift` holds the three column
sets the later phases will share — `listColumns` (adaptive min 260, a touch wider than the
siblings' 250 because Conjugar's rows carry a serif infinitive *and* a gloss line),
`infoColumns` (320), and `detailColumns` (fixed two-up for the verb/model conjugation-card
masonry). Rather than add the plan's proposed second `readableWidth` modifier, I extended
the *existing* `readingWidth` in `Utils/Modifiers.swift` with an `alignment:` parameter
(default `.center`, pass `.leading` for article bodies) — one modifier, one source of
truth, and the lone existing call site (`SettingsView`) keeps working. Deviating from the
plan's name here was the cleaner call; noted so a future session doesn't go looking for
`readableWidth`.

**Phase 2a (VerbBrowseView grid).** Added the size-class split: on regular width the rows
reflow into a `LazyVGrid` of `.card()`-skinned `VerbGridCell`s (new view, same serif-gold
infinitive + gloss + blue rank as `VerbRowLabel` but laid out for a card — rank pulled up
beside the infinitive, no row padding since the card supplies it); the compact `else`
branch is byte-identical to before, so iPhone is untouched. The bottom sort picker got
`.readingWidth()` so it stops stretching to the full iPad width (a no-op on iPhone, which
is narrower than the 680 cap). The `browse_verb_count` launch anchor and the
`ScrollViewReader`/`scrollTo("top")` sort-reset are preserved.

**Landmines.** Editing view files spammed the usual bogus SourceKit diagnostics
(`No such module 'UIKit'`, `Cannot find type 'VerbSort'`, and — new one — `Type 'any
Layout' has no member` because the app's `struct Layout` shows up alongside
`SwiftUI.Layout` in the stale index); `build_app.sh` compiled all of it cleanly, as
CLAUDE.md promises. Verified on a real **iPadOS 26.3** sim (iPad Pro 11" M5) — the
iPadOS-18 sims reject the install ("Requires a Newer Version of iPadOS"). The portrait
grid renders exactly as intended (two columns of carded cells filling the width);
landscape reflow to 3–4 columns is mechanically guaranteed by the `.adaptive(minimum:)`
grid but wasn't screenshot-verified because `simctl` can't rotate and the AppleScript
rotate needs Accessibility permission this session didn't have. Green all the way: build,
**524 tests / 29 suites**, swiftlint 0 violations.

## iPad Support Phases 2b + 2c — Models Grid & Info Reading-Width (2026-07-16)

Continued the per-screen iPad layout pass (`prompts/ipad-plan.md`), landing the last two
list screens after Phase 2a's verb grid.

**Phase 2b (ModelBrowseView grid).** A near-mechanical mirror of Phase 2a. Added the
`horizontalSizeClass` env and the same size-class split: on regular width the model rows
reflow into a `LazyVGrid(columns: BrowseLayout.listColumns)` of `.card()`-skinned
`ModelGridCell`s; the compact `LazyVStack + Divider + zebra` path is byte-identical, so
iPhone is untouched. `ModelGridCell` (new, alongside `ModelRowLabel`) carries the same
serif-gold exemplar + tinted irregularity-percent pill + class number, but laid out for a
card — pill pulled up beside the exemplar via a `Spacer(minLength:)`, class number below,
no row padding since the card supplies it. The bottom 3-segment sort picker
(Irregularity/Alphabetical/Number) got `.readingWidth()` like the verb one. Keeping the two
browse screens structurally parallel matters — the round-2 review's Browse/Model mirroring
carve-out expects them to stay in lockstep, and now the iPad grid does too.

**Phase 2c (InfoBrowseView reading-width).** The plan offered two directions for Info — a
Conjuguer-style grid of section cards, or a Konjugieren-style reading-width grouped list.
Chose the grouped list: the existing sectioned `List` gets `.readingWidth()` plus a
`.background(Color(.systemGroupedBackground).ignoresSafeArea())`, so the About/Tenses
sections sit in a centered ~680 column with the grouped background filling the surround
seamlessly instead of stretching edge-to-edge. Picked it over the card grid on a
risk/reward basis: it's a pure cap that leaves every interactive bit — the live Tutor
availability row, the `E / E&M / E,M&D` difficulty segmented control in the Tenses header,
the difficulty filter — completely untouched, and it reads well because the native
grouped-inset look is preserved, just no longer absurdly wide. The added background is
invisible on iPhone (List already draws `systemGroupedBackground`) and `.readingWidth()` is
a no-op below the 680 cap, so compact is genuinely unchanged.

**Verification.** Both booted iPad sims were iPadOS **18** (they reject the install —
"Requires a Newer Version of iPadOS"); booted a fresh **iPadOS 26** iPad Pro 11" (M4) and
installed there. Dismissed the CommunView "New Version" cover, then screenshotted all three
list tabs: verb grid (2a), model grid (2b, two columns with pills aligned top-right and the
sort picker centered), and Info (2c, sections centered in a reading-width column, grouped
background seamless). Green throughout: build, **524 tests / 29 suites**, swiftlint 0
violations. The usual bogus SourceKit noise (`No such module 'UIKit'`, `Cannot find type
'ModelSort'`) showed up and was ignored per CLAUDE.md — `build_app.sh` is authoritative.
Not committed — holding for Josh's explicit go-ahead per the plan's no-auto-commit rule.

## iPad Phase 3 — Verb/Model detail two-up (2026-07-16)

The detail screens were the last phone-shaped holdout after the Phase-2 list passes.
`VerbView` stacked ~14 full-width conjugation cards in one column; `ModelView` did the same
with its header/grid card plus a full-width verbs-using list. Both stretched edge-to-edge on
iPad, each pronoun|form pair using maybe a third of a 650 pt card.

**The width decision.** The plan's draft said to cap only the header to reading width and let
the conjugation-card grid span full iPad width. I built it the other way: cap the *whole*
content column to `.readingWidth()` (680) and center it on both screens. The reason is the
cards themselves — a "yo hablo / tú hablas …" card is short, low-density content that reads
*worse* the wider it gets. At full 13" width a two-up grid gives ~650 pt cards that are mostly
empty; at a centered 680 column the two columns are ~328 pt each — essentially the same width
as a single phone card, just two abreast, halving the vertical scroll. That's the actual
Konjugieren look, and it has the bonus that header, card grid, and prose cards all share one
left/right measure instead of the header floating narrower than a full-width grid. The cap is a
documented no-op below 680, so iPhone is byte-identical.

**VerbView.** Added `@Environment(\.horizontalSizeClass)`; extracted the per-tense cards into
one `conjugationCards` `@ViewBuilder` so the compact `VStack` path and the regular
`LazyVGrid(columns: BrowseLayout.detailColumns)` path emit the exact same cards and can't
drift — the same single-content-builder discipline Phase 2 used. Etymology / example-use /
medieval cards ride along inside the same reading-width column.

**ModelView is not symmetric with VerbView.** It has no stack of tense cards to reflow — its
conjugation display is a *single* horizontally-scrollable pronoun-by-tense grid card. So the
"two-up" idea had nowhere to land there except the **verbs-using-this-model list**, which I
switched (via a new `verbsUsingList` `@ViewBuilder`) to the same adaptive
`LazyVGrid(columns: BrowseLayout.listColumns)` of carded `VerbGridCell`s that Browse Verbs
uses on regular width, falling back to the bare zebra/divider `LazyVStack` on compact. One
wrinkle worth noting: capping the column at 680 makes the grid card's rightmost person column
(`rehiciéramos`, `rehicierais` on long-stemmed models) scroll into view slightly sooner. It's
not a clip — the card was always a visible-indicator horizontal `ScrollView` — just a narrower
viewport, and it behaves the same as on a phone.

**Verification.** Both this-session iPad sims were iPadOS 18 (they reject the iPadOS-26-only
install), and a third was in an upside-down orientation that made `simctl` screenshots and AXe
taps land in a rotated coordinate space — the "Cool, I Have It" CommunView cover swallowed
every navigation attempt until I raised the correct M5 window by name via `osascript` and
rotated it upright. Once upright on an **iPadOS 26.3 iPad Pro 11" (M5)**: `ser` shows the two
columns of accent-bar cards with irregular red highlights intact; the `rehacer` model shows its
two verbs (`contrahacer` | `rehacer`) side by side and `decir` its single cell. Green
throughout: build, **524 tests / 29 suites**, swiftlint 0 violations. The usual same-module
SourceKit false positives (`Cannot find 'VerbMap' in scope`, etc.) appeared and were ignored
per CLAUDE.md — `build_app.sh` is authoritative. Not committed — holding for Josh's explicit
go-ahead per the plan's no-auto-commit rule.

## iPad Phase 4: reading-width caps — but most of the work was already done (2026-07-16)

Phase 4 of the iPad plan was, on paper, the biggest-sounding of the screen passes: "cap and
center the reading/form/modal screens" — Info, Quiz, Results, Settings, Tutor, Onboarding, and
the Commun cover, seven screens in all. In practice it was the smallest, because opening each
file revealed that **five of the seven were already reading-width-capped** — a happy accident of
how they were built during the original SwiftUI migration. `InfoView` had long carried
`.frame(maxWidth: Layout.readingWidth, alignment: .leading)` on its RichTextView body;
`QuizView` (both the idle briefing and the in-progress card), `ResultsView`, and `CommunView`'s
message column all used the same older literal idiom
(`.frame(maxWidth: Layout.readingWidth).frame(maxWidth: .infinity)`); and `SettingsView` had
already been ported to the newer `.readingWidth()` modifier. That literal idiom is functionally
identical to the modifier — an inner cap, an outer infinity-frame to center it — so there was
nothing to fix. I deliberately left them alone rather than re-wrap working, already-verified
screens just to unify the call-site spelling; Phase 0 had flagged that unification as *optional*,
and churning shipped layout code for zero visible gain is how you introduce regressions.

So the real change landed on the three screens that genuinely stretched edge-to-edge on iPad:
the two Tutor screens and Onboarding. `TutorView` got `.readingWidth()` on its chat scroll
column, the blue divider rule, and the input bar. The input bar was the only one with a wrinkle
worth noting: its cap has to sit *before* the `.background(Color.customBackground)` so the text
field and send button cap to 680 while the footer background still fills the full width — a
capped bar floating in a stripe of bare background would have looked broken. With the column
capped, the message bubbles' `Spacer(minLength: 60)` now shove user/assistant bubbles to the
right/left edges *of the reading column* instead of the full iPad width, which is exactly the
chat look you want. `TutorTestView` (the hidden triple-tap batch harness) got the same one-liner
on its results stack. Neither Tutor screen is reachable in the simulator — the on-device
Foundation Models model reports unavailable there — so those two are a code-review + real-device
check; they mirror the other caps exactly, which is the best assurance available short of an
Apple-Intelligence device.

`OnboardingView` was the one with a visible payoff. Its paged `OnboardingPageView` content
`VStack` had only a bare `.frame(maxWidth: .infinity)`, so on iPad the welcome/feature copy ran
to absurd line lengths. Swapping that for `.readingWidth()` drops each sheet's symbol, title,
body, and CTA into a centered ~680 column. The page dots, Skip/Dismiss, and the animated
Get-Started button all live in the parent `OnboardingView` body and were already centered — the
dots in a centered `HStack`, the CTAs as `PrimaryButtonStyle` capsules that hug their content —
so they needed nothing. Verified first-launch on an iPadOS 26.3 iPad Pro 11" (M5): the welcome
sheet's body wraps at a comfortable measure, centered, no longer edge-to-edge. (The `simctl`
screenshot came back rotated because the sim was physically in landscape; the rounded-corner
inset around the cover is iPadOS 26's new concentric cover chrome, not something in the app.)

Every `.readingWidth()` cap is a no-op on iPhone, whose width is below the 680 threshold, so the
compact layout is byte-identical — this is the same free-lunch property every prior phase relied
on. Green throughout: build, **524 tests / 29 suites**, swiftlint 0 violations. The usual
same-module SourceKit false positives (`Cannot find 'L' in scope`, `Type 'Color' has no member
'customBackground'`, etc.) fired on every edited view and were ignored per CLAUDE.md —
`build_app.sh` is authoritative. Not committed — holding for Josh's explicit go-ahead per the
plan's no-auto-commit rule. Remaining: Phase 1 (the sidebarAdaptable shell decision) and Phase 5
(the orientation/multitasking QA sweep + App Store screenshots).

## iPad Phase 1: the shell decision — leaving well enough alone (2026-07-16)

Phase 1 of the iPad plan was never really an implementation task; it was a *decision* with a
tiny bit of code attached. The plan had already established that on iPadOS 26 the plain
`TabView { Tab(...) }` in `MainTabView` auto-promotes to the centered top-bar pill for free, so
the only open question was whether to pin `.tabViewStyle(.sidebarAdaptable)` on it — the sibling
Conjuguer does (giving a collapsible sidebar), the sibling Konjugieren doesn't, and the plan
declared both "parity." Josh said to just decide, no opinion either way.

I tried it empirically rather than deciding blind: added the modifier, flipped the
`OnboardingDisplay.onboardingEnabled` kill switch so the welcome tour wouldn't cover the shell,
built green, and launched on an iPad Pro 11" M5. The simulator promptly reminded me why the
sibling-app sessions kept complaining about it — with onboarding suppressed, the CloudKit
"New Version" CommunView cover fired in its place, and the M5 sim was sitting in a rotated
orientation that turns every `simctl` screenshot on its side. That cover, at least, gave a free
bonus: it confirmed Phase 4's CommunView reading-width cap works visually — the "New Version"
card sits in a tidy centered column, not stretched across the iPad.

Rather than wrestle the rotation-plus-cover state to force the sidebar into a clean screenshot —
exactly the rabbit hole the plan and CLAUDE.md warn about — I made the call on the merits, which
pointed one way decisively: **don't adopt `.sidebarAdaptable`; keep the plain top-bar TabView.**
Four reasons. The shell already renders correctly and was verified in prior sessions, so the
burden of proof is on *changing* it. The custom `dancer`/`bull` line-art tabs were hand-tuned
for the top bar with `.symbolVariants(.none)`; a sidebar renders icons larger and left-aligned
next to the stock SF Symbols, precisely the context where thin outline bitmaps look rough — a
real regression risk for no functional gain. Conjugar is explicitly kept in parity with
Konjugieren, which ships without the modifier and looks the same — that's the tie-breaker the
plan itself hands you. And a sidebar earns its keep by organizing hierarchy; five flat peer tabs
have none to organize, so it would only add collapse-state and dual-context-bitmap QA surface.

So Phase 1 ships as a decision with **zero code change**: the experimental modifier was reverted,
`git diff` came back empty against the committed shell, and the build is green. The only artifacts
are these doc updates. The full five-tab tap-through and `conjugar://` deeplink regression sweep
fold into the Phase 5 QA pass, since the shell chrome is unchanged — a re-check, not new behavior.
Remaining on the plan: just Phase 5 (orientation/multitasking QA + App Store screenshots).

## iPad Phase 5: the iPhone regression — proving the caps are inert on compact width (2026-07-16)

Phase 5 is the QA-and-screenshots pass, and most of it — the iPad device matrix across four
models in both orientations, Split View / Stage Manager multitasking, the widget gallery, and
the device-captured App Store screenshots — is inherently physical-device or human-eye work that
belongs to Josh. But one slice is squarely Claude's and worth doing before any of that: the
iPhone regression. Every iPad change across phases 2–4 was deliberately gated so it *couldn't*
touch the phone — either behind `horizontalSizeClass == .regular` (the grid branches) or behind
`.readingWidth()`, a cap that's a no-op below its 680 pt threshold, and iPhone is narrower than
that. The regression's whole job is to prove that gating actually holds on a real compact screen,
not just in my head.

So I fresh-installed on an iPhone 17 (iOS 26) and walked every screen the iPad work touched.
The result is a clean pass: every size-class branch and reading-width cap is inert at compact
width, and the phone layout is byte-identical to before. `VerbBrowseView` and `ModelBrowseView`
render their single-column lists with dividers and zebra striping, not grids; `VerbView` shows a
single column of full-width conjugation cards, not the 2-up masonry; `InfoBrowseView` keeps its
grouped list and the E/E&M/E,M&D tense control at normal width; `OnboardingView`, `QuizView`, and
`SettingsView` all fill the compact width exactly as they did pre-change. The bottom tab bar
renders the custom `dancer`/`bull` line-art tabs correctly throughout, and the Info tab's Tutor
row honestly reports "Apple Intelligence is still getting ready" — the expected unavailable state
in a simulator.

Two things I couldn't tick off directly, neither a defect. `ModelView` wouldn't open under AXe's
synthetic taps — the model-list rows ignored three separate tap attempts even though AXe reported
success and even though the *verb*-list rows navigated fine on the same run. That's an AXe/HID
quirk with that particular list, not an app bug (real fingers navigate it every day), and the
screen is covered by pattern anyway: it shares `VerbView`'s exact `.readingWidth()`/size-class
idiom and its "verbs using this model" list mirrors the `VerbBrowseView` compact path I did
confirm. And `TutorView` stays unreachable in the simulator because the on-device model is
unavailable there — the same real-device caveat that has followed the tutor since it was built.

A couple of simulator gremlins ate a few screenshots along the way and are worth noting for the
next session: a system "Apple Account Verification" springboard alert covered the app on first
launch (dismiss with "Not Now"), and the Quiz tab's on-appear Game Center prompt is modal, so a
tab-switch tap issued while it's up lands on the alert instead of switching tabs — dismiss it
first, then navigate. No code changed this turn; the suite was already green at 524 tests. This
was pure verification, so the only artifacts are the plan/blog status updates marking Phase 5
done *with respect to Claude*, with the device matrix, multitasking, widgets, and App Store
screenshots explicitly flagged as Josh's remaining device work.

## Two new power-ups + two new mechanics — killing the per-run repetition (2026-07-16)

The climb (La Subida) has five stages, but the power-up and challenge draws each came from a
no-repeat shuffle bag of only **three** (`PowerUpKind` / `ChallengeMechanic`). A 3-item bag drawn
five times gives a clean permutation for stages 1–3, then reshuffles and hands out two more — so
**every run guaranteed two repeats in each family**. Growing each bag to five (bag-size ==
stage-count) makes each run a clean permutation: all five appear once, in pure-random order, zero
repetition. No draw-logic change was needed — `drawStagePowerUpKind` / `drawStageMechanic` already
do `allCases.shuffled(using:&bossRNG).removeLast()`, so a five-case enum just works. The two old
bag tests hard-coded windows of three (`Set(draws[0..<3]) == allCases`); I generalized them to
`PowerUpKind.allCases.count` so they never rot against a future bag resize.

The four new items all reuse the existing `Obstacle` render + collision path rather than
introducing new entity types (Josh's call) — the struct grew a handful of value-type fields
(`scale`, `parentID`, `birthOffset`, `fadeRemaining`, `vibrateRemaining`, `isChaser`,
`chaseTargetID`, `hopping`) plus an `isSpecial` flag so `updateObstacles` and the zombie homing
skip the ones their own subsystems drive. Two genuinely new tiny structs: `PlatformGap` (a fading
hole in a girder) and `HeartMissile` (a homing projectile).

- **terremoto** (earthquake mechanic): 5 s of vertical screen jiggle + pulsed haptics + ~10 % of
  each girder vanishing as two fading holes. The main engineering was that girders were single
  continuous `CGRect` spans with no gap concept — so I added `platformGaps`, made the player's
  landing snap skip a *finished* gap (a still-fading one stays solid and traversable, per Josh),
  added `fellThroughFloor()` (a light −1-heart reposition, not a full `respawn()`), and taught
  rolling obstacles to **hop** a finished gap on a parabolic arc (a `hopping` flag so they land
  back on the same girder instead of falling through). Haptics are pulsed `.impactMedium` on a
  0.18 s timer — there's no CoreHaptics here, only UIKit discrete generators, so a continuous
  rumble is faked by pulsing (noted as future polish).
- **camada** (obstacles multiply): a one-shot that spawns a half-size baby at each eligible
  obstacle's center; the baby slides one emoji-width out opposite the parent's travel over 0.5 s,
  then mirrors it exactly and rides it off the bottom girder. Any baby hit fades **all** babies
  (the parents untouched). Babies aren't eligible to breed, so a re-fire makes more children of
  the full parents, never grandchildren.
- **flechazo** (heart missiles on jump): a ❤️ pickup that, for the standard 7 s envelope, fires a
  half-size homing ❤️ on each qualifying jump (1 s creation cooldown; a jump with no target on
  screen consumes no cooldown). New `HeartMissile` entity, a ❤️ dancer badge mirroring the ⚡ speed
  badge.
- **cortejo** (mushroom chaser): a 🍄 pickup possesses a random obstacle — it shivers in place
  1.5 s, then pursues another at 1.5× speed (upward allowed) until it catches it; both fade out
  and red confetti blooms. The confetti **reuses the boss end-scene emitter idiom** (`spawnJaleo`
  emoji pops — emoji keep their own red regardless of the jaleo tint), so no new particle type.
  Fewer than two obstacles → a graceful fizzle (possess one, despawn after its shiver).

One implementation gotcha worth recording: the homing subsystems (missiles, chasers) look up their
target *in the same `obstacles` array they're mutating*. Passing `&obstacles[i]` while reading
`obstacles.first { … }` would trip Swift's exclusive-access trap, so those loops read targets from
a **snapshot** copy taken at the top of the frame and write only through indices. One-frame-stale
target positions are imperceptible.

SFX: two upgrades copied from the siblings — `brainLockOn.mp3` (Conjuguer) for the flechazo
lock-on and `coin.mp3` (Konjugieren) for the cortejo catch — dropped into the synchronized
`Conjugar/Audio/` group (auto-added to the target), new `Sound` cases, logged in
`asset-licenses/game-sounds-pixabay.txt`. terremoto reuses `.stampede` (literally a rumble, shared
with encierro); camada uses `.chirp`. Only the two mechanics needed strings (pickups are silent):
`Game.earthquakeAnnouncement` / `Game.multiplyAnnouncement`, both narrative bull sentences that
localize en/es following the `zombieAnnouncement` precedent (not the Spanish-in-both title-card
pattern).

Per the plan I stopped at a green unit-test run and did **not** launch the simulator — Josh will
hard-code specific power-up + mechanic combinations (`CONJUGAR_GAME_POWERUP` /
`CONJUGAR_GAME_MECHANIC`, both extended to accept the new cases) and play-test each himself. Build
succeeds, `swiftlint` clean, and the full suite is green at 538 tests (was 524; +26 new game tests,
−12 net after removing two duplicate bag tests I'd briefly added alongside the generalized
originals).

## Playtesting the four new items — the tuning pass a plan couldn't hold (2026-07-17)

The prior entry landed terremoto/camada/flechazo/cortejo functionally correct and green, and
*explicitly* stopped before the simulator: game feel was Josh's to play-test. This is that pass —
a long back-and-forth where Josh played on his iPhone, sent a screenshot or a sentence, and I
adjusted. It's the clearest demonstration I've hit that a plan can pin down *structure* (which
entities exist, what state they carry, where the render/collision seams are) but not *feel* — you
only learn the answer once photons hit your eye at 60 fps. Josh's own words at the end: "I have a
new respect for the contributions of videogame playtesters." Roughly **14 distinct tweaks** came
out of it, none of which were foreseeable on paper.

**The device-rig detour (and its teardown).** First surprise: the `CONJUGAR_GAME_POWERUP` /
`CONJUGAR_GAME_MECHANIC` env overrides only reach the process through `simctl`'s `SIMCTL_CHILD_*`
prefixes. A build run on a real iPhone from Xcode never sees them, so the game fell back to
*random* draws — Josh reported "not seeing flechazo/terremoto," and an earlier screenshot that
looked alarmingly like a bug (flags **and** animal obstacles on one screen) was just a normal
random run I over-read. The fix was a hard-coded device fallback: `riggedPowerUp` /
`riggedMechanic` constants that `debugForced*` return when no env var is set, **gated OFF under
`NSClassFromString("XCTest")`** (the same signal `World.chooseWorld()` uses) so the bag/mechanic
unit tests keep asserting real randomness, not the rig. Two more rig-only knobs rode along: a 10 s
pickup respawn (collect the same power-up repeatedly) and — later — a tripled forced-mechanic
delay (2 s → 6 s) so a forced mechanic loops on a watchable cadence. All of it was torn out at the
end when Josh said "restore randomization" then "full teardown"; the game is back to shipping
behavior (shuffle-bag draws, once-per-stage pickups, real 25 s mechanic cadence).

**The badge saga — a plan can faithfully reproduce an existing flaw.** The new ⚡/❤️ power-up
badges took *three* separate corrections. The plan had said "mirror `speedBadge`," and the
implementation did exactly that — including its placement a full `playerHeight` above center,
which put the badge squarely over the dancer's face. The plan propagated a latent flaw nobody had
noticed until a second badge made it obvious. Fixes, in order Josh caught them: center on the body
→ hover on her *leading* side like the muleta (offset by `playerFacing · playerWidth/2`) → and
finally anchor to the sprite's *vertical* center, once we pinned down that `playerY` is the center
of the short 30 pt collision box, ~13.6 pt below the tall dancer sprite's visual center
(`dancerFeetOffset`). Excluding the per-frame walk bob from the anchor kept the badge from
bouncing with her gait.

**Two latent/unspecifiable things in terremoto.** (1) Random holes could open on top of a ladder
mouth, severing a climb route — a correctness bug that only exists in the *interaction* of two
independently-specified systems (random gaps × ladders), invisible until you watch it happen. Fix:
treat each ladder mouth on a girder as a forbidden zone (half-ladder + half-dancer clearance). (2)
A hole opening under a *standing-still* player is unfair — she has no input to step off it — so an
idle dancer's footprint became a forbidden zone too, but only while idle (a moving player can
dodge). Both are pure "watch it and react" findings.

**Obstacle-destruction feedback grew in three moves.** Josh wanted a struck obstacle to fade over
1 s + throw a particle burst instead of vanishing. I wired it into the damage collision — then he
reported "not seeing it when hit by *hearts*," because I'd only done the player-collision path, not
the flechazo missile kill (still an instant despawn). Extended it there. Then the color: red →
Conjugar yellow.

**Cortejo — "underwhelming" became a small resource system.** This was the biggest single change,
and it arrived over four messages, each refining feel. The pickup used to be fire-and-forget. Now
a 🍄 grants **three charges**: one fires immediately if the field's idle, the other two spend on
the *next two jumps* — but only once the prior chase/obliteration has finished, so the chase time
is a natural debounce (`isCortejoActive` gate). Charges **persist across level summits** (not
death); a second mushroom collected mid-chase **banks** its three onto the remainder rather than
force-firing; a 🍄 badge sits on her leading side while charged; and — last touch — a banked
pickup plays a distinct **castanet click** so it registers audibly even when it doesn't fire (the
possession keeps its `.chime`). The shared trigger logic (`maybeTriggerCortejo` returning whether
it fired) serves both the pickup and the jump. That a "boring" power-up turned into a banked,
debounced, cross-level charge economy is itself the lesson: none of that was in any plan.

**Smaller ones:** flechazo now targets a *random* obstacle at jump time rather than the nearest
(nearest survives only as the mid-flight retarget fallback) — Josh found homing-the-closest
unsatisfying. And a mechanic announcement (the bull's speech) now **holds 1 s fully opaque and
stationary before it fades/rises** (a new `JaleoPop.hold` field), so "¡Invoco un terremoto!" is
readable before it drifts off — it used to start fading the instant it appeared.

The plan was still worth every line: because it got the bones right (value-type obstacle fields, a
shared fade ager, single render/collision seams), all 14 tweaks were one-file, one-seam edits, not
rearchitecting. The plan's real product wasn't the feature — it was a codebase *cheap to tune*,
which is exactly what an empirical, playtest-driven phase needs. The `GameState` suite grew to
**80** tests (six net new this pass: a ladder-clearance gap test, a standing-still-footprint test,
and four cortejo-charge tests; two existing hit tests renamed/rewritten from instant-despawn to
fade-out). Build succeeds, `swiftlint` clean. Nothing committed or pushed — Josh is playtesting the
now-derigged, fully-random build.

## Settings-tab game blurb: a shorter sibling to Onboarding.gameBody (2026-07-17)

The onboarding flow's `Onboarding.gameBody` string reads well on its full-screen sheet but ran
too long on the Settings tab's game card, which reused it verbatim. Split them: a new
`L.Game.settingsDescription` (`Game.settingsDescription` in the catalog) carries a trimmed
version for Settings — it drops the power-up specifics (no "smash-happy muleta (cape)") and the
surprise catalog ("from zombified-and-stampeding enemies to sudden blackouts"), keeping just
"grabbing power-ups" and "Survive surprises along the way." `SettingsView`'s game section now
points at the new string instead of `L.Onboarding.gameBody`.

While there, tweaked the closing line of both strings from "…a flamenco dance-off with the bull
decides whether love wins." to "…determines whether love conquers all." (es: "…decide si triunfa
el amor." → "…determina si el amor todo lo vence."). Both en/es translated in the catalog; build
succeeds.

## TelemetryDeck, and the analytics schema Conjugar had outgrown (2026-07-18)

Conjugar's analytics had been a ghost for years. AWS Pinpoint was ripped out long ago, but
the *shape* it imposed survived: an `AnalyticsService` protocol whose one real method was
`recordEvent(_:parameters:metrics:)`, a dozen `record*` convenience wrappers, and — the
detail that dates it — event-name constants that dodged parameter-name collisions with
umlauts (`scöre`, `viewContröller`, `cürrentQuestionIndex`, `identifīer`). The only
conformer was `AnalyticsServiceSpy`, which printed a flattened string to the console and
sent nothing anywhere. Every call site had been faithfully maintained through the whole
SwiftUI migration, feeding a service that did nothing.

The sibling apps had already moved on. Conjuguer and Konjugieren both use TelemetryDeck
behind a much smaller protocol: `initialize(appID:)` + `signal(name:parameters:)`, with
names in an `AnalyticsName` enum and keys in a `ParameterKey` enum. So the real question
wasn't "how do I add TelemetryDeck" but "how much of the old vocabulary is worth keeping."
Josh's answer was: none of it. Full convergence — three apps that read identically.

That turned out to be the right call for a reason I didn't anticipate when scoping it. The
`metrics: [String: Double]?` parameter, threaded through every call site, has no
TelemetryDeck analogue at all (its parameters are `[String: String]`), and no caller had
ever passed a non-nil value. Keeping the old protocol would have meant carrying a parameter
that could never do anything.

### What got deleted along the way

Two abstractions fell out as dead weight rather than being targeted. TelemetryDeck reports
country and language natively, which made the locale parameter on `recordBecameActive()`
redundant — and that parameter was the *only* consumer of the `AnalyticsLocale` protocol
and its `Real`/`Stub` pair. (The `becameActive` event went too: TelemetryDeck records
launches and sessions itself.) That protocol had been renamed from a plain `Locale` at some
point because it shadowed `Foundation.Locale` module-wide; it's now simply gone.

The bigger removal was **Commun**, the CloudKit-backed "message from the developer"
feature. Asked which Commun events the new schema should carry, Josh's answer was that he
hasn't used it once in the years since building it — delete all of it. That took out
`Commun`, `CommunViewModel`, `CommunView`, `CommunGetter`/`Real`/`Stub`, its test suite,
the `.fullScreenCover` in `MainTabView`, `Settings.lastCommunIdentifierShown`, and the
`communGetter` slot in `World`. It also simplified the launch path: `MainTabView`'s launch
task used to present onboarding *or* await the commun fetch, with a comment explaining that
two covers must not contend for the anchor. Now it just presents onboarding, and
`presentOnboardingIfNeeded()` no longer needs to return a Bool nobody else uses.

Removing Commun stranded CloudKit — it was the framework's only client — so the dead
`CloudKit.framework` link came out of the target too. The iCloud **entitlements** were held
back initially, since those touch provisioning; Josh asked, and they went too once verified
safe. The check that mattered: nothing else reaches for the container —
`GetterSetterReal` is plain `UserDefaults.standard` rather than `NSUbiquitousKeyValueStore`,
there's no `ubiquity-kvstore-identifier` entitlement, no `NSUbiquitousContainers` in either
Info.plist, and the widget's entitlements never had iCloud at all. The app-group entitlement
stays — that's what the widget and App Intents share defaults through.

Removing an entitlement is a *narrowing* operation, which is why it's safe: codesign checks
that requested entitlements are a subset of what the provisioning profile allows, so
requesting less always still validates. Deliberately **not** done: disabling the iCloud
capability on the App ID in the developer portal (unnecessary, and the step that would
actually invalidate profiles), and deleting the `iCloud.biz.Conjugar` container itself
(irreversible). Checking the deleted `CommunGetterReal` in git history settles what that
container actually holds: a `publicCloudDatabase` query for record type `"Communs"`, with no
write path anywhere in the app. So it stores only Josh's own authored announcement records —
title, content, button titles, a `CKAsset` image, identifier, `isCurrent` — and no user data
at all. Deleting it would destroy nothing but his own message history, but an idle public
database costs nothing to keep, and the entitlement removal already severs the app from it
permanently.

### The isolation surprise

The new files compiled and the app built green, and the whole thing looked done. Then the
first test failed to compile: *"call to main actor-isolated instance method 'signal(name:)'
in a synchronous nonisolated context."* Both conformers are declared `nonisolated`, so this
was confusing for a minute.

The cause is witness inference. `Analytics.swift` carried no isolation annotation, so under
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` the *protocol* became MainActor-isolated, and
conforming methods inherited that isolation regardless of the `nonisolated` on the class.
Which is not a cosmetic problem: `AnalyticsReal` exists precisely to get TelemetryDeck's
blocking `DispatchQueue.sync` calls *off* the main thread, and an implicitly-MainActor
protocol quietly contradicts that design.

The fix was to mark the protocol, its extension, and both enums `nonisolated`, matching how
the engine and `enum L` are already handled in this codebase. Worth noting that Conjuguer
has the same latent annotation gap and doesn't trip on it — only because nothing over there
calls the spy from a nonisolated test suite. The bug was always there; Conjugar just has a
test that looks.

### Secrets, and one signal that didn't survive review

The app ID follows Konjugieren's pattern: gitignored `Conjugar/Secrets.xcconfig` holding
`TELEMETRY_DECK_APP_ID`, wired as the app target's `baseConfigurationReference` for Debug
and Release, surfaced via the `TelemetryDeckAppID` Info.plist key, read in
`ConjugarApp.init()`. An empty ID leaves the service uninitialized and dropping signals, so
a clone without the file still builds. Verified the chain end-to-end by reading
`TelemetryDeckAppID` out of the *built* `Conjugar.app/Info.plist` — the interpolation is
exactly the kind of thing that silently yields an empty string if the xcconfig isn't
actually attached to the target.

Conjugar gained the sibling-parity taps (`tapPlayGame`, `tapShowOnboarding`,
`tapRateOrReview`, `tapSendTutorMessage`) and four game signals the siblings don't have —
`startGame`, `completeStage` (with stage number), `enterBossFight`, `winBossFight` — which
suit La Subida's five-stage arc better than Konjugieren's wave-based `completeWave`.

One planned signal got cut mid-implementation. I'd added `tapViewLeaderboard` for parity,
but Conjugar has no leaderboard *button*: `showLeaderboard()` fires automatically inside
`finish()` when a quiz ends. The signal would have been a misnomer and 1:1 redundant with
`completeQuiz` on every emission. Removed the case and the call.

Quiz signals now also carry `difficulty` and `elapsedTime`, which the old schema tracked in
`Results` but never reported.

### Verification

550 tests pass (30 suites, up from 544 — the six new ones are `AnalyticsTests`, replacing
the deleted `AnalyticsServiceTests` that asserted on the old spy's printed string).
`swiftlint` clean at 177 files. Built and driven in the simulator through all five tabs to
confirm the reworked launch path survives Commun's removal.

Delivery took a further round to confirm, and the detour is worth recording. The app ran
fine on Josh's iPhone but the dashboard stayed empty, which is ambiguous: it could mean
signals never left the phone, or that they arrived and weren't displayed. `World.simulator`
gets the spy, so the obvious check was unavailable.

Two things resolved it. First, the mundane cause: the SDK's
`TelemetryDeck.Config.testMode` defaults to the `DEBUG` flag, so **every signal from an
Xcode build is tagged `isTestMode == true` and is hidden until you flip the dashboard's Test
Mode toggle**. Nothing was broken; the data was one control away. Second, to settle
send-side independently of the dashboard, a throwaway probe drove `AnalyticsReal` directly
(bypassing `World`) while streaming the simulator's unified log. The SDK's own `logHandler`
turned out to be useless here — it appears to log only on failure paths, so a *successful*
send says nothing — but the system log was decisive: a completed TLS handshake to
`nom.telemetrydeck.com`, and no signal cache left on disk afterward (the SDK persists
undelivered signals for retry, so an empty cache means everything went out).

Worth remembering that the proof came from the OS rather than from the library's own
diagnostics. A debug `logHandler` was briefly added for this and then discarded, since it
demonstrated nothing the network evidence hadn't already settled.

`docs/privacy_policy3.txt` was rewritten from the staged Conjuguer draft: Spanish app,
Spanish translation replacing the French one, an event list matching the new schema, and a
new section on the on-device tutor stating plainly that message *content* never leaves the
device — only the fact that a message was sent.

## Porting Conjuguer's screenshot harness — and the anchors it assumed (2026-07-18)

The App Store screenshot machinery came over from Conjuguer: a plan (nine views, light/dark
alternating, en/es × iPhone 17 Pro Max + iPad Pro 13-inch, 36 PNGs), a driver, and a
playbook. Josh had already adapted the plan to Spanish — ser on top of Browse, the decir
model, haber for ModelView, Presente de Indicativo for the Info article. The driver and
playbook were still French.

The mechanical half was dull and quick: bundle id, `LANGS=( en fr )` → `( en es )`,
`Passer` → `Omitir`, `Conjuguer.xcodeproj` → `Conjugar.xcodeproj`. The interesting part was
what the port *assumed*. Conjuguer's driver navigates entirely by accessibility identifier,
and Conjugar had four of them. Seven of the nine screens would have failed at the first tap.
So the honest answer to "can we start shooting?" was no, and the real work was the
instrumentation landing: `verb_row_<infinitive>`, `model_row_<exemplar>`,
`info_row_<stableKey>`, `quiz_start_button`, `input_quiz_conjugation`, `results_score`.

Three decisions worth recording.

**Model rows are keyed by exemplar, not by `ModelInfo.id`.** The id is the `classNumber`,
and class numbers contain hyphens (`29-2`, `30-1`). The driver's jq predicate matches an id
exactly *or* as a `$id + "-"` prefix — a deliberate hack for SwiftUI rolling a row's
identifier onto its `NavigationLink` wrapper — so `model_row_29` would have silently matched
`model_row_29-2`. Exemplars are what the spec names anyway; a quick check confirmed all 102
non-alias rows have unique, hyphen-free exemplars.

**`Info` gained a `stableKey`.** Tense headings are hardcoded Spanish literals, but the
About headings are localized, so a heading-derived identifier would differ between the `en`
and `es` passes of the same sweep. Keying half the list one way and half another seemed
worse than spelling out 27 snake_case keys.

**The quiz fixture is a fixed list, not a generator.** Conjuguer generates 30 questions;
Conjugar's `Quiz.screenshotFixture` is 12 hand-picked ones. Fixed means the per-question
review rows on the results screen are byte-identical across all four device × language
cells, and 12 rather than 30 cuts the paste loop from ~40 s to ~15 s per cell. Two
constraints are load-bearing enough to be comments in the source: no second-person slots
(tú/vos is a user setting and vosotros is region-suppressed, so the question would render
differently depending on state the driver doesn't control), and every slot must conjugate
(a blank answer would desynchronize the paste loop from the on-screen questions and every
later answer would miss).

Two claims written into the playbook before verification turned out to be wrong, which is
the argument for verifying rather than reasoning. The first: I asserted that answers had to
be lowercased or they'd score as misses, because `TenseBridge` returns marked forms (`soY`,
`habRá`) where uppercase flags the irregular part. `ConjugationResult.compare` lowercases
both sides before comparing, so it never mattered. The export still lowercases — for
legibility when a human debugs a bad cell — but the playbook now says so, and says the
earlier claim was wrong.

The second was found by running it. Driving the fixture on a fresh install, the Quiz tab had
no `quiz_start_button` at all: `QuizView.onAppear` calls `maybePromptGameCenter()`, which
raises a Game Center alert that opaques the AXTree. Conjuguer has no equivalent prompt, so
nothing in the ported playbook hinted at it. `seed_defaults` now pre-seeds
`didShowGameCenterDialog` and `userRejectedGameCenter`. Josh then asked whether the playbook
should suppress Game Center UI more broadly; tracing it showed no — `GameCenterReal.authenticate()`
is the only thing that installs `GKLocalPlayer.local.authenticateHandler`, it's called from
exactly two user taps the driver never makes, and nothing authenticates at launch, so
GameKit's login sheet and welcome banner are unreachable during a sweep. That reasoning is
now a table in the playbook rather than something the next session has to rediscover.

Verified end-to-end on iPhone 17 Pro Max: every anchor resolves, `ser` sits at the top of
the frequency-sorted list, all 12 fixture answers conjugate correctly and score as total
matches, and the results screen comes out all-green with the elapsed-time pill the spec
wants. 550 tests pass, SwiftLint is clean. Shooting can begin.

### Addendum: verifying the tab coordinates (2026-07-18)

The one thing I'd flagged as unverified in the port was the tab-bar calibration, inherited
wholesale from Conjuguer. Checking it turned up three things, none of which reading the code
would have surfaced.

First, the two devices need different treatment. The iPhone's pill exposes no children — the
whole bar reports as a single `Tab Bar` group, frame `{0,873},{440,83}` — so there is nothing
to measure and the only available proof is behavioral: tap each coordinate, assert the
destination screen's anchor appears. The iPad's top bar, by contrast, exposes each tab as an
`AXRadioButton` with its own frame, so the centers are exact. Conjuguer's inherited iPad
values did work — every one landed inside the correct tab — but were 3–6 pt off-center. The
driver now carries the measured centers. An off-center-but-working tap is worth fixing
precisely because it's the early warning: it means the geometry has drifted, and the next
device or SwiftUI change may push it out of the tab entirely.

Second, the Settings tab "failed" on the first iPhone pass, and the reason was the *tip
system*, not the coordinate. The "Change Quiz Difficulty" tip is rule-gated on having
completed a quiz — and the probe had just completed one, exactly as the real sweep does at
screen 8 before shooting Settings at screen 9. So a sweep with tips left enabled would have
put a popover over the Settings screenshot, in the precise order the driver runs. The
playbook already said to flip `TipDisplay.tipsEnabled`; this was that instruction earning its
place, and a reminder that the tip fires from *state accumulated during the run*, not from
first-launch conditions a fresh install would avoid.

Third, the iPad install failed outright: this machine has four simulators named `iPad Pro
13-inch (M4)` — iOS 18.0, 18.1, 18.4, 26.0 — and `udid_for()` returns the first by list
order, which is 18.0. Since the deployment target is iOS 26 the failure is at least loud
("Requires a Newer Version of iPadOS … Have 18.0; need 26.0") rather than a subtly wrong
screenshot. The ported playbook described this hazard generically; it is now written up as a
concrete precondition with a snippet that lists the duplicates and names the survivor.

A methodological note worth keeping: two of the three findings came from *running* the thing
under the conditions the sweep actually creates, not from inspecting it. The Settings/tip
interaction in particular is invisible to any amount of code reading, because it depends on
quiz-completion state that only exists partway through a real sweep.

### Addendum: the soft keyboard, and a guard that never fired (2026-07-18)

With Accessibility permission granted to `osascript`, the last unverified piece was screen
5's keyboard. Verifying it turned up a bug that had been sitting in the ported driver the
whole time, invisible to inspection.

The first run of `ensure_soft_keyboard`'s AppleScript failed with *"Can't get window 1 of
process Simulator whose title contains iPhone. Invalid index" (-1719)* — which reads exactly
like a permission problem, and the driver's own warning message says as much ("grant
osascript Accessibility permission"). It wasn't. Permission was fine; the window list is
briefly unenumerable right after `activate`, and the script's `delay 0.2` wasn't enough. Five
consecutive runs afterward all succeeded. The delay is now 0.5 s, and the playbook says
plainly that -1719 is not a permission failure — otherwise the next person burns an hour in
System Settings.

The real bug was underneath. After the toggle succeeded the keyboard was plainly visible in a
screenshot, yet the AXTree reported **zero** elements labelled `space` — which is what
`ensure_soft_keyboard` counted to decide whether to send Cmd+K. The keyboard runs in its own
process and simply does not appear in `axe describe-ui`'s output at all; a full-tree dump of
that screen has nothing below y=1250. So the guard could never fire. And because Cmd+K is a
*toggle* whose state persists in Simulator across app launches, the second `quiz_mid` cell of
a sweep would have switched the keyboard back off, the third on, the fourth off — two of the
four quiz screenshots silently keyboard-less, in a sweep that otherwise reports success.

The fix came from a trick the ported playbook already contained: workaround #12 dismisses the
StoreKit modal using `describe-ui --point`, because `--point` can see system UI the full tree
can't. The same applies to the keyboard — probing a mid-keyboard coordinate returns the key
under it (`g`), while the same probe with the keyboard down returns the app's own content. A
one-or-two-character label is the discriminator. Not the space bar, though: it reports a blank
label, indistinguishable from "nothing found". `ensure_soft_keyboard` now also re-checks after
toggling and warns if it didn't land, since `osascript` returns 0 whether or not Simulator
acted.

Verified both directions: four consecutive calls with the keyboard already up leave it up, and
a call with it down turns it on and subsequent calls keep it on.

The pattern from the earlier addendum repeated exactly. Reading the driver would never have
surfaced this — the guard looks perfectly reasonable, and the failure only manifests on the
*second* invocation within a run. It took driving the real thing and comparing a screenshot
against what the accessibility tree claimed.

Housekeeping in the same session: the simulator inventory was down to 123 GB of accumulated
devices. All 46 iOS 18 devices were deleted (24 iPhones, 22 iPads), reclaiming 25 GB. Worth
noting that unlike the iPad Pro 13-inch duplicates deleted earlier, none of these collided
with a sweep target name — that was cleanup, not a fix, and the distinction was worth stating
before deleting 46 things.

### Addendum: migrating the sweep targets from iOS 26.0 to 26.3 (2026-07-18)

Josh asked whether the iOS 26.0 runtime could go — he builds against the newest runtime and
never reaches for 26.0 deliberately. The answer was no, but not for a reason visible in the
runtime list: **both screenshot targets happened to live on 26.0**, and worse, iOS 26.3 had no
`iPad Pro 13-inch (M4)` at all (only an M5), so deleting 26.0 would have left `udid_for()`
matching nothing and the driver exiting at `apply_device_state`. The sweep had landed on 26.0
by accident — the playbook's own Simulator Setup section says to create targets on 26.3 — so
the right fix was to make reality match the document rather than to keep 26.0 alive.

Migrating meant re-verifying everything runtime-sensitive, which the playbook's *Sim Runtime
Drift* section already demanded. Results: the iPad tab centers were identical to within 0.1 pt
(a first pass flagged them as "different" only because the comparison threshold was 0.05 pt —
sub-pixel noise against tabs 62–97 pt wide), all ten tab taps landed, the keyboard probe points
held, and the fixture played through to an all-green results screen on both devices. Two
incidental discoveries: the device-type id is now `…iPad-Pro-13-inch-M4-8GB` (Xcode 26 split
the M4 into 8/16 GB variants and the bare id no longer resolves), and the M4 type is still
offered on 26.3 even though a fresh install seeds only an M5.

The interesting failure came from the migration itself. With four simulators booted — the old
26.0 pair and the new 26.3 pair — `ensure_soft_keyboard` failed on the iPad. Workaround #10
raises the target window by matching the device-*family* substring (`iPad`), which is
unambiguous only while exactly one sim per family is booted. Four windows meant two matching
`iPad`, and the keystroke went somewhere useless. A normal sweep never creates that situation,
so this isn't a latent sweep bug — but it is an easy state to wander into while testing, and
the failure is silent in the sense that the screenshot still gets taken, just without a
keyboard.

Which is the second time in two sessions that the post-toggle check earned its keep: it logged
`soft keyboard still not visible after Cmd+K` and turned what would have been a puzzling bad
screenshot into a pointed diagnostic. Worth remembering that the check was added almost as an
afterthought while fixing the guard that never fired.

Cleanup ledger for the session, since three separate deletions happened for three different
reasons: three iOS-18 `iPad Pro 13-inch (M4)` duplicates (a real bug — they shadowed the sweep
target by name), 46 iOS 18 devices and then 305 devices on uninstalled runtimes (housekeeping,
no correctness impact), and finally 13 iOS 26.0 devices (consolidating onto one runtime). 354
devices and 123 GB became 37 devices and 35 GB.

## The First Real Screenshot Sweep, and What It Caught (2026-07-18)

The screenshot harness had been verified cell-by-cell for weeks, so running all 36 for the
first time felt like a formality. It was not. The driver reported eight problems' worth of
trouble, but only two of them as failures — the other six were cheerful successes that had
photographed the wrong screen. That asymmetry is the whole lesson of this session.

The two honest failures were the iPad's Spanish quiz cells, which died looking for
`quiz_start_button` on a screen that plainly had one. The cause turned out to be geometry:
the iPad's top segmented tab bar sizes each tab to its label, so the tab centers move when
the UI language changes. `Test` and `Información` are not the same width as `Quiz` and
`Info`, and the English-calibrated x for the quiz tab (526) lands squarely inside
*Información* in Spanish. `tap_tab quiz` had been opening the Info tab and the driver was,
in a sense, right to complain. The unsettling part was what measurement revealed next: the
English "models" coordinate sat **0.05 pt** inside the Spanish Modelos tab. Those two cells
had been passing on a rounding error. The fix was to stop hardcoding and start measuring —
`measured_tab_centers` reads the five `AXRadioButton` frames out of the live AXTree and
computes centers per language, falling back to the table only when nothing is exposed
(always the case on iPhone, whose pill has no children and divides evenly anyway).

The six silent ones were worse, and one of them wasn't a harness problem at all. All four
iPhone `model_view` cells had captured the Models *list* in light mode instead of the
`haber` detail. My first theory was timing, so I added a settle before the tap; the shot
came back identical. Tapping the row by hand in the simulator did nothing either — while
tapping the sort control on the same screen worked fine. The answer was in a diff between
two sibling views: `VerbRowLabel` ends with `.contentShape(Rectangle())` and a comment
explaining that without it SwiftUI hit-tests only the drawn glyphs. `ModelRowLabel` never
got that line. A model row is an exemplar on the left, a percent pill on the right, and a
`Spacer` between — so the entire middle of every row, which is most of it, was dead to
touch. The iPad had been fine because its grid branch wraps each cell in `.card()`, whose
fill hit-tests on its own. This was a real user-facing bug that had shipped, and the
screenshot harness found it precisely because a script taps the geometric center of a row
where a human would unconsciously aim at the word.

The remaining two silent cells were the iPad's settings shots, which showed the Browse grid
ghosted through the Settings cards — you could read `ser`/`be` behind the Region section.
`nav_settings` was the only recipe that tapped a tab and immediately screenshotted; every
other tab-switching recipe inherits a delay from its `verify_screen_loaded` poll. Anchoring
on `app_icon_bull` plus an explicit 1.5 s covers the crossfade, since an anchor being
mounted says nothing about whether the animation finished. A final iPad cell lost its tap to
a mid-render layout shift and was fixed by simply re-running it — the per-cell retry loop
exists for exactly that, and the failure mode is a reminder that a swallowed tap yields a
plausible PNG rather than an error.

Josh also asked mid-run for the "Apple Intelligence is still preparing" row to disappear
from screen 6. Apple Intelligence is never available in a simulator, so the tutor section
can only ever render as a reason row there — honest on a device, but it reads as a defect in
a store listing. Rather than a temporary local edit, this became a third documented kill
switch, `TutorDisplay.tutorUnavailableRowEnabled`, alongside the tips and onboarding ones.
It suppresses only the unavailability row, never the working `NavigationLink`, so it cannot
hide a real feature by accident.

Two Spanish content bugs surfaced in the `presente de indicativo` article while reviewing
the shots, both of which will ship in a screenshot if not fixed: the second bullet is a
duplicate of the first ("Accion que se realiza en el momento…", also missing its accent)
where it should describe habitual action, and the `comer` example reads "como, come, come"
instead of "como, comes, come". Left for Josh to decide on, since they're prose.

The bundle is `docs/screenshots/version_1/` — Conjugar's first, where the sibling apps are
already at version_2 and version_3. The playbook gained workarounds #18–20 and a blunter
warning at the top: budget time for re-shoots, and read every PNG, because the exit code
cannot tell you that a screenshot is of the wrong screen.

## Fixing the Two Spanish Content Bugs (2026-07-18)

Both bugs the screenshot review surfaced turned out to live in one string,
`Info.presenteDeIndicativoText`, and both were copy-paste damage rather than translation
errors. The second bullet of the Spanish "Usos" list was a verbatim duplicate of the first —
"Accion que se realiza en el momento en el que se está hablando", missing the accent on
*Acción* into the bargain — where the English reads "Habitual action" and the example
directly beneath it glosses the habitual sense. It is now "• Acción habitual:". The `comer`
example read "como, come, come, comemos, coméis, comen", with the 2S slot duplicating 3S;
English had it right. Now "como, comes, come, …". Nice irony for an app whose entire purpose
is conjugating verbs correctly.

The editing method matters more than the edit. CLAUDE.md warns that the Edit tool corrupts
`.xcstrings` values containing ASCII quotes, and this value is full of them
("Malteamos." = "We are malting."), so the fix had to go through Python. My first attempt
round-tripped the catalog through `json.load`/`json.dump`, which produced a **2,223-line
diff** — a whole-file reformat that would have buried two real changes in noise and made the
next merge miserable. Reverted, and replaced the two substrings in the **raw file text**
instead. Neither target contains a quote or a backslash, so the escaping cannot break, and
the diff is one line. General rule for this catalog: parse it to *find* things, but patch it
as text.

Verified twice — once by re-parsing the JSON and printing the Spanish body, and once by
driving the app in Spanish to the Presente de Indicativo article and reading both corrected
lines off the screen. The two Spanish `info_view` screenshots were then re-shot, since the
already-assembled bundle was carrying the old text; `version_1` now matches the app.

## Rewriting "Purpose & Use", and a Briefing That Lied (2026-07-26)

The Info tab's "Purpose & Use" article is the app's own description of itself, and it had
quietly gone stale: it described three tabs (Browse, Quiz, Settings) when there are five,
promised "thousands of Spanish verbs" when the engine ships 4,811, placed the Info
difficulty filter "near the bottom of the screen" in red when it now sits in the Tenses
section header, and knew nothing of Models, the tutor, etymologies, literary examples,
widgets, or the game. Josh asked for a plain-text draft in `docs/` — written in Conjugar's
own `^…^ ~…~ $…$ %…%` markup, not localized — that he could edit before any of it reaches
`L.swift` and the catalog. That is `docs/purpose_and_use_proposed.txt`.

The interesting editorial question was what *not* to touch. The article's first half is a
personal story — the developer in a previous job knowing that "ir" means "to go" and saying
"va a la oficina" to baffled colleagues, until he learned it is "$voY$ a la oficina" — and
it is the best writing in the app. It got kept verbatim, along with the three
difficulty-class paragraphs and the accented-letter long-press instructions. Everything
after it was rebuilt: a section per tab, plus new sections for the game, for the widgets and
Control Center controls and quiz Live Activity, and for accessibility. The draft carries a
`====` fence with change notes underneath — kept / corrected / added / reversible decisions
— so the reasoning is inspectable and the notes can be deleted in one stroke.

Reading the code to write the draft turned up a string that lies. `Quiz.briefing` told every
user "Conjugate 50 Spanish verbs against the clock. Your score rewards both speed and
accuracy." It does not. `Quiz.swift` sums the per-answer values and multiplies by the region
and difficulty modifiers; `elapsedTime` is displayed on the HUD, shown on the results card,
and reported to analytics and Game Center, but it never enters the score. So the app was
telling learners to hurry for points that do not exist. Josh chose to fix the string rather
than add a time term, and both localizations now read "Your score rewards accuracy, and
harder difficulty and region settings earn more points." Worth noticing *how* the bug
surfaced: not from a test or a bug report, but from writing documentation carefully enough
to have to check whether a sentence was true.

And a lesson relearned the hard way, one entry after it was first written down. Editing
`Quiz.briefing` through `json.load`/`json.dump` reformatted the entire catalog — a 2,223-line
diff for a two-line change, exactly the failure the previous session recorded. Reverted, then
patched the raw file text by substring with a `count == 1` assertion on each target. Two lines
changed. The rule from last time holds and deserves louder placement: **parse the catalog to
find things, patch it as text.** Knowing a rule and reaching for it under momentum are
different skills.

## Shipping the New "Purpose & Use", and the Bug It Found (2026-07-26)

The rewritten article went into the app today, in both languages, along with the app change
it turned up. Sequence: Josh edited the draft (`docs/purpose_and_use_proposed.txt`), asked
for a typo pass, accepted the fixes, then asked for the whole thing to be localized and
inserted.

The proofread was more useful than a proofread has any right to be. There were **no typos** —
but five factual errors, four of them mine, surfaced only because writing a sentence forces
you to check whether it is true:

- **"like `llover`"** as the example of a defective verb. It isn't one. `Conjugator.isDefective`
  is true only where the resolved model declares formless slots, which in practice means
  **abolir**; `docs/def_worklist.md` lists eleven semantically defective verbs the engine
  deliberately does not enforce yet, and `ConjugatorAccessorsTests` pins `!isDefective("soler")`
  precisely so nobody assumes otherwise. Swapped to abolir.
- **"and about a hundred others"** for pedir's family. Class 6B has **22** verbs. (conocer's 7A
  has 108; buscar's 1-1 has 285.) Now "a score of others".
- **"pull down on the list to reveal the search field."** A screenshot said otherwise: the
  search field is visible on launch, under the Browse title. This is the one claim that
  survived code-reading and died on contact with the running app — a good argument for
  verifying UI prose against pixels rather than source.
- **"tap Return."** The answer field sets `.submitLabel(.next)`, so the key reads *next*
  (*siguiente* in Spanish, which the translation reflects).
- **"on the Browse and Models tabs"** for the vos setting — see below.

That last one was not a documentation error at all. `Settings.secondSingularBrowse` was read
only by `VerbView`; `ModelView.gridPersons` was a `static let` hardcoded to `.secondSingularTú`.
A learner who asked for vos everywhere still got tú in every model grid. Josh chose to fix the
app rather than the sentence, so `gridPersons` became `static func gridPersons(for:)` mirroring
`VerbView.buildSections`'s tú/vos/both logic, with the resolved columns stored per instance and
`gridForms` mapped over the same local array so the precomputed matrix and the rendered columns
cannot drift. Verified on the simulator: model 28 (decir) now shows **vos → decís / decí** where
it showed *dices / di*. Under "Both" the grid becomes seven columns, which the card's horizontal
`ScrollView` already handles.

Also normalized a three-way spelling split. The medieval reference line renders
`"Cantar de mio Cid"` from `MedievalExample.swift`, the Spanish credits agreed, but the English
credits said *Mio Cid* and the onboarding said *mío Cid*. All now match the code's form, which
is also the scholarly one.

Localization was hand-written rather than machine-translated, and reused the existing Spanish
wherever the old article survived — the origin story, the difficulty classes, the vosotros and
voseo paragraphs, the accent instructions. The new material had to respect vocabulary the app
already ships: the tabs are *Explorar / Modelos / Test / Información / Configuración*, the
cross-reference targets must be the **Spanish** headings (`%terminología%`, `%créditos%`) because
`Info.info(forHeading:)` matches localized headings, and RAE says a four-digit number takes no
separator, so it is "4811 verbos" against English's "4,811". A validator checked all ten `%…%`
refs resolve per language and that every `^ ~ $ %` marker is balanced — 20/268/8/20 in English,
20/258/8/20 in Spanish.

Two process notes worth keeping. First, the catalog patch again went in as **raw-text
substring replacement** with a `count == 1` assertion, not a JSON round-trip: 7 lines changed
across four keys in a 215-key file. Second, two simulator lessons. `_resolve_udid.sh` is a
**sourced** helper that sets `UDID` — `UDID=$(_resolve_udid.sh)` captures nothing, which is how
a deeplink got fired at the wrong booted sim earlier in the session. And `simctl spawn defaults
write` did **not** take on an app that had already run this boot; the setting had to be toggled
through the UI, after an `axe swipe` to lift the picker clear of the tab bar. Worth remembering
before trusting a seeded default in a verification run.

Verification: `Build Succeeded`, `** TEST SUCCEEDED **` (550 Swift Testing tests in 30 suites,
plus the XCTest half, 0 failures), the article screenshotted at the top of both localizations,
all four new section headings present in the AXTree in both, and the Spanish `%terminología%`
link tapped through to the Terminología article. Not pushed — Josh is verifying on-device first.

## Screenshot pipeline: port five fixes from the sibling apps (2026-07-26)

Josh asked whether the screenshot-pipeline improvements made in Conjuguer and Konjugieren
since Conjugar's own sweep argued for re-shooting Conjugar's screenshots. They do, and the
investigation turned up a second, independent reason that had nothing to do with the
siblings.

**All 36 files in `docs/screenshots/version_1` carry an alpha channel.** `axe screenshot`
writes RGBA, and Apple's rule — "Images can't include alpha channels or transparencies" —
is a check on the file *format*, not on its contents, so a fully opaque RGBA capture is
rejected exactly like a transparent one. Every file measures `alphamean=1`, i.e. opaque in
every pixel, which is precisely why no amount of looking at the PNGs would ever have
revealed it. Konjugieren hit this on 2026-07-25 (`bbfee8d`) and both siblings now flatten
inside `take_screenshot`; Conjugar did not. Running Conjuguer's `verify_store_media.sh`
against the bundle returns `9 blocking` for each of the four folders.

The second reason is worse and is Conjugar's own. `version_1` is not the output of one
clean run. The raw timestamps under `docs/screenshots/` show the sweep running 15:03–15:23
on 2026-07-18, then roughly fourteen individual cells being re-shot one at a time through
16:14, with the folder assembled at 16:15 — twelve minutes *before* `17faf79` committed the
fixes for the defects that same sweep had just exposed. So part of the shipped-looking
bundle is pre-fix output from the run whose commit message reads "two hard failures and six
wrong-but-plausible screenshots." It also predates `32c1746` (model rows tappable) and
`e128b47` (the Purpose & Use rewrite). Flattening it in place would clear the upload block
while leaving all of that in.

Josh's call: port the fixes now, re-shoot in a fresh session — then, once the port was in,
he cleared me to drive the simulator far enough to lock in the one number I had left open.

Five things landed.

**`take_screenshot` flattens the capture** (`magick -alpha remove -alpha off`), with a
warning if ImageMagick is absent rather than a silent pass.

**`wait_for_stable_screen` gates every capture.** It samples the screen up to eight times
at 0.35 s and shoots once two consecutive frames differ by less than a tolerance. The
reason no accessibility wait substitutes for this is the interesting part: AX state answers
"has the hierarchy changed" while a screenshot is graded on "has the image stopped moving,"
and the two diverge — the outgoing screen's anchor leaves the AX tree within ~0.3 s of a
tap while an iPad cross-fade is still plainly visible. `17faf79` had already fixed the one
instance of this we caught (ghosted Browse content behind the iPad Settings cards) by
anchoring `nav_settings` on `app_icon_bull` and sleeping; this generalizes it.

The tolerance was the one loose end, and it turned out to be worth the trip to the
simulator. Both siblings say in writing not to port their value, and they disagree with
each other — Conjuguer 5e7, Konjugieren 1e8 — because each measured its own app. Conjugar's
answer is **7.5e7**, and the interesting part is that *both* sibling numbers are wrong for
this app, in opposite directions.

The floor is benign motion: 112 consecutive-frame samples on the quiz screen across both
devices, whose elapsed counter ticks and whose answer cursor blinks. Median 9.8e6, p95
1.9e7, max 4.6e7. A genuinely static screen scores exactly 0. The ceiling is a real
transition: 21 first-deltas after an iPad tab tap, minimum 1.2e8, typically 8.3e9 to
2.5e10. Conjuguer's 5e7 sits 1.08x above our worst benign frame — the quiz screen would
trip it. Konjugieren's 1e8 sits 1.16x below our smallest observed transition. 7.5e7 is the
geometric middle, 1.6x above the floor and 1.5x below the ceiling. A ~2.5x gap is narrower
than I would like, which is why the comment says re-measure rather than nudge.

`-metric AE` turned out not to mean what its name suggests, incidentally: two totally
different screens scored 2.4e9 on a 3.8-megapixel image, so it is summing channel error in
quantum units, not counting differing pixels. Only the ratios matter.

Then the part that actually justified the exercise — verifying the gate rather than
trusting the arithmetic. Three rounds on the iPad: tap a tab, run `wait_for_stable_screen`,
capture, and compare against a reference of the same screen taken three seconds later. All
three came back **byte-identical, delta 0**. The control — the old behavior, tap and shoot
— landed 8.0e9 to 1.2e10 away, and the frame is *exactly* the workaround #19 artifact: the
Browse verb list, `ser`/`be`, `poder`/`can`, `decir`/`say`, ghosted straight through the
Settings cards. That bug had been diagnosed from a bad screenshot in July; this is the
first time it has been reproduced on demand and then watched to disappear. On the quiz
screen the gate settles in ~1.9–2.1 s and does not warn.

One limit is recorded rather than smoothed over. An iPad cross-fade's *tail* scores
7.7e6–1.1e7 — below the quiz screen's own noise — so no single threshold separates a
late-fade frame from benign motion, and I could not make one exist. It does not matter in
practice, because in every observed case the frame following such a delta was byte-identical
to the settled screen; the fade at a 0.35 s cadence is effectively binary. But that is an
assumption, not a proof, so it is written down in both the constant's comment and the
playbook as the thing to suspect if ghosting ever comes back.

**`frame_of` takes the largest-area match instead of the depth-first first one.** In
Konjugieren an iPad Info row exposed its heading as a non-interactive `AXStaticText` above
the tappable `AXButton`, so `[0]` tapped the static text, nothing happened, and four cells
captured the Info list instead of the article. Preferring `AXButton` is the obvious fix and
is wrong — on iPad a verb row exposes its *translation* as a button while the infinitive is
static text, so that rule taps the translation. Checked whether Conjugar needs it at all:
as of the July sweep every tap site on both devices in both languages has exactly one
match, so old and new agree everywhere in this app today. Kept as a safety net and
labelled as one, in the code and in the playbook, rather than dressed up as a fix.

**`resolve_ibv_scripts` searches `~/.claude/plugins/marketplaces`, not `~/.claude`.** The
broad glob matched three paths on this machine — plugin-cache copies of 0.3.1 and 0.2.1
plus the marketplace clone — and `find`'s directory order is unspecified, so which release
of `ios-build-verify` built the App Store screenshots was luck. The marketplace clone has
no version segment and yields exactly one match. The same glob was in the playbook's
Prerequisites and is fixed there too.

**`scripts/verify_store_media.sh`** is new, copied byte-for-byte from Conjuguer apart from
its header comment. Konjugieren's `post-release-features.md` already names Conjugar as the
third consumer this file is waiting on. It checks dimensions against Apple's accepted
screenshot and preview sizes, alpha, and — for videos — SAR, duration, codec, level, stream
count, frame rate, and audio bit rate, graded in blocking and advisory tiers. Conjugar has
no app previews, so the video half is inert; it was kept rather than stripped so the three
repos stay diffable. Self-tested four ways: the known-bad bundle (exit 1, nine blocking), a
flattened copy of three of those same files (exit 0, all clear), an empty directory (exit
2), and a nonexistent path (exit 2).

Also: the playbook's `latest/` assembly snippet now begins `rm -rf`. Without it a re-shoot
leaves the previous release's files beside the new ones — every filename carries a
timestamp so nothing is overwritten and nothing looks wrong — and the numbered-bundle
snippet downstream then matches two candidates per slot and breaks the tie by glob order.

Two smaller notes recorded for the re-shoot session. `version_1`'s iPhone shots carry the
live simulator clock (seventeen at 14:31, one re-shot cell at 15:31) while the iPad shots
carry the pinned 9:41; the playbook already treated the iPhone override as optional because
it isn't worth re-shooting a device for on its own, but a full re-shoot makes uniformity
free. And in the light-mode slots (2, 4, 6, 8) the status-bar text renders white on white,
so the clock, wifi, and battery are effectively invisible — worth a look during the
re-shoot. The light/dark alternation itself is correct and specified in
`docs/screenshot-plan.md`; that one had me suspicious for a while before I read the spec.

Two incidental findings for the re-shoot session, both now in the playbook. The iPad
simulator's **system language is still French** from Conjuguer work — its status bar reads
"Dimanche 26 juillet", which would have shipped in the iPad screenshots. The app's own UI
localizes correctly regardless, which is exactly why it is easy to miss. And a stray
`⌘K` I sent to toggle the soft keyboard did not land on Simulator and launched the Fitness
app on Josh's Mac instead — which is workaround #10, "multi-sim window focus", reproduced
live. The driver already raises the Simulator window before sending the keystroke; what it
does not do is *verify* Simulator is frontmost before firing. Worth considering, though the
existing `keyboard_is_visible` check does catch the consequence after the fact.

No app code changed, so there is nothing to build or test. Both scripts pass `bash -n`, the
driver's `resolve_ibv_scripts` was confirmed to resolve to the marketplace path at run time,
the `frame_of` pipeline was unit-tested against a synthetic AX tree in which the small label
precedes the large row, and the no-match path still returns empty so `tap_id_first` keeps
logging its error. The alpha flattening, the largest-area `frame_of`, and the `latest/`
clear are verified in isolation but have not yet run inside a full sweep.

## The First Clean Sweep: 36 Screenshots, Zero Re-shoots (2026-07-26)

The screenshot driver has been fixed in pieces across three sessions without anyone ever
watching it run all the way through. This session ran it: 9 views × en/es × iPhone 17 Pro
Max + iPad Pro 13-inch (M4), the `version_2` upload bundle. Every one of the 36 cells
landed on the first attempt — no retries, no driver warnings, and after reading all 36 PNGs
by eye, no re-shoots. That has never happened before. The first full sweep (2026-07-18)
shipped six silently-wrong cells and two hard failures.

Worth being precise about what a clean run proves, because it is easy to over-read. It
confirms the known failure modes stayed fixed. It does not prove the driver is correct, and
it emphatically does not retire the visual review: every failure this driver has ever had
produced a plausible screenshot and an exit code of 0. A clean run and a six-failure run
look identical from the outside. The playbook now says so in those terms.

The three fixes that had only ever been verified in isolation all held up end to end. Alpha
flattening (workaround #23) is the big one — `version_2` is `hasAlpha: no` across all 36
files and passes `verify_store_media.sh` with 0 blocking and 0 advisory, while `version_1`
still fails the identical check 36/36. That contrast matters: it means the check is
discriminating, not vacuously passing. The settle gate (#22) plus the `nav_settings` anchor
(#19) produced two fully opaque iPad settings cells with none of `version_1`'s Browse-grid
ghosting, and the gate never once logged "still changing after 8 samples", so the measured
`7.5e7` tolerance has real headroom on both devices. Largest-area `frame_of` (#21) caused no
wrong-element taps. The iPad/es `quiz_mid` and `quiz_results` cells — the ones that hard-failed
`version_1` because the hardcoded English tab centers put "quiz" inside *Información* — both
landed on **Test**, so live tab measurement (#18) works.

Two things came out of the run that were not on the list.

**The pinned clock is locale-formatted, which makes the status-bar dance an iPhone problem
too.** The playbook had always framed the system-language + reboot ritual as iPad-only, on
the reasoning that only the iPad status bar shows a date. That reasoning is incomplete. With
the *identical* `--time "9:41"` override, an `en_US` device renders `9:41` and an `es_ES`
device renders `09:41` — 12-hour versus 24-hour. So setting the system language on only one
device leaves the iPhone and iPad clocks disagreeing inside the same language, which is
precisely the kind of defect nobody notices until it is on the store. I ran the language
dance on both devices; the English shots read `9:41` everywhere and the Spanish `09:41`
everywhere. A parallel session flagged the ordering trap mid-run — the reboot clears the
override, so an override applied *before* the language change is wiped — which my helper
already handled, but the near-miss was real enough that the ordering is now encoded in
`scripts/prep_screenshot_sim.sh` rather than left as four prose steps. It prints the override
state and the resulting `AppleLanguages` afterward so a future reader can *see* both landed.

**The `Cmd+K` misfire has a root cause the AXRaise never covered.** Same parallel session
reported that a stray `Cmd+K` had launched Fitness on the host Mac while a run reported
nothing wrong. The existing workaround #10 raises the target Simulator window first, but that
is not sufficient in the way that matters: when the raise silently fails to take focus,
`keystroke` still *succeeds* — it just lands wherever the frontmost app happens to be.
`osascript` returns 0 either way, and the post-toggle `keyboard_is_visible` check can only
report that the keyboard is missing, never that the keystroke went somewhere else. Retrying
is useless because the retry misfires identically. `ensure_soft_keyboard` now asks System
Events for the frontmost process and **skips** the keystroke rather than sending it to the
wrong application. All four `quiz_mid` cells in this sweep had visible keyboards, so the
misfire was situational rather than systemic — but the guard costs nothing and the failure
was silent.

One app-side defect found and deliberately **not** fixed. In the four light-mode slots
(`verb_view`, `model_view`, `info_browse`, `quiz_results`) the status-bar clock is white on a
white background and effectively invisible; on `verb_view` the green battery appears to float
alone with no time and no Wi-Fi glyph beside it. A previous session had flagged this as "worth
a look during the re-shoot" without diagnosing it. The cause is `Conjugar/Info.plist` lines
49–50 and 62–63: `UIStatusBarStyle = UIStatusBarStyleLightContent` with
`UIViewControllerBasedStatusBarAppearance = false`, a UIKit-era holdover from the 2017 app
that forces light status-bar content app-wide regardless of appearance. Correct in the five
dark slots, wrong in the four light ones — and wrong for every light-mode *user*, not just for
screenshots. I left it alone: changing it alters the shipping app's appearance, which is
outside "produce the screenshots", and the light/dark alternation itself is specified in
`docs/screenshot-plan.md` and is correct. It is written up in *Known Gotchas* with the fix and
the cost of acting on it (one plist edit plus a re-shoot of the 16 light cells, ~15 minutes).
Josh's call, not mine to make mid-sweep.

Two smaller observations recorded rather than acted on. The Spanish `quiz_mid` shots show an
**English** keyboard — `EN` on the space bar, no `ñ` key — because the simulator's installed
keyboard list is a separate preference from `AppleLanguages` that the language dance does not
touch; the plan only requires the keyboard be visible, so churning two good cells for it
seemed the wrong trade. And the Spanish verb count renders `4811 VERBOS` where English renders
`4,811 VERBS`; Spanish would normally group as `4.811`. That is app number formatting, not a
capture problem.

No app code changed, so there is nothing to build or test. Both scripts pass `bash -n`, the
new `prep_screenshot_sim.sh` was run live against the iPhone sim and printed the expected
`Time: 09:41` / `(es)` verification, and the frontmost-process query the new guard depends on
was confirmed to return `Simulator`. All three kill switches are restored to `true` and
`git diff --stat Conjugar/Models/ConjugarTips.swift` is empty.

## Addendum: the status-bar fix, and throwing away a clean sweep (2026-07-26)

The entry above ends with the light-mode status-bar defect written up as found-but-not-fixed,
on the reasoning that changing the shipping app's appearance was outside the remit of
"produce the screenshots". Josh read that and made the call: remove both keys, support light
mode properly. So `UIStatusBarStyle = UIStatusBarStyleLightContent` and
`UIViewControllerBasedStatusBarAppearance = false` are gone from `Conjugar/Info.plist`. With
neither present the system derives the style from the appearance — dark-on-light in light
mode, light-on-dark in dark mode. The app builds clean and the built `Conjugar.app/Info.plist`
carries neither key.

The consequence was that the 36 screenshots I had just finished were obsolete: the fix changes
all 16 light cells, and a bundle assembled half from the old build and half from the new would
be exactly the "hand-patched, not the output of one clean run" artifact this playbook already
criticizes `version_1` for being. Josh's instruction was to delete rather than re-shoot and let
a fresh session redo it, so the 36 timestamped PNGs, `latest/`, and `version_2/` are gone.
`version_1` and the unrelated calibration shots from earlier in the day survive. **`version_2`
is now an unclaimed number** — the playbook says so in three places, because the natural
assumption on seeing `version_1` alone on disk is that the next bundle is `version_2`, and this
time that assumption happens to be right for the wrong reason.

Some honest bookkeeping about a prediction I got wrong. Having removed the global override, I
reasoned that the game would regress in light mode: `GameView` pins its subtree dark with
`.environment(\.colorScheme, .dark)`, and that modifier governs how descendants resolve
adaptive colors — it is `.preferredColorScheme(_:)` that drives the status bar. On that
reasoning a light-mode user opening the game would get dark status-bar text over the game's
forced-dark night scene, relocating the invisibility rather than fixing it. I flagged it with a
one-line fix and, because Josh had said he would check it himself, deliberately did not edit
`GameView.swift` under him. He checked: the game looks correct in both modes, no change needed.
The reason the theory failed is placement — the `.environment` override is the *outermost*
modifier on `GameView`'s body (the existing comment even says "applied last" so the background
resolves dark), which makes it the root environment of the full-screen cover's hosting
controller, and `UIHostingController` derives `preferredStatusBarStyle` from its root view's
resolved scheme. The environment override does reach the status bar in that arrangement. Worth
recording because the general rule — "`.environment(\.colorScheme,)` doesn't set the status bar,
`.preferredColorScheme` does" — is true often enough to be worth knowing and wrong here, and the
distinction is placement, not the modifier.

Net state: no screenshots on disk from this session, one real app fix that improves light mode
for every user, a driver that has now demonstrably completed a clean 36-cell run, and a playbook
that describes all of it accurately for whoever shoots next.

## Converging the three drivers on one Cmd+K retry loop (2026-07-26)

Josh asked whether the siblings would benefit from the frontmost guard I had just added.
They would not — they already had it; Conjugar was the last of the three, and the code I
applied came from Conjuguer in the first place. But checking turned up an asymmetry worth
fixing. Conjuguer and Conjugar each did one raise, one frontmost check, and gave up if the
check failed. Konjugieren had folded the same check into a 3× retry loop, which is
meaningfully better for a reason that is easy to miss: the guard's failure mode is not
always permanent. A *transient* steal — Simulator still coming forward, some other app
momentarily frontmost — is exactly the kind of thing that clears in a second, and the
single-attempt shape turned it into a keyboard-less `quiz_mid` cell. So Konjugieren's shape
went into the other two.

The distinction the loop has to preserve is that retrying does not fix the *original* bug.
When AXRaise fails to take focus, `keystroke` still succeeds and lands in whatever is
frontmost, so a bare retry just misfires three times instead of once. What makes the loop
correct is that the frontmost check sits *inside* it: each attempt re-raises, re-checks, and
only then types. A persistent steal therefore burns all three attempts and sends **zero**
keystrokes.

Verified rather than assumed. I extracted `ensure_soft_keyboard` from both repos into a
harness with stubbed `osascript`/`log`/`sleep` and a scripted sequence of frontmost answers,
then counted attempts and keystrokes across three cases. Clean: 1 attempt, 1 keystroke.
Persistent steal: 3 attempts, 0 keystrokes, then the 3× warning. Transient steal (wrong on
attempt 1, right on attempt 2): 2 attempts, 1 keystroke — the recovery the port exists for.
Both repos produced identical output. Stripping comments, Conjugar's function is now
line-for-line identical to Konjugieren's, and Conjuguer differs only in the one intentional
line: it matches its Simulator window on the whole `$DEVICE` string where the other two use a
device-family substring. That difference is deliberate and documented in each playbook —
Conjuguer needs the full name because a bare "iPhone" match there can select the wrong
window.

No app code touched in any repo; both drivers pass `bash -n`, and workaround #10 is updated
in Conjugar's and Conjuguer's playbooks to describe the loop rather than the single attempt.

## Version_2: the 36 App Store screenshots, and a booted simulator with no window (2026-07-26)

The third full sweep, and the first whose output is meant to be uploaded. The second sweep,
hours earlier, had been clean and was then thrown away on purpose: reviewing it turned up the
white-on-white light-mode status bar, the fix was an `Info.plist` change, and 36 files that
predate the build they claim to show are worth less than nothing on disk. So `version_2` was
an unclaimed number, and this run claimed it.

The mechanics went the way the playbook says they should. Both kill switches — all three,
rather: tips, onboarding, and the tutor's unavailability row — off before the build, restored
after, with `git diff --stat` clean at the end. Four passes, one language per boot per device,
each preceded by `prep_screenshot_sim.sh` so the system language is set *before* the reboot and
the status-bar override *after* it. The verification lines that script prints earned their keep
immediately: the iPhone's pinned clock came back `9:41` on the English pass and `09:41` on the
Spanish one, which is the locale-formatting quirk the last sweep discovered, visible as data
rather than as a thing to remember.

One cell out of 36 came out wrong, and the interesting part is why the driver's error message
was misleading. iPad/es `quiz_mid` captured without the soft keyboard, and the log said
`AppleScript Cmd+K failed 3x (accessibility permission …, or Simulator never came frontmost)`.
Neither was true — the permission is granted, and Simulator was frontmost. The real cause was a
third thing the message does not mention: the iPad had come back from the prep reboot **booted
but with no Simulator window**. `simctl` and `axe` never noticed, because they talk to the
device rather than to the UI; the whole sweep ran fine for eight more cells. Only the AppleScript
path needs a window, and `first window whose title contains "iPad"` fails with `-1719 "Invalid
index"` when there isn't one — which is exactly what a missing accessibility permission looks
like.

Getting the window back was harder than expected, which is worth recording so nobody re-derives
it. `open -a Simulator --args -CurrentDeviceUDID <udid>` does nothing when Simulator is already
running; the argument is simply ignored. Simulator's own **File ▸ Open Simulator ▸ iOS 26.3 ▸
iPad Pro 13-inch (M4)** menu item clicks successfully and produces no window. What works is
quitting Simulator.app and relaunching it: on launch it attaches a window to every already-booted
device. So `prep_screenshot_sim.sh` now checks for a window titled with the device name after the
reboot and does that quit-and-relaunch if there is none, re-booting the device first in case the
quit took it down — and it runs before the status-bar override, because a re-boot would clear it.

Honest about the verification: the detection path is confirmed (it correctly reports the window
present), and the manual recovery is confirmed (quit + relaunch did attach both windows). The
recovery *branch* has not run end to end, because the windowless state turned out to be
intermittent and would not reproduce on demand afterward — shutting the device down and booting
it via `simctl` with Simulator running, which is what produced it the first time, gave a window
back every subsequent try.

Everything else held. All 16 light cells now show a legible dark-on-light status bar, which is
the entire reason the previous sweep was discarded. No ghosted iPad Settings, no wrong-element
taps, `Haber` detail in all four `model_view` cells, alpha-free captures, and the settle gate
never once warned. `verify_store_media.sh docs/screenshots/version_2` reports 0 blocking, 0
advisory across all 36.

Two cosmetic things were reviewed and shipped rather than churned. The Spanish `quiz_mid`
keyboard is the English layout, because the simulator's installed-keyboard list is a separate
preference from `AppleLanguages` and the plan only asks that a keyboard be visible. And on iPad
in Spanish, Browse and Models collapse their search field into a magnifying-glass button, because
`Explorar/Modelos/Test/Información/Configuración` is a wider tab bar than the English one — that
is the app adapting correctly, not a capture defect, and it is the same width pressure that made
the iPad tab centers language-dependent back in workaround #18.

The habit that keeps paying off is reading all 36 PNGs. The keyboard-less cell exited 0 and
looked entirely plausible; nothing but a human eye on the image was going to catch it.

## The windowless-simulator fix, ported to all three apps (2026-07-26)

The `version_2` sweep lost one cell to a simulator that was booted but had no Simulator
*window*, and the fix went into `prep_screenshot_sim.sh` because that is where the reboot
that causes it happens. Josh asked whether the siblings would want it. They would, and
answering the question properly changed the shape of the fix.

Neither Conjuguer nor Konjugieren has a prep script at all — it is a Conjugar invention from
earlier the same day. But both drivers carry the identical `ensure_soft_keyboard`, both have
a `quiz_mid` cell that needs the soft keyboard, and both `simctl boot` a cold device from
inside the driver, which is the same call that can come back windowless. Conjuguer is the
more exposed of the two: its playbook prescribes exactly the set-language → shutdown → boot
dance that triggered this, as hand-typed commands with nowhere for a guard to live.
Konjugieren has no status-bar handling whatsoever, which means no reboot step — and also
means its screenshots have been shipping with the simulator's live wall clock, the very
defect Conjugar spent two sweeps eliminating.

The placement question turned out to be the interesting part. Recovery belongs in prep, but
*detection* belongs in the driver, because `ensure_soft_keyboard` is what actually needs the
window and it was the thing emitting a message naming two causes that were both false. So
the check went into all three drivers, inside the existing 3× retry loop, immediately before
the AXRaise — the same position the frontmost guard occupies, for the same reason. The window
list is briefly unenumerable just after Simulator activates, so a pre-loop gate would turn a
transient into a lost cell; inside the loop, a transient recovers on attempt 2 and a real
windowless device burns three attempts, sends zero keystrokes, and says so three times. The
driver does not try to recover, and that is deliberate: recovery means quitting and
relaunching Simulator.app, which is reasonable at reboot time in prep and much too blunt in
the middle of a sweep.

Two porting details were not copy-paste. Conjuguer matches its Simulator window on the full
`$DEVICE` string rather than a family substring — a deliberate difference dating from the day
a stray `iPhone 17` stole its Cmd+K — so its prep script matches the same way. Konjugieren
needed two changes: its sweep sims are *renamed*, so the prep script carries the driver's
hardcoded UDID map rather than resolving by name, and its window check matches the family
substring `iPad`, because the renamed sim's window is titled `Konjugieren iPad Screenshots`
and contains no trace of the `iPad Pro 13-inch (M4)` label the driver takes on `--device`.
Get that one wrong and prep relaunches Simulator on every run while the driver is perfectly
content — a self-inflicted version of the same class of bug.

Verified rather than assumed, reusing the harness idea from the earlier `ensure_soft_keyboard`
port: stub `osascript`, feed it a scripted window list, count raises and keystrokes. Window
present: 1 raise, 1 keystroke, no complaint. Persistently missing: 3 attempts, 0 keystrokes,
three accurate log lines, and the 3× warning, which now names three causes instead of two.
Missing on the first query and present on the second: one log line, then recovery — 1 raise,
1 keystroke. Identical output in all three repos. The first draft of the harness reported the
transient case as a failure, which was the harness's fault, not the driver's: the window query
runs inside a command substitution, so the stub's counter increments were happening in a
subshell and evaporating. Moving the counters into files fixed it. Worth recording because a
stubbed harness that lies to you is worse than no harness.

Then a live `--view quiz_mid` cell in Conjugar against a real Simulator, to check the new
query does not false-positive mid-sweep: no window warning, keyboard present in the capture.
That test PNG was deleted afterward so the reviewed archive stays as reviewed — `version_2`
was already assembled and frozen.

What is still unproven, in all three repos, is the recovery branch. The windowless state was
intermittent and would not reproduce on demand afterward; shutting the device down and
booting it via `simctl` with Simulator running, which is exactly what produced it, gave a
window back every subsequent try. So three apps now carry code whose detection path is
verified and whose repair path has never run. That is worth stating plainly rather than
letting a future session infer from the absence of a caveat that it was tested.

## App Store preview script, ported from Conjuguer (2026-07-26)

`docs/video_script.md` now exists for Conjugar, adapted from Conjuguer's. The scaffolding is
the part that was already hard-won and needed no thought: 32 seconds of footage across five
clips, minus four half-second transitions to land at the 30 the store wants; the preview size
table that is emphatically *not* the screenshot size table (886 × 1920 iPhone, 1200 × 1600
iPad — conflating the two got all four of Conjuguer's 2.0 previews rejected); and a final
`scripts/verify_store_media.sh` pass, which Conjugar already carries verbatim.

What had to change was every number and one whole premise. The counts came from the app
rather than from memory: 4,811 verbs and 102 models read off the `version_2` capture bundle's
own banners (the XML holds 4,815 verb elements — homonyms collapse), 20 entries in
`DisplayTense.conjugatedTenses`, and 50 quiz questions, which I counted out of `Quiz.start`'s
per-difficulty appends and then found confirmed in `Quiz.briefing`'s own copy. Alphabetical
endpoints are abajar and zurrar. The premise that broke is Conjuguer's second clip, which
opens by noting that "Show Compound Tenses" is selected — Conjugar has no such setting, so
that clip just starts at the top of `ser`'s VerbView and the script says explicitly why there
is nothing to set up, so a future reader does not go hunting for a missing toggle. Exemplars
follow the screenshot plan rather than a literal translation of Conjuguer's: `ser` for the
verb detail, `haber` for the model detail, which happens to sit second under the default
Irregularity sort the way `avoir` does in the French app.

One label is a judgment call worth flagging. "Fifty timed questions" is inherited phrasing:
Conjugar's quiz does run a clock and reports elapsed time on the results screen, but elapsed
time does not feed the score — only accuracy, difficulty, and region do. Timed, not scored on
time. If that reads as overclaiming when the preview is actually cut, the fix is the label,
not the app.

Labels are given in English then Spanish, and the script says to shoot the sweep once per
language, matching how the screenshot bundles are already organized. The tutor and the game
are deliberately absent from the five clips; there is no room in 32 seconds, and the cut
Conjuguer proved out is the one to copy first.

## A History of the Spanish Verb System (2026-07-26)

Conjuguer and Konjugieren each carry a `verbHistoryText` essay tracing their language's
verb system from the formation of the solar system to the present, and Josh asked for a
Spanish one. It sits in the About section between Voseo and Credits, as
`L.Info.verbHistoryHeading` / `verbHistoryText`, stableKey `verb_history`, `.easy` like
every other About article.

The two siblings were the model but not the template. Their opening move — supernova
nucleosynthesis, the Yamnaya on the Pontic-Caspian steppe, Proto-Indo-European aspect and
ablaut — is shared inheritance and carries over nearly verbatim, because it *is* shared:
Spanish, French, and German are all downstream of the same steppe. Everything after Italic
splits. The French essay's spine is loss (endings erode, the subject pronoun becomes
compulsory, the passé simple dies); the German one's is Germanic innovation (weak verbs,
the consonant shift, preterite-presents). Spanish needed a third spine, and the app itself
supplied it: the article set has entries the siblings have no equivalent for, and each one
is a historical accident worth explaining.

So the essay is organized to pay off Conjugar's own tense list. Why are there **two**
imperfect subjunctives? Because `cantase` descends from the Latin pluperfect *subjunctive*
and `cantara` from the Latin pluperfect *indicative*, two different tenses that drifted onto
the same job — which is also why journalists still write `el gol que marcara en la final`.
Why is there a **futuro de subjuntivo** nobody speaks? Because it retreated into statutes
and proverbs. Why is there a **raíz futura** at all? Because `cantare habeo` fused into
`cantaré`, and when the two halves ran together fast enough the infinitive's vowel got
squeezed out, propping up `saldré` and `pondré` with an epenthetic d. The Voseo article
directly above gets an explicit handoff: it observes that vos forms do not diphthongize, and
the stress section explains that the vos endings pull stress off the stem so the old
diphthongization law never fires. The distinctively Spanish material — the f- to h- loss on
the Basque frontier that silenced the h of `hacer`, `hablar`, and `haber`; eight centuries of
Arabic that gave four thousand words and left the conjugations untouched except for `ojalá`,
which still governs the subjunctive; `ir` assembled out of three separate Latin verbs — has
no counterpart in either sibling.

Two mechanical things future sessions should know.

**The markup differs from the siblings.** Conjuguer and Konjugieren mark section headings
with backticks; Conjugar's parser wants `^…^`. Emphasis is `~…~`, cross-references and URLs
are `%…%`, irregular spans are `$…$`.

**`parseBodyToSegments` cannot nest inline markers, and fails silently rather than loudly.**
A `$…$` inside a `~…~` clobbers the shared `markupStart` index: the conjugation segment comes
out right, but the enclosing bold then emits its text from the conjugation's start index,
duplicating a run and leaking a literal `$` into the rendered body. The draft hit this three
times, in the future-subjunctive proverbs (`~Adonde $FUeres$, haz lo que vieres~`). Nothing
crashes, no assertion fires, and the markers all balance, so a marker-count check passes
happily. What caught it was porting `richTextBlocks` and `parseBodyToSegments` to Python and
round-tripping the essay: strip the markers from the source, render the parsed blocks, and
compare. The fix is to close the emphasis before the conjugation and reopen after —
`~Adonde~ $FUeres$~, haz lo que vieres~`. Worth doing that round-trip for any long body copy
added here; the existing articles happen to avoid nesting, so the bug had never surfaced.

The `$…$` spans were not eyeballed either. `IrregularityMarker.markedWord` uppercases the
span between the common prefix and common suffix of the real form and its *regular*
composition, so each highlight in the essay was computed the same way the engine computes
it — `$tenGo$` (the g is all that separates it from a regular *teno*), `$habRé$`, `$pUEde$`,
`$FUI$` for the no-common-affix case. The red letters in the essay therefore match the red
letters the reader will see in Browse Verbs for the same form.

`InfoTests` pins the article count, so `.easy` additions bump all three filter tiers: 28 → 29
infos, and 9/17/28 → 10/18/29. The comment there now says why.

The catalog entries are **English only**. Josh asked for a draft he expects to edit, so the
`es` translation waits until the English settles; until then a Spanish run falls back to
English for this one article.

Which raised the obvious problem: 5,500 words on one JSON line is not an editing surface.
So the prose lives in `docs/verb_history.txt` — header block, dashed separator, then the
article verbatim, following the shape `docs/purpose_and_use_proposed.txt` already
established — and `scripts/sync_verb_history.py` pushes it back into the catalog, replacing
just the `en` value line so the diff stays one line and Xcode's formatting survives. The
script is where the nesting rule now lives permanently, alongside three other checks the
parser will not make: markers balance, every non-URL `%…%` names a real article (headings
read out of `Info.swift` for the Spanish tense literals and out of the catalog for the
localized About ones), and no `$…$` span starts with a lone capital, since a capital there
means "irregular, shown red" and would silently redden the first letter of a sentence.
Each validator was negative-tested by corrupting a copy of the file and confirming the
specific message fires. Two sources of truth is a drift risk, but the alternative was
editing JSON by hand, and `--check` makes the drift detectable.

## Fact-checking the verb-history essay with a fan-out (2026-07-28)

The essay shipped, and then Josh asked the obvious next question: is any of it true? The
answer is now `docs/history_corrections.md`. **84 findings kept, 20 of them factual errors,
across all fifteen clusters — and 104 proposed corrections dismissed.** Nothing in the essay
has been changed. The document is a set of proposals with replacement prose; Josh decides
what lands.

The shape of the run matters more than the numbers. The essay was cut into fifteen clusters
**by claim-domain rather than by line count** — cosmos, the steppe, PIE morphology, Latin,
the substrate, the analytic future, the future subjunctive, the -go verbs, Arabic and
Castile, the Americas — and each got a researcher told to check every date, name, etymology
and quoted verb form in its range at ten to fifteen searches. Then every cluster went to a
second agent instructed to **refute** the first one's findings, researching each proposed
correction independently rather than re-reading the researcher's sources.

That second pass is the whole ballgame, and the ratio proves it: **104 of 188 proposals did
not survive.** A fact-checker with a search engine and no self-skepticism will confidently
"correct" a careful hedge into a mistake, and this essay hedges deliberately in a lot of
places. The most instructive single case: the researcher for cluster I flagged "the *Cantar
de mio Cid* is full of such forms" (mesoclitic futures) as a factual error, and it was
graded as one and written into an earlier draft of the document. The adversarial pass
**overturned it** — the charge rested on a corpus sweep that undercounted. It would have
shipped as a correction. Dismissed items are kept per cluster in the document precisely
because knowing what was checked and found sound is as useful as knowing what was wrong.

Sample of what did survive: *taberna* is not an Etruscan loan; Etruscan is not quite a
language isolate as stated; the augment was not PIE's chief past marker; *anduve* **is** an
irregularity Spanish invented, against the essay's claim that the strong preterites are
Latin stress preserved intact; the velar of *tengo* is analogy, not a hardened yod, and
Portuguese *tenho* is the form Spanish threw away; the -go pattern is not "confined almost
entirely to the first person singular", since the entire present subjunctive carries the
same g; Nebrija's grammar has rivals for "first of a living European language"; and the
Isabella-and-the-bishop anecdote is not in Nebrija's prologue.

Operational lessons, since a future session will do this again for Conjuguer and Konjugieren
(prompts are already written at `../Conjuguer/prompts/verify-verb-history.md` and
`../Konjugieren/prompts/verify-verb-history.md`):

- **Workflow `args` did not deserialize.** Paths passed through `args` reached the agents as
  the literal string `undefined`, and one agent wrote a working file into the repo root
  before anyone noticed. Every later workflow embedded absolute paths **inline in each agent
  prompt**. The agents recovered gracefully only because they had been told to report broken
  instructions rather than guess.
- **`CLAUDE_CODE_MAX_WEB_SEARCHES_PER_SESSION` is per session and does not reset with the
  usage window.** The first fan-out exhausted the 200-call default and the remaining
  researchers silently ran dry. Restarting with it set to 600 was the fix.
- **The resume cache is same-session.** The run was stopped twice on cost and resumed once
  across a quit; rather than gamble on a cross-restart cache replaying seven finished agents,
  the completed output was dumped to `~/Desktop/workspace/verb-history-check/leads-*.json`
  and a fresh workflow ran only the nine agents that never completed. Cheaper and
  deterministic.
- **Generate the deliverable, don't transcribe it.** `scratchpad/gen_corrections.py` builds
  the 56,000-word document by merging the four workflow journals, so quotes and citations
  come straight from the agents' structured output. It also rewrites its own framing based on
  what is actually complete — the three-tier confidence preamble and the "Outstanding work"
  section disappear on their own once nothing is left unverified.
- **Give the app-internal agent an explicit clean-tree assertion.** It stands up a temporary
  Swift Testing file to run the real engine against the essay's `$…$` spans, and twice left
  it behind until the prompt named the three files allowed to be dirty.

Narrative notes toward a blog post about the ultracode experience itself are in
`~/Desktop/workspace/ideation/ultracode-verb-history-fact-check.md`.

## Verb history: apply the fact-check's errors and hedges (2026-07-28)

Applied every finding `docs/history_corrections.md` graded **factual error** (20) or
**needs hedging** (24) to `docs/verb_history.txt`. The 40 nitpicks were deliberately left
for Josh to rule on. The suggested revision was the default in every case and none of them
had to be departed from; the corrections document had already been through an adversarial
pass that rewrote the fixes it found faulty, so what was left was directly usable prose.
Whoever writes the sibling apps' version of this should note that the *fixes* needed as much
review as the findings, which is where the second pass earned its keep.

Four spots were resolved as a single edit rather than two, because the document files by
line and quote and some lines carry more than one finding:

- **line 160** — `$dIJeron$` is not stem-stressed and `anduve` is exactly the irregularity
  Spanish invented. One rewrite swaps in `$dIJE$`, softens "That is not an irregularity
  Spanish invented" to "Mostly that is not", and adds the `andUVE`/`~andé~` sentence.
- **line 172** — the `-eo` road into the `-go` verbs does not exist (Portuguese `tenho` is
  the expected outcome Spanish threw away), and the velar runs through the whole present
  subjunctive rather than hiding in the first person singular. Both land in one paragraph,
  which now names `%presente de subjuntivo%` as a tappable term.
- **line 196** — Nebrija's grammar is the first *printed* of a living European language, the
  companion-of-empire line is Nebrija's own rather than the bishop of Ávila's answer, and
  Alfonso X finished a chancery shift Fernando III had begun.
- **lines 104 and 219** — "took two hundred years more" and "stayed four hundred years" are
  the same claim about the Roman presence. Only 219 changed, to "six hundred years"; 104's
  "in all" rewording is a nitpick and would have been a second edit for one fact.

Two of the nitpicks turned out to be consequential rather than optional, because applying a
finding elsewhere left them out of step with the corrected text, and Josh accepted both on
the spot: "supernova-gifted" at line 32 echoed the single-source attribution the line 30 fix
had just removed and became "star-forged", and "one pronoun was left behind" at line 219
re-asserted the vosotros error that line 200 no longer makes and became "was later
abandoned". The corrections document says in as many words that the second stands or falls
with line 200. Worth remembering for the sibling apps: a severity grade describes a finding
in isolation, and a nitpick can be promoted by an edit made three sections away, so the
dependency notes buried in the verification paragraphs are the ones to read before deciding
what to skip.

Checked marker balance, nesting and section count by hand (25 sections, no nested `$…$`
inside `~…~`) rather than running `scripts/sync_verb_history.py`, which is Josh's to run
after he has hand-edited the file and ruled on the nitpicks. The one em-dash in the body,
at line 44, is pre-existing prose and was left alone.

Josh then took the whole nitpick tier except two, so 36 more edits landed in a second pass.
The two declined are the ones the corrections document itself was least sure of: hedging
"which the Romans took from the Carthaginians" to "most likely took", which the adversarial
reviewer graded low-confidence and leaning-refuted, and rewording line 104's "two hundred
years more" to "in all", which was already resolved by the line 219 fix and would have been
a second edit for one fact.

Three of the accepted nitpicks needed care beyond transcription:

- **The corrections document contains a typo in one of its own revisions and says so.** The
  voseo endings fix prints "-és beside -és"; the verification paragraph directly underneath
  warns that the second member is "-éis" and that an editor copying the line should check the
  diphthong survives. Applied as "-és beside -éis". A fact-check document is still prose
  written by an agent, and the place it is likeliest to slip is inside a quoted paradigm.
- **The Arabic word-count fix was relocated rather than dropped in place.** As proposed it
  read "somewhere between two and four thousand words from it, depending on who counts
  derivatives and place names, among them ~aceite~ …", which garden-paths into reading
  ~aceite~ as a place name. The count and the caveat both survive; the caveat became its own
  short sentence after the list.
- **The macron fix at line 70 is deliberately incomplete.** `~egi~` and `~feci~` became
  `~ēgī~` and `~fēcī~`, but `~Feci~ became $hICE$` two sentences later is untouched, and so
  are `~cepi~` at line 90 and `~amabo~`/`~amatur~` at line 96. The document calls that a
  copy-edit decision rather than a correction, on the reasoning that quantity is marked where
  the argument turns on quantity and line 70 is the only sentence where it does. Flagged for
  Josh rather than silently extended.

The body's one em-dash, at line 44, predated
all of this and was split into two sentences rather than recast with commas, since the
surrounding prose already leans on short declaratives.

Running total: 44 findings plus 38 nitpicks applied, 2 nitpicks declined, essay unvalidated
by `scripts/sync_verb_history.py` because Josh runs that himself after his own hand-edit.

### Finishing the `$…$` sweep the fact-check only gestured at (2026-07-28)

Cluster P's line 180 nitpick fixed `ir`'s present but noted in passing that two neighbouring
sentences "take the same repair" without ever writing revision prose for them. Deciding what
to do needed a rule, and the rule turned out to be already latent in the essay and in the
cluster's own six dismissals:

> A form cited **as a paradigm slot** carries engine marking. A form inside a cited phrase
> (`~ojalá venga~`, `~he escrito~`, `~es venido~`), one column of a parallel (`~he~, ~has~,
> ~ha~` against `~cantaré~, ~cantarás~`), or a **discursive mention** in running prose stays
> in plain `~…~`.

That rule settles the cases the document argued about individually, and it also explains why
`~fui~` at the end of line 180 and `~Fui~` at line 219 are correctly plain while `$FUI$` ten
words earlier is red: the first two are mentions, the third is a paradigm citation. Not the
same defect as the `$FUere$`/`$vIniere$` inconsistency at 150 against 152, where both
instances were citations.

Rather than guess the spans, the forms went through the real engine, reusing cluster P's
method: a throwaway Swift Testing suite calling `TenseBridge.conjugate`, the same call
`VerbView.swift:318` makes, then delete and assert `git status` is back to the expected
files. Two notes for the next session that does this. First, `print()` inside a Swift Testing
test is not recoverable from the run: xcbeautify drops it, `xcresulttool get log --type
console` fails on this toolchain's bundle, and an `#expect(Bool(false), "…")` comment string
is not echoed either. What does work is putting the payload in the *expression*, as
`#expect(dump == "SHOW_ME")`, because the failure line prints the evaluated subexpression.
Second, SourceKit spends the whole exercise insisting `No such module 'Testing'`, which is
the usual stale-index noise; `run_tests.sh` compiled and ran the file without complaint.

The engine's answer improved the edit. `ser`'s `seré` and `siendo` and `ir`'s `iré` come back
**unmarked**, so their plain type was already principled rather than an oversight, and the
only addition to that sentence is `$sEa$`. The mixture in "the infinitive ~ser~ itself, along
with ~seré~, $sEa$, and ~siendo~" is now meaningful in exactly the way `~cantare~` staying
plain beside `$FUere$` and `$vIniere$` is. The rest went as the evidence block predicted:
`$ES$`, `$sOn$`, `$ERes$` beside the existing `$ERa$`, and `$FUiste$`, `$FUE$` beside `$FUI$`.

Worth remembering: a nitpick that says two neighbours "take the same repair" is not a spec.
Half the value here came from running the engine instead of transcribing the rationale, since
three of the six candidate forms turned out not to need touching at all.

### Sweeping vowel quantity across every Latin citation (2026-07-28)

Cluster D's line 70 nitpick added macrons to `~ēgī~` and `~fēcī~` on the narrow principle
that the essay marks quantity where the argument turns on quantity. Cluster F, declining the
same fix for `~cepi~` at line 90, called extending it "a copy-edit decision rather than a
correction." Josh took the wider option, so all 36 remaining Latin citations were swept.

The interesting consequence is that the sweep **inverts what silence means**. Before it, an
unmarked Latin vowel said nothing; the essay simply wasn't in the business of marking length.
After it, an unmarked vowel asserts shortness, which is a claim the text is now making about
`~agere~`, `~facere~`, `~esse~`, `~ferrum~`, `~canis~`, `~Satelles~`, `~Populus~`, `~flamma~`,
`~factum~` and `~noctem~`. All of those are genuinely short and the claim holds. The one that
does not is `~arrugia~`, Pliny's mining word, which is pre-Roman and whose quantities are not
attested anywhere; it is left bare and is the sweep's single overclaim. Worth knowing before
the sibling apps run the same exercise: a consistency pass on notation is not cost-free, it
converts absence into assertion.

Scope drawn at **Latin forms cited as words**, meaning etyma and paradigm forms. Excluded:
narrative place names (`~Latium~`, `~Carthago Nova~`), grammatical labels functioning as
English (`~infectum~`, `~perfectum~`), titles (`~Appendix Probi~`), the taxonomic
`~Homo sapiens~`, and everything non-Latin. Two of those exclusions are invisible because the
words happen to be short anyway, `Lătium` and `Homo sapiens` by convention; two would visibly
change if Josh later widens the scope, `Carthāgō Nova` and `Appendix Probī`.

A note on method, since this is the kind of edit where a single wrong macron is worse than
none. Thirty-six replacements is too many for individual Edit calls, so it went through one
Python pass that asserted every search string occurs **exactly once** before writing anything,
which is what keeps a bare `~vos~` replacement from hitting the four Spanish `~vos~` spans on
lines 168 and 202. Only the one explicitly labelled "Late Latin ~vos~" became `~vōs~`.
`~cantare~` at line 150 is likewise Spanish, the futuro de subjuntivo form, and a careless
global rule would have Latinized it.

The convention went into the file header, but not under its existing "Three rules the app
will not warn you about, all checked by the sync script" list, because the quantity
convention is precisely the thing the script does not check. Filing it there would have made
that preamble false. It sits in its own block headed "One convention the sync script does NOT
check, so nothing will catch a slip."

Adding it had a consequence worth recording, because it will bite the sibling apps too:
**the header is above the body, so growing it renumbers the entire article.** The block cost
17 lines, which means every line citation in `docs/history_corrections.md` now points 17
lines high. The first draft of the bullet cited "line 166" and "line 150" for its own
examples and was stale the moment it was written; those became positional references to the
section titles instead. The corrections document was deliberately left alone rather than
renumbered, for two reasons: it quotes the offending text above every finding, so the quotes
still locate everything, and `scratchpad/gen_corrections.py` regenerates the file from the
workflow journals, so a hand-edit would be overwritten. The header now says so.

The general lesson for anything that cites line numbers into a file it also lives in: cite
by quote, or keep the citation and the target in different files.

### A pronoun sweep, prompted by an aside about "it" (2026-07-28)

Josh mentioned in passing that he watches for overused "it", having known a legal-writing
professor who banned the word outright on clarity grounds. A blanket ban is the wrong tool,
because it conflates referential "it" with dummy "it" ("it should be said", "it is this
system that"), and this essay's best sentences lean on the good kind: "It is a sound law
caught in the act", "It is a map of where the stress falls", and the Castile anaphora, "It
lost initial f-. It turned Latin pl-, cl-, and fl- into ll-. It turned -ct- into -ch-." Those
three were explicitly left alone.

Of 83 instances in the body, nine were worth fixing, in three grades. Contestable antecedent:
the Nebrija beat, where the line 196 correction had put two candidates in front of an "It"
that previously had one, plus a trailing "it" in the same sentence, now "The bishop was
unusually candid about what a grammar book is for, and events did not contradict him";
"Latin buried nearly all of it", which reached back across a paragraph break to "a linguistic
thicket"; "most of it kept the monophthongs", a partitive resting on a pronoun; and "It is the
oldest account", whose nearest noun was the adverb rather than the account. Paragraph-opening
"It", clear but reachy: "It kept one fossil" and "It did not disappear, though". Density
rather than ambiguity: three "it"s in twenty words in the Italo-Celtic sentence, the
"which makes it look like" whose antecedent Josh's own edit had pushed further away, and
"Formal Portuguese does it to this day".

Four of the nine were prose written in this session rather than Josh's original, which is
about the rate to expect when splicing corrections into an established voice: a correction is
written to be locally true and is not always written to be locally clear, and a pronoun that
was unambiguous before an insertion may not be after it. The Nebrija case is the sharpest
example, since the ambiguity was noted when the correction was applied and left standing on
the grounds that both readings were true. True and clear are different tests.

Count went 83 to 73. The sweep changed no facts, so nothing in `docs/history_corrections.md`
is affected.

**Follow-up, same day.** Josh caught a real constraint the header had only gestured at. The
`$andUVE$` sentence added by cluster K's correction opened with a `$…$` span, and a span can
never open a sentence when its first letter is irregular: sentence position demands a capital,
and inside `$…$` a capital *is* the irregularity encoding, so the capital would render as one
more red letter and claim an irregularity the form does not have. The sentence became "The
exception in that list is $andUVE$, which Spanish built for itself…", which also fixes a vague
"the one" and, incidentally, scopes the claim properly: Spanish remodelled the strong class
more widely than this one verb, so "the one Spanish built for itself" read as a universal
would have overclaimed. Tying it to the six forms just cited keeps it true.

The header bullet said only "Never capitalize a sentence-initial word there," which states the
symptom without the mechanism and does not tell you what to do. It now distinguishes the two
cases: a span whose first letter is irregular cannot lead a sentence at all and the prose must
be recast, while a span whose first letter is regular may lead and renders lowercase, which is
deliberate rather than a typo. An audit of the body finds exactly one span that genuinely opens
a sentence, `$pUEdo$`, and it is the safe kind. The check is cheap enough to be worth rerunning
after any edit that moves a marked form to the front of a sentence.

## The Verb History Goes to Spanish (2026-07-28)

The verb-history essay shipped in English only, and worse, the copy in the string catalog was
the *pre*-correction draft: 34,961 characters against the corrected file's 38,746. So step one
was not translation at all but noticing that `sync_verb_history.py` had not been run since the
fact-check landed. It is now, and the lesson is that a script whose whole purpose is to keep two
representations in sync is worthless if nobody runs it after the interesting edit. A pre-commit
hook would have caught this; a note in the plan caught it instead.

**Teaching the script a second language.** `write()` used to find the `"en" : {` line by scanning
a fixed eight-line window after the key and then replace the one `"value" : ` line beneath it.
That is fine when the localization is guaranteed to exist. It is useless for `es`, which did not.
The rewrite walks the `"localizations"` block by indentation, collecting `(lang, first, last)` for
each child, and then either replaces the value line or splices a whole new block in alphabetical
position — because Xcode sorts localizations, and a hand-placed `es` before `en` would get churned
on the next save. The comma bookkeeping is the fiddly part: the block before the insertion point
has to gain a comma, and the inserted block only ends without one if nothing follows it. Both
branches are exercised; `--lang en` round-trips byte-identically, which is the regression test.

`headings()`, which builds the legal set of `%…%` targets, now follows `--lang` for the localized
half. This changes nothing today, since all 11 link targets in the essay resolve to Spanish string
literals in `Info.swift` rather than to localized headings. It would matter the moment somebody
links the essay to an About article, and the failure mode without it — validating Spanish prose
against English headings — is the silent kind.

**What the translation had to preserve.** The 58 `$…$` irregularity spans and the 14 `%…%` links
are character-identical across the two languages, verified by comparing multisets rather than
counts. That is not a discipline imposed on the translation; it falls out of what those markers
contain. The spans are Spanish verb forms with `IrregularityMarker`'s per-letter uppercase
encoding, and the links are Spanish tense names pointing at Info articles. Only the prose around
them is English. Twenty-five headings on both sides, 94 paragraphs on both sides, and 41,848
characters of Spanish against 38,746 of English — a 1.08 ratio, right in the middle of what the
sibling articles run.

The one rule that genuinely needed re-checking in translation is that a `$…$` span whose first
letter is irregular can never open a sentence, because Spanish word order moves things around.
A throwaway script found zero violations, but only because the risky spans were consciously kept
mid-sentence: "La excepción de esa lista es $andUVE$", "Luego están los cuatro verbos que terminan
en una letra que significa ‘allí’: $soY$, $doY$, $estoY$, $VOY$".

**What did not survive contact with Spanish: the glosses.** The English body carried 47
single-quoted glosses; the Spanish carries 35. Sorting them by the language of the *glossed* form
does all the work. A Latin or Arabic form glossed in English simply changes target language —
`~agere~, ‘to drive’` becomes `~agere~, ‘conducir’`. A Spanish form glossed in English is a
different animal, because glossing Spanish into Spanish is either tautological or faintly
insulting. `~vuestras mercedes~, ‘your graces’` needs nothing. The two futuro-de-subjuntivo
proverbs need nothing; a Spanish reader parses `~Adonde~ $FUeres$~, haz lo que vieres~` without
help. The better move, wherever the form is archaic, is to replace the translation with a modern
equivalent, which is *more* informative than the English gloss was: `~dar vos he~, ‘os daré’`,
`~es venido~, ‘ha venido’`, `~son idos~, ‘se han ido’`. The archaism is the point of the sentence,
and putting the modern form beside it shows the reader exactly what changed.

`~Hay~, ‘there is’` was the awkward one, because the gloss sets up the ~ibī~ fossil two clauses
later and could not simply vanish. It became a recast: "Es decir que ~hay~ dice, literalmente,
‘ha allí’", which keeps the etymological payload and drops the tautology. Same trick at the end
of the ~ir~ paragraph, where `~fui~` glossed as both ‘I was’ and ‘I went’ would have been circular
in Spanish; it became "~fui~ vale a la vez para el ser y para el ir, y solo el contexto puede decir
cuál de los dos es".

A note for anyone extending the plan's invariant table: it predicted the `~…~` emphasis count would
*fall* as glosses were dropped. It rose by one, 321 to 322, because glosses are delimited by curly
quotes, not tildes. Dropping a gloss removes no emphasis span at all.

**Register.** Josh settled this before the session: keep the learner framing, drop the presupposition
that the reader *is* a learner. The essay was already built that way — its learner references are
third person ("la razón de que un estudiante tenga que memorizar…") and most of its second person is
generic-speaker or app-user address. The app's existing Spanish is impersonal with light *usted*, so
the translation matches: "Si las dos formas le suenan sutilmente distintas, no se lo está imaginando",
"Recuerde esa pequeña ~y~", and the closing "Cuando conjuga un verbo español, cuando dice ~hablo~…".
One passage was deliberately generalized rather than kept in the second person: "~hoy he comido~ is
what you say about lunch" became "es lo que se dice del almuerzo", because the sentence is about a
line that falls in different places on two continents and the impersonal does not seat the reader on
one side of it.

The ablaut section's "the pattern still audible in English sing, sang, sung" was kept, since it is
doing comparative-linguistic work rather than assuming an anglophone, but it now names the alternation
for a reader who does not hear it: "donde la vocal de la raíz, y solo ella, marca el tiempo".

**Verified on device.** Both languages read end to end in the simulator, with the red irregularity
letters rendering (sal**d**ré, pon**d**ré, hab**r**é, d**i**ré, ha**r**é in one paragraph), no stray
`$` or `%` anywhere — a stray marker means the parser gave up, which it does silently — and four link
taps confirmed landing on the right article: `%futuro de subjuntivo%` in English, and `%voseo%`,
`%raíz futura%`, `%imperfecto de subjuntivo 1%` in Spanish. Launching the simulator in Spanish is a
one-liner worth remembering: `xcrun simctl launch "$UDID" biz.joshadams.Conjugar -AppleLanguages '(es)'
-AppleLocale es_ES`.

## video_script.md gains the simctl recording commands (2026-07-30)

Work started in the sibling app Conjuguer, where Josh asked which simulator to record
app-preview clips on. Conjuguer answers that in `docs/app-store-preview-videos.md`;
Conjugar has no such document, so its `video_script.md` — already an adaptation of
Conjuguer's — is now the single place the recording procedure lives, with a pointer back
to the sibling doc for the narrative.

Added: the device table (`iPhone 17 Pro Max` → 1320 × 2868 for the 886 × 1920 project,
Spatial Conform **Fill**; `iPad Pro 13-inch (M5)` → 2064 × 2752 for 1200 × 1600, exactly
3:4), a UDID resolver, build/install/launch by explicit destination (the
`ios-build-verify` config is pinned to `iPhone 17`, so the recording devices need one),
the `prep_screenshot_sim.sh` language/status-bar pass for the en/es double sweep, the
`recordVideo` invocations, and an `ffprobe` size check.

UDIDs are resolved by name rather than pasted — Konjugieren's screenshot driver already
demonstrates the rot, hardcoding a UDID under the label `iPad Pro 13-inch (M4)` for a
device since renamed `Konjugieren iPad Screenshots`:

```bash
udid() { xcrun simctl list devices available | sed -n "s/^ *$1 (\([0-9A-F-]\{36\}\)) .*/\1/p" | head -1; }
```

Tested, including the prefix hazard: `iPhone 17` is a prefix of `iPhone 17 Pro Max`, and
the trailing ` (` in the pattern keeps them distinct.

Two flags that aren't defaults: `--codec h264` (simctl defaults to HEVC) and `--mask
black` (otherwise the unmasked framebuffer is written; Apple rejects alpha).

One local addition worth keeping: the `-AppleLanguages '(es)' -AppleLocale es_ES` launch
trick recorded in an earlier entry is now in the script, but explicitly scoped — it
switches the app without a reboot, which is fine for rehearsing a clip and wrong for a
take, because the status bar stays in the old language and on iPad renders a date.

**Follow-up the same day: rewritten around hand recording.** Josh records by hand rather
than from the shell, and asked whether the invocation affects App Store Connect at all or
whether conformance is purely post-processing. Purely post — only two capture-time facts
matter, and neither is a flag: *which device* you record (that fixes the native pixel size,
hence the aspect and the Spatial Conform) and that the capture is the device framebuffer
rather than the Mac screen. Everything ASC enforces — 886 × 1920, SAR 1:1, H.264 High
≤ L4.0, ≤ 30 fps, 15–30 s, an AAC track — is imposed by Final Cut and the export, and the
master violates nearly all of it by construction (Simulator writes HEVC, variable frame
rate up to 60, at native size).

The section is now: `open -a Simulator`, Run from Xcode to install,
`prep_screenshot_sim.sh` for the en/es language + 9:41 pass, then **Simulator ▸ File ▸
Record Screen** / **Stop Recording** (both menu items verified present in Xcode 26.3 by
reading `Simulator.app/Contents/Resources/Base.lproj/MainMenu.nib`). `simctl io recordVideo`
remains as one sentence, framed as scriptable-but-equivalent, and the `-AppleLanguages
'(es)'` launch trick keeps its rehearsal-only scoping.

One hazard specific to the hand path is now called out: **macOS screen recording is the
trap**. ⌘⇧5 or QuickTime ▸ New Screen Recording aimed at the Simulator *window* captures
at point size × display scale with chrome baked in, roughly 860 × 1864 instead of
1320 × 2868, unrecoverable without upscaling — Simulator's own Record Screen is
framebuffer-based and immune.

A second warning — that a silent capture carries no audio stream, which
`verify_store_media.sh` grades as blocking — was written and then cut at Josh's direction:
the previews always carry a music track and he always exports video and audio. The check
is real; the scenario isn't.

**Correction, from real captures in the sibling app.** Conjuguer's five English iPhone
clips were recorded with Simulator's built-in Record Screen, and probing them disproved a
claim I had asserted in all three scripts without checking: the recordings are **H.264
High, Level 5.0**, not HEVC. The HEVC default belongs to `simctl io recordVideo` (per its
`--help`); the GUI recorder differs. Corrected here too. The rest matched the playbook
exactly — native size, SAR 1:1, no audio track, variable frame rate with static stretches
that carry no frames at all, which is capture working as designed rather than a fault.

## The Browse tab becomes Verbs (2026-08-01)

A one-word rename with a long tail. Conjugar's first tab had always been **Browse** (es
*Explorar*), but the sibling apps Konjugieren and Conjuguer both call theirs **Verbs**
(`Navigation.verbs` → de *Verben*), and the noun beats the verb: the other four tabs are
nouns already (Models, Quiz, Info, Settings), and "Browse" reads as an instruction sitting
in a row of labels. So: en **Verbs**, es **Verbos**, matching how the siblings translate it.

The label itself is one catalog value, `BrowseVerbs.localizedTitle`, which feeds both the
tab and the screen's `navigationTitle`. The interesting part was everything that *names*
the tab in prose. Conjugar's Info bodies talk to the reader about navigation constantly —
four tense articles end with "Tap the ~Browse~ tab for translations and conjugations", the
Purpose-and-Use article lists all five tabs, gives Browse its own `^Browse^` section
heading, and mentions the tab three more times, the FAQ answers a question about "the
~Browse~ list", and Terminology says dictionaries and "~Conjugar~'s Browse tab" list
infinitivo forms. Seventeen values in all, en and es, every one of them updated.

Two occurrences were deliberately **left alone**, and they are the reason this wasn't a
blind find-and-replace:

- Purpose-and-Use's "In the ~Browse~ section, tap ~Vos~…" refers to the *Settings* card
  titled "Browse Tú and/or Vos" (`Settings.browse`), not to the tab. The Spanish text makes
  this obvious — it quotes the card by name, `"Explorar Tú y/o Vos"` — but the English
  sentence goes on to say "…on the ~Browse~ and ~Models~ tabs" eleven words later, where
  the *same word* does mean the tab. One sentence, two referents, one renamed.
- Onboarding's `browseTitle` / `browseVerbsButton` ("Browse 4,811 Spanish Verbs", "Browse
  Verbs") are verb phrases, not tab names. Konjugieren keeps `Onboarding.browseVerbsButton`
  = "Browse Verbs" alongside its "Verbs" tab, so Conjugar matches.

Identifiers stayed put by design, at Josh's instruction for the view and by the usual
wire-name rule for the rest: `VerbBrowseView`, the `L.BrowseVerbs` scope and its catalog
keys, the `.viewVerbBrowseView` analytics case (renaming it would orphan its dashboard
history), the `browse_verb_count` accessibility identifier that `ios-build-verify` uses as
its launch anchor, and `tap_tab.sh browse`. Only `VerbBrowseView.englishTitle` — an
unreferenced English-name constant each screen carries — moved to "Verbs".

Mechanically, the catalog edit went through `python3` with `json.dump(indent=2,
separators=(',', ' : '))`, which round-trips Xcode's formatting exactly: `git diff
--numstat` came back **17 insertions, 17 deletions**, no reflowed neighbors. Each
replacement asserted `count(old) == 1` first, so an ambiguous match would have failed loudly
rather than silently hitting the wrong sentence. Build succeeded; the simulator shows
**Verbs** in both the tab bar and the large title.

## Re-shooting the App Store screenshots after the Verbs rename — and the day Cmd+K died (2026-08-01)

The Browse → Verbs tab rename (`37368a1`) invalidated every one of `version_2`'s 36 App
Store screenshots: the stale label is in the tab bar of all of them, and in the large title
of four. So: another full sweep, the fourth, shipped as `docs/screenshots/version_3`.

Two changes went in before the first cell ran. `docs/screenshot-plan.md` names the **iPad Pro
13-inch (M5)** and Josh had just installed that simulator, so the driver moved off the M4 —
a rename in six `case` arms (`DEVICES`, `tab_coords_for`, `wait_budget_for`,
`keyboard_is_visible`, `ensure_soft_keyboard`, `dismiss_review_prompt`) and nothing more,
since the two devices share the 13-inch geometry and the same 2064×2752 capture. The other
was mundane: `OnboardingDisplay.onboardingEnabled` was still `true` in the working tree while
the other two kill switches were already off. And one environment fix that turned out to
matter later — two iPhone simulators were booted, which makes `ensure_soft_keyboard`'s
`first window whose title contains "iPhone"` ambiguous (workaround #10), so the spare got
shut down.

Then the interesting part. The first cell of the sweep logged `soft keyboard still not
visible after Cmd+K` and `quiz_mid` came out keyboard-less — the same *symptom* as workaround
#24, with none of its causes: permission granted, Simulator frontmost, window present.
Driving Simulator's menu bar by hand showed why. **Cmd+K ("Toggle Software Keyboard") does
nothing on this toolchain** (Xcode 26.3) while a hardware keyboard is attached; clicking that
menu item directly is equally inert. What actually governs the keyboard is
**I/O ▸ Keyboard ▸ Connect Hardware Keyboard** — iOS hides the software keyboard for exactly
as long as one is attached, and unchecking it raises the keyboard instantly.

That fix then broke the paste, which is the part worth remembering. Every quiz answer goes
through the pasteboard because `axe type` has no keycode for `é` (workaround #5 — still true:
`axe type "habré"` fails outright). But axe injects Cmd+V as **hardware** key events, and the
device ignores those while the hardware keyboard is detached. So the two requirements are
mutually exclusive at any instant: pasting needs it attached, photographing the keyboard needs
it detached. Detaching doesn't disturb the field, so the driver now *orders* them —
`set_keyboard_state hidden` → paste → `set_keyboard_state visible` → capture — and
`nav_quiz_results`, which submits twelve answers and never photographs a keyboard, holds
`hidden` throughout. Each state verifies by asking the screen rather than by reading the menu's
checkmark, which is only readable while the menu is open; that also makes it idempotent across
cells.

A third defect fell out of the second: with the keyboard up, the driver's
`tap_id input_quiz_conjugation` was tapping a field that already had focus (QuizView
auto-focuses after Start), and iOS answered with a **"Paste | AutoFill" edit callout** that
both swallowed the Cmd+V and sat in the middle of the screenshot. The tap is gone from both
quiz recipes now, and `paste_into_quiz_field` confirms the field holds the answer before
moving on — which in `nav_quiz_results` guards something worse than a bad picture, since a
silently missed paste desynchronizes every later answer from its question. One wrinkle found
while writing that check: an empty answer field reports its **placeholder** (`conjugation`) as
its `AXValue`, not `""`, so the test compares against the expected answer rather than testing
for emptiness.

Three iterations, each verified by a re-shot cell rather than by reasoning — which is the only
reason the second and third defects were caught at all, since both produced plausible-looking
PNGs and an exit code of 0.

The rest was quiet. 36 cells, all reviewed by eye; `verify_store_media.sh` reported 0
blocking, 0 advisory. One cell needed a re-shoot for a reason the driver got *right*: iPad/es
`quiz_mid` twice logged `frontmost is 'Safari'` and then `'Code'` and refused to send the menu
click — workaround #10's frontmost guard, correctly declining to fire a click into whatever
app Josh was using at that moment. It landed on the third try. Both known cosmetic quirks were
re-reviewed and deliberately shipped again: the Spanish `quiz_mid` cells show an English
keyboard layout (`AppleKeyboards` is a separate preference from `AppleLanguages`), and the
iPad's Spanish Browse/Models screens collapse the search field to a magnifying glass because
the Spanish tab labels are wider — adaptive layout, not a capture defect.

## The kill switches move out of ConjugarTips.swift (2026-08-02)

A small filing change with a documentation tail. The three screenshot kill switches —
`TipDisplay.tipsEnabled`, `OnboardingDisplay.onboardingEnabled`,
`TutorDisplay.tutorUnavailableRowEnabled` — had all accreted into
`Conjugar/Models/ConjugarTips.swift`, for no better reason than that the first of them
genuinely belonged there. `TipDisplay` is about TipKit, so it moved in with the four `Tip`
structs; then onboarding needed the same mechanism and was described in its own doc comment as
"mirroring `TipDisplay.tipsEnabled`", so it landed next to the thing it mirrored; then the
tutor row followed the same logic. By the third one the file's name had stopped describing
half its contents, and an operator looking for the onboarding switch had to already know it
lived in a file about tips. They now live in `Conjugar/Utils/KillSwitches.swift`, moved
verbatim — same three enums, same doc comments, no behavior change and no logic touched.

The move itself was free: `Utils/` is a `PBXFileSystemSynchronizedRootGroup`, so the new file
joined the target without a `project.pbxproj` edit, and the build confirmed it. (Xcode's
SourceKit index, predictably, spat eight `Cannot find 'L' in scope` errors at the *untouched*
remainder of `ConjugarTips.swift` the moment its header comment changed. Same false positive
the project notes already warn about; `xcodebuild` compiled it clean.)

What actually took the work was everything pointing at the old path. Seven references in
`docs/screenshot-playbook.md`, one in `CLAUDE.md`, one in the moved-from file's own header. Two
of the seven were the interesting ones, because they were *executable*: the playbook's
before/after `sed -i ''` incantations that flip all three switches. Those would not have
errored after the move — `sed` on a file that no longer contains the pattern succeeds and
changes nothing — so the failure mode was a screenshot sweep run with all three switches
silently still `true`, which is exactly the class of bug the playbook's own gotcha list already
records happening (2026-07-26: a tip card in the frame; a later entry: `onboardingEnabled` left
`true` in the working tree). Worse, the line right after them is
`git diff --stat <file>   # must be empty when you are done`, the restore check — pointed at
the old path it would have reported empty for the most vacuous possible reason, an all-clear
that confirms nothing. A stale path in prose is a nuisance; a stale path in a verification
command is an actively lying test.

Deliberately left alone: the seven hits in this file. They were accurate when written, and
rewriting them would erase the record of where the switches used to be — which is the whole
point of a dated journal. `scripts/take_screenshots.sh` needed nothing either; it names the
switches but never their file, which in hindsight is the more durable way to write a comment.

Also folded in here, from the same session: `docs/video_script.md` picked up a pre-flight
paragraph before the clip list (language/region set to English/US or Spanish/Spain, hardware
keyboard disconnected, kill switches `false` — now naming the new full path) and four small
clip-direction corrections learned from actually recording them. Clip 2 lost a parenthetical
about Conjugar having no compound-tense toggle, which was reassurance aimed at someone
cross-reading Conjuguer's script rather than a direction. Clip 3's "slowly scroll down for
three seconds" became "slowly scroll conjugation table (iPhone)" — the useful instruction is
*what* to scroll, not for how long. Clip 5 now parks *Presente de Indicativo* near the top of
the screen rather than centered, and scrolls to the bottom rather than vaguely "down."

## Consuming ios-build-verify without a hand-made symlink (2026-08-02)

Fixing the kill-switch doc references surfaced a bigger problem: the build command
`CLAUDE.md` documented did not work. `~/.claude/skills/ios-build-verify/scripts/build_app.sh`
resolved to nothing, because the symlink it depended on had silently vanished. Seven
references in `CLAUDE.md` pointed through that link.

The interesting part is that the project had *already* solved this, twice, and forgotten to
tell `CLAUDE.md`. `scripts/take_screenshots.sh` has a `resolve_ibv_scripts()` that searches
`~/.claude/plugins/marketplaces` and carries a comment explaining that the versioned plugin
cache holds several releases at once, is shared across the other apps, and is enumerated by
`find` in unspecified order — so a broad `~/.claude` glob once picked an arbitrary release to
build App Store screenshots with. `docs/screenshot-playbook.md` documents the same one-liner,
and Konjugieren's `CLAUDE.md` carries it verbatim. Only this file was still on the symlink.

The symlink was worse than it looked. The skill documents three install shapes; this was a
hybrid of two — a manual-install *path* (`~/.claude/skills/…`) pointing into the *versioned
cache* (`…/cache/ios-build-verify/ios-build-verify/0.3.2/…`). So it pinned 0.3.2 and needed
re-pointing on every release, and since `~/.claude/plugins/.last_inuse_sweep` suggests unused
cache versions get collected, the eventual failure mode was worse than the one just hit: once
the sibling apps all move to 0.3.3, the pinned directory can disappear and leave a *dangling*
link, which fails more confusingly than a missing one.

Its one real virtue was that `~/.claude/skills/` registration is what puts the skill in the
Skill-tool listing — and `installed_plugins.json` showed why that mattered here: the plugin was
installed at project scope for Konjugieren, Calculator3, and Conjuguer, but **not** for
Conjugar.mig, which was reaching it entirely through the link. `claude plugin install` fixed
that properly. Worth noting it landed at **user** scope, not the project scope the siblings
use — that is the CLI default, and arguably the better shape, since it covers every iOS
project including the next one, from a single record.

That left the real question, which is why the setup was awkward to begin with: the skill is
developed at `~/Desktop/workspace/ios-build-verify` but consumed from GitHub, so both the cache
and the marketplace clone hold the *published* code. Testing an unpublished change meant
publishing it. But since every call site now resolves a scripts directory instead of hardcoding
one, `IBV_SCRIPTS` is already the dev/prod switch — export it at the dev repo to exercise local
edits, unset it to go back. No second marketplace, no publish-to-test loop. The only change
needed was in `take_screenshots.sh`, which called the resolver unconditionally and so ignored
an override.

The obvious way to write that override is `: "${IBV_SCRIPTS:=$(resolve_ibv_scripts)}"`, and it
is wrong. Under `set -euo pipefail` the `:` builtin always succeeds, so the resolver's
`exit 2` — it runs in a command substitution, where `exit` leaves only the subshell — gets
swallowed, and the sweep proceeds with an *empty* `IBV_SCRIPTS`, invoking `/build_app.sh`. A
probe confirmed it: `SURVIVED with X=[]`, exit 0. The plain `IBV_SCRIPTS=$(resolve_ibv_scripts)`
it replaced did abort correctly, because a failing command substitution in an assignment does
trip errexit. So the guard is a boring `if [[ -z "${IBV_SCRIPTS:-}" ]]`, which keeps the abort
and honors the override; both paths were tested in isolation before the edit landed. A
one-character-looking idiom that quietly converts a hard failure into a bad screenshot sweep is
exactly the kind of thing this project keeps rediscovering.

## Porting Konjugieren's annotated directory tree (2026-08-02)

Konjugieren carries a `docs/project-structure.md` — one big fenced tree, one line of
annotation per file — plus a short CLAUDE.md section pointing at it and a maintenance rule.
Josh asked for the same in Conjugar, so this was a port of a *format*, not of content: every
line had to be derived from Conjugar's actual tree.

The useful discovery was that the repo largely documents itself already. Conjugar's Swift files
carry a header-comment convention — after the `// Created by` / `// Copyright` boilerplate, most
files open with a paragraph explaining what the type is for and why it exists that way. A
fifteen-line Python script that strips the boilerplate and joins the remaining leading `//`
lines produced usable prose for about two-thirds of the 144 Swift files in the app, widget, and
Shared targets, and for most of the test suites. The engine files in particular were nearly
free: `AccentFeature.swift` already explains that the three stress-accent patterns are
mechanically one operation, `StemVowelFeature.swift` that diphthongs and -ir raising are the
same operation in different slot sets. The remaining third — mostly small enums (`Difficulty`,
`Region`, `VerbType`) and the older UIKit-era utilities — got read directly; they're short.

Two judgment calls shaped the result. First, the tree lists *categories* where a literal listing
would be noise: `Assets.xcassets/Game/` holds well over a hundred sprite PNGs, and naming them
individually would bury the fact that they're `dancer_<action>_N` / `bull_<action>_N` flipbooks.
Same for the legacy one-shot MP3s still sitting at the app-target root — the interesting fact
isn't their names, it's that they're at the root while the newer SFX live in the synchronized
`Audio/` group. Second, `prompts/` is grouped by feature rather than listed alphabetically. It
holds 78 files, many of them phases of one effort; alphabetical order scatters
`game_dancer_actions` / `game_dancer_finish_actions` / `game_climb_back_view` across the list
when they're one story. The engine's `phase-2` through `phase-6` briefs are collapsed onto a
single line for the same reason.

The CLAUDE.md section is a verbatim port, including the maintenance note's asymmetry argument:
a missing entry costs a session one `find`, because the session can see the gap; a wrong entry
gets believed. That's the reason to prioritize renames over additions when the tree drifts —
and Conjugar has already done a lot of renaming (`Tense`→`DisplayTense`, `Flag`→`Obstacle`,
`GameState+Flags`→`GameState+Obstacles`, the whole `*2`-suffix drop), so the failure mode is
not hypothetical here.

## Recovering from a media-services reset, and Conjugar's part in causing one (2026-08-02)

This one arrived by an unusual route. Josh reported silent quiz sounds in Konjugieren, on his
iPhone, with audio feedback on and the phone unmuted. Instrumenting that app's `play` and running it
on the device caught the cause in one line: the session category read
`AVAudioSessionCategorySoloAmbient` and `AVAudioPlayer.play()` returned `false`. `.soloAmbient` is
the system default, which none of these three apps ever sets. That pair is the signature of an
`AVAudioSession` media-services reset: `mediaserverd` restarts, the session reverts to defaults, and
every existing `AVAudioPlayer` becomes an orphan that refuses to play. Konjugieren's
`docs/blog_notes.md` entry "The quiz went silent, and the audio session was the reason" has the full
trace.

The trigger was Conjugar. Josh's son had been playing this app's game on the same phone, and
Konjugieren's launch line recorded `otherAudio=true`. Two audio-heavy apps trading the session is an
ordinary way to provoke a reset. So Conjugar caused the reset in a sibling app, and was equally
defenseless against one itself: nothing here observed `mediaServicesWereResetNotification` or
`interruptionNotification`, `Utterer.setup` set a category but never activated the session, and
`sounds` caches an `AVAudioPlayer` per effect for the life of the process.

Conjugar's version of the bug is worse than Konjugieren's, and the reason is the category. Konjugieren
runs `.playback` and loses only its own audio. `Utterer` here documents `.ambient` as a deliberate
contract for a study app: mix with the user's music or podcast, and respect the silent switch. A
reset reverts that to `.soloAmbient`, which *stops* other audio rather than mixing with it. So a
reset in this app both silences its own effects and kills whatever the user was listening to, while
the comment in `Utterer` still describes the behavior the code no longer has.

A near-defense worth naming, since it looks like protection and is not: `warmUpSounds()` runs at
every game start from `GameState`, but it filters to names *absent* from `sounds`, so orphaned
players are skipped rather than replaced. Nothing short of a relaunch would have recovered.

The fix respects the session ownership this file's header goes out of its way to establish.
`SoundPlayerReal` still does not touch the session: the category-and-activate step was extracted
from `Utterer.setup` into `Utterer.configureSession`, and the recovery path calls that. Delegating
rather than duplicating also keeps the order deterministic, since the session has to be back before
the rebuilt players are prepared against it. `SoundPlayerReal.setup` registers for both
notifications: a reset triggers `rebuildAudio`, and an interruption ending calls
`Utterer.configureSession`.

Two details specific to this file. The `play()` `Bool` is the only in-band signal a reset produces,
and it was being discarded because `play()` is dispatched to `playbackQueue` to keep the blocking
audio-server round trip off the game loop; it is now checked on the queue, and a `false` hops back
to the main actor to rebuild, throttled to one rebuild per five seconds. And the music playhead is
deliberately *not* carried across a rebuild: `startMusic` drops `savedMusicTime` whenever it has to
rebuild the player, which is exactly this case, so saving it would only have looked like it worked.
A resumed track restarts per its `startsAtRandomPosition` rule.

Verifying a real reset is not possible: the simulator delegates audio to the host Mac and has no
`mediaserverd` to kill, and a device will not restart one. Konjugieren's port of this code was
verified by posting the notification synthetically and watching the rebuild run, the category return
to `Playback`, and playback resume. 550 tests in 30 suites pass here.

## The 30.015-second trap: how a lossless remux breaks an App Store preview (2026-08-03)

The four App Store preview videos came out of Final Cut and Compressor in good shape.
`scripts/verify_store_media.sh` graded all four at zero blocking issues: 886 × 1920 for
iPhone and 1200 × 1600 for iPad, square pixels, H.264 High Level 4.0, 30 fps, stereo AAC at
48 kHz, and a duration of exactly 30.000000 seconds. Three advisories per file remained,
all cosmetic — a stray timecode track that Final Cut writes and `-map 0:v:0 -map 0:a:0`
does not remove, AAC at 128 kbps against a 256 kbps spec, and a note that landing exactly
on the 30-second cap leaves no rounding margin.

That last one turned out to be bad advice, inherited from Konjugieren, and Josh overruled
it immediately: the cap is inclusive, the App Store accepts 30.000, and a preview's every
second is precious. The "aim for 29 s" guidance has been struck from all three sibling
docs and from all three copies of the verify script. What the advisory had misdiagnosed as
a margin problem was actually a delivery-pipeline bug, which is what the rest of this entry
is about.

The obvious way to clear the other two advisories is a pure remux — copy both streams
untouched, drop the data track, done:

```
ffmpeg -i in.mov -map 0:v:0 -map 0:a:0 -c copy -dn -sn -movflags +faststart out.mov
```

Every file came out at **30.015 seconds**. Over the cap. From a master that measured
exactly 30.000. All four gained the same 15 milliseconds, which is the kind of uniformity
that means a systematic cause rather than a rounding wobble.

The cause is the QuickTime edit list. Compressor's AAC track physically contains 1409
frames, and 1409 × 1024 ÷ 48000 = 30.058 seconds of samples — the encoder cannot end
mid-frame, so it overshoots the last video frame by design. The edit list is the atom that
says "present only the first 30.000 seconds of this track," and `ffprobe` on the master
duly reports both streams as 30.000000. `ffmpeg -c copy` discards edit lists. Once the edit
list is gone, the full audio track is what defines the container duration, and the file
grows to fit its own tail.

`-t 30` does not rescue it, which was the genuinely surprising part — Conjuguer's copy of
the verify script had asserted for months that it would. Under `-c copy` ffmpeg can only
cut on packet boundaries, and an AAC frame is 1024 ÷ 48000 = 21.33 ms, so 30.000 seconds is
1406.25 packets. There is no boundary there to cut on. Both `-t 30` and `-t 29.9999`
produced 30.015 s output, unchanged.

The fix is to stop copying the audio:

```
ffmpeg -i in.mov -map 0:v:0 -map 0:a:0 \
  -c:v copy -c:a aac -b:a 256k -ar 48000 -ac 2 \
  -dn -sn -shortest -map_metadata -1 -movflags +faststart out.mov
```

`-shortest` stops the AAC encoder when the 900th video frame does. The output holds 1407
audio frames and a container duration of exactly **30.000000**. The video is still
stream-copied, so the H.264 bitstream is untouched — confirmed by running
`ffmpeg -i x.mov -map 0:v:0 -f md5 -` against master and delivery and getting identical
hashes for all four files. Only the audio takes a generation of loss, and going from
128 kbps to 256 kbps on a voiceover-plus-music-bed is inaudible.

One more trap surfaced while testing: `-dn` alone does *not* reliably drop the timecode
track. The mov muxer re-creates one from the video stream's metadata, so `-map_metadata -1`
has to be there too. An intermediate test run without it came back with three streams
despite `-dn` being present.

The best part of this is retroactive. Konjugieren's script doc has carried, since its 1.2
delivery, an unexplained note that `English iPad 2 - 1200x1600.mov` shipped at 30.015 s
while its siblings sat between 29.93 and 30.00. Same file type, same 15 milliseconds, same
normalize step. That was never a rounding error; it was one file that went through a
copy-based pass while the others were re-encoded. A year-old mystery in a sibling app,
solved by an unrelated failure in this one.

All of this is now written into `docs/video_script.md` in Conjugar, Conjuguer, and
Konjugieren, under a "Delivering the files" section with a "The 30.015 s trap" subsection,
and the blocking-failure message in all three verify scripts now names the real cause
instead of recommending flags that cannot work. The delivered files live in
`~/Desktop/Final/Conjugar/upload/` and grade zero blocking, zero advisory.

Retiming the four cuts to hit 30 seconds was the other half of this work. Each clip gets a
6, 6, 6, 7, 7-second slot, and the speed to get there is just source frames ÷ target frames
at 30 fps — 180 frames for a six-second slot, 210 for a seven. Two things learned by doing
it wrong first. Enter the **duration** in Final Cut's Custom Speed dialog, never the rate:
a percentage computed against one take silently becomes wrong when the take is retrimmed,
which is exactly how the Spanish iPhone quiz clip ended up running at 339% of a
46-second source and showing 22 seconds of action in 6.5. And legibility, not duration, is
the binding constraint — the quiz clip has to show a prompt, a finished answer, and the
correct/incorrect feedback, and each of those needs to sit near real time to register. That
is why the script was cut from two quiz questions to one; two cannot fit in seven seconds
at any speed a viewer can read.

## The Quiz Drops from 50 Questions to 30 (2026-08-03)

The quiz has run 50 questions since 2017. Nobody finishes 50 questions. That was the whole
diagnosis, and the fix is the obvious one — cut it to 30, matching the sibling apps
Conjuguer and Konjugieren, both of which have always been 30.

Confirming the sibling counts turned out to be less trivial than expected, because the
three apps encode the number in three different ways. Konjugieren is honest about it:
`static let questionCount = 30`, referenced everywhere a progress label or a generation
loop needs it. Conjuguer has no constant at all — its regular difficulty is eight `forEach`
blocks that happen to sum to 30, and its `ridiculous` difficulty is a literal 30-entry
array of hand-picked verb/tense pairs. Conjugar was the same shape as Conjuguer, only more
so: three difficulty branches, each a hand-tuned sequence of `for _ in 0...8` loops and
inline verb arrays, each independently summing to 50. Nothing named 50. Nothing asserted it
except one line in `QuizTests`.

That accounting style is worth a note on its own, because `for _ in 0...8` means *nine*
questions, and a branch built from a dozen of those is genuinely hard to audit by eye. The
rewrite switched every count to half-open `0..<N`, which says what it means. The counts are
the entire point of this change; they should be readable.

### The mixes

The trim was an opportunity to fix balance problems that had accumulated in the old counts,
not just to scale everything by 0.6.

**Easy** was three tenses (presente, futuro, pretérito) at an even 25 regular / 25
irregular but lopsided by tense — 18 presente, 15 futuro, 17 pretérito, for no reason
anyone would defend. It is now ten questions per tense, five regular and five irregular in
each. Same 50/50 regular-to-irregular ratio, but now stateable in one sentence.

**Moderate**'s identity is breadth: ten tenses, including one compound. All ten survive.
Dropping a tense would have been the most visible possible loss, so the thinning went into
depth instead — presente 5, pretérito 4, three each for the middle six tenses, two each for
gerundio and the two imperatives. A side benefit fell out of this: `VerbFamilies`
`irregularImperfectivoVerbs` holds exactly three verbs (*ir*, *ser*, *ver*), and Moderate
was drawing three irregular imperfecto questions, which meant every single run showed the
entire list. At one draw the pick actually varies.

**Difficult** was where the real design decision sat. Its signature has been a complete
sweep of all nine compound tenses, one question each. Nine of 50 is 18% of a quiz; nine of
30 is 30%, which would have made a third of the hardest level into *haber* + participle. So
Difficult now draws **five of the nine per run, without replacement** — a single quiz stays
varied, and repeat play still covers the whole set. The other 25 slots are simple tenses,
weighted toward the ones that reward practice (presente, pretérito, and presente de
subjuntivo at four each) and holding one slot apiece for the exotics that make the level
what it is: both imperfecto de subjuntivo forms, futuro de subjuntivo, condicional on an
irregular raíz futura.

### The part that would have been a silent regression

Score is `questions × 10`, then multiplied by region and difficulty modifiers. Cutting to
30 drops every maximum by 40% — Spain/Difficult from 750 to 450 — and Conjugar reports
scores to a Game Center leaderboard that has years of 50-question entries on it. Ship the
cut alone and every existing high score becomes permanently unbeatable by every new player.
Nothing would have failed; the leaderboard would just have quietly frozen.

The fix is one line and one constant: normalize the raw score to a fixed 50-question scale
before applying the modifiers. `Quiz.scoreScale = 50.0`, and the final score is
`raw × scoreScale / questions.count × region × difficulty`. A perfect 30-question run is
worth exactly what a perfect 50-question run was.

Two details made this land cleanly. Multiply before dividing — `Double(score) * 50.0 /
Double(count)` evaluates 300 × 50 = 15000, then ÷ 30 = 500.0 exactly, whereas computing the
`50.0/30.0` factor first gives 1.6666666666666667 and risks 499.99999999999994 truncating
to 499 through the `Int()` conversion. And divide by `max(questions.count, 1)`, because the
DEBUG screenshot fixture builds a 12-question quiz through the same door.

The payoff shows up in `QuizTests`, where all six region × difficulty maxima — 750, 624,
500, 416, 250, 208 — are **unchanged**. The only edit the test needed was `questionCount ==
50` becoming `== 30`. The float rounding on the Latin America modifier (0.833) lands
identically to before, because the normalized raw score reaching the modifiers is the same
500 it always was.

Full suite green: 550 Swift Testing tests in 30 suites, `** TEST SUCCEEDED **`, SwiftLint
clean. Worth recording that no user-facing string ever named the number — no `.xcstrings`
entry, no Info article, no onboarding copy said "50 questions" — so the change is contained
to `Quiz.swift` and one line of its test. The only place 50 survives is `Quiz.scoreScale`,
where it is no longer a question count at all, just the scale a score is denominated in.

## The Question Count Was in the Copy Too (2026-08-03)

A footnote to the 50-to-30 cut, and a lesson about how a search can lie to you.

When I made that change I checked whether any user-facing string named the number,
concluded none did, and wrote that into both the commit message and the note above. Wrong.
Josh opened the app and the Quiz tab said "Conjugate 50 Spanish verbs."

The failure was in the search, not the codebase. Grep is useless inside `.xcstrings` —
every value is one enormous JSON line, so the tool truncates matches to `[Omitted long
matching line]`, which is why the project's CLAUDE.md says to reach for Python instead. I
did reach for Python, and then wrote a bad regex: `.{60}50.{60}`, meant to print the number
with context around it. That requires sixty characters *on both sides* of the match. The
briefing string opens with "Conjugate 50 Spanish verbs" — the number sits at character ten,
so the pattern could not match, and the search returned one irrelevant hit about the age of
the Earth. A search that returns something feels like a search that worked.

Re-running it with a length filter instead of a context window found `Quiz.briefing`
immediately, and then a wider sweep for `fifty|cincuenta|\b50\b` found two more occurrences
per language inside `Info.purposeAndUseText`, the long Purpose-and-Use article: "a set of
fifty Spanish verbs to conjugate" and "the results screen lists all fifty questions", with
"cincuenta verbos en español" and "las cincuenta preguntas" in the Spanish. Six user-facing
statements of the count altogether, across two keys and two languages, plus
`docs/purpose_and_use_proposed.txt`, the doc the Info body was written from. All now say
thirty. Worth noting the number is spelled out as a word in the Info prose and as digits in
the briefing, which is another reason a single search pattern was never going to find
everything.

Two things I'd take forward. First, when a search is meant to prove a *negative* — "no
string mentions this" — the cost of a false negative is the whole conclusion, so the pattern
needs to be the loosest one that still returns a readable result. Match the term, then slice
context around the match; never require the context in the pattern itself. Second, the
verification gap was real: `QuizTests` pins the count in code, and nothing pins the prose.
I briefly wrote a doc comment on `start()` listing every location, and Josh cut it — fairly.
A comment enumerating four files is duplicated code that rots the first time one of them
moves, and it would not have caught this bug anyway, because the bug was that the copy was
already wrong before the comment existed.

Left open at the time: `docs/video_script.md` said "Quiz mode: fifty timed questions to
sharpen your conjugation skills," and that video was already produced and delivered, so
editing the script would have made the doc misdescribe the shipped asset.

**Resolved the same day, and this paragraph is the stale part of the note.** It went in
three steps, which is worth spelling out because the middle one caught me repeating an
out-of-date journal entry back at Josh. `f5445d9` updated the fourth clip's label in all
three forms — English, Spanish, and the IPA, which had transcribed *cincuenta* as
[siŋˈkwen.ta] and now reads [ˈtɾejn.ta] — treating the script as the spec for the next
re-record rather than as a description of the delivered asset. `a137749` then fixed the
parenthetical at the top of the file that `f5445d9` had missed, the one listing "4,811
verbs, 102 models, 20 conjugated tenses, 50 quiz questions." And then Josh **re-recorded and
re-exported the previews** with the correct counts, which dissolves the dilemma entirely:
script and shipped asset agree again, and neither says fifty.

No occurrence of the old count survives anywhere in the file. The remaining thirties there
are all about the video rather than the quiz: the 32-second timeline, the App Store's
30.000 s cap, and 30 fps.

## The App Store Description, and Three Names That Were Wrong (2026-08-03)

Version 2.8's App Store description is four sentences long and describes an app that no
longer exists: "95 irregular and 112 regular Spanish verbs," a quiz, and tense
descriptions. Everything the migration added — 4,811 verbs, the models browser, the
etymologies and the corpora, the tutor, the widgets, the game, native iPad — is invisible
to anyone reading the store listing. So: a new English description for 3.0, written by
surveying the code rather than the old copy, plus its Spanish translation.

The limit is **4,000 characters**, which turns out to be roomy. The English lands at ~3.0k
and the Spanish at ~3.4k (Spanish runs longer, as always). For the record, the sibling
fields are much tighter and are not written yet: subtitle 30, promotional text 170,
keywords 100.

**The counts came from the code, and one of them was wrong.** Most claims verified cleanly:
20 conjugated tenses from `DisplayTense`, 102 models from `ModelInfo.all`, 30-question quiz
from `Quiz.swift`, four app icons from `AppIcon`, 1,345 etymologies, 2,139 medieval
quotations. But the first draft claimed **6,700 example sentences**, which was nonsense
born of a bad one-liner: `sum(len(v) for v in json.load(...).values())` over
`ExampleUses.json`, where each verb maps to a *single example object* with five keys
(`es`, `en`, `source`, `line`, `token`). The script counted keys and multiplied 1,340 verbs
by 5. The real figure is **1,340 sentences, one per verb**. The same one-liner was right for
`MedievalExamples.json`, whose values genuinely are lists — which is exactly why the error
survived a glance. Lesson: when one file's count looks suspiciously round next to another's,
print the value's *type* before printing its length.

Provenance needed hedging too. Of the 1,340 examples, 1,130 are from the literature tier,
101 from the government/technical tier, and **109 are Claude-authored** originals for verbs
with no clean corpus hit (`docs/authored-examples.md`). "Drawn from real Spanish literature"
was therefore an overclaim; the line now says "most of them drawn from Spanish literature."

**Josh caught the second error before it shipped.** A draft line said the medieval quotations
show verbs "as they were written 800 years ago," and he pushed back: are they all from
exactly 800 years ago? They are not. The corpus is three works spanning 130 years — *Libro de
buen amor* (c. 1330, 1,047 quotations), Berceo's *Milagros* (c. 1246–60, 658), and the *Cantar
de mio Cid* (c. 1200, 434). The largest share is the *youngest*, at about 695 years, so "800
years ago" overstated half the corpus. It now reads "in the 1200s and 1300s" / "en los siglos
XIII y XIV," which is true of all three. The line also named only the Cid, the *smallest*
source; it now names the *Libro de buen amor* as well, covering 69% of the quotations between
them.

**The third wrong name was the game's.** The draft headed a section `LA SUBIDA`, which is
what the code and `prompts/game_la_subida.md` call the five-stage climb — but grepping the
string catalog for "Subida" returns *nothing*. The name users see, in both localizations, is
**Toreo por Amor** (`Game.title`, `Onboarding.gameTitle`). A store listing advertising a
feature by its internal codename is a small trap for a reader who then goes looking for it.
Both descriptions now say Toreo por Amor. Worth remembering generally: internal names and
user-facing names drift, and the string catalog is the authority on which is which.

**Prueba → Test, everywhere.** Translating the description surfaced an inconsistency between
the two string catalogs: the app localizes Quiz as **Test** (`Quiz.localizedTitle`, and
`Settings.difficultyDescription`'s "los tests"), while `ConjugarWidget/Localizable.xcstrings`
independently used **Prueba** — so the same feature was "Test" in the tab bar and "Prueba
Diaria" in the widget gallery. Josh's call: align on Test. That is six values in each catalog
(both hold the `Widget.*` keys), plus the two inline references in `Info.purposeAndUseText`
where the Purpose & Use article names the widget and the control. The rename is not a
find-and-replace, because *prueba* is feminine and *test* is masculine: `Prueba Rápida` →
`Test Rápido`, `Prueba Diaria` → `Test Diario`, `Comienza una prueba` → `Comienza un test`.
The seven *other* Spanish uses of "prueba" in the catalog are ordinary vocabulary and were
left alone — the verb (`~Fácil~ prueba los tres tiempos`), the idiom (`Pon a prueba tus
conocimientos`), "evidence" in the verb-history essay, and `Prueba de Unidad` in the credits.

**A `.xcstrings` editing note, learned the expensive way.** The first attempt did the rename
by `json.load` → mutate → `json.dump`, which produced a **4,484-line diff** on a 12-line
change. Xcode writes the catalog with `"value" : "..."` — a space *before* the colon — and
Python's serializer writes `"value": "..."`, so every line in the file churns. `git checkout`
and redo as raw-text replacement on the exact `"value" : "…"` lines: 12 lines changed, 12
insertions, 12 deletions. CLAUDE.md already warns that the Edit tool mangles ASCII quotes in
`.xcstrings`; the corollary is that a full reserialize is just as destructive in a quieter
way. Surgical string replacement plus a `json.load` validation is the move. `build_app.sh`
succeeds.

**And one bug found by accident.** Grepping the catalog for terminology turned up
`Quiz.gameCenterMessage`, the body of the Game Center alert on the Quiz tab: "¿Te gustaría
que Conjugar **suiera** tus futuras puntuaciones a Game Center...?" *Suiera* is not a word.
The verb is *subir* and `¿Te gustaría que…?` governs the imperfect subjunctive, so it wants
**subiera** — a dropped `b`, shipped and visible to every Spanish-language user who has not
yet enabled Game Center. Fixed in the same pass. A reminder that a translation audit for one
purpose is a decent way to find defects of an entirely different kind.
