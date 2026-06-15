# Task: Multi-agent gloss verification (workflow) — Conjugar verb→model map (B2)

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal. The engine **and** the data are
done: Phase 6 shipped `Conjugar/Models/verbModelMap.xml` — all **4,818** verbs
mapped to a book model number, each carrying a terse **English gloss** (`tn`). This
task is a focused **quality pass on the glosses only** (display-only metadata,
**decoupled from conjugation** — a wrong gloss can never produce a wrong form). It
changes no engine code and no model assignment.

> ## This is a multi-agent **Workflow** task — explicit opt-in
> The whole point of this task is to run a `Workflow` (multi-agent orchestration).
> By handing you this prompt, the user is opting in. Author and run the workflow
> described below; do not do it as one inline pass. It is token-heavy by design.

## The hard constraint (read this first — it shapes everything)

**Josh cannot verify the glosses himself.** He has ~200 words of Spanish, never
formally studied it (he picked it up as an immigration lawyer and learned to
*conjugate* while building Conjugar). He is **unlikely to know whether any given
gloss is correct.** Therefore:

- **The workflow must be self-validating.** Confidence comes from **independent
  multi-agent consensus + dictionary citations**, never from human adjudication.
  "Flag it for Josh to check" is **not** an acceptable resolution — Josh can't
  check Spanish. The only things that may stay flagged are glosses where even a
  grounded, multi-agent consensus genuinely can't settle on one everyday sense
  (and those must say *why*, with sources).
- **Every change must be auditable by someone who *does* know Spanish.** Each
  proposed correction (and each previously-flagged gloss the workflow now confirms)
  must carry a **citation** — an RAE / Wiktionary / WordReference reference, or, for
  an everyday verb, an explicit "N/N agents independently agreed." The deliverable
  report is written for a future bilingual reviewer (or Josh's own spot-check via a
  dictionary), not for Josh to vet from knowledge.
- **Ground the long tail.** The easy verbs (`comer`, `abrir`) don't need the web;
  the rare / technical / regional / denominal tail (`zorrear`, `acharolar`,
  `xerografiar`, `monoptongar`) is exactly where a one-word gloss is shaky, so those
  **must** be web-grounded with a cited definition, not guessed.

## Where things stand (the gloss pipeline — learn this exactly)

The glosses are **generated reproducibly**, not hand-edited in the XML. The
extractor `docs/_build_verbmap.py` builds `verbModelMap.xml` from
`docs/annex_b_verb_models.md` (the 4,818-verb table) plus glosses sourced in this
**priority order** (first hit wins):

1. **Oracle class headers** — `docs/spanish_models.md` ("cantar — *to sing*"), the
   ~95 model verbs. **Book-sourced and load-bearing. Do NOT modify the oracle.**
2. **Old app `verbs.xml`** — `Conjugar.mig/Conjugar/Models/verbs.xml` `tn`
   attribute (~213 verbs), Josh's own older hand glosses. (The old engine is being
   retired; don't edit this file either.)
3. **Annex B footnotes** — the **4 homonyms** (`apostar`/`asolar`/`aterrar`/
   `atestar`, 8 senses), special-cased in the script's `HOMONYMS` table,
   default-sense-first. Book-sourced; treat as authoritative.
4. **Authored side-tables** — `docs/glosses/slice_*.tsv`, one per ~300-verb slice,
   `infinitive<TAB>gloss[<TAB>flag]`. **This is the ~4,556-gloss set the original
   single-pass authoring produced, and the ONLY layer you may edit.**

Key mechanics you must respect (verified against the script):

- **Only the authored TSV layer is editable.** Sources 1–3 win over the TSVs in
  `gloss_for()`, so editing a slice can only change a gloss whose value actually
  comes from the TSVs (the ~4,556 authored ones). For a verb whose gloss comes from
  the oracle/old-xml/footnotes, a slice edit is a **no-op** — if the workflow finds
  a real error in one of those ~262, it goes in the **report only** (flagged for a
  human, since the source is book/old-engine and out of bounds to auto-edit).
- **`terse()` style is enforced and must be preserved.** The script strips a
  leading "to " and keeps only the first comma-clause. Glosses are terse: `open`,
  not `to open`; one sense, no commas (`lower` not `lower, stoop, abase`). A
  multi-word phrase is fine (`make landfall`, `practice usury`); a comma is not.
