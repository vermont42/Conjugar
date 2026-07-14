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
| `--accents` | off | **Bull-only.** Partition the cel skin into muzzle/hooves/horn/eye regions (needs `--toon`). See *The bull* below. |
| `--horn-style S` | `ivory` | With `--accents`: horn color — `ivory` (bone) or `dark` (maroon). |
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

The player actions ship as rendered sprites — `idle` (2), `walk` (6), `climb` (4),
`jump` (3), the two **held-muleta** cape actions `cape` (4, standing swing) and
`capeWalk` (6, hold-in-front while walking), and the two **boss dance-off** actions
`ole` (3, arms-up desplante + back arch) and `stomp` (3, weight-drop zapateado with a
braceo) added for La Llamada (boss plan Phase 4). They are **no longer Mixamo mocap on the
X Bot mannequin**: the dancer is now the purchased **flamenco-gown** mesh (Animod, CGTrader
— `asset-licenses/cgtrader-flamenco-dancer.txt`), hand-keyed on its own 63-bone
Mixamo-named rig by `gen_dancer_action.py` (see **Hand-keying the gown dancer** below).
Notes that held across the set:

- **The default side view (`--view side`) suits every action but climb.** The one
  exception is **climb**, rendered **`--view back`** (camera behind the figure): a
  side-on climb reads oddly on a vertical ladder, whereas watching the character's
  back as they climb *away* up the rungs is the conventional platformer read. The
  gown climb sells the reach from behind (back of the head/hair, arms alternating
  overhead, skirt swaying). Pure `--view back` was enough — no off-axis three-quarter
  nudge to the camera-placement block was needed.
- **Union-crop heights all land at ~226 px** (idle 104×225, walk 122×226, jump
  116×226, cape 152×225, capeWalk 155×227, ole 116×229, stomp 108×229, climb
  172×228 *(back view, arms spread wide)*) — the full
  floor-length gown, feet hidden. `GameView` holds one visual **height**
  (`dancerVisualHeight = 57.3`) and derives each action's **width** from its own aspect
  ratio, so the character stays one size with the hem glued to the platform. (Climb is
  the widest — 172 — because the arms reach up and out in a V.)
- **Facing/mirror:** the renders face **left**; `GameView` mirrors when the player
  faces right — *except* `climb`, which is left un-mirrored (a back-view ladder pose is
  left–right symmetric, so it shouldn't flip). See `GameView.dancerMirror(_:facing:)`.
- **Catching a fast action in a screenshot:** the game loop honors a
  `CONJUGAR_GAME_TIME_SCALE` launch env var (e.g. `0.2` = 5× slow, `0.1` = 10×) and
  a `CONJUGAR_GAME_DISABLE_FLAGS` flag — both default off, no effect on normal play.
  Launch with them set to freeze-frame a jump's apex or a climb pose.

### Hand-keying the gown dancer (`gen_dancer_action.py`)

Because a floor-length gown can't be Mixamo-mocapped (the auto-rigger needs separated
legs, and a leg stride pokes shoes/legs past the hem), each action is **hand-keyed on
the vendor's own rig** with world-space bone rotations, then baked to
`source/dancer_<action>_gown.fbx` for `render_sprites.py`. Run it per action:

```bash
blender -b -P tools/blender/gen_dancer_action.py -- --action idle   # idle|jump|cape|climb|ole|stomp
```

House style: **animate the gown + torso, feet hidden.** Two fixes that were paid for
the hard way and must not regress:

- **Delete the shoe *and* the bare-legs mesh** (`Sho`/`HeA_M`/`Leg`). The skirt
  (`MASkirt_03`) is skinned to the hip+leg **bones**, not the leg mesh — so rotating
  the leg bones still sways the hem, but with the leg mesh gone nothing pokes below
  the hem (otherwise a rotated leg shows as thin gold strands dangling under the skirt).
- **Rotate each bone about its own head, not the world origin.** The rotation helper
  preserves the bone's translation (`m.translation = cur.translation`); a plain
  pre-multiplied `Matrix.Rotation @ matrix` pivots about the world origin — fine for the
  walk's tiny leg angles, but a 125–155° arm raise then swings the hand on a huge arc
  through the body (cape/climb arms fly off into strands). Keep parent-before-child
  order with a `view_layer.update()` between so children inherit correctly (FK).
