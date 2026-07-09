# Sweep provenance comments (numbered-suggestion & book references)

## Why this exists

During the modernization project, an Anthropic Fable model audited this codebase
(and the sibling apps Konjugieren and Conjuguer), and Opus implemented the
suggestions. The implementers left a trail of **provenance citations** in the
comments — pointers to numbered audit suggestions, to build-plan phases, and to
the external Spanish-verb reference book / taxonomy oracle. Josh wants those
pointers gone: they impose a maintenance burden, they couple the code to
documents that don't live in the codebase, and they say nothing a future reader
of *this file* needs to know.

This is a **comment-only** sweep. Do not change any executable code, string
literals, or user-facing copy. `git diff` should show only comment lines.

## The governing rule (the AccentFeature precedent)

`Conjugar/Models/AccentFeature.swift` was already done by hand as the worked
example. The rule it demonstrates, applied to every comment that carries a
provenance citation:

1. **Strip the citation token** — the `(item 20)`, `§4.5`, `Phase 4`,
   `audit §3 / K6, C7`, `spanish_models.md §3`, `decision §6.2`, etc.
2. **Then judge the residual comment on its own merits:**
   - **Keep it (trimmed)** if what remains is genuine, non-obvious domain
     knowledge or rationale a future reader benefits from — e.g. "these three
     grammatical patterns collapse into one mechanical operation," worked
     examples like `enviar → envío`, "recomputed only when searchText or sort
     changes." Rephrase so it reads cleanly without the citation.
   - **Delete the whole comment** if, once the citation is gone, all that's left
     is change-provenance — a note that exists only to explain *that a past edit
     happened* ("Straightened per item 19: …", "Off-main (item 14): …" where the
     remaining text just narrates the refactor). If the comment answers "why is
     the code like this?" with durable reasoning, keep it; if it answers "what
     did we change and which suggestion drove it?", delete it.

This is judgment work, not a regex replace. When a comment is borderline, prefer
Josh's stated default: he is comment-averse and believes well-written code is
self-documenting, so **lean toward deletion** when the residual value is thin.

**When you are genuinely unsure** whether a comment should be deleted, trimmed,
or kept — after applying the rule and the lean-toward-deletion default — **stop
and ask Josh** rather than guessing. Collect such cases and ask them together
(with the file, the comment, and your recommendation) instead of interrupting
per file. Reserve this for real uncertainty; do not ask about clear-cut hits.

## Reference families in scope (search patterns)

Run these across `Conjugar/**/*.swift` and `ConjugarTests/**/*.swift`. Treat the
list as a starting net, not an exhaustive index — read each hit in context.

- **Numbered audit suggestions (the primary target):** `item \d+`
- **Build-plan phases:** `Phase \d+` (these map to the `prompts/phase-*.md`
  files — pure implementation-project provenance)
- **UI-audit section pointers:** `audit §\d+`, and the cross-app audit codes
  `\bK\d+\b` / `\bC\d+\b` (Konjugieren / Conjuguer suggestion numbers, e.g.
  `_(audit §3 / K6, C7)_`), plus references to `docs/conjugar-ui-issues.md` and
  `ios-design-agent-skill §\d+`.
- **Book / taxonomy / oracle citations:** `§\d`, `taxonomy §`, `decision §`,
  `oracle §`, `spanish_models.md`, and the standalone word `book` used as a
  *source citation* ("the book lists two forms", "in the book's row order",
  "the 2010 book"). See the book nuance below.

A single starter regex to find most hits:
`item \d+|Phase \d+|audit §|\bK\d+\b|\bC\d+\b|§\d|taxonomy|spanish_models|\bbook\b|oracle §|ios-design-agent-skill`

## The `book` nuance

The class numbers this engine uses genuinely originate from a published
verb-model reference. Two different uses appear:

- **Citation** — "the book lists two co-equal forms", "the 2010 book predates
  these neologisms". Remove per the rule above.
- **Load-bearing description of what a value is** — "book class number",
  "book order for class numbers", "the book's row order". Here `book` is
  describing the *nature* of the data. **Do not just delete the word and leave a
  dangling phrase.** Rephrase: `book class number` → `class number`;
  `book order` / `book's row order` → `canonical order` (or spell out the order
  once and drop the adjective). The goal is a comment that stands on its own
  without pointing outside the repo.

## Do NOT touch (false positives)

These matched the search net but are **not** provenance citations:

- `Conjugar/Views/TutorView.swift` — `englishSuggestions`, `spanishSuggestions`,
  `suggestions`, `suggestion` are code identifiers (the tutor's prompt chips).
- `Conjugar/Utils/CommunGetterStub.swift:25` — "suggestions for new features" is
  user-facing localized copy inside a stub, not a comment.
- Any occurrence of these words inside a **string literal** or a
  `.xcstrings`-bound value. This sweep is comments only.
## Do NOT reference the sibling apps

Remove **every** mention of the sibling apps Konjugieren and Conjuguer from
comments — including architectural / design-context mentions like "Mirrors
Konjugieren's ModelBrowseView", "matches the sibling apps", "ported from
Conjuguer". Those apps do not live in this codebase and a reader here should not
be sent to them. Apply the governing rule: strip the sibling-app reference, then
keep the residual comment if it stands on its own, or delete it if the reference
was the only content.

## File inventory (as of this writing)

Already done: `Conjugar/Models/AccentFeature.swift`.

**Models / engine** (dense with `§` taxonomy + `Phase` citations; highest
judgment load — most of these comments have real linguistic value around the
citation, so expect mostly *trim*, not delete):
StemFeature, OrthographicFeature, FutureFeature, StemVowelFeature,
PreteriteFeature, ResidueFeature, ConjugationFeature, ConjugatorError,
RegularRoot, EnginePersonNumber, EngineTense, VerbModel, VerbMap, Conjugator,
ModelCatalog, ModelSort, DiaeresisFeature, DisplayPersonNumber,
SecondSingularQuiz, Quiz, LanguageModelService, LanguageModelServiceReal.

**Utils** (mostly `item N`; expect more *delete* — these tend to be
change-provenance):
Utterer, GameCenterFake, SoundPlayer, FontExtensions, RatingsFetcher, Modifiers,
BrowseSearch, WidgetSnapshotWriter, GradientDivider, Settings.

**Views** (`audit §N` in the file-header block comments + scattered `item N`):
VerbView, ModelView, RichTextView, CommunView, ConjugationText, InfoBrowseView,
ModelBrowseView, VerbBrowseView, QuizView, ResultsView, InfoView, SettingsView,
MainTabView.

**Supporting:** L.swift, AppDelegate.

**Tests** (`ConjugarTests/`; mostly `item N` in suite-header comments and a few
`§` MARKs + `2010 book`):
Utils/RatingsFetcherTests, Utils/GameCenterPromptTests, Utils/BrowseSearchTests,
Views/SettingsViewTests, Utils/GameCenterFakeTests, Models/QuizGoldenFormsTests,
Models/QuizTests, Models/VerbMapTests, Models/ConjugatorTests.

Re-run the search before starting — files may have shifted since this inventory.

## MARK comments — delete all of them

Josh does not use `// MARK:` markers for navigation. Delete **every** `// MARK:`
comment in the swept files, unconditionally — not just the ones embedding a
citation. This is a blanket deletion, independent of the provenance rule above:
remove the entire `// MARK: …` line regardless of what text follows the marker.

Search: `// MARK:` across `Conjugar/**/*.swift` and `ConjugarTests/**/*.swift`.

## Execution mechanics

- Work file-by-file. For each, read the full comment context around every hit —
  never blind-replace, because the same `§4.5` may be delete-worthy in one spot
  and keep-worthy in another.
- Editing view/engine files spams SourceKit "Cannot find type X in scope" /
  "has no member" diagnostics for same-module symbols. These are **false
  positives** — comment edits cannot change symbol resolution. Ignore them.
- `Localizable.xcstrings` is **out of scope** (no code comments live there) —
  do not open it.
- When done, validate with one build + the test build, since the change is
  comment-only and should compile identically:
  - `~/.claude/skills/ios-build-verify/scripts/build_app.sh`
  - `swiftlint`
  - Optionally `~/.claude/skills/ios-build-verify/scripts/run_tests.sh` (comment
    edits shouldn't affect tests, but the test files are in scope so a build of
    the test target is worthwhile).
- `git diff` sanity check: every changed line should be a comment (`//`, `///`,
  or inside a `/* */`). If a non-comment line changed, revert it.

## Commit

One commit on the `migration` branch, e.g.:
`Strip audit/build-plan/book provenance citations from comments`
Body: note that this removes pointers to the Fable audit's numbered suggestions,
the build-plan phases, and the external verb-reference/taxonomy oracle — none of
which belong in the shipping codebase — keeping only the durable domain rationale
that stands on its own.

Add a `docs/blog_notes.md` entry describing the sweep.
