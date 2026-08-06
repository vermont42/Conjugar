# Task: Phase 2 — orthographic + accent features

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

Your job is **Phase 2** of the engine build: implement the **orthographic** and
**accent** features and give `Feature2` its real slot-override API. Do **not**
do verb→model data entry, build UI, touch the old engine, or implement
stem-vowel/diphthong features (those are Phase 3). Stay within taxonomy §4.1–§4.2.

## Where things stand (what previous sessions did)

- **Oracle verified.** `docs/spanish_models.md` is the verified, load-bearing
  test oracle (a faithful transcription of *Spanish Verbs Made Simple(r)* Annex
  A), plus a `# Voseo (supplement — not from the book)` section. See
  `docs/spanish_models_verification.md`. **Trust it for expected forms.**
- **Old engine assessed.** `docs/old_engine_assessment.md`: the shipping
  `Conjugator` is a parent-inheritance + string-substitution machine with almost
  no real logic (all irregularity is hand-typed data) and **known orthographic
  bugs** — `buscar/platicar/sacar/tocar` are mis-marked regular and produce
  `*buscé/*tocé` instead of `busqué/toqué`. Useful as a *fallible* differential
  oracle only; **the book is the authority.** (Pleasant consequence: the Phase 2
  engine will be *more* correct than the shipping app on every `-car` verb.)
- **Phase 1 done and committed** (branch `migration` in
  `/Users/josh/Desktop/workspace/Conjugar.mig`, commit "Phase 1: composition
  engine skeleton…"). The new engine (all `2`-suffixed, alongside the old).
  **Note on paths:** the groups→folders migration
  (`prompts/migrate-groups-to-synchronized-folders.md`) was scheduled to run
  *before* this phase. If it has, these files moved from flat `Conjugar/` into a
  real subfolder — most likely `Conjugar/Models/` — so adjust the `Conjugar/…`
  paths below accordingly (check `git status` / the file tree first).
  - `Conjugar/PersonNumber2.swift` — 6 oracle persons + `secondSingularVos`.
  - `Conjugar/Tense2.swift` — the 10 simple/non-finite tenses; cases carry
    `PersonNumber2`; `participioPasado`/`gerundio` are person-less.
  - `Conjugar/RegularRoot2.swift` — `enum {ar,er,ir}` with the full ending
    tables (oracle §3 + voseo) and `init?(infinitive:)`.
  - `Conjugar/Feature2.swift` — **placeholder protocol (this is what you flesh
    out).**
  - `Conjugar/VerbModel2.swift` — `struct { base: RegularRoot2; features:
    [Feature2] }`.
  - `Conjugar/Conjugator2.swift` — `enum`, static
    `conjugate(infinitive:tense:) -> Result<String, Conjugator2Error>`:
    validate → derive base → `stem = infinitive.dropLast(2)` → `stem + ending` →
    **`compose(...)`**, the documented last-wins composition seam (currently a
    no-op). **This is where features fold in.**
  - `ConjugarTests/Models/Conjugator2Tests.swift` — full paradigms of
    cantar/comer/subir + voseo + validation. Gate passes (13 tests, 0 failures).

## The task

Implement taxonomy §4.1 (orthographic) and §4.2 (accent) features so that one
exemplar verb per feature — and the verbs that combine several — conjugate
correctly against the oracle.

**1. Design `Feature2`'s slot-override API.** This is the heart of Phase 2;
everything in Phases 3–5 builds on it, so get it right. From taxonomy §1 and the
resolved decisions (§6): a model is `base + an ordered list of features`;
conjugating starts from the base's regular `stem + ending` and applies each
feature **in listed order, last feature wins on a slot conflict** (§6.1). The
non-negotiable constraint (§1, "end-anchored"): **every slot operation must be
defined relative to the END of the stem**, never the start — that is what makes
features prefix-invariant (`reconocer`, `releer`, `reenviar` ride free).

Note that §4.1 contains **two sub-kinds** of transformation, and the API must
handle both:
  - **Stem-final consonant changes** (`c→qu`, `g→gu`, `gu→gü`, `z→c`, `c→z`,
    `g→j`, `gu→g`, `qu→c`) — triggered by the *following* ending vowel, so a
    feature needs to see (or know) the ending it precedes.
  - **i/y hiatus changes at the stem↔ending junction** (`o-yhiatus`: leer →
    leyó, leyendo, **and** the added accents leíste/leímos/leísteis;
    `o-llñ`: tañer → tañó, tañendo; bullir → bulló, bullendo) — these modify the
    **ending** (or the boundary), not the stem-final consonant.
So a clean abstraction is something like: a feature declares *which slots* it
touches and, for those slots, transforms the `(stem, ending)` pair (or returns a
full replacement form). Read Conjuguer's `StemAlteration.swift` for prior art —
but note it is stem-only and additive/non-additive; Spanish needs the slightly
more general stem-**and**-ending form. Don't over-engineer; design exactly what
§4.1–§4.2 needs, with the composition (last-wins, end-anchored) contract honored.

**2. Implement the §4.1 orthographic features** (see the table in
`docs/spanish_taxonomy.md` §4.1 for the exact rule + slot set of each):
`o-car`, `o-gar`, `o-guar`, `o-zar`, `o-cz`, `o-gj`, `o-gug`, `o-quc`,
`o-yhiatus`, `o-llñ`.

**3. Implement the §4.2 accent features:** `a-i` (i→í), `a-u` (u→ú), and
`a-stem` (accent the stem vowel, **parameterized** by the accented vowel í/ú per
§6.3). These apply to the **STR** slot set (§2): `PI{1s,2s,3s,3p}` +
`PS{1s,2s,3s,3p}` + `IMP{2s}`.

**4. Wire features into `Conjugator2`.** Fold them in `compose(...)` (the seam is
already there). You will also need a way to **attach features to a verb for
testing**, since the verb→model map doesn't exist yet (that's Phase 6). Add a
model-taking entry point — e.g. `conjugate(infinitive:tense:model:)` or
`conjugate(stem:base:features:tense:)` — and keep the existing
`conjugate(infinitive:tense:)` (regular, no features) working. Tests construct
`VerbModel2(base:features:)` directly.

