# Spanish Etymology Generation Pipeline

## Status

Seeded and live. `Conjugar/Models/Etymologies.json` exists (seeded with `estar`),
`Conjugar/Models/Etymology.swift` already reads it, and the work-list
(`prompts/etymology-verbs.json`, the 988 usage-ranked verbs) is in place. **There is no
stored "next verb"** — resume by diffing the work-list against the keys already in
`Etymologies.json` (Step 1 / Step 7 do this automatically). To see where things stand, run
the Step 7 one-liner. Just start at **Step 1** each session; Step 0 (seeding) is already
complete.

> **Remaining lifecycle step (not this pipeline's job):** `Etymology.swift` loads the JSON
> but nothing displays it yet. Rendering it under the conjugations in `VerbView` — a
> `~…~`→bold attributed-string renderer plus an etymology card — is a separate UI task. This
> pipeline only *populates the data*.

## Goal

Populate `Conjugar/Models/Etymologies.json` with an etymology for every verb in the
work-list (`prompts/etymology-verbs.json` — the 988 most-used verbs — plus the select verbs
below), in **both English and Spanish**. The app reads this file via `Etymology.swift`.

This pipeline **generates** etymologies from research. (Konjugieren's analogous pipeline
only *translated* pre-existing English text; ours must research and write from scratch, then
render a parallel Spanish version.) Run it repeatedly across sessions, a batch at a time,
until the work-list is exhausted.

## Output shape

`Conjugar/Models/Etymologies.json` is keyed **language → infinitive → text**, exactly as
`Etymology.swift` expects:

```json
{
  "en": { "estar": "From Latin ~stāre~ …", "...": "..." },
  "es": { "estar": "Del latín ~stāre~ …", "...": "..." }
}
```

Each verb appears under both `"en"` and `"es"`. Keys are sorted alphabetically.

### Both languages are required

Every verb **must** have both an English (`"en"`) and a Spanish (`"es"`) entry — Spanish is
never optional. English is also the fallback: `Etymology.text(for:)` returns the `"en"`
text when the device language has no table, so a missing English entry would leave some
users with nothing. A batch is not complete until both tables contain every verb in it; the
Step 4 validator rejects any verb missing either language. The Spanish entry narrates in the
pretérito indefinido and uses guillemets (see below).

## The work-list

`prompts/etymology-verbs.json` (in this `prompts/` folder) is the source of truth for
*which* verbs to cover and in what order:

```json
{ "count": 988,
  "verbs": [ { "rank": 1, "infinitive": "ser", "gloss": "be" }, … ] }
```

`gloss` is the verb's terse English translation (the `tn` attribute from
`Conjugar/Models/verbModelMap.xml`), handed to subagents as disambiguating context. Process
verbs in ascending `rank` order so the most useful verbs get etymologies first. The ranks
come from `docs/SpanishVerbFrequencyRanks.txt` (the top-1000 by usage); a handful of ranks
are absent from the 1..1000 sequence, so the work-list has 988 entries, not 1000.

### Select verbs (beyond the ranked 988)

A handful of rare-but-interesting verbs are covered even though they fall outside the
top-1000. They are unranked in `verbModelMap.xml` (`fr` absent), so they are **not** in the
work-list and must be named explicitly. Add more here as desired.

```
yacer     — lie (at rest); defective/archaic — "aquí yace" ("here lies") on tombstones
abolir    — abolish; historically a defective verb (only endings beginning in -i-)
placer    — please; archaic strong preterite "plugo" / "pluguieron"
asir      — grasp; the -g- present ("asgo") is largely avoided in practice
balbucir  — stammer; defective, propped up by the regular -ear verb "balbucear"
atañer    — concern; defective, used almost only in the third person ("me atañe")
```

For each select verb, look up its gloss once if you need it:
`python3 -c "import xml.etree.ElementTree as ET; print([v.get('tn') for v in ET.parse('Conjugar/Models/verbModelMap.xml').getroot().iter('verb') if v.get('in')=='yacer'])"`

The **target set** for the pipeline is the 988 ranked verbs ∪ the select verbs.

### Verbs with two senses (homonyms)

A few verbs carry two `<verb>` rows in `verbModelMap.xml` — one per sense/model — most
notably `apostar` (*bet* / *station, post*; the work-list joins the two in `gloss` as
`"bet; station"`). Etymology is a property of the **word**, not the conjugation model, so
each such verb gets **one** entry keyed on its infinitive. When the two senses share an
origin, write a single etymology accounting for **both**; when they are true unrelated
homonyms with distinct origins (as `apostar` is), say so and give both.

---

## Per-session procedure

> **Working directory:** run all the Python/bash snippets below from the **repo root**
> (`/Users/josh/Desktop/workspace/Conjugar.mig`). That is why paths are repo-root-relative:
> the work-list is `prompts/etymology-verbs.json` (it lives beside this file) and the output
> is `Conjugar/Models/Etymologies.json`.

