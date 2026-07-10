# Example-Uses Pipeline (per-verb example sentences + Medieval Spanish examples)

Self-contained plan to finish the "example uses" feature: give each usage-ranked Spanish verb one
**modern-prose example sentence** (with translation) and, where one genuinely exists, a nested
**Medieval Spanish example** with a tap-through to *all* medieval examples for that verb. This is
Conjugar's port of the feature Conjuguer (French) and Konjugieren (German) already ship. The
original request is `prompts/example_uses.md`; the source/licensing manifest and running build log
is `docs/example-corpus-sources.md` — **read that manifest first**, it has the full source list,
licenses, attribution strings, and normalization rules this plan summarizes.

Work from the repo root: `/Users/josh/Desktop/workspace/Conjugar.mig`. Commits go to the
`migration` branch. Add a note to `docs/blog_notes.md` as you complete chunks.

---

## What is DONE (starting point)

1. **Sources chosen + licensing verified** — `docs/example-corpus-sources.md`.
2. **Corpus fetched & cleaned** — 21 texts in `corpus/originals/{medieval,literature,government,technology}/*.txt`
   (gitignored, re-fetchable). Provenance script `corpus/working/fetch_corpus.sh`; cruft remover
   `corpus/working/clean_corpus.py` (both tracked). Gutenberg boilerplate, PDF running
   headers/page-numbers, and the Cid's OCR front matter are already stripped.
3. **Form-dump DONE** — `ConjugarTests/Models/CorpusFormsDumpTests.swift` (a `.disabled` build-time
   tool) writes `corpus/working/forms.json` (ranked: **52,166 forms → 988 verbs**) and
   `forms_all.json` (all: **254,328 forms → 4,811 verbs**), each `{ "<surface form>": ["<infinitive>", …] }`.
   Regenerate: remove the `.disabled(...)` trait, then
   `~/.claude/skills/ios-build-verify/scripts/run_tests.sh --only-testing ConjugarTests/CorpusFormsDumpTests`,
   then restore the trait.
4. **Credits DONE** — `Info.creditsText` in `Conjugar/Supporting/Localizable.xcstrings` has an
   `^Example Uses^` / `^Ejemplos de Uso^` section (both `en` and `es`) crediting every source +
   Claude. **Edit `.xcstrings` only via `python3`/`json.dump`, never the Edit tool** (ASCII-quote
   foot-gun — see `docs/example-corpus-sources.md` / CLAUDE.md). If you add CC BY-SA vendor docs
   later (see "deferred" below), add a share-alike credit then.

## What REMAINS (this plan)

A. ✅ **DONE** — `grokked/` medieval prep (see "A. …" below for what was built + learnings).
B. ✅ **DONE** — `build_corpus_index.py` + `build_medieval_index.py` (see "B. …" below).
C. ✅ **DONE** — Mining workflow: subagents selected + translated → `ExampleUses.json` (888) /
   `MedievalExamples.json` (695 verbs, 2,139 lines), both dual-written.
D. ✅ **DONE** — Tail rescue + authored (Claude) residue → **988/988 ranked verbs** now have a
   modern example (61 corpus-rescued + 39 Claude-authored). See "D. …" below for what was built.
E. **← NEXT.** App-side Swift loaders + `VerbView` cards (mirror the etymology feature).
F. "Future plans": non-ranked verbs that have a medieval example also get a modern example
   (fabricated if none in corpus) + an etymology.

