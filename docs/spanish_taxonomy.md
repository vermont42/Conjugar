# Spanish Verb Taxonomy for Conjugar (composition model)

This is **our** model taxonomy for Conjugar — not the book's. It uses the
conjugation *facts* transcribed in `spanish_models.md`, but reorganizes them for
**maximum parsimony**: every irregularity is defined **once** and reused
everywhere it recurs.

It deliberately diverges from Conjuguer in two ways Josh chose:

1. **Most models have parents.** Even "fundamentally irregular" verbs (ser,
   haber, estar, …) are expressed as a regular **base + overrides**, not as
   parentless roots. (In Conjuguer, être/avoir are roots; here their Spanish
   analogues are not.)
2. **Composition instead of single-parent inheritance.** A model is a **base
   root + an ordered list of composable features**, rather than a single
   `parentId`. This is the key change that makes the representation minimal,
   because Spanish irregularities are *orthogonal and combinatorial* (e.g.
   `tener` = `comer` + diphthong + go-1s + dr-future + strong-preterite), and a
   single parent can only capture one axis.

> **Status:** design/taxonomy only. No engine or XML is written yet. The slot
> vocabulary and feature definitions below are precise enough to encode later,
> but the Conjugar `Conjugator` + model schema will need to be built to match
> (the Conjuguer engine is single-parent and French-specific).

---

## 1. The composition model

```
verb        →  model
model       =  base  +  [feature, feature, …]  +  residue
base        ∈  { cantar (-ar), comer (-er), subir (-ir) }   // §3
feature     ∈  the feature catalog                          // §4
residue     =  per-model overrides too rare to share        // participle, etc.
```

- A model names exactly one **base** (one of the three regular roots) and a
  list of **features**. Conjugating = start from the base's regular endings,
  then apply each feature's slot overrides **in listed order; on a slot
  conflict, the later feature wins.**
- Recommended order so precedence is predictable: **base → stem-vowel →
  1s/subjunctive → preterite → future → participle → residue.** (Example: for
  `tener`, the diphthong sets 1s `*tieng-`, then go-1s overrides 1s → `teng-`.)
- A **feature is defined once** and referenced by many models. That single
  definition is the whole parsimony win.

### Derivation rules (so one override covers several tenses)

These mirror the book's own notes (ii)/(iii) and Conjuguer's design:

| Rule | One override of… | …automatically drives |
|---|---|---|
| **Future stem** | the future stem (default = infinitive) | Future **and** Conditional |
| **Strong preterite** | the preterite stem | both Imperfect Subjunctives (-ra / -se) |
| **subj-from-1s** | the present-indicative **1s** stem | the **whole** Present Subjunctive |
| **Imperative** | (mostly derived) | tú ≈ PI 3s; vosotros = infinitive − r + d; usted/ustedes/nosotros = PS |

Imperfect indicative is regular for **every** Spanish verb except `ser`, `ir`,
`ver` (handled as residue).

### Prefixed verbs and the end-anchored constraint

Prefixed compounds (`reconocer`, `deshacer`, `componer`, `describir`,
`recontar`, `reenviar`, `releer`, …) need **no model of their own**: the verb
just references its base's model, and the engine conjugates the verb's *own*
stem (`reconoc-`). Because every feature's slot operation is **anchored to the
end of the stem** (index-from-end or letter-based, never from the start), the
prefix rides along untouched — `c→zc` on `reconoc` yields `reconozco`
automatically. So prefixed verbs are pure **data entry** (assign the base's
model), exactly as in Conjuguer.

> **Constraint (must hold for every feature):** define each slot operation
> relative to the **end** of the stem, never the beginning. This is what makes
> features prefix-invariant. It is the rule that lets one `conocer` model cover
> `conocer`, `reconocer`, `desconocer`, … for free.

We deliberately do **not** model verbs as an explicit `prefix + base` pair. It's
unnecessary for correctness, and the from-end rule already delivers the benefit.

