# Verb-frequency sources for all 4,811 verbs

> **Status (2026-08-30): shipped.** The recommendation below was adopted whole — CORPES XXI 1.5
> as the primary key with the *-se* merge, Google Books as the tie-breaker, counts stored and
> ranks derived at parse time, estimates flagged `hp` and clamped. The pipeline, its provenance,
> and the rebuild recipe live in [`../frequency/README.md`](../frequency/README.md); the ordered
> list the app is tested against is `docs/frequencies.txt`. This document is kept as the record of
> what was measured and what was rejected, not as a live plan. One number in it moved: the two
> malformed keys were corrected first, so 46 verbs end up estimated rather than 48.

Research notes, checked 2026-08-28, on where a frequency-of-use ranking for *every* verb in
`verbModelMap.xml` could come from. Prices, licenses, and coverage numbers were measured live
that day; the reproduction recipes are at the end. Nothing here has been sent, bought, or
shipped. The companion document for the French app is
`../../Conjuguer/docs/verb-frequency-sources.md`; the Sketch Engine findings there carry over
unchanged and are only summarized here.

## Short version

- **The best source is free, official, and already licensed for this: the Real Academia
  Española's CORPES XXI lemma-frequency list.** Version 1.5 (June 2026; 455 million
  orthographic forms from about 420,000 written and oral texts of every Spanish-speaking
  country) ships as `corpes_lemas.zip` on `rae.es`, and the zip carries a `license.txt` that
  places the data under **Creative Commons Attribution-ShareAlike 4.0** — "para cualquier
  propósito, incluso comercialmente." No permission email is needed; attribution and
  share-alike on the derived data are the whole license.
- **It covers 4,763 of Conjugar's 4,811 infinitives (99.0%)** once the 72 pronominal verbs that
  CORPES lemmatizes with *-se* (`arrepentirse`, `suicidarse`, `adueñarse`, …) are folded into
  their base entries, and its ranking agrees with the existing Sketch Engine ranks at
  Spearman ρ = 0.894 over the 985 verbs both have. The verbs it lacks are Conjugar's own
  spelling variants and dictionary ghosts (`reeligir`, `rembolsar`, `abetunar`, …).
- **Google Books Ngrams (Spanish, 2020 release, CC BY 3.0) is the tie-breaker.** Its
  `_VERB`-tagged 1-grams, summed through Conjugar's own paradigms, give a count for 4,800 of the
  4,811 verbs (99.8%) from 10.2 billion verb tokens (1950–2019), agree with CORPES at ρ = 0.945,
  and separate the CORPES ties in the tail (2,592 verbs share a count with some other verb in
  CORPES; six do after the tie-break). It is too contaminated by mis-tagged nouns to rank on
  its own.
- **The paid options are worse, not just dearer.** Mark Davies's Spanish list from the Corpus
  del Español costs $145 (academic) / $295 (non-academic) but its purchase agreement forbids
  showing users "the exact rank order" and forbids redistribution — fatal for a `#rank` badge in
  an AGPL app with public data files. Lexical Computing's word-list price list starts at €250
  per list for academic use and **€2,500 for commercial use**; a subscription (€17.54/month)
  does not lift the 1,000-item cap that produced today's 988 ranks.
- **Recommendation:** rank from the CORPES 1.5 counts with the *-se* merge, break ties with the
  Google Books counts, give the 43 verbs only Google Books knows a flagged, clamped *estimate*
  and the 5 verbs nothing knows an editorial zero, store counts rather than ranks the way
  Konjugieren stores DWDS hits, and credit the RAE and Google in the Credits screen. Fix
  `sobre(e)ntender` and `reeligir` first — they are the only "missing" verbs that are actually
  data bugs.

## Where Conjugar stands

`Conjugar/Models/verbModelMap.xml` has 4,815 `<verb>` rows and **4,811 distinct infinitives**
(`apostar`, `asolar`, `aterrar`, `atestar` appear twice, one row per homonym sense). 989 rows
carry `fr`, and **988 distinct verbs are ranked**, with ranks running 1–1,000 and gaps where
the export's non-verbs were dropped. `VerbMapEntry.frequencyRank` is `nil` for the other
3,823 verbs; `VerbSort.frequency` sorts them after the ranked ones, alphabetically;
`VerbBrowseView` shows a blue `#rank` badge only when a rank exists; and
`WidgetSnapshotWriter.rankedVerbs()` draws the verb of the day and the widget quiz from the
ranked set only. `Shared/WidgetSnapshot.swift` documents the field as "nil if outside the top
~1000."

The provenance is in `docs/`:

- `SpanishVerbFrequencies.xml` — a Sketch Engine word-list export from
  `preloaded/estenten18_fl5` (**esTenTen18**, Spanish Web 2018: 16.9 billion words / 19.6
  billion tokens by Sketch Engine's count; the export's own relative frequencies imply
  ≈ 20.3 billion), `lempos` attribute, 1,000 items. `ser` leads with 300,015,919 hits
  (14,774.27 per million), `haber` second with 129,786,746.
- `SpanishVerbFrequencyRanks.txt` — the 999 `infinitive,rank` lines that `_build_verbmap.py`
  actually reads (`load_frequency_ranks()`), after the 2026-06-13 cleanup removed the export's
  non-verbs (`también`, `están`, `aquí`, `iphone`, `on`, …) and the G-rating pass removed
  `joder`.
- `verbs.csv` — a *second* export, from esTenTen23 according to the journal entry "Frequency-list
  cleanup + closing the top-990 coverage gap", ranked the same way. It is **not** the shipped
  ranking: only 32 of its verbs carry the same rank as the `.txt`, 40 verbs appear only in the
  `.txt` and 30 only in the `.csv`. `project-structure.md` called it "the same ranking"; it is
  the same *shape*.
- `freq_unmatched.txt` — the 13 export items with no verb-map row.

