# Plan — Give the bull real sprites (retire the last numbered box)

**Goal:** replace the bull's placeholder numbered-box with a real rendered flipbook for
its three actions — **idle, walk, throw** — so *nothing* in the game shows a debug box
anymore (the player went fully sprite-animated in `game_dancer_actions.md` +
`game_climb_back_view.md`; the bull is the last placeholder). Success = in
`conjugar://game` the bull on the top platform walks back and forth as a rendered bull and
plays a throw animation each time it hurls a flag, correct facing, feet on the platform,
no yellow `Text(verbatim:)` box.

Fresh-session, **higher-risk** task — read the context first. This is the quadruped the
dancer plans deliberately deferred as "the cost center."

## Why the bull is harder than the dancer (read this before estimating)
The dancer was cheap because **Mixamo** hands you a rigged biped + royalty-free mocap for
free, and the render harness is pure headless CLI. **None of that applies to a quadruped:**
- **Mixamo is biped-only** — no auto-rig, no mocap for a four-legged bull.
- So the bull needs a mesh **and a rig you drive yourself**, and at least the **throw**
  (a bull hurling a flag) is bespoke — there's no stock clip; it will almost certainly be
  **hand-keyed** in Blender.
- Model licensing is **per-asset**, not a blanket grant. A Sketchfab model must have its
  individual license read, confirmed compatible with this **public AGPL** repo, and logged.

This is the one game-asset job where the **interactive blender-mcp path earns its keep**
(rig + hand-key are GUI work), not just the headless `render_sprites.py` CLI.

