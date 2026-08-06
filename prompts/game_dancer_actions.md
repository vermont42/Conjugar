# Plan — Render the dancer's remaining four actions

**Goal:** finish animating the **player** by rendering the dancer's other four actions —
**idle, climb, jump, cape** — through the render harness already proven on the walk cycle,
and wiring each into the game's flipbook seam so the player is fully sprite-animated (no
numbered-box placeholders left for the player). Success = all five player actions
(`idle`, `walk`, `climb`, `jump`, `cape`) show real rendered frames in **Settings → Play**
(or `conjugar://game`), with correct facing and platform-aligned feet.

Fresh-session task; read the context first. This is the direct follow-on to
`prompts/game_blender_setup.md` (the toolchain + walk cycle — **done**).

## Current state (already complete — this plan is the next step)
- **The toolchain is stood up and proven.** `tools/blender/render_sprites.py` (headless
  Blender: FBX import → clears the default cube → auto-fit orthographic side camera over
  the *action's* frame range → EEVEE Next + transparent RGBA PNG → N evenly-sampled
  frames) and `tools/blender/pack_or_rename.sh` (crops all frames to one common bounding
  box, renames to `<actor>_<action>_1..N.png`). Documented in `tools/blender/README.md`.
- **The walk cycle is live in-app.** `dancer_walk_1..6` render from a Mixamo "Walking"
  clip (stock **X Bot** character), cropped to 109×169, in
  `Conjugar/Assets.xcassets/Game/`. `GameView.playerSprite` shows
  `Image("dancer_walk_\(gameState.playerFrame)")` for the `.walk` action and keeps the
  numbered-box fallback for every other action. Facing: the render faces **left**, mirrored
  when `playerFacing >= 0` (walking right).
- **`blender-mcp` is wired** (registered + addon vendored at `tools/blender/blender-mcp/`),
  though the dancer path is pure headless CLI and needs neither it nor the Blender GUI.
- **Mixamo access:** Josh is (or can be) logged into Mixamo in Chrome; Claude drove the
  walk export via the Claude-in-Chrome MCP (search clip → apply → check **In Place** →
  Download FBX 30 fps / With Skin). Same flow applies here.

## The four actions & their exact frame counts
The seam's frame-count table is authoritative — **render N to match it exactly**, or the
index math (`Int(phase*fps) % count + 1`, 1-based, `fps = 10`) drops or repeats frames.
From `Conjugar/Models/Game/GameState+Animation.swift`:

```
static let playerFrameCounts: [PlayerAction: Int] = [
  .idle: 2, .walk: 6, .climb: 4, .jump: 3, .cape: 4
]
```

So: **idle → 2, climb → 4, jump → 3, cape → 4** (walk = 6 already done).

When each action actually shows (from `derivedPlayerAction()`), so you pick a fitting clip:
- **idle** — grounded, no horizontal input, not caped. A standing/breathing idle.
- **climb** — on a ladder (`playerClimbing`). A ladder-climb cycle.
- **jump** — airborne (`!playerGrounded`). A jump arc (in place).
- **cape** — grounded, caped, standing still (walk takes precedence when caped **and**
  moving, so `.cape` is effectively a *powered-up idle*). Pick a confident/assertive
  clip — taunt, flex, or an aggressive stance — to read as "powered up / smash-ready."

## Read first
1. `prompts/game_blender_setup.md` — the completed toolchain plan (esp. Phases 2–4).
2. `tools/blender/README.md` — harness args, the Mixamo export settings, "add a new
   action" section, and the palette/toon notes.
3. `docs/game_design_research.md` §3.3 (dancer via Mixamo) and §2.1 (the frame-index seam).
4. The seam: `GameState+Animation.swift` (`playerFrame`, `playerFrameCounts`,
   `derivedPlayerAction`) and `GameView.swift` (`playerSprite`, the `.walk` swap to extend).

---

