# Native iPad Support — Implementation Plan (item 15 / step 9)

**Status:** all Claude-side phases ✅ done (2026-07-16, on `migration`). Phases 0, 1, 2a,
2b, 2c, 3, 4, and the iPhone-regression slice of 5 are complete (commits `fb08e9b`,
`1b45fe8`, `0c5ab81`, `796fd26`, `8ce8439`, `e10bbe9`, `a975ba6`). **Remaining is Josh's
device/manual work only:** the Phase 5 iPad device matrix (portrait/landscape/rotate),
Split View + Stage Manager multitasking, iPad widget-gallery previews, App Store iPad
screenshots, and the real-device `TutorView`/`TutorTestView` check (the on-device model is
unavailable in the simulator). See §3 Phase 5 for the split.
**Tracks:** round-2 review **item 15** ("Native iPad support: per-screen layout audit + fix")
and **step 9** of the proposed implementation sequence in
`prompts/code-review-recommendations-2.md`.
**Owner:** Josh, across multiple sessions (same as the sibling apps).

---

## 1. Where things stand

The *enabling* change is already done: the app target was flipped to
`TARGETED_DEVICE_FAMILY = 1,2` (2026-07-15), so Conjugar now runs **native** on iPad
instead of letterboxed in iPhone-compatibility mode. `Info.plist`'s
`UISupportedInterfaceOrientations~ipad` already allows all four orientations. The
**game screen is handled** (item 8: `GameView.fieldSize(in:)` portrait-column letterbox
+ `GameState.reconfigure(screenSize:)` re-deal on resize). **Everything else in
`Views/` still renders phone-shaped, stretched to iPad width.**

### What the current build actually looks like on iPad (iPad Pro 11", iPadOS 26, this session)

- **The navigation chrome is already correct for free.** On iPadOS 26 the plain
  `TabView { Tab(...) }` in `MainTabView` auto-promotes to the centered **top tab-bar
  pill** (Browse · Models · Quiz · Info · Settings), and `.searchable` collapses to a
  magnifying-glass button at the top-right. No shell rewrite is needed — this matches
  the sibling-app screenshots out of the box.
- **The content is the problem.** Every screen is a single phone-width column stretched
  edge-to-edge:
  - **Browse / Models:** a full-width `List`/`LazyVStack`; each verb row spans the whole
    ~834–1366 pt width with the `#rank` badge marooned at the far right and a sea of dead
    space between gloss and badge.
  - **Verb detail (`VerbView`):** a single column of full-width conjugation cards, each
    using only ~30 % of its width for `yo/tú/él… + form`; the rest is empty.
  - **Info:** grouped inset `List`s stretched full-width (least offensive, but still
    uncapped long rows).
  - **Onboarding cover:** welcome content floats as a small block pinned to the top of a
    vast empty iPad canvas.
- **Long-form reading content** (Info article bodies, tense explanations) will run to
  ridiculous line lengths at iPad width with no measure cap.

### The sibling-app blueprint (Conjuguer + Konjugieren) — mirror this

Both sibling apps were audited this session. Their entire iPad story rests on **two**
mechanisms and **no** heavy machinery — importantly, **neither uses `NavigationSplitView`,
a custom top-bar TabView, `UIDevice`, nor `userInterfaceIdiom` anywhere:**

1. **Shell:** a plain iOS 18 `TabView { Tab(_:systemImage:value:) }` — the OS renders the
   bottom bar on iPhone and the top bar on iPad. Conjuguer additionally pins
   `.tabViewStyle(.sidebarAdaptable)`; Konjugieren does **not** and looks the same on the
   top bar. (Conjugar currently matches Konjugieren — no style modifier — and already
   top-bars on iPadOS 26.)
2. **Per-screen adaptation:** each list/detail screen reads
   `@Environment(\.horizontalSizeClass)` and switches its body between a single-column
   `List`/`LazyVStack` (**compact**) and a `LazyVGrid` (**regular**). Long-form text is
   capped with `.frame(maxWidth: 680)`.

