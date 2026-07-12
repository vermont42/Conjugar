# Blender → 2D sprite pipeline (Conjugar game)

This directory holds the **3D→2D-sprite render harness** for Conjugar's
Donkey-Kong-style flamenco/bull game. It turns a rigged, animated 3D model into
transparent PNG animation frames and drops them into the game's flipbook seam.

The design rationale lives in `docs/game_design_research.md` **§3** (asset &
animation pipeline). This README is the operational how-to.

## The pipeline at a glance

```
concept (Gemini)                    ← reference only, not frames
   └─ 3D mesh (Mixamo stock char, or image-to-3D later)
        └─ rig + mocap (Mixamo: walk / idle / climb / jump / dance)   → FBX
             └─ render_sprites.py (Blender, orthographic, transparent) → PNG frames
                  └─ pack_or_rename.sh (rename or montage)             → Xcode assets
                       └─ Assets.xcassets/Game/  →  Image("dancer_walk_N") in GameView
```

Blender is only the **render/animation** stage — not the whole tool. Humanoid
animation comes free from **Mixamo** (auto-rig + royalty-free mocap); Blender
points an **orthographic** camera at the result and renders each frame to a
transparent sprite.

## Requirements (verified July 2026)

| Tool | Version used | Install |
|---|---|---|
| Blender | 4.5.11 LTS | `brew install --cask blender` |
| ImageMagick | 7.1.2 | `brew install imagemagick` (`magick`) |
| uv | 0.11.28 | `brew install uv` (only for blender-mcp) |

`render_sprites.py` uses Blender's bundled Python — no separate install.

For the *interactive* path (optional), the blender-mcp add-on is vendored at
`blender-mcp/addon.py` — see `blender-mcp/README.md` for install + Connect steps.
The headless CLI below needs neither the add-on nor the GUI.

## Directory layout

```
tools/blender/
  render_sprites.py    # the headless render script (Blender Python)
  pack_or_rename.sh    # rename frames to the Xcode convention, or pack a sheet
  README.md            # this file
  source/              # input FBX exports from Mixamo (git-ignored if large)
  renders/             # raw output: <actor>_<action>/<action>_0001.png …
  dist/                # renamed/packed, ready for Assets.xcassets
```

## Step 1 — get an animation (Mixamo)

1. Sign in at <https://www.mixamo.com> (free, Adobe account).
2. Pick a **stock character** (fastest — skip custom-mesh work for the first
   proof), then a **Walking** animation.
3. **Check "In Place"** so the character walks without translating — essential
   for a centered sprite cycle.
4. **Download → FBX**, 30 fps, "With Skin". (Frame reduction is fine; the script
   samples down to N frames anyway.)
5. Save as `tools/blender/source/dancer_walk.fbx`.

Mixamo license: royalty-free for commercial use, no attribution; you just can't
resell the raw asset standalone. Shipping it inside the app is fine — **log it in
`asset-licenses/`.**

## Step 2 — render the frames

```bash
# From the repo root. Renders 6 walk frames at 192px (3× of a 64pt sprite).
blender -b -P tools/blender/render_sprites.py -- \
    --fbx tools/blender/source/dancer_walk.fbx \
    --actor dancer --action walk --frames 6 --size 192 \
    --out tools/blender/renders
```

Output: `tools/blender/renders/dancer_walk/walk_0001.png … walk_0006.png`,
transparent RGBA.

**Smoke-test the render path without any FBX** (renders Blender's default cube —
handy to confirm EEVEE renders headless on this machine):

```bash
blender -b -P tools/blender/render_sprites.py -- --actor test --action cube --frames 1
```

### `render_sprites.py` arguments

| Flag | Default | Meaning |
|---|---|---|
| `--fbx PATH` | *(none)* | FBX to import; omitted ⇒ render the open scene. |
| `--actor NAME` | `dancer` | Actor name (output folder + filename prefix). |
| `--action NAME` | `walk` | Action name. |
| `--frames N` | `6` | Frames to render, evenly sampled across the range. |
| `--size PX` | `192` | Square render size (3× target; 64pt ≈ 192px). |
| `--ortho F` | `0` (auto) | Orthographic scale; `0` auto-fits the mesh bounds. |
| `--margin F` | `1.15` | Auto-fit padding around the bounds. |
| `--view V` | `side` | `side`(-X) `side2`(+X) `front`(-Y) `back`(+Y). |
| `--engine E` | `eevee` | `eevee` / `workbench` / `cycles` (EEVEE→Workbench fallback). |
| `--toon` | off | Apply a flat palette material (see `--color`). |
| `--color C` | `gold` | `--toon` color: `gold` #CDA51B, `red` #C1001D, `none`. |
| `--start N` / `--end N` | auto | Override the sampled frame range. |
| `--out DIR` | `tools/blender/renders` | Output root. |