## Phase 1 — Export the four Mixamo clips  [Josh or Claude-via-Chrome]
For **each** action, on the **same X Bot** stock character (keep the character identical
across actions so proportions/scale match the walk):
- Mixamo → search + apply a clip (suggestions; audition and pick what reads best):
  - **idle** → "Idle" / "Breathing Idle".
  - **climb** → "Climbing" / "Ladder Climb" (see the framing note in Phase 2 — a ladder
    climb may read better from a slightly front/back view than pure side).
  - **jump** → "Jump" (a jump-up in place; not "Jump Forward" which travels).
  - **cape** → an assertive idle/taunt (e.g. "Taunt", "Flexing", "Roaring").
- **Check "In Place"** (essential — keeps the character centered), Mirror off.
- **Download → FBX, 30 fps, With Skin.** Save as `tools/blender/source/dancer_<action>.fbx`
  (e.g. `dancer_idle.fbx`, `dancer_climb.fbx`, `dancer_jump.fbx`, `dancer_cape.fbx`).
- These stay git-ignored (raw Mixamo assets; see `tools/blender/.gitignore`).
- Same Mixamo license as the walk — already logged; extend the existing
  `asset-licenses/mixamo-dancer-walk.txt` entry to cover the added actions (or rename it
  `mixamo-dancer.txt` and list all five clips).

## Phase 2 — Render each action  [Claude]
Run the harness per action, **matching N to `playerFrameCounts`**:

```bash
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/dancer_idle.fbx  --actor dancer --action idle  --frames 2 --size 192 --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/dancer_climb.fbx --actor dancer --action climb --frames 4 --size 192 --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/dancer_jump.fbx  --actor dancer --action jump  --frames 3 --size 192 --out tools/blender/renders
blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/dancer_cape.fbx  --actor dancer --action cape  --frames 4 --size 192 --out tools/blender/renders
```

Framing notes (all use the same left-profile `--view side` as the walk unless noted):
- **climb** — a Mixamo ladder climb often faces the camera. If the side profile reads
  poorly (arms/legs occluded), try `--view front` or `--view back` for this action only;
  pick whichever shows the climb clearly. Whatever you choose, the in-game facing mirror
  still applies — verify it doesn't look wrong on a ladder (climbing is vertical, so
  left/right facing matters less; you may want to *not* mirror climb — see Phase 4).
- **jump** — the arc peaks higher than a stance; the auto-fit samples the whole range, so
  the peak won't clip, but the character will be a bit smaller. That's fine (jump is brief).
- Keep `--size 192` for consistency with the walk, so all actions share a scale.

Then crop + rename each to the 1-based convention (the union-box crop keeps framing
consistent *within* an action):

```bash
tools/blender/pack_or_rename.sh rename dancer idle
tools/blender/pack_or_rename.sh rename dancer climb
tools/blender/pack_or_rename.sh rename dancer jump
tools/blender/pack_or_rename.sh rename dancer cape
```