- **The `[1,1557]` trap:** the vendor FBX ships a long baked clip; `animation_data_clear()`
  before keying and export with `bake_anim_use_all_actions=False`, or every frame samples
  a static tail.
- **The held muleta (cape actions).** For `cape`/`capeWalk`, `make_muleta()` builds a flared
  red cloth (hangs down+forward, in the Y-Z plane so the side camera sees its face) and the
  frame loop **keyframes its LOCATION to the hand midpoint** (not skinned) — the arm swing
  then carries it up/down. Render with `render_sprites.py --cape`, which paints the `Muleta`
  mesh **red** and every other mesh **gold** (a two-material cel, like the bull accents). The
  boxes are wider than the other actions (the muleta juts forward): cape 152, capeWalk 155.
  **Front is −Y; NEGATIVE world-X swings the arms up-and-forward** (positive throws them
  back — which first put the cape behind her). Measure with a probe, don't guess the sign.

## `--toon` cel look + `--outline` (done, 2026-07-11)

`--toon` now renders a real **banded cel** material (not the old flat fill), and
`--outline` adds a black drawn edge. Both actors were re-shaded through this in one
pass: **dancer = gold** (`--color gold` #CDA51B), **bull = red** (`--color red`
#C1001D) — hero/villain contrast, the outline separating the red bull from the red
girders. EEVEE only (Shader-to-RGB is an EEVEE node); `--toon` now **aborts** if the
engine resolves to anything but EEVEE rather than silently falling back to Workbench
(which would erase the look).

**The cel material** (`apply_cel_material`) is the node graph the plan called for:

```
Diffuse BSDF (white) → Shader to RGB → ColorRamp (Constant, 2 stops) → Emission → Output
```

The white Diffuse + Shader-to-RGB turn scene lighting into a 0–1 luminance the
*Constant*-interpolation ramp quantizes into flat bands; the ramp **stops carry the
palette** (shadow = base × 0.55 at pos 0.0, lit = base at pos 0.33), so the whole mesh
is one hue and only the bands shape it. `--bands 3` adds a `base × 1.2` highlight stop.

**Two colour-pipeline fixes were needed for true palette hex** (a flat cel exposes
what a photoreal render hides): the toon path sets the **Standard** view transform
(the 4.5 default AgX shifts saturated reds → pink, mutes gold), and the ramp colours
are **sRGB→linear converted** before assignment (Blender colour sockets are linear;
feeding raw sRGB renders the red as hot pink). With both, the bull's lit band samples
back to exactly **#C1001D** and the gold to **#CDA51B**.

**The outline is Freestyle, not the inverted-hull Solidify trick the plan sketched.**
Under this build's **EEVEE-Next**, a flipped-normal + backface-cull Solidify shell was
unreliable (a 4-variant probe: it either culled the rim away → no outline, or swallowed
the whole figure in black). **Freestyle** silhouette line rendering is deterministic and
its thickness is directly in output px — `setup_outline` enables silhouette + border +
contour lines, black, at `--outline-width` px (default **2**, ≈ 1px on-screen at the 3×
sprite size). Bonus: it renders into the alpha, so the crop-box growth Phase 4 expects
still happens.

**The gotcha the plan warned about — the outline moves the crop boxes** — is real and
was handled. Freestyle draws the line *outside* the mesh bounds, so the ortho auto-fit
(hence the **body's** rendered px) is unchanged; the union-crop just grew a uniform
**~+4px** on every dim from the line. The `GameView.swift` size constants were re-derived
from the new crops: each `dancerWidth(_:)` aspect refreshed to the new `cropW/cropH`,
`dancerVisualHeight` bumped **56 → 57.3** (× 173/169) to hold the character *body* at its
prior on-screen size, and `bullCrop(_:)` updated to the new dims with `bullScale`
unchanged (the bull body was already body-constant; the +4px is just outline margin).
Don't reuse the old crop numbers — re-capture all 8 `WxH` boxes from `pack_or_rename.sh`
whenever the outline width changes.

To *later* pivot toward a rendered-realistic look (Vainglory-style) instead of flat cel,
this is the wrong material — that path wants real PBR textures + 3-point/rim lighting +
Cycles AO/soft-shadow + compositor bloom, and **no** outline (rim light separates figures).
That's a separate `--realistic` mode and an art-direction fork, not an extension of `--toon`.

## The bull (done, 2026-07-11)

No Mixamo for quadrupeds, so the bull was sourced pre-rigged: Sketchfab's
**"Simple Rigged Bull" by Leo_Aguiar (CC BY 4.0)**, a Blender **Rigify Basic
Quadruped**. License logged at `asset-licenses/sketchfab-bull.txt`; raw
`.blend`/`.fbx` stay git-ignored (only PNGs ship). Three actions were authored on
its rig and rendered side-view through **this same `render_sprites.py`**
(`--actor bull --view side`), N matched to `GameState.bullFrameCounts`
(idle 2 / walk 6 / throw 5, plus the three **boss dance-off** actions stomp 3 /
rear 4 / bow 4, added for La Llamada by `gen_bull_action.py` — boss plan Phase 3):

- **idle (2)** — free: two samples of the model's own baked standing-sway clip.
- **walk (6)** — hand-keyed cyclic diagonal quadruped gait (thigh swing + knee bend).
- **throw (5)** — hand-keyed head-toss one-shot: head rears up (windup) then thrusts
  down (goring release), timed to `bullThrowDuration` (0.5 s).
- **stomp (3)** — front-hoof raise → strike + head nod (union crop 452×306). Used for
  the intro llamada, the demo-stomp cue, and the smug fail/showboat accent.
- **rear (4)** — rear up on the hind legs, forelegs pawing (452×294; seed poses from
  `throw`'s raised head/neck keys) — the ole demo and the showboat flourish.
- **bow (4)** — front legs fold, head sweeps low (452×232). The win payoff: the final
  frame reads as a **held** bow and `GameState.capBullBowHold()` freezes the flipbook
  there through `.victory`/`.endScene` (an uncapped phase would loop the bow forever).

Authored **interactively** through blender-mcp (live viewport + per-pose sign-off from
Josh), *not* headless-and-blind — the first blind attempt sheared the continuous mesh
(giraffe neck, straight-bar forelegs, a tangled bow) because big FK rotations distort a
one-piece body. The approved peak angles were then baked into `gen_bull_action.py` (peak
dicts + per-frame scale factors + a trailing-duplicate so the held pose survives the
half-open `[start,end)` one-shot sampling) and rendered headless.

**Gotcha that shaped the authoring:** the FBX round-trip strips Rigify's control
logic — the imported control rig has **0 constraints / 0 drivers**, so posing the
`*_ik`/`torso` "controls" does nothing. The mesh is skinned to the `DEF-` bones and
the baked clip keys them directly, so walk/throw were keyed **on the `DEF-` deform
bones** (rear `DEF-thigh/shin`, `DEF-front_thigh/shin`, and the `DEF-spine.008..011`
neck→head chain), quaternion channels, In-Place. Author actions in Blender's **Right
Ortho** view = the render's `--view side` (head-left; the game mirrors for facing).

**Per-action framing matters.** `render_sprites.py` auto-fits ortho by the bull's
constant body *length* (every action crops ~170 px wide), so **one render pixel is
the same world size in every action** — the throw's reared head just makes a taller
crop (114 px vs walk's 92). `GameView` maps crop px → screen at one constant
`bullScale`, deriving per-action width/height/feet-offset, so the body stays one size
while the head genuinely extends up on a throw (a fixed on-screen *height* would
instead shrink the body ~19 % mid-throw).

Example actor invocations (one FBX per action, exported from `bull.blend` with that
action active — sidesteps multi-action ambiguity):

```bash
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_walk.fbx  --actor bull --action walk  --frames 6 --size 192 --view side
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_throw.fbx --actor bull --action throw --frames 5 --size 192 --view side
# Boss dance-off actions — the shipped bull is re-rendered at --size 512 (crisp horn):
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_stomp.fbx --actor bull --action stomp --frames 3 --size 512 --view side
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_rear.fbx  --actor bull --action rear  --frames 4 --size 512 --view side
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_bow.fbx   --actor bull --action bow   --frames 4 --size 512 --view side
```

### Bull cel accents — `--accents` (done, 2026-07-12; paid-asset spike Phase 0 Part A)

The flat single-material `--toon` renders the bull as one flat red mass — it reads as
a bull-shaped **blob**. `--accents` (bull-only; requires `--toon`) partitions the mesh
into a few cel regions so it reads as a bull **with character**, staying in the same
banded-cel language as the dancer:

- **body** — the `--color` base (red), rendered `--bands 3` so a lit highlight band
  gives the back/shoulder volume (biggest "not-flat" win). The **head is body-red
  too** (see the black-bg note below).
- **horn** — `--horn-style ivory` (bone; **shipped** — the one *light* accent that
  pops on the black field and is *the* bull signifier) or `dark` (maroon; cohesive
  all-red villain, but the horn then relies on the silhouette outline).
- **eye** — a near-black dot on each flank, sitting *interior* to the red head so it
  reads dark-on-red (not at the silhouette edge).
- **hooves** — base × 0.35 (deep maroon): grounds the legs when on a red platform.

> **Black-background constraint (learned the hard way).** The bull lives against the
> game's near-pure-black field, over which the black Freestyle **outline is invisible**
> — the silhouette is defined *only* where a light/red fill meets black. A first pass
> darkened the **muzzle** (base × 0.35); at a silhouette *edge* against black it
> vanished, taking the whole front of the head with it (the ivory horn then floated in
> a void — "the northwest corner of Oregon, flipped"). Rule: silhouette-**edge**
> regions (muzzle/snout, horn, back) stay **red or light**; only **interior** regions
> (the eye) may go dark. So the head is kept red and the ivory horn is the lone light
> accent. (On a *light/red* background a dark muzzle would help — but the bull is never
> on one.)

**The accents are materials-only** (the silhouette is unchanged), so at a *fixed* render
size they'd leave the crop boxes untouched. But a separate legibility pass **did** move
the `GameView` constants — see the resolution note below — so the shipped crops are the
512-render values (idle 436×230 / walk 452×248 / throw 452×306), not the old 192 ones.

> **Resolution matters more than the shape (a device-only bug).** On a physical iPhone the
> ivory horn read as a blocky/smudgy speck even after the shape was right. Cause: the bull
> is *displayed large* (~137 pt ≈ 410 px @3x wide) but was rendered at `--size 192` (~168 px
> crop), so it was upscaled ~2.4× and the small horn turned to mush. Fixes, all needed
> together: render the **bull at `--size 512`** (source ≈ the @3x display, so the horn is
> crisp); draw the bull `Image` with **`.interpolation(.high)`** in `GameView` (nearest-
> neighbor frays the outline into spikes on the 512→display *downscale*); and keep the
> **default `--outline-width 2`** (at 512 a wider outline makes Freestyle draw hair-like
> contour spikes). `GameView.bullScale` was re-derived to hold the on-screen size (also +25 %
> per Josh): 436 px × 0.314 ≈ 137 pt. Only the **bull** needs 512 — the dancer displays near
> 1:1 from its 192 render, so it stays at 192 with `.interpolation(.none)`.

**How the regions are selected (and the one fragility):** region membership is tested
on each polygon's **rest-pose local centroid** (`vertices[i].co`, the undeformed basis
— stable across every animation frame; the armature deforms at eval time, so the ivory
horn and dark muzzle correctly *follow* the head as it rears in the throw). The boxes
are hardcoded in `_bull_region()` from `bull_idle.fbx` geometry: bull runs along **Y**
(muzzle at −Y ≈ −1.68, rear at +Y), **Z** up (hooves z ≈ 0, back ridge z ≈ 1.6), **X**
left/right (±0.5); `--view side` shows the +X flank. **If the bull mesh is ever
replaced, re-measure these boxes** (the spike's Phase-0 probe scripts print the coords).

```bash
# The shipped bull re-skin — ivory horn, all three actions (512 for a crisp horn):
A="--toon --color red --bands 3 --accents --horn-style ivory --outline --size 512 --view side"
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_idle.fbx  --actor bull --action idle  --frames 2 $A
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_walk.fbx  --actor bull --action walk  --frames 6 $A
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_throw.fbx --actor bull --action throw --frames 5 $A
# then: pack_or_rename.sh rename bull <action>  ->  copy PNGs into Assets.xcassets/Game/
```

## The matador (done, 2026-07-12)

The game's **matador** is the kidnapped bullfighter — a **static, single-frame GOAL figure**
standing beside the bull on the top platform (the player rescues him to win). No animation, no
in-game rig: one `Image("matador")` in `GameView.matadorSprite`. Same store/license lane as the
dancer: CGTrader vfxsinghbu **"Matador - Bullfighter Rigged"** (#5905689, CGTrader Royalty-Free /
no-AI, `asset-licenses/cgtrader-matador.txt`), a Daz **Genesis 8 Male**. Only the rendered PNG
ships; the raw `.blend/.fbx/.rar` stay git-ignored.

### Pipeline: `gen_matador.py` → `render_sprites.py --matador`

```bash
# 1. raw purchase -> posed blend (clean scene + pose arms + place montera)
blender -b tools/blender/source/matador.blend -P tools/blender/gen_matador.py
# 2. posed blend -> one sprite PNG.  --view back = the FACE (the model faces -Y).
blender -b tools/blender/source/matador_posed.blend -P tools/blender/render_sprites.py -- \
    --actor matador --action idle --frames 1 --size 512 --view back \
    --toon --matador --outline --out tools/blender/renders
# 3. crop + name -> dist/matador_idle_1.png (records the WxH crop box)
tools/blender/pack_or_rename.sh rename matador idle
# 4. -> Conjugar/Assets.xcassets/Game/matador.imageset/matador.png  (single universal asset)
```

- **`gen_matador.py`** cleans the raw scene (drops ~25 junk objects + the cape, hides the heavy
  vendor hair — hidden `hide_render` meshes are now skipped by the renderer so they neither draw
  nor inflate the auto-fit), then poses the figure. **The Daz rig has IK constraints that
  override FK**, so posing the arms does nothing until the script **clears all 255 pose-bone
  constraints** and re-poses the arms **hands-on-hips in pure FK**. It also **repositions/scales
  the montera** (a vertex-level reposition) onto the head, raised so the eyes + a little forehead
  show. Output: `source/matador_posed.blend`.
- **`--matador`** is a per-garment cel mode (requires `--toon`). Because Genesis-8 splits the
  outfit into separate garment meshes, `MATADOR_MESH_COLORS` maps mesh-name substrings to colors:
  jacket/pants **blue**, vest/hat **gold**, socks **pink**, shoes **dark-red** (= `red × 0.60`,
  the bull's hoof color), shirt **cream**, body **skin**. The **Cape mesh is deleted** in
  `gen_matador.py`, not colored. Marked forms are lowercased before the model (irrelevant here —
  that's the tutor path — but the palette added the `blue/pink/skin/cream` hues).
- **`--view back` shows the FACE** — the Genesis-8 model faces **−Y** (so `--view front` shows
  his back). He renders **front-on**, hands on hips; unlike the side-rendered dancer/bull he is
  therefore **never mirrored** in `GameView`.
- **Resolution: 512 + `.interpolation(.high)`** (the bull lesson) — he displays fairly large
  beside the bull, so a 512 render downscaled with smooth interpolation keeps the face/montera
  and the Freestyle outline crisp; nearest-neighbor frays the outline.
- **Crop box → `GameView` constants** (the recurring coupling): the union crop is **188×452**;
  `GameView` holds a constant `matadorVisualHeight` and derives width from `188/452`, with a feet
  offset planting his shoes on `Platform.surfaceY`. Re-capture the box from `pack_or_rename.sh` if
  he's ever re-rendered — don't reuse the dancer/bull numbers.
- **For a future animated matador** (Josh asked): the mesh is fully rigged. Restore/drive the Daz
  IK targets (`lHand_IK` / `rHand_IK`) or hand-key FK like `gen_dancer_action.py`, then render N
  frames through `render_sprites.py --matador` and extend `matadorSprite` to a flipbook.