**Match the frame count to the seam.** `GameState+Animation.swift` sets
`playerFrameCounts[.walk] = 6`. Render **N = 6** so the game's index math
(`Int(phase*fps) % count + 1`, 1-based, `fps = 10`) maps 1:1 onto the files.
Change one, change the other.

**Frame sampling** is half-open `[start, end)` — the closing frame of a Mixamo
loop equals the opening frame, so dropping it makes the N frames tile seamlessly.

**Framing** auto-fits mesh bounds across the *entire* range, so a stride's
extremes (or a jump's peak) never clip. Pin it with `--ortho` once you find a
value you like (printed context makes tuning easy).

### Render settings baked in (research §3.6)

- Camera **Orthographic**, side profile (platformers are side-on).
- **Film ▸ Transparent ON**, output **PNG / RGBA**.
- A Sun light; **EEVEE** by default (auto-falls back to **Workbench** if EEVEE
  can't init headless — Workbench also gives a clean flat-shaded look).

## Step 3 — name or pack for Xcode

```bash
# Rename to the 1-based flipbook convention the game expects:
tools/blender/pack_or_rename.sh rename dancer walk
#   -> tools/blender/dist/dancer_walk_1.png … dancer_walk_6.png

# …or pack a horizontal sprite sheet instead:
tools/blender/pack_or_rename.sh sheet dancer walk "" "" 96
#   -> tools/blender/dist/dancer_walk_sheet.png  (6x1 @ 96px cells)
```

## Step 4 — into the app

1. Drag `dist/dancer_walk_1.png … _6.png` into a new
   **`Conjugar/Assets.xcassets/Game/`** group as imagesets (the catalog is in a
   synchronized group — no `project.pbxproj` edit needed). Provide a single 3×
   asset, or @2x/@3x.
2. In `Conjugar/Views/GameView.swift`, the player sprite currently renders
   `Text(verbatim: "\(gameState.playerFrame)")`. Swap it, for the `.walk`
   action, to:
   ```swift
   Image("dancer_walk_\(gameState.playerFrame)")
     .resizable().interpolation(.none)
   ```
   keeping the numbered `Text` fallback for actions not yet rendered.
3. **Pre-decode** the frames once at load (research §2.2) to avoid a per-frame
   decode hitch.

## Adding a new action

1. Mixamo → apply the new clip (e.g. **Climbing**) → export
   `source/dancer_climb.fbx` (In Place, 30 fps, With Skin).
2. Render: `... --fbx source/dancer_climb.fbx --action climb --frames 4 ...`
   (match `playerFrameCounts[.climb]`).
3. `pack_or_rename.sh rename dancer climb` → add to `Assets.xcassets/Game/`.
4. Extend the `GameView` swap to that action.

### The dancer's full action set (done)

All five player actions now ship as rendered sprites — `idle` (Breathing Idle, 2),
`walk` (Walking, 6), `climb` (Climbing Ladder, 4), `jump` (Jump, 3), `cape` (Taunt,
4) — all on the same **X Bot** character. Notes that held across the set:

- **The default side view (`--view side`) was enough for every action**, including
  the ladder climb: the "Climbing Ladder" clip reads clearly in profile (stepping
  legs, reaching arms), so no `--view front/back` special-case was needed.
- **Union-crop heights all landed at ~169 px** (idle 34×170, climb 82×169, jump
  119×169, cape 109×169, walk 109×169) because In-Place keeps the figure the same
  height. `GameView` holds one visual **height** and derives each action's **width**
  from its own aspect ratio, so the character stays one size with feet aligned.
- **Facing/mirror:** the renders face **left**; `GameView` mirrors when the player
  faces right — *except* `climb`, which is left un-mirrored (a symmetric ladder pose
  shouldn't flip). See `GameView.dancerMirror(_:facing:)`.
- **Catching a fast action in a screenshot:** the game loop honors a
  `CONJUGAR_GAME_TIME_SCALE` launch env var (e.g. `0.2` = 5× slow, `0.1` = 10×) and
  a `CONJUGAR_GAME_DISABLE_FLAGS` flag — both default off, no effect on normal play.
  Launch with them set to freeze-frame a jump's apex or a climb pose.

## Upgrading `--toon` to a real cel look (later)

`--toon` currently applies a flat, palette-colored Principled material — enough
to prove the palette reads. For a drawn/cel look (EEVEE only), insert between the
BSDF and the Material Output:

```
Diffuse/Principled → Shader to RGB → ColorRamp (Constant interpolation, 2–3 stops)
→ Emission → Material Output
```

and optionally add a Solidify modifier with a flipped-normal black material for
an outline. Do this *after* the raw render is validated (the plan's order).

## The bull (later)

No Mixamo for quadrupeds. Source a pre-rigged bull (Sketchfab "Simple Rigged
Bull" — **verify its per-model license**, log it) or rig with Blender Rigify's
quadruped meta-rig, hand-key walk/climb/throw/defeat, then render through **this
same `render_sprites.py`** (`--actor bull --action walk …`). blender-mcp's
image-to-3D + Sketchfab integration helps source the mesh.