**Consistency gotcha:** each action is cropped to *its own* union box, so different actions
may end up different pixel sizes/aspect. That's OK because `GameView` sizes by a fixed
visual height with `.scaledToFit()` — but sanity-check that the **feet line up** across
actions (all should sit at the sprite's bottom edge; In-Place keeps feet planted). If an
action's feet float, add a small bottom pad or adjust its crop.

## Phase 3 — Add the imagesets  [Claude]
For each action, add `<action>`×N single-scale universal imagesets under
`Conjugar/Assets.xcassets/Game/` exactly like the walk (folder `dancer_<action>_<i>.imageset`
+ `Contents.json` + PNG). The catalog is in a synchronized group — no `project.pbxproj`
edit. (Script the loop as in the walk setup.)

## Phase 4 — Generalize the GameView swap  [Claude]
Today `playerSprite` special-cases `.walk`. Replace that with a **per-action lookup** so
every rendered action uses its frames and anything unrendered still falls back to the box.

Suggested shape (in `GameView.swift`):
```swift
// Actions that have real rendered sprites. Extend as art lands.
private static let spriteActions: Set<PlayerAction> = [.idle, .walk, .climb, .jump, .cape]

// In playerSprite:
if Self.spriteActions.contains(gameState.playerAction) {
  Image("dancer_\(actionName(gameState.playerAction))_\(gameState.playerFrame)")
    .resizable().scaledToFit()
    .frame(width: Self.dancerVisualWidth, height: Self.dancerVisualHeight)
    .scaleEffect(x: mirror(for: gameState.playerAction, facing: gameState.playerFacing), y: 1)
    .offset(y: Self.dancerFeetOffset)
} else { /* numbered-box fallback */ }
```
where `actionName(.climb) == "climb"`, etc. Details to decide:
- **Asset naming** must match the render output: `dancer_idle_1…2`, `dancer_climb_1…4`,
  `dancer_jump_1…3`, `dancer_cape_1…4`, `dancer_walk_1…6`.
- **Facing/mirror:** walk mirrors when facing right (native render faces left). Reuse the
  same rule for idle/jump/cape. For **climb**, decide whether mirroring makes sense — a
  ladder climb is symmetric front-on; you may want climb to **never mirror** (pass a
  constant). Encode that in a small `mirror(for:facing:)` helper.
- **Per-action visual size?** The walk uses one `dancerVisualHeight`. If jump/climb read
  better a touch smaller/larger, allow a per-action size; otherwise keep one size for
  simplicity. Verify feet-alignment either way.

## Phase 5 — Verify in-app  [Claude + Josh]
Build (`ios-build-verify`), then drive the game via the **`conjugar://game`** deeplink
(see CLAUDE.md — no Settings navigation needed) and exercise each action:
- **idle** — stand still → the idle cycle plays (not the box).
- **walk** — hold left/right → walk, correct facing both ways (already verified).
- **jump** — tap the jump button → jump frames while airborne.
- **climb** — hold up at a ladder → climb frames; confirm it doesn't look wrong-facing.
- **cape** — grab a cape (`?` pickup) and stand still → the caped/powered-up frames.
Capture a screenshot of each (hold-and-capture recipe is in CLAUDE.md). Confirm **no
numbered box** appears for the player in any state.

## Phase 6 — Document  [Claude]
- Update `tools/blender/README.md` if any per-action framing (`--view` for climb) became
  the recommended default.
- Extend the `asset-licenses/` Mixamo entry to list all five clips.
- Add a `docs/blog_notes.md` entry (per CLAUDE.md).
- Commit to the `migration` branch.

## Definition of done
- `dancer_{idle,climb,jump,cape}` imagesets exist with the **exact** `playerFrameCounts`
  frame counts, rendered headlessly through `render_sprites.py`.
- `GameView` renders real sprites for **all five** player actions; the numbered-box
  fallback remains only for the **bull** and any future unrendered action.
- Each action verified in the running game via `conjugar://game`, feet platform-aligned,
  facing correct.
- `asset-licenses/` updated; blog note added; committed to `migration`.

## Not in scope (later sessions)
- **The custom flamenco dancer mesh** (replace the X Bot mannequin) — Gemini concept →
  image-to-3D → Mixamo auto-rig → re-render **all** actions through this same harness.
- **The toon/palette pass** (cel shader in Conjugar red/gold; `--toon` scaffolding exists).
- **The bull** (quadruped — the cost center; no Mixamo). See `prompts/game_blender_setup.md`
  "The bull" note.
- **Stills** (bullfighter, capes, background, HUD) via Gemini, and **flag** assets.

## Gotchas
- **Match N to `playerFrameCounts` exactly** (idle 2 / climb 4 / jump 3 / cape 4). Changing
  a count means changing both the table and the render.
- **In-Place on every Mixamo export**, else the auto-fit inflates and the sprite shrinks.
- **Same X Bot character for all actions** so scale/proportions match the walk.
- **Feet alignment across actions** — In-Place keeps feet planted; verify after the
  per-action union-box crop so the player doesn't bob between states.
- **Climb facing** — decide mirror vs no-mirror; a symmetric front-on climb shouldn't flip.
- Raw FBX stays git-ignored; only the rendered sprites ship (Mixamo raw-asset license).
