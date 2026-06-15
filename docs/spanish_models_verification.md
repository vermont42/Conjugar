# Verification of `spanish_models.md` against the source PDF

**Date:** 2026-06-12
**Source of truth:** `docs/spanish_verbs_made_simpler.pdf`, Annex A ("Models of
Verb Classes and Sub-classes"), PDF pages 180–227 (printed book pages 167–214).
**File verified:** `docs/spanish_models.md`.

## Purpose

`spanish_models.md` will be the **test oracle** for the Spanish conjugation
engine: the engine is validated by conjugating one exemplar verb per model and
asserting equality with this file. It must therefore be a faithful transcription
of the book *before* it becomes load-bearing. This pass checks every conjugation
cell, every footnote marker, and the structural/defective-table shapes.

## Method

The transcription was originally produced by a model **reading the PDF page
images by eye**. For this verification I used a deliberately **independent
extraction path** as the primary screen, then adjudicated every disagreement on
the page image:

1. **Primary screen — embedded text layer.** `pdftotext -layout` over pages
   180–227. The PDF has a clean, selectable text layer that preserves Spanish
   accents and diaeresis intact (e.g. `canté / cantó / cantábamos / cantáis`,
   `argüí / oís / ceñir / reír`) and keeps column structure. Because this is a
   different process from the original by-eye image read, agreement on a form is
   strong corroboration and any disagreement pinpoints the exact cell to inspect.
2. **Ground truth / tiebreaker — page images.** For every text-layer
   disagreement, and for everything the text layer cannot represent, I read the
   page image and treated it as authoritative. The text layer **cannot** show:
   - the superscript `+` "additional written accent" box markers (these are
     dropped on extraction), and
   - merged-cell layout / blank-vs-`—` distinctions.
   It *can* and does carry the `*` and `†` markers positionally.
3. **Marker policy (per task answers).** Forms verified exhaustively everywhere;
   markers verified exhaustively on every table that bears them. Image reads were
   done for all `+`-bearing tables (2-3 leer, 9 caer, 10 oír, 14-1 prever,
   6B-4 reír, 25 dar, 33 traer) and the flagged dense/irregular tables.

### Image pages read for adjudication

PDF pp. **188–192** (leer markers; empeller/tañer/bullir/bruñir starred forms),
**203–204** (reír, ceñir, dormir), **207–212** (caer, oír, salir/valer/asir,
ver, prever, discernir), **219–222** (dar, poder, querer, decir, predecir,
bendecir), **224–227** (suponer, obtener, tener, venir, convenir, traer,
-ducir, andar). All other cells were verified via the text layer.

## Corrections made

Two transcription errors were found and fixed in place. Both are the *same*
class of slip: the book deliberately prints a hypothetical **incorrect** form
(marked `*`) **without** a written accent, to contrast it with the correct
preterite; the transcriber reflexively "corrected" it by adding the accent.

| Model | Cell | Before | After |
|---|---|---|---|
| **2-4 empeller** | Simple Past, *él* | `empelló (not *empellió)` | `empelló (not *empellio)` |
| **3-5 bullir** | Simple Past, *él* | `bulló (not *bullió)` | `bulló (not *bullio)` |

**Why these are correct.** The book is internally consistent: the parallel
sub-classes **2-5 tañer** (`tañó (not *tañio)`) and **3-6 bruñir**
(`bruñó (not *bruñio)`) print the starred form *unaccented*, and the markdown had
already transcribed those two faithfully. Both `pdftotext` and the page images
(PDF pp. 189, 192) confirm the book prints `empellio` and `bullio` with no
accent. The fix restores fidelity and removes the internal inconsistency.
(Note: these starred strings are pedagogical "do-not-write-this" forms, not
conjugations the engine must produce, so they have no effect on engine tests —
but the oracle should still match the book exactly.)

## Spot-checks that *passed* (high-risk areas, no change needed)

- **6B-4 reír** (the most marker-dense table). Every `+` and `*` verified against
  the image: present `río⁺ ríes⁺ ríe⁺ reímos⁺ … ríen⁺` with **`reís` correctly
  unmarked**; preterite `rió*`, `rieron*`, `reíste⁺/reímos⁺/reísteis⁺`;
  subjunctive `ría⁺ rías⁺ ría⁺ … rían⁺` with **`riamos`/`riáis` correctly
  unmarked**; all imperfect subjunctives `*`; `riendo*`, `reído⁺`, `ríe⁺/reíd⁺`.
  Flawless.
- **10 oír** — `2p` present confirmed as **`oís`**; and the easily-missed
  **`oímos⁺` in the *present*** 1p (the book does mark it) is present and correct.
- **18 argüir** — diaeresis placement correct throughout (`arguyo / argüí /
  arguyó / argüimos / argüís / argüía`); the text layer rendered every `ü`.
- **6A-1 erguir** — `yergo/irgo` alternates and the `yergamos/yergáis²` footnote
  about RAE non-recognition transcribed correctly.
- **9-1 raer / 9-2 roer / 7A-1 yacer / 7A-2 placer** — all alternate-form (`A / B`)
  cells and the `pluguieron/plegue/plega` "not RAE" footnotes correct.
- **`+` marker tables** (2-3 leer, 9 caer, 14-1 prever, 25 dar) — all `+`
  placements match the images exactly (e.g. dar marks only `dé⁺` 1s/3s; prever
  marks the six monosyllable-derived forms `preví⁺ prevés⁺ prevé⁺ previó⁺
  prevéis⁺ prevén⁺` and `prevé⁺` imperative).
- **`*`/`†` tables** (6B-3 ceñir, 28 decir, 29 hacer, 33 traer, 34 -ducir) —
  every marker position confirmed, incl. traer's image-only `traído⁺`.
- **Non-standard shapes** — the `-eron/-endo` tables (2-4, 2-5, 3-5, 3-6),
  one-line past-participle variants (2-6, 3-9…3-13, 5B-3, 5B-4, 6C-1), the
  regular/irregular comparison tables (28-1, 28-2, 29-2, 30-1, 31-1, 32-1), and
  the defective **3-14 abolir** (blanks for `nosotros/vosotros`, `—` elsewhere)
  all transcribed faithfully.
- **Index of classes** (35 classes + sub-class lists) matches the book index.

## Notes on the book itself (faithfully preserved, not "fixed")

These are properties of the source, recorded for downstream awareness. None were
altered in the transcription except the one explicitly-sanctioned gloss typo.

- **3-10 cubrir gloss.** The book glosses cubrir as "to close"; this is a clear
  book typo (cubrir = *to cover*). It was corrected to "to cover" in a prior
  session (sanctioned: an unambiguous gloss fix, not a conjugated form). Flagged
  here for the record.
- **28-1 predecir / 28-2 bendecir.** The book gives predecir an *irregular*
  future/conditional (`diré`-style) per the RAE, while noting Moliner/VOX show
  the regular `predeciré/predeciría`. The book's own footnote captures this
  disagreement; transcribed as-is. (Worth a second look when the engine reaches
  these — modern usage favors the regular forms.)
- **Old/disputed alternates** (`pluguieron`, `plegue`, `plega` for placer;
  `yergamos/yergáis` for erguir; `rao` for raer) are flagged by the book as
  not RAE-recognized and are transcribed faithfully with those notes.
- **Bold/italic styling** in the book (it bolds the orthographic-change letters,
  e.g. **QU** in `toque`, and italicizes stem-stressed forms) is intentionally
  *not* reproduced; the forms themselves are faithful. (In the raw text layer
  this styling surfaces as stray uppercase, e.g. `toqUe`, `cueZo`, `neGUe` — a
  rendering artifact, correctly lowercased in the markdown.)

## Confidence statement

**Verified PDF pages 180–227 (all 35 classes + ~60 sub-classes) against the
source.** Every conjugation cell was screened against the independent
`pdftotext -layout` extraction, and every disagreement plus every `+`-marker
table and flagged irregular table was adjudicated on the page image.
**2 corrections** made (2-4 empeller, 3-5 bullir — both the unaccented starred
preterite). Accents, diaeresis, the `+`/`*`/`†` markers, blank-vs-`—` cells, and
all non-standard table shapes are confirmed faithful.

**Remaining uncertainties:** none material to engine testing. The only residual
items are *the book's own* editorial choices (the predecir future per RAE vs.
other dictionaries; the various "not RAE-recognized" archaic alternates), which
are correctly transcribed as the book presents them and are not transcription
defects. The oracle can be trusted as load-bearing.

## Addendum (post-verification): voseo supplement

After this verification, a **`# Voseo (supplement — not from the book)`** section
was appended to `spanish_models.md`. The scope statement above — "verified
faithful transcription of the book" — covers **only the material above that
heading.** The voseo section is a deliberate, separately-sourced addition (the
book is peninsular and has no voseo): its forms follow the RAE and match the
shipping app's existing `vos` slots, and it exists so the engine can gate `vos`.
It was **not** checked against the PDF (there is nothing in the PDF to check it
against) and must **not** be counted toward the transcription's confidence
statement. Treat it as an engine-reference rule set, not as verified book text.
