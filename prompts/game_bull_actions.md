# Plan — Produce the bull's three actions and ship them (Phases 2–7)

**Goal:** turn the rigged bull sourced in Phase 1 into the game's three bull flipbooks —
**idle (2), walk (6), throw (5)** — and wire them into `GameView.bullSprite`, retiring the
**last numbered placeholder box** in the game. Success = in `conjugar://game` the bull on the
top platform walks back and forth as a rendered bull, plays a throw each time it hurls a flag,
correct facing, feet on the platform, and **no yellow `Text(verbatim:)` box anywhere** (player
*and* bull are sprites).

This continues `prompts/game_bull.md` (the master bull plan). **Phase 1 is done** — this file
supersedes that plan's Phase 1 and its generic Phase 2, because we now know *exactly which
model we have and how its rig behaves* (reconnaissance below). Phases 3–7 follow the proven
dancer pipeline; this file re-specifies them with the bull's model-specific details baked in.

Fresh-session, **higher-risk** task (hand-keyed quadruped animation) — read the context and the
reconnaissance before touching Blender.

---

## Current state (Phase 1 complete — committed to `migration`, commit 369bdce)
- **Source model chosen + rigged `.blend` saved.** `tools/blender/source/bull.blend` (git-ignored)
  holds the mesh + armatures + the model's baked animation. Raw `tools/blender/source/bull.fbx`
  also git-ignored. Only rendered PNGs will ship.
- **Model:** "Simple Rigged Bull" by **Leo_Aguiar**, Sketchfab, **CC BY 4.0**. Provenance +
  required attribution already logged in `asset-licenses/sketchfab-bull.txt`. (No frames ship
  without that file — it exists; finalize it in Phase 7 with the shipped-frame list.)
- **The player is fully sprite-animated;** the numbered-box fallback in `GameView` now fires
  **only for the bull** — this plan removes the last one.

## Reconnaissance — how THIS rig actually behaves (read before Blender; verified 2026-07-11)
Established by headless Blender inspection + a 10-frame probe render of the model's baked clip.
These facts reshape Phase 2, so internalize them:

1. **Orientation / facing (matches the dancer convention exactly).** The bull's length runs
   along **Y**, up is **Z** (feet at Z≈0, ~1.6 units tall), width along X. Rendered with
   `--view side` (camera on −X) it is a **clean side profile facing LEFT** (head left, tail
   right) — the *same* "renders face left, game mirrors when facing right" rule the dancer uses.
   So Phase 5's mirror rule is: mirror (`-1`) when `bullFacing >= 0` (facing right). Scale is
   irrelevant — the harness auto-fits the mesh bounds.
2. **The baked clip (`rigAction`, frames 1..105) is an IDLE, not a walk.** It is a subtle,
   **In-Place** standing sway — planted legs, tiny body/head motion (silhouette area is ~constant
   across the whole range). Consequences:
   - **`idle` is essentially free:** sample 2 frames from `rigAction` and you have a valid idle.
   - **There is NO free walk.** The "bonus baked walk" the master plan hoped for did **not**
     materialize. **`walk` must be hand-keyed** (a quadruped gait). Budget for it.
3. **The Rigify *control* logic did NOT survive the FBX round-trip.** The imported `rig` (381
   bones) has **0 bone constraints, 0 drivers, 0 widget shapes** — the IK/FK "controls" are an
   inert bone hierarchy that drives nothing. **BUT** the mesh is skinned to the **`DEF-` bones**,
   and `rigAction` keys *every* bone (including all `DEF-`/`*_fk` bones) directly — which is why
   the baked idle still deforms the mesh. **Implication for authoring:** posing the "control"
   bones (torso/hips/`*_ik`) does nothing; you must key the bones the mesh is weighted to. Two
   viable paths, below.