The Credits screen (`Info.creditsText`) credits Wikipedia, WordReference, and the other content
sources but says nothing about Sketch Engine or Lexical Computing, so nothing there has to be
*removed*; the CC BY-SA source below has to be *added*.

## What "a ranking for every verb" actually needs

The same five things as for French, with Spanish-specific wrinkles:

1. **Coverage.** 4,811 lemmas, most of them rare, several of them variant spellings that a
   corpus lemmatizer normalizes away (`rembolsar` → `reembolsar`, `podrir` → `pudrir`).
2. **Resolution in the tail.** Below rank 3,000 a 100-million-word corpus sees a verb a few
   times a year; only billion-word corpora separate `filetear` from `apostrofar`.
3. **Lemmatization.** Counts must be per lemma. Spanish form lists are poisoned by homographs
   worse than French ones: `como` (comer), `para` (parar *and* parir), `una`/`uno` (unir),
   `nada` (nadar), `casa` (casar), `vino` (venir), `fui`/`fue` (ser *and* ir). The naive
   experiment below ranks *unir* fifth and *parir* fifteenth.
4. **Register.** Web text ranks `realizar`, `utilizar`, `consultar`, `descargar` high;
   a balanced reference corpus ranks `mirar`, `sentir`, `morir` higher; books rank `existir`
   and `tratar` high. The choice decides how much the 988 existing ranks move.
5. **License.** Conjugar is AGPL and its data files are public on GitHub, so the source must
   allow redistribution of derived data. CC BY and CC BY-SA do; CC BY-NC (SUBTLEX-ESP) and
   bespoke purchase agreements (Davies) do not.

## The Real Academia Española's CORPES XXI lists

### What the RAE publishes

CORPES XXI (*Corpus del Español del Siglo XXI*) is the RAE's reference corpus of 21st-century
Spanish: written and oral texts from Spain, the Americas, the Philippines, and Equatorial
Guinea, built to a design that allots 25 million forms to each year of the century. The
`rae.es/banco-de-datos/corpes-xxi` page dates **version 1.5 to June 2026: almost 420,000
documents and 455 million orthographic forms.** Since the 2021 post "Conozca (algo más) el
CORPES: listados de frecuencias" the RAE has published the corpus's frequency statistics as
downloadable files, and since version 1.1 (April 2024) a *Diccionario de frecuencias léxicas*
derived from it. Everything lives under
`https://www.rae.es/corpes/assets/rae/files/corpes/`:

| File | Size | Dated | What it is |
|---|---|---|---|
| `corpes_lemas.zip` | 16.3 MB | 26 Jun 2026 | **The full lemma list, v1.5**: `license.txt` (CC BY-SA 4.0) + `frecuencia_lemas_corpes_1_5.txt` (53.6 MB, 2,058,524 rows, tab-separated: *Elemento*, class letter, *Frecuencia*, per-million with and without punctuation). Classes: N 1,634,254 rows, F (foreign) 244,874, M (numerals) 112,175, A 43,444, **V 14,077**, R 6,113, … The verb rows sum to 67,493,311 tokens. |
| `corpes_elementos.zip` | 36.3 MB | 26 Jun 2026 | The same by grammatical element (lemma + full tag). |
| `corpes_formas_ortograficas.zip` | 7.1 MB | 26 Jun 2026 | Orthographic forms. |
| `listas_dp_lemas.tsv` | 9.6 MB | 11 Mar 2026 (header says 29/03/24) | The *Diccionario de frecuencias léxicas*: 116,726 lemmas from the **press subcorpus of 21 countries (180+ million words, ~381,000 texts)**, ordered by dispersion, with absolute and per-million frequency, DP, and number of countries. 10,399 verb lemmas. |
| `diccionario_frecuencias_corpes_alfa.tsv` | 35.0 MB | 11 Mar 2026 | The same dictionary alphabetically, with one row per inflected form under each lemma (EAGLES-style tags such as `Nfsc---n`). |
| `Lemas_por_paises/Lemas_subcorpus_<país>.TXT` × 21 | small | — | Per-country lemma lists from the dictionary (semicolon-separated; Panamá: 1,790,775 forms, 24,744 lemmas). Index page `rae.es/corpes/contenidos/lemas-pais`. |
| `10000_lemas.txt`, `1000/5000/10000_lemas.html` | — | — | Top-N excerpts. |
| `guiaDiccionariosFrecuenciasLex.pdf` | 354 KB | Apr 2024 | The dictionary's guide. |

Two access quirks. **`www.rae.es` sits behind Cloudflare and answers non-browser clients with a
JavaScript challenge** — `curl` and `WebFetch` get a 403 "Just a moment…" page, and the Wayback
Machine's copies are access-restricted (402 "Please contact the site owner for access"). Download
the files in a browser. (Every number below was computed *inside* a browser tab on the live
files — `fetch` plus `DecompressionStream('deflate-raw')` on the zip — so nothing was saved to
disk; the recipe is in the appendix.) And the older CREA corpus at `corpus.rae.es/lfrecuencias.html`
offers only *form* lists (1,000 / 5,000 / 10,000 / total), plus 1,000–10,000-lemma excerpts of
the annotated CREA — too small and the wrong unit.

### License

`license.txt` inside `corpes_lemas.zip` reads, in full:

> Este conjunto de datos se publica bajo la licencia Creative Commons
> Atribución/Reconocimiento-CompartirIgual 4.0 Internacional (CC BY-SA 4.0).
>
> Usted es libre de: Compartir — copiar y redistribuir el material en cualquier medio o formato
> para cualquier propósito, incluso comercialmente. Adaptar — remezclar, transformar y construir
> a partir del material para cualquier propósito, incluso comercialmente. La licenciante no
> puede revocar estas libertades en tanto usted siga los términos de la licencia.
>
> Bajo los siguientes términos: Atribución — Usted debe dar crédito de manera adecuada, brindar
> un enlace a la licencia, e indicar si se han realizado cambios. […] CompartirIgual — Si
> remezcla, transforma o crea a partir del material, debe distribuir su contribución bajo la
> misma licencia del original. No hay restricciones adicionales […]
>
> https://creativecommons.org/licenses/by-sa/4.0/legalcode

