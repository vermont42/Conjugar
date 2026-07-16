# Native iPad Support — Implementation Plan (item 15 / step 9)

**Status:** in progress. **Phase 0** (shared components) and **Phase 2a**
(`VerbBrowseView` grid) are ✅ done (2026-07-16, commits `fb08e9b` + `1b45fe8` on
`migration`). Everything else is still to do.
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

### Phase 1 — Navigation shell + search + covers audit

Mostly verification; the shell already top-bars on iPadOS 26.

- **Confirm the top tab bar renders correctly** with Conjugar's **custom `dancer`/`bull`
  image tabs** and the `.symbolVariants(.none)` symbol tabs. The sibling apps use only
  stock SF Symbols in the bar; verify the custom line-art bitmaps look right in the iPad
  top bar (and in the sidebar, if you adopt `.sidebarAdaptable`).
- **Decide on `.tabViewStyle(.sidebarAdaptable)`.** Conjuguer uses it (gives the
  sidebar-toggle affordance + expandable sidebar); Konjugieren doesn't. Try it; if the
  custom tab bitmaps render cleanly in a sidebar and the sidebar adds value for 5 tabs,
  keep it — otherwise leave the shell as-is (it already looks correct). Either is parity.
- **Search placement:** `.searchable` is already on the Verb/Model stacks; confirm it
  lands in the top-bar on iPad in both orientations. No code change expected.
- **Re-check the two `.fullScreenCover`s at iPad size:** `OnboardingView` (welcome content
  currently floats tiny at the top — see Phase 4) and `CommunView`. A full-screen cover on
  iPad is genuinely full-screen; both need width-capped, centered content.

**Verify:** launch on iPad, tap through all five tabs portrait + landscape; open a
`conjugar://` deeplink to confirm routing still works; trigger onboarding
(`conjugar://` cold launch / reset `hasSeenOnboarding`).

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
- **`ModelBrowseView`** — same treatment (it mirrors `VerbBrowseView`; the review's
  Browse/Model mirroring carve-out means keep them structurally parallel).
- **`InfoBrowseView`** — the grouped sections (About / Concepts-Voseo / Tenses + the
  Conjugation-Tutor row + the tense-detail `E / E&M / E,M&D` segmented control). Two
  viable directions, pick per how it looks:
  - **Grid of section cards** (Conjuguer's Info approach): each section a `LazyVGrid` of
    tappable cards under a section header. Richer, fills the width.
  - **Reading-width grouped list** (Konjugieren's Info approach): keep the grouped `List`
    but cap it to `.readableWidth()` so rows aren't absurdly long.
  Keep the Tutor availability row behavior and the tense segmented control intact.

**Verify:** all three lists in both orientations; confirm ≈2 columns portrait / ≈3–4
landscape via adaptive sizing; half-width Split View falls back to the single-column list;
search still filters; sort still animates + haptics.

### Phase 3 — Detail screens: Verb, Model

- **`VerbView`** — header block (title, gloss, metadata pills) stays single-column and
  should be `.readableWidth(alignment: .leading)`-capped so the pills don't drift miles
  right. The **conjugation cards** switch to the fixed two-up:
  `if horizontalSizeClass == .regular { LazyVGrid(columns: BrowseLayout.detailColumns, alignment: .leading, spacing: Layout.tripleDefaultSpacing) { conjugationCards } } else { VStack { conjugationCards } }`
  where `conjugationCards` is one `@ViewBuilder` var emitting every `ConjugationText`
  card, reused by both branches. The etymology / example-use / medieval cards below stay
  full single cards but capped to reading width (or spanned across — decide visually).
- **`ModelView`** — same 2-up treatment for its rule/paradigm cards; keep the "verbs using
  this model" list (which reuses `VerbRowLabel`) as its own size-class grid switch
  (Konjugieren re-applies the list grid inside detail sub-lists).

**Verify:** `ser`, `haber`, a regular verb, and a compound-heavy verb in both
orientations; confirm the 2-column masonry aligns and no card is clipped; rotate
mid-screen (the geometry is grid-driven so it should reflow cleanly, unlike the game).

### Phase 4 — Reading / form / modal screens

Cap and center; no grids needed.

- **`InfoView`** — the rich-text article body → `.readableWidth(alignment: .leading)`
  (this is the single most important reading-width fix; Info bodies are the longest text).
- **`QuizView` + `ResultsView`** — cap the prompt / text field / results to reading width
  and center; on iPad the answer field currently stretches full-width. Keep the keyboard
  behavior working in both orientations.
- **`SettingsView`** — cap the form/cards column to reading width and center so toggles
  and the app-icon picker aren't a 1366-pt-wide row.
- **`TutorView`** (+ `TutorTestView`) — cap the chat column to reading width, centered
  (chat bubbles at full iPad width read badly). *Not reachable in the simulator* (model
  unavailable), so this is a code-review + real-device check; keep it minimal and mirror
  the other reading-width caps.
- **`OnboardingView` cover** — center the paged content and cap its width so the welcome /
  feature sheets sit in a centered column instead of pinned to the top of an empty canvas;
  keep the page dots + Skip/Get-Started. Verify the conditional AI-tutor page and the
  game-preview CTA still work.
- **`CommunView` cover** — cap + center the message.

**Verify:** each screen portrait + landscape; Dynamic Type at a large size (reading-width
cap must coexist with larger text — the cap is a max, text still wraps within it).

### Phase 5 — Orientation & multitasking QA + screenshots

- **Device matrix:** iPad Pro 11" and 12.9"/13", iPad mini (narrowest regular width), iPad
  (A16). Each: **portrait + landscape**, plus **rotate mid-screen** on every screen.
- **Multitasking:** Split View (½ and ⅓ widths → should degrade to compact/phone layout),
  Stage Manager (arbitrary window sizes, including narrow → compact).
- **Widget gallery previews** at iPad sizes (item 15 calls this out): confirm the small /
  medium / large widget previews render correctly in the iPad widget gallery.
- **App Store iPad screenshots** once the screens land (device-captured, per the
  simulator emoji-tofu caveat for the game's stage-1 flags).
- Full regression on **iPhone** (all the size-class branches must leave compact untouched).

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
3. Phase 2b — `ModelBrowseView` grid.
4. Phase 2c — `InfoBrowseView`.
5. Phase 3 — `VerbView` + `ModelView` detail 2-up.
6. Phase 4 — reading-width caps across Info/Quiz/Results/Settings/Tutor/Onboarding/Commun.
7. Phase 1 shell decision (sidebarAdaptable or not) — small, can land anytime.
8. Phase 5 — QA sweep + screenshots (no code, or tiny fixups).

Keep item 15's heading and step 9 in `code-review-recommendations-2.md` marked in
progress; flip to ✅ only when the full per-screen audit ships and the App Store iPad
screenshots are captured.
