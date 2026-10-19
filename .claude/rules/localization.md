---
paths:
  - "**/*.xcstrings"
  - "Conjugar/Supporting/L.swift"
---

# Localization details

These rules also apply to the widget target's own catalog, `ConjugarWidget/Localizable.xcstrings`. The overview of the two-part system (`L.swift` plus `Localizable.xcstrings`) is in the root `CLAUDE.md`.

# Adding / changing a localized string

1. Add the accessor to `L.swift` in the right scope (`Feature.purpose`); use a `static func`
   for parameterized strings.
2. Add the key + `en`/`es` translations to `Localizable.xcstrings` (both `"state":
   "translated"` so Xcode doesn't treat `es` as stale and fall back to English).
3. Use via `L.Feature.name` in code.

# Editing `Localizable.xcstrings` safely (the foot-guns)

- **The Edit tool corrupts `.xcstrings` values with ASCII quotes.** Edit operates on
  *rendered* text, so JSON's `\"` displays as a plain `"`; any edit adding/removing/changing
  an ASCII `"` (U+0022) inside a value writes an **unescaped** quote and breaks the catalog.
  Rule: edit `.xcstrings` values containing ASCII quotes via `python3` on the raw file, not
  Edit. Unicode curly quotes `" " „` need no escaping and are safe with Edit.
- **Always validate after any edit:**
  `python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"`.
- **Grep is useless inside `.xcstrings`** — each value is one very long JSON line, so the
  Grep tool truncates matches to `[Omitted long matching line]`. To find a phrase: Grep for
  the line number, then Read at that offset. To replace: Python with a unique nearby word as
  an anchor to hit the correct language section (e.g. a Spanish word to target `es`, not
  `en`).

# `.strings` vs `.xcstrings` escaping & newlines

If you ever re-derive the catalog from a legacy `.strings` file, do **not** hand-translate
escaping — use real parsers (`plutil -convert json` to read, `json.dump` to write). The
rules differ:

- **`.strings`** (old, UTF-16, C-style): interior quotes `\"`; **literal newlines allowed**
  inside a value; a naive UTF-8 read produces garbage.
- **`.xcstrings`** (new, JSON, UTF-8): interior `"` must be `\"`, backslash `\\`; **literal
  newlines are illegal** — every newline must be `\n`, so each rich-text block is one
  physical JSON line. A serializer emits both correctly; string-concatenation does not.

# Percent signs — two different kinds

- **Rich-text markup** like `%terminología%`, `%voseo%`, `%presente de indicativo%` is the
  Info parser's *tappable-term* syntax, a **single** `%…%` looked up with no format
  arguments — the `%` passes through literally. Do **not** double it. URLs in Info bodies are
  also wrapped in single `%…%` (e.g. `%https://…%`).
- **Format specifiers** (`%@`, `%lld`) are the real ones. Prefer `%lld` over `%d` for `Int`
  (what the catalog generates). Multi-arg strings use **positional** specifiers so
  translators can reorder: `Model %1$@ · %2$lld%% irregular` (note `%%` for a literal
  percent). Pluralized strings use xcstrings plural **variations** (`one`/`other`), provided
  for both `en` and `es`; where a distinct zero sentence is needed (e.g. ratings), keep it a
  separate key and pick it at the call site, because CLDR maps `0 → other` for en/es.

# Info rich-text markup (parsed by `StringExtensions`, rendered by the Info screens)

Other markup in the long Info/tense bodies is literal text needing no escaping in either
format:

| Marker | Purpose | Example |
|--------|---------|---------|
| `^…^` | Section heading | `^Purpose^`, `^Conjugation^` |
| `~…~` | Emphasis/italic | `~Conjugar~`, `~vosotros~` |
| `$…$` | Irregularity highlight (uppercase letters = the irregular part, shown red) | `$voY$`, `$soY$`, `$habRá$` |
| `%…%` | Tappable term (links to another tense/terminology) or URL | `%voseo%`, `%https://…%` |

When relocalizing an Info body, preserve every marker in the equivalent position and keep
example Spanish/English words and irregular-highlight casing intact.