- **The flag column accumulates — clearing a flag requires editing the slice in
  place.** `load_authored_glosses` appends to `flagged` whenever any file sets the
  flag; there is no override file that can *un*-flag a verb. So corrections and
  flag changes are **in-place edits to the `slice_*.tsv` files**: set column 3 to
  empty (or drop it) to clear a flag on a now-confirmed gloss; set it to `1` to
  (re-)flag a genuinely-unresolvable one.
- **Re-running the script reproduces the resource byte-for-byte** from the markdown
  + the TSVs. After editing slices you regenerate and the XML changes only where you
  changed a gloss.
- **Worklist outputs** the script regenerates: `docs/glosses_to_review.md` (the
  flagged set — currently **522** after a prior 4-gloss cleanup), `docs/
  glosses_missing.txt` (must stay empty), `docs/def_worklist.md` (9 defectives,
  unrelated to this task).

Current state: **4,818 rows, 0 glossless, 522 flagged.** The flagged set is the
**priority** target, but the flag was *self-reported* low confidence from a
single-pass author — there can be **confidently-wrong** glosses outside the 522
too, so the sweep should cover **all ~4,556 authored glosses**, not only the flagged
ones (the flagged ones just get the most scrutiny / always go through the adversarial
round).

## The task — design and run the workflow

Build a `Workflow` that verifies the authored glosses against independent
dictionary-grade consensus, **auto-applies** the corrections it can defend, and
emits an audited trail. Recommended shape (adapt as the budget allows):

### Phase 1 — blind gloss + compare (pipeline over slices)

Pipeline over the ~16 slices (or ~300-verb chunks). For each chunk, an agent
processes every verb:

