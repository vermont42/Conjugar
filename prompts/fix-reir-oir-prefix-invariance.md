# Task: fix the reír (6B-4) / oír (10) prefix-invariance bug (engine)

You are starting a fresh session on the **Conjugar parsimony project**. Read
`CLAUDE.md` (project root) for the overall goal. This is a small, surgical
**engine** fix on branch `migration` in `/Users/josh/Desktop/workspace/Conjugar.mig`.
It is a **prerequisite for Phase 6 C** (the no-`model:` resolver, `prompts/phase-6-data-entry.md`):
do this first, then 6C can include reír/oír compounds in its gate.

## Background — where things stand

The engine (Phases 1–5b) and the Phase 6 **model catalog** (A) + **verb→model map +
glosses** (B/B2) are done: **332 tests, 0 failures** on `migration`
(`ConjugarTests/{Conjugator2Tests,VerbMap2Tests}`). While verifying B, a
**pre-existing Phase-5 engine defect** surfaced, fully analyzed in
**`docs/phase6_known_issues.md`** (read it first). This task fixes it.

The defect: a few `ModelCatalog2` models conjugate some slots from **literal slot
overrides** (`LiteralSlotOverride2`, absolute form strings like `"río"`, `"oímos"`)
instead of **end-anchored features**. Literals are **not prefix-invariant**, so a
prefixed compound that maps to such a class conjugates the *base* verb's literal in
those slots instead of its own stem — violating the taxonomy §1 end-anchored
constraint that makes the prefix payoff work (`docs/spanish_taxonomy.md` §1).

Concretely (verified):
- **6B-4 `reír`** — broadly broken for its **6 compounds** (`freír`, `sonreír`,
  `sofreír`, `refreír`, `desleír`, `engreír`). Present indic./subj., 1p/2p preterite,
  and PP are literals (`río`, `ríes`, `ría`, `reímos`, `reído`, …) so e.g.
  `conjugate("freír", PI-1s)` returns **`río`** instead of `frío`.
- **10 `oír`** — narrowly broken for `desoír`, `entreoír`: only the **2** literal
  slots (PI-1p `oímos`, IMP-2p `oíd`) are wrong (`desoír` PI-1p → `oímos` not
  `desoímos`). Everything else (oigo/oyó/oído) is already correct/end-anchored.

