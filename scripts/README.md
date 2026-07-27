# scripts

## `sync_verb_history.py` — the verb-history essay, edited as prose

Pushes [`docs/verb_history.txt`](../docs/verb_history.txt) into `Localizable.xcstrings` as
`Info.verbHistoryText` (`en`). The essay is ~5,500 words on a single JSON line in the
catalog, which makes it miserable to edit in place and easy to corrupt — an ASCII quote
written unescaped breaks the file. The `docs/` copy is the editing surface; the catalog is
what ships.

```bash
python3 scripts/sync_verb_history.py            # validate, then write
python3 scripts/sync_verb_history.py --check    # validate only
```

The article body is everything after the dashed separator line in the source file; the
header above it is instructions and is never shipped.

### What it validates

`RichText.swift`'s parser fails *silently* on bad markup — nothing crashes, no assertion
fires, and the marker counts still balance — so the checks matter:

| Check | Why |
|-------|-----|
| markers balance | an unterminated `~`/`%`/`$`/`^` swallows the rest of the block |
| markers do not **nest** | a `$…$` inside a `~…~` clobbers the shared `markupStart`, so the emphasis run is emitted from the conjugation's index: text duplicated, literal `$` leaked. Close and reopen instead — `~Adonde~ $FUeres$~, haz lo que vieres~` |
| every non-URL `%…%` names a real article | headings come from `Info.swift` (Spanish tense literals) plus the catalog (localized About headings); a miss makes the tap a no-op |
| no lone leading capital inside `$…$` | uppercase there means "irregular letter, shown red", not "start of sentence" |

The `$…$` spans in the shipped draft were computed the way `IrregularityMarker` computes
them — uppercase the difference between the real form and its regular composition — so the
red letters match what Browse Verbs shows for the same form.

## `make_symbols.py` — tab-bar custom SF Symbols

Generates the `dancer` and `bull` custom SF Symbols used by the Browse and Quiz tabs
(`Conjugar/Assets.xcassets/{dancer,bull}.symbolset`) from Noun Project line art, with
no vector editor.

```bash
python3 scripts/make_symbols.py
```

### What it does

For each artwork it parses the true bounding box (sampling the Béziers), fits it to the
reference glyph's bbox in every weight/scale slot of an SF Symbols template, and thickens
it by **geometric dilation** — the symbol compiler honours `fill`, not `stroke`, so weight
has to come from geometry (a union of offset copies ≈ Minkowski sum with a disk). The
dilated art is defined once in `<defs>` and referenced per slot with `<use>`, keeping each
symbol ~90 KB instead of ~3 MB.

Tunables via env vars: `GROW` (dilation radius in template units, default 1 — matches the
weight of stock `key`/`gearshape`; ≥2 closes the line art's internal gaps), `DIRS` (offset
directions, default 8), `ROUND` (emitted coordinate decimals, default 0). Per-symbol size
is set in the `__main__` block (`bull` is rendered at 1.2× for legibility).

Custom symbols are referenced with `image:` (not `systemImage:`) and are not subject to the
tab bar's automatic `.fill` substitution, so they render their line art as-is.

### Sources (`symbol-sources/`)

| File | Provenance |
|------|-----------|
| `gearshape-template.svg` | SF Symbols.app export of `gearshape` (Static template) — used only as the annotated canvas (guides + weight/scale slots). |
| `noun-bull-8280587.svg` | "bull" by **taash5studio**, [Noun Project](https://thenounproject.com/icon/bull-8280587/), CC BY 3.0. |
| `noun-flamenco-dance-4581460.svg` | "flamenco dance" by **Amethyst Studio**, [Noun Project](https://thenounproject.com/icon/flamenco-dance-4581460/), CC BY 3.0. |

The two Noun Project icons are CC BY 3.0; attribution is carried in the app's Info-tab
credits (`Localizable.xcstrings` → `Info.creditsText`). To swap in different art, drop a new
SVG in `symbol-sources/`, point the `__main__` call at it, and re-run.
