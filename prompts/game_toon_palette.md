# Plan — Cel/toon palette pass for the game's dancer + bull sprites

**Goal:** re-render the **existing** player (dancer) and bull flipbooks with a **drawn
cel look in Conjugar's palette**, replacing the current photoreal-ish grey renders, so both
sprite actors read as one hand-styled game. **No new frames, no new imagesets, no asset
renames, no new source models** — this is a *re-render + re-shade* of the 8 actions already
shipping, swapping the PNGs inside the current imagesets.

**Decision (made by Josh, baked into this plan):**
- **Dancer (player) → GOLD** cel (`customYellow` #CDA51B family) — the hero pops on the dark
  background.
- **Bull → RED** cel (`customRed` #C1001D family) — antagonist contrast.
- **Black cel OUTLINE on both.** The red bull sits on the red girders, so an outline is
  required to separate it; apply the same outline to the dancer so the two match.

Success = in `conjugar://game` both actors are cel-shaded (banded, drawn look) in gold/red
with a crisp black edge, still correctly sized/facing/planted, walk + throw + climb + jump +
cape all still read, and nothing regressed (feet on platforms, mirror at turns, no clipping).

Continues the sprite work in `prompts/game_dancer_actions.md`, `prompts/game_bull_actions.md`,
and the toolchain in `tools/blender/README.md`. Medium-risk: the render-side node work and the
**crop-box coupling** (below) are the real content; the wiring barely changes.

---

## Current state (what ships today, 2026-07-11)
- **8 actions, 32 frames, all grey (untextured/default material).** Player + bull are both
  rendered sprites; the last numbered placeholder is gone.
  - Dancer: `idle 2`, `walk 6`, `climb 4`, `jump 3`, `cape 4` (19 frames).
  - Bull: `idle 2`, `walk 6`, `throw 5` (13 frames).
- **All FBX sources present** in `tools/blender/source/` (git-ignored): `dancer_{idle,walk,
  climb,jump,cape}.fbx`, `bull_{idle,walk,throw}.fbx`. Re-rendering needs only these + the
  render script — **no Blender GUI / blender-mcp** (this is a headless `blender -b` pass).
- **`render_sprites.py` already has toon scaffolding:** `--toon` applies a *flat* single-color
  Principled material; `--color gold|red|none` picks #CDA51B / #C1001D. The **cel upgrade is
  documented but not built** (README "Upgrading `--toon` to a real cel look"): insert
  `Shader to RGB → ColorRamp (Constant, 2–3 stops) → Emission` between BSDF and Output, plus an
  optional Solidify flipped-normal black-material outline. **EEVEE only** (Shader-to-RGB is not
  a Cycles node).
- **Per-action render invocations** (match these when re-rendering — views/frames must not
  change): all actions `--view side --size 192`, **except the dancer's `climb`, which is
  `--view back`** (a back-view ladder pose). Frame counts exactly as above.

## The one thing that will bite: crop boxes are wired into GameView
`pack_or_rename.sh` union-crops each action to its silhouette; those pixel dims are **hardcoded
in `GameView.swift`** and drive on-screen sizing. **Adding a black outline inflates every
silhouette by the outline thickness on all sides → the crop boxes change → these constants must
be re-derived.** The coupled constants:

- **Dancer** (`GameView.swift`, "constant visual HEIGHT, per-action WIDTH"): `dancerWidth(_:)`
  aspects `idle 34/170`, `walk 109/169`, `climb 70/169`, `jump 119/169`, `cape 109/169`;
  `dancerVisualHeight = 56`; `dancerFeetOffset = -(56 - playerHeight)/2`.
- **Bull** ("constant SCALE, per-action W/H"): `bullCrop(_:)` = `idle 164×87`, `walk 170×92`,
  `throw 170×114`; `bullScale = 0.653`; `bullHeight`/`bullFeetOffset` derived from those.

A toon *material* alone wouldn't move these (same silhouette); the **outline will**. Phase 4
re-captures every crop box and recomputes these using the formulas already documented in the
code comments. Do **not** assume they're unchanged.

## Read first
1. This file's **decision** + **crop-box coupling** sections above.
2. `tools/blender/README.md` — the harness, the `--toon`/`--color` flags, and the
   "Upgrading `--toon` to a real cel look" section (the node graph to build).
3. `tools/blender/render_sprites.py` — `apply_flat_material` (the v1 to upgrade), `PALETTE`,
   `configure_output`/`resolve_engine` (EEVEE handling + the Workbench fallback to defeat for
   toon), and `setup_light` (the ramp needs this directional light to define where bands fall).
4. `Conjugar/Views/GameView.swift` — the dancer + bull sizing helpers named above.
5. `prompts/game_dancer_actions.md` + `prompts/game_bull_actions.md` — the per-action views,
   frame counts, and the render→crop→imageset→wire pipeline this pass re-runs.

---

## Phase 1 — Build the cel look into `render_sprites.py`  [Claude, headless iteration]
Upgrade the toon path from flat to a real cel material, keeping the existing `--toon`/`--color`
flags working:

- **Cel material.** Replace/extend `apply_flat_material` with a node graph:
  `Principled (or Diffuse) → Shader to RGB → ColorRamp → Emission → Material Output`, EEVEE
  only. The **ColorRamp uses Constant interpolation** with **2 stops to start** (shadow + lit),
  derived from the `--color` base: `shadow = base × ~0.55`, `lit = base` (optionally a 3rd
  `highlight = min(base × 1.2, 1.0)` stop if 2 bands read too flat at 56 px). Stop positions
  ~0.33 (and ~0.66 for 3). Keep the whole mesh one base color (clear existing slots, as v1
  does) so the silhouette stays uniform and the bands do the shaping.
- **Outline.** Add an opt-in `--outline` flag (default off): a **Solidify** modifier
  (flipped normals, small thickness) with a **black emission** material in the extra slot, so
  the back-faces render as a dark edge. Thickness is a **fraction of model height** (start
  ~0.012 units for the ~1.6-unit models; expose as `--outline-width` or hardcode + tune). This
  is the flag that changes the crop boxes — see Phase 4.
- **EEVEE, not Workbench.** Shader-to-RGB requires EEVEE. The script currently falls back to
  Workbench if EEVEE throws — for a toon render that fallback silently ruins the look, so make
  `--toon` **require** EEVEE (fail loudly instead of falling back, or assert the engine after
  render). (EEVEE-Next runs headless here — the raw bull pass used `BLENDER_EEVEE_NEXT` fine.)
- **Iterate on ONE frame** first (e.g. `dancer_walk` frame, gold, outline on): render → eyeball
  the bands + edge at 192 px and mentally at 56 px → tune ramp stops / outline width **before**
  committing to all 32 frames. A `docs/`-style montage helps.

## Phase 2 — Re-render all 8 actions, both actors  [Claude, headless]
Re-run the pipeline **preserving each action's view + frame count + size**, adding `--toon
--outline` and the per-actor `--color`:

```bash
# DANCER — gold. All side view except climb (back view).
for a in "idle 2 side" "walk 6 side" "climb 4 back" "jump 3 side" "cape 4 side"; do
  set -- $a
  blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/dancer_$1.fbx \
    --actor dancer --action $1 --frames $2 --size 192 --view $3 --toon --color gold --outline \
    --out tools/blender/renders
done
# BULL — red. All side view.
for a in "idle 2" "walk 6" "throw 5"; do
  set -- $a
  blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_$1.fbx \
    --actor bull --action $1 --frames $2 --size 192 --view side --toon --color red --outline \
    --out tools/blender/renders
done
```

Confirm `engine=BLENDER_EEVEE_NEXT` in each run's log (**not** Workbench). Spot-check a montage
per action (gold dancer, red bull, black edge, bands defining the pose).

## Phase 3 — Crop + rename  [Claude]
```bash
for a in idle walk climb jump cape; do tools/blender/pack_or_rename.sh rename dancer $a; done
for a in idle walk throw;          do tools/blender/pack_or_rename.sh rename bull   $a; done
```
**Record every printed `WxH` crop box** — you need all 8 to redo the GameView math in Phase 4.

## Phase 4 — Re-derive the GameView size constants from the NEW crops  [Claude]
The outline moved the boxes. Recompute, using the **same formulas the code comments document**:
- **Dancer** stays "constant `dancerVisualHeight`, per-action width = height × (cropW/cropH)":
  update each `dancerWidth(_:)` aspect to the new `cropW/cropH`. If the outline made the per-
  action crop **heights** no longer ~equal (they were all ~169–170), keep the constant-height
  model but note the small variance is fine, or bump `dancerVisualHeight` if the silhouette grew.
  Re-derive `dancerFeetOffset` if the crop's foot padding changed.
- **Bull** stays "constant `bullScale`, per-action W/H from `bullCrop`": update the three
  `bullCrop(_:)` dim pairs to the new boxes. Re-check `bullScale` still gives a good on-screen
  size (it maps crop-px→pt; a thicker silhouette at the same px means a hair bigger on screen —
  fine, or nudge `bullScale`).
- **Sanity:** the outline adds the *same* px to width and height, so aspects barely move; the
  main real change is a slightly larger silhouette. Don't over-tune — get it feet-planted and
  correctly proportioned, verify in Phase 5.

## Phase 5 — Swap PNGs + wire  [Claude]
- Copy each `tools/blender/dist/<actor>_<action>_<i>.png` over the PNG **inside the existing
  imageset** (same names — no imageset add/remove, no `project.pbxproj` touch). Script the loop
  as the original setup did.
- Apply the Phase-4 constant updates to `GameView.swift`.
- Build (`ios-build-verify`).

## Phase 6 — Verify in-app  [Claude + Josh]
Drive `conjugar://game` (flags **on** to see the bull throw; `CONJUGAR_GAME_TIME_SCALE=0.2` to
freeze the 0.5 s throw). Confirm, screenshotting representative frames:
- **Both actors cel-shaded** — gold dancer, red bull, black outline, bands reading the pose (not
  a flat blob, not a muddy edge at size).
- **Bull separates from the red girders** (the whole point of the outline).
- **Nothing regressed:** dancer walk/climb/jump/cape + idle all read; bull walks + throws
  (windup→release); feet on platforms; mirror flips at turns; no clipping from the fatter
  silhouette; sizes still right relative to each other and the platforms.
- Drive the player across a girder and up a ladder (`conjugar://verb`… no — use the on-screen
  D-pad / hold-up at a ladder base) to exercise climb + jump live.

## Phase 7 — Document + commit  [Claude]
- `tools/blender/README.md` — turn "Upgrading `--toon` to a real cel look (later)" into the
  **done** record: the node graph built, `--outline` added, dancer=gold / bull=red, EEVEE-only,
  and the crop-box/aspect re-derivation gotcha.
- `docs/blog_notes.md` — the toon-pass story (flat→cel node graph, the gold/red hero-villain
  choice, the outline-changes-the-crop-boxes coupling and how the GameView constants were
  recomputed, both actors now one drawn style).
- **No license/credits change** — same source models (dancer = Mixamo X Bot; bull = Leo_Aguiar,
  already credited), just re-shaded. Confirm this explicitly; don't touch `asset-licenses/`.
- Commit to the **`migration`** branch (raw `.blend`/`.fbx`/renders/dist stay git-ignored; only
  the swapped PNGs in the imagesets + the README/blog/GameView edits are tracked).

## Definition of done
- `render_sprites.py --toon` produces a real 2-band-plus cel look; `--outline` adds a black edge;
  EEVEE is enforced for toon.
- All 32 frames re-rendered (gold dancer / red bull / outline), same 8 actions/views/counts,
  swapped into the existing imagesets.
- `GameView.swift` size constants re-derived from the new crop boxes; app builds.
- Verified live: both actors cel-shaded and on-palette, bull distinct from the red girders,
  every action still reads and is correctly sized/planted/faced.
- README + blog updated; committed to `migration`; no credits/license change.

## Gotchas
- **The outline moves the crop boxes → GameView constants MUST be re-derived** (Phase 4). This
  is the #1 trap. Re-capture all 8 `WxH` boxes; don't reuse the current numbers.
- **EEVEE only for cel.** If EEVEE fails headless the script must NOT silently fall back to
  Workbench (that erases the toon look). Assert the engine.
- **Preserve per-action `--view`** — dancer `climb` is `--view back`; everything else `side`.
  Re-render with the wrong view and the climb re-introduces the "which way is the figure facing"
  bug the back-view render fixed.
- **Preserve frame counts** (dancer 2/6/4/3/4, bull 2/6/5) — they match `playerFrameCounts` /
  `bullFrameCounts`. Changing N here means changing those tables too (don't).
- **Readability at 56–60 px is the bar,** not the 192 px render. 3 tight bands + a fat outline
  can muddy small; start 2 bands + thin outline, thicken only if the edge disappears.
- **Whole-mesh single color is intentional** — the bands do the shaping. Don't try to preserve
  the X Bot's material breakup.
- **SourceKit false positives** editing `GameView.swift` — `build_app.sh` is authoritative.
- **Raw assets stay git-ignored;** only PNGs + code/docs ship.

## Not in scope (later sessions)
- **Custom flamenco-dancer mesh** (replace the X Bot mannequin) — the bigger visual upgrade; a
  cel pass on the *current* mesh is independent of it and stays valid after a mesh swap (re-run
  this same toon pipeline on the new FBX).
- **Bullfighter + flag art** (still emoji — the "?" boxes are the flag emoji missing-glyphing in
  the sim) and a **bull defeat/hit reaction** (new `BullAction`).
- **Background/platform restyle** — this pass only touches the two actor sprites.