### Step 0 (first session only): seed `Etymologies.json` — ✅ DONE

Already complete: `Conjugar/Models/Etymologies.json` was seeded with the `estar` entry and
the file is live. Skip this step; begin at Step 1. (Kept for the record: seeding wrote
`{"en": {"estar": …}, "es": {"estar": …}}` via `json.dumps`, so the pipeline could
accumulate into it.)

### Step 1: select the next batch

Compute the next BATCH of verbs = the smallest-numbered ranks (rank 1 = most-used first)
not yet in `Etymologies.json`.
Recommended batch: **5 subagents × ~8 verbs = ~40 per session** (generation + web research
is heavier than translation, so keep batches modest to avoid context compaction mid-run).

```python
python3 << 'ENDPY'
import json, pathlib
BATCH = 40
worklist = json.loads(pathlib.Path('prompts/etymology-verbs.json').read_text())['verbs']
select = [  # rare-but-wanted verbs outside the top-1000; rank 10_000+ just sorts them last
    {"rank": 10_000, "infinitive": "yacer",    "gloss": "lie (at rest)"},
    {"rank": 10_001, "infinitive": "abolir",   "gloss": "abolish"},
    {"rank": 10_002, "infinitive": "placer",   "gloss": "please"},
    {"rank": 10_003, "infinitive": "asir",     "gloss": "grasp"},
    {"rank": 10_004, "infinitive": "balbucir", "gloss": "stammer"},
    {"rank": 10_005, "infinitive": "atañer",   "gloss": "concern"},
]
targets = worklist + select
done = set(json.loads(pathlib.Path('Conjugar/Models/Etymologies.json').read_text())['en'])
todo = [v for v in targets if v['infinitive'] not in done][:BATCH]
print(f"{len([v for v in targets if v['infinitive'] not in done])} remaining; next {len(todo)}:")
for v in todo:
    print(f"  {v['rank']:>5}  {v['infinitive']:<16} {v['gloss']}")
# Split into ~8-verb groups for subagents and stash as JSON for the prompts:
groups = [todo[i:i+8] for i in range(0, len(todo), 8)]
pathlib.Path('/tmp/etym_batch.json').write_text(json.dumps(groups, ensure_ascii=False))
print(f"{len(groups)} groups -> /tmp/etym_batch.json")
ENDPY
```

### Step 2: launch parallel subagents

Launch one `general-purpose` subagent per group **in a single message** (parallel Agent
tool calls). Give each the self-contained prompt in the next section, substituting its
group's verbs (infinitive + gloss). Do **not** write etymologies yourself — delegate all of
them.

**For the group that contains `ser` (rank 1) and/or `haber` (rank 2):** also paste the
**"Deep-dive verbs: ser and haber"** section below into that subagent's prompt (after "Your
verbs"). Those two verbs get a fuller, three-paragraph treatment matching the sibling app's
`être`/`avoir` entries, and most of the reference text lifts whole-cloth.

### Step 3: extract results from subagent transcripts