## Two rig paths for hand-keying walk + throw (pick per Phase-2 sub-step)
- **Path B — key the deform/FK bones directly (recommended default).** The mesh deforms via the
  directly-keyed `DEF-`/`*_fk` bones (proven: the baked idle works this way). For only three
  short, tiny-rendered actions this is the pragmatic path: pose+key the relevant leg bones
  (`*_thigh`, `*_shin`, `*_foot`, `*_toe` — front L/R + rear `thigh/shin/foot` L/R) for the walk,
  and the spine/neck/head chain for the throw, FK-style. At 6 frames / 70-px sprite size, a
  clean leg-alternation reads as a walk; per-joint IK polish is wasted.
- **Path A — regenerate a working Rigify rig from the metarig (optional, if you want real IK
  legs).** The intact **`metarig`** (49 bones, Basic Quadruped) is present. **Risk to verify
  first:** FBX import likely stripped the metarig's `rigify_type` custom props + bone-collection
  assignments, so Blender's **Rigify ▸ Generate Rig** may produce nothing. Before betting on this,
  check in Blender whether the metarig bones still carry `rigify_type`. If they don't, either
  rebuild a fresh Rigify Basic Quadruped metarig, snap it to the mesh, and re-skin (heavy), or
  fall back to Path B. **Do not sink hours into rig regeneration** — Path B ships.

---

## The bull's exact seam (authoritative — match N to this; unchanged from `game_bull.md`)
From `Conjugar/Models/Game/GameState+Animation.swift` and `GameModels.swift`:

```swift
enum BullAction { case idle, walk, `throw` }               // GameModels.swift (~:63)

static let bullFrameCounts: [BullAction: Int] = [           // GameState+Animation.swift (~:19)
  .idle: 2, .walk: 6, .throw: 5
]

private func derivedBullAction() -> BullAction {            // (~:56)
  bullThrowTimer > 0 ? .throw : .walk                       // idle is init/reset only
}
```

Render **idle → 2, walk → 6, throw → 5**. Two subtleties (still true):
- **`idle` is never *derived* in play** — only the init/reset value. In play the bull shows
  **walk** (patrolling) and **throw** (hurling a flag). Render idle to match the table (2 frames
  off `rigAction` is plenty); don't over-invest.
- **`throw` is a 0.5 s one-shot, not a loop.** `bullThrowTimer = bullThrowDuration = 0.5s`
  (`GameState.swift:54`, `GameState+Flags.swift:37`); 5 frames × (1/`fps`=1/10 s) = **exactly
  0.5 s**. The flag spawns at throw *start* (`spawnFlag()` then sets the timer,
  `GameState+Flags.swift:34-37`), so the 5 frames must read **windup → release**, release landing
  around frame 4–5.

## The bull in the game (so the animations fit the behavior; unchanged)
- Sits on the **top platform**, `bullX = w*0.4`, walks back and forth; `bullFacing` (±1) tracks
  direction (`GameState.swift:155-161, 289-295`). It faces and pelts the player.
- **Collision size is `bullSize = 70`** (a square today). A bull silhouette is **wider than tall**,
  so the *visual* sprite should overhang that box — exactly as the dancer's visual
  (`dancerVisualHeight = 56`) overhangs `playerHeight` via `dancerFeetOffset`
  (`GameView.swift:30-31`). Keep `bullSize` for collision; give the sprite its own visual height +
  per-action width.
- Facing is shown today by a **chevron** (`facingChevron`, `GameView.swift:162-176`). With a real
  sprite we **mirror the sprite** by `bullFacing` and **delete the chevron**.

## Read first
1. **This file's reconnaissance section** (above) — the rig behavior is the whole ballgame.
2. `prompts/game_bull.md` — the master plan (Phases 3–7 rationale, license gate, not-in-scope).
3. `prompts/game_dancer_actions.md` + `prompts/game_climb_back_view.md` — the harness workflow,
   one-visual-height/per-action-width sizing, the render-faces-left/mirror rule, and the
   `spriteActions`/`actionName`/`dancerWidth`/`dancerMirror` generalization to copy for the bull.
