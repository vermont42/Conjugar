# Verb frequencies

Everything behind the `#rank` badge in the Verbs tab. Every one of Conjugar's 4,811 verbs
carries a frequency-of-use rank, from `ser` at #1 to the rarest at #4,811, and this folder
is where those numbers come from.

The design decision worth knowing up front: **the app stores counts and derives ranks at
parse time.** `verbModelMap.xml` carries `hi`, `gb`, and `hp` per verb; `VerbMap` sorts on
them once per load and assigns 1…4,811. Adding a verb therefore never renumbers the others
and never requires touching a rank, and the two counts are the provenance of the rank a
user sees. The predecessor scheme stored an `fr` rank per verb and could only ever cover
the 988 verbs a capped export happened to include.

The research that chose these sources — including everything that was rejected, and why —
is [`../docs/verb-frequency-sources.md`](../docs/verb-frequency-sources.md).

## What the app ends up with

| Attribute of `<verb>` | Meaning |
|---|---|
| `hi` | CORPES XXI 1.5 lemma hits for the bare infinitive **plus** its `-se` lemma (`arrepentir` + `arrepentirse`). The primary sort key. Measured, or an estimate when `hp` is present. Every verb has one. |
| `gb` | Google Books Spanish 2020 verb-form tokens, 1950–2019, summed through the app's own paradigms. The tie-breaker. Present for almost every verb. |
| `hp` | `y` when `hi` is an estimate rather than a measured CORPES count. Affects nothing the user sees; it exists so the provisional population stays findable rather than quietly becoming permanent. |

`docs/frequencies.txt` renders the resulting order, one `<rank> <infinitive>` per line, and
`VerbMapRankingTests` asserts the app agrees with it verb for verb.

## Sources

### CORPES XXI 1.5 — the primary key

The Real Academia Española's *Corpus del Español del Siglo XXI*: written and oral texts
from Spain, the Americas, the Philippines, and Equatorial Guinea, version 1.5 (June 2026),
about 420,000 documents and 455 million orthographic forms.

| | |
|---|---|
| File | `corpes_lemas.zip` (**not tracked** — see below) |
| Source | `https://www.rae.es/corpes/assets/rae/files/corpes/corpes_lemas.zip` |
| Size | 16,303,368 bytes |
| SHA-256 | `68eca9615e06eb7372ad61bd60e1d8a8f248018b5601485107a939cfaefa5ddb` |
| Contents | `license.txt` (1,798 bytes) and `frecuencia_lemas_corpes_1_5.txt` (53,589,177 bytes) |
| Licence | **CC BY-SA 4.0**, per the zip's own `license.txt`, copied here as `CORPES-LICENSE.txt` |

**Download it in a browser.** `www.rae.es` sits behind Cloudflare and answers `curl` with a
JavaScript challenge (HTTP 403, a "Just a moment…" page), and the Wayback Machine's copies
of the file are access-restricted. Open the URL in Chrome or Safari, then move the file
here and check the SHA-256 above with `shasum -a 256 frequency/corpes_lemas.zip`.

The lemma file is tab-separated with CRLF line endings: two header lines, then 2,058,524
rows of *Elemento*, a one-letter word class, the absolute *Frecuencia*, and two per-million
columns. The pipeline keeps class `V` — 14,077 lemmas, 67,493,311 tokens.

Two things about the CORPES numbers are worth knowing before they surprise you:

- **416 of its verb lemmas end in `-se`.** CORPES lemmatizes a pronominal verb with the
  clitic attached; Conjugar keys the same verb bare. `hi` is therefore
  `count(infinitive) + count(infinitive + "se")`, which is what recovers `arrepentir`
  (8,541 hits, all under `arrepentirse`), `adentrar`, `suicidar`, and seventy-odd others
  that would otherwise have looked like zeroes.
- **`haber` ranks eighth, not second.** CORPES appears to annotate a compound tense as one
  verbal element under the participle's lemma, so `haber` is counted only in its
  independent uses (`hay`, `haber de`) — 1,034,648 tokens against `ser`'s 7,661,318. There
  is no separate auxiliary lemma anywhere in the file. For a learner's list, eighth is
  fine, and it is left measured rather than corrected.

### Google Books Ngrams (Spanish, 2020 release) — the tie-breaker

The `_VERB`-tagged 1-grams of the 2020 (v3) Spanish export, summed through the app's own
paradigms. **CC BY 3.0.**

| | |
|---|---|
| Source | `http://storage.googleapis.com/books/ngrams/books/20200217/spa/1-0000{0,1,2}-of-00003.gz` |
| Size | 631 MB + 1,114 MB + 1,478 MB, streamed, never saved |
| Kept | `gbooks/verb_{0,1,2}.tsv` (**not tracked**) → `gbooks-verb-lemmas.json` (tracked) |
| Licence | CC BY 3.0, `https://creativecommons.org/licenses/by/3.0/` |

