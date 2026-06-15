# Task: Phase 5 — per-verb residue + full assembly of the irregular verbs

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

Your job is **Phase 5** of the engine build: the **per-verb residue** and the
**full assembly** of the ~35 fundamentally-irregular verb classes (taxonomy §5,
oracle classes **19–35** + their sub-classes), plus the two cross-cutting pieces
the earlier phases deferred: **irregular participles** (§4.8) and the
**imperative derivation** (usted/nosotros/ustedes from the present subjunctive;
the irregular tú imperatives). After Phase 5, **every one of the ~95 oracle
exemplars must conjugate fully and correctly** — all ten tenses, all six persons,
the four derived imperatives, the participle, and the gerund.

Phases 1–4 built the shared, composable **features**. Phase 5 is where the engine
goes from "covers the productive patterns" to "covers the whole language," by
adding the *residue* — the per-verb overrides too rare to share (decision §6.4:
**residue is a feature**) — and wiring up the last derivation rule (imperatives).
This is the final engine phase; **Phase 6 is bulk data entry** (assign each of the
4,818 verbs a model) and the UI comes after.

## Where things stand (what previous sessions did)

- **Oracle verified.** `docs/spanish_models.md` is the verified, load-bearing
  test oracle (a faithful transcription of *Spanish Verbs Made Simple(r)* Annex A
  plus a voseo supplement). **Trust it for expected forms.** The old engine is a
  fallible differential oracle only; the book wins every disagreement.