> **Status after A & B (2026-07-10).** All build scripts committed to `migration`. Artifacts that
> now exist and feed step C:
> - `corpus/working/corpus_index.json` (regenerable; gitignored) — modern candidates, **977/988
>   ranked verbs**, ≤5 per verb.
> - `corpus/working/medieval_index.json` (regenerable; gitignored) — reflex-matched medieval
>   candidates, **1,048 verbs** (444 ranked + 604 medieval-only special), ≤20 per verb.
> - `corpus/grokked/{cantar-de-mio-cid,milagros-berceo,libro-de-buen-amor}.txt` +
>   `medieval_verses.json` (tracked).
> - `corpus/working/oldspanish.py` (tracked) — the canonicalizer, importable by any verify script.
>
> Regenerate (from `corpus/working/`, in any order after the form-dump): `python3
> build_corpus_index.py` and `python3 build_medieval_index.py`. Both are idempotent; the medieval
> builder imports `oldspanish.py`. **The two `*_index.json` are gitignored** (regenerable) — a
> fresh clone must rebuild them, which also requires `corpus/originals/` to be present (re-fetch
> via `corpus/working/fetch_corpus.sh` + `clean_corpus.py` if missing — see the note in §C).

---

## The model to replicate (Conjuguer)

Read these as working templates:
- **Pipeline doc:** `../Conjuguer/docs/literature-example-corpus.md` (the whole approach: pre-conjugate
  with the app engine → deterministic token index → subagents only select/translate).
- **Build scripts:** `../Conjuguer/corpus/working/` — `build_corpus_index.py`, `build_tail_index.py`,
  `build_literature_examples.py`, `mine_examples.workflow.js`, `build_chanson_examples.py`,
  `build_classical_index.py`, `mine_classical.workflow.js`, `merge_classical.py`.
- **App models:** `../Conjuguer/Conjuguer/Models/` — `Example.swift`, `ExampleSource.swift`,
  `ChansonExample.swift`, `ExampleData.swift`, `ChansonData.swift`.
- **App UI:** `../Conjuguer/Conjuguer/Views/VerbView.swift` — `exampleCard(...)` (modern example +
  attribution) with a nested `chansonSection(...)` (medieval example + reference + a "next example"
  button that cycles all medieval examples for the verb). See `~/Desktop/VerbView.png` for the look.

Conjugar differs from Conjuguer in three ways to keep in mind: the engine is `TenseBridge`/
`Conjugator` (not `Conjugator.conjugatedString`); verbs are keyed by **bare infinitive** (no
`extraLetters`); and there are **three** medieval works, not one poem, so `MedievalExample` carries
a `work` field.

---

## Data model (output JSON shapes)

Mirror `Etymologies.json`'s dual-home convention: write the canonical export to `corpus/json/` AND
the bundled copy to `Conjugar/Models/` (the app loads the bundled copy). Both scripts must dual-write.