Subagents return a JSON object as their final text. Read it from the persisted JSONL
transcripts (survives context compaction), not from the live tool result. The agent id
alone locates the transcript — no session id needed. Each Agent tool result prints its
`agentId`; `find` resolves the path under whatever session dir is current (there are
several, so don't hard-code one):

```python
python3 << 'ENDPY'
import json, pathlib, subprocess
# (agent_id, output) — one per subagent; agent ids come from this run's Agent results.
agents = [("AGENT_ID_1", "/tmp/etym_g1.json"),
          ("AGENT_ID_2", "/tmp/etym_g2.json")]
for aid, out in agents:
    hit = subprocess.run(
        ["find", str(pathlib.Path.home() / ".claude"), "-path", "*subagents*",
         "-name", f"agent-{aid}.jsonl"],
        capture_output=True, text=True).stdout.splitlines()
    assert hit, f"transcript not found for {aid}"
    text = ""
    for line in pathlib.Path(hit[0]).read_text().splitlines():
        try: obj = json.loads(line)
        except: continue
        if obj.get("type") != "assistant": continue
        for b in obj.get("message", {}).get("content", []):
            if b.get("type") == "text": text = b["text"]
    text = text[text.find("{"):]      # drop any preamble before the JSON
    data = json.loads(text, strict=False)   # strict=False: agents often use raw newlines in values
    pathlib.Path(out).write_text(json.dumps(data, ensure_ascii=False))
    print(f"{aid}: {len(data)} verbs -> {out}")
ENDPY
```

Substitute the agent ids from this run's Agent results.

**If `json.loads` raises `Extra data`,** the subagent emitted more than one top-level JSON
object in its final message (seen in practice: an agent that wrote an `en`-only block, then
a separate `es`-only block, then a combined object). The single-object slice above grabs the
first one. Recover by scanning **all** top-level objects with `raw_decode` and keeping the
entries that carry both `en` and `es`:

```python
python3 << 'ENDPY'
import json
dec = json.JSONDecoder()
objs, i = [], 0
while i < len(text):
    if text[i] == "{":
        try:
            o, end = dec.raw_decode(text, i); objs.append(o); i = end; continue
        except json.JSONDecodeError:
            pass
    i += 1
merged = {}
for o in objs:
    for verb, langs in o.items():
        if isinstance(langs, dict) and "en" in langs and "es" in langs:
            merged[verb] = langs          # complete pair wins
        elif verb not in merged:
            merged.setdefault(verb, {}).update(langs)
data = {v: l for v, l in merged.items() if "en" in l and "es" in l}
ENDPY
```

### Step 4: validate markup before merging

For every `(verb, lang)` value, check:

```python
python3 << 'ENDPY'
import json, glob, re
emph = re.compile(r'\*(?!~)[^*~\n]+?\*')   # *word* emphasis (NOT the *~root~ reconstruction)
problems = []
for f in glob.glob('/tmp/etym_g*.json'):
    for verb, langs in json.load(open(f)).items():
        for lang in ("en", "es"):
            t = langs.get(lang, "")
            if not t:                        problems.append((verb, lang, "MISSING"))
            if t.count("~") % 2:            problems.append((verb, lang, "odd ~ count"))
            if "~~" in t:                    problems.append((verb, lang, "~~ double tilde"))
            if '"' in t:                     problems.append((verb, lang, 'ASCII \" in prose'))
            if "\\n" in t:                   problems.append((verb, lang, "literal backslash-n"))
            if "\n\n" not in t:              problems.append((verb, lang, "no paragraph break"))
            if "~*" in t:                    problems.append((verb, lang, "~* misplaced recon asterisk (want *~)"))
            if emph.search(t):               problems.append((verb, lang, "*word* emphasis (use ~bold~ or plain)"))
        # en/es should bold the same forms -> tilde counts should match
        if langs.get("en","").count("~") != langs.get("es","").count("~"):
            problems.append((verb, "en/es", "tilde count mismatch"))
print("OK" if not problems else f"{len(problems)} issues:")
for p in problems: print("  ", p)
ENDPY
```

Fix issues (usually a stray tilde or an ASCII `"` that should be `“ ”`/`« »`) before
merging. A tilde-count mismatch between `en` and `es` means one language bolded a form the
other didn't — reconcile them.

### Step 5: merge into `Etymologies.json`

Never hand-write JSON or put etymology text in a shell heredoc/inline dict — always go
through `json.dumps`/`json.loads`:

```python
python3 << 'ENDPY'
import json, glob, pathlib
p = pathlib.Path('Conjugar/Models/Etymologies.json')
data = json.loads(p.read_text())
n = 0
for f in glob.glob('/tmp/etym_g*.json'):
    for verb, langs in json.load(open(f)).items():
        data["en"][verb] = langs["en"]
        data["es"][verb] = langs["es"]
        n += 1
for lang in data: data[lang] = dict(sorted(data[lang].items()))
data = dict(sorted(data.items()))
p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"merged {n}; totals en={len(data['en'])} es={len(data['es'])}")
ENDPY
```

### Step 6: validate JSON & summarize

```bash
python3 -c "import json; d=json.load(open('Conjugar/Models/Etymologies.json')); print('Valid.', len(d['en']),'en /',len(d['es']),'es')"
```

Print a short table: verb | first 60 chars of the English etymology | en/es tilde match.

### Step 7: report progress

```python
python3 -c "
import json, pathlib
wl = json.loads(pathlib.Path('prompts/etymology-verbs.json').read_text())['verbs']
done = set(json.loads(pathlib.Path('Conjugar/Models/Etymologies.json').read_text())['en'])
todo = [v for v in wl if v['infinitive'] not in done]
print(f'Done {len(wl)-len(todo)}/{len(wl)} ranked verbs.',
      f'Next: {todo[0][\"infinitive\"]} (rank {todo[0][\"rank\"]})' if todo else 'ALL RANKED VERBS DONE.')"
```

When the ranked 988 (and any select verbs) are all present in both tables, the pipeline is
complete and the `VerbView` wiring step can proceed.

---

## Deep-dive verbs: ser and haber

`ser` (rank 1) and `haber` (rank 2) are the two most-used verbs in the language and deserve
the same depth as the sibling French app Conjuguer gives its `être` and `avoir` — a fuller,
**three-paragraph** treatment with comparative philology and a genuine payoff, not the
standard two paragraphs. Because `ser`/`haber` and `être`/`avoir` share their Latin origins,
**most of the reference text below lifts whole-cloth** — reuse it, adjusting the specifics
noted. Paste this entire section into the subagent handling these verbs (in addition to the
normal template), and have it produce both `en` and `es` at this depth. Verify the
Spanish-specific claims against es.Wiktionary / DLE / Corominas / Penny's *A History of the
Spanish Language* before asserting them; hedge anything the sources hedge.

### haber — lifts almost entirely from `avoir`

`haber` and French `avoir` both descend from Latin ~habēre~, so the reference entry transfers
nearly verbatim: the ~habēre~ → *~habēō~ → PIE *~gʰh₁bʰ-~ chain (keep the "generally traced"
hedge — this root is debated), the Romance-sibling set, the **"English ~have~ is not a
cognate"** false-friend point, the derived family (~hábito~, ~habitar~, ~exhibir~,
~prohibir~, and via ~dēbēre~ = ~dē-~ + ~habēre~ the verb ~deber~), and the whole third
paragraph on German ~haben~ (from a *different* root PIE *~keh₂p-~ "to grasp" → Latin
~capiō~), the false cognation, and the Western-European ~Sprachbund~ that made two unrelated
"have" verbs into twin auxiliaries.

