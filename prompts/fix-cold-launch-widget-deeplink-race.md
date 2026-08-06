# Plan: check for (and fix) the cold-launch widget-deeplink race

## Origin

Conjuguer (the French sibling) had this bug: **force-quit the app, then tap a
Verb-of-the-Day widget → the app opened to the verb *browse* list instead of the
individual verb view.** Tapping the same widget after merely *backgrounding* the app
worked correctly. Fixed in Conjuguer commit `1f359d4`.

### Why it happened in Conjuguer

1. `ConjuguerApp` shows a `.loading` / `.loaded` state and kicks off
   `await verbData.load()` in a `.task`. The heavy XML parse of ~6,300 verbs runs
   **off the main actor** (`Task.detached`), so `Verb.verbs` is momentarily empty at
   launch.
2. On a cold launch the widget's `.widgetURL` is delivered through `.onOpenURL` →
   `World.handleURL(_:)` **before** that parse finishes.
3. Conjuguer's `handleURL` looked up the verb (→ `nil`, not loaded yet) but **switched
   the tab unconditionally**, landing on the Verbs tab with a nil verb binding: browse
   list, no verb.

The two necessary ingredients were: **(a) an asynchronous verb load that can still be
in flight when the deeplink arrives, and (b) a router that changes tab / navigation
state even when the entity lookup fails.** The fix stashed any deeplink that arrived
before the data was ready and replayed it after loading finished.

## Preliminary finding for Conjugar — likely NOT vulnerable

A quick read of the current code suggests Conjugar is protected on **both** axes, but
confirm rather than assume:

- **The verb data is a lazy *synchronous* static — accessing it *is* what loads it.**
  `VerbMap.shared` (`Conjugar/Models/VerbMap.swift`) is `static let shared = VerbMap()`,
  whose `private init()` parses `verbModelMap.xml` synchronously with `XMLParser`.
  Swift guarantees a lazy `static let` is initialized exactly once, thread-safe, **on
  first access**. So when `AppRouter.handle(url:)` calls
  `VerbMap.shared.entry(for:)`, that access blocks until the parse completes and then
  returns a fully-populated map. There is no "empty then later populated" window the way
  Conjuguer's `Task.detached` load created. (Ingredient (a) is absent — the map cannot
  be observed empty.)

  Note: `MainTabView`'s `.task` also kicks `WidgetSnapshotWriter.refresh()` off on a
  `Task.detached`, which likely touches `VerbMap.shared` too — but that only means the
  first access might come from either place; whichever wins triggers the same one-time
  synchronous parse, and the router still sees a complete map.

- **Guarded routing.** `AppRouter.handle(url:)`
  (`Conjugar/Views/AppRouter.swift`) only navigates on a **successful** lookup:
  ```swift
  case "verb":
    let last = url.lastPathComponent
    if last == "random", let random = VerbMap.shared.entries.keys.randomElement() {
      open(verb: random)                       // sets tab + pendingVerb
    } else if VerbMap.shared.entry(for: last) != nil {
      open(verb: last)
    }
    // else: ignored — no tab change, no partial state
  ```
  If the verb didn't resolve, `open(verb:)` is never called, so neither `selectedTab`
  nor `pendingVerb` changes. (Ingredient (b) is absent.)

Because neither ingredient is present, the exact Conjuguer symptom (wrong tab, no verb)
should not occur. **However**, note a subtle *different* failure mode worth checking:
if a verb ever *failed* to resolve at handle time, `handle(url:)` would **silently drop**
the deeplink (no defer/replay) rather than land wrongly — an acceptable degrade, but
only relevant if the map could be empty, which the lazy-static design prevents.

## Verification checklist (do this before concluding "safe")

1. **Confirm `VerbMap.shared` is still a synchronous lazy static.** Re-read
   `Conjugar/Models/VerbMap.swift`. Ensure nothing has moved the parse behind an
   `async` API, a background `Task` that assigns `entries` later, or a two-phase
   "create empty, fill later" pattern. If the map were ever made async / filled
   post-init, ingredient (a) returns — proceed to the fix.
2. **Confirm the router still guards navigation on resolution.** In
   `Conjugar/Views/AppRouter.swift`, verify the `verb` host only calls `open(verb:)`
   inside the `entry(for:) != nil` (and `random` non-nil) branches, and that
   `pendingVerb` / `selectedTab` are not set on the miss path. The `quiz` host switches
   unconditionally — fine, since `quiz/start` needs no verb data.
