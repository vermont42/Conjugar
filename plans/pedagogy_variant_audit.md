# Variant Audit for the Quiz's Accepted Answers

**For:** Josh, to rule on before pedagogy Phase 0 accepts any variant
([`pedagogy_implementation.md`](pedagogy_implementation.md) § Phase 0, T1.5). **Written:**
2026-11-22. A ruled variant becomes an accepted quiz answer only. The verb page keeps the engine's
form unless a row says otherwise.

## Method

1. **What the engine gives.** `ConjugationMapTool --cells-json` dumped every one-word form of the
   4,811 verbs with its cells. A script then listed every accented form that the 2010
   *Ortografía* counts as a monosyllable: one vowel group, with the accent on a diphthong or
   triphthong (a lone accented vowel, as in dé or sé, is a diacritic accent and stays). The other
   candidates were checked cell by cell in the same dump, and `Conjugator.conjugateAll` gave the
   alternates the engine already models.
2. **What the RAE says.** A research pass looked for each candidate in the *Diccionario
   panhispánico de dudas* (DPD), the *Diccionario de la lengua española* (DLE) and its
   conjugation tables, and the *Ortografía*. rae.es and dle.rae.es answered every scripted fetch
   with a Cloudflare 403, so the first pass read search-engine extracts of those pages. After
   Josh's rulings, Claude in Chrome read the pages themselves: every row once marked
   *unconfirmed*, and the DLE tables behind the engine change (fiar, huir, ver, hablar). Those
   readings are marked *read in Chrome*.
3. **Already decided:** the -ra and -se imperfect subjunctives do not accept each other.

## Rows

