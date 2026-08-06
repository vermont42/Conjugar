# Task: Phase 4 — irregular 1s/subjunctive + strong preterites + future stems

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

Your job is **Phase 4** of the engine build: implement the **irregular-1s /
present-subjunctive** features (§4.5), the **strong / suppletive preterites**
(§4.6), and the **future / conditional stems** (§4.7), composing them onto the
Phase 1–3 machinery. These three families introduce the **derivation rules**
(taxonomy §1) — *one* override of the 1s / preterite / future stem cascading to a
whole tense — which is the new mechanism beyond Phase 2–3's slot-level rewrites.

Do **not** do verb→model data entry, build UI, touch the old engine, or assemble
the full "fundamentally irregular" verbs with all their per-verb residue (PI
overrides, irregular participles, irregular imperatives, monosyllable accents):
that residue catalog + full assembly is **Phase 5**. Stay within taxonomy
§4.5–§4.7 plus the *mechanism* for residue stems (defined below).

## Where things stand (what previous sessions did)

- **Oracle verified.** `docs/spanish_models.md` is the verified, load-bearing
  test oracle (a faithful transcription of *Spanish Verbs Made Simple(r)* Annex
  A) plus a voseo supplement. **Trust it for expected forms.** The old engine is
  a fallible differential oracle only (`docs/old_engine_assessment.md`); the book
  wins every disagreement.
- **Phases 1, 2, 3 done and committed/pushed** (branch `migration` in
  `/Users/josh/Desktop/workspace/Conjugar.mig`). The new engine lives alongside
  the old, all `2`-suffixed, in **`Conjugar/Models/`**. The groups→folders
  migration ran (`project.pbxproj` is `objectVersion = 70` with
  `PBXFileSystemSynchronizedRootGroup`s), so **new files dropped into that folder
  auto-compile — no `project.pbxproj` edit needed**.

  What exists after Phase 3 (read before extending):
  - `PersonNumber2.swift` — 6 oracle persons + `secondSingularVos`.
  - `Tense2.swift` — the 10 simple/non-finite tenses; finite cases carry
    `PersonNumber2`; `participioPasado`/`gerundio` are person-less.
  - `RegularRoot2.swift` — `enum {ar,er,ir}` with the full ending tables
    (incl. the FU/CO endings with the theme vowel baked in: `-aré/-eré/-iré`,
    `-aría/-ería/-iría`).
  - `Feature2.swift` — **the composition API**: protocol with `applies(to:) ->
    Bool` (the "Slots" column) + `apply(stem:ending:tense:) -> (stem,ending)`
    (the "Rule" column, end-anchored). Holds `enum Slot2` with **two** named slot
    sets: `isStressedStem(_:)` (**STR**, vos-excluded) and `isWeakIr(_:)`
    (**WK**), deliberately disjoint.
  - `OrthographicFeature2.swift` — §4.1: `StemFinalConsonant2` (the 8 swaps),
    `IYHiatus2` (`o-yhiatus`), `AbsorbIAfterPalatal2` (`o-llñ`).
  - `AccentFeature2.swift` — §4.2: `AccentStem2(vowel:)`.
  - `StemVowelFeature2.swift` — §4.3/§4.4: `StemVowel2(from:to:slots:)` — the
    diphthongs (`d-ie`/`d-ue`/…/spelled variants) and the -ir raisers
    (`r-ei-wk`/`r-ei-str`/`r-ou-wk`). **You compose Phase 4 features with all of
    these.**
  - `VerbModel2.swift` — `struct { base: RegularRoot2; features: [Feature2] }`.
  - `Conjugator2.swift` — `conjugate(infinitive:tense:)` (regular) and
    `conjugate(infinitive:tense:model:)` (the test entry point). `compose(...)`
    **threads the `(stem, ending)` pair through the model's features in listed
    order, last feature winning on a true conflict.** Every operation is
    end-anchored, so prefixes ride free.
  - `ConjugarTests/Models/Conjugator2Tests.swift` — 41 tests (Phase 1–3), 0
    failures, with `assertEqual` / `assertParadigm` helpers (plain and
    model-taking overloads). Grow this file.

## The task

Implement §4.5, §4.6, §4.7 so the exemplar verbs — and especially the verbs that
**stack a Phase 4 feature on a Phase 3 diphthong/raise** (tener, venir, poder,
querer, decir) — conjugate correctly against the oracle.

The single most important idea this phase adds: a **derivation rule** is *one*
stem override that drives a whole tense (or two). Mechanically, in the existing
flat `compose`, you realize each derivation by giving the feature a **slot set
that spans the paired tenses** and emitting the right `(stem, ending)` for each
slot. No control-flow restructuring of `Conjugator2` is required for that part —
but two genuinely new pieces of machinery are (see "New machinery" below).

