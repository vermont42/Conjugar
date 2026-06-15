# Task: Phase 3 — stem-vowel diphthongs + -ir raising

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

Your job is **Phase 3** of the engine build: implement the **stem-vowel
diphthong** features (§4.3) and the **-ir weak-slot raising** features (§4.4),
composing them onto the Phase 2 machinery. Do **not** do verb→model data entry,
build UI, touch the old engine, or implement irregular-1s / preterite / future /
residue features (those are Phase 4–5). Stay within taxonomy §4.3–§4.4.

## Where things stand (what previous sessions did)

- **Oracle verified.** `docs/spanish_models.md` is the verified, load-bearing
  test oracle (a faithful transcription of *Spanish Verbs Made Simple(r)* Annex
  A) plus a voseo supplement. **Trust it for expected forms.**
- **Old engine** is a fallible differential oracle only (`docs/old_engine_assessment.md`);
  the book wins every disagreement.
- **Phase 1 + Phase 2 done and committed/pushed** (branch `migration` in
  `/Users/josh/Desktop/workspace/Conjugar.mig`). The new engine lives alongside
  the old, all `2`-suffixed, in **`Conjugar/Models/`** (the groups→folders
  migration ran: `project.pbxproj` is `objectVersion = 70` with
  `PBXFileSystemSynchronizedRootGroup`s, so **new files dropped into that folder
  auto-compile — no `project.pbxproj` edit needed**). The app target builds with
  no extra artifacts (AWS was removed; analytics are a no-op stub).

  What exists after Phase 2 (read before extending):
  - `PersonNumber2.swift` — 6 oracle persons + `secondSingularVos`.
  - `Tense2.swift` — the 10 simple/non-finite tenses; finite cases carry
    `PersonNumber2`; `participioPasado`/`gerundio` are person-less.
  - `RegularRoot2.swift` — `enum {ar,er,ir}` with the full ending tables.
  - `Feature2.swift` — **the API you reuse unchanged**: protocol with
    `applies(to:) -> Bool` (the "Slots" column) + `apply(stem:ending:tense:) ->
    (stem,ending)` (the "Rule" column, end-anchored). Also holds `enum Slot2`
    with `isStressedStem(_:)` (**STR**, vos-excluded). **There is no `WK` helper
    yet — you add it.**
  - `OrthographicFeature2.swift` — §4.1: `StemFinalConsonant2` (the 8 swaps, e.g.
    `.oGar`, `.oZar`, `.oCar`, `.oGj`, `.oGug`, `.oCz`), `IYHiatus2` (`o-yhiatus`),
    `AbsorbIAfterPalatal2` (`o-llñ`). **You compose Phase 3 features with these.**
  - `AccentFeature2.swift` — §4.2: `AccentStem2(vowel:)`.
  - `VerbModel2.swift` — `struct { base: RegularRoot2; features: [Feature2] }`.
  - `Conjugator2.swift` — `conjugate(infinitive:tense:)` (regular) and
    `conjugate(infinitive:tense:model:)` (the test entry point). `compose(...)`
    **threads the `(stem, ending)` pair through the model's features in listed
    order, last feature winning on a true conflict.** Every feature operation is
    end-anchored, so prefixes ride free.
  - `ConjugarTests/Models/Conjugator2Tests.swift` — 28 tests (Phase 1 regulars +
    voseo + validation, Phase 2 orthographic/accent + compositions +
    prefix-invariance), 0 failures. Grow this file.

## The task

Implement taxonomy §4.3 (stem-vowel diphthong/raise in STR) and §4.4 (-ir
weak-slot raising) so the exemplar verbs — and the verbs that combine these with
Phase 2 orthographic features — conjugate correctly against the oracle.

**The Phase 2 `Feature2` API is sufficient as-is — do not change it.** Every
Phase 3 feature is a stem-vowel rewrite of the same shape (replace the **last**
stem vowel of a given letter with a target string, in a given slot set). The work
is: add the missing slot set, write the features, and instantiate them per the
taxonomy table.

**1. Add the `WK` slot set** to `Slot2` (taxonomy §2): **WK** =
`PS{1p,2p}` + `PR{3s,3p}` + `GER` + `IS{all}`. This is the second named slot set;
STR already exists. **STR and WK are deliberately disjoint** (see point 4).