| # | Variant | Engine gives | Source says | Recommendation |
|---:|---|---|---|---|
| 1 | **2010 monosyllables:** rio, guio, crie, fie, lie, pie, frio (freír), hui, huis, flui, fluis, riais, friais, and the -iais/-ieis vosotros forms of criar, fiar, guiar, liar, piar | rió, guió, crié, fié, lié, pió, frió, huí, huís, fluí, fluís, riáis, friáis, criáis, criéis… | The *Ortografía* (2010) writes them unaccented and drops the double spelling that 1999 allowed. The DPD's [tilde](https://www.rae.es/dpd/tilde) entry lists "fie, fio, fiais, fieis". | Accept both spellings. The rule is computed, not listed, so it covers every such form and nothing else. |
| 2 | **Voseo of the same verbs:** fias, crias, guias, lias, pias (presente) and fia, cria, guia, lia, pia (imperativo) | fiás, criás, guiás, liás, piás; fiá, criá, guiá, liá, piá | The DPD's [tilde](https://www.rae.es/dpd/tilde) and [aun](https://www.rae.es/dpd/aun) entries give "las de voseo fias, fia (pron. [fiás], [fiá]), de fiar". *Read in Chrome:* the DLE's [fiar](https://dle.rae.es/fiar) table gives "fías / fias", fiais, fie, fio, and its [huir](https://dle.rae.es/huir) table "huyes / huis", hui, and the imperative "huye / hui". | Accept both. Row 1's rule already covers these. |
| 3 | **ver, vos imperative:** ve | vé | The DPD's [tilde](https://www.rae.es/dpd/tilde) and [ver](https://www.rae.es/dpd/ver) entries say accenting ve, vi, vio is incorrect. *Read in Chrome:* the DLE's [ver](https://dle.rae.es/ver) table gives "ve" for tú / vos. | Accept ve. See the defects below. |
| 4 | **Participle doublets:** frito (freír), sofrito, refrito; provisto (proveer), desprovisto; imprimido (imprimir) and reimprimido | freído, sofreído, refreído; proveído, desproveído; impreso, reimpreso (the engine already holds imprimido as an alternate) | These are the only three verbs, with their derivatives, whose two participles both work in compound tenses ([freír](https://www.rae.es/dpd/freír), [sofreír](https://www.rae.es/dpd/sofreír), [imprimir](https://www.rae.es/dpd/imprimir), [proveer](https://www.rae.es/dpd/proveer), [desproveer](https://dle.rae.es/desproveer), [refreír](https://dle.rae.es/refreír)). The DPD says frito is the commoner today. Electo, preso, and rompido are not for compound tenses. reimprimido is unconfirmed but follows "con sus respectivos derivados". | Accept, in the participio and in every compound tense (he frito). |
| 5 | **-scripto participles** (Argentina, Paraguay, Uruguay): inscripto, suscripto, descripto, prescripto, circunscripto | -scrito | The DLE's [inscribir](https://dle.rae.es/inscribir) and [suscribir](https://dle.rae.es/suscribir) entries, and the RAE's [El participio](https://www.rae.es/buen-uso-español/el-participio) page for the other three. *Read in Chrome:* the DLE's [proscribir](https://dle.rae.es/proscribir), [transcribir](https://dle.rae.es/transcribir), and [adscribir](https://dle.rae.es/adscribir) tables give "proscrito, proscripto", "transcrito, transcripto", and "adscrito, adscripto". escripto has no support. | Accept all eight, in the participio and the compound tenses. |
| 6 | **satisfacer, tú imperative:** satisface | satisfaz | The DLE's [satisfacer](https://dle.rae.es/satisfacer) entry says "satisfaz o satisface". | Accept. |
| 7 | **predecir, contradecir: future and conditional in -deciré, -deciría** | prediré, contradiré | The DPD's [predecir](https://www.rae.es/dpd/predecir) and [contradecir](https://www.rae.es/dpd/contradecir) entries admit both, and say predeciré is in fact commoner. *Read in Chrome:* the DPD's [desdecir](https://www.rae.es/dpd/desdecir) entry says "desdiré o desdeciré … desdiría o desdeciría" are used "con normalidad, en ciertas zonas". bendecir and maldecir have only bendeciré and maldeciré, which the engine gives. | Accept for predecir, contradecir, and desdecir, in the futuro and the condicional. |
| 8 | **-uar stress doublets:** adecúo, evacúo, licúo (and the other stressed cells) | adecuo, evacuo, licuo | The DLE's [adecuar](https://dle.rae.es/adecuar) entry says "c. averiguar o c. actuar". *Read in Chrome:* the DPD's [evacuar](https://www.rae.es/dpd/evacuar) and [licuar](https://www.rae.es/dpd/licuar) entries prefer averiguar's stress in cultivated use but call actuar's "hoy mayoritaria, y también válida". | Accept all three. |
| 9 | **-iar stress doublets:** agrio (agriar), expatrio (expatriar), and the other stressed cells | agrío, expatrío | The DPD's [agriar](https://www.rae.es/dpd/agriar) entry and the DLE's expatriar entry ("c. anunciar o c. enviar"). *Read in Chrome:* the DPD's [paliar](https://www.rae.es/dpd/paliar), [repatriar](https://www.rae.es/dpd/repatriar), and [historiar](https://www.rae.es/dpd/historiar) entries say each "puede acentuarse como anunciar … o como enviar", and [vidriar](https://www.rae.es/dpd/vidriar) prefers anunciar's "pero también se admite" enviar's. | Accept all six: palío, repatrio, historío, and vidrío beside the engine's palio, repatrío, historio, and vidrio. |
| 10 | **Voseo subjunctive:** vos hablés, tengás, vayás (presente de subjuntivo), and no hablés (imperativo negativo) | hables, tengas, vayas; no hables | The DPD's [voseo](https://www.rae.es/dpd/voseo) entry says that in Argentina the voseo forms alternate with the tuteo forms, and that Uruguay and Paraguay prefer the tuteo forms. *Read in Chrome:* the DLE's [hablar](https://dle.rae.es/hablar) table lists only hables for tú / vos, so the DPD is the only support. The vos negative imperative is not addressed separately. | Accept, for vos questions only, in the presente de subjuntivo, the imperativo negativo, and the perfecto de subjuntivo (hayás hablado). Build each form from the vosotros form without its i (habléis → hablés, deis → des). |
| 11 | **Forms the engine already models** (`conjugateAll`): erguir irgo/irga/irgue; yacer yazgo/yago and yaz; raer rayo/raya; roer roigo/royo, roiga/roya; imprimir imprimido | the first of each | The DLE and DPD list them all ([yacer](https://www.rae.es/dpd/yacer), [roer](https://www.rae.es/dpd/roer), [raer](https://dle.rae.es/raer)). The DPD prefers yazco and roo. | Accept. |
| 12 | **placer's archaic forms:** plegue, plega, plugo | plació, plazca | The DPD's [placer](https://rae.es/dpd/placer) entry calls them literary and archaizing, mostly in "plega a Dios". | Accept, since the engine models them and no one types plugo by mistake. |
| 13 | **irse, vosotros imperative:** iros beside idos | — | The DPD's [ir](https://rae.es/dpd/ir) entry and an RAE note: idos is recommended, and iros "se puede considerar válido". | Not applicable: the quiz asks ir, never irse. Revisit if a pronominal verb is asked. |

## Defects on the Verb Page

These are not quiz variants. Each changes what the verb page and the conjugation map show.

- **The engine wrote the pre-2010 accents** of rows 1 and 2 (rió, guió, fiás, huí, and the
  rest), which the RAE has not admitted since 2010. *Fixed in Phase 0* (see Rulings).
- **ver's vos imperative was vé** (row 3). *Fixed in Phase 0:* a residue entry on ver's model
  gives ve.

## Rulings

**Josh, 2026-11-22:**

- **Rows 1 to 9 and 11 to 12:** accept, as recommended, for quiz acceptance only.
- **Row 10, the voseo subjunctive:** accept, for vos questions only.
- **The unconfirmed rows:** confirm them in Chrome first. All were confirmed (above) and are
  accepted.
- **The verb page:** change it in Phase 0. The engine now writes the 2010 spelling everywhere
  (`Orthography.currentSpelling(of:)`, applied to every form it composes), and ver's vos
  imperative is ve. `Conjugator.conjugateAll` keeps each retired spelling last, so the quiz still
  takes rió.
- **Row 13 (iros):** not applicable while the quiz asks no pronominal verb.
