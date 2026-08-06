# Conjugar Code Review (round 2)

Please do a thorough review of the **recent additions** to the Conjugar codebase. Look for
bugs, code smells, incorrect conjugation logic, code duplication, deprecated/outdated API
use, concurrency gotchas, inelegant code, and any other shortcomings. Output your findings
as a ranked Markdown file (details below). **Review only — produce the document; do not
modify app code.**

## Scope

Conjugar was already reviewed by Fable on July 7, 2026. That review lives at
`prompts/code-review-recommendations.md`, and I implemented all of its recommendations. This
round targets what has changed **since** that review — roughly 90+ commits.

To be clear up front, this is not a redundant pass. Most of the app's highest-risk code
landed *after* July 7 and has never been reviewed: the game **La Subida** (a five-stage
climb), the **boss fight**, the **onboarding** flow, and the settings rework. So expect this
to be a first look at a large body of new code, not a re-check of what you saw last time.

- Diff the delta with `git diff f8d5714..HEAD` (the prior review's implementation wrapped up
  around `f8d5714`; the working branch is `migration`).
- **Read `prompts/code-review-recommendations.md` first**, for two reasons: (1) match its
  format and severity rubric, and (2) do **not** re-report items it already covered and I
  already fixed. You are still free to flag anything that earlier pass missed.
- The largest new subsystems — where the risk concentrates — are: the game **La Subida**
  (`GameState` and its extensions `+Obstacles`, `+Stages`, `+PowerUps`, `+Mechanics`), the
  **boss fight** (`GameState+BossFight`), **onboarding** (`Views/OnboardingView.swift` and
  its wiring), and any conjugation-engine changes. CLAUDE.md's "Running the App in the
  Simulator" section documents the game's deeplinks and debug env vars if you want to drive
  it.

## Deliverable

Write your findings to **`prompts/code-review-recommendations-2.md`** (do not overwrite the
prior review). Rank items highest impact → lowest, using the same impact rubric as the prior
review: **user-visible correctness first, then crash/concurrency risk, then code health,
then modernization and polish.** For each item: cite evidence as `file:line`, explain why it
matters, sketch a fix, and label your confidence — **confirmed** vs. **suspected**. Prefer
tracing the actual code path over pattern-matching, and exercise the app via the
ios-build-verify skill when a behavioral claim needs proof. At the bottom, propose an
implementation sequence (group related items, note dependencies, flag which are mechanical
vs. risky).

> **On line references:** `file:line` citations are accurate only as of the moment this
> document is written. They will drift as items are implemented, so treat each one as a
> starting pointer, not a durable address — confirm by symbol/surrounding context before
> editing. Please state this caveat near the top of your output, too, since the reader will
> be working through the list as the code shifts underneath it.

## Establish a baseline first

Build and run the full suite before reviewing (ios-build-verify skill; the prior review's
baseline was 403 tests / 17 suites / 0 failures, SwiftLint 0 violations). A green baseline
means any new failure is real signal. Two things not to trip on, both documented in
CLAUDE.md: editing view files spams SourceKit false positives (`Cannot find 'X'`, `has no
member`) — xcodebuild is authoritative, don't chase them; and write any new tests as Swift
Testing, not XCTest (the XCTest + MainActor isolated-deinit landmine).

## Conjugation correctness

This is the highest-value and hardest dimension. The engine has a verified oracle at
`docs/spanish_models.md` and Swift Testing suites (`ConjugatorTests`,
`ConjugatorAccessorsTests`, `ConjugatorResolverTests`, `VerbMapTests`, `TenseBridgeTests`).
Spot-check tricky cases **against the oracle** rather than by eye: irregular families,
homonyms, defectives, compound tenses, imperativo negativo, and voseo.

## Intentional — do not flag

- The `ModelBrowseView` / `VerbBrowseView` duplication is deliberate.
- `AnalyticsServiceSpy` is the only analytics implementation on purpose (a TelemetryDeck-
  backed real conformer is planned). **Adding TelemetryDeck is the one remaining feature and
  is already planned — do not spend the review recommending it.**
- Legacy asset names are intentional: `flamencoLoop.mp3` (holds a different track now) and
  the `CONJUGAR_GAME_DISABLE_FLAGS` env var / `debugFlagsDisabled` (a documented external
  contract).
- `TutorTestView` ships without `#if DEBUG` deliberately.
- Jaleo shouts and title cards are intentionally Spanish in **both** localizations.
- The conjugation engine is `nonisolated`-by-design (see CLAUDE.md's concurrency model).

## Context

I created Conjugar in 2017 with UIKit. Recently I converted it to SwiftUI, added a new
composition-based conjugation engine, thousands of verbs, and several features (the game,
onboarding, the on-device tutor). Conjugar is largely code-complete; the only feature left
to add is TelemetryDeck analytics. When this migration branch is done, I'll merge to master
and ship a new version.

Conjugar has sibling apps — Conjuguer (French) at `/Users/josh/Desktop/workspace/Conjuguer`
and Konjugieren (German) at `/Users/josh/Desktop/workspace/Konjugieren`. Conjugar need not
match their implementations, but they may offer inspiration. **Do not review the siblings as
part of this task** — both have been quiescent since their own Fable reviews.

You're running on Fable. You wrote the plans for Conjugar's game and boss fight (both now
implemented) and the prior code review. There have been many additions since that review, so
there should be real findings to surface.