The two TSV dictionaries and the 21 per-country files carry the same grant as their first line
("Este contenido está licenciado bajo CC BY-SA 4.0"), and the per-country header adds "(C) Real
Academia Española 2025". The site-wide *Aviso legal* reserves all rights over the web's
*Contenidos* and forbids commercial reuse without written authorization, but the datasets carry
their own explicit, more specific grant, and that is the one that governs the files. **No
permission email is needed.** The 2021 post invites questions at `corpus@rae.es`; a courtesy
note is optional and drafted below.

### Coverage, measured on version 1.5

Matching Conjugar's 4,811 infinitives against the 14,077 verb lemmas:

- **Direct matches: 4,691 (97.5%)**, and they account for **99.52% of all verb tokens** in the
  corpus. The 120 misses split three ways.
- **72 are pronominal verbs that CORPES lemmatizes with the clitic attached** — 416 of its verb
  lemmas end in *-se*, and Conjugar keys the same verbs bare (`rx="1"` marks the reflexive-only
  ones): `arrepentirse` 8,541, `adentrarse` 7,214, `suicidarse` 5,480, `antojarse` 3,835,
  `adueñarse` 2,399, `incautarse` 2,181, `desentenderse` 1,927, `acurrucarse` 1,790,
  `endeudarse` 1,712, `dignarse` 910, `regodearse` 781, `personarse` 742, `ufanarse` 600,
  `ensimismarse` 592, `acuclillarse` 581, `adormilarse` 561, `bifurcarse` 514,
  `vanagloriarse` 494, `despreocuparse` 426, `compenetrarse` 416, `querellarse` 413, … Adding
  `count(inf) + count(inf + "se")` recovers all 72 and lifts coverage to **4,763 (99.0%)**.
  Six verbs exist in both spellings and simply sum (`resentir` 1 + `resentirse` 2,669,
  `desvivir` 2 + 533, `automedicar` 5 + 389, `contorsionar` 1 + 338; `conquistar` 12,617 + 1
  and `enquistar` 454 + 1 are the harmless converse).
- **48 remain.** Two are data bugs in the verb map (see *Side findings*): `sobre(e)ntender`
  (CORPES has `sobrentender`, 253) and `reeligir` (CORPES has `reelegir`, 1,613). Six are
  variant spellings that Conjugar also lists in standard form (`rembolsar`/`reembolsar`,
  `remplazar`/`reemplazar`, `podrir`/`pudrir`, `rescribir`/`reescribir`,
  `trasbordar`/`transbordar`, `trasmutar`/`transmutar`) — CORPES lemmatizes to the standard
  spelling. The other 40 are rarities the corpus never saw: `abalar`, `abanar`, `abetunar`,
  `achabacanar`, `almohazar`, `bribonear`, `cabrahigar`, `chinchorrear`, `cizañar`, `coercer`,
  `coheredar`, `consonantizar`, `desaclimatar`, `desarrendar`, `descaperuzar`, `desencorvar`,
  `desenfurruñar`, `desentablillar`, `desentoldar`, `despiezar`, `empeller`, `encallejonar`,
  `engrescar`, `explicotear`, `gallardear`, `hebraizar`, `interviuvar`, `mensualizar`,
  `mixtificar`, `presintonizar`, `reensayar`, `rodrigar`, `salgar`, `superabundar`,
  `triptongar`, `ventiscar`, `xerocopiar`, `xerografiar`, `yodurar`, `aguachicolear`. Google
  Books has counts for 43 of the 48; five (`aguachicolear`, `desenfurruñar`,
  `desentablillar`, `presintonizar`, and the misspelled `sobre(e)ntender`) have nothing anywhere.
- Of the 988 verbs ranked today, three are absent: `rodrigar`, `salgar` (both added to the map
  in June only because the esTenTen export listed them) and `adentrar` (rescued as
  `adentrarse`).

### Resolution and ties

On the merged counts the covered list runs from `ser` (7,661,318) through rank 988
`reafirmar` (6,162), rank 1,000 `interponer` (5,935), rank 2,000 `urdir` (1,398), rank 3,000
`desecar` (424), rank 4,000 `constipar` (67), rank 4,500 `destaponar` (14), rank 4,700
`desencajonar` (2), to rank 4,763 `yermar` (1). Of the directly matched verbs, 41 have a single
hit, 133 have five or fewer, 210 ten or fewer, 880 a hundred or fewer. There are 2,874 distinct
counts among the 4,763 verbs, so **2,592 verbs sit in 703 tie groups** (40 verbs at count 1,
33 at 2, 25 at 8, 24 at 4). That is the tail a 455-million-form corpus can resolve, and it is
where Google Books earns its place: with its counts as the second sort key, six verbs remain tied.

### Register: the top barely moves, the junk falls out

CORPES's top thirty — *ser, estar, tener, ir, hacer, poder, decir, haber, dar, ver, saber,
querer, deber, pasar, llegar, dejar, llevar, seguir, encontrar, poner, quedar, hablar, parecer,
pensar, volver, creer, salir, conocer, contar, tomar* — is the current list with the web verbs
demoted a little (`realizar` 15 → 36, `utilizar` 30 → 65, `consultar` 136 → 426, `descargar`
407 → 806) and the spoken-and-narrative verbs promoted (`mirar` 110 → 37, `sentir` 81 → 33,
`morir` 139 → 77, `oír` 383 → 126, `matar` 310 → 178). ρ = 0.894 against the current ranks.