## Current state (already complete — this plan is the next step)
- **Render harness is proven** across five dancer actions: `tools/blender/render_sprites.py`
  (headless Blender: import → clear default cube → auto-fit orthographic camera over the
  action's frame range → EEVEE Next → transparent RGBA PNG → N evenly-sampled frames) and
  `tools/blender/pack_or_rename.sh` (union-crop all frames to one box, rename to
  `<actor>_<action>_1..N.png`). It already takes `--actor` — `--actor bull` just changes the
  output folder/prefix. Documented in `tools/blender/README.md` (see its "The bull (later)"
  note).
- **The player is fully sprite-animated**; the numbered-box fallback in `GameView` now fires
  only for the bull.
- **blender-mcp is wired** (addon vendored at `tools/blender/blender-mcp/`, MCP registered).
  The MCP exposes `execute_blender_code`, `get_scene_info`/`get_viewport_screenshot`,
  **Sketchfab** search/download, and **Hyper3D/Hunyuan** text/image→3D. Unlike the dancer,
  this plan will likely use it.
- **Claude-in-Chrome MCP is available — Claude should drive it wherever it can.** The
  dancer plan drove **Mixamo** through it (search a clip → apply → check In Place → download
  FBX). The same applies here for **Sketchfab**: Claude can browse the site, audition models,
  **read the exact per-model license on the model page** (the authoritative source, more
  reliable than an API license field), and initiate downloads directly in the browser. Load
  the tools with one `ToolSearch` (`tabs_context_mcp`, `navigate`, `read_page`/`get_page_text`,
  `computer`, `tabs_create_mcp`), start with `tabs_context_mcp`, and prefer a new tab.
  **Josh can and will create accounts / authenticate** (Sketchfab, Adobe, any gated
  download) whenever a step needs a login — hand off to him for the auth step, then resume
  driving. Between the browser MCP and the blender-mcp Sketchfab tools, prefer whichever
  gets a clean, license-verified download; the browser is best for *judging + license*, the
  blender-mcp for *pulling the asset into the scene*.

## The bull's exact seam (authoritative — match N to this)
From `Conjugar/Models/Game/GameState+Animation.swift` and `GameModels.swift`:

```swift
enum BullAction { case idle, walk, `throw` }               // GameModels.swift:63

static let bullFrameCounts: [BullAction: Int] = [           // GameState+Animation.swift:19
  .idle: 2, .walk: 6, .throw: 5
]

private func derivedBullAction() -> BullAction {            // :56
  bullThrowTimer > 0 ? .throw : .walk                       // idle is init/reset only
}
```

So render **idle → 2, walk → 6, throw → 5** frames. Two subtleties:
- **`idle` is never *derived*** — it's only the init/reset value, overwritten on the first
  `advanceAnimations`. In play the bull shows **walk** (patrolling the top platform) and
  **throw** (when it hurls a flag). Render idle anyway to match the table and cover reset,
  but don't burn effort on it — a 2-frame near-still is plenty.
- **`throw` is a one-shot, not a loop.** `bullThrowTimer = bullThrowDuration = 0.5s`
  (`GameState.swift:54`, `GameState+Flags.swift:37`), and 5 frames × (1/`fps`=1/10 s) =
  **exactly 0.5 s** — one clean play-through of a windup→release. The flag actually spawns
  at throw start (`spawnFlag()` then sets the timer, `GameState+Flags.swift:34-37`), so the
  5 frames should read as *wind up → release*, releasing around frame 4–5.

## The bull in the game (so the animations fit the behavior)
- Sits on the **top platform**, `bullX = w*0.4`, walks back and forth; `bullFacing` (±1)
  tracks direction (`GameState.swift:155-161, 289-295`). It faces and pelts the player.
- **Collision/logic size is `bullSize = 70`** (a square box today). A bull silhouette is
  **wider than tall**, so the *visual* sprite should be free to overhang that box — exactly
  as the dancer's visual (`dancerVisualHeight = 56`) overhangs `playerHeight` with a
  `dancerFeetOffset` (`GameView.swift:30-31`). Keep `bullSize` for collision; give the
  sprite its own visual height + per-action width.
- Facing today is shown by a **chevron** (`facingChevron`, `GameView.swift:162-176`) because
  a mirrored *digit* looks wrong. With a real sprite we **mirror the sprite** by
  `bullFacing` and **delete the chevron**.

## Read first
1. `prompts/game_dancer_actions.md` and `prompts/game_climb_back_view.md` — the harness
   workflow, the one-visual-height/per-action-width sizing, the render-faces-left/mirror
   rule, and the `spriteActions`/`actionName`/`dancerWidth`/`dancerMirror` generalization to
   mirror for the bull.
2. `tools/blender/README.md` — harness args and the **"The bull (later)"** section (Sketchfab
   "Simple Rigged Bull" / Rigify quadruped meta-rig guidance).
3. `Conjugar/Views/GameView.swift` — `bullSprite` (:162), `facingChevron`, and the dancer
   helpers (`dancerVisualHeight`, `dancerFeetOffset`, `dancerWidth`, `dancerMirror`,
   `spriteActions`, `actionName`) to copy the pattern for a `bull*` equivalent.
4. `Conjugar/Models/Game/GameState+Animation.swift` (`bullFrameCounts`, `derivedBullAction`)
   and `GameState+Flags.swift` (throw timing / flag spawn).
5. `docs/game_design_research.md` §3 (asset pipeline) and its bull notes.

---

## Phase 1 — Source a bull mesh + rig  [Claude + Josh — decision fork]
Pick **one** path (audition cheapest first; escalate only if it reads badly). Whatever the
source, the deliverable of this phase is **a rigged bull in a `.blend`** you can pose.

- **(A) Sketchfab, already rigged (try first).** **Drive this in Claude-in-Chrome** —
  browse Sketchfab (filter *Animated* + *Downloadable*), audition candidates on the model
  page, and **read the license right off the page**. Fall back to the blender-mcp tools
  (`search_sketchfab_models` → `get_sketchfab_model_preview` → `download_sketchfab_model`)
  when they give a cleaner pull into the scene. If a **download or account is gated, hand
  the auth/login step to Josh** (he'll create the account / sign in), then resume driving.
  **Bonus win:** some Sketchfab bulls ship *with baked animations* (walk/idle) — if so,
  those render straight through `render_sprites.py` via the clip's frame range, and only
  **throw** needs hand-keying. **License gate (blocking):** read the model's individual
  license; it must permit redistribution inside an AGPL app (CC-BY / CC0 fine with
  attribution; **CC-BY-NC or "editorial only" is disqualifying**). If unclear, reject it.
- **(B) Rigify quadruped meta-rig (fallback).** Take a static bull mesh (Sketchfab CC0, or
  a Poly Haven-style source), add Blender's **Rigify horse/quadruped meta-rig**, fit bones,
  generate the rig, skin it. Then Phase 2 is all hand-key.
- **(C) Generate the mesh (last resort).** `generate_hyper3d_model_via_text`/`_via_images`
  ("a stylized fighting bull, low-poly") or Hunyuan, then rig via (B). Cheapest to *get* a
  mesh, most work to make it animate well; only if A/B fail.

**Recommend A**, since a pre-animated rigged bull could collapse Phases 1–2 into "download +
render." Present Josh 2–3 candidate Sketchfab models (preview + license) and let him pick —
this is his call the way the climb-angle judgment was.

Save the working file as `tools/blender/source/bull.blend` (git-ignored) and log provenance
immediately in `asset-licenses/<source>-bull.txt` (e.g. `sketchfab-bull.txt`): model name,
author, URL, exact license, attribution text. **No asset proceeds without this file.**

## Phase 2 — Produce the three actions  [Claude, GUI via blender-mcp]
Get **idle (2), walk (6), throw (5)** as animation ranges on the rig:
- **walk** — a cyclic quadruped walk (4-beat gait). Use a baked Sketchfab clip if (A)
  provided one; else hand-key a short loop (contact → passing → contact) and let the
  harness sample 6 frames. Keep it **In-Place** (no root translation) so the sprite stays
  centered, exactly like the Mixamo In-Place rule.
- **throw** — bespoke **one-shot**: head/horns/neck wind up then snap forward to fling a
  flag, ~0.5 s. Hand-key ~5 poses so the 5 rendered frames read windup→release, release at
  frame 4–5 (the flag spawns at throw start). This is the animation with no shortcut.
- **idle** — a 2-frame subtle weight-shift/breath. Minimal.

Sanity via `get_viewport_screenshot` as you key. Orient the bull as a **left-facing side
profile** (matches the dancer convention: renders face left, game mirrors when facing
right) — a side profile is also the natural read for a quadruped patrolling a platform.

## Phase 3 — Render each action  [Claude, headless]
Export/keep the actions and render with the proven CLI, **matching N to `bullFrameCounts`**
(`--view side` — a bull on a platform is a side actor; no back-view special-case like climb):

```bash
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull.fbx --actor bull --action idle  --frames 2 --size 192 --view side --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull.fbx --actor bull --action walk  --frames 6 --size 192 --view side --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/bull.fbx --actor bull --action throw --frames 5 --size 192 --view side --out tools/blender/renders
```

(If the rig lives in a `.blend` with multiple actions rather than per-action FBX, either
export one FBX per action, or add per-action frame-range handling — `--start/--end` already
exist — and render from the open scene. Prefer per-action FBX to match the dancer flow.)

Then crop + rename:

```bash
tools/blender/pack_or_rename.sh rename bull idle
tools/blender/pack_or_rename.sh rename bull walk
tools/blender/pack_or_rename.sh rename bull throw
```

Record each printed **common crop box** (`WxH`) — you need the aspect for Phase 5. Expect
**width > height** (quadruped). **Throw caveat:** `pack_or_rename` union-crops across the
*whole* action, so a big forward horn-thrust on the release frame widens the box for all 5 —
fine (consistent framing), just expect throw to be the widest. Also, the harness samples
**half-open `[start, end)`** (drops the loop-closing frame) — right for the cyclic walk, but
for the **one-shot throw** you may want the final release pose *included*; if frame 5 looks
cut, nudge with `--end` (or render `--frames 6` and drop the first) so the release lands.

## Phase 4 — Add the imagesets  [Claude]
Add `bull_<action>_<i>.imageset` (idle×2, walk×6, throw×5) under
`Conjugar/Assets.xcassets/Game/`, same shape as the dancer imagesets (`Contents.json` +
single universal PNG). The catalog is a **synchronized group** — no `project.pbxproj` edit.
Script the loop as the dancer setup did.

## Phase 5 — Wire `bullSprite` (mirror the dancer generalization)  [Claude]
Replace the box in `GameView.bullSprite` (:162) with the sprite path, reusing the dancer
pattern:
- Add `bullSpriteActions: Set<BullAction> = [.idle, .walk, .throw]`, a
  `bullActionName(_:) -> String`, a `bullWidth(_:)` from each Phase-3 crop aspect at a
  constant `bullVisualHeight`, and a `bullFeetOffset` (`-(bullVisualHeight - bullSize)/2`,
  as the dancer does). Pick `bullVisualHeight` so the bull reads a touch bigger/heavier than
  the player but stays on-platform (start ~56–64; tune in Phase 6).
- Render `Image("bull_\(bullActionName(action))_\(gameState.bullFrame)")` `.resizable()`
  `.interpolation(.none)` `.scaledToFit()`, framed `bullWidth × bullVisualHeight`,
  `.scaleEffect(x: bullMirror, y: 1)`, offset by `bullFeetOffset`, positioned at
  `bullX,bullY`.
- **Facing:** renders face left → mirror (`-1`) when `bullFacing >= 0` (facing right), same
  rule as the player's non-climb actions. **Delete `facingChevron`** for the bull (the
  sprite now shows facing); remove the helper if nothing else uses it.
- Keep the numbered-box **fallback** for any `BullAction` not in `bullSpriteActions`
  (defensive; all three are covered).

## Phase 6 — Verify in-app  [Claude + Josh]
Build (`ios-build-verify`), then drive `conjugar://game`. **Do NOT set
`CONJUGAR_GAME_DISABLE_FLAGS`** here — you *need* flags on to see the throw:
- **walk** — watch the bull patrol the top platform: rendered bull, feet on the platform,
  correct facing each direction (mirror flips at the turns), no box.
- **throw** — wait for / provoke a flag toss: the 5-frame throw plays as windup→release in
  sync with the flag spawning, then returns to walk. Use `CONJUGAR_GAME_TIME_SCALE=0.2` to
  freeze-frame the 0.5 s throw (as with the jump/climb).
- Confirm the bull is sized/planted right relative to the player and platforms; confirm
  **no numbered box anywhere in the game** (player *and* bull now sprites).
Screenshot walk + throw (hold-and-capture recipe in CLAUDE.md).

## Phase 7 — Document + commit  [Claude]
- New `asset-licenses/<source>-bull.txt` (from Phase 1) — finalize with the shipped-frame
  list (`bull_{idle,walk,throw}_*`) and attribution.
- `tools/blender/README.md` — turn the speculative "The bull (later)" section into the
  **done** record: which source/rig path was used, that walk/idle/throw ship, any per-action
  framing notes; add the bull to the "actor" examples.
- `docs/blog_notes.md` entry (per CLAUDE.md) — the quadruped-vs-Mixamo story, the
  source/rig path taken, hand-keying the throw, and "the last numbered box is gone."
- Commit to the **`migration`** branch.

## Definition of done
- `bull_{idle,walk,throw}` imagesets exist with the **exact** `bullFrameCounts` counts
  (2/6/5), rendered through `render_sprites.py --actor bull`.
- `GameView.bullSprite` renders real sprites for all three bull actions, correct facing
  (sprite mirrored by `bullFacing`, chevron removed), feet platform-aligned; numbered-box
  fallback remains only as a defensive safety net.
- Verified live via `conjugar://game`: bull walks and throws as rendered art; **no numbered
  box appears for either actor** in any state.
- Bull model license read, compatible with AGPL redistribution, and logged in
  `asset-licenses/`; README updated; blog note added; committed to `migration`.

## Not in scope (later sessions)
- **Toon/palette pass** (cel look in Conjugar red/gold; `--toon` scaffolding exists) —
  apply to dancer **and** bull together later.
- **Custom flamenco-dancer mesh** (replace the X Bot mannequin).
- **A bull "defeat"/hit reaction** — not in `BullAction` today; would need a new enum case,
  frame-count entry, derivation trigger, and render. Only if the game later rewards goring
  the bull.
- **The bullfighter** (`bullfighterEmoji`, a static emoji beside the bull) and **flag** art —
  still emoji; separate stills job.

## Gotchas
- **No Mixamo for the bull** — biped-only. Expect to source+rig and **hand-key the throw**;
  budget accordingly. This is the point of the whole plan.
- **Match N to `bullFrameCounts` exactly** (idle 2 / walk 6 / throw 5). Change a count →
  change both the table and the render.
- **`throw` is a 0.5 s one-shot, not a loop** — 5 frames = exactly `bullThrowDuration`;
  make sure the **release** frame survives the half-open `[start,end)` crop (nudge `--end`
  if cut). The flag spawns at throw *start*, so read as windup→release.
- **`idle` is init/reset-only** — never derived in play; render it to match the table but
  spend the effort on walk + throw.
- **In-Place** the walk (no root translation) or the auto-fit inflates and the sprite
  shrinks — same rule as Mixamo.
- **Visual size vs collision:** keep `bullSize` (70) for collision; let the *visual* sprite
  (wider than tall) overhang via `bullVisualHeight` + `bullFeetOffset`, exactly like the
  dancer's visual/collision split. Verify feet sit on the platform.
- **Facing:** render left-facing, mirror when `bullFacing >= 0`; **remove `facingChevron`**
  (the sprite shows facing now).
- **License is per-model and blocking** — read it, confirm AGPL-app redistribution is
  allowed, log it before shipping a single frame. No blanket Mixamo grant here.
- **Raw mesh/rig stays git-ignored** (`source/`, `*.blend`, `*.fbx`); only rendered PNGs
  ship — same as the dancer.
- **Verify with flags ON** (don't set `CONJUGAR_GAME_DISABLE_FLAGS`) or the throw never
  fires; use `CONJUGAR_GAME_TIME_SCALE=0.2` to catch it.
