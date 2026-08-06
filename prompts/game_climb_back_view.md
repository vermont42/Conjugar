# Plan — Render the dancer's climb from the BACK instead of the side

**Goal:** re-render the player's **climb** action from a **back view** (camera behind
the figure) rather than the current left-profile side view. A side-on climb reads oddly
on a vertical ladder; watching the character's back as they climb *away* up the ladder is
the conventional platformer read and looks more natural. Success = the in-game climb
(hold up at a ladder via `conjugar://game`) shows the dancer from behind, feet still
platform-aligned, same size as the other actions, no numbered-box fallback.

Small, contained change — the render harness already supports it. This is a follow-on to
`prompts/game_dancer_actions.md` (all five player actions, **done** and committed).

## Current state (already complete — this plan only re-angles climb)
- **All five player actions ship as rendered sprites** (`dancer_{idle,walk,climb,jump,cape}`),
  each a real Mixamo→Blender flipbook. The player never shows the numbered-box placeholder
  (only the bull does). Committed on the `migration` branch.
- **Climb today is a LEFT side profile** (`--view side`), 4 frames, cropped to **82×169**,
  in `Conjugar/Assets.xcassets/Game/dancer_climb_1..4.imageset`.
- **Climb is deliberately un-mirrored.** `GameView.dancerMirror(.climb, facing:)` returns
  a constant `1` (no flip) because a ladder pose is symmetric. **This stays correct for a
  back view** (front-to-back symmetric too) — leave it.
- **Per-action sizing.** `GameView.dancerWidth(.climb)` hardcodes the aspect ratio
  `82.0 / 169.0`, measured from the *side* crop. Every action is held to one visual
  **height** (`dancerVisualHeight = 56`) and given its own width from this aspect, so all
  actions are one character-size with feet aligned. **This width constant is the one bit of
  code that must change** (a back view has a different silhouette → different crop width).
- **The source FBX is still on disk:** `tools/blender/source/dancer_climb.fbx` (the Mixamo
  "Climbing Ladder" clip, In-Place / 30 fps / With Skin). It is **git-ignored** but present
  locally from the last session — **no Mixamo re-export needed**, just a re-render. (If it
  is somehow gone, re-download it from Mixamo per `game_dancer_actions.md` Phase 1: same
  X Bot character, "Climbing Ladder", check In Place.)