**Exception — compounds that differ by more than the prefix.** Almost always a
written-accent shift on a monosyllabic base form: base `ten`/`pon`/`ven` are
stressless monosyllables, but `obtén`/`supón`/`convén` become polysyllabic and
require an accent. These get a **derived model = base model + a one-slot
residue** (and the book already isolates them: 30-1 suponer, 31-1 obtener,
32-1 convenir; likewise 28-1 predecir / 28-2 bendecir off `decir`, and
`satisfacer` = `hacer` + `IMP satisfaz`). A residue used by a single model is
just a feature, so the mechanism is uniform.

---

## 2. Slot vocabulary

Person codes: `1s 2s 3s 1p 2p 3p`. Tense codes:

| Code | Tense |
|---|---|
| `PI` | presente de indicativo |
| `IM` | pretérito imperfecto (indicativo) |
| `PR` | pretérito (indefinido / simple past) |
| `FU` | futuro simple |
| `CO` | condicional |
| `PS` | presente de subjuntivo |
| `IS` | pretérito imperfecto de subjuntivo (-ra and -se; derived from `PR` stem) |
| `IMP` | imperativo (afirmativo: 2s, 2p) |
| `PP` | participio pasado |
| `GER` | gerundio |

Two named slot sets recur constantly:

- **STR** ("stressed stem") = `PI{1s,2s,3s,3p}` + `PS{1s,2s,3s,3p}` + `IMP{2s}`.
  Where stem-vowel changes surface (the stress falls on the stem).
- **WK** ("weak -ir slots") = `PS{1p,2p}` + `PR{3s,3p}` + `GER` + `IS{all}`.
  Where -ir verbs raise e→i / o→u (and where i→y / i-absorption happen).

---

## 3. The three regular roots

Endings only — these are the ground truth the engine composes onto. (-er and
-ir differ in just **PI 1p/2p** and **IMP 2p**; kept as separate roots for
tradition and clarity.)

### `cantar` — regular -ar

| Tense | 1s | 2s | 3s | 1p | 2p | 3p |
|---|---|---|---|---|---|---|
| PI | -o | -as | -a | -amos | -áis | -an |
| IM | -aba | -abas | -aba | -ábamos | -abais | -aban |
| PR | -é | -aste | -ó | -amos | -asteis | -aron |
| FU | -aré | -arás | -ará | -aremos | -aréis | -arán |
| CO | -aría | -arías | -aría | -aríamos | -aríais | -arían |
| PS | -e | -es | -e | -emos | -éis | -en |
| IS-ra | -ara | -aras | -ara | -áramos | -arais | -aran |
| IS-se | -ase | -ases | -ase | -ásemos | -aseis | -asen |
| IMP | — | -a | — | — | -ad | — |

PP `-ado` · GER `-ando`

### `comer` — regular -er

| Tense | 1s | 2s | 3s | 1p | 2p | 3p |
|---|---|---|---|---|---|---|
| PI | -o | -es | -e | -emos | -éis | -en |
| IM | -ía | -ías | -ía | -íamos | -íais | -ían |
| PR | -í | -iste | -ió | -imos | -isteis | -ieron |
| FU | -eré | -erás | -erá | -eremos | -eréis | -erán |
| CO | -ería | -erías | -ería | -eríamos | -eríais | -erían |
| PS | -a | -as | -a | -amos | -áis | -an |
| IS-ra | -iera | -ieras | -iera | -iéramos | -ierais | -ieran |
| IS-se | -iese | -ieses | -iese | -iésemos | -ieseis | -iesen |
| IMP | — | -e | — | — | -ed | — |

PP `-ido` · GER `-iendo`

### `subir` — regular -ir

| Tense | 1s | 2s | 3s | 1p | 2p | 3p |
|---|---|---|---|---|---|---|
| PI | -o | -es | -e | -imos | -ís | -en |
| IM | -ía | -ías | -ía | -íamos | -íais | -ían |
| PR | -í | -iste | -ió | -imos | -isteis | -ieron |
| FU | -iré | -irás | -irá | -iremos | -iréis | -irán |
| CO | -iría | -irías | -iría | -iríamos | -iríais | -irían |
| PS | -a | -as | -a | -amos | -áis | -an |
| IS-ra | -iera | -ieras | -iera | -iéramos | -ierais | -ieran |
| IS-se | -iese | -ieses | -iese | -iésemos | -ieseis | -iesen |
| IMP | — | -e | — | — | -id | — |