### §4.5 — irregular 1s present + present subjunctive (`subj-from-1s` bundled)

All four touch **`PI{1s}` + `PS{all}`** (y-add additionally touches `PI{2s,3s,3p}`).
`subj-from-1s` (the rule "the whole present subjunctive is built on the PI-1s
stem") is **bundled** into each — i.e. each feature applies its 1s stem change to
all of `PS` too (decision §6.2). Spelling of the insert:

| Feature | Rule | Slots | Exemplars (oracle class) |
|---|---|---|---|
| `g1-g` | append **g** to the stem | `PI{1s}` + `PS{all}` | asir→asgo/asga (13), salir→salgo/salga (11), valer→valgo/valga (12), poner→pongo/ponga (30), tener→tengo/tenga (31), venir→vengo/venga (32) |
| `g1-ig` | append **ig** to the stem | `PI{1s}` + `PS{all}` | caer→caigo/caiga (9), traer→traigo/traiga (33), oír→oigo/oiga (10) |
| `zc` | stem-final **c → zc** | `PI{1s}` + `PS{all}` | conocer→conozco/conozca (7A), lucir→luzco/luzca (7B), conducir→conduzco/conduzca (34) |
| `y-add` | insert **y** after the stem | `PI{1s,2s,3s,3p}` + `PS{all}` | construir→construyo/construyes/construye/construyen, construya (8) |

### §4.6 — strong / suppletive preterites (each drives `IS` via the derivation rule)

Each replaces the **preterite endings** for all six persons, and (because the
imperfect subjunctives derive from the preterite) the **`IS` endings** too. The
*stem* a strong preterite runs on is per-verb **residue** (tuv-, estuv-, anduv-,
pus-, sup-, cup-, hic-, quis-, vin-, dij-, traj-, -duj-, hub-, pud-, …) — that
catalog is Phase 5, but you implement the **mechanism** (a residue stem feature,
below) and prove it on a handful.

| Feature | PR endings (1s,2s,3s,1p,2p,3p) | IS endings | Exemplars |
|---|---|---|---|
| `sp-end` | **e**, iste, **o**, imos, isteis, **ieron** | -iera…/-iese… | tener (tuve…/tuviera), andar (anduve…, 35), estar (estuve…, 20), haber (hube…), poner (puse…), poder (pude…), saber (supe…), querer (quise…), caber (cupe…) |
| `sp-jend` | **e**, iste, **o**, imos, isteis, **eron** (no i after j) | -era…/-ese… (no i) | decir (dije…/dijeron/dijera, 28), conducir (conduje…/condujeron/condujera, 34), traer (traje…/trajeron/trajera, 33) |
| `wp-i` | **i**, iste, **io**, imos, isteis, ieron (unaccented monosyllables) | -iera…/-iese… (regular) | dar (di/diste/dio/dimos/disteis/dieron, 25), ver (vi…/vieron, 14) |
| `pret-fue` | stem **fu-** + i, iste, **e**, imos, isteis, **eron** | fu- + -era…/-ese… | ser **and** ir (fui/fuiste/fue/fuimos/fuisteis/fueron; fuera/fuese), 19/24 |

### §4.7 — future / conditional stems (each drives **both** FU and CO)

One future-stem override drives the whole future **and** the whole conditional
(they share the stem; only the endings differ). Since the FU/CO endings in
`RegularRoot2` bake in the theme vowel, the lowest-risk realization is an
**ending rewrite in `FU{all}` + `CO{all}`** (uniform with how `sp-end` rewrites
endings); the per-verb contracted stems of `f-contract` are handled by the
residue stem feature. (An equally valid but more invasive alternative is to
restructure FU/CO into *future-stem + bare endings* and override the stem; your
call — keep the existing 41 tests green either way.)

| Feature | Rule | Slots | Exemplars |
|---|---|---|---|
| `f-drope` | drop the theme **-e-** (-er → -r) | `FU{all}` + `CO{all}` | haber→habr- (habré/habría), saber→sabr-, poder→podr-, querer→**querr**-, caber→cabr- |
| `f-dr` | insert **d** (drop the theme vowel) | `FU{all}` + `CO{all}` | tener→tendr-, poner→pondr-, salir→saldr-, valer→valdr-, venir→vendr- |
| `f-contract` | irregular contraction (per-verb future stem) | `FU{all}` + `CO{all}` | hacer→har- (haré/haría, 29), decir→dir- (diré/diría, 28) |

## The cruxes (this is where the bugs hide)

1. **`subj-from-1s` resets a prior diphthong — last-wins in PI-1s and all of PS.**
   This is *the* Phase 4 correctness crux. `tener` = `comer` + `d-ie` + `g1-g`.
   The diphthong surfaces in `PI{2s,3s,3p}` (**tienes/tiene/tienen**) and in
   `IMP 2s` residue — but `g1-g` must **win** in `PI{1s}` (**tengo**, *not*
   `*tiengo`) and in **all** of `PS` (**tenga/tengas/tenga/tengamos/tengáis/
   tengan** — uniformly `teng-`, no diphthong anywhere in PS). So the §4.5
   features must build the 1s/subjunctive stem from the **regular** stem
   (regular + g), **discarding** whatever a prior diphthong/raise feature did —
   they *reset*, they do not append onto `tien-`. `venir` is the same
   (**vengo/venga** beside **vienes/viene/vienen**). Contrast `sentir` (Phase 3),
   which has *no* irregular 1s, so no `subj-from-1s`, so its PS *does* split
   STR/WK (`sienta`…`sintamos`). The reset is needed only in the PI-1s/PS overlap
   slots; **preterite and future never collide with the diphthong** (the
   diphthong's STR set excludes PR/FU/CO entirely — `tuve`/`tendré`, never
   `*tuive`/`*tiendré`).

2. **`sp-end` is base-independent — `andar`/`estar` prove it.** They are `-ar`
   verbs, yet their strong preterite **and** imperfect subjunctive take the
   `-ie-` endings: **anduve…anduvieron / anduviera**, **estuve / estuviera** —
   *not* `*anduvara`. So `sp-end` fully **replaces** `PR{all}` and `IS{all}`
   endings regardless of base. (For `-er`/`-ir` bases the IS override is a no-op
   since `-iera` is already regular.)

3. **`sp-jend` absorbs the i after j.** 3p is `-eron` (**dijeron**, not
   `*dijieron`) and IS is `-era` (**dijera**, not `*dijiera`) — same shape as
   `o-llñ`'s absorption, but driven by the j of the strong stem.

4. **`wp-i` monosyllables carry no accent**, and force `-iera` on an `-ar` base:
   **di / dio / vi / vio** (not `*dí`/`*dió`), and `dar`'s IS is **diera** (not
   `*dara`).

