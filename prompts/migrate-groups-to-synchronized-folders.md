# Task: Migrate the Conjugar Xcode project from groups to synchronized folders

You are starting a fresh session on the **Conjugar parsimony project** (see
`CLAUDE.md`). This task is **infrastructure, not engine work**: convert the
`Conjugar.mig` Xcode project from old-style *virtual groups* to **file-system-
synchronized folders** (Xcode 16+, `objectVersion 77`), so that adding or
removing source files no longer requires editing `project.pbxproj`. Do **not**
write engine code or change conjugation logic.

## Why this matters

The project is old-style (`objectVersion = 54`): every source file is registered
by hand in `project.pbxproj` (~4 places each, ×2 for the test target). Adding the
Phase 1 engine files required scripting that with the `xcodeproj` gem. With
synchronized folders, Xcode auto-includes whatever is in a target's folder, so
the remaining engine phases (2–6) just **drop `.swift` files into the right
directory** and they compile. This removes a recurring friction point.

A prior "Convert to Folder" attempt in Xcode **failed** with: *"Each group must
have an associated folder… the following groups are not associated with a folder:
Conjugar/Analytics, Conjugar/Assets, Conjugar/Controllers, Conjugar/Models,
Conjugar/Supporting, Conjugar/Views, Conjugar/UIViews, Conjugar/Utils."* That is
the crux: those are **virtual groups** with no matching directory — the ~89
`.swift` files all sit **flat** in `Conjugar/` on disk. Conversion requires disk
to match the group structure first.

## Current state (verify before starting)

- Repo: `/Users/josh/Desktop/workspace/Conjugar.mig`, branch `migration`, last
  commit the Phase 1 engine. **Ensure a clean working tree** (`git status`)
  before starting.
- `project.pbxproj`: `objectVersion = 54`, **no** `PBXFileSystemSynchronizedRootGroup`.
- App target `Conjugar`: ~89 `.swift` files flat in `Conjugar/`, organized into
  virtual groups (Analytics, Assets, Controllers, Models, Supporting, Views,
  UIViews, Utils). Also physically in `Conjugar/`: `Assets.xcassets`,
  `Base.lproj`, `es.lproj`.
- Test targets: `ConjugarTests` (its `Models/` subfolder **already exists on
  disk** — partly folder-backed), `ConjugarUITests`.
- Xcode supports synchronized folders (the build machine has Xcode 26.x).
- Tooling: `xcodeproj` Ruby gem available (ruby 2.7.5).

## The task

### Recommended — preserve the group organization (Approach A)

1. **Make disk match the groups.** For each app-target group (Analytics,
   Controllers, Models, Supporting, Views, UIViews, Utils), create a real
   subfolder `Conjugar/<Group>/`, move that group's `.swift` files into it, and
   update each file reference's path + the group's `path` in `project.pbxproj`.
   Use the **`xcodeproj` gem** — don't hand-edit. Do this **one group at a time,
   building after each**, so breakage is localized and obvious. (`Assets.xcassets`
   is a resource, not source — leave it where it is.)
2. **Verify the project still builds and the Phase 1 gate still passes** (still
   old-style at this point):
   ```
   xcodebuild test -project Conjugar.xcodeproj -scheme Conjugar \
     -destination 'platform=iOS Simulator,id=<an available iPhone sim>' \
     -only-testing:ConjugarTests/Conjugator2Tests
   ```
   (`xcrun simctl list devices available | grep iPhone` for a simulator id.)
3. **Convert to synchronized folders.** With disk now matching the groups, do the
   actual conversion. The reliable path is **Xcode itself** (right-click each
   now-folder-backed group → "Convert to Folder"), which bumps the project to
   `objectVersion 77` and replaces the groups with `PBXFileSystemSynchronizedRootGroup`.
   The `xcodeproj` gem's support for objectVersion-77 synchronized groups lags, so
   prefer Xcode for this final step. **If the user is driving Xcode, hand off here
   with exact click-by-click instructions and wait** for them to confirm.
4. **Build + run the gate again** to confirm no regression.

### Lower-effort fallback — flatten, then convert (Approach B)

If reorganizing into subfolders proves troublesome, instead dissolve the virtual
subgroups so the flat disk matches a single flat `Conjugar` group, then convert
that one group to a synchronized folder. Result: a flat (un-grouped) navigator
that still auto-includes new files. Organization can be reintroduced later by
moving files into real subfolders on disk — a synchronized folder tracks disk
automatically, so no `project.pbxproj` edits are needed for that cleanup.

Apply the same disk-matches-group reasoning to `ConjugarTests` and
`ConjugarUITests` (the existing `ConjugarTests/Models/` folder helps).

## Acceptance test (how you know it worked)

After conversion, create a throwaway file (e.g. `Conjugar/Models/_SyncCheck.swift`
with a trivial `enum`) **without touching `project.pbxproj`**, then build the
`Conjugar` target — it should compile (proving auto-inclusion). Delete it. Confirm
`project.pbxproj` now shows `objectVersion = 77` and `PBXFileSystemSynchronizedRootGroup`
entries, and that `ConjugarTests/Conjugator2Tests` still passes.

## Safety rails

- The clean git branch is your net — **commit before starting**, and
  `git restore` if a move goes wrong. Consider committing after each group move
  (Approach A step 1) so reverts are cheap.
- **Build/test after every significant step.** A broken `project.pbxproj` is
  silent until you build.
- Do **not** move or break: `Assets.xcassets`, `Base.lproj`, `es.lproj`, or
  `Info.plist`. Resource and build-phase membership must survive every move.
- The objectVersion bump yields a **large, noisy `project.pbxproj` diff** — keep
  this migration on its **own commit(s)**, separate from engine work.

## Deliverable

- Project converted to synchronized folders (`objectVersion 77`), building, with
  `ConjugarTests/Conjugator2Tests` green.
- A one-line entry in `docs/blog_notes.md` under today's date.
- A clean **commit on `migration`** (e.g. "Migrate Xcode project to file-system-
  synchronized folders"); **push only if the user asks**. End the commit message
  with the repo's Co-Authored-By trailer.

## Pointers

- For the target layout, Conjuguer (`/Users/josh/Desktop/workspace/Conjuguer`)
  already uses real folders (`Conjuguer/Analytics/`, `Models/`, `Utils/`, …).
- `prompts/phase-2-orthographic-accent-features.md` has been updated to assume
  this migration is done (new files auto-include; gem registration kept only as a
  fallback).

## Note on ordering

This migration runs **before Phase 2**. Once it lands, dropping new feature files
into `Conjugar/Models/` is all that's needed — no `project.pbxproj` step.
