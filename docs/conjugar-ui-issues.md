# Conjugar UI Issues — Mapped from the Sibling Audits (SwiftUI Migration, Step 2)

_Produced for Step 2 of `prompts/ui_claude.md`. Conjugar's UIKit UI is nearly identical to
the **pre-improvement** UI of its siblings **Konjugieren** (German) and **Conjuguer**
(French), both of which have already been audited and improved with the
`ios-design-agent-skill`. Rather than re-audit a UI we are about to delete, this document
**maps** those existing findings onto Conjugar's concrete screens, and adds a **fresh
audit only** for the screens the siblings lack or lay out differently — chiefly the
**Models** tab and the **Commun** messaging modal._

**Source audits (cross-reference keys used below):**

- **K#** → Konjugieren, `Konjugieren/docs/ui-audit.md` (24 numbered items).
- **C#** → Conjuguer, `Conjuguer/docs/conjuguer-ui-issues.md` (30 numbered items, six-run
  synthesis; the more complete list, already batched A–F).

**Before-screenshots** (current UIKit UI, `docs/screenshots/`, git-ignored — captured with
the `run-in-simulator` skill, iPhone 17 / iOS 26):

| # | Screen | Dark | Light |
|---|--------|------|-------|
| Browse Verbs (`BrowseVerbsVC`) | verb list | `01-browse-verbs-dark.png` | `11-browse-verbs-light.png` |
| Verb detail (`VerbVC`) | conjugation list | `02-verb-detail-dark.png` | _(see light verb detail in run)_ |
| Browse Models (`BrowseModelsVC`) | model list | `03-browse-models-dark.png` | — |
| Model detail (`ModelVC`) | grid + verbs-using | `04-model-detail-dark.png` | — |
| Quiz not-started (`QuizVC`) | Start screen | `05-quiz-notstarted-dark.png` | — |
| Quiz in-progress (`QuizVC`) | question screen | `06-quiz-inprogress-dark.png` | `12-quiz-inprogress-light.png` |
| Browse Info (`BrowseInfoVC`) | topic list | `07-browse-info-dark.png` | — |
| Info detail (`InfoVC`) | article | `08-info-detail-dark.png` | — |
| Settings (`SettingsView`, already SwiftUI) | preferences | `09-settings-dark.png` | `10-settings-light.png` |

> **Not screenshotted:** the **Results** screen (`ResultsVC`) — reaching it means finishing
> a 50-question quiz — and the **Commun** modal (`CommunVC`), which only appears CloudKit-
> driven at launch. Both are audited from source below.

---

## Screen inventory & tab structure

Conjugar has **five** tabs (one more than the siblings' four — it splits Browse into
**Verbs** and **Models**):

1. **Browse** — `BrowseVerbsVC` → `VerbVC`
2. **Models** — `BrowseModelsVC` → `ModelVC`  ← _Conjugar-specific layout; fresh audit_
3. **Quiz** — `QuizVC` → `ResultsVC`
4. **Info** — `BrowseInfoVC` → `InfoVC`
5. **Settings** — SwiftUI `SettingsView`

`CommunVC` is a modally-presented messaging popup, not a tab.

The four verb/quiz/info/settings tabs map 1:1 onto the siblings; the **Models** tab is
Conjugar's own (Conjuguer has a Models browser too, but its layout differs — see §Models).

---

## Foundations (build these first — everything else leans on them)

