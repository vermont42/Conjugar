# Example-Uses Corpus — Sources & Plan

Step 1 of the "example uses" feature (`prompts/example_uses.md`): give each usage-ranked
Spanish verb one **modern-prose example sentence**, plus — where one genuinely exists — a
nested **Medieval Spanish** example (the Conjugar analogue of Conjuguer's *Chanson de Roland*
card, with a tap-through to *all* medieval examples for that verb). This document is the
**source-and-licensing manifest** and the pipeline plan. It mirrors Conjuguer's
`docs/*-corpus-sources.md` manifests and reuses the approach in
`../Conjuguer/docs/literature-example-corpus.md` (pre-conjugate every verb with the app's own
engine, index the corpus deterministically, and let subagents do only the select/translate
judgment work).

> **Status:** sources identified & licensing verified; owner decisions taken (2026-07-10 —
> see **Decisions** at the bottom). Corpus fetch + pipeline construction now in progress.

## How it maps to what's already in the repo

The etymology feature is the working template — build the examples feature the same way:

| Concern | Etymology (existing) | Examples (planned) |
|---|---|---|
| Ranked verb set | `VerbMap.frequencyRank` (`fr` attr in `verbModelMap.xml`; **989** ranked verbs, 1-based) | same set |
| Work-list | `prompts/etymology-verbs.json` (988 + select) | reuse it; add the medieval-only "special" verbs (verbs *not* in the ranked set that nonetheless appear in the Cid — Conjuguer's "Chanson-only 144" analogue) |
| Bundled data | `Conjugar/Models/Etymologies.json`, keyed **language → infinitive → text** | `Conjugar/Models/ExampleUses.json` (modern examples) + `MedievalExamples.json` (Cid/medieval), keyed by infinitive |
| Load path | `Etymology.swift` → `EtymologyCache` (`nonisolated`, `@unchecked Sendable`, load-once) | mirror as `ExampleUses.swift` / same cache shape |
| UI | etymology card under conjugations in `VerbView` (wiring is the pending lifecycle step) | example card + medieval card in the same spot, per `~/Desktop/VerbView.png` |

Because the whole engine (`Conjugator`/`TenseBridge`/`VerbMap`) is `nonisolated`, the
form-dump step can run in the test target exactly as Conjuguer's `CorpusFormsDumpTests` does —
conjugate every ranked verb across all tenses/persons, emit `{ surface-form → [verb id] }`, and
match whole generated word-forms against the corpus tokens (no hand-written stem regexes).

---

## Tier 1 — Medieval Spanish (the *Chanson de Roland* analogue)

**Primary spine: *Cantar de Mio Cid* (Poema de Mio Cid), c. 1200.** The Castilian national
epic and the exact Iberian analog of the *Chanson de Roland* (~3,730 anisosyllabic verses,
three *cantares*, anonymous). Public domain worldwide.

- **Working plain text (RECOMMENDED):** Menéndez Pidal 1913 *normalized/critical* edition on
  the Internet Archive — `https://archive.org/details/poemademiocid00men` → full-text TXT
  `https://archive.org/stream/poemademiocid00men/poemademiocid00men_djvu.txt` (~570 KB, PD).
  This layer keeps the medieval morphology (*ferir*, *aduxo*, *connusco*) but with consistent
  spelling — the sweet spot for form-matching. OCR needs light cleanup.
- **Paleographic reference (spot-checks only):** Washington & Lee / UT Austin digital edition
  `https://miocid.wlu.edu/` — parallel paleographic + normalized + English, folio-by-folio.
  Site markup is © UT Austin (reference, not bulk download); the underlying poem is PD.
- **Not viable:** Project Gutenberg has **no** Spanish-original (English translations only);
  es.wikisource's Cid editions are largely "A transcribir" (incomplete).

**The direct Roland cousin (flavor supplement): the *Roncesvalles* fragment.** Navarro-Aragonese
retelling of the Roncevaux material, c. 1225–1250 — literally the Spanish cousin of the
*Chanson de Roland*, but only **~100 surviving verses**. Text: Menéndez Pidal, *RFE* IV (1917),
pp. 105–204 (PD). Charming as a special "Roland cousin" tag; too short to be a coverage source.

**Coverage supplements — all IN SCOPE** (decision 2; all PD). The medieval tier is Cid +
these three, so the "all medieval examples" tap-through has real depth:

| Work | Date | Size | Note |
|---|---|---|---|
| Berceo, *Milagros de Nuestra Señora* | c. 1246–60 | ~3,644 lines | 13th-c., cleaner/more regular spelling than the Cid → easiest to match |
| *Poema de Fernán González* | c. 1250 | ~2,750 lines | another Castilian epic; period- and register-consistent with the Cid |
| Juan Ruiz, *Libro de buen amor* | c. 1330 | ~7,000 lines | biggest verb yield, spelling closest to modern — 14th-c. (a shade later than the Cid, but included for coverage) |

Sources: bibliotecagonzalodeberceo.com, Biblioteca Virtual Miguel de Cervantes, Project
Gutenberg where available (all PD).

### Old-Spanish → Modern-Spanish reflex matching (the medieval-tier engineering)

The Cid attaches to a modern verb only when a line contains that verb's **own ancestor
word-form** (Conjuguer's reflex-only policy). This is tractable but requires normalizing
*both* sides to a common reduced form before matching — never match raw medieval spelling
against modern conjugation tables. Canonicalizer rules:

1. **f- → h-** (and h- → ∅): *ferir→herir, fazer→hacer, fablar→hablar*. Highest-yield rule.
2. **ç/z → c/z**, sibilant normalization: *fizo/fiço, plaça*.
3. **u↔v, i↔j↔y** by position: *auer→haber, biuo→vivo*.
4. **Cluster/Latinism simplification:** *dubda→duda, escripto→escrito, omne→hombre*.
5. **Apocope + enclitic fusion (the hard part):** *diz(e), quier(e), tien(e)*; split enclitics
   *tornós→tornó se, díxol→díxole, ques→que se* **before** identifying the verb.
6. **Lexical/suppletive replacements — need a hand table** (rules won't catch them): strong
   preterites *sopo→supo, ovo→hubo, dixo→dijo, troxo→trajo, aduxo→(aducir/traer), connusco→conocer,
   tovo→tuvo, priso→prendió*. This is exactly the irregular set the app already models richly —
   the engine's irregular data doubles as ground truth, and the payoff is highest precisely
   where matching is hardest (the vivid *f-/h-* and strong-preterite forms).

A rule-normalized compare + an exception table + an edit-distance backstop covers most of it;
hand-verify the irregulars.

---

## Tier 2 — Literature (16th–early-20th c., public domain)

The backbone. 19th-c. peninsular realist prose has the highest yield of common verbs in
**modern-matching** conjugated forms. Download channel: **Project Gutenberg**, `.txt.utf-8`
endpoint (older Spanish files are Latin-1 — the `.txt.utf-8` URL avoids mojibake), stripping
the `*** START/END OF THE PROJECT GUTENBERG EBOOK ***` boilerplate.

**Recommended starter set (8 works — unambiguously PD in US + Spain, clean `.txt`, maximal
modern-form coverage):**

| # | Work | Author (life) | Year | PG ID | Role |
|---|---|---|---|---|---|
| 1 | *Fortunata y Jacinta* | Pérez Galdós (1843–1920) | 1887 | 17013 | anchor — largest, most dialogue |
| 2 | *Doña Perfecta* | Galdós | 1876 | 15725 | (PG 2462 = English; do not use) |
| 3 | *La Regenta* | Clarín (1852–1901) | 1884–85 | 17073 | **verify both tomos in the `.txt`** |
| 4 | *Los pazos de Ulloa* | Pardo Bazán (1851–1921) | 1886 | 18005 | |
| 5 | *Pepita Jiménez* | Juan Valera (1824–1905) | 1874 | 17223 | |
| 6 | *El sombrero de tres picos* | Alarcón (1833–1891) | 1874 | 29506 | short, lively, clean UTF-8 |
| 7 | *La barraca* | Blasco Ibáñez (1867–1928) | 1898 | 14944 | adds regional usage |
| 8 | *Don Quijote* | Cervantes (1547–1616) | 1605/15 | 2000 | **supplement only** — flag 17th-c. orthography before mining forms |

**Overflow (same authors, guaranteed-clean modern forms) for verbs still uncovered:** Galdós
*Misericordia* (21831), *Marianela* (48818), *Episodios Nacionales*/*Trafalgar* (16961); Pardo
Bazán *La madre naturaleza* (58059); Blasco Ibáñez *Cañas y barro* (57781), *Sangre y arena*
(26983). Latin American prose (optional regional flavor): Sarmiento *Facundo* (33267). **Skip
for form-mining:** *Martín Fierro* (verse + gaucho dialect), *Don Segundo Sombra* (1926,
dialect, newest/most contestable text). *María* (Isaacs, PD) is **not on PG in Spanish** — use
Cervantes Virtual / es.wikisource if wanted.

**Copyright:** binding test is Spain life+80 (pre-1987 deaths). Every starter-set author is
clear in both US (pre-1930 publication) and Spain by decades. The only "latest" items to note:
**Blasco Ibáñez** (d. 1928 → Spanish PD only since 2009; fine in 2026) and, if ever added,
**Güiraldes** (1926 text — excluded from the clean set). No author died after 1940; no genuine
landmine.

---

## Tier 3 — Government / official documents

Supplies formal administrative verbs (subjunctives, futures, *deberá/se establecerá/corresponderá*)
that literature lacks. Two legal buckets:

- **Public domain (zero obligation)** — *official texts* are excluded from copyright by statute:
  **Spain, Art. 13 TRLPI** (leyes, reglamentos, resoluciones, actos de organismos públicos + their
  official translations) and **Mexico, Art. 14 LFDA** (identical carve-out). This is the exact
  analogue of the Swiss Art. 5 URG basis the French app used. → any **BOE** law text, any **DOF**
  legal text: copy verbatim, no attribution required.
- **Open reuse (attribution only, commercial OK)** — agency *reports/strategies/statistics* are
  creative works, not covered by Art. 13, but fall under Spain's PSI regime (**Ley 37/2007**;
  commercial + non-commercial reuse, cite source + don't distort) and CC-BY declarations (**INE =
  CC BY 4.0**, **Argentina argentina.gob.ar = CC BY 4.0**, Mexico datos.gob.mx = **Libre Uso MX**).

**Curated list** (theme spread so common admin verbs are covered):

| Document | Theme | Ctry | License | Attribution |
|---|---|---|---|---|
| TRLPI (RDL 1/1996), boe.es | law | ES | **PD** (Art. 13) | none |
| PNIEC 2023–2030 (MITECO) | energy/env | ES | Reuse (Ley 37/2007) | "Fuente: MITECO" |
| Estrategia de Movilidad 2030 (Mitma) | transport | ES | Reuse | "Fuente: Mitma" |
| Informe Anual SNS 2024 (Sanidad) | health | ES | Reuse | "Fuente: Sanidad" |
| INE Informe Anual 2024 | statistics | ES | **CC BY 4.0** | "Fuente: INE" |
| Ley Federal del Derecho de Autor (DOF) | law | MX | **PD** (Art. 14) | none |
| argentina.gob.ar content | admin | AR | **CC BY 4.0** | "Fuente: argentina.gob.ar" |

**Share-alike caveat:** Chile (INE, datos.gob.cl) and Colombia (DANE, datos.gov.co) are CC BY-**SA**
4.0 — fine for individual-sentence mining, but avoid for anything we'd redistribute wholesale.
Prefer the PD + CC-BY sources above. A single credits page ("Fuente: INE / MITECO / Mitma /
Sanidad / argentina.gob.ar") satisfies every attribution obligation at once.

---

## Tier 4 — Technology

Value: the **consumer how-to register** — imperatives/infinitives (*descargue, instale,
actualice, reinicie, configure, haga clic*) and technical verbs (*descargar, cifrar, conectar*)
absent from literary/administrative prose.

**⚠ Key finding — unlike the French app, Spain has no clean PD/CC-BY cyber how-to.** The best
register matches are license-blocked for a shipped commercial app:

- **INCIBE / OSI** consumer guides and **AEPD** citizen guides → **CC BY-NC-SA 4.0**. The **NC**
  clause blocks commercial use. *Do not mine.*
- **CCN-CERT** → all-rights-reserved (private-use-only). *Do not mine.*

**Commercial-safe options** (with obligations):

| Source | License | Obligation | Register |
|---|---|---|---|
| Mozilla Support (SUMO) español, support.mozilla.org/es | CC BY-SA 3.0/later | attribution + **share-alike** | ★★★ imperatives |
| Wikilibros *Seguridad informática* | CC BY-SA 4.0 | attribution + **share-alike** | ★★★ |
| GNOME/Ubuntu Spanish docs | CC BY-SA 3.0 | attribution + **share-alike** | ★★★ step-by-step |
| España Digital 2026 (Red.es) | PSI reuse (Ley 37/2007) | attribution only (**no SA/NC**) | ★★ policy infinitives |

**Mitigation:** short utilitarian instruction sentences ("Haga clic en Aceptar", "Descargue el
archivo") generally fall **below the threshold of originality** → low copyright risk regardless.
Mine *individual short sentences*, not whole sections. If we want **zero** SA entanglement, lean
on the PSI-reuse government tech prose (España Digital 2026) and accept its weaker imperative
register — otherwise Mozilla SUMO + GNOME/Ubuntu (CC BY-SA) are the best consumer-register mine.

---

## Proposed pipeline (mirrors the etymology pipeline + Conjuguer's corpus flow)

1. **Directory:** `corpus/` with `originals/{medieval,literature,government,technology}/`
   (gitignored — re-fetchable), `grokked/` (tracked hand-built intermediates: the Cid
   normalization table / reflex overrides), `working/` (tracked build scripts), `json/`
   (tracked finished exports). Manifest + license note tracked under `docs/` (this file).
2. **Form dump** (test-target tool, à la `CorpusFormsDumpTests`): conjugate every ranked verb
   across all tenses/persons via `TenseBridge` → `{ surface-form → [verb id] }`. Compound tenses
   emit only the participle (else *he* maps to every haber-form).
3. **Index build:** one tokenizing pass per source `.txt` → `{ verb id → [{doc,line,token,text}] }`,
   round-robin merged with a per-verb rotating lead author for balance. For the medieval tier,
   run the Old→Modern canonicalizer (rules 1–6 above) on both the corpus tokens and the generated
   forms before lookup.
4. **Select + translate:** shard the index (~30 verbs/shard); one subagent per shard picks the
   earliest genuine *verbal* use (rejecting same-spelled nouns), re-opens the source for the clean
   sentence, and translates → schema-validated array. Merge into `ExampleUses.json` /
   `MedievalExamples.json`.
5. **Tail rescue** for verbs whose surface form collides with a common noun: re-mine the tail from
   the government + technology tiers only, ranking candidates by how distinctively-verbal the token
   is (infinitive/participle/gerund over the bare noun-stem).
6. **Authored residue:** verbs no open corpus uses verbally get an original Claude-authored
   sentence, flagged `"source": "Claude (Opus 4.8)"` / `"line": null` so AI authorship is explicit
   and never attributed to a corpus. (Per the user's side note: a non-ranked verb with a medieval
   example may also get a fabricated modern example + an etymology.)

---

## Decisions (resolved 2026-07-10)

1. **Technology tier → CC BY-SA vendor docs + LatAm government tech.** Mine Mozilla SUMO +
   GNOME/Ubuntu (CC BY-SA), taking only short below-originality-threshold instruction sentences,
   **and** broaden beyond Spain to Mexican / Colombian / Argentinian government digital/tech
   documents — with each country's exact attribution requirement confirmed (see the LatAm-gov
   attribution research folded into Tier 3 below). Spain's NC sources (INCIBE/OSI, AEPD) and
   all-rights-reserved CCN-CERT stay excluded.
2. **Medieval → four works.** Cantar de Mio Cid + Berceo *Milagros* + *Poema de Fernán González*
   + *Libro de buen amor* (+ the *Roncesvalles* garnish). All PD.
3. **Latin American sources → included.** LatAm government (incl. CC BY-SA Chile/Colombia) and PD
   LatAm prose are in scope for regional verb usage; observe the per-country attribution and the
   share-alike caveat (mine sentences, don't redistribute datasets wholesale).
4. **Scope → fetch + build.** Proceed to fetch the corpus and build the form-dump / index /
   mining pipeline, mirroring the etymology pipeline and Conjuguer's corpus flow.

---

## Build status (2026-07-10)

### Corpus fetched — 21 source texts under `corpus/originals/` (gitignored)

| Tier | Files | Notes |
|---|---|---|
| medieval (3) | Cantar de Mio Cid (Menéndez Pidal 1913, archive.org OCR), *Libro de buen amor* (PG 16625), Berceo *Milagros* (bibliotecagonzalodeberceo PDF→txt) | Cid OCR + Milagros PDF need front-matter/apparatus stripping in the `grokked/` stage. **Gap:** *Poema de Fernán González* — only lending-restricted critical editions found; to fill later. |
| literature (8) | Galdós *Fortunata y Jacinta* & *Marianela*, Clarín *La Regenta* (both tomos), Pardo Bazán *Los pazos de Ulloa*, Valera *Pepita Jiménez*, Alarcón *El sombrero de tres picos*, Blasco Ibáñez *La barraca*, Cervantes *Don Quijote* | All PG `.txt.utf-8`. **Doña Perfecta (PG 15725) was dropped** — it is a Heath annotated *student* edition (pervasive inline `=markup=`, margin line-numbers, English intro + NOTES/VOCABULARY) — and replaced with clean Spanish-only **Marianela (48818)**. *El sombrero* (PG 29506) is also annotated but its Spanish body is clean, so the cleaner slices it out of the English apparatus. |
| government (5) | ES: TRLPI (PD legal), INE Informe Anual 2024, PNIEC, Mitma Movilidad 2030; CO: DANE GEIH | **Gaps:** MX INEGI ENOE + AR INDEC IPC PDFs came down non-extractable — retry later. |
| technology (5) | España Digital 2026; MX Estrategia Digital Nacional; CO CONPES 3975 + MinTIC Gobierno Digital; AR Agenda Digital | Digital-policy tier (tech-domain infinitives). **Deferred:** Mozilla SUMO / GNOME-Ubuntu (CC BY-SA) consumer-imperative how-to — add if the imperative register is thin after mining. |

### LatAm government attribution (verified; DANE correction)

All three LatAm sources are **attribution-only, commercial-friendly — no share-alike, no NC**.
Correction to the earlier CC BY-**SA** assumption: **DANE (Colombia) is CC BY 4.0**, no
ShareAlike. Legal bases: MX official texts PD (Art. 14 LFDA) + Libre Uso MX ("único requisito de
citar la fuente de origen"); CO norms Art. 41 Ley 23/1982 + DANE CC BY 4.0; AR argentina.gob.ar &
INDEC CC BY 4.0. Paste-ready **credits block** (one page satisfies every obligation):

```
FUENTES DE CONTENIDO
España  — Textos oficiales (BOE): dominio público (Art. 13 TRLPI). Informes: reutilización
          Ley 37/2007 · INE (CC BY 4.0).
México  — Textos oficiales: dominio público (Art. 14 LFDA). Datos: Términos de Libre Uso MX —
          Fuente: Gobierno de México, datos.gob.mx (e INEGI — www.inegi.org.mx).
Colombia— Normas: Art. 41 Ley 23/1982. Estadística — Fuente: DANE (www.dane.gov.co), CC BY 4.0.
          Política: DNP (CONPES) y MinTIC — www.gov.co.
Argentina— Contenidos Argentina.gob.ar (CC BY 4.0). Fuente: INDEC (www.indec.gob.ar). Normas:
          Boletín Oficial (www.boletinoficial.gob.ar).
```

### Cruft removal DONE — `corpus/working/clean_corpus.py`

Retrieval boilerplate ("at the start of the document, on every page, and at the end") is stripped
by a tracked, idempotent cleaner (fetch is captured in `fetch_corpus.sh`, so raw→clean is
reproducible):

- **Gutenberg** — keep only text between `*** START … ***` and the end marker (both the modern
  `*** END … ***` and the older `End of Project Gutenberg's <title>` form); drop leading
  "Produced by …".
- **Annotated student editions** (*El sombrero*) — slice the Spanish body out of the English
  `PREFACE`/`INTRODUCTION` front matter and `NOTES`/`VOCABULARY` back matter (cutting at the
  *last* occurrence, since the edition's contents page also lists those headers).
- **PDF-derived** (gov/tech/Berceo) — drop per-page running headers/footers (frequency-detected),
  standalone page numbers, `Página N`, and dotted-leader TOC lines.
- **Cid OCR** — slice to the poem body (drop Menéndez Pidal's modern Introducción), strip the
  `CANTAR DEL DESTIERRO` running headers, the back-of-book `Cantar primero/segundo/tercero`
  índice, the Internet Archive front matter, and the printer's colophon.

Verified: a global sweep finds **zero** Gutenberg boilerplate, English NOTES/VOCABULARY/glossary,
Cid índice/IA/colophon, or `Página N`/`BOLETÍN` running headers across all 21 files. **Residual
(a `grokked/`-stage concern, not retrieval cruft):** the medieval editions still contain their
modern editorial *introductions/footnotes* (the Cid keeps interspersed footnotes + a trailing
"Valor nacional del Poema" essay; Berceo/LBA keep short intros) — these must be excluded from the
*medieval* index so they don't inject modern Spanish forms.

### Pipeline — form-dump DONE

`ConjugarTests/Models/CorpusFormsDumpTests.swift` (disabled build-time tool) conjugates every
verb through `TenseBridge` and writes `corpus/working/forms.json` (ranked: **52,166 forms → 988
verbs**) and `forms_all.json` (all: **254,328 forms → 4,811 verbs**). Verified: irregulars and
suppletion resolve correctly (`voy→ir`, `fue→[ir,ser]`, `supe→saber`, `dicho→decir`,
`tuviéramos→tener`). Compounds emit only the participle; imperativo negativo drops "no"; the
UPPERCASE irregularity marking is lowercased to the plain surface form; voseo (2S vos) forms are
included. Regenerate on demand by removing the `.disabled` trait and running
`run_tests.sh --only-testing ConjugarTests/CorpusFormsDumpTests`.

### Remaining pipeline steps (next)

1. **`grokked/` medieval prep + Old→Modern canonicalizer** (rules 1–6 above) so Cid/Berceo/LBA
   tokens match modern forms; strip OCR/PDF apparatus first.
2. **`build_corpus_index.py`** — tokenize each tier's `.txt`, whole-token lookup in `forms.json`,
   round-robin author balance → `working/corpus_index.json`.
3. **Mining workflow** — shard the index; subagents pick the earliest genuine verbal use + clean
   sentence + translation → `ExampleUses.json` / `MedievalExamples.json`.
4. **Swift loader + UI** — `ExampleUses.swift` (mirror `Etymology`/`EtymologyCache`) + example &
   medieval cards in `VerbView` (same slot as the pending etymology card).
