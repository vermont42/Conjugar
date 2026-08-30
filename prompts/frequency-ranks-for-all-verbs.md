# Frequency ranks for all 4,811 verbs (CORPES XXI + Google Books)

Self-contained plan to give every verb in `verbModelMap.xml` a frequency-of-use rank, replacing
the 988 ranks that survived the capped 2026 Sketch Engine export. The research that chose the
sources is `docs/verb-frequency-sources.md` — **read it first**; every number below comes from
it and it explains why the paid options lose. The template to copy is Conjuguer, which shipped
the same design on 2026-08-28 (commits `fccc793`, `5336d9e`, `b6d4dcd` in `../Conjuguer`): a
`frequency/` pipeline folder at the repo root, counts stored in the XML, ranks derived at parse
time, estimates flagged `hp`, and a `docs/frequencies.txt` the app is tested against.

Work from the repo root, `/Users/josh/Desktop/workspace/Conjugar`, on a branch off `master`
(`frequency` is a fine name), one commit per step. Build and test through the `ios-build-verify`
skill (`export IBV_SCRIPTS=$(dirname "$(find ~/.claude/plugins/marketplaces -path '*ios-build-verify*' -name build_app.sh 2>/dev/null | head -1)")`;
then `"$IBV_SCRIPTS/build_app.sh"`, `"$IBV_SCRIPTS/run_tests.sh"`, `swiftlint`). Append a note
to `docs/blog_notes.md` as you complete chunks, and update `docs/project-structure.md` for every
file you add, rename, or retire.

---

## Read first

- `docs/verb-frequency-sources.md` — the source choice, the measured coverage, the `-se` merge,
  the calibration fit, the clamp, the credits wording, the reproduction recipes.
- `../Conjuguer/frequency/README.md`, `build_counts.py`, `apply_counts.py`,
  `generate_frequencies_txt.py`, `editorial-counts.json`, `report.md` — the pipeline shape.
  Conjugar differs in one important way: `verbModelMap.xml` is **generated** by
  `docs/_build_verbmap.py`, so there is no `apply_counts.py` step — the build script reads the
  counts table directly.
- `../Conjuguer/Conjuguer/Models/VerbParser.swift` (`ranked(_:)`, lines 47–95) and
  `../Conjuguer/ConjuguerTests/Models/ParserTests.swift` (lines 90–110) — rank derivation and
  its test.
- `../Conjuguer/docs/blog_notes.md`, entry "A frequency rank for every verb: GLÀFF replaces a
  capped 2021 export (2026-08-28)" — two bugs worth not repeating: rank grouping must key on
  the *dictionary key*, and Python's collation must be checked against Swift's by diffing, not
  assumed.
- `../Konjugieren/Konjugieren/Models/Verb.swift` lines 35–50 — the `hits` / `hitsAreProvisional`
  / `frequency` doc comments, which are the convention.
- `docs/_build_verbmap.py` — `load_frequency_ranks()`, `FREQ_GAP_VERBS`, the XML writer; and
  `CLAUDE.md` on editing `Localizable.xcstrings` (python only, never the Edit tool) and on
  writing new tests in Swift Testing.

## What the app ends up with

| Attribute of `<verb>` | Meaning |
|---|---|
| `hi` | CORPES XXI 1.5 lemma hits for the bare infinitive **plus** its `-se` lemma (`arrepentir` + `arrepentirse`). The primary key. Measured, or an estimate when `hp` is present. Every verb has one. |
| `gb` | Google Books Spanish 2020 verb-form tokens, 1950–2019, summed through the app's own paradigms. The tie-breaker. Present for 4,800 verbs. |
| `hp` | `y` when `hi` is an estimate (43 calibrated from `gb`, 4 editorial) rather than a measured CORPES count. |

`fr` disappears. `VerbMap` derives the dense rank 1…4,811 once per load by sorting on
`(hi desc, gb desc, infinitive in Spanish collation)`; homonym rows (`apostar` ×2, …) share
one rank because the counts belong to the spelling. `docs/frequencies.txt` renders the same
order, one `<rank> <infinitive>` per line, and a test asserts the app agrees with it verb for verb.