PP `-ido` · GER `-iendo`

---

## 4. Feature catalog

Each feature is defined once. "Scale" is a rough sense of how many of the 4,818
verbs it touches (exact counts to be pulled from the book's verb list later).

### 4.1 Orthographic (spelling-only; triggered by the stem-final consonant)

These are the highest-leverage features — each covers an entire spelling class.

| Feature | Rule | Slots | Example | Scale |
|---|---|---|---|---|
| `o-car` | c → qu before e | `PR 1s` + `PS{all}` | tocar → toqué, toque | all -car |
| `o-gar` | g → gu before e | `PR 1s` + `PS{all}` | pagar → pagué, pague | all -gar |
| `o-guar` | gu → gü before e | `PR 1s` + `PS{all}` | averiguar → averigüé | -guar |
| `o-zar` | z → c before e | `PR 1s` + `PS{all}` | cazar → cacé, cace | all -zar |
| `o-cz` | c → z before a/o | `PI 1s` + `PS{all}` | vencer → venzo; fruncir → frunzo | -cer/-cir (cons.) |
| `o-gj` | g → j before a/o | `PI 1s` + `PS{all}` | coger → cojo; dirigir → dirijo | -ger/-gir |
| `o-gug` | gu → g before a/o | `PI 1s` + `PS{all}` | distinguir → distingo | -guir |
| `o-quc` | qu → c before a/o | `PI 1s` + `PS{all}` | delinquir → delinco | -quir |
| `o-yhiatus` | unstressed i → y between vowels; the remaining regular -i- forms take a written accent to mark the hiatus | i→y: `PR{3s,3p}` + `GER` + `IS{all}`; +accent: `PR{2s,1p,2p}` + `PP` | leer → leyó, leyendo, leíste, leído | -eer/-aer/-oer/-uir |
| `o-llñ` | i absorbed after ll/ñ (-ió→-ó, -ieron→-eron, -iendo→-endo) | `PR{3s,3p}` + `GER` + `IS{all}` | tañer → tañó; bullir → bulló | -llir/-ñir/-ñer |

### 4.2 Stress-accent (orthographic accent on the stem vowel in STR)

| Feature | Rule | Slots | Example | Scale |
|---|---|---|---|---|
| `a-i` | i → í | STR | enviar → envío | ~30% of -iar |
| `a-u` | u → ú | STR | actuar → actúo | -uar (not -cuar/-guar) |
| `a-stem` | accent the stem vowel (param: í/ú per verb) | STR | aislar → aíslo; reunir → reúno; prohibir → prohíbo | small closed sets |

### 4.3 Stem-vowel changes in STR (diphthong / raise)

| Feature | Rule | Slots | Example | Scale |
|---|---|---|---|---|
| `d-ie` | e → ie | STR | pensar, perder, querer, discernir | large |
| `d-ue` | o → ue | STR | mostrar, mover, poder | large |
| `d-ie-ye` | e → ie spelled **ye-** (word-initial) | STR | errar → yerro | tiny |
| `d-ue-gue` | o → ue spelled **güe** | STR | agorar → agüero; avergonzar | tiny |
| `d-ue-hue` | o → ue spelled **hue-** | STR | oler → huelo; desosar → deshueso | tiny |
| `d-i-ie` | i → ie | STR | adquirir, inquirir | tiny |
| `d-u-ue` | u → ue | STR | jugar → juego | jugar only |

### 4.4 -ir weak-slot raising (the "umlaut" of `spanish_models.md` §6)

| Feature | Rule | Slots | Example |
|---|---|---|---|
| `r-ei-wk` | e → i | WK | sentir → sintió, sintamos, sintiera |
| `r-ei-str` | e → i (instead of a diphthong) | STR | pedir → pido |
| `r-ou-wk` | o → u | WK | dormir → durmió, durmamos |

Compositions: **sentir** = `subir` + `d-ie` + `r-ei-wk`; **pedir** = `subir` +
`r-ei-str` + `r-ei-wk`; **dormir** = `subir` + `d-ue` + `r-ou-wk`.

### 4.5 Irregular 1s present + subjunctive

| Feature | Rule | Slots | Example | Scale |
|---|---|---|---|---|
| `subj-from-1s` | PS{all} built on the PI 1s stem | `PS{all}` | (structural; bundled into the three below) | — |
| `g1-g` | insert -g- in PI 1s (+ `subj-from-1s`) | `PI 1s`, `PS{all}` | salir → salgo; poner → pongo | ~half a dozen |
| `g1-ig` | insert -ig- in PI 1s (+ `subj-from-1s`) | `PI 1s`, `PS{all}` | caer → caigo; oír → oigo; traer → traigo | 3 + derivatives |
| `zc` | c → zc in PI 1s (+ `subj-from-1s`) | `PI 1s`, `PS{all}` | conocer → conozco; lucir → luzco | **hundreds** (-acer/-ecer/-ocer/-ucir) |
| `y-add` | insert -y- (PI 1s/2s/3s/3p, PS all) | `PI{1s,2s,3s,3p}`, `PS{all}` | construir → construyo, construya | -uir (+ `o-yhiatus` for WK) |

### 4.6 Strong / suppletive preterites (each drives `IS` via the derivation rule)

| Feature | Rule | Example |
|---|---|---|
| `sp-end` | "grave" preterite endings (unstressed 1s/3s): -e, -iste, -o, -imos, -isteis, **-ieron** | tener → tuve, tuviste, tuvo… |
| `sp-jend` | j-preterite endings: …, **-eron** (no i after j) | decir → dije…dijeron; conducir → conduje…condujeron |
| `wp-i` | weak monosyllabic -i preterite (di/dio, vi/vio) | dar, ver |
| `pret-fue` | suppletive **fu-** stem (shared) | ser **and** ir → fui, fuiste, fue… |

The **strong stem itself** (`estuv-`, `tuv-`, `anduv-`, `pud-`, `pus-`, `sup-`,
`cup-`, `hic-`, `quis-`, `vin-`, `dij-`, `traj-`, `-duj-`, `hub-`, `quep-`…) is
per-verb residue listed in §5 — it can't be shared, but the *endings* (`sp-end`
/ `sp-jend`) and the IS-derivation are.

