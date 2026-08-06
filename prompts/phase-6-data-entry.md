# Task: Phase 6 — the verb→model map (bulk data entry)

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal: bringing Conjuguer's
parsimonious, composition-based representation of verb irregularities to the
Spanish app Conjugar, so ~4,818 verbs can be represented compactly.

The **engine is complete.** Phases 1–5b built a composition conjugator that
covers **every** form the oracle lists for the ~95 model classes, including the
alternate forms (303 Swift Testing tests, 0 failures, on branch `migration` in
`/Users/josh/Desktop/workspace/Conjugar.mig`). What the engine still lacks is the
**other half** of the parsimony scheme: a map from each of the 4,818 verbs to the
model it follows. Phase 6 is that map — the **easy data-entry half** the whole
architecture was built to enable ("once the Spanish model hierarchy exists, this
table assigns a model to every verb," per `blog_notes.md`). This is still
**engine-only** work (no UI); the UI (Models tab, irregularity-score display, the
other Conjuguer-style changes) comes after.

The data already exists, fully transcribed and verified:
**`docs/annex_b_verb_models.md`** maps all 4,818 verbs to their book model number.
Phase 6 turns that table into something the engine can consult.

> ## STATUS (read this first) — A and B/B2 are DONE; only **C** remains
>
> Parts **A** (the model catalog) and **B/B2** (the verb→model map + glosses) are
> complete and committed on `migration` — **332 tests, 0 failures**
> (`ConjugarTests/{Conjugator2Tests, VerbMap2Tests}`). What shipped:
> - **A:** `Conjugar/Models/ModelCatalog2.swift` (class number → `VerbModel2` for all
>   106 numbers; the new 4B-1/4B-5/4B-6/10 builds; the 29-2/30-1/31-1/32-1 aliases),
>   with `Conjugator2Tests` refactored to exercise it.
> - **B/B2:** `Conjugar/Models/verbModelMap.xml` (4,818 elements / 4,814 distinct
>   infinitives, `<verb in cl tn rx/>`), generated reproducibly by
>   `docs/_build_verbmap.py`; the loader `Conjugar/Models/VerbMap2.swift`; tests in
>   `ConjugarTests/Models/VerbMap2Tests.swift`. Glosses: oracle/`verbs.xml` reused,
>   the rest authored (low-confidence flagged in `docs/glosses_to_review.md`); `(DEF)`
>   verbs logged in `docs/def_worklist.md`; schema reserves `tnr` (reflexive gloss)
>   and `dg` (defect group). **Resolved decisions:** glosses authored in one pass
>   (Q1=a); homonym default = the everyday sense, both retrievable, default first —
>   `apostar`→bet, `asolar`→raze, `aterrar`→**terrify** (the regular sense, not the
>   book's first), `atestar`→stuff (Q2); resource is **XML** (Q3). The "Questions"
>   block below is historical.
>
> **Your job is Part C** (below): wire the no-`model:` `Conjugator2` entry points to
> consult `VerbMap2` → `ModelCatalog2` → conjugate. Sections A and B/B2 remain as
> reference for what already exists.
>
> **Prerequisite:** run `prompts/fix-reir-oir-prefix-invariance.md` **first** (a
> small engine fix for a pre-existing Phase-5 defect surfaced during B; see
> `docs/phase6_known_issues.md`). Until it lands, the reír (6B-4) and oír (10)
> compounds aren't prefix-invariant. Once it lands, include reír/sonreír/desoír in
> C's prefix-payoff gate (below); if for some reason you run C first, exclude them
> and note it.

## Where things stand (what previous sessions did)

- **Oracle.** `docs/spanish_models.md` is the verified, load-bearing oracle (book
  Annex A + a voseo supplement). **Trust it; the book wins every disagreement.**
  Do not modify it. `docs/spanish_taxonomy.md` is the composition taxonomy (§1
  composition + the **prefixed-compound rule**, §2 slots, §4 feature catalog, §5
  every class as base + features + residue, §6 decisions incl. §6.5 the
  irregularity score). Do not modify it.
- **The verb→model index.** `docs/annex_b_verb_models.md` — all **4,818** verbs,
  one per row, each with its **Model #** (the book class number: `1`, `1-1`,
  `4A-1`, `7A`, `31-1`, `5B-3`, …). This is your data source. It was generated
  from the PDF with `docs/_extract_annexb.py` (kept for reproducibility); the
  table is the source of truth, the script just shows how it was built.
  - **106 distinct model numbers** appear in the table. Format of a data row:
    `| 470 | apostar (1) | mostrar | 4B | [2](#fn2) |` — columns are
    `# | Verb | Model (sub-class) | Model # | Note`. **The "Model #" column (4th)
    is the key you map to**; the "Model (sub-class)" column (3rd) is human prose.
  - **Markers in the Verb cell** you must strip to recover the bare infinitive:
    `(se)` (reflexive-only, e.g. `aborregar(se)`), `(DEF)` (defective, e.g.
    `acaecer (DEF)`), and the homonym disambiguators `(1)`/`(2)`.
  - **Homonyms:** exactly **8 rows** (4 verbs × 2 senses) carry `(1)`/`(2)` —
    `apostar`, `asolar`, `aterrar`, `atestar` — each sense a *different* model
    (`apostar (1)` → mostrar 4B, `apostar (2)` → cantar 1). The bare key
    `apostar` is genuinely ambiguous; see crux 4.
  - **Footnotes** (the Note column) flag orthographic variants and a few dual
    participles (fn11 desprovisto/desproveído, fn15 frito/freído, fn20 pudrir-like)
    — mostly already handled by the engine's alternate-forms machinery. They are
    **not** needed to assign a model; treat as out of scope (log, don't model).
- **The engine** (Phases 1–5b, all on branch `migration`, in `Conjugar/Models/`,
  a **synchronized folder** so new files auto-compile — no `project.pbxproj`
  edit). The pieces you'll touch:
  - **`Conjugator2.swift`** — entry points
    `conjugate(infinitive:tense:[model:]) -> Result<String, Error>` and (Phase 5b)
    `conjugateAll(infinitive:tense:[model:]) -> Result<[String], Error>`. The
    **no-`model:` overloads currently infer a *regular* base from the infinitive's
    ending** (there is no verb→model map yet — that's literally the Phase 6 gap).
    The `model:`-taking overloads take an explicit `VerbModel2`. The conjugator
    always conjugates the verb's **own** stem (`infinitive.dropLast(2)`), and every
    feature is **end-anchored**, so a prefixed verb rides its base's model for free.
  - **`VerbModel2.swift`** — `struct { base: RegularRoot2; features: [Feature2];
    alternates: [[Feature2]] }`. A model = one regular base + ordered primary
    features (+ optional alternate stacks). The **irregularity score (§6.5) reads
    `features` only** — don't disturb that.
  - The feature files (`OrthographicFeature2`, `AccentFeature2`,
    `StemVowelFeature2`, `StemFeature2`, `PreteriteFeature2`, `FutureFeature2`,
    `ResidueFeature2`, `DiaeresisFeature2`) — the catalog you'll assemble models
    from. You should **not** need to write new features for Phase 6.
  - **`Conjugator2Tests.swift`** (test target, `ConjugarTests/Models/`) — the
    Swift Testing suite. It already defines **~95 model exemplars** as
    `static let`s (tocar, pensar, mostrar, sentir, tener, ser, decir, hacer,
    erguir, argüir, …). These are the proven, oracle-verified builds — your
    **catalog should be these same models**, but promoted to the app target and
    keyed by class number (see the task). Use the **`swift-testing-expert` skill**
    for the idiomatic test *how*.
- **The old engine** (`Conjugar.mig/Conjugar/verbs.xml` + `Conjugator.swift`) is a
  parent-inheritance + literal-string machine that conjugates only **214** verbs.
  It is **not** a model to copy (`docs/old_engine_assessment.md` — it's brittle and
  already buggy), but its 214 verbs are a useful **non-gating differential
  cross-check** (book wins disagreements). It also shows the app's existing
  **resource-loading** pattern (an XML in the bundle), which you may mirror.

## The task

Three pieces: build the model **catalog**, build the verb→model **map**, and
**wire** them into the conjugator. Then tests.

### A. The model catalog (class number → `VerbModel2`)

Create, **in the app target** (`Conjugar/Models/`, e.g. `ModelCatalog2.swift`), a
lookup from each book class number (a `String` key — `"1"`, `"1-1"`, `"4B-1"`,
`"7A"`, `"31-1"`, …) to its `VerbModel2`. This is the **single source of truth**
for the ~95 models, today scattered as test-only `static let`s.

- **Most models already exist** in `Conjugator2Tests.swift`, verified against the
  oracle. **Move/replicate the canonical, *complete* build of each into the
  catalog** (use the Phase 5/5b versions — e.g. the full `conducir`/`andar`, not
  the Phase-4 partials `conducir`/`andarFull`/`tenerSpEnd`/`decirSpJend`, which are
  test scaffolding). The regular roots are trivial: `1` = `VerbModel2(base: .ar)`,
  `2` = `.er`, `3` = `.ir`.
- **A handful of classes were never built as test exemplars** — build these now
  (base + features per taxonomy §5 / the oracle; verify against the oracle):
  - **4B-1 trocar** = mostrar + `o-car` (`d-ue` + c→qu).
  - **4B-5 desosar** = `d-ue-hue` on an **-ar** base (deshueso; oler is the -er
    cousin already built as 5B-2).
  - **4B-6 avergonzar** = `d-ue-gue` + `o-zar` (avergüenzo / avergüence).
  - **10 oír** = subir + `g1-ig` + `y-add` + `o-yhiatus` + `a-stem` (oigo/oyes/
    oye, oí/oyó, oiga…, oído/oyendo). The taxonomy §5 lists it; it was built in
    principle in Phase 4/5 but is **not** a test exemplar — build and test it.
  - The **prefix-accent compounds** **29-2 satisfacer, 30-1 suponer, 31-1 obtener,
    32-1 convenir** need **no distinct model**: they are byte-identical to their
    parents (29 hacer, 30 poner, 31 tener, 32 venir) because `ApocopatedImperative2`
    already derives the accented imperative (satisfaz/supón/obtén/convén) and every
    other feature is prefix-invariant. **Map these class numbers to the parent
    model.** (This is the §1 "ride for free" payoff; confirm satisfecho/supuesto/
    obtuvo/convino come out right on a compound, then alias the number.)
- **Refactor the tests to consume the catalog** (so there is one source of truth
  and the catalog is itself under test). Cleanest: have the existing exemplar tests
  reference `ModelCatalog2.model(forClass: "31")` etc. instead of a local
  `static let`; or keep the `static let`s but define them *as* the catalog lookups.
  Either way, **the 303 existing assertions must stay green** and the catalog must
  be the thing they exercise.
- **Completeness invariant:** assert (in a test) that **every one of the 106
  distinct model numbers in Annex B resolves to a catalog entry** — no verb can
  map to a missing model. Generate the 106-number list from the table (don't
  hand-list it).

### B. The verb→model map (the data entry)

Turn `docs/annex_b_verb_models.md` into a lookup the app can load: **bare
infinitive → (class-number, gloss)** for all 4,818 verbs (the gloss is **B2**).

- **Representation: an attribute-based XML resource, mirroring Conjuguer's
  `verbs.xml`** — a generated bundle resource, not 4,818 lines of hand-written
  Swift. One element per verb, fields as **named attributes**:
  ```
  <verb in="abrir"  cl="3-9"  tn="open" />
  <verb in="abrazar" cl="1-4" tn="hug" />
  <verb in="apostar" cl="4B"  tn="bet" />      <!-- homonym sense (1) -->
  ```
  (`in` = infinitive, `cl` = class number, `tn` = gloss; pick the exact attribute
  names you like, but follow the `verbs.xml` two-letter convention.) Write a small,
  reproducible extractor (a Python script beside `docs/_extract_annexb.py`, or a
  Swift build step) that parses the markdown table → this XML, ship it in the app
  bundle, and load it once at launch (Conjuguer's `VerbParser` is an `XMLParser`
  you can adapt — see pointers). **Confirm the resource actually lands in the
  app/test bundle** (synchronized folders auto-add *source*; verify resources are
  bundled too — this is the one place the folder setup can bite you).
  - Strip the Verb-cell markers (`(se)`, `(DEF)`, `(1)`/`(2)`) to get the `in` key.
  - **Verify counts:** exactly **4,818** rows parsed, **0** rows with an
    unparseable model number, **0** model numbers absent from the catalog (A's
    invariant), and the homonyms preserved (crux 4).
  - **Why XML attributes, not TSV/plist/JSON.** The schema is **normalized and
    *will grow* optional, sparse, per-verb fields** — defectiveness next (see
    below), and after that frequency / example / etymology, exactly as Conjuguer's
    `verbs.xml` carries `fr`/`ee`/`dg`. **Named optional attributes** add a field
    without touching existing rows or relying on column order; positional **TSV**
    fights that (every new column = trailing empties + order-discipline, and CSV is
    out anyway — glosses contain commas, "lower, stoop, abase"). **plist** is
    type-safe but bloated and diff-hostile at this scale. **JSON + `Codable`** is
    the one acceptable alternative (same optional-field and type-safety wins, less
    bloat than plist) — choose it only if the team prefers `JSONDecoder` over
    `XMLParser`; otherwise XML wins on **precedent + existing parser code + the app
    already speaks it** (the migration eventually folds into that app). Do **not**
    use TSV or plist. Compactness is a near-non-issue (a few hundred KB either way),
    so extensibility and precedent decide, not byte count.

- **Reserve the defectiveness hook now (don't build it — Phase 6 just must not
  foreclose it).** Conjuguer models defectiveness **orthogonally** to the
  conjugation model: `defectGroups.xml` defines ~25 groups once (a slot list — "only
  PP is used," "no preterite," …) and each `verbs.xml` row references one by id via
  a `dg` attribute, *independent* of its `mo` (model). Our engine already has the
  exact seam: `DefectiveFeature2(isMissing: (Tense2) -> Bool)` — a "defect group"
  *is* one of those, and a defective verb's model is just its class features **+**
  that feature. So the eventual design is: **defect-group definitions in Swift**
  (a small id→`DefectiveFeature2` catalog, ~25 entries, logic not bulk data —
  exactly like the §A model catalog is Swift), and a **per-verb optional `dg`
  attribute** in the XML referencing one. For Phase 6: **leave `dg` out of the
  data** (Annex B's `(DEF)` marker doesn't say *which* pattern, so the assignment is
  future data entry like the glosses), but choose the XML schema so a `dg`
  attribute drops in later with zero migration, and **log the `(DEF)`-marked verbs**
  (parse the marker, record them somewhere) so the future pass has the worklist.
  (This also points to a tidy later refactor: abolir/3-14, which today bakes
  `DefectiveFeature2.abolir` into its class, becomes "model 3 (subir) + defect
  group" like every other defective verb — **not** Phase 6.)

### B2. Glosses (gloss as you map)

The app shows each verb's **English meaning** (the old `verbs.xml` `tn`
attribute — `in="abrir" tn="open"`, `in="abrazar" tn="hug"`). Annex B has **no
gloss column**, so the gloss is genuinely new content you must supply **alongside**
the model assignment — *gloss as you map*, one short English gloss per verb,
carried in the same resource (the `tn` attribute on each verb row). This is the one place Phase 6
is authorship, not transcription, so treat it like the voseo supplement: clearly
mark it as not-from-the-book and make it spot-checkable.

Source the glosses in this priority order, so existing curation is reused and only
the genuinely-missing ones are written fresh:

1. **The oracle class headers** (`spanish_models.md`, e.g. "cantar — *to sing*",
   "conocer — *to know, become acquainted with*") — the ~95 model verbs.
2. **The old `verbs.xml` `tn` attribute** (`Conjugar/Models/verbs.xml`, ~214
   verbs) — the author's own glosses; reuse verbatim where the infinitive matches.
   **On disagreement, the oracle header wins** (it's the verified, book-sourced
   gloss; the `tn` is older hand entry) — but the gloss is display-only, so just
   take the oracle's and move on; don't agonize. (Trim the oracle gloss to the
   terse `tn` style — "to know" → "know" — per source 4's convention.)
3. **Annex B footnotes** — the homonym senses are glossed there (fn2 "To bet" vs
   fn3 "To station or post" for `apostar (1)`/`(2)`; likewise asolar/aterrar/
   atestar). Use these to gloss **each homonym sense distinctly** (the gloss is
   what disambiguates them for the user — crux 4).
4. **The remaining ~4,500** have no source gloss — **write a concise gloss as you
   map** (verb meaning is general knowledge; keep it to 1–3 words / a short phrase,
   matching the terse `tn` style: "to" is usually omitted, `tn="open"` not
   `tn="to open"` — follow the existing convention). Prefer the **primary,
   everyday** sense. Where you are genuinely unsure, **flag it** (a marker column /
   a logged list) rather than guessing silently, so a later human pass can review;
   do **not** leave a verb glossless.

Keep the gloss **decoupled** from conjugation: it is display metadata, never an
input to the engine, so a wrong gloss can never produce a wrong form. Generate it
with the same reproducible extractor (sources 1–3 wired in; source 4 either
authored in a checked-in side table the script merges, or — if you batch-generate
them — emitted to a reviewable file, never hand-scattered).

### Questions from the implementer (B / B2) — for Josh

*(Added by the session picking up B and B2. The rest of the prompt is clear; these
are the few genuine decisions I can't resolve from defaults/the codebase. My
recommended default is marked **→** so I can proceed even if you don't answer.)*

1. **B2 — gloss authorship method & quality bar (the big one).** Annex B has no
   glosses, and reuse is thinner than it sounds: the ~95 oracle class headers + the
   old `verbs.xml`'s **213** `tn` values + the 8 footnote homonym senses cover at
   most ~300 of the 4,818. So **~4,500 glosses are genuine fresh authorship** — and
   the long tail is the hard part (rare / technical / regional / denominal verbs:
   `zorrear`, `aborregar(se)`, `zonificar`, `abetunar`…), where a one-word English
   gloss is much shakier than for everyday verbs. How do you want them produced?
   - **(a) →** I author all 4,818 in one pass from general knowledge, and emit every
     low-confidence gloss to a reviewable `docs/glosses_to_review.md` for a later
     human pass. Cheapest/fastest; common verbs solid, long tail "good but flagged."
   - **(b)** A multi-agent **workflow** authors *and* independently cross-checks each
     gloss against a dictionary-style consensus. Much stronger on the long tail, but
     many more tokens and it needs your **explicit opt-in** (workflows aren't run by
     default). Say "use a workflow" if you want this.
   - **(c)** Gloss only a high-frequency subset now; leave the long tail with a
     clearly-marked placeholder + flag, to be filled in a later dedicated pass.

   **My recommendation: (a).** The gate is "0 glossless," the gloss is display-only
   and *decoupled from conjugation* (a wrong gloss can never produce a wrong form),
   so an imperfect-but-flagged long-tail gloss is a cosmetic, trivially-fixable bug
   — not worth workflow cost unless you specifically want the higher gloss quality.

2. **B / C — homonym default sense.** The XML will carry **both** senses for each of
   the 4 homonyms (8 rows), glossed distinctly from the footnotes. When the engine
   conjugates by **bare name** (no `model:`), which sense wins? **→** I'll store
   `verb → [class numbers]` (1–2 entries) and have the resolver default to the
   **more common everyday sense** — `apostar`→*bet* (4B), `asolar`→*raze* (4B),
   `aterrar`→*terrify* (4B), `atestar`→*stuff* (1) — keeping both retrievable for the
   future UI and **logging** the non-default. OK? Or do you want a particular sense
   fixed per verb, or both always surfaced via `conjugateAll`?

3. **B — resource format: confirm XML.** The prompt recommends attribute-based XML
   (mirrors `verbs.xml`, reuses the existing `XMLParser` path); JSON+`Codable` is the
   only sanctioned alternative. **→** I'll go **XML** unless you'd rather have JSON.

   *(Working assumptions I'll otherwise just apply, no answer needed: strip `(se)` /
   `(DEF)` / `(1)`/`(2)` from the `in` key per the prompt; reflexive-only `(se)`
   verbs get a plain gloss — `arrepentir(se)`→"repent" — with no special marker; the
   9 `(DEF)` verbs are mapped to their conjugation model and logged to a worklist
   with the `dg` attribute deliberately omitted; off-list verbs fall back to
   regular-by-ending.)*

### C. Wire the resolver into the conjugator

Make the no-`model:` entry points consult the map:
`conjugate(infinitive:tense:)` (and `conjugateAll(...)`) should **look up the verb
→ class number → catalog model → conjugate**, instead of today's "infer a regular
base from the ending."

- **Keep the `model:`-taking overloads exactly as they are** (the tests and the
  alternate-forms path call them directly). Only the **no-`model:`** convenience
  overloads gain the map lookup.
- **Fallback policy (decide and document):** a verb **not** in the map (a typo, or
  a verb outside the 4,818) should fall back to **regular-by-ending** (today's
  behavior) — *or* return a new `.unknownVerb` error. Recommended: fall back to
  regular (it's the safe, useful default and keeps every existing no-model test
  green), but **log/comment** the choice. Whatever you pick, the existing
  no-`model:` tests (cantar/comer/subir/voseo/"arbitrary regular verbs") must stay
  green.
- **The irregularity score (§6.5) is unaffected** — it reads a model's `features`,
  and the catalog models carry exactly the primary features. Don't foreclose it.

## The cruxes (where Phase 6 bugs hide)

1. **One model, many verbs — prove the prefix payoff.** The map points `detener`,
   `contener`, `obtener`, … *all* at the tener model (31/31-1); the engine
   conjugates each on its **own** stem and the end-anchored features ride along.
   Spot-check a deep prefix (`reconocer`→reconozco, `descomponer`→descompuesto,
   `desdecir`→desdigo) so a stem-length or anchoring bug can't hide. (reír/oír
   compounds — sonreír/freír/desoír — only ride free **after** the prerequisite
   bug-fix lands; see the STATUS banner.)
2. **Catalog ⊇ every model number used.** If even one of the 106 numbers lacks a
   catalog entry, thousands of verbs silently break. Make this a hard,
   table-derived test, not a visual check.
3. **Marker stripping.** `aborregar(se)`, `acaecer (DEF)`, `apostar (1)` must key
   on `aborregar`, `acaecer`, `apostar`. A sloppy strip either misses verbs or
   collides them. Watch spacing (`acaecer (DEF)` has a space; `aborregar(se)` does
   not).
4. **Homonyms are genuinely two models.** `apostar/asolar/aterrar/atestar` each
   have two senses with different conjugations. A plain `[String:String]` map can't
   hold both. Decide: store `[String: [String]]` (a verb → its 1–2 class numbers)
   and have the resolver pick a documented **default** (e.g. the first / the more
   common sense) while preserving both for the future UI; **or** explicitly pick
   one sense for the engine and **log** the dropped one. Don't let the second
   `apostar` silently overwrite the first.
5. **Scale: you cannot eyeball 4,818 verbs.** ~290k forms. Verify
   **structurally** (counts, completeness, resolver wiring) plus a **representative
   sample** — at least one verb per class (~106), chosen to actually exercise the
   class's irregularity, conjugated through the **verb name alone** and checked
   against the oracle. A per-class sample is the gate; exhaustive is impossible.
6. **Canonical vs. scaffold models.** The test file holds both partial Phase-4 and
   full Phase-5 builds of a few verbs (conducir, andar, tener, decir). The catalog
   must use the **complete** one. Cross-check the catalog model's full paradigm
   against the oracle for those, so a stale partial can't sneak in.
7. **Resource actually ships.** A map that loads in the test bundle but not the
   app bundle (or vice-versa) is a silent failure. Verify loading from **both** the
   real app and the test target.
8. **Every verb is glossed, distinctly for homonyms (B2).** A glossless verb shows
   blank in the UI; two homonyms sharing one gloss are indistinguishable. Assert
   **0 empty glosses** across the 4,818, and that the 8 homonym senses carry the
   two *different* footnote glosses. The gloss is display-only — a bad one is a
   cosmetic bug, never a conjugation bug — so flag-and-move-on beats blocking, but
   nothing ships glossless.

## Out of scope (do NOT do this phase)

- **All UI** — the Models tab, the irregularity-score *display*, any
  Conjuguer-style screens. (Phase 6 is the last engine/data phase; UI follows.)
- **The irregularity-score computation** itself — just don't break the seam
  (alternates already stay out of the primary feature count; keep it that way).
- **Compound (perfect) tenses.**
- **Per-verb defectivity beyond the modeled classes.** The `(DEF)` marker in
  Annex B flags ~dozens of verbs used only in 3rd person / non-finite forms; the
  engine models defectivity only for the **abolir** class (3-14). Treat broader
  `(DEF)` as **out of scope** — map the verb to its conjugation model and **log**
  that its defectivity isn't enforced. Same for the footnote orthographic variants
  (fn10/13/14/16/… "new rules allow crie/crié") beyond what the alternate-forms
  machinery already yields: log, don't model.

## Gate (what "Phase 6 passes" means)

Unit tests in the real test target, all green, **303 prior tests still passing**:

- **Map loads:** exactly **4,818** verb entries parsed from the resource, **0**
  unparseable rows, homonyms preserved.
- **Glosses present (B2):** **0** of the 4,818 verbs is glossless; the old
  `verbs.xml` glosses are reused where the infinitive matches; the 8 homonym senses
  carry their two distinct footnote glosses. Any model-authored glosses the
  implementer was unsure of are surfaced in a reviewable list (not silently shipped).
- **Catalog complete:** a test deriving the **106** distinct model numbers from
  `annex_b_verb_models.md` asserts **every one resolves** to a `VerbModel2`.
- **Per-class sample:** one representative verb per class (~106 verbs) conjugates
  correctly **through the verb name alone** (`conjugate(infinitive:tense:)`, no
  explicit model) against the oracle — at minimum the slots that carry the class's
  irregularity (e.g. tener→tengo/tuve/tendré/ten; oír→oigo/oyó/oído; erguir→
  yergo + conjugateAll yergo/irgo; argüir→arguyo/arguyó).
- **Prefix payoff:** a clutch of prefixed compounds resolve via the map and
  conjugate correctly on their own stem (detener, reconocer, descomponer, desdecir,
  prever — and reír/sonreír + desoír **once the prerequisite reír/oír fix has
  landed**; see the STATUS banner).
- **Homonyms:** `apostar`/`asolar`/`aterrar`/`atestar` resolve per the documented
  policy (both senses retrievable, or one chosen + the other logged).
- **Fallback:** an off-list verb behaves per the documented policy, and every
  pre-Phase-6 no-`model:` test still passes.
- **(Non-gating) differential cross-check:** run the old engine's 214 verbs through
  the new resolver; agreement corroborates, disagreements are **logged as
  shipped-app bugs** (the book/RAE wins). Optional but valuable.

## Method (build/test mechanics)

- **Fast inner loop** — compile the engine standalone with a `main.swift` driver
  (far faster than the app build); include every `Conjugar/Models/*.swift` and your
  new catalog file. Pattern (from Phase 5b):
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar
  DIR=Models
  xcrun -sdk macosx swiftc $DIR/*.swift /tmp/p6/main.swift -o /tmp/check && /tmp/check
  ```
  (top-level statements need the driver file literally named `main.swift`; put it
  in its own dir. SourceKit "cannot find type" / "No such module 'Testing'" on
  single-file indexing is noise — the `swiftc` build and the `xcodebuild test` run
  are the source of truth.) For the **map** itself, prototype the extractor and the
  resolver against a few hundred rows in the driver before wiring the real resource.
- **Full test gate:**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=<an iPhone sim id>' \
    -only-testing:ConjugarTests/Conjugator2Tests
  ```
  (`xcrun simctl list devices available | grep iPhone` for a sim id; iPhone 15 Pro
  `6F676E8C-B98B-432C-9FD5-41E555921BC5` worked in Phase 5b.) All green, 0 failures.
- **Reproducible extraction.** **Generate** the XML resource (§B) with a checked-in
  script (extend or sit beside `docs/_extract_annexb.py`), so the 4,818 mappings are
  regenerable from the markdown, never hand-curated. Re-running the script must
  reproduce the resource byte-for-byte.

## Deliverable

- A **model catalog** in the app target (class number → `VerbModel2`, ~95 models,
  the few new builds for 4B-1/4B-5/4B-6/10 + the 29-2/30-1/31-1/32-1 aliases), with
  the tests refactored to exercise it.
- A **verb→model map** (the generated bundle resource + its extractor script),
  carrying an **English gloss per verb** (B2 — reused from `verbs.xml`/oracle/
  footnotes where available, authored for the rest, homonyms glossed distinctly),
  and the **resolver** wiring in `Conjugator2` (no-`model:` overloads consult the
  map, documented fallback + homonym policy). The gloss is display-only metadata,
  decoupled from conjugation.
- **Unit tests** covering the gate above, all passing on the real target, the 303
  prior tests still green.
- A one-line entry in `docs/blog_notes.md`
  (`/Users/josh/Desktop/workspace/Conjugar.mig/docs/blog_notes.md`) under today's
  date, and any new files added to its "Files created" footer.
- A clean **commit on `migration`** in `Conjugar.mig` (e.g. "Phase 6: verb→model
  map + model catalog + resolver"), **push only if the user asks**. End the commit
  message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

## Helpful context / pointers

- `docs/annex_b_verb_models.md` — the 4,818-row table (your data source) + its
  footnotes. `docs/_extract_annexb.py` — the existing extractor to extend/mirror.
- `docs/spanish_taxonomy.md` — **§1** "Prefixed verbs and the end-anchored
  constraint" + the prefix-accent exception (the 29-2/30-1/31-1/32-1 rationale),
  **§5** every class as base + features (the recipe for the few unbuilt models),
  **§6.5** the irregularity score (don't break it).
- `docs/spanish_models.md` — the oracle, for verifying the new models (4B-1 trocar
  ≈ line 722, 4B-5 desosar ≈ 766, 4B-6 avergonzar ≈ 779, 10 oír ≈ 1287) and the
  per-class sample expected forms.
- `Conjugator2Tests.swift` — the ~95 existing model exemplars to promote into the
  catalog, and the Swift Testing patterns (`expectForm`/`expectForms`, the
  `@Test(arguments:)` parameterization) to reuse.
- `Conjugar.mig/Conjugar/Models/verbs.xml` + the old `Conjugator.swift` /
  `Conjugar/Supporting/` — the app's existing resource-bundle loading pattern to
  imitate, the 214-verb differential set, **and the gloss source**: each `<verb>`'s
  `tn` attribute is the English gloss (`in="abrir" tn="open"`), in the terse style
  to match (B2 source 2 — but the oracle header wins on disagreement).
- Conjuguer prior art: `/Users/josh/Desktop/workspace/Conjuguer/Conjuguer/Models/`
  (`verbs.xml` = the same verb→model mapping for French; `VerbModelParser.swift` =
  how it loads). This Phase 6 is Conjugar's `verbs.xml` moment.

## Suggested next step (after Phase 6)

With the engine **and** the data complete, the project turns to **UI**: the Models
tab (as in Conjuguer), the irregularity-score display (design the "marked output"
API — form + irregular-character ranges — at the engine/UI seam; see
`blog_notes.md` "Deferred work" for the red-letter-highlighting plan), and the
other Conjuguer-style changes. Then fold `migration` into master and retire the
old engine + `verbs.xml`.