Expected outcome, from the research: `ser` #1, `estar` #2, `tener` #3, `ir` #4, `hacer` #5,
`poder` #6, `decir` #7, `haber` #8 (CORPES counts only its non-auxiliary uses — leave it
measured), ρ = 0.894 against today's ranks over the 985 verbs both have; the tail runs
`urdir` ≈ #2,000, `desecar` ≈ #3,000, `constipar` ≈ #4,000, `destaponar` ≈ #4,500, `yermar`
last among the measured; 47 verbs flagged `hp`.

---

## Step 1 — Fix `sobre(e)ntender` and `reeligir` (do this first, on its own commit)

Two map keys are not verbs, and no corpus will ever match them:

- `sobre(e)ntender` (`verbModelMap.xml` line ~4350, `cl="5A"`, `tn="infer"`) is Annex B's
  notation for the spelling pair *sobrentender / sobreentender*, transcribed literally from
  `docs/annex_b_verb_models.md` row 4356. Rename to **`sobrentender`** (the CORPES lemma, 253
  hits; the DLE lists both spellings).
- `reeligir` (line ~3946, `cl="6B-1"`, `tn="reelect"`; Annex B row 3954, "pedir (elegir)") is a
  misspelling of **`reelegir`** (CORPES 1,613; the DLE has only *reelegir*). The class stays
  `6B-1` — it conjugates exactly like `elegir`.

Do it in the pipeline, not by hand-editing the XML:

1. First check the source PDF (`docs/spanish_verbs_made_simpler.pdf`, gitignored but present;
   `docs/_extract_annexb.py` knows the Annex B pages) for those two rows. If the *book* prints
   the correct spelling, the transcription is wrong: fix `annex_b_verb_models.md` and say so in
   the journal. If the book itself prints `reeligir` / `sobre(e)ntender`, keep the transcription
   faithful and add a `SPELLING_FIXES = {"sobre(e)ntender": "sobrentender", "reeligir": "reelegir"}`
   table to `docs/_build_verbmap.py`, applied in `parse_annex()` right after `strip_markers()`,
   with a comment giving the reason for each.
2. Rename the gloss rows to match, because `gloss_for()` looks up the corrected key:
   `docs/glosses/slice_am.tsv:145` (`reeligir	reelect` → `reelegir	reelect`) and
   `docs/glosses/slice_an.tsv:224` (`sobre(e)ntender	infer` → `sobrentender	infer`). The
   `docs/glosses/phase1/*` files are an archive of the verification pass; leave them.
3. Re-run `python3 docs/_build_verbmap.py`. `git diff Conjugar/Models/verbModelMap.xml` must
   show exactly two changed lines (the rows move to their new alphabetical positions, so expect
   two deletions and two insertions, nothing else). `xmllint --noout Conjugar/Models/verbModelMap.xml`.
4. Grep the rest of the repo for the old keys (`rg -n 'sobre\(e\)ntender|reeligir' --glob '!docs/blog_notes.md' --glob '!docs/verb-frequency-sources.md' --glob '!prompts/'`).
   `ExampleUses.json`, `Etymologies.json`, `MedievalExamples.json`, and `VerbFamilies.swift`
   do not reference them today; confirm.
5. Add a data-quality test to `ConjugarTests/Models/VerbMapTests.swift` (Swift Testing) that every
   infinitive matches `^[a-záéíóúüñ]+$` — the test that would have caught this in June. Counts
   stay 4,811 (a rename, not an addition).
6. Regenerate `corpus/working/forms_all.json` so Step 2's Google Books aggregation sees the new
   spellings: remove the `.disabled(...)` trait on `CorpusFormsDumpTests`, run
   `"$IBV_SCRIPTS/run_tests.sh" --only-testing ConjugarTests/CorpusFormsDumpTests`, confirm the
   `Test run with N tests` line, restore the trait. (`forms.json` regenerates alongside; it is
   the ranked subset and still keys off `frequencyRank != nil`, which Step 4 changes — see there.)
7. Deeplink check after a build: `conjugar://verb/sobrentender` and `conjugar://verb/reelegir`
   open the verb; `conjugar://verb/reelegir` conjugates *reelijo, reeligió, reelegido* (plus the
   irregular participle *reelecto* is **not** expected — the map class is `6B-1`; note it in the
   journal if you think the book's class is wrong, don't fix it here).