Two things to know about the CORPES numbers:

- **`haber` ranks eighth, not second.** CORPES counts 1,034,648 verb tokens for `haber` against
  7,661,318 for `ser` (a ratio of 0.135; esTenTen18's is 0.43, Google Books' 0.44), and there is
  no separate auxiliary lemma anywhere in the file (`haber` N has 1,531, `he` R 3,024, `ha`/`han`/
  `hay` as foreign words a few dozen). The only reading consistent with the data is that CORPES
  annotates a compound tense as one verbal element under the participle's lemma, so `haber`
  counts only its independent uses (`hay`, `haber de`). For a learner's list, eighth is fine.
- **The current ranks contain esTenTen tagger artifacts that CORPES corrects.** The biggest
  movers from the current ranking are `hacendar` 465 → 4,063, `adir` 985 → 4,121, `jamar` 611 →
  3,569, `paginar` 650 → 3,509, `visar` 974 → 3,734, `timar` 729 → 3,251, `maquinar` 754 →
  2,735, `salar` 770 → 2,695, `morar` 857 → 2,627, `medicar` 934 → 2,573, `licenciar` 859 →
  2,378, `numerar` 755 → 2,231, `embarazar` 743 → 2,187 — nouns (*hacienda, página, visa,
  máquina, sala, licencia, número*) that FreeLing lemmatized as verbs in the web crawl. CORPES's
  own tagger is not spotless (`solar` 2,050, `molar` 945, `nuclear` 491, `erar` 739, and `cf.`
  536 appear as verb lemmas, none in Conjugar), but among Conjugar's verbs its contamination is
  far lighter than either the web export's or Google's.

### The dispersion list, for the record

The press-only *Diccionario* (`listas_dp_lemas.tsv`) covers 4,651 verbs with the *-se* merge
(96.7%), agrees with the current ranks *better* than the full corpus does (ρ = 0.917 — press
is closer to web than fiction and speech are), and adds something no other source has: how
many of the 21 national subcorpora document each verb (2,260 of Conjugar's verbs appear in all
21; 163 in only one) and a dispersion index. But 180 million words leave 552 verbs at ten hits
or fewer and rank 4,000 at `mesar` = 14, so it cannot be the primary key. A "panhispanic"
badge from its country count would be a feature, not a ranking.

## Google Books Ngrams as the tie-breaker

The 2020 (v3) Spanish 1-gram export (`storage.googleapis.com/books/ngrams/books/20200217/spa/`,
three gzip shards of 631 MB, 1,114 MB, and 1,478 MB, **CC BY 3.0**) covers 158.9 billion tokens
of scanned books, 76.5 billion of them printed since 1980, and every 1-gram also appears with a
part-of-speech suffix. The `_VERB` rows — 1,260,588 of them — are word forms, not lemmas, but
Conjugar already has the lemmatizer: `corpus/working/forms_all.json` (from
`CorpusFormsDumpTests`) maps 254,328 surface forms to the verbs that produce them. Summing the
tagged counts through it, and splitting the 264 forms that belong to more than one verb
(`fui`, `fue`, `era` …, 3.4% of the tokens) by expectation-maximization, gives:

| Slice | Verb tokens | Covered | ρ vs current | ρ vs CORPES |
|---|---|---|---|---|
| all years (1500–2019) | 14.4 billion | 4,800 / 4,811 | 0.820 | — |
| 1950–2019 | 10.2 billion | 4,800 | 0.849 | **0.945** (0.901 in the unranked tail, 0.907 in the top 988) |
| 1980–2019 | 7.2 billion | 4,800 | 0.861 | — |

Only eleven verbs have no Google Books hits at all (`aguachicolear`, `amorriñar`,
`desenfurruñar`, `desentablillar`, `despendolar`, `encorbatar`, `enguachinar`, `enguarrar`,
`enmadrar`, `presintonizar`, `sobre(e)ntender`), and the 1950–2019 slice has 4,743 distinct
values over 4,800 verbs — essentially no ties. That is exactly what CORPES lacks.

Why it must not be the primary key: **Google's tagger marks nouns and adjectives `_VERB` when
they happen to coincide with a form of a rare verb**, and the damage is large in absolute terms.
Against CORPES: `versar` 4,143,660 vs 1,337 (*verso*), `salar` 1,309,158 vs 649 (*sala*),
`aviar` 476,889 vs 78, `loar` 326,282 vs 123 (*loa*), `cristianar` 303,816 vs 25
(*cristiana*), `libertar` 303,492 vs 141 (*liberta*), `agostar` 236,570 vs 117 (*agosto*),
`hacendar` 224,490 vs 58 (*hacienda*), `foliar` 186,244 vs 54 (*folio*), `comedir` 169,823 vs
30, `conferenciar` 156,088 vs 76 (*conferencia*), `adir` 124,984 vs 50, `ministrar` 105,391 vs
14 (*ministro*), `abajar` 91,948 vs 27 (*abajo*), `subvenir` 89,428 vs 28, `desusar` 65,219 vs
8, `gloriar` 56,160 vs 26 (*gloria*), `medicinar` 40,298 vs 6, `resinar` 28,385 vs 9,
`prosternar` 26,114 vs 1, `escobar` 25,551 vs 3 (*escoba*). Used only to order verbs that
CORPES already ties, the contamination can move a verb within its tie group and no further.

Its top thirty (1950–2019) — *ser, haber, poder, tener, estar, hacer, decir, dar, ir, deber, ver,
querer, llegar, saber, encontrar, parecer, quedar, pasar, dejar, llevar, seguir, poner, tratar,
hablar, venir, tomar, existir, pensar, volver, permitir* — is books: `existir` and `tratar`
high, `jugar` down at 206.

## Other free sources, measured or checked

