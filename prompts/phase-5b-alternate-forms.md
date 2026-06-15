# Task: Phase 5b — alternate forms + the deferred corner classes

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

Your job is **Phase 5b**, a small engine addendum that closes the last gap Phases
1–5 deliberately left open: **a verb slot that has more than one accepted form.**
The engine today returns exactly one string per slot, but Spanish has a real
(small) set of verbs where the book lists two or three co-equal forms. This phase
adds the **alternate-forms representation** and then uses it to finish the handful
of classes that were marked *bonus / deferred* precisely because they need it:
**erguir (6A-1)** and **argüir (18)**, plus the alternate-bearing classes Phase 4
deferred — **raer (9-1)**, **roer (9-2)**, **yacer (7A-1)**, **placer (7A-2)** —
and the **two-form participles** (imprimir `impreso`/`imprimido`, freír
`frito`/`freído`, escribir's `-scripto` family). argüir also needs one genuinely
new orthographic feature (the **güy → guy** diaeresis drop).

After Phase 5b, the engine covers **every** form the oracle lists for the ~95
exemplars, including the alternates — and the alternate-forms mechanism is in
place for Phase 6 data entry to reuse. This is still engine-only work (unit tests,
no UI); **Phase 6 is bulk data entry** and the UI comes after.

## Where things stand (what previous sessions did)

- **Oracle.** `docs/spanish_models.md` is the verified, load-bearing test oracle
  (a faithful transcription of *Spanish Verbs Made Simple(r)* Annex A plus a voseo
  supplement). **Trust it for expected forms — the book wins every disagreement.**
  Do not modify it. `docs/spanish_taxonomy.md` is our composition taxonomy (§1
  composition + derivation rules + the prefixed-compound exception, §2 slots,
  §4 feature catalog, §5 every class as base + features + residue, §6 resolved
  decisions). The verb→model data for Phase 6 lives in `docs/annex_b_verb_models.md`.
- **Phases 1–5 done, committed and on branch `migration`** in
  `/Users/josh/Desktop/workspace/Conjugar.mig`. The new engine lives alongside the
  old, all `2`-suffixed, in **`Conjugar/Models/`** (synchronized folder — new files
  auto-compile, no `project.pbxproj` edit). **272 Swift Testing tests pass, 0
  failures.** Read these before extending:

  - **`Conjugator2.swift`** — `conjugate(infinitive:tense:[model:]) -> Result<String, Conjugator2Error>`.
    `compose(stem:ending:tense:features:)` threads the `(stem, ending)` pair
    through the model's features in listed order (last-wins, end-anchored), then
    concatenates. Non-2nd-person affirmative imperatives are **derived** from the
    computed present subjunctive (`deriveImperative`). A suppression check at the
    top turns a defective slot into `.failure(.noForm(tense))`. **This is the
    single-form entry point you must keep working unchanged** (every existing test
    and the future Phase-6 path call it).
  - **`Feature2.swift`** — protocol: `applies(to:) -> Bool`,
    `apply(stem:ending:tense:regularStem:) -> (stem,ending)` (end-anchored;
    `regularStem` is the base stem before any feature ran), and
    `suppresses(_:) -> Bool` (default `false`, for defectivity). Holds `enum Slot2`
    with the named predicates: `isStressedStem` (STR), `isWeakIr` (WK),
    `isSubjFrom1s`, `isYAdd`, `isPreteriteSystem`, `isFutureSystem`, `isImperfect`,
    `isPresentSubjunctive`.
  - **`StemVowelFeature2.swift`** — `StemVowel2` (the diphthong/raise feature):
    `dIe`, `dUe`, `dIIe`, `dUUe`, `dIeYe` (e→**ye**, the errar spelling),
    `dUeGue`, `dUeHue`, `rEiWk` (e→i in WK), `rEiStr` (e→i in STR), `rOuWk`.
  - **`OrthographicFeature2.swift`** — `StemFinalConsonant2` (the c↔qu/g↔gu/gu↔gü/
    gu↔g/… swaps; `oGug` = `gu→g` before a back vowel), `IYHiatus2.oYhiatus`
    (unstressed i→y between vowels + the hiatus accent, accenting only after a
    strong vowel — so `construir`/`-üir` verbs take **no** accent), and
    `AbsorbIAfterPalatal2.oLlñ`.
  - **`StemFeature2.swift`** — the rebuild-from-`regularStem` feature with ops
    `append`/`swapSuffix(from:to:)`/`replaceWhole`. Named: `g1g`, `g1ig`, `zc`,
    `yAdd`; factories `strongPreterite(from:to:)`, `contractedFuture(from:to:)`,
    `irregularFirstSingular(from:to:)`.
  - **`PreteriteFeature2.swift`** (`spEnd`/`spJend`/`wpI`, `SuppletivePreterite2.fue`),
    **`FutureFeature2.swift`** (`fDrope`/`fDr`/`fContract`),
    **`AccentFeature2.swift`** (`AccentStem2`).
  - **`ResidueFeature2.swift`** (Phase 5) — `LiteralSlotOverride2` (the catch-all
    literal residue, `[(slot: Tense2, form: String)]`), `IrregularParticiple2`
    (`coreSuffix`, `participle`, **`alternate: String?`** — the second participle
    is *already stored here but not surfaced*; see machinery C),
    `ApocopatedImperative2`, `DefectiveFeature2`, `RunningStemConsonantSwap2`,
    `CollapseDoubleI2`.
  - **`VerbModel2.swift`** — `struct { base: RegularRoot2; features: [Feature2] }`,
    `init(base:features: [Feature2] = [])`.
  - **`Conjugator2Error.swift`** — `.infinitiveTooShort`,
    `.invalidInfinitiveEnding(String)`, `.imperativeNotAvailable(PersonNumber2)`,
    `.noForm(Tense2)`.
  - **`Conjugator2Tests.swift`** — the Swift Testing suite (`@Suite` struct,
    parameterized `@Test(arguments:)` over `zip(PersonNumber2.oracleOrder, [forms])`
    and `(Tense2, String)` pairs; helpers `expectForm(_:model:_:_:)`,
    `assertFailure`, `residue(_:)`, `subjunctiveStem(_:)`, the `static let` model
    catalog). **Write all Phase 5b tests in this style. Use the
    `swift-testing-expert` skill** (`swift-testing-expert:swift-testing-expert`)
    for the idiomatic *how*.

- **Feature precedence is load-bearing** (taxonomy §1): a model's feature list
  follows **stem-vowel → 1s/subjunctive → preterite → future → residue**, so each
  later override wins last. Residue/alternate features go at the end.

## The task

Five pieces: the alternate-forms machinery, the new diaeresis feature, and the
four (groups of) classes that need them — plus tests.

### A. The alternate-forms representation (the load-bearing decision)

The engine must be able to say "this slot has forms `[X, Y, …]`." **Do not change
`conjugate(...) -> Result<String, …>`** — it must keep returning the single
**primary** form, so all 272 existing tests and the Phase-6 path are untouched.
Add a parallel **all-forms** entry point, e.g.:

```
static func conjugateAll(infinitive:tense:[model:]) -> Result<[String], Conjugator2Error>
```

returning `[primary] + alternates`, **primary first, de-duplicated, stable order**
(the book's preference order). `conjugate` is then `conjugateAll(...).map(\.first!)`
or stays as-is and `conjugateAll` builds on it — your call, but keep them
consistent (the primary `conjugateAll` returns **must** equal what `conjugate`
returns).

There are **two kinds** of alternate, and they want different tools — design the
representation so both compose through the existing seam:

1. **Variant paradigms** (erguir `yergo`/`irgo`; raer `raigo`/`rayo`; roer
   `roo`/`roigo`/`royo`; yacer `yazco`/`yazgo`/`yago`): the alternate is a *whole
   different derivation* of the same slots. The clean, prefix-invariant, score-
   friendly representation is to let a model declare **one primary feature stack
   plus zero or more alternate feature stacks**, and have `conjugateAll` compose
   each stack and **union** the per-slot results. The primary stack alone is what
   `conjugate` and the irregularity score (§6.5) see; the alternate stacks only
   surface through `conjugateAll`. (Slots where the stacks agree — e.g. erguir
   `erguimos`, the unstressed `irguió` — collapse to one form via the dedup.)
   This reuses *all* existing machinery and needs no change to `compose`.

2. **Per-slot literal alternates** (the participles `impreso`/`imprimido`,
   `frito`/`freído`; the `-scripto` family): a single extra string on one slot. A
   variant *stack* is overkill here. Surface `IrregularParticiple2.alternate`
   (already stored) through `conjugateAll`, and/or add a tiny "alternate literals"
   feature for the non-participle ones if any need it. Keep it minimal.

Pick the representation, write it up in a short comment, and confirm it doesn't
disturb the single-form path. **Recommended shape:** add an optional
`alternates: [[Feature2]]` (alternate stacks) to `VerbModel2` (default `[]`, so
every existing model is unchanged) + surface participle `alternate` literals; have
`conjugateAll` compose the base stack and each alternate stack and union the
slot's results. Confirm this is the right call before building (you own the
decision; the book and the existing architecture are the constraints).

### B. New machinery — the **güy → guy** diaeresis feature (for argüir)

argüir (18) is construir's build (`y-add` + `o-yhiatus`) plus one rule the book
states as **GÜY → GUY**: when the glide `y` lands immediately after `gü`, the
diaeresis drops (`argüy-` → `arguy-`), but a plain `güi` keeps it (`argüimos`,
`argüí`). The catch (**crux**): in `arguyó`/`arguyendo` the `güy` cluster
**spans the stem↔ending boundary** (`ü` is stem-final from the base, `y` is
ending-initial from `o-yhiatus`), so a feature anchored to only one side can't see
it. Implement a small orthographic-residue feature that fires after `y-add`/
`o-yhiatus` and rewrites `gü`→`gu` exactly when a `y` follows — handling **both**
the in-stem case (`argüy-` after `y-add`) and the boundary case (stem ends `gü`,
ending starts `y`). A post-compose fixup anchored to the `güy` cluster is
acceptable if it stays end-anchored and prefix-invariant; just don't touch `güi`.

### C. Surface the two-form participles (§4.8)

`IrregularParticiple2` already carries `alternate: String?`. Wire it into
`conjugateAll` (PP slot → `[participle, alternate]` when `alternate != nil`).
Catalog: **imprimir** `impreso`/`imprimido` (already constructed with the
alternate in the Phase 5 tests), **freír** `frito`/`freído`, and the **escribir
`-scripto`** family (the RAE accepts `inscripto`/`suscripto`/`transcripto`… for
`-scribir` verbs *except* escribir/rescribir/reescribir/manuscribir — see the
oracle's 3-11 footnote). Implement the book's **primary** as the single-form
answer; the alternate is the bonus that `conjugateAll` now also returns.

### D. The variant-paradigm classes

Build each as base + a **primary** stack + **alternate** stack(s), verified
against the oracle (read the full tables — the book wins):

- **18 argüir** = `subir` + `y-add` + `o-yhiatus` + the **güy→guy** feature
  (machinery B). (Mostly a single paradigm; the only "alternate" is orthographic,
  not a variant stack. Listed here because it's a deferred corner class.)
- **6A-1 erguir** "like sentir or pedir; GU → G" — two co-equal paradigms in the
  stressed slots. **Primary** (the book calls the sentir/`ye` model "more
  common") = `subir` + `d-ie-ye` + `r-ei-wk` + `o-gug` (yergo/yergues/yergue/
  yerguen, yerga…, IMP yergue). **Alternate** = `subir` + `r-ei-str` + `r-ei-wk`
  + `o-gug` (the pedir/raise paradigm: irgo/irgues/irgue/irguen, irga…, IMP irgue).
  The **unstressed** slots are identical in both and must not double up:
  `erguí`, `irguió`, `irguieron`, `irguiendo`, `erguimos`, `erguís`. (The book
  notes `yergamos`/`yergáis` are irregular-but-attested — the engine's `irgamos`/
  `irgáis` from the raise are the RAE-preferred ones; surfacing `yergamos` too is
  bonus.)
- **9-1 raer** / **9-2 roer** = caer-build (`g1-ig` + `o-yhiatus`) + an alternate
  `y-add` stack: raer `raigo`/`rayo`, raiga/raya; roer `roo`/`roigo`/`royo`,
  roa/roiga/roya (**three** variants — the plain `roo`, the `g1-ig` `roigo`, the
  `y-add` `royo`). The preterite/gerund (`rayó`/`royó`, `rayendo`/`royendo`,
  `raído`/`roído`) come from `o-yhiatus` and are shared.
- **7A-1 yacer** / **7A-2 placer** = conocer/lucir-build (`zc`) + alternate stacks:
  yacer `yazco`/`yazgo`/`yago` (and the matching subjunctives yazca/yazga/yaga, IMP
  yace/yaz); placer the archaic/alternate forms (subjunctive `plazca`/`plega`/
  `plegue`, preterite `plació`/`plugo`, …). Implement the book's primary cleanly;
  the full archaic set for placer is bonus — but the mechanism must allow N≥2.

> **Note on oír (class 10).** oír (`subir` + `g1-ig` + `y-add` + `o-yhiatus` +
> `a-stem`) was built in Phase 4/5 without issue and is **not** an alternate-forms
> class — don't add alternates to it. It is listed in §5 only as a feature stack.

## The cruxes (where Phase 5b bugs hide)

1. **Keep the single-form API byte-for-byte.** `conjugate` must still return the
   primary and all 272 tests must stay green. `conjugateAll`'s first element must
   equal `conjugate`'s result for every slot of every model.
2. **Dedup and order.** A slot where the variant stacks coincide must return *one*
   form, not a duplicate. Order is primary-first, then alternates in the book's
   preference order. Decide set-equality vs. order-sensitive for the test
   assertions and be consistent.
3. **The argüir diaeresis spans the stem/ending seam.** `arguyó` = stem `argü` +
   `o-yhiatus` ending `yó`; the `ü`+`y` straddle the boundary. `güi` (argüimos)
   keeps the diaeresis; only `güy` drops it. Stay prefix-invariant (a hypothetical
   `re-argüir` rides free).
4. **erguir's unstressed slots are shared, not alternates.** Only STR (+ IMP 2s,
   PI/PS stressed persons) differ (yerg-/irg-); `erguí`/`irguió`/`irguiendo`/
   `erguimos` are one form. If your union accidentally emits `erguió`/`yrguió`
   you've routed the raise wrong.
5. **The irregularity score (§6.5) reads the primary stack only.** Alternate
   stacks must not inflate the feature count. Encode so the score still works off
   `model.features` (the primary), with `alternates` invisible to it.
6. **N ≥ 2, not exactly 2.** roer/yacer have **three** present-1s variants. The
   representation and the tests must handle an arbitrary count.
7. **Voseo is unaffected.** vos still uses the tú form for everything except the
   two voseo rules; alternates don't apply to vos slots. Don't regress the voseo
   tests.

## Out of scope (do NOT do this phase)

- **Verb→model data entry** for the 4,818 verbs (Phase 6).
- **The irregularity-score computation and any UI** — just don't foreclose the
  score (keep alternates out of the primary feature count).
- **Compound (perfect) tenses.**
- **Exhaustive archaic minutiae** — placer's full plega/plugo set, every `-scripto`
  variant: implement the book's primary, and as many alternates as stay clean;
  the rest is bonus, but `log`/comment what you left out so it's not mistaken for
  "covered."

## Gate (what "Phase 5b passes" means)

Unit tests in `Conjugator2Tests.swift`, asserted against `spanish_models.md`:

- **All 272 existing tests still green** (the single-form path is untouched).
- **argüir** — full paradigm via `conjugate` (arguyo/arguyes/arguye/argüimos/
  argüís/arguyen, argüí/arguyó/arguyeron, arguya…, arguyendo/argüido, IMP
  arguye/argüid). Prefix-invariance spot-check.
- **erguir** — `conjugate` returns the primary (yerg-) paradigm; `conjugateAll`
  returns **both** yergo/irgo (etc.) in the stressed slots and **one** form in the
  shared unstressed slots.
- **raer / roer / yacer** — `conjugateAll` returns the full variant set in PI 1s /
  PS (raigo+rayo; roo+roigo+royo; yazco+yazgo+yago); the shared preterite/gerund
  stays single-valued; `conjugate` returns the book's primary.
- **Two-form participles** — `conjugateAll(...,.participioPasado)` returns
  `[impreso, imprimido]`, `[frito, freído]`, and an `-scripto` exemplar (e.g.
  `inscribir` → `[inscrito, inscripto]`); `conjugate` returns the primary.
- **A focused `conjugateAll` test** for a *regular* verb and a single-form
  irregular (e.g. `tener`) proving it returns exactly `[onlyForm]` (no spurious
  alternates) — i.e. the new path is a strict superset that degenerates correctly.

Full paradigm = PI, PR, IM, FU, CO, PS, IS(-ra & -se), the affirmative imperative
(2s/3s/1p/2p/3p + vos), PP, GER.

## Method (build/test mechanics)

- **Fast inner loop** — compile the engine standalone with a `main.swift` driver
  (far faster than the app build). Include the Phase 5 residue file **and your new
  file(s)**:
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar
  DIR=Models
  xcrun -sdk macosx swiftc \
    $DIR/PersonNumber2.swift $DIR/Tense2.swift $DIR/RegularRoot2.swift \
    $DIR/Feature2.swift $DIR/VerbModel2.swift $DIR/Conjugator2.swift \
    $DIR/Conjugator2Error.swift $DIR/OrthographicFeature2.swift \
    $DIR/AccentFeature2.swift $DIR/StemVowelFeature2.swift \
    $DIR/StemFeature2.swift $DIR/PreteriteFeature2.swift $DIR/FutureFeature2.swift \
    $DIR/ResidueFeature2.swift $DIR/<new Phase 5b file(s)> \
    /tmp/main.swift -o /tmp/check && /tmp/check
  ```
  (SourceKit "cannot find type" / "No such module 'Testing'" warnings on single-
  file indexing are noise; the swiftc build / the xcodebuild test run are the
  source of truth.)
- **Full test gate:**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an iPhone sim id>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  (`xcrun simctl list devices available | grep iPhone` for a sim id.) All tests
  green, 0 failures.
- **Differential cross-check (optional):** the old engine
  (`Conjugar.mig/Conjugar/verbs.xml`) has many of these verbs; agreement
  corroborates, but **the book wins** every disagreement.

## Deliverable

- The alternate-forms machinery (`conjugateAll` + the chosen representation, e.g.
  `VerbModel2.alternates` + surfaced participle alternates), the **güy→guy**
  diaeresis feature, and the full builds of argüir / erguir / raer / roer / yacer /
  placer + the two-form participles, as `VerbModel2` exemplars in the test suite.
- **Unit tests** covering the gate above, all passing on the real test target,
  with the 272 prior tests still green.
- A one-line entry in `docs/blog_notes.md`
  (`/Users/josh/Desktop/workspace/Conjugar.mig/docs/blog_notes.md`) under today's
  date, and any new feature file(s) added to its "Files created" footer.
- A clean **commit on `migration`** in `Conjugar.mig` (e.g. "Phase 5b: alternate
  forms + erguir/argüir/raer/roer/yacer/placer + two-form participles"), **push
  only if the user asks**. End the commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

## Helpful context / pointers

- `docs/spanish_models.md` — expected forms (the oracle). Read in full before
  building: **6A-1 erguir** (≈ line 908), **7A-1 yacer** (≈ 1134), **7A-2 placer**
  (≈ 1147), **9 caer** (≈ 1237, the parent of raer/roer), **9-1 raer** (≈ 1263),
  **9-2 roer** (≈ 1276), **10 oír** (≈ 1287, *not* an alternate class), **18
  argüir** (≈ 1537), **6B-4 reír** + the **freír `frito`** note (≈ 1042/1070),
  **3-11 escribir** + the `-scripto` footnote (≈ 587/591), **3-12 imprimir**
  (≈ 593). Verify line numbers — the file may have shifted.
- `docs/spanish_taxonomy.md` — **§5** rows for 6A-1, 7A-1/7A-2, 9-1/9-2, 18 (each
  spelled as base + features + the "alternate/archaic forms" residue), **§6.5**
  (irregularity score — keep alternates out of it). Do not modify this doc.
- **Phase 5 source to imitate:** `ResidueFeature2.swift` (the residue-feature
  shapes, the `IrregularParticiple2.alternate` field you'll surface),
  `Conjugator2.swift` (the `compose` seam + `deriveImperative` + the suppression
  check — model `conjugateAll` on the same structure), `Conjugator2Tests.swift`
  (the Swift Testing patterns + `expectForm`; add an `expectForms(...)` helper for
  the multi-form assertions).
- Conjuguer prior art:
  `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Models/` — check how (if at
  all) it represents alternate forms / dual participles, and adapt the *idea*.

## Suggested next step (after Phase 5b)

With the engine complete on all ~95 exemplars *including alternates*, **Phase 6**
is the bulk data entry: encode the verb→model map for all 4,818 verbs from
`docs/annex_b_verb_models.md` (prefixed verbs ride their base model for free).
Then the UI work (Models tab and the other Conjuguer-style changes) and the
irregularity-score display.
