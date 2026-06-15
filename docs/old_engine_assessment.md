# Assessment of the existing Conjugar engine (as logic reference + differential oracle)

**Date:** 2026-06-12
**Subject:** `/Users/josh/Desktop/workspace/Conjugar.mig/Conjugar/` — `Conjugator.swift`
(432 lines), `verbs.xml` (214 verbs), `Tense.swift`, `PersonNumber.swift`,
`VerbParser.swift`, `StringExtensions.swift`.
**Why:** Build-plan step 1 proposed (a) mining the old engine's accent/orthographic
logic and (b) using it as a *differential oracle* against the new engine. This
records what's actually there.

## TL;DR

- The old engine is a **parent-inheritance + first-occurrence string-substitution**
  machine, **not** a linguistic rules engine. All irregularity — diphthongs,
  orthographic changes, stem accents — lives as **literal forms in `verbs.xml`**,
  one attribute per slot, hand-entered per verb.
- **There is almost no accent/orthographic *logic* to mine.** The only computed
  linguistic rule in the whole file is the imperfect-subjunctive-`nosotros`
  accent. Everything else is data.
- It is **brittle by construction** and **already has bugs**: 4 `-car` verbs are
  misclassified as regular and produce wrong forms (`tocar → *tocé`, not `toqué`).
- It is still useful as (1) a **fallible second-opinion** differential oracle —
  never an authority — and (2) a **curated data** source (forms + a seed for the
  verb→model map). Use the verified `spanish_models.md` + RAE as the real oracle.

## How it works (architecture)

Each verb in `verbs.xml` has a parent (`pe`), a trim substring (`tr`), and a
replacement stem (`st`). `conjugateRecursively` conjugates the parent for the
requested (tense, personNumber), then patches it:

```
conjugation = parentConjugation.replaceFirstOccurence(of: trim, with: stem)
```

Base of the recursion: `hablar` / `comer` / `subir`, whose regular endings are
themselves produced by substitution off stored forms. Any slot that is irregular
is **stored explicitly** in the XML and short-circuits the recursion:

```xml
<verb in="pensar" vt="ir" pe="hablar" tr="habl" st="pens"
      fspr="pIenso" sspr="pIensas" tspr="pIensa" tppr="pIensan"
      fspb="pIense" sspb="pIenses" tspb="pIense" tppb="pIensen" ssio="pIensa" />
<verb in="llegar" vt="ir" pe="hablar" tr="habl" st="lleg"
      fspt="llegUé" fspb="llegUe" sspb="llegUes" tspb="llegUe"
      fppb="llegUemos" sppb="llegUéis" tppb="llegUen" />
```

The **capital letter** inside a form (`pIenso`, `llegUé`, `caCe`) marks the
irregular glyph for display only — `StringExtensions` lowercases it for the
visible string and builds an attributed string that bold/colors that letter;
`ConjugationResult` compares case-insensitively. So `"llegUé"` is `llegué`
everywhere that matters. **Any differential harness must `.lowercased()` the old
engine's output before diffing**, or every irregular form is false noise.

Future/conditional and the imperfect/future subjunctives are the exception: their
endings come from a hardcoded `endingFor(tense:personNumber:)` table appended to a
future-stem (`rf`) or to the `-ron`-stripped preterite. Compound tenses are
`haber` (stored) + participle. `df` in a slot = defective (no such form).

### Slot-key vocabulary (for reading the XML / building the harness)

A stored slot attribute is `PersonNumber.rawValue + Tense.rawValue`.

| PersonNumber | code | Tense (simple/nonfinite) | code |
|---|---|---|---|
| firstSingular | `fs` | presenteDeIndicativo | `pr` |
| secondSingularTú | `ss` | pretérito | `pt` |
| secondSingularVos | `sv` | imperfectoDeIndicativo | `ii` |
| thirdSingular | `ts` | futuroDeIndicativo | `fu` |
| firstPlural | `fp` | condicional | `co` |
| secondPlural | `sp` | presenteDeSubjuntivo | `pb` |
| thirdPlural | `tp` | imperfectoDeSubjuntivo1 (`-ra`) | `i1` |
| none | `no` | imperfectoDeSubjuntivo2 (`-se`) | `i2` |
| | | futuroDeSubjuntivo | `fv` |
| | | gerundio / participio | `ge` / `po` |
| | | imperativo pos. / neg. | `io` / `ni` |
| | | raízFutura (future stem) | `rf` |