5. **The `-uir` accent reconciliation (the fiddly corner, analogous to Phase 3's
   spelled variants).** `construir` (8) = `subir` + `y-add` + `o-yhiatus`. It
   takes the i→y **glide** (**construyó, construyeron, construyendo,
   construyera**) but **not** `o-yhiatus`'s hiatus **accents**: it is
   **construiste / construimos / construido** — *not* `*construíste`. But
   `caer`/`oír`/`leer` (where the -i- follows a *strong* vowel a/e/o, a true
   hiatus) **do** take them (**caíste, caído, oíste, oímos, leíste, leído**).
   Phase 2's `o-yhiatus` adds those accents *unconditionally* (it was only
   exercised on `leer`). Reconcile this so the accent fires **only after a strong
   vowel (a/e/o)** — keeping leer/caer/oír right and making construir right — and
   don't let it masquerade as a `y-add` bug.

6. **Prefix-invariance still holds for every Phase 4 feature.** `reconocer →
   reconozco/reconozca`, `detener → detuve / detendré`, `componer → compuse /
   compondré`, `deshacer → desharé`, `contradecir → contradiré`. The inserts, the
   strong-stem swaps, and the contracted-future swaps must all be **end-anchored**.

## New machinery (beyond Phase 2–3 slot rewrites)

Phase 2–3 features only ever *transformed* the running `(stem, ending)`. Phase 4
needs two new capabilities; design them minimally and keep the existing 41 tests
green:

- **Regular-stem access for the §4.5 features.** To reset a prior diphthong
  (crux 1), `g1-g`/`g1-ig`/`zc` must build from the regular base stem, not the
  running (possibly diphthongized) stem. The clean way is to give `apply` the
  base stem — extend the seam (e.g. an extra parameter or a small context passed
  by `compose`); the Phase 2/3 features simply ignore it. (A hackier
  diphthong-stripping alternative is discouraged — diphthongs vary.)

