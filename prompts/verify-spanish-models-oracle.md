# Task: Verify `docs/spanish_models.md` as the conjugation test oracle

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal. The short version: we are
bringing Conjuguer's parsimonious, model-based representation of verb
irregularities to the Spanish app Conjugar, so that ~4,818 Spanish verbs can be
represented compactly instead of the 214 verbs Conjugar handles today.

A previous session transcribed the source book and designed the model taxonomy.
**Your job is narrow and important: verify the transcription so it can be trusted
as the test oracle for the conjugation engine we are about to build.** Do not
build the engine, change the taxonomy, or do data entry — just verify (and
correct) the transcription.

## Why this matters

The whole engine-test strategy leans on `docs/spanish_models.md` as a source of
truth. The engine will be validated by conjugating one exemplar verb per model
and asserting the result equals what `spanish_models.md` says. If the
transcription has errors, they will masquerade as engine bugs (or, worse, hide
real ones). So the oracle must be correct **before** it becomes load-bearing.

## What `spanish_models.md` is, and how it was produced

- It is a **faithful Markdown transcription** of Annex A ("Models of Verb Classes
  and Sub-classes") of the book `docs/spanish_verbs_made_simpler.pdf`.
- Source range: **PDF pages 180–227** (printed book pages 167–214). PDF page 180
  is the Annex title + the index of classes; the conjugation tables run from
  there to PDF page 227.
- It was produced by a model **reading the PDF page images and typing the tables
  out by hand** — i.e. effectively OCR-by-a-human-process. That means the likely
  error class is *transcription slips*, especially **written accents** (á é í ó ú
  / ñ / ü), which are easy to drop or misplace and are exactly what a conjugator
  must get right.
- Read the top "Conventions used in this file" section of `spanish_models.md`
  first — it documents person order, what blank cells vs `—` mean, and the
  `+`/`*`/`†` markers (these reproduce the book's own footnote markers).

## The task

Go through `spanish_models.md` model by model and **compare every conjugation
cell against the PDF**, correcting any discrepancy. Pay special attention to:

1. **Accents.** The single highest-risk area. Check every stem-stressed form
   (present indicative/subjunctive 1s/2s/3s/3p, imperative 2s) and every preterite
   1s/3s. Verify diphthong/accent marks (envío, actúo, reúno, prohíbe, etc.).
2. **The `+` / `*` / `†` markers** are placed correctly (they flag which
   orthographic/irregular rule produced a form; see each model's header).
3. **Blanks vs `—`.** In abbreviated sub-class tables a blank cell means "same as
   the parent model"; `—` means the form does not exist (defective `abolir`).
   Make sure these weren't confused.
4. **The non-standard table shapes** transcribed faithfully:
   - `-eron`/`-endo` variant tables: 2-4 empeller, 2-5 tañer, 3-5 bullir,
     3-6 bruñir (these show only Simple Past + the two imperfect subjunctives +
     gerund).
   - Alternate-forms tables (`A / B` cells): 7A-1 yacer, 7A-2 placer, 9-1 raer,
     9-2 roer, 6A-1 erguir.
   - One-line past-participle variants: 2-6 romper, 3-9…3-13, 5B-3 resolver,
     5B-4 volver, 6C-1 morir.
   - The regular/irregular comparison tables: 28-1 predecir, 28-2 bendecir,
     29-2 satisfacer, 30-1 suponer, 31-1 obtener, 32-1 convenir.
   - The defective `3-14 abolir`.
5. **Specific spots the previous session flagged as worth a hard look:**
   - **6B-4 reír** — the most marker-dense table (`+`/`*` on many forms). Verify
      río/ríes/ríe, rió, rieron, riendo, and the subjunctive carefully.
   - **10 oír 2p present** — the previous session normalized the image to `oís`;
     confirm against the PDF.
   - **18 argüir** — the diaeresis (ü) placement (argüimos vs arguyo, etc.).
   - **6A-1 erguir** — the `yerg-/irg-` alternates and footnote about yergamos.
   - **3-10 cubrir** — gloss already corrected to "to cover" (don't re-flag).

## Method (note the PDF-reading mechanics)

- The PDF is large; the Read tool **requires the `pages` parameter** and caps at
  **20 pages per call**. In practice the page images are heavy, so read in
  batches of ~6–7 pages. Useful batches: 180–185, 186–192, 193–198, 199–204,
  205–211, 212–218, 219–227.
- A useful cross-check oracle: the **existing, shipping Conjugar engine already
  conjugates 214 verbs correctly.** Its data lives in the working branch at
  `/Users/josh/Desktop/workspace/Conjugar.mig` (verb data in
  `Conjugar/Conjugar/verbs.xml`). For any verb that appears both there and as a
  model exemplar, it's a free correctness check. (You can also spot-check a
  handful of forms against the RAE if anything looks off in the book itself.)
- Where the book and reality genuinely disagree (the book has a couple of
  glosses/oddities), **trust the book for transcription fidelity** but leave a
  note — this file's job is to faithfully represent the book.

## Deliverable

- **Correct `spanish_models.md` in place** for any transcription errors you find.
- Write a short **`docs/spanish_models_verification.md`** report: what you
  checked, the list of corrections made (model + cell + before→after), anything
  the book itself gets wrong/ambiguous, and a closing **confidence statement**
  ("verified pages X–Y against the PDF; N corrections; remaining uncertainties: …").
- Add a one-line entry to `docs/blog_notes.md` under today's date noting the
  verification pass and the number of corrections.

## Helpful context / pointers

- Design doc (do **not** modify, but read for context): `docs/spanish_taxonomy.md`
  — the composition model (base root + composable features + residue), the
  resolved decisions (§6), and the build plan (§7). The exemplars you're
  verifying are what the feature catalog was derived from.
- The three regular roots are `cantar` (-ar), `comer` (-er), `subir` (-ir).
- Conjuguer (the French app this is modeled on) lives at
  `/Users/josh/Desktop/workspace/Conjuguer` if you want to see the target design.

---

## Suggested next steps (after the oracle is verified)

These follow the build plan in `docs/spanish_taxonomy.md` §7. Do them in fresh
sessions; don't start them as part of the verification.

1. **Read the existing Conjugar conjugator** (in `Conjugar.mig`). Goals: (a) mine
   its already-correct Spanish accent-placement and orthographic-change logic so
   the new engine doesn't reinvent it, and (b) set it up as a *differential
   oracle* — run old vs. new engines over the shared 214 verbs and diff.
2. **Phase 1 — engine skeleton.** Define the Spanish `Tense` type + ending-group
   types, encode the three regular roots (`docs/spanish_taxonomy.md` §3), and
   write a composition-aware `Conjugator` (base + ordered features, last-wins on
   slot conflicts). Gate: the three regular roots conjugate correctly under unit
   tests built from the verified oracle.
3. **Phases 2–5 — features, easy→hard**, each gated by unit tests against the
   oracle: orthographic + accent (§4.1–4.2) → stem-vowel + -ir raising (§4.3–4.4)
   → 1s/subjunctive + preterite + future (§4.5–4.7) → residue for the ~35 hard
   verbs (§5).
4. **Only then, Phase 6 — data entry:** the verb→model map for all 4,818 verbs
   (the easy, bulky part; prefixed verbs just reference their base's model).
5. **Then UI:** the Models tab and other Conjuguer-style changes.

Keep the rule from the taxonomy doc in mind throughout: **every feature's slot
operation must be anchored to the end of the stem**, so prefixed verbs
(`reconocer`, `deshacer`, …) conjugate correctly for free.

---

## Questions from the verifying session (2026-06-12)

A finding first, then questions. **The PDF has a clean, selectable text layer,
and accents survive intact** — `pdftotext -layout` on the conjugation pages
returns `canté / cantó / cantábamos / cantáis`, and `argüir / oír / ceñir / reír`
in the index, with columns preserved. Crucially this is an **independent
extraction path** from how the markdown was made (a model reading page *images*
by eye), so where `pdftotext` and `spanish_models.md` agree on a form that's
strong evidence; where they disagree it pinpoints exactly the transcription slip
to inspect. The text layer does *not* reliably carry the superscript `+`/`*`/`†`
footnote markers or convey merged-cell/blank-vs-`—` layout, so those still need
image reads.

1. **Primary method — OK to lean on the text layer?** My plan: diff every form
   against `pdftotext -layout` output as the primary accent/spelling oracle
   (fast, exact, independent), and reserve page-*image* reads for (a) the
   `+`/`*`/`†` marker placement, (b) the non-standard table shapes (§4 of this
   prompt), and (c) blank-vs-`—` disambiguation. The alternative reading of your
   instructions is that you want a *fresh by-eye image re-read of every cell* and
   deliberately do **not** want me to trust the embedded text (since the same
   text layer might have been the unreliable thing that pushed the original
   author to transcribe from images). Which do you want — text-layer-primary
   (my recommendation, with targeted image reads), or full image re-read?

2. **How exhaustive on the `+`/`*`/`†` markers?** These are the part the text
   layer can't verify, so they're the expensive part (careful image reads).
   Exhaustive marker verification across all 35 classes + ~60 sub-classes, or
   exhaustive only on the marker-dense / flagged tables (6B-4 reír, 6A-1 erguir,
   18 argüir, 10 oír, the orthographic-change classes) with spot-checks on the
   mechanically-regular derived sub-classes?

3. **How hard should I push on the book itself being wrong?** You said trust the
   book for transcription fidelity but leave a note on genuine book errors, and
   that RAE spot-checks are fine. If `pdftotext`, the markdown, *and* the book
   image all agree on a form that I believe is wrong Spanish (or the
   Conjugar.mig 214-verb engine disagrees), do you want that (a) only noted in
   the report, or (b) flagged inline in `spanish_models.md` too (e.g. a footnote)
   — recognizing the file's stated job is faithful transcription, not correction?

4. **Deliverable location confirm.** `Migration/` is not a git repo (no commit
   expected). I'll edit `docs/spanish_models.md` in place, write
   `docs/spanish_models_verification.md`, and add the one-liner to
   `docs/blog_notes.md`. Anything else you want captured?

---

## Answers (2026-06-12)

**1 — Text-layer-primary: yes, with image adjudication.** Lean on
`pdftotext -layout` as the primary screen for accents/spelling. Its value is
precisely that it's an **independent extraction path** from the by-eye image
transcription, so agreement is strong corroboration. One refinement: don't treat
`pdftotext` as ground truth on its own — where it **disagrees** with
`spanish_models.md`, adjudicate that specific cell with a page-*image* read
before changing anything (`pdftotext` can itself slip on ligatures, merged
columns, or the odd dropped accent). So: **text-layer diff = fast primary screen;
image read = tiebreaker/ground truth for every disagreement**, plus the
marker/layout/blank-vs-`—` items the text layer can't see. A full by-eye re-read
of every cell is **not** warranted now that you've shown the text layer carries
accents intact — that retires the original (hypothetical) worry about trusting
embedded text.

**2 — Markers: exhaustive where they exist, don't hunt where they don't.** Key
framing: the `+`/`*`/`†` markers are *annotations about which rule produced a
form* — they are **not** part of the conjugated string the engine will assert
against. So for the oracle's core job (correct forms) they're secondary.
Therefore: verify **forms** exhaustively (method in answer 1); verify **markers**
exhaustively only on the tables that actually carry them (reír, erguir, leer,
caer, oír, traer, decir, hacer, ceñir, -ducir, estar, dar, prever, and the
accent/orthographic-change classes), and on marker-free tables just confirm at a
glance that none were dropped. Spot-check — don't exhaustively re-derive — the
mechanically-regular derived sub-classes. If ever time-constrained, prioritize
forms over markers.

**3 — Both note *and* flag (non-destructively).** If `pdftotext`, the markdown,
and the book image all agree on a form you believe is wrong Spanish (or the
Conjugar.mig 214-verb engine disagrees), do both: (a) record it in the
verification report, and (b) flag it inline in `spanish_models.md` — but
**keep the book's form as transcribed** (the file's job is fidelity) and add a
short footnote/parenthetical noting the discrepancy and the believed-correct
form / the disagreeing source. Never silently overwrite a transcribed
*conjugated form* with your own Spanish. (The earlier `cubrir` gloss was an
obvious book typo with an unambiguous fix, so it was corrected outright; a
disputed conjugated form is different — annotate, don't replace.)

**4 — Deliverable plan approved; no repo, no commit.** There is no git repo for
this project yet, and that's fine — none is expected. Proceed exactly as you
listed: edit `docs/spanish_models.md` in place, write
`docs/spanish_models_verification.md`, and add the one-line `docs/blog_notes.md`
entry. Nothing else to capture.