4. `tools/blender/README.md` — harness args (`--view`, `--start/--end`, `--frames`, `--size`,
   `--toon`) and the pipeline.
5. `Conjugar/Views/GameView.swift` — `bullSprite` (~:162), `facingChevron`, and the dancer helpers
   (`dancerVisualHeight`, `dancerFeetOffset`, `dancerWidth`, `dancerMirror`, `spriteActions`,
   `actionName`) to mirror for a `bull*` equivalent.
6. `Conjugar/Models/Game/GameState+Animation.swift` (`bullFrameCounts`, `derivedBullAction`,
   `bullFrame`) + `GameState+Flags.swift` (throw timing / flag spawn).

---

## Phase 2 — Author idle / walk / throw on the rig  [Claude, GUI via blender-mcp]
Work in `tools/blender/source/bull.blend`. Drive Blender through **blender-mcp**
(`execute_blender_code` for the keying, `get_viewport_screenshot` to sanity-check poses). Keep
the bull a **left-facing side profile** throughout (matches the render convention and reads
naturally for a quadruped on a platform). Author each action as its **own Blender action** (name
them `bull_idle`, `bull_walk`, `bull_throw`) so Phase 3 can export one FBX per action.

- **idle (2 frames) — nearly free.** Duplicate/trim `rigAction` (or just mark two frames of it)
  into a 2-frame `bull_idle`. A subtle weight-shift/breath is the goal; the existing sway already
  is one. Keep it **In-Place**.
- **walk (6 frames) — the first real hand-key.** A cyclic **quadruped walk**, In-Place (no root
  translation, or the auto-fit inflates and the sprite shrinks — same rule as Mixamo). Use a
  4-beat gait: key **contact → passing → contact** poses for the diagonal leg pairs and let the
  harness sample 6 frames across the loop; make the closing pose equal the opening one (the
  harness drops it via the half-open `[start,end)` so the 6 frames tile). Path B: rotate the
  `front_thigh/front_shin/front_foot` (L/R) and rear `thigh/shin/foot` (L/R) FK/DEF bones. At
  sprite size a readable leg-alternation + slight body bob is enough; don't chase realism.
- **throw (5 frames) — the bespoke one-shot, no shortcut.** Head/horns/neck **wind up then snap
  forward** to fling a flag, ~0.5 s. Hand-key ~5 poses so the 5 rendered frames read
  **windup → release**, release at frame 4–5 (the flag spawns at throw *start*). Path B: key the
  spine → neck → head DEF/FK chain (and a little front-leg brace). Keep it In-Place.

Sanity-check each action with `get_viewport_screenshot` as you key. Save `bull.blend` often.

## Phase 3 — Render each action  [Claude, headless]
**Export one FBX per action** from `bull.blend` (set the rig's active action, export
`tools/blender/source/bull_<action>.fbx` with that single action) — this matches the proven
dancer `--fbx` flow and sidesteps multi-action ambiguity. (Alternative if you keep all three as
one timeline: render from the open `.blend` and carve ranges with `--start/--end` — the harness
honors those over the action range. Per-action FBX is simpler; prefer it.)