- **A residue stem feature** — a general, **end-anchored** stem-suffix
  replacement applied to a given slot set (decision §6.4: "residue *is* a
  feature"). It serves three roles this phase: the **strong preterite stem**
  (`PR{all}`+`IS{all}`: ten→tuv, and→anduv, dec→dij, conduc→conduj, …), the
  **contracted future stem** for `f-contract` (`FU{all}`+`CO{all}`: hac→ha[r],
  dec→di[r]), and **explicit irregular 1s stems** (e.g. decir's `dig-`, which is
  `g1-…` set explicitly rather than a productive g-append). Implement the
  *mechanism* and prove it on the handful in the gate; the **full per-verb
  catalog and the full assembly of the ~35 hard verbs are Phase 5.**

Everything else — the per-person preterite/future endings, and the
`PR→IS` / `FU→CO` / `PI1s→PS` cascades — is realized by an ending-rewrite feature
whose `applies(to:)` spans the paired slot sets and whose `apply` switches on
`tense.personNumber`. No `Conjugator2` control-flow change needed for those.

## Gate (what "Phase 4 passes" means)

Unit tests that conjugate **one exemplar per feature**, the affected tenses (or
full paradigm), asserted against `spanish_models.md` (oracle class numbers in
parens). Construct `VerbModel2(base:features:)` directly in tests, as in Phase 2–3.
Minimum coverage:

- **§4.5 clean:** conocer (7A, `zc`), lucir (7B, `zc`), asir (13, `g1-g`), caer
  (9, `g1-ig` + `o-yhiatus` — assert **caigo/caiga** *and* **caíste/caído/cayó/
  cayera**), construir (8, `y-add` + glide — assert **construyo/construye/
  construyen**, **construya**, **construyó/construyera/construyendo**, and that
  **construiste/construimos/construido have NO accent** — crux 5).
- **§4.5 + §4.7 integration, no residue:** salir (11, `g1-g` + `f-dr`:
  **salgo/salga** + **saldré…/saldría…**; skip IMP — `sal` is Phase-5 residue),
  valer (12, `g1-g` + `f-dr`: **valgo/valga** + **valdré…**).
- **§4.6 `sp-end`:** andar (35, on the `-ar` base — **anduve…anduvieron** +
  **anduviera/anduviese**; the `-ie-` IS is the base-independence proof, crux 2),
  tener preterite (**tuve…tuvieron** + **tuviera**).
- **§4.6 `sp-jend`:** conducir (34, `zc` + `sp-jend` — **conduzco** +
  **conduje…condujeron** + **condujera**), decir preterite (**dije…dijeron** +
  **dijera**).
- **§4.6 `wp-i`:** dar (25, **di/diste/dio/dimos/disteis/dieron** + **diera/
  diese**), ver (14, **vi…vieron** + **viera**).
- **§4.6 `pret-fue`:** ser/ir preterite (**fui/fuiste/fue/fuimos/fuisteis/
  fueron** + **fuera/fuese**).
- **§4.7 `f-drope`:** haber (**habré…habrán** + **habría…**), querer (**querré**
  — the doubled r), poder (**podré**).
- **§4.7 `f-dr`:** tener (**tendré…tendrán** + **tendría…**), poner (**pondré**).
- **§4.7 `f-contract`:** hacer (**haré…harán** + **haría…**), decir (**diré…
  dirían**).
- **Capstone (full paradigm minus residue): tener (31) = comer + `d-ie` + `g1-g`
  + `sp-end`(tuv) + `f-dr`.** Assert PI (**tengo/tienes/tiene/tenemos/tenéis/
  tienen**), PS (**tenga…tengan** — all `teng-`, the last-wins reset proof,
  crux 1), PR (**tuve…tuvieron**), IS (**tuviera…**), FU (**tendré…**), CO
  (**tendría…**); skip IMP (`ten` = residue). This one verb exercises the whole
  phase at once.
- **Prefix-invariance:** reconocer (**reconozco/reconozca**) and detener
  (**detuve / detendré**) (or componer → **compuse / compondré**).

## Out of scope (do NOT implement this phase — Phase 5)

- **Per-verb residue catalog + full assembly** of the fundamentally-irregular
  verbs (§5 rows 19–35): PI overrides (soy/eres, voy/vas, he/has, estoy, doy,
  veo, quepo, sé), irregular imperfects (era-/iba-/veía-), suppletive/accented
  presents, monosyllable accents (prevé, supón, obtén, convén, **rehíce**, **dé**),
  `hizo` (c→z), GER overrides (pudiendo, yendo). Implement only the *shared*
  features + the residue *mechanism*; skip the catalog and the whole-verb builds
  (except the tener capstone, whose only missing piece is IMP `ten`).
- **§4.8 irregular participles** (hecho, dicho, puesto, visto, muerto, …).
- **Irregular tú imperatives** (ten/pon/sal/di/haz/ve) and **imperative
  derivation** for usted/nosotros/ustedes from PS.
- decir sub-variants (predecir 28-1 / bendecir 28-2), satisfacer (29-2), the §5
  derived-accent compounds (30-1/31-1/32-1), and **argüir**'s güy/guy diaeresis
  (18) — bonus only if trivial.

## Method (build/test mechanics — these save real time)

- **Fast inner loop (no app, no simulator).** The engine is pure Swift with zero
  UIKit/Foundation deps, so compile it standalone and run a driver — far faster
  than the ~78-second app build. Put top-level driver code in a file named
  `main.swift` (swiftc requires that for multi-file builds):
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar
  DIR=Models
  xcrun -sdk macosx swiftc \
    $DIR/PersonNumber2.swift $DIR/Tense2.swift $DIR/RegularRoot2.swift \
    $DIR/Feature2.swift $DIR/VerbModel2.swift $DIR/Conjugator2.swift \
    $DIR/Conjugator2Error.swift $DIR/OrthographicFeature2.swift \
    $DIR/AccentFeature2.swift $DIR/StemVowelFeature2.swift \
    $DIR/<new Phase 4 feature file(s)> \
    /tmp/main.swift -o /tmp/check && /tmp/check
  ```
  (SourceKit will flag "cannot find type" in `/tmp/main.swift` — that's index
  noise; the swiftc build is the source of truth.)
- **Adding new files.** Just drop new feature files into `Conjugar/Models/`; the
  synchronized folder auto-includes them (no `project.pbxproj` edit). Match the
  existing file headers/idiom.
- **Full XCTest gate (run the real target to confirm, not just the driver):**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  (`xcrun simctl list devices available | grep iPhone` for a sim id.)
- **Differential cross-check (optional):** the old engine
  (`Conjugar.mig/Conjugar/verbs.xml`) has many of these verbs; agreement is
  corroboration, but the book wins every disagreement.

## Deliverable

- The §4.5 + §4.6 + §4.7 **features implemented**, the **two new pieces of
  machinery** (regular-stem access for the §4.5 reset; the residue stem feature),
  and the three **derivation rules** realized through the existing `compose` seam.
- **Unit tests** covering the gate above, all passing (real XCTest target).
- A one-line entry in `docs/blog_notes.md` under today's date (and add the new
  feature file(s) to the "Files created" footer).
- A clean **commit on `migration`** (e.g. "Phase 4: irregular 1s + strong
  preterites + future stems"), and **push** only if the user asks. End the commit
  message with the Co-Authored-By trailer used in this repo.

## Helpful context / pointers

- `docs/spanish_taxonomy.md` — **§1** (composition + the derivation-rule table +
  end-anchored rule + the `tener` precedence example), **§2** (slot vocabulary),
  **§4.5/§4.6/§4.7** (the feature table), **§5** (which class = base + which
  features — the per-verb residue is spelled out there), **§6** (resolved
  decisions: §6.2 bundle `subj-from-1s`, §6.4 residue-is-a-feature). Do not modify
  this doc.
- `docs/spanish_models.md` — expected forms (the oracle). Classes 7A–14 (the
  `zc`/`y-add`/`-go` patterns), 19–35 (the fundamentally irregular — read their
  Simple-Past, Future, Conditional, and Present-Subjunctive columns).
- Phase 1–3 source (read before extending): `Feature2.swift` (the API + `Slot2`'s
  STR/WK), `Conjugator2.swift` (the `compose` seam you extend for regular-stem
  access), `StemVowelFeature2.swift` / `OrthographicFeature2.swift` /
  `AccentFeature2.swift` (prior-art feature shape), `Conjugator2Tests.swift` (test
  helpers — the model-taking `assertEqual` / `assertParadigm` overloads).
- Conjuguer prior art: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Models/`
  — its stem-alteration + future-stem + irregular-participle handling (single-
  parent + French-specific; adapt the *ideas*, don't copy).

## Suggested next step (after Phase 4)

Phase 5 — **per-verb residue + full assembly** of the ~35 fundamentally-irregular
verbs (§5): the residue *catalog* (strong/contracted stems, PI overrides,
irregular imperfects, monosyllable/derived accents, GER overrides), §4.8
irregular participles, and the irregular/derived **imperatives**
(tú = irregular residue or PI 3s; usted/nosotros/ustedes from PS; vosotros =
inf − r + d). After Phase 5 passes on all ~95 exemplars, **Phase 6** is the bulk
data entry: assign each of the 4,818 verbs its model (prefixed verbs included).
Then the UI work (Models tab, etc.).