## Gate (what "Phase 2 passes" means)

Unit tests that conjugate **one exemplar per feature**, full paradigm, asserted
against `spanish_models.md`. Minimum coverage (oracle class numbers in parens):

- **Orthographic:** tocar (1-1, `o-car`), pagar (1-2, `o-gar`), averiguar (1-3,
  `o-guar`), cazar (1-4, `o-zar`), vencer (2-1) + fruncir (3-1, `o-cz`), coger
  (2-2) + dirigir (3-2, `o-gj`), distinguir (3-3, `o-gug`), delinquir (3-4,
  `o-quc`), leer (2-3, `o-yhiatus`), empeller/tañer/bullir/bruñir (2-4/2-5/3-5/
  3-6, `o-llñ` — mind the starred non-forms and the `-eron/-endo` shapes).
- **Accent:** enviar (1-15, `a-i`), actuar (1-14, `a-u`), and the `a-stem`
  family aislar/aullar/descafeinar/rehusar/amohinar (1-5…1-9) + reunir/prohibir
  (3-7/3-8).
- **Composition (multiple features, last-wins):** ahincar (1-10 = `a-stem` +
  `o-car`), cabrahigar (1-11 = `a-stem` + `o-gar`), enraizar (1-12 = `a-stem` +
  `o-zar`), europeizar (1-13 = `a-stem` + `o-zar`). These prove features stack.
- **Prefix-invariance:** at least one prefixed verb whose stem isn't a listed
  model, e.g. `releer` → releyó/releyendo (o-yhiatus on `rele-`) and `reenviar`
  → reenvío (a-i). Confirms the end-anchored rule.

Do **not** add diphthong/raising verbs (negar, empezar, etc. mix in §4.3
diphthongs — Phase 3). Where a class combines a diphthong with an orthographic
change, it's out of scope this phase.

## Method (build/test mechanics — these save real time)