Both sibling audits open with the same lesson: **a handful of shared design-system
primitives unlock most of the screen-level fixes**, so build them first (Conjuguer's
"Batch A", Konjugieren's "Cross-Cutting Design System Addition"). Conjugar's Step 1 already
laid part of this groundwork; here is the gap:

| Primitive | Sibling ref | Status in Conjugar today | Action |
|-----------|-------------|--------------------------|--------|
| **Surface / card color** | K "surface color", C9 | ✅ `customCardBackground` + `customCardBorder` colorsets **already exist** (added Step 1) | Add a `.card()` modifier (`Modifiers.swift`) — padding + `RoundedRectangle` fill w/ `customCardBackground`, `customCardBorder` stroke, optional leading accent bar. This one modifier unlocks the quiz card, conjugation section cards, settings grouping, results summary card. |
| **Brand-colored title modifier** | C12 | ⚠️ `HeadingLabel` already sets `.foregroundStyle(Color.customYellow)` — Conjugar's titles are already colored (unlike Conjuguer's, which weren't). **No drift to fix.** | Keep; just make sure the SwiftUI ports route titles through `HeadingLabel`. |
| **`customGreen` "correct" color** | C23 | ❌ No green. Red is currently overloaded: primary CTA (Start), destructive (Quit), links (Enable/Rate), **and** error/irregularity. | Add a `customGreen` colorset (light + dark) so "correct" gets its own semantic and red can retreat to error/irregularity. Give primary CTAs the yellow/accent tint, not red. |
| **Centralized `.sensoryFeedback` on the quiz** | K10, C4 | ❌ Zero haptics anywhere (the app *does* already play sounds + speak). Gap is **tactile + visual**, not feedback in general. | Wire `.sensoryFeedback(.success/.error, trigger:)` into the SwiftUI quiz. |
| **Numeric text style** | K6, C5 | ❌ Score/progress/elapsed are plain proportional text that jitters as they tick. | `.contentTransition(.numericText())` + `.monospacedDigit()` helper for the changing counts. |

> **Palette note:** Conjugar's Step 1 shipped 8 colorsets: `customBackground`,
> `customForeground`, `customCardBackground`, `customCardBorder`, `customRed`,
> `customYellow`, `customBlue`, `AccentColor` — all light/dark. The only **new** color the
> audit calls for is `customGreen`. `customCardBackground` already serves the siblings'
> `customSurface` role, so C9's "add a surface token" is **half-done**.

---

## Mapped findings — by screen

Each item cites the sibling audit item(s) it derives from. "Direct" = applies as-written;
"Adapted" = same problem, Conjugar-specific wording.

### 1. Quiz — not-started screen  (`QuizVC`, screenshot 05)

The marquee finding, raised 6/6 in both siblings. Conjugar's not-started quiz is **~90%
empty black** with a corner "Quiz" title and a lone red **Start** text button pinned just
above the tab bar (screenshot 05 is almost entirely void).

- **Fill the barren screen with a briefing.** _(C3 direct, K1 partial)_ Center a short
  description + the active difficulty (`Current.settings.difficulty`), the region, "50
  questions" (Conjugar quizzes are **50**, per screenshot 06 — not 30), and the best score
  (Game Center is wired). Compose **Start** into it as a clear primary CTA, not a stray
  text button.
- **Fix the Start-button styling / truncation risk.** _(C6 direct)_ Start is a bare red
  `StandardButton` label. Give it a real filled/capsule button style; add
  `.lineLimit(1).minimumScaleFactor(0.7)` so large Dynamic Type doesn't clip "Start".
- **Gate / soften the pulse.** _(C25, K2 partial)_ `startRestartButton.pulsate()` runs a
  continuous scale animation with **no Reduce-Motion guard**. Gate it behind
  `@Environment(\.accessibilityReduceMotion)`; consider `.symbolEffect(.pulse)` on a lead
  glyph instead of scaling the whole button.

### 2. Quiz — in-progress screen  (`QuizVC`, screenshots 06 / 12)

Highest time-on-screen; weakest layout. Seven near-identical labeled rows
(Verb / Pronoun / Tense / Progress / Score / Elapsed) over a **bare, borderless**
"conjugation" text field floating in empty space.

- **Make the answer field visible + focus ring.** _(C1 direct, 6/6)_ The single most-used
  control is an invisible borderless `UITextField` — just a gray "conjugation" placeholder
  and a cursor (screenshots 06/12). Give it a filled `RoundedRectangle` container
  (`customForeground` at ~6%) with a focus-tinted border.
- **Give the question a hierarchy distinct from the metadata.** _(C2 direct, K1)_ Make the
  verb the hero (heading weight), fold pronoun · tense into one emphasized ask, demote the
  translation to a subtitle, and push Progress / Score / Elapsed into one compact,
  de-emphasized status strip.
- **Frame the quiz in a card + progress bar.** _(K1 direct)_ Wrap the active content in a
  `.card()`; add a real `ProgressView(value:total:)` bar in place of the "1 / 50" text.
- **Add haptics + unmissable answer feedback.** _(C4 direct, K2)_ Today the only feedback
  is sound (`chime`/`chirp`/`buzz`) + the tiny "Last / Correct" reveal
  (`quizView.last`/`correct`). Add `.sensoryFeedback(.success, trigger:)` /
  `.sensoryFeedback(.error, trigger:)` and a brief `checkmark.circle.fill` /
  `xmark.circle.fill` flash; reserve a fixed-height slot so the reveal doesn't shove the
  question.
- **Stabilize the changing numbers.** _(C5 direct, K6)_ `.contentTransition(.numericText())`
  on Score / Progress / Elapsed so the layout stops jittering per tick.
- **Move Quit into the toolbar.** _(K1)_ Quit is a floating red word top-right; make it a
  `.toolbar { ToolbarItem(placement: .cancellationAction) }` (or `.destructive` role).
- **Fix the "Tense:" prefix inconsistency.** _(fresh, minor)_ `viewWillAppear` sets the
  tense label to a bare `tense.displayName` while `questionDidChange` prefixes it with
  "Tense: " — so the label reads "Tense: futuro…" mid-quiz but "futuro…" on return
  (compare screenshots 06 vs 12). The SwiftUI rebuild should pick one.
- **Revisit the Dynamic-Type cap.** _(C24)_ If any quiz label caps Dynamic Type to protect
  the fixed layout, raise/remove the ceiling once the quiz is a scrollable card.

### 3. Quiz — Results screen  (`ResultsVC`, not screenshotted; audited from source)

`ResultsVC` shows a header (difficulty / region / score / time) over a table of
`ResultCell`s (verb, tense, personNumber, correctAnswer, proposedAnswer).

- **Hero score + semantic correctness color.** _(C7 direct, K6)_ The score is just another
  labeled line. Promote it to a large rounded numeral, color-coded by performance
  (green >80% / yellow 50–80% / red <50%, using the new `customGreen`), and animate it up
  with `.contentTransition(.numericText())`.
- **Label + color each result row.** _(C7 direct)_ Each `ResultCell` should left-align,
  label the two answers ("Your answer" / "Correct"), and color the ✓/✕ by outcome
  (green/blue correct, red wrong) instead of one flat color for both.
- **Frame the summary in a card** separated from the scrollable list. _(C7, K6)_

### 4. Verb detail  (`VerbVC`, screenshot 02)

Metadata rows (have / Irregular / tenido / teniendo / RF: tendr- / Not Defective) over a
**single left-aligned column** of conjugations grouped by red tense headings.

- **Conjugation section cards + accent bars.** _(K3 direct, C18)_ Wrap each tense section
  (`ConjugationDataSource`'s grouped rows) in a `.card()` with a leading accent bar so
  "Presente de Indicativo", "Pretérito", … stop blending into one dense ribbon
  (screenshot 02).
- **Two-column conjugation layout.** _(C8 direct, 6/6)_ Render each tense as a
  pronoun | form `Grid`, keeping the red-irregularity `AttributedString` in the form cell,
  instead of the single "yo tengo / tú tienes" column that uses ~40% of the width.
- **Metadata pills.** _(K12 direct)_ Give the top metadata (gloss, Irregular/parent,
  participio, gerundio, RF, defective) pill-shaped tinted backgrounds instead of four bare
  corner labels.
- **Serif for linguistic content.** _(K9, C-cross)_ Set the infinitive title and the
  Spanish conjugation forms in `.fontDesign(.serif)` to distinguish "language" from "UI
  chrome".
- **Speak-on-tap flash.** _(K11)_ `VerbVC` already speaks a form on tap (`tapSpanish`);
  add a brief background flash to confirm the tap landed.
- **Empty-state / no fresh issue for search** — `VerbVC` is a detail screen; the
  empty-state item belongs to the list (§6).

### 5. Verb detail — irregularity color legend  (cross-cuts Verb + Model)

- **Document the red color code.** _(C10 direct)_ Conjugar's best idea — irregular
  spans/endings in `customRed` (screenshots 02, 04) — is unexplained at point of use. Add a
  dismissible inline legend on first conjugation view (`@AppStorage` "seen" flag) or a short
  Info article, linked from the existing "Irregularities"/"Terminology" Info entries.

### 6. Browse Verbs list  (`BrowseVerbsVC`, screenshots 01 / 11)

Already the **strongest** current screen — it has two-line cells (infinitive + gloss) and a
`#N` frequency rank, which is more than Conjuguer's list had (it lacked scent entirely,
C13). So several sibling list items are **already satisfied**. Remaining:

- **Empty-state view.** _(K8 direct)_ If a search/filter ever yields nothing, show a
  `ContentUnavailableView` (magnifyingglass) instead of a blank list. _(Note: the current
  Browse list has no search bar — confirm whether the SwiftUI version adds one; if so, this
  applies.)_
- **Animate the sort change.** _(K13, C19)_ Frequency⇄Alphabetical currently snaps
  (`reloadTableData`). Wrap the reassignment in `withAnimation(.snappy)` and add
  `.sensoryFeedback(.selection, trigger: sort)`.
- **Verb-count banner.** _(K14)_ A compact "4,811 verbs" header in small-caps to convey
  scale.
- **Already done, keep:** two-line cell w/ gloss (C13), frequency rank badge (K22).

### 7. Browse Info list  (`BrowseInfoVC`, screenshot 07)

Flat list of centered topic rows (Purpose & Use, Terminology, per-tense explainers) with a
"Filter Tenses by Difficulty" segmented control (E / E&M / E,M,&D) pinned at the bottom
(screenshot 07).

- **Section the list.** _(C21 direct)_ Group into `Section("About")` (Purpose & Use,
  Terminology) / `Section("Tenses")` (the per-tense explainers) so references are findable.
- **Left-align the rows.** _(fresh, cf. C11)_ The topic titles are **centered** (screenshot
  07) — a `List`/leading layout reads better and matches iOS convention.
- **Distinct treatment for the difficulty filter.** The bottom segmented control is
  disconnected from the list it filters; in SwiftUI make it a labeled control (or move it to
  a toolbar/section header) so its relationship is clear.

### 8. Info detail  (`InfoVC`, screenshot 08)

Yellow title, a subheading, and a **full-width gold body** with bold inline terms and the
rich-text markup (`^…^`, `~…~`, `$…$`, `%…%`).

- **Serif title + reading width.** _(K4 direct, C22)_ Set the heading in `.fontDesign(.serif)
  .font(.largeTitle.bold())`, constrain body to `maxWidth: ~680` centered for iPad/large
  type, and add `.lineSpacing(4)`.
- **Reconsider all-gold body text.** _(fresh)_ The entire article body renders in gold
  (screenshot 08), which is heavy for long-form reading; consider `customForeground`
  (adaptive primary) for body copy and reserve gold for headings/emphasis. Verify the
  SwiftUI rich-text renderer keeps the four markers (`^`, `~`, `$`, `%`) — see the markup
  table in `CLAUDE.md`.
- **Distinct treatment for interactive rows.** _(K16)_ N/A today (Conjugar has no Tutor
  row); skip.

### 9. Settings  (`SettingsView`, already SwiftUI, screenshots 09 / 10)

Already SwiftUI, so this is the **reference pattern** for the migration — but it still has
the siblings' pre-improvement issues:

- **Left-align the section headers.** _(C11 direct)_ The title is centered and every section
  header (Region, Difficulty, Browse Tú/Vos, Quiz Tú/Vos, Game Center) is **centered**
  (screenshots 09/10) — wrap the scroll content in
  `VStack(alignment: .leading){…}.frame(maxWidth:.infinity, alignment:.leading)`.
- **Group each setting into a card.** _(K5 direct, C11)_ Wrap each setting + its description
  in `.card()` so the one long undifferentiated scroll gains rhythm.
- **Unify the "action" link color.** _(C11, C23)_ "Enable" (Game Center) renders in red
  (screenshot 09) — an action link, not an error. Once `customGreen`/CTA colors land,
  reserve red for destructive and give links a consistent non-red tint.
- **Replace any dot-pattern separators** with a thin gradient rule. _(K5)_

---

## Fresh audit — Conjugar-specific screens

### 10. Model detail  (`ModelVC`, screenshot 04)  ⚠️ contains a real layout bug

This screen has no direct sibling equivalent (Conjuguer's `ModelView` uses an endings grid,
not a full conjugation grid). It shows: a header (exemplar, "Model 28 · 82% irregular",
gloss, participio/gerundio), a **conjugation grid** (tense rows × pronoun columns), a
"verbs using this model" count, and a list of those verbs.

- **🔴 The conjugation grid overflows the screen and clips.** _(fresh, high)_ The grid lays
  out six pronoun columns (yo / tú / él / nosotros / vosotros / ellos) at a fixed width, but
  **only ~4 fit** — screenshot 04 shows "nosotr…", "decim…", "digam…" hard-cut at the right
  edge with **no horizontal scroll and no truncation affordance**. The last two persons
  (vosotros, ellos) are entirely invisible. The SwiftUI rebuild must either make the grid
  horizontally scrollable, shrink to fit (`minimumScaleFactor`/`ViewThatFits`), or restructure
  (e.g. pronoun rows within each tense) so all six persons are reachable.
- **Badge the irregularity percent.** _(adapted from C15)_ "Model 28 · 82% irregular" and the
  list's inline "82%" (screenshot 03) should be a tinted `Capsule` badge, its tint scaled by
  the percentage.
- **Lighten the heavy header.** _(C15)_ The stacked exemplar / model# / gloss / participio /
  gerundio lines form a dense gold slab; demote secondary lines to subheadings and card the
  block.
- **Card the grid + verbs-using list** with `.card()` for separation.
- **Serif the Spanish forms** in the grid, consistent with §4.

### 11. Browse Models list  (`BrowseModelsVC`, screenshot 03)

Two-line cells (exemplar + class number) with an irregularity "82%" on the right; sort
control Irregularity / Alphabetical / Number.

- **Badge the "82%".** _(C15 direct)_ Render the trailing percent as a tinted capsule, not
  plain blue text.
- **Animate the sort change + haptic.** _(K13, C19)_ As with the verb list.
- **Empty-state** if a filter yields nothing. _(K8)_

### 12. Commun messaging modal  (`CommunVC`, not screenshotted; audited from source)

A CloudKit-driven modal popup (`CommunUIV`) with a title, body content, an image, and up to
four buttons (close / okay / cancel / action) whose visibility depends on the message
`type` (information / newVersion / email / website). No sibling equivalent.

- **This is the lowest-priority screen** — rarely seen, server-driven. When migrating (Step
  4 item 4), reproduce it as a SwiftUI `.sheet`/`.alert`-style presentation.
- **Card the content + adopt the design system.** Route its title through `HeadingLabel`,
  body through the body style, buttons through a single button style (not four ad-hoc
  buttons); apply `customCardBackground` so it reads as a surface. _(cf. C9)_
- **Give it a discoverable dismiss.** _(cf. C16)_ Ensure the close affordance is obvious
  (toolbar Done / visible X), since it's presented modally.
- **Fix the image fallback.** `CommunViewModel.image` defaults to an empty `UIImage()` when
  absent — in SwiftUI, conditionally omit the image view rather than render an empty frame.

---

## Cross-cutting (apply opportunistically during the screen migrations)

- **`.fontDesign(.serif)` for linguistic content** — verb infinitives, conjugation forms,
  tense headings, article titles. _(K9, C-cross)_
- **`.sensoryFeedback()`** — success/error in Quiz, `.selection` on every sort control.
  _(K10, C4/C19)_
- **Card everything cardable** once `.card()` exists — quiz, verb sections, model header,
  results summary, settings groups, info-list sections. _(K "surface color", C9)_
- **Retire the last hardcoded blacks** — Step 1 already made `Colors.swift` adaptive, but
  confirm no ported view reintroduces `Color.black`. _(K "surface", C9)_
- **`timeString` format** — verify the in-quiz "Elapsed: 3" and the results "Time: 1:25"
  share one sub-minute format. _(C20 — Conjugar shows "Elapsed: 3" in screenshot 06 and
  "1:25" in 12; the difference there is just <60 s vs ≥60 s, but confirm the <60 s branch
  reads as "0:03" not "3".)_
- **Scroll-edge fades** on long reference lists (Verb/Model), Reduce-Motion-safe. _(K19,
  C28)_

---

## Migration sequencing (ties this audit to Step 4 of the plan)

Step 4's suggested order, annotated with the mapped items each screen carries:

| Order | Screen(s) | Carries |
|-------|-----------|---------|
| **0 (foundations)** | `Modifiers.swift`, `Assets.xcassets` | `.card()`, `customGreen`, sensory-feedback + numeric-text helpers |
| **1** | Info (`BrowseInfoVC` → list, `InfoVC` → detail) | §7, §8 — mostly text; exercises rich-text markup |
| **2** | Browse lists (`BrowseVerbsVC`, `BrowseModelsVC`) | §6, §11 |
| **3** | Detail screens (`VerbVC`, `ModelVC`) | §4, §5, §10 — **incl. the Model-grid overflow bug** |
| **4** | `CommunVC` | §12 |
| **5** | Quiz (`QuizVC` → `ResultsVC`) — last | §1, §2, §3 — the marquee redesign, on the Step-0 `@Observable Quiz` |

`SettingsView` (§9) is already SwiftUI — improve it in place as the reference pattern, and
delete/rewrite each replaced VC's test as Swift Testing per Step 4 (this retires the five
crashing UIKit XCTest suites).

---

_This document is the mapping deliverable of Step 2. It is not exhaustive line-by-line —
the sibling audits hold the full rationale for each K#/C# item; consult
`Konjugieren/docs/ui-audit.md` and `Conjuguer/docs/conjuguer-ui-issues.md` for the "why"
behind any mapped item._