A prefix prepend hack will **not** work (it gives `freír`→frío but `desleír`→*desrío;
the literal `río` bakes in the consonant `r`, which differs from `desleír`'s `l`).
The fix must **compute the forms from each verb's own stem**.

## The fix — compose from existing features (no new feature type needed)

The forms decompose cleanly into features the engine already has. **This recipe is
a strong, analysis-backed hypothesis — verify every slot against the oracle and
adjust as needed; the oracle wins.**

### Relevant existing pieces (in `Conjugar/Models/`)
- `StemVowel2.rEiStr` / `.rEiWk` — raise stem `e→i` in stressed/weak slots (turns
  `re`→`ri`; already in the reír build). End-anchored.
- `AccentStem2.aI` (`AccentFeature2.swift`) — accents the stem's **last** `i`→`í` in
  the **stressed-stem** slots, end-anchored (this is exactly what `enviar` uses:
  `enví`→envío/envías/envíe/envíen, 1p `enviamos` unaccented). Applied **after** the
  raise, this yields `rí`→ río/ríes/ríe/ríen, ría/rías/ría/rían, ríe(IMP-2s), and is
  prefix-invariant (`sonri`→sonrío, `fri`→frío, `desli`→deslío).
- `IYHiatus2.oYhiatus` (`OrthographicFeature2.swift`) — the i→y glide + the **hiatus
  written accents** on `PR{2s,1p,2p}` + `PP`, firing **only after a strong vowel
  (a/e/o)** (so it gives reíste/reímos/reísteis/reído for the `re` stem, but leaves
  the weak-vowel -uir verbs alone). Already in the oír build.
- `CollapseDoubleI2.collapse` (`ResidueFeature2.swift`) — `ri+ió→rió`, `ri+iendo→
  riendo`, `ri+iera→riera` (already in the reír build). End-anchored.

### Step 1 — extend `IYHiatus2`'s accent slots (fixes the shared 1p/2p gap)

Add `PI(.firstPlural)` and `IMP(.secondPlural)` to `IYHiatus2.isAccentSlot`. The
accent already fires **only when the ending starts with `i` and the stem's last
char is a strong vowel**, so this is safe for every existing `oYhiatus` user
(verified):
- `leer`/`caer`/`traer`/`raer`/`roer` (-er): 1p/IMP-2p endings are `-emos`/`-ed`
  (no leading `i`) → no-op.
- `construir` (-ir): `construimos`/`construid` — stem ends in weak `u` → guard
  blocks the accent → unchanged.
- `oír`: `o`+`imos`/`id` → **oímos / oíd** ✓. `reír`: `re`+`imos`/`id` → **reímos /
  reíd** ✓ (PI-1p/IMP-2p are not stressed-stem, so the stem stays `re`).

This alone fixes **oír** entirely.

### Step 2 — rebuild `oir` and `reir` end-anchored (delete the literal residue)

```swift
static let oir = VerbModel2(base: .ir, features: [
  StemFeature2.yAdd, StemFeature2.g1ig, IYHiatus2.oYhiatus,   // no residue([...])
])

static let reir = VerbModel2(base: .ir, features: [
  StemVowel2.rEiStr, StemVowel2.rEiWk,   // re→ri (raise)
  AccentStem2.aI,                        // ri→rí in stressed-stem slots: río/ríes/ríe/ríen, ría…, ríe
  IYHiatus2.oYhiatus,                    // reíste/reímos/reísteis/reído (+1p/IMP-2p from step 1)
  CollapseDoubleI2.collapse,             // rió, rieron, riendo, riera
])
```
Order matters: raise **before** `AccentStem2.aI` (so it accents the raised `i`).
Cross-check `AccentStem2.aI` does not mis-fire in a stressed-stem slot that lacks a
raised `i` (it shouldn't — PI-1p/PR-3s/PS-1p are not stressed-stem); if any slot is
off, narrow with the oracle.

### Note on participles (out of scope, but the fix improves them)

The reír family's PP **variants** (`freír`→frito, `sofreír`→sofrito, `refreír`→
refrito; Annex B fn15/22/24) are **per-verb data, explicitly out of scope** (the
Phase 6 prompt's "log, don't model"). With the end-anchored PP above, `freír` now
yields **`freído`** (the regular/secondary accepted form — a correct improvement
over today's `reído`); only the preferred `frito` alternate remains unmodeled,
tracked for the later per-verb-data pass (same shape as the `dg` defect hook). Do
**not** add per-verb participle data here. The test-only `freir`/`inscribir` models
in `Conjugator2Tests` (which carry `frito` for the two-form-participle tests) are
independent of the catalog and should stay as-is.

## Gate (what "fixed" means)

All in the real test target, **332 prior tests still green** (`Conjugator2Tests` +
`VerbMap2Tests`), 0 failures:

- **oír family:** `oír`, `desoír`, `entreoír` conjugate correctly on their own stem —
  in particular `desoír` PI-1p → **desoímos**, IMP-2p → **desoíd**, and oigo/oyó/oído
  ride along (oír's full paradigm unchanged from the oracle).
- **reír family:** `reír` full paradigm matches the oracle (`docs/spanish_models.md`
  6B-4, ≈ line 1042), **and** each compound conjugates on its own stem —
  `freír`→frío/frió/friendo/freímos/freído, `sonreír`→sonrío/sonrió/sonriendo,
  `sofreír`/`refreír`/`desleír`/`engreír` likewise (e.g. `desleír`→deslío, proving
  the prefix is computed, not prepended).
- **No regression:** every other `oYhiatus` user (leer/caer/traer/construir/raer/
  roer) is byte-for-byte unchanged (the IYHiatus extension is a no-op for them).
- **Score seam intact:** the §6.5 irregularity score still reads `model.features`
  only; reír/oír feature lists changed (literals removed, raise/accent added) — that
  is the honest decomposition, fine. Don't special-case the score.
- **Add tests:** extend `Conjugator2Tests` with reír's full paradigm and oír's
  oímos/oíd as catalog-driven exemplars, and add reír/oír **prefix-invariance** cases
  (sonreír, freír, desleír, desoír) — mirror the existing `reargüir`/`detener`
  prefix-invariance tests. Then **remove the reír/oír caveats** from
  `ConjugarTests/Models/VerbMap2Tests.swift` (the `perClassSample` comment and the
  prefix-payoff note) and add the now-passing compounds there.

## Method (build/test mechanics)

- **Fast inner loop** — standalone `swiftc` driver (SourceKit "No such module
  'Testing'"/"cannot find type" on single-file indexing is noise; the `swiftc` build
  and `xcodebuild test` are the truth). Compile the **engine-only** files (not all
  `Models/*.swift` — several app files import UIKit and won't link standalone):
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig/Conjugar/Models
  ENGINE="PersonNumber2.swift Tense2.swift RegularRoot2.swift Feature2.swift \
  VerbModel2.swift Conjugator2.swift Conjugator2Error.swift OrthographicFeature2.swift \
  AccentFeature2.swift StemVowelFeature2.swift StemFeature2.swift PreteriteFeature2.swift \
  FutureFeature2.swift ResidueFeature2.swift DiaeresisFeature2.swift ModelCatalog2.swift \
  VerbMap2.swift"
  xcrun -sdk macosx swiftc $ENGINE /tmp/fix/main.swift -o /tmp/fixcheck && /tmp/fixcheck
  ```
  (driver file must literally be named `main.swift`, in its own dir). Drive forms via
  `Conjugator2.conjugate(infinitive:tense:model: ModelCatalog2.model(forClass: "6B-4")!)`
  etc. — conjugate each compound on its own infinitive to prove prefix-invariance.
  Use `conjugateAll` where you want to check alternates.
- **Full gate:**
  ```
  cd /Users/josh/Desktop/workspace/Conjugar.mig
  xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
    -destination 'platform=iOS Simulator,id=6F676E8C-B98B-432C-9FD5-41E555921BC5' \
    -only-testing:ConjugarTests/Conjugator2Tests -only-testing:ConjugarTests/VerbMap2Tests
  ```
  (iPhone 15 Pro sim id worked this session; `xcrun simctl list devices available |
  grep iPhone` for another.) All green, 0 failures.

## Deliverable

- The two rebuilt catalog models + the `IYHiatus2` accent-slot extension, with new
  reír/oír paradigm + prefix-invariance tests, all green (332 + new, 0 failures).
- **Delete `docs/phase6_known_issues.md`** (or replace its body with a one-line
  "Resolved <date>: reír/oír are now end-anchored; see blog_notes.md"), since the
  issue it tracks is fixed.
- A one-line entry in `docs/blog_notes.md` under today's date.
- A clean **commit on `migration`** in `Conjugar.mig` (e.g. "Fix reír/oír
  prefix-invariance: end-anchor the literal residue"), **push only if the user asks**.
  End the commit message with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

## Pointers

- `docs/phase6_known_issues.md` — the full defect analysis (read first).
- `docs/spanish_models.md` — the oracle: 6B-4 reír ≈ line 1042, 10 oír ≈ line 1287.
- `Conjugar/Models/ModelCatalog2.swift` — the `reir`/`oir` builds to rewrite.
- `Conjugar/Models/{AccentFeature2,OrthographicFeature2,StemVowelFeature2,ResidueFeature2}.swift`
  — `AccentStem2.aI`, `IYHiatus2`, `StemVowel2.rEi*`, `CollapseDoubleI2`.
- `ConjugarTests/Models/Conjugator2Tests.swift` — the `reargüir`/`detener`
  prefix-invariance tests to mirror; the `swift-testing-expert` skill for the *how*.
