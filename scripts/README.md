# scripts

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