Concrete numbers worth stealing:
- **List grids** use one adaptive column: `GridItem(.adaptive(minimum: ~220–250))`. The
  adaptive minimum is what makes portrait vs. landscape "just work" — the OS fits more
  columns as width grows (≈2 portrait, ≈3–4 landscape, ≈2 in a half-width Split View).
- **Verb-detail conjugation cards** use a **fixed two-column**
  `[GridItem(.flexible()), GridItem(.flexible())]` grid on regular width, fed from a
  single `@ViewBuilder` var reused by both branches (zero content duplication). This is
  the "2 columns of cards side-by-side" seen in the Konjugieren screenshots.
- **Reading width** is the literal `680`. Conjugar **already has `Layout.readingWidth = 680`**.
- Grid cells get the **card** skin; list rows stay bare with dividers/zebra striping. The
  grid is not just a reflowed list — rows are re-skinned as cards.

### What Conjugar already has (so Phase 0 is small)

- `Layout.readingWidth = 680`, `Layout.cornerRadius = 12`, the spacing constants.
- `.card()`, `.cardWithAccentBar()`, `.cardRim()` in `Utils/Modifiers.swift`.
- `BrowseSearch.results(in:query:matches:)` generic filter, already used by Verb/Model browse.
- `VerbRowLabel` (shared verb row used by Browse and Model detail).

### What's missing (build in Phase 0)