Render, **matching N to `bullFrameCounts`**, `--view side` (a platform bull is a side actor — no
back-view special-case like the dancer's climb), left-facing:

```bash
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_idle.fbx  --actor bull --action idle  --frames 2 --size 192 --view side --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_walk.fbx  --actor bull --action walk  --frames 6 --size 192 --view side --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull_throw.fbx --actor bull --action throw --frames 5 --size 192 --view side --out tools/blender/renders
```

Then crop + rename:

```bash
tools/blender/pack_or_rename.sh rename bull idle
tools/blender/pack_or_rename.sh rename bull walk
tools/blender/pack_or_rename.sh rename bull throw
```

Record each printed **common crop box** (`WxH`) — you need the aspect for Phase 5. Expect
**width > height** (quadruped). **Throw caveat:** `pack_or_rename` union-crops across the whole
action, so a big forward horn-thrust on the release frame widens the box for all 5 (consistent
framing — fine; throw will be widest). **Half-open `[start,end)`** drops the loop-closing frame
— right for the cyclic walk, but for the **one-shot throw** you may want the final release pose
*included*; if frame 5 looks cut, nudge with `--end` (or render `--frames 6` and drop the first)
so the release lands.

## Phase 4 — Add the imagesets  [Claude]
Add `bull_<action>_<i>.imageset` (idle×2, walk×6, throw×5) under
`Conjugar/Assets.xcassets/Game/`, same shape as the dancer imagesets (`Contents.json` + single
universal PNG). The catalog is a **synchronized group** — no `project.pbxproj` edit. Script the
loop as the dancer setup did.

## Phase 5 — Wire `bullSprite` (mirror the dancer generalization)  [Claude]
Replace the box in `GameView.bullSprite` (~:162) with the sprite path, reusing the dancer pattern:
- Add `bullSpriteActions: Set<BullAction> = [.idle, .walk, .throw]`, a `bullActionName(_:) -> String`,
  a `bullWidth(_:)` from each Phase-3 crop aspect at a constant `bullVisualHeight`, and a
  `bullFeetOffset` (`-(bullVisualHeight - bullSize)/2`, as the dancer does). Pick `bullVisualHeight`
  so the bull reads a touch bigger/heavier than the player but stays on-platform (start ~56–64; tune
  in Phase 6).
- Render `Image("bull_\(bullActionName(action))_\(gameState.bullFrame)")` `.resizable()`
  `.interpolation(.none)` `.scaledToFit()`, framed `bullWidth × bullVisualHeight`,
  `.scaleEffect(x: bullMirror, y: 1)`, offset by `bullFeetOffset`, positioned at `bullX,bullY`.
- **Facing:** renders face left → mirror (`-1`) when `bullFacing >= 0` (facing right) — **confirmed
  by reconnaissance**, same rule as the player's non-climb actions. **Delete `facingChevron`** for
  the bull; remove the helper if nothing else uses it.
- Keep the numbered-box **fallback** for any `BullAction` not in `bullSpriteActions` (defensive; all
  three are covered).

## Phase 6 — Verify in-app  [Claude + Josh]
Build (`ios-build-verify`), then drive `conjugar://game`. **Do NOT set
`CONJUGAR_GAME_DISABLE_FLAGS`** — you *need* flags on to see the throw:
- **walk** — watch the bull patrol the top platform: rendered bull, feet on the platform, correct
  facing each direction (mirror flips at the turns), no box.
- **throw** — wait for / provoke a flag toss: the 5-frame throw plays windup→release in sync with
  the flag spawning, then returns to walk. Use `CONJUGAR_GAME_TIME_SCALE=0.2` to freeze-frame the
  0.5 s throw (as with the jump/climb). Launch-env recipe is in `CLAUDE.md` ("Freeze-framing").
- Confirm the bull is sized/planted right relative to the player and platforms; confirm **no
  numbered box anywhere** in the game (player *and* bull now sprites).
Screenshot walk + throw (hold-and-capture recipe in `CLAUDE.md`).

## Phase 7 — Document + commit  [Claude]
- `asset-licenses/sketchfab-bull.txt` — **finalize** the STATUS/frame-list lines with the shipped
  frames (`bull_{idle,walk,throw}_*`); the attribution + provenance are already written. Add the
  bull credit to the app's **Credits** screen (Info ▸ Credits) alongside "Game Music"/"Game Sounds"
  (the license file has a TODO for this) — "Game Art — Bull", CC BY, crediting Leo_Aguiar + the
  model URL.
- `tools/blender/README.md` — turn the speculative "The bull (later)" section into the **done**
  record: Simple Rigged Bull (Rigify quadruped) was the source; idle came free from the baked clip,
  walk + throw were hand-keyed on the DEF/FK bones (Rigify controls didn't survive FBX); note the
  per-action framing; add the bull to the "actor" examples.
- `docs/blog_notes.md` — the Phase-2 story (idle-was-free, walk+throw hand-keyed, the dead-controls
  discovery and DEF-bone workaround, "the last numbered box is gone"). A Phase-1 note already exists.
- Commit to the **`migration`** branch (raw `.blend`/`.fbx` stay git-ignored — only PNGs ship).

## Definition of done
- `bull_{idle,walk,throw}` imagesets exist with the **exact** `bullFrameCounts` counts (2/6/5),
  rendered through `render_sprites.py --actor bull --view side`.
- `GameView.bullSprite` renders real sprites for all three bull actions, correct facing (sprite
  mirrored by `bullFacing`, chevron removed), feet platform-aligned; numbered-box fallback remains
  only as a defensive safety net.
- Verified live via `conjugar://game`: bull walks and throws as rendered art; **no numbered box
  appears for either actor** in any state.
- `asset-licenses/sketchfab-bull.txt` finalized + bull credited in the Credits screen; README
  updated; blog note added; committed to `migration`.

## Not in scope (later sessions) — from `game_bull.md`
- **Toon/palette pass** (cel look in Conjugar red/gold; `--toon` scaffolding exists) — apply to
  dancer **and** bull together later. (The model ships untextured/flat, so a palette pass would suit
  it well when that session comes.)
- **Custom flamenco-dancer mesh** (replace the X Bot mannequin).
- **A bull "defeat"/hit reaction** — not in `BullAction` today; would need a new enum case,
  frame-count entry, derivation trigger, and render.
- **The bullfighter** (`bullfighterEmoji`) and **flag** art — still emoji; separate stills job.

## Gotchas (model-specific — the important ones for THIS rig)
- **No free walk.** `rigAction` is an idle, not a walk (reconnaissance). idle is free (2 frames off
  it); **walk and throw are both hand-keyed.** Don't waste time hunting for a baked walk clip.
- **Rigify controls are dead** (0 constraints/drivers/widgets after FBX). Posing `*_ik`/`torso`/
  `hips` does nothing — key the **`DEF-`/`*_fk`** bones the mesh is skinned to (Path B). Only pursue
  Rigify **regeneration** (Path A) if you first confirm the metarig kept its `rigify_type` props, and
  even then only if you want real IK legs — Path B ships.
- **In-Place** every action (no root translation) or the auto-fit inflates and the sprite shrinks.
- **Match N to `bullFrameCounts` exactly** (idle 2 / walk 6 / throw 5). Change a count → change both
  the table and the render.
- **`throw` is a 0.5 s one-shot** — 5 frames = exactly `bullThrowDuration`; make sure the **release**
  frame survives the half-open `[start,end)` crop (nudge `--end` if cut). Flag spawns at throw
  *start* → read as windup→release.
- **Visual size vs collision:** keep `bullSize` (70) for collision; let the *visual* sprite (wider
  than tall) overhang via `bullVisualHeight` + `bullFeetOffset`, like the dancer's visual/collision
  split. Verify feet sit on the platform.
- **Facing:** renders face **left** (confirmed); mirror when `bullFacing >= 0`; **remove
  `facingChevron`**.
- **Raw mesh/rig stays git-ignored** (`source/`, `*.blend`, `*.fbx`); only rendered PNGs ship.
- **License already logged** (`asset-licenses/sketchfab-bull.txt`, CC BY, Leo_Aguiar) — just
  finalize the frame list + add the Credits-screen line in Phase 7.
- **Verify with flags ON** (don't set `CONJUGAR_GAME_DISABLE_FLAGS`) or the throw never fires; use
  `CONJUGAR_GAME_TIME_SCALE=0.2` to catch it.
- **SourceKit false positives** editing `GameView.swift` — `build_app.sh` is authoritative; trust it.