**2. Implement the §4.3 diphthong features** (STR slot set). All are
"replace the last `<vowel>` of the stem with `<string>`," end-anchored:
  - `d-ie` (e → ie): pensar → pienso; perder → pierdo
  - `d-ue` (o → ue): mostrar → muestro; mover → muevo
  - `d-i-ie` (i → ie): adquirir → adquiero
  - `d-u-ue` (u → ue): jugar → juego
  - **Spelled variants** — same operation, different target string (this is the
    one fiddly corner; mind it so it doesn't masquerade as an engine bug):
    - `d-ie-ye` (e → **ye**): errar → yerro
    - `d-ue-gue` (o → **üe**, the preceding g keeps its hard sound): agorar →
      agüero; avergonzar → avergüenzo
    - `d-ue-hue` (o → **hue**): oler → huelo; desosar → deshueso

A single parameterized stem-vowel feature (`from: Character`, `to: String`,
`slots`) likely covers **all** of §4.3 *and* §4.4 — the spelled variants are just
a different `to` string. Don't over-engineer; that one feature + the right
instances is probably the whole job.

**3. Implement the §4.4 raising features:**
  - `r-ei-wk` (e → i, **WK** slots): sentir → sintió, sintamos, sintiera, sintiendo
  - `r-ei-str` (e → i, **STR** slots, *instead of* a diphthong): pedir → pido
  - `r-ou-wk` (o → u, **WK** slots): dormir → durmió, durmamos, durmiendo

The three headline -ir verbs are compositions: **sentir** = `subir` + `d-ie` +
`r-ei-wk`; **pedir** = `subir` + `r-ei-str` + `r-ei-wk`; **dormir** = `subir` +
`d-ue` + `r-ou-wk`.

**4. Honor the STR/WK split — this is the crux of Phase 3 correctness.** In an
-ir verb that both diphthongizes and raises, the **present subjunctive splits**:
PS{1s,2s,3s,3p} take the STR change, PS{1p,2p} take the WK change. For `sentir`,
PS is `sienta/sientas/sienta/`**`sintamos`**`/`**`sintáis`**`/sientan` — diphthong
in the STR persons, raise in the WK persons. Because STR and WK are disjoint
person-sets within PS, the `d-ie` feature (STR) and the `r-ei-wk` feature (WK)
each fire on their own PS persons and **do not conflict** — threading just works,
*provided* STR excludes 1p/2p (it does) and WK is exactly the set above. Note
also that `r-ei-wk` does **not** touch PR{1s,2s,1p,2p} (sentí/sentiste/sentimos/
sentisteis stay regular — only PR{3s,3p} are WK).

`discernir` (15 = `subir` + `d-ie`, **no** raise) is the control case: it
diphthongizes in STR (`discierno`) but its WK slots stay regular
(`discernió`, `discernamos`, **not** *discirnió/*discirnamos). It proves the
diphthong feature is independent of the raise feature.

**5. Voseo.** STR stem-vowel features must **not** touch the voseo present-2s /
imperative-2s slots (`vos pensás`/`pensá`, not *piensás). `Slot2.isStressedStem`
already excludes `secondSingularVos`, and the WK set never includes those slots,
so this is handled for free — but confirm it with a spot check and don't
regress it.

**6. Wire + test.** Features compose through the existing `compose(...)` seam;
no `Conjugator2` change should be needed beyond instantiating features in test
models. Construct `VerbModel2(base:features:)` directly in tests, as in Phase 2.

## Gate (what "Phase 3 passes" means)

Unit tests that conjugate **one exemplar per feature**, full paradigm, asserted
against `spanish_models.md` (oracle class numbers in parens). Minimum coverage:

- **Diphthong, no raise (-ar/-er):** pensar (4A, `d-ie`), mostrar (4B, `d-ue`),
  perder (5A, `d-ie`), mover (5B, `d-ue`).
- **Spelled variants:** errar (4A-3, `d-ie-ye`), agorar (4B-4, `d-ue-gue`), oler
  (5B-2, `d-ue-hue`).
- **Rare diphthongs:** adquirir (17, `d-i-ie`), jugar (16, `d-u-ue` + `o-gar`).
- **Diphthong on -ir with no raise:** discernir (15, `d-ie`) — assert the WK
  slots stay regular (`discernió`, `discernamos`).
- **-ir raising:** sentir (6A, `d-ie` + `r-ei-wk`), pedir (6B, `r-ei-str` +
  `r-ei-wk`), dormir (6C, `d-ue` + `r-ou-wk`). Assert the **full** paradigm,
  especially the PS split and `GER` (sintiendo/pidiendo/durmiendo).
- **Cross-phase composition (Phase 3 feature + a Phase 2 orthographic feature):**
  negar (4A-1, `d-ie`+`o-gar`), empezar (4A-2, `d-ie`+`o-zar`), colgar (4B-2,
  `d-ue`+`o-gar`), forzar (4B-3, `d-ue`+`o-zar`), cocer (5B-1, `d-ue`+`o-cz`),
  elegir (6B-1, pedir-raises + `o-gj`), seguir (6B-2, pedir-raises + `o-gug`).
  These are the verbs Phase 2 deliberately deferred; they prove a Phase 3 and a
  Phase 2 feature stack. **Watch the preterite/subjunctive divergence**: empezar
  has `empiece` (PS: diphthong + z→c) but **`empecé`** (PR 1s: z→c only — PR 1s ∉
  STR, so no diphthong). negar: `niegue` vs `negué`.
- **Prefix-invariance:** at least one prefixed verb whose stem isn't a listed
  model — e.g. `comprobar` → compruebo (`d-ue` on `comprob-`) and `repetir` →
  repito (pedir-raises on `repet-`). Confirms the end-anchored rule still holds
  for stem-vowel changes (the **last** stem vowel diphthongizes/raises).

## Out of scope (do NOT implement this phase)

- **Per-verb residue** (Phase 5): morir's PP `muerto` (6C-1), resolver/volver PP
  (5B-3/4), reír's hiatus accents (6B-4), erguir's dual `yergo/irgo` + `yergamos`
  forms (6A-1). Implement only the *shared* features; skip exemplars whose only
  remaining irregularity is residue. (ceñir, 6B-3 = pedir-raises + `o-llñ`, is
  clean composition with no residue — fine to include as a bonus, not required.)
- §4.5 irregular-1s (`g1-g`/`zc`/`y-add`), §4.6 preterites, §4.7 future stems —
  Phase 4.

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
    $DIR/AccentFeature2.swift $DIR/<new Phase 3 feature file(s)> \
    /tmp/main.swift -o /tmp/check && /tmp/check
  ```
- **Adding new files.** Just drop new feature files into `Conjugar/Models/`;
  the synchronized folder auto-includes them (proved in Phase 2 — no
  `project.pbxproj` edit). Match the existing file headers/idiom.
- **Full XCTest gate:**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  Run the **real** XCTest target to confirm, not just the standalone driver.
- **Differential cross-check (optional):** the old engine
  (`Conjugar.mig/Conjugar/verbs.xml`) has many of these verbs; agreement is
  corroboration, but the book wins every disagreement.

## Deliverable

- The §4.3 + §4.4 **features implemented** (reusing the Phase 2 `Feature2` API),
  the `WK` slot set added to `Slot2`, and the features composing correctly with
  the Phase 2 orthographic features through the existing seam.
- **Unit tests** covering the gate above, all passing (real XCTest target).
- A one-line entry in `docs/blog_notes.md` under today's date.
- A clean **commit on `migration`** (e.g. "Phase 3: stem-vowel diphthongs + -ir
  raising"), and **push** only if the user asks. End the commit message with the
  Co-Authored-By trailer used in this repo.

## Helpful context / pointers

- `docs/spanish_taxonomy.md` — **§1** (composition + end-anchored rule), **§2**
  (slot vocabulary; STR/WK definitions), **§4.3/§4.4** (the feature table), **§5**
  (which class = base + which features), **§6** (resolved decisions). Do not
  modify this doc.
- `docs/spanish_models.md` — expected forms (the oracle). Classes 4A, 4B, 5A, 5B,
  6A, 6B, 6C, 15, 16, 17 and their sub-classes.
- Phase 1/2 source (read before extending): `Conjugar/Models/Feature2.swift`
  (the API + `Slot2`), `Conjugator2.swift` (the `compose` seam),
  `OrthographicFeature2.swift` / `AccentFeature2.swift` (prior-art feature shape),
  `Conjugator2Tests.swift` (test helpers — note the model-taking `assertEqual` /
  `assertParadigm` overloads).
- Conjuguer prior art: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/
  Models/StemAlteration.swift` (single-parent + stem-only; adapt, don't copy).

## Suggested next step (after Phase 3)

Phase 4 — **irregular 1s + present subjunctive, strong/suppletive preterites, and
future/conditional stems** (§4.5, §4.6, §4.7): `g1-g`/`g1-ig`/`zc`/`y-add` (with
the bundled `subj-from-1s`), `sp-end`/`sp-jend`/`wp-i`/`pret-fue` (each driving
the imperfect subjunctive via the derivation rule), and `f-drope`/`f-dr`/
`f-contract` (each driving both future and conditional). These introduce the
**derivation rules** (§1) — one override of the 1s/preterite/future stem
cascading to a whole tense — which are new machinery beyond Phase 2–3's
slot-level rewrites.