### 4.7 Future / conditional stems (drive both FU and CO)

| Feature | Rule | Example |
|---|---|---|
| `f-drope` | -er → -r (drop the theme vowel) | haber → habr-; saber → sabr-; poder → podr-; querer → querr-; caber → cabr- |
| `f-dr` | insert d (drop vowel) | tener → tendr-; poner → pondr-; salir → saldr-; valer → valdr-; venir → vendr- |
| `f-contract` | irregular contraction (per-verb) | hacer → har-; decir → dir- |

### 4.8 Irregular participles (per-model attribute, like Conjuguer's `ep`)

Not a shared feature — a per-model value, but listed here for completeness:
`abierto, cubierto, escrito, impreso/imprimido, podrido, roto, resuelto,
vuelto, muerto, puesto, hecho, dicho, visto, frito` (+ regular fallbacks). Use a
case-encoding convention (regular vs. irregular) so the irregularity score can
count it, exactly as Conjuguer does with upper/lowercase `ep`.

---

## 5. The 35 book classes expressed as base + features

`spanish_models.md` numbering. "Residue" = per-verb stems/forms too rare to
share. This is the payoff: even the "fundamentally irregular" verbs reduce to a
base + a short feature list.

### Regular + orthographic + accent

| # | Verb | = base + features (+ residue) |
|---|---|---|
| 1 | cantar | **cantar** (root) |
| 1-1…1-4 | tocar/pagar/averiguar/cazar | cantar + `o-car`/`o-gar`/`o-guar`/`o-zar` |
| 1-5…1-13 | aislar…europeizar | cantar + `a-stem` (and + `o-zar`/`o-gar`/`o-car` for the combined ones, e.g. 1-10 ahincar = cantar + `a-stem` + `o-car`) |
| 1-14 / 1-15 | actuar / enviar | cantar + `a-u` / `a-i` |
| 2 | comer | **comer** (root) |
| 2-1 / 2-2 | vencer / coger | comer + `o-cz` / `o-gj` |
| 2-3 | leer | comer + `o-yhiatus` |
| 2-4 / 2-5 | empeller / tañer | comer + `o-llñ` |
| 2-6 | romper | comer + residue: PP `roto` |
| 3 | subir | **subir** (root) |
| 3-1…3-4 | fruncir/dirigir/distinguir/delinquir | subir + `o-cz`/`o-gj`/`o-gug`/`o-quc` |
| 3-5 / 3-6 | bullir / bruñir | subir + `o-llñ` |
| 3-7 / 3-8 | reunir / prohibir | subir + `a-stem` |
| 3-9…3-13 | abrir/cubrir/escribir/imprimir/pudrir | subir + residue: PP `abierto/cubierto/escrito/impreso/podrido` |
| 3-14 | abolir | subir + residue: defective (only STR-less forms exist) |