Reference text to adapt (Conjuguer's `avoir`, English):

> From Old French ~avoir~ (also ~aveir~), from Latin ~habēre~ (“to have, hold, possess”),
> from Proto-Italic *~habēō~, generally traced to Proto-Indo-European *~gʰh₁bʰ-~ (“to grab,
> to take, to hold”). Its Romance siblings are everywhere everyday verbs: Italian ~avere~,
> Spanish ~haber~, Portuguese ~haver~, Romanian ~avea~. Tempting as it looks, English ~have~
> is not in fact a cognate — the resemblance is a coincidence, that verb belonging to a
> separate Germanic family.
>
> [middle paragraph: ~habēre~ "to hold" → "to possess" → auxiliary; the derived family
> ~hábito~/~habitar~/~exhibir~/~prohibir~/~deber~ (via ~dēbēre~).]
>
> [third paragraph: German ~haben~ became a compound-past auxiliary too, yet ~haben~ and
> ~haber~ are not cognates — ~haben~ is from PIE *~keh₂p-~ ("to grasp", source of Latin
> ~capiō~ and so of ~captar~, ~cautivo~, ~aceptar~), while ~haber~ is from *~gʰh₁bʰ-~. Two
> unrelated "have" verbs pressed into the same grammatical service — a hallmark of the
> Western European ~Sprachbund~.]

**Spanish-specific changes to make** (this is `haber`'s memorable payoff, and it *differs*
from French):

- **Spanish demoted ~haber~ from possession to a near-pure auxiliary.** Where French/Italian
  kept ~avoir~/~avere~ as the ordinary verb of possession, Spanish handed that job to ~tener~
  (from Latin ~tenēre~, “to hold”) and left ~haber~ with two roles: the auxiliary of the
  compound tenses (~he cantado~ = “I have sung”) and the impersonal existential ~hay~ /
  ~había~ / ~habrá~ (“there is / there are”). The old possessive sense survives only
  fossilized — the noun ~haber~ / ~haberes~ (“assets, wages”) and set phrases like
  ~habérselas con~.
- **~hay~ is worth its own sentence.** It is medieval ~ha~ + the locative clitic ~y~ (from
  Latin ~ibī~, “there”), exactly parallel to French ~il y a~ and Catalan ~hi ha~ — “it has
  there” → “there is.”
- **Handle the ~Sprachbund~ point carefully for Spanish.** Old Spanish *did* share the
  European ~ser~/~haber~ auxiliary split (unaccusatives took ~ser~: ~es nacido~, ~so
  venido~), so recast the twin-auxiliary parallel as Spanish ~he comido~ / German ~ich habe
  gegessen~. But note the twist: Spanish later **leveled** the split, generalizing ~haber~
  to all compound tenses (~ha muerto~, not older ~es muerto~) — so modern Spanish, unlike
  French and German, no longer keeps the ~ser~/~haber~ auxiliary division it once had. That
  innovation is a sharper ending than French's, since this app *is* Spanish.

### ser — lifts the framing from `être`, but the donor verbs differ

`ser` is, like `être`, famously **suppletive** — its paradigm is stitched from more than one
Latin verb — so `être`'s framing transfers: the descent of the "be" forms from Latin ~esse~
back to PIE *~h₁es-~, the cognate set (Italian ~essere~, French ~être~, English ~is~ and
~am~, German ~ist~), and the "several of its commonest forms descend not from ~esse~ at all"
hook. **But the donor verbs are Spanish-specific — do not copy `être`'s ~stāre~ story.**

Reference framing to adapt (Conjuguer's `être`, English, opening):

> …~être~ is famously suppletive: its paradigm is stitched together from more than one Latin
> verb, and several of its commonest forms descend not from ~esse~ at all… The verb ~esse~
> was already defective in Latin, lacking many forms, so speakers borrowed pieces from
> [another verb] to fill the gaps.

**Spanish suppletion — the three donors to describe** (Spanish `ser` draws on three Latin
sources, not `être`'s ~esse~ + ~stāre~):

- **~esse~ (“to be”), PIE *~h₁es-~** — supplies the present (~soy~, ~eres~, ~es~, ~somos~,
  ~sois~, ~son~) and the imperfect (~era~, ~eras~… from Latin ~eram~). A nice detail: ~eres~
  descends from the Latin *future* ~eris~ (“you will be”), pressed into service as a present
  to keep it distinct from ~es~.
- **~sedēre~ (“to sit”), from *~sed-~** — supplies the **infinitive ~ser~ itself** (via Old
  Spanish ~seer~), plus the future/conditional (~seré~, ~sería~), the present subjunctive
  (~sea~), and the imperative (~sé~). So the very name of the verb is, etymologically, “to
  sit.” (This is `ser`'s counterpart to `être` borrowing from ~stāre~ “to stand” — Spanish
  sat where French stood.)
- **~fuī~ (Latin perfect of ~esse~), PIE *~bʰuH-~ (“to become, grow”)** — supplies the
  preterite (~fui~, ~fuiste~, ~fue~…). The memorable payoff: this preterite is **shared
  identically with ~ir~ (“to go”)** — ~fui~ means both “I was” and “I went,” context alone
  deciding — because ~ir~ borrowed the same ~fuī~ forms. Two of Spanish's commonest verbs
  literally share a past tense.

Build `ser`'s three paragraphs around: (1) the ~esse~ / *~h₁es-~ descent + cognate set,
(2) the suppletion — the three donors above, with the ~ser~-from-~sedēre~ and the
~fui~-shared-with-~ir~ details as the vivid turns, (3) the same-root family (~ente~,
~esencia~, ~presente~, ~ausente~, ~interés~; and from ~sedēre~: ~sede~, ~sentar~, ~sesión~,
~residir~). Keep en/es tilde-parallel throughout, as always.

---

## Subagent prompt template

Give each subagent the prompt below, substituting **YOUR VERBS** with its group (each verb
as `infinitive — gloss`). The prompt is fully self-contained; the subagent cannot see this
file.

> You are a careful etymologist writing short, engaging verb etymologies for a Spanish-verb
> learning app. You will be given several Spanish verbs. For each, produce an etymology in
> **two languages, English and Spanish**, conveying the same content. Do NOT write any
> files. Return ONLY the JSON object described at the end.
>
> ## Your verbs
>
> YOUR VERBS  *(e.g. `hablar — speak`, one per line)*
>
> ## Research
>
> Base each etymology on reliable sources. Use the two Wiktionaries for different things —
> they are organized differently and each is richer on a different axis:
> - **es.Wiktionary (es.wiktionary.org)** and the **DLE / Diccionario de la lengua española
>   (dle.rae.es)** are the better *primary* sources for the **Spanish-specific** descent
>   (the Latin etymon, the Castilian sound-changes, first attestations) and for register /
>   dispute notes. For the deeper history, **Corominas** (*Breve diccionario etimológico de
>   la lengua castellana*) is the standard authority — cite what it supports.
> - **en.Wiktionary (en.wiktionary.org)** is usually richer for the **deep etymological
>   chain** — the Proto-Indo-European / Proto-Italic reconstructions and the cross-language
>   cognate sets — because it maintains dedicated reconstruction pages and per-etymon entries
>   and links them aggressively.
>
> So: take the Spanish chain, register, and dispute notes from es.Wiktionary / DLE /
> Corominas; cross-reference en.Wiktionary's etymon/reconstruction pages for the PIE root and
> the cognates. Use web search to verify the chain of descent and the reconstructed roots
> whenever you are not certain. **Write original prose** — do not copy source text.
> **Accuracy outranks completeness:** if a detail is genuinely uncertain, omit it rather than
> guess. Never invent a root or a cognate.
>
> ## Disputed origins — mark them, don't launder them
>
> When the origin of a verb (or of one vivid detail) is **disputed or merely proposed** in
> the sources, you have two acceptable choices: omit it, **or present it explicitly as
> disputed** — *never assert one contested hypothesis as settled fact.* The single most
> engaging, quotable detail of an entry is disproportionately the disputed one, and the
> temptation is to narrate it confidently; resist that. Concretely:
>
> - If the sources hedge (`quizá`, `probablemente`, `acaso`, `se ha propuesto`, `de origen
>   incierto`, two competing accounts), **carry the hedge into your prose**: write “by one
>   account…”, “the origin is debated; the favored account is…”, “Corominas rejects the idea
>   that…” / « según una hipótesis… », « de origen discutido ».
> - **Do not invent a literal concretization** of a figurative or uncertain development and
>   present it as the explanation.
> - **Do not assert a descent step the sources don't support.** If the primary source gives a
>   simple origin and a fuller blend appears only elsewhere, say so (“traditionally also
>   explained as…”) rather than presenting the blend as the plain chain.
> - **Do not build a flourish on an unproven premise.** A memorable closing line is welcome —
>   but only on facts that are actually settled.
>
> Marking disputes keeps the engaging detail (which is the point of the entry) while removing
> the only real accuracy risk. When you hedge, hedge **identically in both languages** so
> en/es stay parallel.
>
> ## What to write (per verb)
>
> Two paragraphs, ~120–220 words each:
>
> 1. **Descent.** The chain from the modern Spanish verb back through Old Spanish /
>    Vulgar Latin to Latin (or Arabic, Germanic, Greek, etc.) and, where well established,
>    the Proto-Indo-European root — plus a notable cognate or two in other languages
>    (Italian, French, Portuguese, English, German…).
> 2. **Development.** How the meaning evolved, a memorable or surprising detail, and a few
>    modern Spanish words descended from the same root. **If the memorable detail rests on a
>    disputed or proposed origin, mark it as such** (see “Disputed origins” above) — don't
>    state it as settled fact.
>
> Tone: educational, precise, engaging. Same content and level of detail in both languages.
>
> ## Markup (identical rules for both languages)
>
> - **Bold** every cited word-form, ancestral form, cognate, affix, and root by wrapping it
>   in a **single tilde on each side**: `~estar~`, `~stāre~`, `~re-~`. Bold **nothing
>   else** — not ordinary prose.
> - **Never** use double tildes (`~~word~~`). The count of `~` in each value must be
>   **even** (every opener has a closer).
> - **Bold the same set of forms in the English and Spanish versions**, so the two have the
>   same number of tildes.
> - **A bolded cognate must be introduced as a cognate in BOTH languages** — e.g. English
>   `~stand~` / el inglés `~stand~`. **Never bold an English word that appears only as an
>   inline aside in the English prose**: the Spanish version has no parallel for it, so the
>   tilde counts diverge. Either present it symmetrically as a named cognate in both
>   languages, or leave it un-bolded in both.
> - **When you cite the headword verb inside an example phrase**, bold it in **both**
>   languages or **neither** — don't bold the bare verb in one language while glossing it in
>   quotes in the other.
> - **Reconstructed (unattested) forms** take a literal asterisk *before* the bold:
>   `*~steh₂-~`, `*~bʰuH-~`. Keep the asterisk **outside** the tildes. **Never write
>   `~*steh₂-~`** (asterisk inside the bold) — it renders the `*` bolded, glued into the
>   word. The asterisk and the opening tilde always go in the order `*~`, never `~*`.
> - **The asterisk is reserved for reconstructions only — never use `*word*` for emphasis.**
>   This renderer treats `~` as the *only* bold marker and passes every `*` through
>   literally (it has to, for `*~steh₂-~`). So a markdown-style `*inhabit*` shows up in the
>   app as literal asterisks around the word. To stress a word, either bold it with tildes
>   (counting it on both sides) or just leave it plain — do not wrap it in `*`.
> - **Subscripts/superscripts** in roots are written with real Unicode characters, never
>   markup: subscripts `₀₁₂₃` (e.g. `*~h₂epo~`), superscript modifier letters `ʰ ʷ ʲ`
>   (e.g. `*~bʰuH-~`).
> - **Before returning, count the `~` characters in each verb's `en` string and in its `es`
>   string — they MUST be equal.** If they differ, you bolded a form in one language that you
>   didn't bold in the other; find it and fix it. This en/es tilde mismatch is the single most
>   common error, so do this check for every verb before you output the JSON.
>
> ## Quotation marks (keep JSON safe)
>
> - **English:** use curly quotes for glosses — `“to stand”`, not ASCII `"`.
> - **Spanish:** use guillemets (comillas angulares) — `« estar de pie »`.
> - **Never put an ASCII straight double-quote `"` anywhere in the prose.** It must appear
>   only as a JSON string delimiter. (Apostrophes inside words are fine.)
>
> ## Spanish register
>
> Narrate historical development in the **pretérito indefinido** (simple past — `fue`,
> `absorbió`, `pasó a`, `dio`, `se convirtió en`), not the pretérito perfecto compuesto
> (never `ha sido`, `ha absorbido`, `se ha convertido`). Use natural, idiomatic Spanish
> throughout. Prefer peninsular-neutral usage; where a form differs across regions, note it
> rather than pick one silently.
>
> ## Paragraph break
>
> Separate the two paragraphs with one blank line (a real line break in the string).
>
> ## Worked example (the verb `estar`)
>
> `{"estar": {`
> `"en": "From Latin ~stāre~ (“to stand”), from Proto-Italic *~stāō~, from Proto-Indo-European *~steh₂-~ (“to stand”). Cognate with Italian ~stare~ and Portuguese ~estar~, and — through the same root — with English ~stand~ and ~stay~ and French ~ester~, an Old French verb now surviving only as a legal term.\n\nSpanish inherited two verbs from Latin's copula system and split the work of “to be” between them: ~ser~ (from ~esse~, reinforced by ~sedēre~, “to sit”) carries permanent, essential being, while ~estar~ (from ~stāre~, “to stand”) carries location, state, and condition — literally, how something “stands” at a given moment. That is why someone ~es~ tall but ~está~ tired. The past participle ~estado~ (“been; state”) gave the noun ~estado~ (“state, condition,” and by extension the political “State”). The same PIE root *~steh₂-~ seeded a vast family of Spanish words, among them ~estación~, ~estable~, ~estatua~, ~constante~, ~restar~, and ~estatuto~.",`
> `"es": "Del latín ~stāre~ (« estar de pie, permanecer »), del itálico común *~stāō~, del protoindoeuropeo *~steh₂-~ (« estar de pie »). Emparentado con el italiano ~stare~ y el portugués ~estar~, y —por la misma raíz— con el inglés ~stand~ y ~stay~ y el francés ~ester~, verbo del francés antiguo que hoy solo pervive como término jurídico.\n\nEl español heredó dos verbos del sistema copulativo latino y repartió entre ellos la función de « ser »: ~ser~ (de ~esse~, reforzado por ~sedēre~, « estar sentado ») expresa el ser permanente y esencial, mientras que ~estar~ (de ~stāre~, « estar de pie ») expresa la ubicación, el estado y la condición —literalmente, cómo « se sostiene » algo en un momento dado. Por eso alguien ~es~ alto pero ~está~ cansado. El participio ~estado~ (« sido; estado ») dio el sustantivo ~estado~ (« estado, condición », y por extensión el « Estado » político). La misma raíz indoeuropea *~steh₂-~ originó una amplia familia de palabras españolas, entre ellas ~estación~, ~estable~, ~estatua~, ~constante~, ~restar~ y ~estatuto~."`
> `}}`
>
> ## Output format
>
> Return ONLY a JSON object, no markdown fencing, no commentary before or after:
>
> `{"verb1": {"en": "…", "es": "…"}, "verb2": {"en": "…", "es": "…"}, …}`
>
> Use real line breaks inside the strings for paragraph breaks (your JSON encoder will escape
> them as `\n`). Write `á é í ó ú ñ ¿ ¡ « » “ ”` and all accented letters as literal
> characters — they are JSON-safe; do not `\u`-escape them.

**End subagent prompt.**

---

## JSON munging advice

1. **Never** put etymology text in a shell heredoc or an inline Python dict — pass it only
   through `json.dumps`/`json.loads`. Build intermediate files with
   `pathlib.Path(...).write_text(json.dumps(data, ensure_ascii=False))`.
2. **Extract from the subagent JSONL transcripts on disk** (Step 3), not from the live tool
   result — transcripts survive context compaction, and the answer lives in the last
   `message.content[*].text` of a `type:"assistant"` line.
3. The curly-quote / guillemet rule means the **only** ASCII `"` in a subagent's output are
   its JSON delimiters, so `json.loads` cannot be tripped by a quote inside the prose. The
   Step 4 validator flags any stray ASCII `"` that slipped through.
4. **Validate JSON after every write** (Step 6).

## Lessons (carried from the French/German pipelines + Spanish-specific)

> **This section is a living log — keep it current.** If a run hits friction (a
> subagent-output shape the Step 3/4 extractors didn't anticipate, a recurring markup slip, a
> research pitfall specific to some verb family, a Spanish-register trap, a batch size that
> caused compaction, anything that cost you time), **add the lesson here before you finish
> the session** — a short bold-led bullet in the same style, and if it's mechanically
> checkable, a matching check in the Step 4 validator. The point is that the next session
> starts from your hard-won knowledge, not from scratch.

- **Subagents may emit real literal newlines inside their JSON string values** (the "use
  real line breaks for paragraph breaks" instruction invites exactly this). Strict JSON
  forbids raw control characters in strings, so the Step 3 extractor's `json.loads(text)`
  dies with `Invalid control character at: …`. **Fix: parse with `json.loads(text,
  strict=False)`** — it accepts the raw newlines, and the re-serialization to
  `/tmp/etym_g*.json` normalizes them back to `\n`. Seen in batch 1 (ranks 1–51): 2 of 5
  agents did this. Cheap to handle; just use `strict=False` in Step 3 by default.
- **A subagent may silently omit the second language entirely.** Seen in practice: an agent
  wrote ten polished `"en"` etymologies and emitted *no* `"es"` key at all, despite the
  prompt demanding both languages and shipping a bilingual worked example. The Step 4
  validator's `MISSING` check catches this, and the en/es tilde-mismatch check flags it a
  second way. **Do not hand-write the missing Spanish** — re-dispatch a fresh subagent for
  that whole group with an explicit, up-front warning that *both* `en` and `es` are required
  for every verb and that an English-only return will be rejected. Re-running the group is
  cheap; the failure is all-or-nothing per agent, not per verb.
- **Tildes get dropped or added when subagents restructure a sentence.** The Step 4
  even-count and en/es-match checks catch most of this. Common slip: bolding an English
  cognate that appears in un-tilded prose, or losing a tilde around a small word. When an
  English-only inline aside reuses a cognate the Spanish doesn't, un-bold the aside in `en`
  (a mechanical markup fix) — don't add a phantom bold to `es`. **Subagents' own "I counted
  N tildes each side" claims are unreliable** — trust the Step 4 validator, not the agent's
  self-report.
- **`*~root~`, not `~*root~`.** The reconstruction asterisk goes *outside* the tildes, or the
  asterisk renders inside the bold run.
- **Use real Unicode sub/superscripts.** `*~h₂epo~` and `*~bʰuH-~` already carry their
  glyphs; the renderer does no sub/superscript markup.
- **Pretérito indefinido, not perfecto compuesto** — the Spanish-register slip to watch;
  re-read each Spanish entry for stray `ha + participio` forms.
- **Arabisms are a Spanish-specific richness — and a Spanish-specific accuracy trap.** Many
  common Spanish words are from Arabic, but relatively few *verbs* are; do not reach for an
  Arabic origin unless the sources give one. When they do (e.g. words in `al-`), cite it.
- **Keep en and es parallel.** Same facts, same bolded forms, same paragraph structure. If
  one language earns a detail the other can't support, drop it from both.
- **The confident narrative voice launders disputed etymologies into fact.** The single real
  accuracy risk is over-confident framing of genuinely *disputed* origins — it clusters on
  the vivid "memorable detail," which is disproportionately the contested one. The fix is the
  **"Disputed origins" section** in the subagent prompt: mark disputes as disputes rather
  than omitting or asserting them.
- **"Next" means the smallest remaining rank number (rank 1 first), not the verb after the
  last batch** — earlier batches can leave gaps. Step 1/Step 7 always diff the work-list
  against `Etymologies.json`.
- **3–5 subagents × ~8 verbs.** Bigger batches risk compaction mid-run. If compaction
  happens, the agent transcripts persist on disk and Step 3 recovers the results.
  **Batch 4 pushed this to 10 × 10 = 100 verbs** (split across two parallel-launch messages
  of five agents each) with zero compaction and zero lost transcripts, so the 3–5 guidance is
  conservative — a full 100 is safe when you split the launch into 2–3 messages.
- **Paste REAL curly quotes / guillemets into the worked example, not ASCII.** In batch 4,
  3 of 10 agents (30 English entries) emitted straight `"…"` glosses instead of curly `“…”`
  — because the worked-example block *in the Agent-tool prompt string* had its quotes
  flattened to ASCII when composed (this pipeline file's example is correct; the flattening
  happened at paste time). Agents mirror whatever they literally see in the example. The
  Step 4 `ASCII " in prose` check caught all 30; the mechanical fix is a paired-quote
  substitution on the `/tmp/etym_g*.json` files before merging:
  `re.sub(r'"([^"]*)"', lambda m: "“"+m.group(1)+"”", t)` for `en`, guillemets for `es`.
  Cheaper still: verify the example's quotes are curly `“ ”` / `« »` before launching.
- **Make `strict=False` the DEFAULT in the Step 3 scan-all-objects extractor, not a
  fallback.** `json.JSONDecoder()` (the `Extra data` recovery snippet) defaults to *strict*
  mode, which rejects the real literal newlines agents routinely emit — in batch 4 that
  silently produced "0 verbs" for 4 of 10 agents until re-run with
  `json.JSONDecoder(strict=False)`. Construct the decoder as `json.JSONDecoder(strict=False)`
  up front so every agent parses on the first pass regardless of newline style.

## Reminders

- Launch all subagents for a batch in a **single message** (parallel Agent calls). If the
  runtime caps tool calls per message, split into 2–3 messages.
- Each subagent prompt must be fully self-contained — paste all rules and the worked example
  into every one.
- Do not write etymologies yourself; delegate all to subagents.
- Validate markup (Step 4) and JSON (Step 6) before considering a batch done.
- **Hit friction? Feed it back.** Before ending the session, record any new lesson in the
  **Lessons** section above (and add a Step 4 check if it's mechanically detectable) so the
  pipeline improves each run.