**`ExampleUses.json`** — keyed by infinitive (like Conjuguer's `literature_examples.json`):
```json
{ "abandonar": { "es": "…Spanish example sentence…",
                 "en": "…English translation…",
                 "source": "fortunata-y-jacinta-galdos-1887.txt",
                 "line": 379, "token": "abandonó" } }
```
Verbs whose example is Claude-authored carry `"source": "Claude (Opus 4.8)"`, `"line": null`.

**`MedievalExamples.json`** — keyed by infinitive → **array** (the tap-through shows all), like
Conjuguer's `chanson_examples.json` but with a `work`:
```json
{ "cabalgar": [ { "work": "cid",  "ref": "Cantar I, v. 330",
                  "os": "…Old Spanish line…", "tr": "…translation…" },
                { "work": "lba",  "ref": "copla 1487", "os": "…", "tr": "…" } ] }
```
`work` ∈ `cid` | `berceo` | `lba`. `ref`: for the Cid use `Cantar {I,II,III}, v. N`; for Berceo
`estrofa N`; for the Libro de buen amor `copla N`. `os` = the medieval line (verse). `tr` = a
Claude translation (English; keep parallel to the modern example's `en`).

---

## A. `grokked/` medieval prep (do this before the medieval index)  ✅ DONE

> **Built by `corpus/working/grok_medieval.py`** (verse isolation) **+ `corpus/working/oldspanish.py`**
> (the canonicalizer). Outputs: `corpus/grokked/{cantar-de-mio-cid,milagros-berceo,libro-de-buen-amor}.txt`
> (verse-only, for inspection) + `corpus/grokked/medieval_verses.json` (the `[{work, ref, text,
> cantar?}]` map). Counts: **3242 Cid + 3652 Berceo + 7271 LBA** verse lines; **Berceo 912 stanzas**
> (vs canonical 911), **LBA 1725 coplas** (vs 1728). The narrative below is the design that was
> implemented; how it actually turned out (block-classification approach, ~87% Cid recall traded for
> zero apparatus leakage, monotonic verse-number snapping) is in the code comments and `docs/blog_notes.md`.

The three medieval editions still contain their **modern editorial matter**, which must NOT feed
the medieval index (it would inject modern Spanish forms into "medieval example" lookups):
- **Cid** (`corpus/originals/medieval/cantar-de-mio-cid-menendezpidal-1913.txt`) — the retrieval
  cruft is gone, but Menéndez Pidal's footnotes are interspersed at page bottoms and a trailing
  "Valor nacional del Poema" essay remains. Also the head is a **prose** *Crónica* summary filling
  the lost first folio (period Old-Spanish, keep it or drop it — your call; it is not the verse).
  The verse lines characteristically carry a caesura (originally big internal gaps, now collapsed).
- **Berceo** (`milagros-berceo.txt`) and **Libro de buen amor** (`libro-de-buen-amor-juan-ruiz-1330.txt`)
  keep short modern introductions before the verse.

Produce, under `corpus/grokked/` (tracked — this is irreplaceable hand/verified work):
1. Cleaned **verse-only** text per work (footnotes/intros/essays removed). Heuristics: verse lines
   are short, medieval-spelled, and (Cid) many have the caesura; footnotes are modern-Spanish prose
   often starting `(1)`/`v.`/citations. A subagent pass per work that keeps verse and drops
   apparatus is reasonable; verify a sample.
2. A **line/stanza number map** so `ref` can be emitted (Cid cantar+verse; Berceo/LBA stanza).
3. The **Old→Modern canonicalizer** (below) as a small tracked Python module both the index builder
   and any verification reuse.

### Old→Modern Castilian normalization (canonicalize BOTH corpus tokens and generated forms before matching)
Rule order matters; apply as a canonicalizer, then compare canonical↔canonical:
1. **f- → h-** (and initial h- → ∅): *ferir→herir, fazer→hacer, fablar→hablar, fijo→hijo*.
2. **ç/z → c/z**, normalize sibilants: *fizo/fiço, plaça*.
3. **u↔v, i↔j↔y** by position: *auer→haber, biuo→vivo*.
4. **Cluster / Latinism simplification:** *dubda→duda, escripto→escrito, omne→hombre, nombre*.
5. **Apocope + enclitic fusion** — split enclitic pronouns off the verb *before* identifying it:
   *diz(e), quier(e), tien(e); tornós→tornó se, díxol→díxole, ques→que se*.
6. **Strong-preterite / suppletive EXCEPTION TABLE** (rules won't catch these — hand-list, a few
   hundred entries covers the Cid's high-frequency irregulars): *sopo→supo, ovo→hubo, dixo→dijo,
   troxo/traxo→trajo, aduxo→(aducir/traer), connusco→conocer, tovo→tuvo, estido→estuvo,
   priso→prendió, vido→vio, cavalgar→cabalgar, ferir→herir*.
Match strategy: canonicalize both sides, then also keep an edit-distance backstop; **hand-verify
the irregulars** (that is exactly the set the app cares most about, and the reflex the learner sees).

### Reflex-only attachment policy (the rule for which verb a medieval line attaches to)
Attach a medieval line to a modern verb **only when the line genuinely contains that verb's own
ancestor word-form** (its etymological reflex) — never merely a synonym. `ferir` attaches to
**herir** (its descendant), not to *golpear*. Use `forms_all.json` (all 4,811 verbs) for the
medieval index, not just the ranked set, because medieval reflexes routinely fall outside the
top-1000 (these are the "medieval-only special verbs", Conjuguer's Chanson-only analogue).

---

## B. `build_corpus_index.py` (modern tiers) + medieval index  ✅ DONE

> **Modern:** `corpus/working/build_corpus_index.py` → `corpus_index.json` (**977/988 ranked verbs,
> 98.9%**). **Medieval:** `corpus/working/build_medieval_index.py` → `medieval_index.json` (**1,048
> verbs = 444 ranked + 604 medieval-only special**). Both regenerable/gitignored. The medieval
> builder's precision guard: canonical keys shared by >8 verbs are dropped as over-merged; a
> per-verse-line hit keeps the longest matching token. Reflex fidelity verified (`connusco→conocer`,
> `priso→prender`, `firiendo→herir`, `aduxieron→aducir`, `oviéronla→haber`). The design below is
> what was implemented.

Port `../Conjuguer/corpus/working/build_corpus_index.py`. One tokenizing pass per source `.txt`
(NFC, lowercased, apostrophe/hyphen split), look each token up in `forms.json`, write
`corpus/working/corpus_index.json` = `{ "<infinitive>": [ {doc, line, token, text}, … ] }`.
- Gather candidates from each literature source independently, then merge round-robin with a
  **per-verb rotating lead author** so the first candidate is spread across the 8 works, not drained
  from whichever is scanned first. Government/technology append as fallback.
- Recognize the tiers by folder; priority order **literature → government → technology** for the
  ranked modern index. Print coverage, the author balance, and the zero-coverage tail.
- **Medieval index** — a separate builder over `corpus/grokked/` verse using the canonicalizer +
  `forms_all.json`, keyed by infinitive, applying the reflex-only policy, emitting `ref` metadata.
- Compound tenses in `forms.json` already emit only the participle, so a token maps to the right
  verb; a token mapping to several verbs (homographs: *vino* → venir + noun; *fue* → ir + ser) is
  recorded under each — the mining step disambiguates from context.

## C. Mining workflow (select + translate)  ← NEXT STEP

Shard the index (~30 verbs/shard) so each subagent reads only its slice. Fan out one subagent per
shard (parallel `Agent` calls, or the `Workflow` tool **only if the user has opted into multi-agent
orchestration** — a fresh context does not have that opt-in by default). Mirror
`mine_examples.workflow.js` and `prompts/etymology-pipeline.md`'s parallel-subagent pattern. Each
subagent, per verb: pick the **earliest candidate that is a genuine *verbal* use** (reject
same-spelled nouns/adjectives — *vino* the noun, *cena* the noun; reject glossary/list fragments),
re-open the source for the full **clean single sentence**, **translate** it (English), return a
schema-validated object. Aggregate → `ExampleUses.json` / `MedievalExamples.json`; **dual-write**
the bundled copies (`corpus/json/` + `Conjugar/Models/`). Then a report pass prints author/source
balance and the uncovered tail.

Batch sizing and transcript-extraction gotchas are the same as the etymology pipeline — reuse the
mechanics in `prompts/etymology-pipeline.md` (Steps 2–5: launch parallel, read results from the
persisted JSONL transcripts with `strict=False`, validate, merge via `json.dumps`).

### What the indices actually emit (verified building B — the mining INPUT)

- **`corpus/working/corpus_index.json`** = `{ "<infinitive>": [ {doc, line, token, text}, … ] }`.
  `doc` is the **repo-relative path** to the on-disk original
  (`corpus/originals/literature/fortunata-y-jacinta-galdos-1887.txt`); `line` is its **physical
  1-based line number**; `text` is a ≤200-char preview snippet centered on `token` (may be
  `…`-truncated mid-sentence — re-open `doc`:`line` for the real sentence). Candidates are already
  author-balanced and ordered, so "earliest" = first in the list. → produces the **modern** entry
  `{ es, en, source, line, token }`, where `source` is `os.path.basename(doc)` (the filename only,
  e.g. `fortunata-y-jacinta-galdos-1887.txt`) to match `ExampleSource`'s filename→attribution map.
- **`corpus/working/medieval_index.json`** = `{ "<infinitive>": [ {work, ref, os, token}, … ] }`,
  ≤20 candidates/verb, ranked most-distinctively-verbal first. `work` ∈ `cid` | `berceo` | `lba`;
  `ref` is already the final citation string (`"Cantar I, v. 330"`, `"estrofa 470"`, `"copla 900"`).
  → produces the **medieval** array entry `{ work, ref, os, tr }` (add `tr`, **clean** `os`, drop
  `token`).

### Gotchas discovered building A & B (read before mining)

1. **Line numbers reference `corpus/originals/` (gitignored, re-fetchable).** The mining step
   re-opens `doc`:`line`, so the originals must be present. On a fresh clone they won't be — run
   `corpus/working/fetch_corpus.sh` then `python3 corpus/working/clean_corpus.py` to restore them
   (the line numbers are physical lines in the *cleaned* files, which is what the indices were
   built against). On this machine they already exist.
2. **Clean the medieval `os` before writing it.** The grokked verse is *match-quality, not
   display-quality* — especially the Cid, whose OCR leaves garble (`£id`/`Qid` for "Cid", caesura
   artifacts like `… ondrada, [nancias;`, stray marginal-number fragments at line head). Berceo and
   LBA `os` lines are clean. The subagent must normalize the Cid `os` to a readable verse line
   (fix the garbled Cid, undo the caesura bracket re-ordering) when producing the final `os`. Do
   **not** modernize the spelling — keep it medieval (*ferir, dixo, cavalgar*); that is the point of
   the card.
3. **Do not "correct" the medieval `ref`.** Berceo `estrofa N` and LBA `copla N` are exact. Cid
   `v. N` is a running counter snapped to the OCR's marginal numbers — accurate at the poem's end
   (v. 3718 ≈ true 3730) but **approximate near the two internal cantar boundaries**; leave it as
   emitted (it is an illustrative citation, not a scholarly one).
4. **Reject the ~2 residual Cid modern-prose lines + spurious canonical collisions.** The
   canonicalizer is lossy, so a medieval token can attach to several verbs (homographs) *and* a
   rare footnote line can survive as a candidate. The subagent must confirm the `os` line genuinely
   realizes **that verb's own reflex** (reflex-only policy) and reject a line that reads as modern
   editorial prose or where the token is really a different verb/POS. This is the medieval analogue
   of the modern noun-rejection rule.
5. **Mine the full medieval set, including the 604 medieval-only special verbs.** `medieval_index.json`
   is keyed by bare infinitive over *all* 4,811 verbs; the 604 unranked "special" verbs (e.g.
   *yantar, aducir, catar, trovar, lidiar*) are exactly step F's set — produce their
   `MedievalExamples.json` arrays now so F only has to add the modern example + etymology.
6. **The 11 zero-coverage modern verbs go straight to step D.** They are absent from
   `corpus_index.json` (no verbal use in the modern corpus): *comportar, congelar, debutar, egresar,
   empatar, encabezar, medicar, postular, protagonizar, puntualizar, ultimar*. Don't wait on a
   corpus candidate for them.
7. **Sharding sizes:** modern = 977 verbs (~33 shards of 30); medieval = 1,048 verbs (~35 shards).
   Keep the two mines separate (different schemas, different rejection rules).
8. **Cervantes is 17th-c.** *quijote-cervantes-1605.txt* candidates use older orthography than the
   19th-c. novels; still modern-matchable, but prefer a 19th-c. work's candidate when one exists
   (the round-robin already spreads leads, so this is usually automatic).

## D. Tail rescue + authored residue  ✅ DONE

> **Result: 988/988 ranked verbs have a modern example** = 949 corpus-sourced (888 step C + 61 tail
> rescue) + 39 Claude-authored. The 100 step-C nulls split 89 (had noun-only candidates) + 11 (no
> candidate); tail rescue placed 61, and 39 (9 tail-nulls + 30 never-verbal) were authored. Both
> `ExampleUses.json` copies are complete. Scripts committed; the design below is what was built.

- **Tail rescue** (`build_tail_index.py`, ported from Conjuguer): verbs whose surface form collides
  with a common noun/adjective (*cocinar*→*cocina*, *dudar*→*duda*, *sumar*→*suma*, *forzar*→*fuerza*,
  *viajar*→*viaje*) came back null because the literature-first index drained all five slots with
  noun uses. Re-mines just the uncovered ranked verbs across all three modern tiers, ranking each
  candidate by a Spanish `verbalness` score (infinitive/gerund highest, participle next, the
  noun-shaped present forms score 0 and sink). **Learning:** a single per-doc gather cap let a
  hyper-frequent score-0 collision (the article *una*, which the engine maps to *unir*) fill the
  quota before the rare verbal form was scanned — fixed with a *split cap* (score-0 ≤2/doc, verbal
  ≤20/doc). Emits `tail_index.json` + `shards/tail_NNN.json`. Three `general-purpose` subagents mined
  the shards with a stricter rejection rule (a top-ranked candidate that's still a noun/homograph is
  a red flag); output `mined_tail_*.json`.
- **Authored residue** (`write_authored.py` → `mined_authored.json`): the 39 verbs with no clean
  verbal corpus use get an original **Claude (Opus 4.8)** sentence, flagged `"source": "Claude (Opus
  4.8)"`, `"line": null`, so AI authorship is explicit and never attributed to a corpus. Each is
  asserted to contain its `token` verbally and to carry no ASCII double-quote. Documented in
  `docs/authored-examples.md` (mirrors Conjuguer).
- **Merge:** `build_examples.py aggregate modern` now globs `mined_modern_*` + `mined_tail_*` +
  `mined_authored*` (disjoint key-sets) and re-merges — idempotent, rebuilds all 988 from shards.

## E. App-side integration (mirror the etymology feature)

The etymology feature is the exact template and is **already wired into `VerbView`**
(`Conjugar/Views/VerbView.swift`: `etymology = Etymology.text(for: verb)` in `init`, rendered by
`etymologyCard(...)` → `EtymologyText`, `.card()`). Add, mirroring it:
- **Models** (`Conjugar/Models/`, `nonisolated`): `Example.swift` (`es/en/source/token/line`),
  `ExampleSource.swift` (map source filename → attribution string + provenance/license, port of
  Conjuguer's enum — see the source→attribution table in `docs/example-corpus-sources.md`),
  `MedievalExample.swift` (`work/ref/os/tr`). Loaders `ExampleData.swift` + `MedievalData.swift`
  mirroring `Etymology.swift`/`EtymologyCache` (load-once, `@unchecked Sendable`, `nonisolated`;
  `ExampleData.example(for:)` returns one, `MedievalData.examples(for:)` returns the array).
- **JSON** dropped in `Conjugar/Models/` are auto-added to the target (`Supporting/` is a synchronized
  group; `Models/` — confirm, else it's the same synchronized treatment). The app bundles them.
- **`VerbView`**: add an example card (modern example + `ExampleSource.attribution`) and a nested
  medieval card (heading, `ref`, `os`, `tr`, and a "next example" button cycling
  `MedievalData.examples(for:)` when >1) — same slot as `etymologyCard`, using `.card()`. Port
  Conjuguer's `exampleCard`/`chansonSection`.
- **Localize** new UI strings in `L.swift` + `Localizable.xcstrings` (`VerbView.exampleUse`,
  `VerbView.exampleUses`, medieval heading, "next example", the `ref` format) — both `en` and `es`.
  Follow `docs/example-corpus-sources.md` / CLAUDE.md localization rules.

## F. Future plans (non-ranked verbs with a medieval example)

Per `prompts/example_uses.md`: a verb **outside** the ranked group that has a medieval example
should get not only the medieval example but also a **more-recent example** (fabricate one, Claude,
if the corpus has none) **and an etymology** (run the etymology pipeline for that verb —
`prompts/etymology-pipeline.md`, "Select verbs" mechanism). The medieval index (built over
`forms_all.json`) surfaces exactly this set.

---

## Corpus inventory (cleaned, in `corpus/originals/`)

- **medieval (3):** `cantar-de-mio-cid-menendezpidal-1913.txt`, `libro-de-buen-amor-juan-ruiz-1330.txt`,
  `milagros-berceo.txt`. **Gap:** *Poema de Fernán González* (only lending-restricted editions found).
- **literature (8):** `fortunata-y-jacinta-galdos-1887`, `marianela-galdos-1878`, `la-regenta-clarin-1885`,
  `pazos-de-ulloa-pardo-bazan-1886`, `pepita-jimenez-valera-1874`, `sombrero-tres-picos-alarcon-1874`,
  `la-barraca-blasco-ibanez-1898`, `quijote-cervantes-1605`. (*Doña Perfecta* was dropped as an
  annotated student edition and replaced by *Marianela*; *Quijote* is a supplement — 17th-c.
  orthography, flag before mining forms.)
- **government (5):** `es-trlpi-…` (PD, Art. 13), `es-ine-informe-anual-2024` (CC BY 4.0),
  `es-miteco-pniec-2023-2030` + `es-mitma-movilidad-2030` (Ley 37/2007 reuse), `co-dane-geih-jul2025`
  (CC BY 4.0). **Gaps:** MX INEGI + AR INDEC stats PDFs (non-extractable — retry).
- **technology (5):** `es-espana-digital-2026`, `mx-estrategia-digital-nacional`,
  `co-conpes-3975-transformacion-digital-ia`, `co-mintic-gobierno-digital`, `ar-agenda-digital-2022`.
- **Deferred (add if the consumer-imperative register is thin after mining):** Mozilla SUMO español,
  GNOME/Ubuntu Spanish docs (CC BY-**SA** — mine only short below-originality-threshold instructions,
  and add a share-alike credit to `creditsText`).

The `source` filename prefix drives `ExampleSource`'s attribution + license; the full per-source
attribution strings and the LatAm credits block are in `docs/example-corpus-sources.md`.

---

## Key paths & commands

- Ranked set: `VerbMap.shared.entries` filtered by `frequencyRank != nil` (989 ranked). Reusable
  work-list: `prompts/etymology-verbs.json` (`{rank, infinitive, gloss}`, 988 entries).
- Engine to conjugate/verify: `TenseBridge.conjugate(infinitive:tense:personNumber:)`,
  `DisplayTense.conjugatedTenses`, `VerbMap.shared.entry(for:)` (all `nonisolated`).
- Regenerate forms: enable + run `CorpusFormsDumpTests` (see "What is DONE" #3).
- Build: `~/.claude/skills/ios-build-verify/scripts/build_app.sh`. Tests:
  `run_tests.sh --only-testing ConjugarTests/<Suite>`. New tests → Swift Testing (see CLAUDE.md).
- Validate any `.xcstrings` edit: `python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.

## `.gitignore` (corpus)

`corpus/.gitignore` tracks durable artifacts only: `working/*.py`, `working/*.js`, `grokked/`,
`json/`. It ignores `originals/` (re-fetchable) and regenerable intermediates
(`working/forms*.json`, `working/*_index.json`, `working/shards/`, `working/mined_*.json`). New
build scripts under `working/` and finished JSON under `json/` are committed automatically; the
bundled `Conjugar/Models/*.json` copies are tracked normally.

## Foot-guns

- **Never inject the medieval editions' modern apparatus into the medieval index** (§A) — it is the
  single biggest correctness risk for the medieval tier.
- **`.xcstrings` edits go through `python3`/`json.dump`, never the Edit tool** (ASCII-quote corruption).
- **Reflex-only attachment** for medieval (§A) — a synonym is not an attachment.
- **Dual-write** every finished JSON (`corpus/json/` + bundled `Conjugar/Models/`), like the
  etymology and Conjuguer example scripts.
- **Homographs** (*fue*→ir+ser, *vino*→venir+noun) are recorded under each candidate; the mining
  subagent disambiguates from context and rejects non-verbal uses.
- SourceKit will spam false `Cannot find … in scope` on new view/model files — `build_app.sh` is
  authoritative.