Acceptance: build green, all tests green, the two-line XML diff, the new invariant test, a
journal paragraph.

## Step 2 — The `frequency/` pipeline: counts for every verb

Create `frequency/` at the repo root (like `corpus/`; nothing under `Conjugar/` because that is
a synchronized folder and would join the app target). Contents:

| File | Role | Tracked |
|---|---|---|
| `README.md` | Provenance: sources, versions, SHA-256s, licences, re-download recipe, what each XML attribute means, the estimate tiers, the clamp, the gates. Model it on `../Conjuguer/frequency/README.md`. | yes |
| `corpes_lemas.zip` | CORPES XXI 1.5 lemma list, 16,303,368 bytes, modified 26 Jun 2026, from `https://www.rae.es/corpes/assets/rae/files/corpes/corpes_lemas.zip`. **Download it in a browser** — `www.rae.es` answers `curl` with a Cloudflare challenge and the Wayback copies are access-restricted. Record its SHA-256 in the README. | no (gitignore `frequency/corpes_lemas.zip`, `frequency/gbooks/`) |
| `CORPES-LICENSE.txt` | The zip's `license.txt` (CC BY-SA 4.0), copied out so the licence travels with the derived data. | yes |
| `extract_gbooks_verbs.sh` | Streams the three Spanish 1-gram shards (`http://storage.googleapis.com/books/ngrams/books/20200217/spa/1-0000{0,1,2}-of-00003.gz`, 631 MB + 1,114 MB + 1,478 MB) through `gunzip | grep '_VERB\t'` into `frequency/gbooks/verb_{0,1,2}.tsv` (~500 MB, gitignored). The recipe is in the research doc's appendix. | yes |
| `aggregate_gbooks.py` | `frequency/gbooks/*.tsv` + `corpus/working/forms_all.json` → `gbooks-verb-lemmas.json`: per infinitive, the 1950–2019 token sum, with the 264 ambiguous forms (`fui`, `fue`, `era`, …) split by the EM loop in the research doc's appendix. Lower-cases forms, keeps only `^[a-záéíóúüñ]+$`. | yes |
| `gbooks-verb-lemmas.json` | 4,811 rows — the only Google Books artifact that needs to exist for a rebuild. | yes |
| `build_counts.py` | `corpes_lemas.zip` + `gbooks-verb-lemmas.json` + `editorial-counts.json` → `verb-counts.json` + `report.md`. | yes |
| `verb-counts.json` | One row per distinct infinitive: `{"corpes": N, "corpes_se": N, "gbooks": N, "estimate": {"count": N, "tier": "gbooks-fit" \| "editorial", "reason": "…"}}` (`corpes`/`corpes_se` omitted when unmeasured; `estimate` present only then). | yes |
| `editorial-counts.json` | The hand-assigned tier with a one-line reason each. | yes |
| `generate_frequencies_txt.py` | `verbModelMap.xml` → `docs/frequencies.txt` in the app's exact order; `--check` compares without writing. | yes |
| `report.md` | The last build's report. | no |

`build_counts.py`, in order:

1. **Targets.** The distinct `in=` values of `Conjugar/Models/verbModelMap.xml` (4,811 after
   Step 1) and their current `fr` ranks, for the continuity check that only works on the first run.
2. **CORPES.** Open the zip's `frecuencia_lemas_corpes_1_5.txt` (53.6 MB; two header lines,
   then 2,058,524 tab-separated rows: *Elemento*, one-letter class, absolute *Frecuencia*, two
   per-million columns). Keep class `V` (14,077 lemmas, 67,493,311 tokens). For each target,
   `corpes = V[inf]`, `corpes_se = V[inf + "se"]`; `hi` is their sum. The research measured
   4,691 direct matches, 72 rescued by `-se` (`arrepentir` 0 + 8,541, `adentrar` 0 + 7,214,
   `suicidar` 0 + 5,480, …), six with both (`resentir` 1 + 2,669, `conquistar` 12,617 + 1, …),
   and 48 with neither. Gate: those numbers, ±0 — a different count means a different file
   version or a parser slip, and the report must say which.