| Source | What it is | Lemmatized | License | Result |
|---|---|---|---|---|
| **OpenSubtitles 2018 form list** (`hermitdave/FrequencyWords`, `es_full.txt`) | 1,202,520 forms, 423.3 million tokens | **no** | CC BY-SA 4.0 | Summed through `forms_all.json` with equal splits it "covers" 4,653 verbs but ρ = 0.531 and the top 25 are *ser, estar, ir, tener, **unir**, haber, hacer, poder, decir, querer, saber, **comer**, ver, **parar, parir**, deber, pasar, **asir**, hablar, **nadar, casar**, …* — *una/uno, como, para, nada, casa* doing the ranking. Dead end without a tagger. |
| **doozan/spanish_data `frequency.csv`** | The same OpenSubtitles counts folded into 25,002 lemmas with FreeLing tags and Wiktionary paradigms; 2,931 verbs | yes | CC BY-SA 3.0 | 2,772 / 4,811 (57.6%), ρ = 0.715. Too short by design. |
| **SUBTLEX-ESP** (Cuetos, Glez-Nosti, Barbón & Brysbaert 2011; `osf.io/xp6sz`) | 94,338 word forms, 40.0 million subtitle tokens | no | **CC BY-NC-SA 4.0** | Forms only and non-commercial; out on both counts. |
| **EsPal** (Duchon et al. 2013, BCBL, `bcbl.eu/databases/espal/`) | 2012 web query tool over a ~300-million-token written corpus and ~460 million subtitle tokens; lemma frequencies are among the properties it returns for an uploaded word list | yes | none stated; `espal@bcbl.eu` | Unmeasured: bulk export is a per-query upload with unstated limits and unstated terms, and its corpora are a fraction of CORPES's. Superseded. |
| **Leeds Internet corpora** (CC BY 2.5, TreeTagger lemma lists) | ~100-million-word web corpus | yes | CC BY 2.5 | `corpus.leeds.ac.uk` refused connections on both ports on 2026-08-28, as it did for the French session. Smaller than CORPES in any case. |
| **CREA** (RAE, 1975–2004) | form lists (1,000 / 5,000 / 10,000 / total ≈ 737,000 forms); 10,000-lemma excerpt of the annotated CREA | forms; 10k lemmas | unstated | Wrong unit / too small. |
| **Wiktionary "Frequency lists/Spanish"**, **Leipzig Wortschatz**, **wordfreq** | re-hostings of subtitle, Wikipedia, and news *form* counts | no | CC BY / mixed | Need a tagger in front. |
| **Kelly** (Spanish) | 9,000 words across all parts of speech | yes | CC BY-NC-ND-SA | Non-commercial and tiny. |
| **Sketch Engine free lists** (`sketchengine.eu/spanish-word-list/`) | 500 words, 200 nouns, 200 adjectives, **200 verbs** | yes | unstated | No help. |
| **Do it yourself** | spaCy / Stanza / FreeLing over OSCAR, Wikipedia-es, or the raw OpenSubtitles dump | yes | corpus-dependent | Feasible but reproduces, with a worse tagger and no editorial design, what the RAE already published. Fallback only. |

## Paid sources

### Mark Davies — Corpus del Español (`wordfrequency.info/spanish.asp`, `corpusdata.org`)

The Spanish product is "the top 40,000 lemmas / words" from the **Web/Dialects** corpus of the
Corpus del Español (the page says one billion words, the purchase agreement two billion;
2,127,738 texts from 21 countries), sold as three files: 39,600 lemmas with part of speech,
frequency, and text range; the frequency of every form of those lemmas; and 200,000+ word
forms. **$145 academic, $295 non-academic**, by a signed purchase agreement (`.doc` from the
page) and PayPal. From the public sample (every tenth lemma), 451 of the 3,960 sampled entries
are verbs, so the list holds about **4,500 verb lemmas**; 382 of the 451 (85%) are Conjugar
verbs, which puts its coverage of Conjugar around 3,800 of 4,811 — roughly 80% — with the
verbs at ranks 35,000–40,000 sitting at 148–253 hits.

The terms of license are the problem, and they are identical in the academic and commercial
agreements:

> 2. In any materials that you develop with the data, end users cannot see the exact frequency
> of a word (e.g. it occurs 823 times in the corpus) or the exact rank order (e.g. it is the
> 2,920th most common word). But you can group words into frequency bands (e.g. the word is in
> the band of words from rank order 3000-5000), although the number of frequency bands should
> be limited to 20 or less.
> 3. In no case can the Data be distributed beyond the company listed above. A small, unique
> change has been made to each dataset that is sold, and this can serve as a "fingerprint" to
> identify you as the unique source of the data.

Conjugar shows `#rank`, and its data files are public. Out.

`corpusdata.org` sells the full text of the same corpus (with a word/lemma/PoS format one could
count from) at **$395 academic / $795 non-academic** per corpus, under the same family of
restrictions. Unnecessary.

### Lexical Computing / Sketch Engine

Checked again on 2026-08-28; the French document's findings hold. The subscription price list
(`pay.sketchengine.eu/api.cgi?c=pricelist`) is unchanged — academic personal €9.34 / month,
€25.72 / quarter, €87.71 / year; non-academic personal €17.54 / €46.77 / €152.04 — and the
word-list cap for preloaded corpora is 1,000 items on trial and paid accounts alike. The
Spanish corpus is now **esTenTen23: 28.6 billion words / 33.1 billion tokens**, crawled in 2020
and 2022–23 and tagged with FreeLing. `lexicalcomputing.com/spanish-word-frequency-lists-for-download/`
offers a free sampler (the last 100 items of each thousand up to 100,000, esTenTen18 word
forms) and a quote form; its price list page (`/word-list-n-gram-price-list/`) says **"prices
start at EUR 250" per list per language for research use and "EUR 2,500" for commercial use**,
plus VAT, with the final price depending on length, metadata, and "whether the list will be
resold." An independent developer's free app is "non-academic" in their taxonomy, so the
€2,500 floor is the number to expect. The 23-billion-word crawl would resolve the tail better
than CORPES, but Google Books already does that for free, and the whole request is moot unless
the RAE data is rejected. If it ever comes to that, the quote-request draft in the Conjuguer
document applies with `esTenTen23` and Conjugar's figures substituted.