- A shared **adaptive-columns** definition (the sibling apps' `BrowseLayout`).
- A **reading-width** centering view-modifier.
- **Card-styled grid-cell** variants for the list screens (the bare rows need a card skin
  for grid mode).

---

## 2. Guiding principles

- **Both orientations are first-class.** Josh's explicit requirement: it must look good in
  **portrait and landscape**. Favor `.adaptive(minimum:)` grids (column count follows
  width) over hard-coded column counts, except the verb-detail 2-column masonry where a
  fixed 2-up is the intended look. Test every screen in both orientations, and rotate
  mid-screen to catch reflow glitches.
- **Size-class driven, so Split View / Stage Manager come for free.** A half-width Split
  View pane reports **compact** width and should fall back to the phone layout; that's
  correct, not a bug. Do not gate on device model or idiom.
- **Mirror the siblings; add no new abstractions beyond the three Phase-0 pieces.** The
  per-screen `if horizontalSizeClass == .regular { grid } else { list }` inline pattern is
  the house style — keep it.
- **Reuse one content builder per screen** across the two branches (as Konjugieren's
  `conjugationSections` does) so the compact and regular layouts can never drift.
- **Never commit without Josh's explicit go-ahead.** Do the work, build/test/lint it
  green, show Josh what changed, and **wait for him to say "commit" (or equivalent)**
  before running `git commit`. This holds for every phase — do not auto-commit even when a
  phase is finished and green. (The suggested commit *sequence* in §6 describes how to
  group the eventual commits, not permission to make them unprompted.)
- **Keep this plan's status current.** When you finish a phase/step, mark it **✅ DONE** in
  this file — both at its section heading and in the §6 commit sequence — with the date and
  (once committed) the short SHA, plus a line noting any deviation from the draft. Do this
  as part of the work so the next session sees an accurate map of what's left. Updating this
  planning doc is not itself a code change and can be done without waiting for commit
  approval, but the doc edit still ships in the same eventual commit Josh approves.
- **Ship green every phase:** `build_app.sh` + full suite (**524 tests / 29 suites** as of
  2026-07-16) + `swiftlint` (0 violations) before showing the change for commit approval.
  Layout-only changes shouldn't need new tests, but add a small `Layout`/`BrowseLayout`
  constant test if you introduce shared numeric constants.
- **Don't touch** the game (done), the engine, or analytics. This work is confined to
  `Views/` + a couple of `Utils/` layout files.
- **Per CLAUDE.md:** append a dated `## <Title> (YYYY-MM-DD)` entry to
  `docs/blog_notes.md` as chunks land; comments only for hacks/todos, never referencing
  the review; edit `.xcstrings` via `python3` (any new localized strings — e.g. a sidebar
  toggle a11y label — need both `en`/`es`).

---

## 3. Phases

Each phase is independently shippable and independently verifiable in the iPad simulator.
Phases 0–1 are foundational; 2–4 are the screen passes (parallelizable across sessions);
5 is QA + screenshots.

### Phase 0 — Shared layout components (do this first) — ✅ DONE (2026-07-16, `fb08e9b`)

Small, mechanical, no visible change on its own. **Shipped**, with two deviations from the
draft below, both intentional:
- The `readingWidth` modifier already existed in `Utils/Modifiers.swift`; rather than add a
  second `readableWidth`, it gained an `alignment:` param (default `.center`). Call sites
  use **`.readingWidth(alignment:)`**, not `.readableWidth(...)`.
- `BrowseLayout.listColumns` uses `.adaptive(minimum: 260)` (not 250) — Conjugar's rows are
  a touch wider than the siblings'. `infoColumns` = 320, `detailColumns` = fixed two-up.
- The card grid-cell (item 3) landed as **`VerbGridCell`** in `VerbBrowseView.swift` as part
  of Phase 2a, not as a standalone Phase-0 file. A `ModelGridCell` is still to build in 2b.

1. **`BrowseLayout` enum** (new file `Views/BrowseLayout.swift`, mirroring the siblings):
   ```swift
   enum BrowseLayout {
     /// Adaptive columns for the verb / model list grids (regular width).
     static let listColumns = [GridItem(.adaptive(minimum: 250), spacing: Layout.doubleDefaultSpacing)]
     /// Adaptive columns for the Info section-card grid (wider cells).
     static let infoColumns = [GridItem(.adaptive(minimum: 320), spacing: Layout.doubleDefaultSpacing)]
     /// Fixed two-up for the verb/model detail conjugation-card masonry.
     static let detailColumns = [GridItem(.flexible()), GridItem(.flexible())]
   }
   ```
   Tune the minimums against real screenshots in Phase 2 (250/320 are the sibling values;
   Conjugar's rows are a touch wider because of the serif infinitive + gloss).
2. **Reading-width modifier** in `Utils/Modifiers.swift`:
   ```swift
   /// Caps long-form content to a comfortable measure and centers it in the
   /// available width. iPhone is narrower than the cap, so this is a no-op there.
   func readableWidth(_ maxWidth: CGFloat = Layout.readingWidth, alignment: Alignment = .center) -> some View {
     frame(maxWidth: maxWidth)
       .frame(maxWidth: .infinity, alignment: alignment)
   }
   ```
   (The inner cap + outer `maxWidth: .infinity` is the exact sibling idiom.)
3. **Card grid-cell** for the list screens. Add a card-skinned wrapper the browse grids
   use — either a small `VerbGridCell`/`ModelGridCell` view, or reuse `VerbRowLabel`/model
   row inside `.card()`. Decide in Phase 2 once the rows are seen in a grid; keep the bare
   row for the compact `List` path.
4. Optional: promote the magic `680` usages to `.readableWidth()` call sites (don't
   scatter new literals — `Layout.readingWidth` is the single source).

**Verify:** builds green; no UI change on iPhone (regression check the iPhone simulator —
the other session may have it booted, so use a *separate* iPad sim for iPad checks and
don't fight over the iPhone one).

### Phase 1 — Navigation shell + search + covers audit — ✅ DONE (2026-07-16, no code change)

Mostly verification; the shell already top-bars on iPadOS 26. **Outcome: no code change** —
the decision below is to leave the shell exactly as-is.

- **Decision on `.tabViewStyle(.sidebarAdaptable)`: DO NOT adopt it — keep the plain
  top-bar `TabView`, matching Konjugieren.** Tried it empirically this session (added the
  modifier, built green, launched on iPad Pro 11" M5). The reasons to leave the shell alone
  won decisively:
  1. The current shell already renders correctly (top-bar pill on iPadOS 26), verified in
     prior sessions.
  2. The custom `dancer`/`bull` line-art tabs were hand-tuned for the top bar with
     `.symbolVariants(.none)`. A sidebar renders icons larger and left-aligned beside the
     stock SF Symbols, where thin outline bitmaps tend to look rough/misaligned — a real
     regression risk for zero functional gain.
  3. **Konjugieren** — the app Conjugar is explicitly kept in parity with ("Conjugar
     currently matches Konjugieren") — ships *without* `sidebarAdaptable` and looks the
     same on the top bar. That's the tie-breaker the plan itself offers ("either is parity").
  4. A sidebar's value is grouping/nesting; 5 flat peer top-level tabs don't benefit, and it
     adds collapse-state + dual-context-bitmap QA burden.
  The experimental modifier was reverted; the tree is back to the committed shell.
- **Top tab bar with custom tabs:** unchanged code, verified correct in prior sessions;
  nothing in this work touches `MainTabView`'s tab definitions.
- **Search placement:** `.searchable` is already on the Verb/Model stacks; no code change.
- **The two `.fullScreenCover`s at iPad size:** both **observed directly this session** on the
  M5 iPad and both render content in a centered reading-width column — `OnboardingView`
  (capped in Phase 4) and `CommunView` ("New Version" card, capped from the migration). ✓

**Verify:** ✅ builds green after the revert (tree == committed shell); covers confirmed
capped/centered on iPad Pro 11" M5. The full portrait+landscape five-tab tap-through and
`conjugar://` deeplink-routing sweep are folded into the Phase 5 QA pass (the shell chrome is
unchanged, so this is a regression re-check, not new behavior).

### Phase 2 — List screens: Browse Verbs, Models, Info

The highest-impact visual fix. For each, add
`@Environment(\.horizontalSizeClass) private var horizontalSizeClass` and split the
collection body.

- **`VerbBrowseView`** — ✅ **DONE (2026-07-16, `1b45fe8`).** Shipped as specified: the
  `filteredVerbs` loop now switches on `horizontalSizeClass == .regular` into a
  `LazyVGrid(columns: BrowseLayout.listColumns)` of `NavigationLink { VerbGridCell(entry).card() }`,
  with the compact `LazyVStack + Divider + zebra` path byte-identical to before (iPhone
  untouched). The bottom sort `Picker` got `.readingWidth()` (no-op on iPhone). The
  `browse_verb_count` anchor and the `ScrollViewReader`/`scrollTo("top")` reset are
  preserved. The tip banner was left uncapped for now — cap it if it looks bad in a later
  QA pass. Verified rendering on iPadOS 26.3 (portrait, two columns); landscape reflow is
  guaranteed by the adaptive grid but not yet screenshot-verified (sim-rotation tooling).
- **`ModelBrowseView`** — ✅ **DONE (2026-07-16, Phase 2b, `0c5ab81`).** Shipped as the
  exact mirror of `VerbBrowseView`: `horizontalSizeClass`
  env, a `LazyVGrid(columns: BrowseLayout.listColumns)` of `NavigationLink { ModelGridCell(model).card() }`
  on regular width, the compact `LazyVStack + Divider + zebra` path byte-identical to before,
  and `.readingWidth()` on the bottom 3-segment sort `Picker`. New `ModelGridCell` view
  (exemplar + irregularity-percent pill pulled up beside it, class number below) added
  alongside `ModelRowLabel`. Verified on iPadOS 26 (iPad Pro 11" M4, portrait): two columns
  of carded cells, pills aligned top-right, sort picker centered.
- **`InfoBrowseView`** — ✅ **DONE (2026-07-16, Phase 2c, `796fd26`).** Took the
  **reading-width grouped list** (Konjugieren) direction, not the
  section-card grid — the grouped `List` gets `.readingWidth()` + a
  `.background(Color(.systemGroupedBackground).ignoresSafeArea())` so the sections sit in a
  centered ~680 column with the grouped background filling the surround seamlessly, rather
  than stretching edge-to-edge. Chosen over the card grid because it's a pure cap (zero risk
  to the Tutor availability row, the tense `E / E&M / E,M&D` segmented control, or the
  difficulty filter — all left untouched) and reads well: the About / Tenses sections keep
  their native grouped-inset look, just no longer absurdly wide. No-op on iPhone (narrower
  than the cap; the identical background is invisible). Verified on iPadOS 26.

**Verify:** all three lists in both orientations; confirm ≈2 columns portrait / ≈3–4
landscape via adaptive sizing; half-width Split View falls back to the single-column list;
search still filters; sort still animates + haptics.

### Phase 3 — Detail screens: Verb, Model — ✅ DONE (2026-07-16, uncommitted — awaiting Josh's go-ahead)

Both screens shipped, with one deliberate deviation from the draft: rather than cap the
header to reading width and let the card grid span full iPad width, **the whole content
column is capped to `.readingWidth()` (680) and centered** on both screens. Full-width
conjugation cards read badly on a 13" iPad — a pronoun|form pair uses ~30 % of a 650 pt
card and marooned the rest as dead space — so a centered reading-width column (header,
2-up card grid, and prose all sharing one tidy measure) is the better look and keeps every
left/right edge aligned. The `.readingWidth()` cap is a no-op on iPhone (narrower than 680),
so the compact layout is untouched.

- **`VerbView`** — ✅ added `@Environment(\.horizontalSizeClass)`; the conjugation cards now
  switch to a fixed two-up `LazyVGrid(columns: BrowseLayout.detailColumns, alignment: .leading, spacing: Layout.doubleDefaultSpacing)`
  on regular width and the plain single column on compact, both fed from one shared
  `conjugationCards` `@ViewBuilder` var so they can't drift. `metadataHeader` (leading-aligned
  via the VStack) and the etymology / example / medieval cards ride inside the same
  reading-width column. Verified on iPadOS 26.3 (iPad Pro 11" M5, portrait) with `ser`: two
  columns of accent-bar cards (Presente | Pretérito, …), irregular red highlights intact.
- **`ModelView`** — ✅ added `@Environment(\.horizontalSizeClass)`. ModelView has no stack of
  tense cards (it has a single horizontally-scrollable pronoun-by-tense **grid card**), so the
  2-up treatment lands on the **"verbs using this model"** list instead: a new
  `verbsUsingList` `@ViewBuilder` switches between the adaptive
  `LazyVGrid(columns: BrowseLayout.listColumns)` of `VerbGridCell().card()` (regular) and the
  bare zebra/divider `LazyVStack` of `VerbRowLabel` (compact) — mirroring Browse Verbs. The
  header card, grid card, and list all sit in the centered reading-width column. Verified with
  `rehacer` (2 verbs → `contrahacer` | `rehacer` side by side) and `decir` (1 verb → single
  cell). Note: the reading-width cap makes the grid card's rightmost person column scroll into
  view a touch sooner on long-stemmed models (e.g. `rehiciéramos`); the card was already a
  visible-indicator horizontal `ScrollView` by design, so this is expected, not a clip.

**Verify:** ✅ `ser` and the `rehacer`/`decir` models in portrait on iPad Pro 11" M5
(iPadOS 26.3); the 2-column card masonry aligns and no card is clipped. Landscape/rotate
reflow is guaranteed by the grid geometry (adaptive/flexible columns) but not yet
screenshot-verified — deferred to the Phase 5 QA sweep.

### Phase 4 — Reading / form / modal screens — ✅ DONE (2026-07-16, uncommitted — awaiting Josh's go-ahead)

Cap and center; no grids needed. **Key finding on starting this phase:** five of the seven
target screens were *already* reading-width-capped during the original SwiftUI migration —
`InfoView` (RichTextView `.frame(maxWidth: Layout.readingWidth, alignment: .leading)`),
`QuizView` (both `briefing` + `inProgress`), `ResultsView`, `SettingsView` (already on the
`.readingWidth()` modifier), and `CommunView`'s message column all carry the cap (mostly via
the older `.frame(maxWidth: Layout.readingWidth).frame(maxWidth: .infinity)` literal idiom,
which is functionally identical to `.readingWidth()`). Those were left untouched — they're
already verified and shipped, and re-wrapping working screens just to unify the idiom risked
regressions for no visible gain (Phase 0 item 4 lists that unification as *optional*). So the
actual Phase-4 code change was confined to the three screens that were **not** capped:

- **`TutorView`** — ✅ capped the chat scroll column (`.readingWidth()` on the messages
  `VStack`), the blue divider rule, and the input bar to a centered reading-width measure. The
  input bar's `.readingWidth()` sits **before** its `.background(Color.customBackground)` so
  the controls cap to 680 while the footer background still fills the full width edge-to-edge.
  Chat bubbles' `Spacer(minLength: 60)` now push user/assistant bubbles to the right/left
  edges *of the 680 column* rather than the full iPad width. *Not reachable in the simulator*
  (model unavailable) — code-review + real-device check; mirrors the other caps exactly.
- **`TutorTestView`** — ✅ `.readingWidth()` on the batch-results `VStack`. Same sim caveat.
- **`OnboardingView`** — ✅ `.readingWidth()` on `OnboardingPageView`'s content `VStack`
  (replacing its bare `.frame(maxWidth: .infinity)`), so each welcome/feature sheet's symbol,
  title, body, and CTA sit in a centered ~680 column instead of stretching across the iPad
  canvas. Page dots, Skip/Dismiss, and the animated Get-Started button live in the parent
  `OnboardingView` body and are already centered (dots in a centered `HStack`; the CTAs are
  `PrimaryButtonStyle` capsules that hug their content), so they needed no change. The
  conditional AI-tutor page and game-preview CTA are untouched. Verified first-launch on
  iPad Pro 11" M5 (iPadOS 26.3): the welcome sheet's body copy wraps at a comfortable measure,
  centered, no longer edge-to-edge.
- **`InfoView` / `QuizView` / `ResultsView` / `SettingsView` / `CommunView`** — already capped
  during the migration; no change this phase.

**Verify:** ✅ builds green; **swiftlint 0 violations**; full suite **524 tests / 29 suites
passed**; onboarding visually confirmed capped on iPad Pro 11" M5. Portrait+landscape rotation
sweep and Dynamic Type at large sizes deferred to the Phase 5 QA pass (the cap is a `max`, so
text still wraps within it — a straightforward interaction). Tutor screens await a real
Apple-Intelligence device.

### Phase 5 — Orientation & multitasking QA + screenshots — ✅ DONE *with respect to Claude* (2026-07-16); remaining items are Josh's device/manual work

Split into what Claude can verify in the simulator vs. what genuinely needs a physical
device or a human eye. **Claude's slice is done; the rest is Josh's.**

- ✅ **Full regression on iPhone** — DONE (2026-07-16). Fresh-installed on iPhone 17 (iOS 26)
  and walked every screen the iPad work touched; every size-class branch and `.readingWidth()`
  cap is confirmed **inert at compact width** — the iPhone layout is byte-identical to before.
  Confirmed compact-path renders: `OnboardingView` (symbol/title/body full-width-minus-padding,
  centered), `VerbBrowseView` (single-column list, not grid), `VerbView` (single column of
  full-width cards, not 2-up), `ModelBrowseView` (single-column rows w/ %-pill, not grid),
  `InfoBrowseView` (grouped list + E/E&M/E,M&D control, normal width), `QuizView` (briefing
  centered), `SettingsView` (full-width cards). The bottom tab bar renders the custom
  `dancer`/`bull` line-art tabs correctly throughout, and the Tutor row correctly reports
  "Apple Intelligence is still getting ready" (unavailable in-sim). Two non-defects: `ModelView`
  wasn't opened directly (its rows wouldn't navigate under AXe's synthetic taps — an AXe/HID
  quirk, not an app bug; covered by pattern since it shares `VerbView`'s idiom + a
  `VerbBrowseView`-style verbs list), and `TutorView` is unreachable in-sim (model unavailable).
- ⬜ **Device matrix (Josh):** iPad Pro 11" and 12.9"/13", iPad mini (narrowest regular width),
  iPad (A16). Each: **portrait + landscape**, plus **rotate mid-screen** on every screen.
- ⬜ **Multitasking (Josh):** Split View (½ and ⅓ widths → should degrade to compact/phone
  layout), Stage Manager (arbitrary window sizes, including narrow → compact).
- ⬜ **Widget gallery previews (Josh)** at iPad sizes (item 15 calls this out): confirm the
  small / medium / large widget previews render correctly in the iPad widget gallery.
- ⬜ **App Store iPad screenshots (Josh)** once the screens land (device-captured, per the
  simulator emoji-tofu caveat for the game's stage-1 flags).

---

## 4. Verification tooling

- Use **`ios-build-verify`** for build/launch, but drive an **iPad** simulator so you don't
  collide with the other session's iPhone sim. This session verified end-to-end on
  **iPad Pro 11" (M4), iPadOS 26.x** — install the `Debug-iphonesimulator` build onto the
  iPad sim and `simctl launch` (the app requires iPadOS 26; iPadOS-18 iPad sims will reject
  install with "Requires a Newer Version of iPadOS").
- **Rotation:** `simctl` has no direct rotate; rotate via the Simulator UI (⌘→/⌘←) or
  `Device ▸ Rotate`, or script it with `osascript` against the Simulator app. Capture with
  `xcrun simctl io <udid> screenshot`.
- Deeplinks (`conjugar://verb/ser`, `conjugar://quiz/start`, `conjugar://game`) still jump
  straight to screens for fast per-screen checks.
- The `browse_verb_count` accessibility identifier remains the launch-render anchor — don't
  remove it when reworking `VerbBrowseView`.

---

## 5. Coordination note

Another session is implementing **item 14 (the olé glyph)**, which is confined to
`GameView.swift` + boss-dance assets — **no overlap** with this iPad work (this plan
never touches `GameView`). The only shared files this plan edits that anything else might
touch are `Utils/Layout.swift` and `Utils/Modifiers.swift` (Phase 0 additions) and
`MainTabView.swift` (Phase 1) — all additive. Launch the **iPad** simulator here; the other
session's iPhone simulator is independent. If a build breaks for reasons unrelated to this
plan's diffs (e.g. an in-flight change from the other session), flag it to Josh rather than
working around it.

---

## 6. Suggested commit sequence

1. ✅ Phase 0 shared components (`BrowseLayout`, `readingWidth(alignment:)`, grid cell) — no UI change. (`fb08e9b`)
2. ✅ Phase 2a — `VerbBrowseView` grid (the flagship visual win). (`1b45fe8`)
3. ✅ Phase 2b — `ModelBrowseView` grid. (`0c5ab81`)
4. ✅ Phase 2c — `InfoBrowseView` reading-width grouped list. (`796fd26`)
5. ✅ Phase 3 — `VerbView` + `ModelView` detail 2-up. (`8ce8439`)
6. ✅ Phase 4 — reading-width caps across Tutor/TutorTest/Onboarding (Info/Quiz/Results/Settings/Commun were already capped from the migration). (`e10bbe9`)
7. ✅ Phase 1 shell decision — **no code change** (keep the top-bar `TabView`; do NOT adopt `.sidebarAdaptable`). (`a975ba6`; docs only.)
8. ✅ Phase 5 — QA sweep. **iPhone regression done by Claude** (no code change); iPad device matrix / multitasking / widget-gallery / App Store screenshots remain Josh's device/manual work. (2026-07-16; docs only.)

Keep item 15's heading and step 9 in `code-review-recommendations-2.md` marked in
progress; flip to ✅ only when the full per-screen audit ships and the App Store iPad
screenshots are captured.