1. **Gloss blind first (anti-anchoring).** Given only the Spanish infinitive (and
   its reflexive flag), the agent writes the best **terse everyday** English gloss
   from its own knowledge — *before* seeing the current gloss. (Pass the current
   gloss only in the compare step, so the agent isn't anchored to it.)
2. **Compare** its blind gloss to the current one and classify:
   - `agree` — current gloss is correct / a fine everyday sense.
   - `replace` — current is wrong, or not the primary everyday sense; propose the
     blind gloss.
   - `uncertain` — rare/technical/regional/denominal; can't be confident without a
     source.
3. Return a structured verdict per verb (use a `schema`):
   `{ infinitive, current, proposed, status, sense_note, needs_grounding }`.

Don't churn valid glosses: a current gloss that is *a* correct sense should stay
`agree` even if the agent would've phrased it differently — only `replace` for
**wrong** or **clearly-not-the-everyday-sense** glosses (prefer the primary,
everyday meaning, per the project's gloss convention).

### Phase 2 — adversarial consensus on the contested set (parallel, grounded)

Collect every verb that is `replace` **or** `uncertain` **or** currently
**flagged** (the 522). For each, run **N independent checkers** (recommend 3, with
*diverse lenses* — e.g. one RAE-grounded, one Wiktionary/WordReference-grounded, one
reasoning from morphology + the everyday-vs-technical distinction). Each checker:

- For anything rare/technical/regional or marked `needs_grounding`, **WebFetch a
  dictionary entry** (RAE `dle.rae.es`, Wiktionary, or WordReference) and **cite it**
  (URL + the gloss it supports). (WebSearch/WebFetch are available to workflow agents
  via ToolSearch.)
  - **Prefer Spanish Wiktionary (`es.wiktionary.org`) for the obscure tail.** It
    covers rare / regional / technical Spanish verbs far better than English
    Wiktionary; the agent reads the Spanish definition and renders the terse English
    gloss itself. Reach for `en.wiktionary.org` first only for everyday verbs, and
    **fall back to `es.wiktionary.org` whenever the English entry is missing the
    verb** (which is common in the long tail this pass exists to fix).
  - **If RAE or Wiktionary is blocked** — `robots.txt` disallow, a bot wall, or a
    page that only renders its content via JavaScript so `WebFetch` returns empty /
    boilerplate — **fall back to the Claude in Chrome MCP** (the browser tools,
    reachable via ToolSearch) to load the page in a real browser and read the
    rendered definition. Cite the same URL; note in the verdict that it was
    Chrome-rendered. (Caveat: an interactively-authenticated MCP like this may be
    absent in a headless/cron run — if so, the agent uses WebSearch snippets +
    consensus and marks the item `needs_grounding` rather than guessing.)
- Returns `{ infinitive, verdict_gloss, keep_or_replace, citation, confidence }`.

**Consensus rule** (decide and document, e.g.): a gloss is **confirmed** (or a
replacement **accepted**) when **≥2 of 3** checkers independently land on the same
sense *with at least one dictionary citation*. If the checkers split with no
citable resolution, it stays **flagged** with a `sense_note` explaining the
ambiguity and listing the candidate senses + sources — that's the *only* legitimate
residual flag.

### Phase 3 — synthesis (single step; applies + audits)

One synthesis step (not parallel — avoids concurrent file writes) takes the verdicts
and:

- **Edits the `slice_*.tsv` files in place**: write the accepted gloss (terse, no
  comma, no "to"), and **clear the flag** on every confirmed/corrected gloss; **set
  the flag** (`1`) only on the genuinely-unresolvable residuals. Preserve TSV format
  and verb order exactly (so the diff is just the changed glosses/flags).
- **Writes the audit report** `docs/gloss_verification_report.md`: every **change**
  (`infinitive: old → new`, consensus count, citation, one-line rationale), every
  **previously-flagged-now-confirmed** gloss (with its citation), and the **residual
  flags** (candidate senses + why unresolved). This file is the receipts — written
  for a bilingual auditor, since Josh can't vet the Spanish.
- **Reports out-of-bounds findings**: any high-confidence error in an oracle /
  old-`verbs.xml` / footnote gloss (sources 1–3, which slice edits can't touch) goes
  in the report under a clearly-labeled "needs human decision — book/old-engine
  sourced, not auto-edited" heading. Do **not** modify `spanish_models.md`,
  `verbs.xml`, or the script's `HOMONYMS` table.

Then **regenerate** the resource and verify (see Gate).

### Scale / budget

~4,556 authored glosses. Phase 1 is one cheap pass per slice (~16 agents). Phase 2
only hits the contested + flagged subset (likely ~600–1,500 verbs) × N checkers —
that's the token-heavy part; scale N and the grounding depth to `budget` if a token
target is set, else use N=3 and ground only the rare tail. `log()` any cap (e.g. "Phase 2
ran 3 checkers on 1,140 verbs; web-grounded 410 of them") so nothing is silently
skipped.

## The cruxes (where this task's bugs hide)

1. **Anchoring.** If the agent sees the current gloss first, it rubber-stamps it.
   Gloss **blind**, then compare. This is the single most important design point.
2. **Josh can't be the backstop.** Every unresolved item must be settled by
   grounded consensus or stay flagged *with sources*; "ask Josh" is not a resolution.
3. **Terse style + no commas.** A gloss with a comma is silently truncated by
   `terse()` to its first clause — so emit single-sense glosses. No leading "to".
4. **Only the authored layer is editable.** Slice edits to an oracle/old-xml/
   footnote-sourced gloss are no-ops; those errors are report-only.
5. **Flags clear only via in-place slice edits** (the flag list accumulates across
   files). Confirm a gloss → blank its flag column → it leaves `glosses_to_review.md`.
6. **Everyday vs. technical sense.** Prefer the common meaning (`apostar`→bet, not a
   military "post"); a *valid but secondary* sense isn't "wrong" — don't churn it.
7. **Reflexive-only verbs** (`rx`) are glossed in their reflexive sense already
   (`arrepentir`→repent, `atrever`→dare); keep that — don't "correct" to a
   non-reflexive gloss.
8. **Homonyms** (the 8 senses) are book-footnote-sourced and default-sense-first;
   leave them (report only if a sense looks wrong).
9. **Reproducibility.** Don't hand-edit `verbModelMap.xml`; edit slices →
   regenerate. Re-running must reproduce byte-for-byte.
10. **Can't eyeball 4,556.** The gate is structural (counts) + the audit report +
    the consensus discipline, not a human read-through.

## Gate (what "the gloss pass passes" means)

- `python3 docs/_build_verbmap.py` regenerates cleanly: **4,818 rows, 0 glossless**,
  `glosses_missing.txt` empty, homonyms intact, every `tn` comma-free and not
  starting with "to ".
- Every **change** and every **now-confirmed previously-flagged** gloss appears in
  `docs/gloss_verification_report.md` **with a citation or an N/N-agreement note**.
- The residual `glosses_to_review.md` count is **only** genuinely-ambiguous glosses,
  each with a sourced `sense_note` — and is **materially smaller** than 522 (the
  bulk of the flagged set should resolve, not persist).
- No edits to `spanish_models.md`, the old `verbs.xml`, or the `HOMONYMS` table;
  out-of-bounds findings are report-only.
- Conjugation is untouched: the `Conjugar.mig` test suite still passes (it doesn't
  assert on glosses except `noGlossless` + a few oracle-sourced reuses, none of
  which a TSV edit can break — a quick `xcodebuild test` of `VerbMap2Tests` confirms).

## Method / mechanics

- **Run it as a `Workflow`** (see the tool's guidance): `pipeline()` for Phase 1
  over slices; for Phase 2, pipeline each contested verb through the N-checker
  `parallel()` fan-out so a verb verifies as soon as its checkers return (don't
  barrier the whole set). Use `schema` on every agent so verdicts come back
  structured (no parsing). Give agents the `Explore`/web tools they need via the
  default workflow agent + ToolSearch (`WebFetch`, `WebSearch`).
- **Subagents write to disk, not back through context** (the prior gloss-authoring
  workflow had each agent write its slice's verdicts to a per-slice file) so 4.5k
  verdicts never re-enter the main context. The synthesis step reads those files.
- **Regenerate + verify**:
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/docs && python3 _build_verbmap.py
  ```
  then spot-check the changed `tn`s in
  `/Users/josh/Desktop/workspace/Conjugar.mig/Conjugar/Models/verbModelMap.xml`.
- **Test gate** (display-only change, but confirm green):
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=6F676E8C-B98B-432C-9FD5-41E555921BC5' \
    -only-testing:ConjugarTests/VerbMap2Tests
  ```

## Deliverable

- **Corrected `docs/glosses/slice_*.tsv`** (in-place: glosses fixed, flags cleared on
  confirmed, set only on true residuals) and the **regenerated
  `Conjugar/Models/verbModelMap.xml`** (4,818 rows, 0 glossless).
- **`docs/gloss_verification_report.md`** — the audited trail (every change +
  confirmed-flag + residual, all with citations / agreement counts; plus the
  report-only out-of-bounds findings).
- A shrunken, sourced `docs/glosses_to_review.md`.
- A one-line entry in `docs/blog_notes.md` under today's date, noting how many
  glosses were verified / changed / grounded / left flagged, and the workflow's
  token/agent cost.
- A clean **commit on `migration`** in `Conjugar.mig` (the regenerated
  `verbModelMap.xml` plus the updated slices / report / blog entry, all now in the
  repo). **Push only if Josh asks.** End the commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

## Helpful context / pointers

- `docs/_build_verbmap.py` — the extractor (sources, priority, `terse()`, flag
  handling, `HOMONYMS`). `docs/glosses/slice_*.tsv` — the editable authored layer.
- `docs/glosses_to_review.md` — the 522 flagged (priority set). `docs/
  annex_b_verb_models.md` — the 4,818 verbs + the homonym footnotes.
- `docs/spanish_models.md` (oracle, **read-only**) and
  `Conjugar.mig/Conjugar/Models/verbs.xml` (old, **read-only**) — sources 1 and 2.
- `Conjugar.mig/ConjugarTests/Models/VerbMap2Tests.swift` — the gloss tests
  (`noGlossless`, the reused-gloss spot-checks, homonym glosses).
- Grounding sources for the agents: RAE `https://dle.rae.es/<verb>`, Wiktionary
  `https://es.wiktionary.org/wiki/<verb>` / `https://en.wiktionary.org/wiki/<verb>`,
  WordReference `https://www.wordreference.com/es/en/translation.asp?spen=<verb>`.
  - **Spanish Wiktionary (`es.wiktionary.org`) is the best source for rare/obscure
    verbs** — try it whenever English Wiktionary lacks the verb (the long tail).
  - **When RAE/Wiktionary is blocked by `robots.txt` or JavaScript-only rendering,
    use the Claude in Chrome MCP** (browser tools via ToolSearch) to render the page
    and read the definition; cite the same URL. Falls back to WebSearch + consensus
    if that MCP isn't available in the run.