So `fspr` = first-singular present indicative, `fspt` = first-singular preterite,
`fspb` = first-singular present subjunctive, `ssio` = tú affirmative imperative.
(There are also 9 compound tenses, `pi pa fi fp cc cp p1 p2 fo`, built
mechanically from `haber` + participle.) Note the old engine also emits `vos`
forms and `futuro de subjuntivo`, which the book/oracle does not cover.

## The only reusable computed rule

Worth lifting verbatim into the new engine (and it's correct):

> **Imperfect-subjunctive `nosotros` accent.** Take the 3rd-plural preterite,
> strip the final `-ron`, accent the last vowel of what remains (`a → á`,
> otherwise `→ é`), then append the ending. Yields `habláramos`, `comiéramos`,
> `dijéramos`, `fuéramos`, `construyéramos`.

(`Conjugator.swift:235-249`.) Everything else an accent/orthographic engine needs
— `c→qu`, `z→c`, `g→gu`, `gu→gü`, the `envío`/`actúo`/`reúno` stress accents,
diphthong raising — is **absent from the code** and must be implemented fresh per
the taxonomy (`docs/spanish_taxonomy.md` §4). This is the structural reason the
old approach caps at 214 verbs: every irregularity is manual data entry.

## Confirmed bugs / brittleness

Correctness depends entirely on a human (1) marking a verb irregular and (2)
typing every changed form correctly. Where that lapses, the engine is silently
wrong. Found in minutes:

- **4 `-car` verbs misclassified as regular** (`vt="ra"`, no overrides):
  **`buscar`, `platicar`, `sacar`, `tocar`**. Each resolves preterite 1s by
  `hablar`'s `hablé` → substitute → **`buscé` / `platiqué`✗→`platicé` / `sacé` /
  `tocé`** (correct: `busqué / platiqué / saqué / toqué`), and the **entire
  present subjunctive** to `busque`→`busce`, etc. The affirmative `nosotros`/`Ud.`
  imperatives (derived from the subjunctive) inherit the error.
  - The curator *did* mark the `-gar` (`llegar`, `pagar`) and `-zar` (`cazar`)
    verbs irregular with correct overrides — so the engine is right there. It
    simply missed every `-car`. That inconsistency is the whole point: there is no
    rule enforcing it.

Implication: treat **every** old-engine form as a hypothesis, not a fact. Its
disagreements with the new (rule-based) engine will cluster predictably at
orthographic-change verbs and anywhere an override was forgotten — and in those
clusters the **new** engine is the correct one.

## Recommendation per goal

**(a) Mine the logic → downgrade.** There is no orthographic/accent algorithm to
port. Copy the one imperfect-subjunctive-`nosotros` accent rule, learn the
slot/tense vocabulary above, then move on. The new engine implements §4 of the
taxonomy from scratch.

**(b) Differential oracle → keep, as a fallible second opinion.** The real oracle
is the verified `spanish_models.md` (exemplar per model) + RAE for everything
else. Harness spec:

1. **Normalize:** `.lowercased()` both sides (strip the styling capitals);
   decide a policy for RAE dual forms (`rió/rio`, `frito/freído`) — treat as
   acceptable variants, not diffs.
2. **Scope:** diff only tenses **both** engines emit **and** the book covers — the
   simple tenses + participle + gerund. Skip `vos`, `futuro de subjuntivo`, and
   the 9 compound tenses (mechanical `haber` + participle; low value).
3. **Triage every diff against the book/RAE**, into:
   (i) new engine wrong → fix the new engine;
   (ii) old engine wrong → leave the new engine, **log it** (a bug in the shipped
   app); expect the `-car`/orthographic cluster here;
   (iii) both defensible → record as an acceptable variant.
4. **Gate vs. report:** the hard CI gate is unit tests asserting
   `new engine == spanish_models.md` for the model exemplars. The 214-verb diff is
   a **non-gating report**, broad coverage to catch verb→model misassignments that
   exemplar tests can't.
5. **Output a findings list** of old-engine bugs (starts with `buscar`,
   `platicar`, `sacar`, `tocar`) for the shipped app, before `migration` folds
   into master.

**Bonus — data reuse.** `verbs.xml`'s `pe=` (parent) attribute is a rough seed for
the new verb→model map (`granizar`, `viralizar` already point at `cazar`). Useful
as a hint, but **verify against the book** — the classifications themselves contain
the errors above (e.g. `buscar` is mislabeled regular). The literal stored forms,
where present, are a good per-form cross-check.