3. **Google Books.** `gb` from `gbooks-verb-lemmas.json`; 4,800 verbs have one.
4. **Calibration.** Least-squares fit of `log(hi)` on `log(gb)` over the verbs with both nonzero
   (4,757 on the research day: `log(hi) = −3.94 + 0.920·log(gb)`, R² = 0.884). Gate: R² ≥ 0.75.
   Report the residual quartiles and 5th/95th percentiles.
5. **Estimates.** For the 43 targets CORPES lacks but Google Books counts, `hi = min(exp(fit(gb)),
   clamp)`, tier `gbooks-fit`, where the clamp is the measured `hi` at rank 1,000 (5,935 on the
   research day — recompute, never hard-code). Expected: `podrir` ≈ 2,764 (≈ #1,454),
   `remplazar` ≈ 1,109, `trasmutar` ≈ 297, `trasbordar` ≈ 149, `rescribir` and `salgar` ≈ 96,
   `mixtificar` 78, `rembolsar` 58, … down to `abetunar`, `bribonear`, `xerocopiar`,
   `xerografiar`, `yodurar`, `desaclimatar` at 1. For the four with nothing anywhere —
   `aguachicolear`, `desenfurruñar`, `desentablillar`, `presintonizar` — read
   `editorial-counts.json`. Write those four entries yourself, each with a reason (0 is a fine
   count; the point is that it is chosen). While you are there: `aguachicolear` came from the
   legacy app's `EXTRA_VERBS` with the gloss "steal water"; check whether CORPES has
   `huachicolear` (Mexican, to steal fuel) and record what you find in the reason — a
   misspelled neologism is the audit's problem, not this step's, but the reason field is where
   it gets noticed. A measured count is never estimated, and a measured 1 stays 1.
6. **Gates before writing.** Every target has `hi`; the top three by `hi` are `ser`, `estar`,
   `tener`; every estimate ≤ clamp; `hp` population = 47; Spearman vs the old `fr` ranks ≥ 0.85
   over the verbs both have (expect 0.894). Refuse to write `verb-counts.json` otherwise.
7. **Report** (`report.md`): the coverage numbers, the fit, the clamp, every estimate with its
   implied rank, the `-se` rescues, the 20 biggest rank moves against the old `fr` (expect
   `hacendar` 465 → ~4,063, `adir` 985 → ~4,121, `jamar`, `paginar`, `visar`, `timar` — esTenTen
   tagger artifacts CORPES corrects), and a **gaps** section: every CORPES `V` lemma with ≥ 100
   hits that is not a target, minus `-se` forms of targets (`joder` 8,890 and the other fifteen
   G-rating removals will top it; then `colmar` 3,466, `aflorar` 3,295, `monitorear` 3,221,
   `reinventar` 2,995, `migrar` 2,868, `develar` 2,706, `fungir`, `ameritar`, `desolar`,
   `orbitar`, `reelegir` — which Step 1 just added — …). That list replaces
   `docs/freq_unmatched.txt` and is input to a later verb-list audit, not to this plan.

Acceptance: `python3 frequency/build_counts.py` writes `verb-counts.json` with 4,811 rows and
passes its gates; `report.md` reads sensibly; the README's SHA-256 matches the downloaded zip.

## Step 3 — `docs/_build_verbmap.py` reads the counts and emits `hi` / `gb` / `hp`

1. Replace `FREQ_RANKS` / `load_frequency_ranks()` with `load_verb_counts()` over
   `frequency/verb-counts.json`. Fail loudly if any emitted infinitive lacks a row (the pipeline
   is upstream of the map, so a verb added to Annex B or `FREQ_GAP_VERBS` without a count is a
   build error, not a silent unranked verb).
2. Emit `hi="…"` on every row, `gb="…"` where present, `hp="y"` where estimated; drop `fr`.
   Homonym rows repeat the same attributes (rank is per spelling). Update the XML header comment
   and the module docstring; the attribute table in Step 0 is the wording to reuse.
3. Retire the `freq_unmatched.txt` writer (the gaps section of `frequency/report.md` supersedes
   it) and update the report lines (`frequency-ranked (fr)` → `counted (hi) … / estimated (hp)`).
4. `FREQ_GAP_VERBS` stays — those six are real verbs — but its comment now describes the 2026
   esTenTen list as history ("surfaced by the 2026 frequency pass"), not as the live source.
5. `python3 docs/_build_verbmap.py`, then `python3 frequency/generate_frequencies_txt.py`
   (which mirrors the Swift sort of Step 4: `hi` desc, `gb` desc with a missing `gb` sorting
   *below* a present one, then the infinitive in Spanish collation — accents secondary, `ñ` a
   letter between `n` and `o`). `xmllint --noout` the XML. The diff to `verbModelMap.xml` is
   large (every row gains attributes); that is expected once and never again.

Acceptance: the XML validates, every `<verb>` carries `hi`, `docs/frequencies.txt` exists with
4,811 lines and `ser` first.

## Step 4 — Swift: counts in, ranks derived, the widget keeps its window

`Conjugar/Models/VerbMap.swift`:

1. `VerbMapEntry` gains `hits: Int` (`hi`), `bookHits: Int?` (`gb`), `hitsAreProvisional: Bool`
   (`hp`), and `frequencyRank` becomes a **non-optional `Int`**. Copy Konjugieren's doc comments
   for the three: the rank is "the number the UI renders as `#168`"; the flag "affects nothing
   the user sees … and exists so the provisional population stays findable rather than quietly
   becoming permanent."
2. `VerbMapParser` reads the three attributes and builds entries with a placeholder rank
   (`0`); a missing or non-numeric `hi` is an `assertionFailure` in debug (the map is generated,
   so this is a build error surfacing late) and ranks last in release. After `parser.parse()`,
   `VerbMap` runs `ranked(_:)`: sort the entry keys by `(hits desc, bookHits desc with nil last,
   infinitive by Spanish collation)`, assign `index + 1`, rebuild each entry with
   `withFrequencyRank(_:)`. Both `init`s share it. Expose `rankCount` (4,811) for the tests and
   any future "#n of m" label.
3. **Isolation.** `VerbMap` is `nonisolated` and `@unchecked Sendable`; `VerbSort` is a plain
   (MainActor-isolated by default) enum whose `spanish` locale the widget writer already
   avoids for that reason. Put the collation locale somewhere nonisolated — a `nonisolated
   static let spanish = Locale(identifier: "es")` on `VerbMap`, say — and have `VerbSort` use it,
   rather than reaching into `VerbSort` from the parser.
4. `Conjugar/Models/VerbSort.swift`: `.frequency` becomes `lhs.frequencyRank < rhs.frequencyRank`;
   the three `nil` branches go.
5. `Conjugar/Views/VerbBrowseView.swift` (lines ~176 and ~211): the badge's `if let` becomes
   unconditional. `Text(verbatim: "#\(rank)")` renders `#4811` without a separator today; keep
   that (it matches the widget and Konjugieren) unless Josh wants `#4,811`.
6. `Conjugar/Utils/WidgetSnapshotWriter.swift`: `rankedVerbs()` currently means "the ~1,000 with
   a rank" and feeds both the verb of the day and the widget quiz. Every verb now has a rank, so
   without a window the widget would one day serve `churruscar`. Replace it with
   `verbOfTheDayPool()` = the frequency-sorted entries `.prefix(verbOfTheDayPoolSize)`, with
   `static let verbOfTheDayPoolSize = 1000` and a comment saying why (Conjuguer windows by
   "has an example" instead, which here would be 1,340 verbs — defensible, but 1,000 preserves
   today's behavior exactly). The day-to-verb hash `abs(dayOffset &* 127) % pool.count` is
   unchanged, so the pool's *size* changing from 988 to 1,000 changes which verb a given day
   gets; that is fine, note it in the journal.
7. `Shared/WidgetSnapshot.swift`: `frequencyRank` stays `Int?` in the JSON contract (old
   snapshots on disk must still decode); fix the comment ("nil if outside the top ~1000" → "the
   verb's rank among all 4,811; optional only for decoding older snapshots"). `SnapshotReader`'s
   placeholder `frequencyRank: 8` can stay (`tener` is #3 now; the placeholder is a sample, not
   data — change it to 3 if you like).
8. `ConjugarTests/Models/CorpusFormsDumpTests.swift` line 50: `.filter { $0.frequencyRank != nil }`
   → `.filter { $0.frequencyRank <= 1000 }` (the example-uses pipeline's "usage-ranked" set),
   and update the header comment.

Tests (all Swift Testing; `@MainActor` only where a suite touches MainActor types — `VerbMap`
is nonisolated):

- **Parser fixture** (new, in `VerbMapTests` or a new `VerbMapRankingTests`): write a five-verb
  XML to a temp URL and load it with `VerbMap(url:)`; assert `hits`, `bookHits`, `hitsAreProvisional`
  parse; a provisional count ranks like any other; ties on `hi` fall to `gb`; a missing `gb`
  sorts below a present one; the residual tie falls to Spanish collation (`ñoñear` after
  `nadar`, before `obrar`); homonym rows share one rank; `rankCount` counts spellings.
- **Whole-map invariants**: ranks are exactly `1...4811`, each once; `ser` #1, `estar` #2,
  `tener` #3; every entry has `hits ≥ 0`; exactly 47 entries are provisional; no provisional
  entry ranks above 1,000.
- **`docs/frequencies.txt` agreement**: read the file from the repo (`#filePath`-relative, the
  way `CorpusFormsDumpTests` finds the repo root) and assert line *n* names the verb the map
  ranks *n* — all 4,811 lines. This is the check Conjuguer did by hand with a throwaway Swift
  script; make it permanent. If it fails on a tie group, the Python collation key is wrong, not
  the app — fix `generate_frequencies_txt.py` and regenerate.
- Update `VerbMapTests`: the `frequencyRank` argument table (`haber` is #8, `desvelar` is no
  longer #1000 — pin only the top three plus one mid-list spot check you take from
  `docs/frequencies.txt`), delete the "verbs outside the top 1000 have no rank" test, rewrite
  "exactly 988 ranked verbs" as the invariants above, drop the rank column from the
  `FREQ_GAP_VERBS` table (those six ranks were esTenTen's).
- Update `VerbSortTests`: the `entry(_:rank:)` helper takes a non-optional rank; delete the
  unranked-verb cases; `frequencySortOfVerbMapStartsWithSer` asserts `last?.frequencyRank == 4811`.

Acceptance: build green; `run_tests.sh` green with the count line present; `swiftlint` clean.

## Step 5 — Copy, credits, licence

Every `.xcstrings` edit goes through `python3` + `json.load`/`json.dump` (never the Edit tool —
CLAUDE.md explains the ASCII-quote foot-gun); validate with
`python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`;
both `en` and `es` get `"state": "translated"`.

1. **`Info.creditsText`** (`en` and `es`): add a section. The research doc's "shape of the
   change" §5 has the wording in both languages (headings `^Verb frequencies^` /
   `^Frecuencias de los verbos^`, the RAE + CORPES XXI 1.5 credit, the CC BY-SA 4.0 link in
   `%…%`, the note that pronominal lemmas were merged and ties ordered with Google Books Ngram
   data under CC BY 3.0, and that the derived counts are shared under the same licence). Place it
   after the WordReference section, before the Claude/AI credits if there are any.
2. **`Info.purposeAndUseText`** (`en` and `es`): "The most common verbs also show their frequency
   ranks; "ser", the most commonly used verb, is #1." → "Every verb shows its frequency rank;
   "ser", the most commonly used verb, is #1." / "Los verbos más comunes también muestran su
   rango de frecuencia" → "Todos los verbos muestran su rango de frecuencia". Mirror the change
   in `docs/purpose_and_use_proposed.txt` line 31 so the draft and the catalog agree.
3. **`README.md`**: the "Verb browser" bullet gains "every verb carries a frequency rank derived
   from the Real Academia Española's CORPES XXI"; add a short **Data sources** subsection above
   **License** naming CORPES XXI (CC BY-SA 4.0, link) and Google Books Ngrams (CC BY 3.0), one
   sentence each. Attribution for a share-alike source belongs where a reader of the repo will
   see it, not only inside the app.
4. **`docs/release_notes.txt`**, the 3.0 "A NEW CONJUGATION ENGINE" paragraph: add "Every verb
   now carries a frequency rank, from ser at #1 to the rarest at #4,811, based on the Real
   Academia Española's CORPES XXI corpus."
5. **`docs/verb-frequency-sources.md`**: add a one-paragraph *Status* block under the title
   saying the recommendation shipped on the date, pointing at `frequency/README.md`.

## Step 6 — Retire the 2026 files and update the caches

- Delete `docs/SpanishVerbFrequencyRanks.txt`, `docs/verbs.csv`, `docs/freq_unmatched.txt`.
  Keep `docs/SpanishVerbFrequencies.xml` as provenance of the ranks users saw in 2026, with its
  `project-structure.md` comment changed to say it is no longer read by anything.
- `docs/project-structure.md`: add the `frequency/` tree (every file above, with the same
  "Tracked" facts), `docs/frequencies.txt`, and the changed comments; remove the deleted files.
- `docs/blog_notes.md`: the narrative — what the RAE publishes and under what licence, the
  `-se` merge, the 47 estimates and the clamp, `haber` at #8 and why it stays, the biggest movers
  (`hacendar`, `adir`, `jamar` were esTenTen artifacts), the collation check, the widget window,
  and anything that surprised you.

## Step 7 — Optional courtesy note to the RAE (Josh sends it)

Not required by the licence — CC BY-SA 4.0 is the whole grant — but the RAE's 2021 post on the
frequency lists invites contact at `corpus@rae.es`, and a note costs nothing. Claude cannot send
mail; Josh sends this from his own account, plain text, once the credit wording in Step 5 is
final (so the note describes what actually shipped):

Update: Josh sent this email on August 30, 2026.

```
Asunto: Uso de las listas de frecuencias del CORPES XXI en una aplicación gratuita

Estimado equipo del CORPES:

Les escribo para informarles de que Conjugar, una aplicación gratuita y de
código abierto para iOS que conjuga 4.811 verbos españoles
(https://github.com/vermont42/Conjugar), utiliza la lista de frecuencias de
lemas del CORPES XXI (versión 1.5) para ordenar sus verbos por frecuencia de
uso, conforme a la licencia CC BY-SA 4.0 con la que publican los datos. La
aplicación atribuye la fuente a la Real Academia Española y al CORPES XXI en
su pantalla de créditos, enlaza la licencia e indica las modificaciones
(fusión de los lemas pronominales con su verbo base y desempate con los
recuentos de Google Books). Si prefieren una fórmula de atribución concreta,
la incorporaré con gusto.

Muchas gracias por publicar estos datos.

Josh Adams
vermontcoder@gmail.com
```

## Step 8 — Verify in the simulator, then ship the branch

1. `"$IBV_SCRIPTS/build_app.sh"`, `"$IBV_SCRIPTS/run_tests.sh"` (confirm the `Test run with N
   tests` line), `swiftlint`, `xmllint --noout Conjugar/Models/verbModelMap.xml`,
   `python3 frequency/generate_frequencies_txt.py --check`.
2. `"$IBV_SCRIPTS/launch_app.sh"`; Browse tab in Frequency order shows `ser #1`, `estar #2`,
   `tener #3`; search `churruscar` and confirm it carries a four-digit rank; switch to
   Alphabetical and back. `"$IBV_SCRIPTS/screenshot.sh" frequency-all-verbs`.
3. `xcrun simctl openurl "$UDID" conjugar://verb/sobrentender` and `…/reelegir` open the verbs.
4. Info tab → Credits shows the new section in English; switch the simulator to Spanish (or set
   `-AppleLanguages (es)` in the scheme) and check the Spanish paragraph and the markup renders
   (the `%…%` link, no stray `^`).
5. After a launch, read the widget snapshot from the App Group container (the
   `WidgetConstants.snapshotURL` path) and confirm `frequencyRank` ≤ 1000 for the day's verb.
6. Open the PR against `master` with the journal entry in place.

## Out of scope (record, don't do)

- The verb-list audit the `report.md` gaps section enables (`colmar`, `aflorar`, `monitorear`,
  `migrar`, `empoderar`, `tuitear`, 521 candidates), the DLE variant pairs (`rembolsar` /
  `reembolsar`, …), and `aguachicolear`.
- A "panhispanic" badge from the CORPES *Diccionario de frecuencias*' country counts.
- Enforcing defectivity for `respectar` / `adir` (still `def_worklist.md`'s job).