- **Fast inner loop (no app, no simulator).** The engine is pure Swift with zero
  UIKit/Foundation deps, so compile it standalone and run a driver — this is
  far faster than the 78-second app build. Put top-level test code in a file
  named `main.swift` (swiftc requires that for multi-file builds):
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar
  # DIR = where the engine files live: "." before the folders migration,
  # "Models" after it. Put top-level driver code in a file named main.swift.
  DIR=Models
  xcrun -sdk macosx swiftc \
    $DIR/PersonNumber2.swift $DIR/Tense2.swift $DIR/RegularRoot2.swift \
    $DIR/Feature2.swift $DIR/VerbModel2.swift $DIR/Conjugator2.swift \
    $DIR/Conjugator2Error.swift $DIR/<new feature files> \
    /tmp/main.swift -o /tmp/check && /tmp/check
  ```
- **Adding new files.** If the groups→folders migration
  (`prompts/migrate-groups-to-synchronized-folders.md`) has run — confirm with
  `objectVersion = 77` and `PBXFileSystemSynchronizedRootGroup` in
  `project.pbxproj` — then just **drop new feature files into the engine's folder**
  (likely `Conjugar/Models/`). Xcode auto-includes them; **no `project.pbxproj`
  edit needed.** If for some reason it hasn't run (still `objectVersion 54`), fall
  back to registering each file with the `xcodeproj` gem (ruby 2.7.5) as in Phase
  1: add it to the `Conjugar/Models` group + the `Conjugar` target's source build
  phase and verify the ref's `real_path` exists.
- **Full XCTest gate:**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  The app target builds with no extra artifacts: analytics now go through the
  no-op `AnalyticsServiceable` stub, so there is no backend, framework, or
  configuration file to supply.
- **Differential cross-check (optional):** the old engine
  (`Conjugar.mig/Conjugar/verbs.xml`) has many of these verbs; agreement is
  corroboration, but remember its `-car` bugs — the book wins every disagreement.

## Deliverable

- The §4.1 + §4.2 **features implemented**, `Feature2`'s API defined, and
  `Conjugator2` folding them (with a model-taking entry point for tests).
- **Unit tests** covering the gate above, all passing (run the real XCTest target
  to confirm, not just the standalone driver).
- A one-line entry in `docs/blog_notes.md` under today's date.
- A clean **commit on `migration`** (e.g. "Phase 2: orthographic + accent
  features"), and **push** only if the user asks. End the commit message with the
  Co-Authored-By trailer used in this repo.

## Helpful context / pointers

- `docs/spanish_taxonomy.md` — **§1** (composition model + end-anchored rule),
  **§2** (slot vocabulary, STR/WK sets), **§4.1/§4.2** (the exact feature
  table), **§5** (which class = base + which features), **§6** (resolved
  decisions: last-wins ordering, `a-stem` parameterization, residue-is-a-feature).
  Do not modify this doc.
- `docs/spanish_models.md` — expected forms (the oracle).
- Phase 1 source (read before extending): `Conjugar/Conjugator2.swift` (the
  `compose` seam), `Conjugar/Feature2.swift`, `Conjugar/RegularRoot2.swift`,
  `Conjugar/Tense2.swift`, `Conjugar/PersonNumber2.swift`.
- Conjuguer prior art: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/
  Models/StemAlteration.swift`, `Conjugator.swift`, `VerbModel.swift` (single-
  parent + stem-only; adapt, don't copy).

## Suggested next step (after Phase 2)

Phase 3 — **stem-vowel changes + -ir raising** (§4.3, §4.4): the diphthongs
(`d-ie`, `d-ue`, and the spelled variants) and the -ir weak-slot raising
(`r-ei-wk`, `r-ei-str`, `r-ou-wk`), composing onto the Phase 2 machinery. Recall
the voseo subtlety already in the oracle: voseo present-2s and imperative-2s are
built on the **regular** stem and **bypass** the diphthong (`vos tenés`, not
*tienés*) — so STR stem-vowel features must not touch the `secondSingularVos`
present/imperative slots.