### Diphthongs

| # | Verb | = base + features |
|---|---|---|
| 4A | pensar | cantar + `d-ie` |
| 4A-1…4A-3 | negar/empezar/errar | cantar + `d-ie` + `o-gar`/`o-zar`; errar = cantar + `d-ie-ye` |
| 4B | mostrar | cantar + `d-ue` |
| 4B-1…4B-6 | trocar/colgar/forzar/agorar/desosar/avergonzar | cantar + `d-ue`(or `d-ue-gue`/`d-ue-hue`) + `o-car`/`o-gar`/`o-zar` |
| 5A / 5B | perder / mover | comer + `d-ie` / `d-ue` |
| 5B-1 / 5B-2 | cocer / oler | comer + `d-ue`(+`o-cz`) / `d-ue-hue` |
| 5B-3 / 5B-4 | resolver / volver | comer + `d-ue` + residue: PP `resuelto`/`vuelto` |

### Diphthong + -ir raising

| # | Verb | = base + features |
|---|---|---|
| 6A | sentir | subir + `d-ie` + `r-ei-wk` |
| 6A-1 | erguir | subir + `r-ei-str` + `r-ei-wk` + `o-gug` (+ alt. `d-ie-ye` forms as residue) |
| 6B | pedir | subir + `r-ei-str` + `r-ei-wk` |
| 6B-1 / 6B-2 | elegir / seguir | pedir-features + `o-gj` / `o-gug` |
| 6B-3 | ceñir | subir + `r-ei-str` + `r-ei-wk` + `o-llñ` |
| 6B-4 | reír | subir + `r-ei-str` + `r-ei-wk` + residue: hiatus accents (ríe, rió, riendo) |
| 6C | dormir | subir + `d-ue` + `r-ou-wk` |
| 6C-1 | morir | dormir-features + residue: PP `muerto` |

### -zco, "add -y", and -go

| # | Verb | = base + features |
|---|---|---|
| 7A / 7B | conocer / lucir | comer + `zc` / subir + `zc` |
| 7A-1 / 7A-2 | yacer / placer | comer + `zc` + residue: alternate/archaic forms |
| 8 | construir | subir + `y-add` + `o-yhiatus` |
| 9 | caer | comer + `g1-ig` + `o-yhiatus` |
| 9-1 / 9-2 | raer / roer | comer + `g1-ig` + `o-yhiatus` + residue: alternates (raigo/rayo) |
| 10 | oír | subir + `g1-ig` + `y-add` + `o-yhiatus` + `a-stem` |
| 11 | salir | subir + `g1-g` + `f-dr` + residue: IMP `sal` |
| 12 | valer | comer + `g1-g` + `f-dr` |
| 13 | asir | subir + `g1-g` |