## Which register should rank a learner's verbs?

Rank of each verb in the three candidates (current = esTenTen18 web export; CORPES = full
list, merged; Books = Google Books 1950–2019):

| Verb | Current | CORPES | Books | | Verb | Current | CORPES | Books |
|---|---|---|---|---|---|---|---|---|
| ser | 1 | 1 | 1 | | hablar | 32 | 22 | 24 |
| haber | 2 | 8 | 2 | | pensar | 39 | 24 | 28 |
| tener | 3 | 3 | 4 | | vivir | 48 | 38 | 35 |
| poder | 4 | 6 | 3 | | sentir | 81 | 33 | 38 |
| estar | 5 | 2 | 5 | | mirar | 110 | 37 | 52 |
| hacer | 6 | 5 | 6 | | morir | 139 | 77 | 80 |
| decir | 7 | 7 | 7 | | comer | 199 | 113 | 151 |
| ir | 8 | 4 | 9 | | matar | 310 | 178 | 231 |
| dar | 9 | 9 | 8 | | amar | 330 | 308 | 243 |
| ver | 10 | 10 | 11 | | oír | 383 | 126 | 106 |
| deber | 11 | 13 | 10 | | permitir | 25 | 39 | 30 |
| pasar | 12 | 14 | 18 | | utilizar | 30 | 65 | 74 |
| querer | 13 | 12 | 12 | | realizar | 15 | 36 | 36 |
| encontrar | 14 | 19 | 15 | | disfrutar | 124 | 211 | 383 |
| saber | 16 | 11 | 14 | | consultar | 136 | 426 | 485 |
| llegar | 17 | 15 | 13 | | descargar | 407 | 806 | 938 |
| seguir | 18 | 18 | 21 | | configurar | 548 | 810 | 606 |
| llevar | 20 | 17 | 20 | | jugar | 91 | 75 | 206 |

CORPES is the pedagogically sane middle: a designed, panhispanic reference corpus with fiction,
press, and speech in it, rather than whatever the crawler found or whatever was printed. Its
ρ = 0.894 with the current list means the change is visible only in the details — `mirar`,
`sentir`, `oír` up; `consultar`, `descargar` down — and every one of those moves is an
improvement for a learner. Either way the data is free, so the choice can be remade in a script.

## Side findings about `verbModelMap.xml`

- **`sobre(e)ntender`** is not a verb; it is Annex B's notation for the pair
  *sobrentender / sobreentender*, transcribed literally. CORPES has `sobrentender` (253).
  Whichever spelling is chosen, the parenthesis has to go; it currently produces a verb no
  corpus can ever match and a URL-unfriendly deeplink key.
- **`reeligir`** is a misspelling of `reelegir` (CORPES 1,613, Google Books 515 for the
  misspelled forms — the DLE has only *reelegir*).
- The map lists both members of six variant pairs (`rembolsar`/`reembolsar`,
  `remplazar`/`reemplazar`, `podrir`/`pudrir`, `rescribir`/`reescribir`,
  `trasbordar`/`transbordar`, `trasmutar`/`transmutar`), and `mixtificar`/`mistificar`. That
  is fine — they conjugate identically and the DLE admits both — but only the standard spelling
  will ever carry a CORPES count; the variant gets an estimate (below).
- **Common verbs missing altogether**, by CORPES count, excluding the sixteen verbs removed on
  purpose in the G-rating pass (which duly top the list — `joder` 8,890, `cagar` 5,755, …) and
  the pronominal duplicates: `colmar` 3,466, `aflorar` 3,295, `monitorear` 3,221 (the map has
  `monitorizar`), `reinventar` 2,995, `migrar` 2,868 (it has `emigrar`), `develar` 2,706 (it
  has `desvelar`), `fungir` 2,068, `ameritar` 2,048, `desolar` 1,985 (it has `asolar`), `orbitar`
  1,705, `reelegir` 1,613, `detonar` 1,537, `opacar` 1,469, `signar` 1,385, `redescubrir` 1,311,
  `reverter` 1,303, `ponchar` 1,279, `permear` 1,278, `entrecerrar` 1,237, `desanimar` 1,234,
  `reubicar` 1,214, `circundar` 1,207, `reformular` 1,188, `empoderar` 1,132, `rentar` 1,066,
  `correlacionar` 1,062, `comerciar` 1,059, `reorientar` 1,035, `colisionar` 1,027,
  `reinterpretar` 1,001. In all, 521 CORPES verb lemmas with 100 hits or more have no row in
  the map (the 2010 book predates *tuitear* 825, *empoderar*, *hackear* 513, *postear* 401, and
  much Latin American usage: *ameritar*, *fungir*, *rentar*, *parquear* 400, *laburar* 495,
  *checar* 300). None of this is the frequency project's job, but the import script will produce
  the list for free.

## If CORPES is adopted: shape of the change

Mirror Konjugieren's design (and the Conjuguer recommendation) rather than the 2026-06 one:

1. **Store counts, derive ranks at parse time.** Replace `fr` with a CORPES count (`hi`, the
   base-plus-*-se* sum) and a Google Books count (`gb`, 1950–2019, rounded), and let
   `VerbMapParser` compute the dense 1…n rank by `(hi desc, gb desc, infinitive)` after the
   whole map is loaded. Adding a verb then never renumbers the others, and the two numbers are
   the provenance. `frequencyRank` can become non-optional once every verb has one.
