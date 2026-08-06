# Task: Rename the remaining `*2` engine types — drop the meaningless "2"

You are starting a fresh session on the **Conjugar modernization project** (see
`CLAUDE.md`). The legacy `Conjugator` engine, `verbs.xml`, and their tests were
**removed in July 2026**, so the "2" suffix on the new engine's types no longer
distinguishes anything — there is no "1" anymore. Rename the remaining `*2` model
types to names without the "2".

**Naming discretion:** For most types, simply dropping the "2" is fine
(`VerbModel2` → `VerbModel`). But you have discretion to choose a *better* name
where plain removal produces something weak, vague, or collision-prone — e.g.
`Feature2` → bare `Feature` is very generic; something like `ConjugationFeature`
may serve better. Per this project's convention (see the naming discussion in
`CLAUDE.md`), **check for system-API collisions** before settling on any name
(`Locale` famously had to become `AnalyticsLocale`).

**Propose before executing.** Before renaming anything, present Josh a table of
old name → proposed new name (with a one-line rationale wherever you deviate from
plain 2-dropping) and wait for his approval.

## Precedent (already done — do not redo)

Two rename rounds established the pattern and mechanics (commits `4d813ee`,
`e187eeb`):

- `Tense` → `DisplayTense`, `Tense2` → `EngineTense`
- `PersonNumber` → `DisplayPersonNumber`, `PersonNumber2` → `EnginePersonNumber`

Those four had *both* halves alive (UI vocabulary vs. engine vocabulary), hence
the Display/Engine prefixes. The types below have no counterpart — the plain name
is free — so no prefix is needed.

## Inventory (complete as of 2026-07-05 — verify with the greps below)

Types declared with a trailing `2` (33 identifiers):

```
AbsorbIAfterPalatal2   DiaeresisDropBeforeY2   PreteriteEndings2
AccentFeature2         FutureEndings2          RegularRoot2
AccentStem2            FutureFeature2          ResidueFeature2
ApocopatedImperative2  IrregularParticiple2    RunningStemConsonantSwap2
CollapseDoubleI2       IYHiatus2               Slot2
Conjugator2            LiteralSlotOverride2    StemFeature2
ConsonantTrigger2      ModelCatalog2           StemFinalConsonant2
DefectiveFeature2      OrthographicFeature2    StemVowel2
DiaeresisFeature2      PreteriteFeature2       StemVowelFeature2
Feature2               SuppletivePreterite2    VerbMap2
                                               VerbMapEntry2
                                               VerbMapParser2
                                               VerbModel2
```

Identifiers with an *interior* `2` that must also change:

- `Conjugator2Error` — note the deleted legacy engine's `ConjugatorError` name is
  now free, so plain `ConjugatorError` works (or better, your call).
- Test suites: `Conjugator2Tests`, `Conjugator2AccessorsTests`, `VerbMap2Tests`,
  `Resolver2Tests` (there is no `Resolver2` type — the suite tests model
  resolution inside the engine; rename it to whatever matches its subject).

Files to `git mv` (filename = type name, one type per file where that already
holds; the Feature files bundle several conformers — keep their bundling, just
rename the files to match their primary type):

```
Conjugar/Models/AccentFeature2.swift        Conjugar/Models/PreteriteFeature2.swift
Conjugar/Models/Conjugator2.swift           Conjugar/Models/RegularRoot2.swift
Conjugar/Models/Conjugator2Error.swift      Conjugar/Models/ResidueFeature2.swift
Conjugar/Models/DiaeresisFeature2.swift     Conjugar/Models/StemFeature2.swift
Conjugar/Models/Feature2.swift              Conjugar/Models/StemVowelFeature2.swift
Conjugar/Models/FutureFeature2.swift        Conjugar/Models/VerbMap2.swift
Conjugar/Models/ModelCatalog2.swift         Conjugar/Models/VerbModel2.swift
Conjugar/Models/OrthographicFeature2.swift
ConjugarTests/Models/Conjugator2AccessorsTests.swift
ConjugarTests/Models/Conjugator2Tests.swift
ConjugarTests/Models/Resolver2Tests.swift
ConjugarTests/Models/VerbMap2Tests.swift
```

The Xcode project uses **file-system-synchronized groups**, so renamed files are
picked up automatically — no pbxproj surgery.

## ⚠️ Do NOT rename these

- `imperfectoDeSubjuntivo2Text` and `pluscuamperfectoDeSubjuntivo2Text`
  (`Localizations.swift` / `Info.swift` / `Localizable.strings`): the "2" there
  means *Imperfecto de Subjuntivo **2*** — the tense's -se variant — not the
  engine generation. Leave them, and leave every `NSLocalizedString` **key**
  untouched in general (keys are how the Spanish translations are looked up; the
  Tense rename round protected the `"Tense"` key for exactly this reason).
- `DisplayTense` / `EngineTense` / `DisplayPersonNumber` / `EnginePersonNumber` —
  already final.
- Historical documents: `docs/blog_notes.md` entries and `prompts/*.md` are a
  journal; old names in them are history, not staleness. (A *new* blog note about
  this rename is expected, though.)

## Mechanics that worked in the prior rounds

- Word-boundary-aware perl over both source trees, e.g.
  `perl -pi -e 's/\bVerbModel2\b/VerbModel/g'` via
  `find Conjugar ConjugarTests -name '*.swift' -print0 | xargs -0 perl -pi -e '…'`.
  `\b` protects compounds automatically (`\bConjugator2\b` does not match
  `Conjugator2Error`), but rename interior-2 identifiers **first** anyway, then
  the trailing-2 batch, then grep for stragglers.
- Sweep **lowercase locals/parameters** echoing old names afterwards (the prior
  rounds caught `tense2`, `personNumber2`, `simpleTense2`); expect the likes of
  `feature2`, `model2`, `slot2`.
- String literals: `@Suite`/`@Test` display strings *should* adopt the new names;
  localization keys must not (see above). Audit with
  `grep -rEn '"[^"]*2[^"]*"' Conjugar ConjugarTests --include='*.swift'`.
- Update **CLAUDE.md**: the Project Overview and Core Models sections name
  `Conjugator2`/`VerbMap2`/`ModelCatalog2` and "the `*2.swift` family", and the
  Build/Test section's `-only-testing:` examples reference `Conjugator2Tests` —
  all must match the new names.
- Verify no stragglers:
  `grep -rEn '\b[A-Za-z]+2[A-Za-z]*\b' Conjugar ConjugarTests --include='*.swift'`
  (expect only the two `…Subjuntivo2Text` localization accessors and their keys).

## Heads-up: test-ordering flake risk

Renaming XCTest classes changes their **alphabetical execution order**, which the
PersonNumber round proved can surface latent shared-state flakes (it exposed a
`Current.gameCenter` race in `GameCenterFakeTests`, since fixed). If a seemingly
unrelated test fails, suspect ordering/shared `Current` state, run it in
isolation, and read the failure line from the `.xcresult`
(`xcrun xcresulttool get test-results summary --path …`) before assuming your
rename broke logic.

## Verification & deliverables

- Build, then full suite green, **twice** (flake check):
  ```bash
  xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  xcodebuild -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test
  ```
- `swiftlint` — violation count should not grow (132 pre-existing as of this
  writing).
- Smoke-test in the simulator via the **`run-in-simulator`** project skill:
  Browse → tap a verb → full conjugation grid renders.
- Add a `docs/blog_notes.md` entry.
- Commit to the **migration** branch and push.