- **Debug affordances exist** for catching animations in screenshots (both default off, no
  effect on normal play): `CONJUGAR_GAME_TIME_SCALE` (a loop-`dt` multiplier — `0.2` = 5×
  slow, `0.1` = 10×) and `CONJUGAR_GAME_DISABLE_FLAGS` (quiets the bull's flags). See below.

## Read first
1. `tools/blender/README.md` — the harness, the `--view` flag, "Adding a new action", and
   the "dancer's full action set" notes (esp. the facing/mirror + one-height/per-width bits).
2. `tools/blender/render_sprites.py` — the `--view` argument. It maps
   `side`(−X) / `side2`(+X) / `front`(−Y) / `back`(+Y) to an orthographic camera direction.
   **`--view back` is the whole trick.** Note it only does the 4 orthogonal directions — no
   arbitrary angle (see the Phase 2 fallback).
3. `Conjugar/Views/GameView.swift` — `dancerWidth(_:)` (the `82.0/169.0` climb aspect to
   re-measure), `dancerMirror(_:facing:)` (climb → `1`, leave it), `spriteActions`,
   `actionName`, `dancerFeetOffset`.
4. `Conjugar/Models/Game/GameState+Animation.swift` — `playerFrameCounts[.climb] = 4`
   (the render `--frames` must stay **4**).

---

## Phase 1 — Re-render climb from the back  [Claude]
Same command as before, only `--view side` → `--view back`:

```bash
blender -b -P tools/blender/render_sprites.py -- \
  --fbx tools/blender/source/dancer_climb.fbx \
  --actor dancer --action climb --frames 4 --size 192 --view back \
  --out tools/blender/renders
tools/blender/pack_or_rename.sh rename dancer climb
```

`pack_or_rename.sh` prints the new **common crop box** (e.g. `NNxMM+X+Y`) — **record the
`NNxMM`**; you need the width/height for Phase 3. Height should still be ~169 (In-Place
holds the figure height); width will differ from 82 (arms out gripping rungs, legs spread
→ likely wider).

## Phase 2 — Judge whether the back view reads  [Claude + Josh]
This is the only real risk: does the "Climbing Ladder" clip look *good* from directly
behind? Build a contact sheet of the 4 back-view frames on a mid-gray background and look:
- **Good:** back of the figure, arms reaching up alternately to rungs, legs stepping — a
  clear climb. Proceed.
- **Bad** (occluded/ambiguous — e.g. the body hides the arm/leg motion): a *pure* back view
  (`+Y`) may be too flat. `--view` only offers the 4 orthogonal directions, so a
  **three-quarter-back** angle would mean nudging the camera in `render_sprites.py` (rotate
  the camera a few degrees off the +Y axis, or offset its X a touch, in the view-placement
  block) rather than a flag. Keep that change local and behind the same auto-fit. Try
  `side2`/`front` too if useful for comparison before editing the script.

Pick the angle that reads best; only then continue.

## Phase 3 — Update the width constant + swap the imagesets  [Claude]
1. In `GameView.dancerWidth(_:)`, change the `.climb` aspect from `82.0 / 169.0` to the
   **new crop box** dims from Phase 1 (`newWidth / newHeight`). Nothing else in GameView
   changes — mirror rule, frame count, feet offset all stay.
2. Overwrite the 4 PNGs in `Conjugar/Assets.xcassets/Game/dancer_climb_1..4.imageset/`
   with the new `tools/blender/dist/dancer_climb_1..4.png` (same filenames → no
   `Contents.json` or `project.pbxproj` edit; the catalog is a synchronized group).

## Phase 4 — Verify in-app  [Claude + Josh]
Build (`ios-build-verify`), then drive the game and confirm the climb reads from behind:

```bash
# launch slowed + calm so the climb pose is easy to frame (both default off in normal play)
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;d=json.load(sys.stdin)['devices'];print(next(x['udid'] for v in d.values() for x in v if x.get('state')=='Booted'))")
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Conjugar-*/Build/Products/Debug-iphonesimulator/Conjugar.app | head -1)
xcrun simctl terminate "$UDID" biz.joshadams.Conjugar 2>/dev/null; xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_CONJUGAR_GAME_TIME_SCALE=0.2 SIMCTL_CHILD_CONJUGAR_GAME_DISABLE_FLAGS=1 \
  xcrun simctl launch "$UDID" biz.joshadams.Conjugar
sleep 2; xcrun simctl openurl "$UDID" conjugar://game
```

Then walk the player onto a ladder and hold **up** (the up-button only appears when aligned
at a ladder — poll `describe_ui.sh` for the "Move up" label to know you're on it, as in the
last session). Screenshot mid-climb; confirm: back view, feet on the rungs / platform-
aligned, same size as idle/walk, **no numbered box**. Check the other four actions still
look right (nothing else changed, but confirm feet still line up).

## Phase 5 — Document + commit  [Claude]
- `asset-licenses/mixamo-dancer.txt` and `tools/blender/README.md` currently say the climb
  was rendered "side view" — update the climb wording to "back view" (and, if Phase 2 used a
  nudged camera, note that in the README's "dancer's full action set" section as the one
  action that needed a non-default angle).
- Add a short `docs/blog_notes.md` entry (per CLAUDE.md).
- Commit to the `migration` branch.

## Definition of done
- `dancer_climb_1..4` are re-rendered from the back (or a three-quarter-back angle if pure
  back read poorly), still 4 frames, height ~169, feet at the sprite bottom.
- `GameView.dancerWidth(.climb)` matches the new crop aspect; climb stays un-mirrored.
- The in-game climb shows the figure from behind, verified via `conjugar://game`, feet
  platform-aligned, same size as the other actions, no numbered box; the other four actions
  unchanged.
- License/README wording updated; blog note added; committed to `migration`.

## Gotchas
- **`--view back` is the change** — don't rebuild the whole toolchain; only climb re-renders.
  Leave idle/walk/jump/cape (all side view) alone.
- **Re-measure the crop box** and update `dancerWidth(.climb)` — a back silhouette is wider
  than the 82px side profile. Height stays ~169, so feet alignment is unaffected; only width.
- **Keep climb un-mirrored** — back view is front-to-back symmetric, so `dancerMirror`
  returning `1` for climb is still right. Don't add a facing flip.
- **`--frames 4`** must match `playerFrameCounts[.climb]`; changing it means changing both.
- **The FBX is git-ignored but on disk** (`tools/blender/source/dancer_climb.fbx`); no
  Mixamo trip unless it's missing.
- **`--view` only does 4 orthogonal directions.** A three-quarter angle needs a small edit
  to the camera-placement block in `render_sprites.py`, not a flag.
- **Use the slowdown env vars to screenshot the climb** — climb animates continuously so
  it's easier to catch than a jump, but 5× slow + flags-off still makes framing trivial.