### Mixed

| # | Verb | = base + features |
|---|---|---|
| 14 | ver | comer + residue: PI `ve-` stem (veo, ves…), IM `veía` (irregular), PP `visto`, `wp-i` preterite |
| 14-1 | prever | ver + residue: monosyllable accents (prevé, prevés…) |
| 15 | discernir | subir + `d-ie` (no weak raise — like perder but -ir) |
| 16 | jugar | cantar + `d-u-ue` + `o-gar` |
| 17 | adquirir | subir + `d-i-ie` |
| 18 | argüir | subir + `y-add` + `o-yhiatus` + residue: diaeresis (güy→guy) |

### Fundamentally irregular → base + features + small residue

| # | Verb | = base + features (+ residue) |
|---|---|---|
| 19 | ser | comer + `pret-fue` + residue: PI (soy/eres/es/somos/sois/son), PS `sea-`, IM `era-`, IMP `sé` |
| 20 | estar | cantar + `sp-end` + residue: PI accents + `estoy`, strong stem `estuv-` |
| 21 | haber | comer + `sp-end` + `f-drope` + residue: PI (he/has/ha/hemos/habéis/han), PS `haya-`, strong stem `hub-`, IMP `he` |
| 22 | saber | comer + `sp-end` + `f-drope` + residue: PI 1s `sé`, PS `sep-`, strong stem `sup-` |
| 23 | caber | comer + `sp-end` + `f-drope` + residue: PI 1s `quepo`, PS `quep-`, strong stem `cup-` |
| 24 | ir | subir + `pret-fue` + residue: PI (voy/vas/va/vamos/vais/van), IM `iba-`, PS `vaya-`, IMP `ve`, GER `yendo` |
| 25 | dar | cantar + `wp-i` + residue: PI 1s `doy`, PS `dé/des/dé…` |
| 26 | poder | comer + `d-ue` + `sp-end` + `f-drope` + residue: strong stem `pud-`, GER `pudiendo` |
| 27 | querer | comer + `d-ie` + `sp-end` + `f-drope` + residue: strong stem `quis-` |
| 28 | decir | subir + `r-ei-str`+`r-ei-wk` + `g1-…`(dig-) + `sp-jend` + `f-contract`(dir-) + residue: PP `dicho`, IMP `di`, strong stem `dij-` |
| 28-1 / 28-2 | predecir / bendecir | decir − some overrides (regular IMP `predice`; bendecir also regular FU/CO + PP `bendecido`) |
| 29 | hacer | comer + `g1-…`(hag-) + `sp-end` + `f-contract`(har-) + residue: PP `hecho`, IMP `haz`, strong stem `hic-`/`hizo` |
| 29-1 / 29-2 | rehacer / satisfacer | hacer + residue: accents (rehíce) / IMP `satisfaz` |
| 30 | poner | comer + `g1-g`(pong-) + `sp-end` + `f-dr`(pondr-) + residue: PP `puesto`, IMP `pon`, strong stem `pus-` |
| 30-1 | suponer | poner + residue: IMP accent `supón` |
| 31 | tener | comer + `d-ie` + `g1-g`(teng-) + `sp-end` + `f-dr`(tendr-) + residue: IMP `ten`, strong stem `tuv-` |
| 31-1 | obtener | tener + residue: IMP accent `obtén` |
| 32 | venir | subir + `d-ie` + `g1-g`(veng-) + `r-ei-wk`(GER viniendo) + `sp-end` + `f-dr`(vendr-) + residue: IMP `ven`, strong stem `vin-` |
| 32-1 | convenir | venir + residue: IMP accent `convén` |
| 33 | traer | comer + `g1-ig`(traig-) + `sp-jend` + `o-yhiatus`(trayendo/traído) + residue: strong stem `traj-` |
| 34 | -ducir (conducir) | subir + `zc` + `sp-jend` + residue: strong stem `-duj-` |
| 35 | andar | cantar + `sp-end` + residue: strong stem `anduv-` |