- **Phases 1–4 done and committed/pushed** (branch `migration` in
  `/Users/josh/Desktop/workspace/Conjugar.mig`). The new engine lives alongside
  the old, all `2`-suffixed, in **`Conjugar/Models/`**. New files dropped into
  that folder auto-compile (synchronized folders — no `project.pbxproj` edit).

  What exists after Phase 4 (read before extending):
  - `PersonNumber2.swift`, `Tense2.swift` (10 tenses; `imperativoAfirmativo`
    carries a `PersonNumber2`), `RegularRoot2.swift` (the three roots' full
    ending tables; `ending(for:)` returns **nil** for non-2nd-person affirmative
    imperatives — the seam you'll fill).
  - `Feature2.swift` — the composition API: `applies(to:) -> Bool` +
    `apply(stem:ending:tense:regularStem:) -> (stem,ending)` (end-anchored). The
    `regularStem` parameter (added in Phase 4) gives features the **base** stem so
    they can rebuild/reset. Holds `enum Slot2` with the named slot sets: `STR`,
    `WK`, `isSubjFrom1s` (PI1s+PS), `isYAdd`, `isPreteriteSystem` (PR+IS),
    `isFutureSystem` (FU+CO).
  - `OrthographicFeature2.swift` (§4.1; `IYHiatus2` now accents only after a
    strong vowel), `AccentFeature2.swift` (§4.2), `StemVowelFeature2.swift`
    (§4.3/§4.4 diphthongs + raises).
  - `StemFeature2.swift` (§4.5 + the residue **stem** mechanism): a unified
    stem-rebuild feature with ops `append` / `swapSuffix(from:to:)` /
    `replaceWhole`, fired on a slot predicate. Named features `g1g`/`g1ig`/`zc`/
    `yAdd`; factories `strongPreterite(from:to:)`, `contractedFuture(from:to:)`,
    `irregularFirstSingular(from:to:)`. **It rebuilds from `regularStem`, so it
    resets a prior diphthong/raise** (the subj-from-1s last-wins).
  - `PreteriteFeature2.swift` (§4.6 endings): `PreteriteEndings2` (`spEnd`/
    `spJend`/`wpI`, spanning PR+IS, base-independent) + `SuppletivePreterite2.fue`
    (ser/ir's fu-).
  - `FutureFeature2.swift` (§4.7 endings): `FutureEndings2` (`fDrope` connector
    "", `fDr` connector "d", `fContract` "" + a `contractedFuture` stem).
  - `VerbModel2.swift` — `struct { base: RegularRoot2; features: [Feature2] }`.
  - `Conjugator2.swift` — `conjugate(infinitive:tense:[model:])`; `compose(...)`
    threads `(stem, ending)` through the model's features in listed order,
    last-wins, every op end-anchored. For non-2nd-person affirmative imperatives
    it currently returns `.failure(.imperativeNotAvailable(pn))`.
  - `Conjugator2Tests.swift` — the Phase 1–4 suite, **now Swift Testing** (the
    XCTest→Swift Testing conversion landed before this phase): a `struct` suite of
    parameterized `@Test`s using `#expect`, an `expectForm` helper, and shared
    `static let` models. **Write all Phase 5 tests in that style** — parameterized
    `@Test(arguments:)` over `(Tense2, String)` pairs (or `zip(persons, expected)`),
    reusing `expectForm`. Grow this file. **Use the `swift-testing-expert` skill**
    (`swift-testing-expert:swift-testing-expert`, installed on this machine) for
    the idiomatic Swift Testing *how* — `@Test(arguments:)`, `#expect`/`#require`,
    traits/tags, parallel execution; invoke it when writing the new tests and
    follow it where it's more specific than this prompt.

- **Feature precedence is load-bearing.** Phase 4 established that a model's
  feature list must follow taxonomy §1 order — **stem-vowel → 1s/subjunctive →
  preterite → future → (Phase 5) residue** — so each later override wins
  last (venir lists `r-ei-wk` *before* `g1-g` so the subjunctive resets to
  `veng-`, not `*ving-`). Residue features go **at the end** of the list.

## The task

Implement the residue catalog and assemble every irregular class so it passes the
oracle. Concretely, four pieces of machinery + the catalog + the full builds.

### A. New machinery 1 — a general **literal slot override** residue feature

Most residue is a handful of *exact forms* that no productive rule yields: the
suppletive presents (soy/eres/es/somos/sois/son; voy/vas/va/vamos/vais/van;
he/has/ha/hemos/habéis/han; estoy + the accented estás/está/están; doy; veo/ves;
quepo; sé), the suppletive imperfects (era-/iba-), the accent residue (dé,
prevé/prevés/prevén, the derived-compound imperatives obtén/supón/convén, and
hacer's `hizo`/rehacer's `rehíce`/`rehízo`), and the gerund overrides (yendo,
pudiendo). Add **one** end-anchored-agnostic residue feature that maps specific
`(tense, person)` slots (and the person-less PP/GER) to a **literal final form**,
replacing whatever composition produced (it sits last → last-wins). This is the
catch-all "residue is a feature" mechanism (§6.4). Keep it minimal: a slot→string
table, applied by returning `(literal, "")` so the existing `stem + ending` seam
needs no change.

> Some residue is better expressed as a **stem** override than a literal: ver's
> imperfect is just regular `-er` endings on stem `ve-` (veía = ve+ía), and the
> derived-accent compounds reuse the parent's features. Prefer reusing
> `StemFeature2` (point it at new slot sets — e.g. add an `IM` predicate to
> `Slot2`) where the irregularity is a clean stem swap, and reserve the literal
> override for genuinely suppletive per-person forms. Both are residue; pick the
> one that keeps the residue *thin* (the parsimony goal — see the note at the end
> of taxonomy §5).

### B. New machinery 2 — **imperative derivation** (the last derivation rule)

Replace the `.imperativeNotAvailable` stub with the real derivation (taxonomy §1
imperative row). For `Tense2.imperativoAfirmativo(pn)`:

- **tú (2s):** already correct as the STR form (canta = PI 3s; piensa; sal→**sal**
  is residue). Apply an **irregular-tú literal residue** where the book gives one:
  `ten, pon, sal, ven, haz, di, ve, sé` (and the derived-accent compounds
  obtén/supón/convén/… as residue on those sub-classes).
- **vos (2s):** already correct — infinitive − r, final vowel accented
  (`tené/poné/salí/decí/hacé`), **regular even for irregular-tú verbs** (the
  irregular-tú override must target **`.secondSingular` only**, never
  `.secondSingularVos`). Confirm this holds; add a test.
- **usted (3s) / ustedes (3p) / nosotros (1p):** derive from the **present
  subjunctive** of the same person (so all the PS irregularities — tenga,
  pongamos, conduzcan, vayan — come through for free). The clean implementation
  computes the PS form via the existing `compose` and returns it. **Residue
  exception:** `ir`'s affirmative nosotros is **vamos** (not vayamos).
- **vosotros (2p):** infinitive − r + d (cantad/tened/poned/salid/decid/haced/id)
  — already regular via the root; just confirm no feature corrupts IMP 2p.

This is the one genuine **control-flow** change to `Conjugator2`. Keep it small:
non-2nd-person imperatives map to the corresponding PS slot (then residue may
override), 2s/2p stay as today plus the irregular-tú residue.

### C. New machinery 3 — **irregular participle** (§4.8)

The past participle is a per-model attribute (Conjuguer's `ep`): `abierto,
cubierto, escrito, impreso, podrido, roto, resuelto, vuelto, muerto, puesto,
hecho, dicho, visto, frito` (+ regular fallback). Represent it either as a literal
PP override (machinery A, targeting `.participioPasado`) **or** as a dedicated
`participle: String?` on `VerbModel2` — your call, but **encode regular-vs-
irregular so the irregularity score can later count it** (decision §6.5; the score
itself is not required this phase, but don't foreclose it). Note the **two-form**
participles (impreso/imprimido, frito/freído) — pick the book's primary; a second
accepted form is bonus.

### D. The residue catalog + full assembly

Express each class 19–35 as **base + the Phase 1–4 shared features + its thin
residue**, exactly as taxonomy §5 decomposes them, and verify the **whole
paradigm** against the oracle. The residue per class (from §5 and the oracle
tables — transcribe carefully, the book wins):

| # | Verb | shared features | residue (literal/stem/PP/IMP) |
|---|---|---|---|
| 19 | ser | `pret-fue` | PI soy/eres/es/somos/sois/son; PS sea-; IM era-; IMP tú **sé**; (voseo pres 2s **sos**) |
| 20 | estar | `sp-end`(estuv) | PI estoy + accents estás/está/están; PS esté/estés/esté/…/estén; IMP tú está |
| 21 | haber | `sp-end`(hub) + `f-drope` | PI he/has/ha/hemos/habéis/han; PS haya-; IMP tú he |
| 22 | saber | `sp-end`(sup) + `f-drope` | PI 1s **sé**; PS sep- |
| 23 | caber | `sp-end`(cup) + `f-drope` | PI 1s **quepo**; PS quep- |
| 24 | ir | `pret-fue` | PI voy/vas/va/vamos/vais/van; IM iba-; PS vaya-; IMP tú **ve**, nosotros **vamos**; GER **yendo** |
| 25 | dar | `wp-i` | PI 1s **doy**; PS dé/des/dé/demos/deis/den |
| 26 | poder | `d-ue` + `sp-end`(pud) + `f-drope` | GER **pudiendo** |
| 27 | querer | `d-ie` + `sp-end`(quis) + `f-drope`(**querr-**) | (none beyond the stems) |
| 28 | decir | `r-ei-str`+`r-ei-wk` + `irregular1s`(dec→**dig**) + `sp-jend`(dij) + `f-contract`(dir) | PP **dicho**; IMP tú **di** |
| 29 | hacer | `irregular1s`(hac→**hag**) + `sp-end`(hic) + `f-contract`(har) | PP **hecho**; IMP tú **haz**; PR 3s **hizo** (c→z) |
| 30 | poner | `g1-g`(pong) + `sp-end`(pus) + `f-dr`(pondr) | PP **puesto**; IMP tú **pon** |
| 31 | tener | `d-ie` + `g1-g`(teng) + `sp-end`(tuv) + `f-dr`(tendr) | IMP tú **ten** |
| 32 | venir | `d-ie` + `r-ei-wk`(GER viniendo) + `g1-g`(veng) + `sp-end`(vin) + `f-dr`(vendr) | IMP tú **ven** |
| 33 | traer | `g1-ig`(traig) + `sp-jend`(traj) + `o-yhiatus`(trayendo/traído) | (none beyond the stems) |
| 34 | -ducir | `zc` + `sp-jend`(-duj) | (none beyond the stem) |
| 35 | andar | `sp-end`(anduv) | (none beyond the stem) |

*(31/32/33/34/35 plus the tener capstone were already proven in Phase 4 — now
finish them: add the residue IMP/PP and assert the full paradigm incl. derived
imperatives.)*

Then the **sub-classes** that exercise the **derived-model** mechanism (taxonomy
§1 "compounds that differ by more than the prefix" — a model = another model's
build + a one-slot residue, or *minus* an override):

- **30-1 suponer / 31-1 obtener / 32-1 convenir** = poner/tener/venir + IMP-tú
  accent residue (**supón / obtén / convén**).
- **28-1 predecir** = decir but **regular tú imperative** (predice).
- **28-2 bendecir** = decir but **regular FU/CO** (bendeciré/bendeciría),
  **regular tú imperative** (bendice), **regular PP** (bendecido) — a *subtractive*
  derived model (keeps dig-/raise/strong-preterite, drops f-contract + PP + IMP
  residue).
- **29-1 rehacer** = hacer + accent residue (**rehíce / rehízo**).
- **29-2 satisfacer** = hacer + IMP residue (**satisfaz / satisface**).
- **14-1 prever** = ver + monosyllable-accent residue (prevé/prevés/prevén, preví/
  previó).

And the **§4.8 participle / defective sub-classes** (mostly subir/comer + a PP or
defectivity residue): **2-6 romper** (roto), **3-9…3-13** abrir/cubrir/escribir/
imprimir/pudrir (abierto/cubierto/escrito/impreso/podrido), **3-14 abolir**
(defective — only forms whose post-stem vowel is i/ie/io exist), **5B-3 resolver /
5B-4 volver** (resuelto/vuelto), **6C-1 morir** (dormir-features + muerto).

Finally the **remaining residue-bearing stem classes** Phase 3 deferred:
- **14 ver** = comer + `wp-i` + residue: PI **veo**/ves; IM **veía-** (regular -er
  IM on stem `ve-`); PP **visto**.
- **6B-4 reír** = pedir-raises + residue: hiatus accents (**río/ríe/rió/riendo/
  reí/reíste**) — the í/diaeresis corner.
- **6A-1 erguir** = `r-ei-str`+`r-ei-wk`+`o-gug` (with alternate `d-ie-ye` forms
  yergo/irgo as residue).
- **18 argüir** = construir-build + residue: the **güy→guy** diaeresis
  (arguyo/argüimos) — bonus if it stays clean.

## The cruxes (where Phase 5 bugs hide)

1. **Imperative derivation must reuse the *computed* PS, not re-derive it.** The
   usted/nosotros/ustedes imperatives inherit *all* present-subjunctive
   irregularities (tenga, pongamos, conduzcan, vayan, sea, dé). Compute them by
   asking the engine for the PS form of that person, then apply residue. Don't
   hand-build them — that would duplicate every §4.5 reset and diverge.
2. **Irregular tú vs. regular vos/vosotros.** `ten/pon/sal/di/haz/ve` are tú-only.
   The vos imperative is **regular** (tené/poné/salí/decí/hacé) and vosotros is
   **regular** (tened/poned/salid/decid/haced/id). Scope the irregular-tú residue
   to `.secondSingular` exactly, or you'll break vos and vosotros.
3. **The derived-accent compounds are a *monosyllable→polysyllable* accent
   shift.** Bare `ten/pon/ven` are stressless monosyllables (no accent); prefixed
   `obtén/supón/convén` gain one. Likewise `prevé` (vs `ve`), `rehíce/rehízo` (vs
   `hice/hizo`), `dé` (vs `di`). These are pure residue on the derived model.
4. **`hizo` is c→z, not a literal-only special-case if you can keep it general.**
   hacer's strong stem is `hic-`; PR 3s spells it **hizo** (c→z before o), and
   rehacer's is **rehízo** (+ accent). Decide whether this is a literal override
   of PR 3s or a tiny orthographic residue — either is fine; just don't let it
   leak into the other strong-preterite persons (hice/hiciste/hicimos keep the c).
5. **`ir` is maximally suppletive — keep its residue honest.** voy/vas/…, iba-,
   vaya-, ve/vamos, **yendo**, and `pret-fue`. The nosotros imperative **vamos**
   is the one place PS-derivation (vayamos) is wrong — residue must override it.
6. **`ser`'s voseo present 2s = `sos`** (the sole present-tense voseo irregular —
   see the oracle's voseo supplement). All other voseo for irregular verbs follows
   the two regular voseo rules (vos tenés/has/das/estás/ves).
7. **Defectivity (abolir).** Only forms whose post-stem vowel is `-i-` (or the
   diphthongs -ie/-io) exist; the others have **no form**. Decide how the engine
   represents "no form here" (a residue that suppresses specific slots → a
   distinct `Result` failure, reusing the imperative-unavailable shape, or a
   sentinel). Keep it consistent with how missing imperatives are reported.

## Out of scope (do NOT do this phase — Phase 6 / later)

- **Verb→model data entry** for the 4,818 verbs (Phase 6). Phase 5 builds the ~95
  exemplar models in *tests*, not a verb→model map or XML.
- **The irregularity-score computation and any UI** (Models tab, etc.) — later.
  Just don't foreclose the score: encode regular-vs-irregular participles/endings
  so it can be counted (decision §6.5).
- **Compound (perfect) tenses** (haber + participle) — the nine compound tenses
  are mechanical and were excluded from the Tense2 skeleton; add them only if a
  later prompt asks.
- **Exhaustive sub-variant minutiae** (every -scripto alternate, raer/roer/yacer/
  placer triple-alternates from Phase 4's deferral) — implement the book's primary
  form; alternates are bonus.

## Gate (what "Phase 5 passes" means)

Unit tests constructing `VerbModel2(base:features:)` (+ residue) directly, asserted
against `spanish_models.md`. **Full paradigm** = PI, PR, IM, FU, CO, PS, IS(-ra &
-se), the **affirmative imperative for all of 2s/3s/1p/2p/3p** (and vos 2s), PP,
GER. Minimum coverage:

- **Each of classes 19–35** — full paradigm against the oracle (19–27 are new
  full builds; 28–35 finish the Phase-4 partials with residue + derived
  imperatives). Special asserts: ser (soy/eres, era-, sé, **vos sos**), estar
  (estoy + accents, está), haber (he/has/ha, haya-), ir (voy/vas, iba-, vaya-,
  **ve/vamos**, **yendo**), dar (doy, **dé**), poder (**pudiendo**), querer
  (querré), decir (digo/dices, dije/dijeron, diré, **dicho**, **di**), hacer
  (hago, **hizo**, haré, **hecho**, **haz**), poner/tener/venir (PP/IMP residue +
  derived imperatives ponga/pongamos/pongan, etc.).
- **Derived-model mechanism:** suponer (**supón**), obtener (**obtén**), convenir
  (**convén**); predecir (regular **predice**, irregular **prediré/predicho**);
  bendecir (**bendeciré/bendecido/bendice**, but **bendije/bendijera**); rehacer
  (**rehíce/rehízo**); satisfacer (**satisfaz**); prever (**prevé/prevés/preví**).
- **§4.8 participles & defectives:** abrir/cubrir/escribir/imprimir/pudrir/romper/
  resolver/volver/morir (assert the PP and that the rest of the paradigm stays the
  base's), and abolir (defective — assert the existing forms and that the
  STR/1s/PS-less slots report "no form").
- **Imperative derivation (its own test):** a regular verb (cantar → canta/cante/
  cantemos/cantad/canten), a stem-changer (pensar → piensa/piense/pensemos/pensad/
  piensen), an irregular-tú verb (tener → **ten**/tenga/tengamos/tened/tengan,
  and **vos tené**), and ir (**ve/vamos/id**). **Update or replace the
  non-2nd-person-imperative-unavailable test** (now Swift Testing) — those
  imperatives now succeed, so it must assert the derived forms instead.
- **ver / reír** (the deferred residue stem classes); **erguir / argüir** bonus.
- **Prefix-invariance** still holds for residue: detener → **detén** (derived
  accent? — detener's tú is *detén*, like obtén), reponer → **repón**, etc., and
  the strong/contracted stems on prefixes (already covered for detuve/compuse in
  Phase 4 — extend to the PP/IMP residue: descubierto, compuesto).

## Method (build/test mechanics — these save real time)

- **Fast inner loop (no app, no simulator).** Compile the engine standalone with
  a `main.swift` driver — far faster than the app build:
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar
  DIR=Models
  xcrun -sdk macosx swiftc \
    $DIR/PersonNumber2.swift $DIR/Tense2.swift $DIR/RegularRoot2.swift \
    $DIR/Feature2.swift $DIR/VerbModel2.swift $DIR/Conjugator2.swift \
    $DIR/Conjugator2Error.swift $DIR/OrthographicFeature2.swift \
    $DIR/AccentFeature2.swift $DIR/StemVowelFeature2.swift \
    $DIR/StemFeature2.swift $DIR/PreteriteFeature2.swift $DIR/FutureFeature2.swift \
    $DIR/<new Phase 5 residue file(s)> \
    /tmp/main.swift -o /tmp/check && /tmp/check
  ```
  (SourceKit will flag "cannot find type" in `/tmp/main.swift` and across files on
  single-file indexing — that's noise; the swiftc build is the source of truth.)
- **Adding new files.** Drop them into `Conjugar/Models/`; the synchronized folder
  auto-includes them (no `project.pbxproj` edit). Match the existing file headers/
  idiom.
- **Full test gate (run the real target to confirm):**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  (`xcrun simctl list devices available | grep iPhone` for a sim id.) All Phase
  1–5 tests green, 0 failures.
- **Differential cross-check (optional):** the old engine
  (`Conjugar.mig/Conjugar/verbs.xml`) has most of these irregular verbs hand-
  entered; agreement is corroboration, but the **book wins** every disagreement
  (and the old engine has known bugs).

## Deliverable

- The residue machinery (literal slot override; imperative derivation in
  `Conjugator2`; irregular-participle representation), the **residue catalog**,
  and the **full assembly** of classes 19–35 + the gated sub-classes + the §4.8
  participle/defective classes + ver/reír.
- **Unit tests** covering the gate above (full paradigms incl. derived
  imperatives), all passing on the real test target.
- A one-line entry in `docs/blog_notes.md` under today's date, and the new feature
  file(s) added to the "Files created" footer.
- A clean **commit on `migration`** (e.g. "Phase 5: residue + full assembly of
  the irregular verbs"), **push only if the user asks**. End the commit message
  with the repo's Co-Authored-By trailer.

## Helpful context / pointers

- `docs/spanish_taxonomy.md` — **§1** (composition + derivation rules + the
  prefixed-compound exception), **§2** (slot vocabulary), **§4.5–4.8** (features +
  participles), **§5** (every class as base + features + residue — the residue is
  spelled out per verb), **§6** (resolved decisions: §6.2 bundle subj-from-1s,
  §6.4 residue-is-a-feature, §6.5 irregularity score). Do not modify this doc.
- `docs/spanish_models.md` — expected forms (the oracle). Read classes **19–35**
  in full (Present, Simple Past, Imperfect, Future, Conditional, Present/Imperfect
  Subjunctive, Imperative, both participles), the sub-classes (28-1/28-2, 29-1/
  29-2, 30-1, 31-1, 32-1, 14-1), the §4.8 PP sub-classes (2-6, 3-9…3-14, 5B-3/4,
  6C-1), and the **Voseo supplement** (ser→sos; the two regular voseo rules).
- Phase 1–4 source (read before extending): `Conjugator2.swift` (the compose seam
  + the imperative stub you replace), `StemFeature2.swift` (the residue stem
  mechanism + slot-predicate pattern to imitate for the literal override),
  `Feature2.swift`'s `Slot2` (add an `IM` predicate if you route ver/prever
  imperfects through `StemFeature2`), `Conjugator2Tests.swift` (the Swift Testing
  suite — `expectForm`, shared `static let` models, the parameterization patterns
  to follow; the imperative-unavailable test you must update).
- Conjuguer prior art: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Models/`
  — its participle (`ep`) attribute, residue/stem-alteration shapes, and
  imperative handling (single-parent + French-specific; adapt the *ideas*).

## Suggested next step (after Phase 5)

With the engine passing on all ~95 exemplars, **Phase 6** is the bulk data entry:
encode the verb→model map for all 4,818 verbs from `spanish_verbs_made_simpler.pdf`
(prefixed verbs ride their base model for free — pure data entry, as in Conjuguer).
Then the UI work (Models tab and the other Conjuguer-style changes) and the
irregularity-score display.