2. **Estimate, flag, clamp for the 48.** A least-squares fit of `log(hi)` on `log(gb)` over the
   4,757 verbs both sources count gives `log(hi) = −3.94 + 0.920·log(gb)`, R² = 0.884; the
   middle half of the residuals lies within ×0.66…×1.63 of the fit, the 5th–95th percentiles
   within ×0.23…×3.3 — a few hundred rank places mid-list. Applied to the 43 verbs only Google
   Books counts, and clamped at the count of CORPES rank 1,000 (5,935) so no estimate can enter
   the top of the list, it yields `podrir` ≈ 2,764 (≈ #1,454), `remplazar` ≈ 1,109 (≈ #2,210),
   `trasmutar` ≈ 297 (≈ #3,220), `trasbordar` ≈ 149 (≈ #3,640), `rescribir` and `salgar` ≈ 96
   (≈ #3,870), `mixtificar` 78, `rembolsar` 58, `despiezar` 54, `superabundar` 38, `abanar` 33,
   `gallardear` 32, `abalar` 30, `almohazar` 23, `coercer` 18, `empeller` 13, `ventiscar` 11,
   `cizañar` and `rodrigar` 9, and single digits for the rest down to `abetunar`, `bribonear`,
   `xerocopiar`, `xerografiar`, `yodurar`, `desaclimatar` at 1. Every one of those is plausible
   company. The four with no data anywhere (`aguachicolear`, `desenfurruñar`,
   `desentablillar`, `presintonizar`) get an editorial 0 with a stated reason, and
   `sobre(e)ntender` gets renamed. Carry Konjugieren's `hp="y"` flag on every estimated row so
   the provisional population stays countable and a later source can replace it. Measured
   zeros do not exist here — CORPES lists only what it saw — so nothing measured is estimated.
3. **Keep the pipeline out of the app target.** A `frequency/` folder at the repo root, like
   `corpus/`: the build script tracked; `corpes_lemas.zip` (16 MB) gitignored with its SHA-256
   and a download note ("open in a browser; the site refuses curl"); the zip's `license.txt`
   tracked; the Google Books `_VERB` extraction (3.2 GB streamed, nothing kept) reduced to a
   committed `gbooks_verb_lemmas.tsv` of 4,811 lines with the recipe in a README.
   `_build_verbmap.py` reads the new table instead of `SpanishVerbFrequencyRanks.txt`.
4. **App code that assumes "~1,000 ranked."** `WidgetSnapshotWriter.rankedVerbs()` must keep a
   top-N window (1,000 is the current behavior) so the verb of the day and the widget quiz never
   serve `churruscar`; the `WidgetSnapshot.frequencyRank` comment and `SnapshotReader`'s sample
   need the same edit. `VerbSort.frequency`'s nil branches become dead; `VerbMapTests`'
   "exactly 988 distinct ranks" and `VerbSortTests`' unranked-verb cases change accordingly.
5. **Attribution.** CC BY-SA 4.0 asks for credit, a license link, and a note that changes were
   made; the derived counts in `verbModelMap.xml` are shared under the same license (the app
   is AGPL; the data file is a separate work and carries its own notice). Ship `license.txt`
   with the pipeline and add to the Credits screen something like:

   > ^Verb frequencies^
   >
   > Each verb's frequency rank is derived from the lemma-frequency lists of the Real Academia
   > Española's *Corpus del Español del Siglo XXI* (CORPES XXI, version 1.5), published under
   > the Creative Commons Attribution-ShareAlike 4.0 license, %https://creativecommons.org/licenses/by-sa/4.0/%.
   > ~Conjugar~ merges each pronominal lemma into its base verb and orders ties with verb counts
   > from the Google Books Ngram data (2020 release, Creative Commons Attribution 3.0). The
   > derived counts are shared under the same Attribution-ShareAlike license.
   >
   > ^Frecuencias de los verbos^
   >
   > El rango de frecuencia de cada verbo se deriva de las listas de frecuencias de lemas del
   > *Corpus del Español del Siglo XXI* (CORPES XXI, versión 1.5) de la Real Academia Española,
   > publicadas bajo la licencia Creative Commons Atribución-CompartirIgual 4.0,
   > %https://creativecommons.org/licenses/by-sa/4.0/deed.es%. ~Conjugar~ fusiona cada lema
   > pronominal con su verbo base y desempata con los recuentos verbales de los datos de Google
   > Books Ngram (edición de 2020, Creative Commons Atribución 3.0). Los recuentos derivados se
   > comparten bajo la misma licencia Atribución-CompartirIgual.

   Add the same to the README.
6. **Retire the 2018 files** — `SpanishVerbFrequencies.xml`, `SpanishVerbFrequencyRanks.txt`,
   `verbs.csv`, `freq_unmatched.txt` — or keep the XML in `docs/` as provenance of the ranks
   users saw in 2026; either way fix `project-structure.md`, which calls `verbs.csv` "the same
   ranking."

### Optional courtesy note to the RAE

Not required by the license. The 2021 post invites contact at `corpus@rae.es`; if Josh wants
the RAE to know, plain text, no Markdown:

```
Asunto: Uso de las listas de frecuencias del CORPES XXI en una aplicación gratuita

Estimado equipo del CORPES:

Les escribo para informarles de que Conjugar, una aplicación gratuita y de
código abierto para iOS que conjuga 4.811 verbos españoles
(https://github.com/vermont42/Conjugar), va a utilizar la lista de
frecuencias de lemas del CORPES XXI (versión 1.5) para ordenar sus verbos
por frecuencia de uso, conforme a la licencia CC BY-SA 4.0 con la que
publican los datos. La aplicación atribuirá la fuente a la Real Academia
Española y al CORPES XXI en su pantalla de créditos, enlazará la licencia
e indicará las modificaciones (fusión de los lemas pronominales con su
verbo base). Si prefieren una fórmula de atribución concreta, la
incorporaré con gusto.

Muchas gracias por publicar estos datos.

Josh Adams
vermontcoder@gmail.com
```

## Appendix: reproduction recipes

Downloads (the RAE files need a browser — `www.rae.es` answers `curl` with a Cloudflare
challenge and the Wayback copies are access-restricted; everything else is plain `curl`):

```
https://www.rae.es/corpes/assets/rae/files/corpes/corpes_lemas.zip
https://www.rae.es/corpes/assets/rae/files/corpes/listas_dp_lemas.tsv
https://www.rae.es/corpes/assets/rae/files/corpes/diccionario_frecuencias_corpes_alfa.tsv
https://www.rae.es/corpes/contenidos/lemas-pais            # the 21 per-country lists
```

```bash
for i in 0 1 2; do
  curl -sS "http://storage.googleapis.com/books/ngrams/books/20200217/spa/1-0000$i-of-00003.gz" \
    | gunzip -c | LC_ALL=C grep -a $'^[^\t]*_VERB\t' > gbooks_verb_$i.tsv      # ~3.2 GB streamed
done
curl -sSLo es_full.txt https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/es/es_full.txt
curl -sSLo SUBTLEX-ESP.xlsx https://osf.io/download/fxt57/
curl -sSLo doozan_frequency.csv https://raw.githubusercontent.com/doozan/spanish_data/master/frequency.csv
curl -sSo span_40k_lemmas.txt https://www.wordfrequency.info/span/samples/span_40k_lemmas.txt
curl -sS "https://pay.sketchengine.eu/api.cgi?c=pricelist"
```

CORPES coverage with the *-se* merge (`frecuencia_lemas_corpes_1_5.txt` is tab-separated;
column 0 the lemma, column 1 a one-letter class, column 2 the absolute frequency; two header
lines):

```python
import re
inf = sorted({m for m in re.findall(r'<verb in="([^"]+)"', open('Conjugar/Models/verbModelMap.xml').read())})
V = {}
for line in open('frecuencia_lemas_corpes_1_5.txt', encoding='utf-8'):
    f = line.rstrip('\n').split('\t')
    if len(f) >= 3 and f[1].strip() == 'V' and f[2].strip().isdigit():
        V[f[0].strip()] = V.get(f[0].strip(), 0) + int(f[2])
counts = {v: V.get(v, 0) + V.get(v + 'se', 0) for v in inf}
print(sum(1 for c in counts.values() if c), 'covered;', [v for v in inf if not counts[v]])
```

Google Books lemma counts through the app's paradigms (`corpus/working/forms_all.json` is
`{"form": ["infinitive", …]}`; regenerate it with `CorpusFormsDumpTests` if the verb map has
changed):

```python
import json, re, collections
forms = json.load(open('corpus/working/forms_all.json'))
fc = collections.Counter()
for i in range(3):
    for line in open(f'gbooks_verb_{i}.tsv', encoding='utf-8', errors='replace'):
        tok, _, rest = line.partition('\t')
        form = tok[:-5].lower()                       # strip _VERB
        if not re.match(r'^[a-záéíóúüñ]+$', form) or form not in forms: continue
        fc[form] += sum(int(p[1]) for p in (r.split(',') for r in rest.split('\t')) if len(p) == 3 and int(p[0]) >= 1950)
mass = collections.Counter(); amb = []
for form, c in fc.items():
    cands = forms[form]
    if len(cands) == 1: mass[cands[0]] += c
    else: amb.append((c, cands))
base = mass.copy()
for _ in range(15):                                   # EM split of fui/fue/era/…
    add = collections.Counter()
    for c, cands in amb:
        tot = sum(mass[v] + 1.0 for v in cands)
        for v in cands: add[v] += c * (mass[v] + 1.0) / tot
    mass = base + add
```

Spearman: rank both orderings over the verbs both have, average ranks within ties, and apply
`1 − 6·Σd² / n(n²−1)` (equivalently, Pearson on the ranks). The in-browser measurement of the
RAE files, for the record: from any `www.rae.es` tab, `fetch('/corpes/assets/rae/files/corpes/corpes_lemas.zip')`,
read the central directory, and pipe the second member's bytes through
`new DecompressionStream('deflate-raw')` — the 53 MB text decodes in a few seconds and never
touches the disk.

Pages consulted: `rae.es/banco-de-datos/corpes-xxi`, `rae.es/noticia/conozca-algo-mas-el-corpes-listados-de-frecuencias`,
`rae.es/corpes/contenidos/lemas-pais`, `rae.es/aviso-legal`, `corpus.rae.es/lfrecuencias.html`,
`revistas.udc.es/index.php/rlex/article/view/11847` (the *Diccionario de frecuencias* paper),
`todoele.net/diccionarios/diccionario-de-frecuencias-lexicas-basado-en-el-corpes`;
`wordfrequency.info/spanish.asp`, `/span/files.asp`, `/purchase.asp`, `/license/spanish_40k_{acad,com}.doc`,
`corpusdata.org/spanish.asp`, `/purchase.asp`; `lexicalcomputing.com/spanish-word-frequency-lists-for-download/`,
`/word-list-n-gram-price-list/`, `sketchengine.eu/estenten-spanish-corpus/`, `/spanish-word-list/`,
`pay.sketchengine.eu/api.cgi?c=pricelist`; `storage.googleapis.com/books/ngrams/books/datasetsv3.html`
and `…/20200217/spa/spa-1-ngrams_exports.html`; `bcbl.eu/databases/espal/` and its FAQ;
`osf.io/xp6sz`; `github.com/doozan/spanish_data`, `github.com/hermitdave/FrequencyWords`,
`github.com/bnpd/freqListsLemmatized`; `en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Spanish`;
`corpus.leeds.ac.uk` (unreachable).