Note how thin the residue is for the "fundamentally irregular" verbs:
**andar** = `cantar` + one feature + one stem; **estar** = `cantar` + one
feature + accents + one stem; **tener** = `comer` + four shared features + a
stem and a short imperative. That is the parsimony goal realized.

---

## 6. Resolved decisions

All six resolved (Josh, 2026-06-12).

1. **Feature ordering — RESOLVED: apply in order, last wins on conflicts.**
   Features are applied in the model's listed order; when two features touch the
   same slot, the later one wins (§1). No exclusive slot ownership / no
   overlap-erroring. This is what makes `tener` work: diphthong sets 1s
   `*tieng-`, then `g1-g` overrides 1s → `teng-`.
2. **`subj-from-1s` bundling — RESOLVED: keep it bundled** into `g1-g` /
   `g1-ig` / `zc`. No verb in the book needs an irregular 1s *without* the
   matching present subjunctive; if one ever appears we split it out then.
3. **Accent-class granularity — RESOLVED: parameters are fine.** `a-stem` stays
   a single feature parameterized by the accented vowel (í/ú), rather than being
   exploded into separate features. Fewer definitions.
4. **Residue representation — RESOLVED: residue *is* a feature.** A model carries
   optional stem-alterations + an optional participle override (Conjuguer's `p` +
   `ep` shape). A "residue" is simply alterations referenced by a *single* model
   instead of many. There is exactly **one** override mechanism — no
   special-casing for irregular verbs — which keeps both the `Conjugator` and the
   scoring (decision 5) uniform.
5. **Irregularity score — RESOLVED: use the cleaner composition-based score.**
   `score = (number of features) + (residue weight)`, with the case-encoding
   convention (regular vs. irregular endings) carried over from Conjuguer so the
   count is meaningful. Drives the per-model "X% irregular" display.
6. **Build approach — RESOLVED: parallel engine first, UI later.** Build a new
   system *alongside* the existing Conjugar conjugator — new models, a new
   composition-aware `Conjugator`, new XML files — exercised by **unit tests
   only**. No UI work until the engine is correct and trusted; UI changes follow.
   Rationale: the conjugation engine is the substantive change, so touching the
   UI first would be a distraction.

## 7. Agreed build plan

Engine-first / strangler approach. The hard, *bounded* work (engine + ~30
features + ~95 model exemplars) comes first; the bulky-but-easy 4,818-verb data
entry comes last, once the engine is trusted.

**Phase 0 — Oracle & groundwork.** The whole test strategy leans on a source of
truth, so establish it first:
- **Verify `spanish_models.md`** (my manual transcription) before it becomes
  load-bearing — its errors would otherwise masquerade as engine bugs.
- **Read the existing Conjugar conjugator** to reuse its (correct) Spanish accent
  + orthographic logic, and to use it as a differential oracle.
- Three oracles, in order of value: (a) the ~95 model exemplars from
  `spanish_models.md`, fully conjugated; (b) **differential test vs. the shipping
  Conjugar engine** over its 214 verbs; (c) external spot-check vs. the RAE.

**Phase 1 — Roots + skeleton.** Spanish `Tense`/ending-group types, the three
regular roots (§3), and a composition-aware `Conjugator`. Gate: regulars pass.

**Phase 2 — Orthographic + accent features** (§4.1, §4.2). Covers the *bulk* of
verbs for little code. Gate: all orthographic/accent exemplars pass.

**Phase 3 — Stem-vowel + -ir raising** (§4.3, §4.4).

**Phase 4 — 1s/subjunctive + preterite + future** (§4.5, §4.6, §4.7).

**Phase 5 — Residue** for the ~35 hard verbs (§5).

**Phase 6 — Data entry.** Only after the engine passes on all ~95 exemplars:
encode the verb→model map for all 4,818 verbs (pure data entry — assign each
verb its model, prefixed verbs included).

**Then — UI.** Models tab and the other Conjuguer-style UI changes.

Every phase is gated by unit tests against the Phase 0 oracles.