CORPES ties thousands of verbs in the tail — a 455-million-form corpus simply cannot
separate `filetear` from `apostrofar` — and this is what breaks those ties. It is
emphatically **not** fit to rank on its own: Google's tagger marks a noun `_VERB` whenever
it coincides with a form of a rare verb, so `versar` collects 4.1 million tokens (from
*verso*) against CORPES's 1,337, `salar` 1.3 million (from *sala*) against 649. Used only
to order verbs CORPES has already tied, that contamination can move a verb inside its tie
group and no further.

## Files

| File | Role | Tracked |
|---|---|---|
| `README.md` | This file. | yes |
| `CORPES-LICENSE.txt` | The zip's `license.txt`, copied out so the licence travels with the derived data. | yes |
| `corpes_lemas.zip` | The CORPES download. Re-fetch in a browser per above. | no |
| `extract_gbooks_verbs.sh` | Streams the three Google Books shards through `gunzip` and a `_VERB` filter into `gbooks/`. | yes |
| `gbooks/verb_{0,1,2}.tsv` | The filtered `_VERB` rows, ~830 MB. | no |
| `aggregate_gbooks.py` | `gbooks/*.tsv` + `corpus/working/forms_all.json` → `gbooks-verb-lemmas.json`. | yes |
| `gbooks-verb-lemmas.json` | Per-infinitive 1950–2019 token sums. The only Google Books artifact a rebuild needs. | yes |
| `build_counts.py` | `corpes_lemas.zip` + `gbooks-verb-lemmas.json` + `editorial-counts.json` → `verb-counts.json` + `report.md`. | yes |
| `editorial-counts.json` | The hand-assigned counts, with a reason each. | yes |
| `verb-counts.json` | One row per distinct infinitive. What `docs/_build_verbmap.py` reads. | yes |
| `generate_frequencies_txt.py` | `verbModelMap.xml` → `docs/frequencies.txt`; `--check` compares without writing. | yes |
| `report.md` | The last build's report. Regenerated every run. | no |

## Rebuilding

```bash
# Only if the two source downloads are missing (see above for corpes_lemas.zip):
./frequency/extract_gbooks_verbs.sh
python3 frequency/aggregate_gbooks.py

python3 frequency/build_counts.py            # -> verb-counts.json + report.md
python3 docs/_build_verbmap.py               # -> Conjugar/Models/verbModelMap.xml
python3 frequency/generate_frequencies_txt.py  # -> docs/frequencies.txt
xmllint --noout Conjugar/Models/verbModelMap.xml
```

`aggregate_gbooks.py` reads `corpus/working/forms_all.json`, which is itself generated (by
`ConjugarTests/CorpusFormsDumpTests`, normally disabled — see that file's header). **If the
verb list changed, regenerate the form dump first**, or the new verbs will silently get no
Google Books count.

## How a count becomes a rank

1. **Targets.** The distinct `in=` values of `verbModelMap.xml`.
2. **Measure.** `hi = corpes[inf] + corpes[inf + "se"]`, either term optional.
3. **Calibrate.** Least squares of `log(hi)` on `log(gb)` over every verb both sources
   count nonzero. The build gates on R² ≥ 0.75 and reports the residual spread, which is
   the honest error bar on an estimate.
4. **Estimate.** A verb CORPES never saw but Google Books did takes
   `hi = min(exp(fit(gb)), clamp)`, tier `gbooks-fit`. The **clamp** is the measured `hi`
   at rank 1,000, recomputed every run: an estimate is a guess, and a guess must not be
   able to land a verb in the part of the list a learner actually reads.
5. **Decide.** A verb neither source knows takes a count from `editorial-counts.json`, with
   a written reason. Zero is a fine answer; the point is that a human chose it.
6. **Flag.** Every estimated row, either tier, carries `hp="y"`.
7. **Gate.** The build refuses to write `verb-counts.json` unless every target has an `hi`,
   the top three are `ser`/`estar`/`tener`, no estimate exceeds the clamp, the provisional
   population is the expected size, and Spearman against the retired `fr` ranks clears 0.85
   over the verbs both rankings have. A ranking this visible should fail loudly, not
   silently ship `hacendar` at #465 again.
8. **Rank.** `VerbMap` sorts on `(hi desc, gb desc with absent below present, infinitive in
   Spanish collation)` and assigns 1…4,811. Homonym rows (`apostar` ×2, …) share one rank,
   because the counts belong to the spelling.

**A measured count is never estimated, and a measured 1 stays 1.** CORPES lists only what
it saw, so there are no measured zeros to mistake for missing data.

## Attribution

The derived counts in `Conjugar/Models/verbModelMap.xml` and `docs/frequencies.txt` are
adapted from the CORPES XXI lemma-frequency lists and are therefore shared under the same
**CC BY-SA 4.0** licence, separately from the app's AGPL. The changes made to the RAE's data
are: pronominal lemmas merged into their base verb, ties ordered with Google Books Ngram
counts (CC BY 3.0), and a flagged estimate substituted where CORPES has no lemma at all.
The Credits screen (`Info.creditsText`) and `README.md` carry the user-facing version of
this notice.
