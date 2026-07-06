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