3. **Confirm the pendingVerb consumer is race-free too.** `open(verb:)` sets
   `router.pendingVerb`; `VerbBrowseView` consumes and clears it. Check that the
   consumer resolves the pending infinitive against `VerbMap.shared` / the browse data
   source at consume time, so it can't itself be defeated by ordering. (This is the
   navigation half of the same concern.)
4. **Exercise it on device (the real repro).** Build & install, **force-quit** Conjugar
   (swipe up from the app switcher — not just background it), then tap the medium/large
   Verb-of-the-Day widget (`conjugar://verb/<infinitive>` via `WidgetDeeplink.verb`,
   attached in `ConjugarWidget/Views/{Medium,Large,Small,Accessory,Quiz}WidgetView.swift`).
   Expected: the verb detail opens directly. Repeat after only backgrounding, to match
   Conjuguer's original comparison. Also test the control-center intents drained on
   `scenePhase == .active` via `MainTabView.drainPendingDeeplink()`
   (`OpenRandomVerbIntent` → `conjugar://verb/random`, `OpenQuizIntent` →
   `conjugar://quiz/start`).
5. If all pass, **record the result** (a note here or in the commit) and stop — no code
   change needed.

## Fix (apply ONLY if step 1, 2, or 3 shows a real gap)

Adapt Conjuguer commit `1f359d4` to `AppRouter`:

1. Add `var pendingDeeplink: URL?` to `AppRouter`.
2. In `handle(url:)`, if the required data isn't ready (e.g. `VerbMap.shared.entries`
   became async/empty), stash the URL and return instead of routing:
   ```swift
   guard !VerbMap.shared.entries.isEmpty else {
     pendingDeeplink = url
     return
   }
   ```
3. Add `func drainPendingDeeplink()` (the router already has the shared-defaults drain
   in `MainTabView`; add an in-router one for the `onOpenURL` path) that replays
   `pendingDeeplink` once cleared.
4. Call it from `MainTabView` at the point loading is known complete — e.g. at the end
   of the existing `.task` after whatever load it awaits, and/or in the
   `scenePhase == .active` branch alongside the existing `drainPendingDeeplink()`.
5. If the app proves not vulnerable, no change is needed — the lazy-synchronous
   `VerbMap` plus guarded routing is already the robust design.

## Tests

If a fix is applied, add a `ConjugarTests` case (Swift Testing) for the drain-replay and
no-op-when-nothing-pending paths, driving `AppRouter` directly (set `pendingDeeplink`,
call `drainPendingDeeplink()`, assert `selectedTab` / `pendingVerb`). Do **not** empty
the shared `VerbMap` in a test — construct an isolated `VerbMap(url:)` if you need a
controlled map, and prefer exercising the router's public surface.

## Resolution (2026-07-09) — NOT vulnerable, no code change

Verified all three static axes; each holds, so the fix was **not** applied.

1. **`VerbMap.shared` is still a synchronous lazy static** (`Conjugar/Models/VerbMap.swift`):
   `static let shared = VerbMap()`, `private init()` parses `verbModelMap.xml` inline with
   `XMLParser`. No async API, no background `Task` that assigns `entries` later, no
   create-empty-then-fill. The map cannot be observed empty. (Ingredient (a) absent.)
2. **Router still guards navigation on resolution** (`Conjugar/Views/AppRouter.swift:32`):
   `open(verb:)` runs only inside the `verb/random`-non-nil or `entry(for:) != nil`
   branches; the miss path sets neither `selectedTab` nor `pendingVerb`. `quiz` switches
   unconditionally, which is fine (needs no verb data). (Ingredient (b) absent.)
3. **Consumer is race-free** (`Conjugar/Views/VerbBrowseView.swift:124`): `pendingVerb`
   is read via `.onChange(..., initial: true)`, so a deeplink that set it before the view
   existed (cold launch) is consumed on first appearance; the pushed infinitive already
   resolved against the same synchronous `VerbMap.shared`. Grep confirms `open(verb:)` is
   the *only* setter of `pendingVerb`, and both URL entry points (`.onOpenURL` and the
   shared-defaults drain in `MainTabView`) funnel through the single guarded `handle(url:)`.

The race requires a verb store observable as empty; a synchronous lazy static structurally
cannot be one, so the Conjuguer symptom can't reproduce. Step 4's on-device force-quit +
widget-tap repro was not run (can't drive a real-device widget tap from here) and would only
confirm what the code already guarantees. Outcome recorded in `docs/blog_notes.md`.
