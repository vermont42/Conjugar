# Plan — Finish the flamenco-gown dancer: idle / climb / jump / cape (+ consistency pass)

**Supersedes `game_dancer_actions.md`** (that one assumed the X-Bot mannequin + Mixamo mocap).
The dancer is now the purchased **flamenco gown** mesh, and the animation approach has changed
(hand-keyed on the model's own rig, feet hidden). This plan finishes the player.

## Where we are (2026-07-12, end of the paid-dancer spike)

- **Asset:** Animod "Flamenco Dancer" (CGTrader, Royalty-Free no-AI, $6.99), logged in
  `asset-licenses/cgtrader-flamenco-dancer.txt`. Raw FBX + textures are git-ignored under
  `tools/blender/source/` (`Flamenco_Dancer.fbx`). It **clears the 57 pt app-icon floor** (a
  female flamenco dancer in a gold gown; see `docs/dancer_shortlist.md` + `docs/blog_notes.md`).
- **Rig:** the vendor FBX already ships a **63-bone skeleton with exact Mixamo bone names**
  (`Hips, Spine1-3, LeftUpLeg, LeftLeg, LeftFoot, RightUpLeg, …`) and **the skirt (`MASkirt_03`)
  is skinned to the hip + leg bones.** So we **pose/animate that existing rig directly** — no
  Mixamo auto-rig (it can't rig a floor-length skirt anyway).
- **Art direction (decided by Josh): "animate the gown," feet hidden.** A floor-length gown in
  a side view can't show a real stride — the legs live inside the skirt, so any leg swing pokes
  the *shoes* past the hem and they read as detached blobs. So we **delete the shoe mesh**
  (`HeA_MltherShoesA_01`) and animate the gown+torso: subtle leg motion still drives the skirt
  (it's skinned to the legs) → hem sway + body bob, but nothing detaches. This is the **house
  style for every dancer action.**
- **Walk: DONE and wired.** Hand-keyed 6-frame walk (feet hidden), rendered `--toon --color
  gold --outline`, union-cropped **122×226**, installed into `dancer_walk_1..6.imageset`, and
  `GameView.dancerWidth(.walk)` aspect updated **113/173 → 122/226**. **Live-verified** in
  `conjugar://game`: she walks on the platform, correctly planted and sized.
- **Not done:** idle / climb / jump / cape still render the **old X-Bot mannequin** (only walk
  was swapped), so standing↔walking visibly swaps figure. That's what this plan fixes.

## Frame counts (must match `GameState.playerFrameCounts`)

`GameState+Animation.swift`: **idle 2, walk 6 (done), climb 4, jump 3, cape 4.** Render exactly
that many frames per action (`render_sprites.py --frames N`).

## The proven pipeline (reproduce these; they work)

Mesh prep + hand-key + render + crop + wire. All Blender is **headless** (`blender -b -P …`);
the machine has no `timeout` binary — rely on the Bash tool's own timeout, never wrap with
`timeout`.

### 1. Build the animated FBX (per action) — hand-key on the existing rig, feet hidden

Skeleton is fine as-is; the *only* mesh edit is deleting the shoes. Key just the leg/hip bones
(and, per action, the spine/arms) with **world-space rotations** — proven robust where local
rotations are ambiguous. Reset each bone to `matrix_basis = Identity` at the top of every frame,
then apply absolute angles from rest. Skeleton bones to drive: `Hips, LeftUpLeg, LeftLeg,
RightUpLeg, RightLeg` (+ `Spine*/arms` for gestures). Skeleton naming lets you address bones by
name directly.

Reusable skeleton of the per-action script (this is exactly the walk generator, minus the
walk-specific angles):

```python
import bpy, math
from mathutils import Matrix
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.ops.import_scene.fbx(filepath="tools/blender/source/Flamenco_Dancer.fbx")
for o in list(bpy.data.objects): o.animation_data_clear()
# feet hidden: delete shoe mesh (dead-ref safe: query, then remove)
for o in [x for x in bpy.data.objects if x.type=='MESH' and any(k in x.name for k in ['Sho','HeA_M'])]:
    bpy.data.objects.remove(o, do_unlink=True)
arm = [o for o in bpy.data.objects if o.type=='ARMATURE'][0]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE'); PB = arm.pose.bones
def reset(bones):
    for b in bones: PB[b].matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
def worldX(b, deg):   # swing a bone about world-X (fore/aft); parent-first, update between
    PB[b].matrix = Matrix.Rotation(math.radians(deg),4,'X') @ PB[b].matrix
    bpy.context.view_layer.update()
N = 6                                   # = frame count for this action
driven = ['LeftUpLeg','LeftLeg','RightUpLeg','RightLeg','Hips']
for i in range(1, N+1):
    scene.frame_set(i); p = 2*math.pi*(i-1)/N
    reset(driven)
    # --- per-action angles go here (see walk example below) ---
    for b in driven:
        PB[b].keyframe_insert('rotation_quaternion', frame=i)
        if b=='Hips': PB[b].keyframe_insert('location', frame=i)
bpy.ops.object.mode_set(mode='OBJECT'); scene.frame_start=1; scene.frame_end=N
objs=[o for o in bpy.data.objects if o.type in ('MESH','ARMATURE')]
bpy.ops.object.select_all(action='DESELECT')
for o in objs: o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, add_leaf_bones=False,
    bake_anim=True, bake_anim_use_all_bones=True, bake_anim_use_nla_strips=False,
    bake_anim_use_all_actions=False, path_mode='STRIP')
```

Walk angles that shipped (subtle, feet tucked):
```python
worldX('LeftUpLeg', 10*math.sin(p));  worldX('LeftLeg', 18*max(0.0, math.sin(p-math.pi/2)))
worldX('RightUpLeg',10*math.sin(p+math.pi)); worldX('RightLeg',18*max(0.0, math.sin(p+math.pi/2)))
h=PB['Hips']; m=h.matrix.copy(); m.translation.z += -0.025*abs(math.sin(p)); h.matrix=m
bpy.context.view_layer.update()
```

### 2. Render → crop → wire (identical to the walk)

```bash
BL=/usr/local/bin/blender
$BL -b -P tools/blender/render_sprites.py -- --fbx <animated.fbx> \
    --actor dancer --action <ACTION> --toon --color gold --outline \
    --frames <N> --size 256 --view <side|front>          # walk/idle/jump/cape = side; climb = front/back
tools/blender/pack_or_rename.sh rename dancer <ACTION>    # prints "common crop box: WxH+X+Y"
# install: cp tools/blender/dist/dancer_<ACTION>_i.png  Conjugar/Assets.xcassets/Game/dancer_<ACTION>_i.imageset/
# update GameView.dancerWidth(.<ACTION>) aspect = W/H from the crop box
```

Then build + live-verify:
```bash
~/.claude/skills/ios-build-verify/scripts/build_app.sh
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;d=json.load(sys.stdin)['devices'];print([x['udid'] for r in d.values() for x in r if x.get('state')=='Booted'][0])")
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Conjugar-*/Build/Products/Debug-iphonesimulator/Conjugar.app|head -1)
xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_CONJUGAR_GAME_TIME_SCALE=0.2 SIMCTL_CHILD_CONJUGAR_GAME_DISABLE_FLAGS=1 xcrun simctl launch "$UDID" biz.joshadams.Conjugar
sleep 2; xcrun simctl openurl "$UDID" conjugar://game
# drive: axe touch -x 131 -y 767 --down --up --delay 4 --udid "$UDID"  (hold right = walk)
```

## Per-action notes (floor-length gown, feet hidden)

- **idle (2 frames, side):** a gentle breathing/sway — tiny hip bob + a few-degree torso/skirt
  shift between the two frames. Must **register vertically with the walk** (same hem baseline)
  so standing↔walking doesn't pop. This is the most-seen pose; get the silhouette clean.
- **climb (4 frames, front or back view):** `dancerMirror` treats climb as a **back-view ladder
  pose** (never mirrored). No legs on rungs (feet hidden) — sell it as the gown rising with an
  arm-over-arm reach + slight skirt swing; alternate the reaching arm across the 4 frames.
  Consider a hair/skirt bob to imply vertical motion. Render the view the climb code expects
  (check `game_climb_back_view.md`).
- **jump (3 frames, side):** crouch → rise → apex. Whole body + skirt lifts; tuck the legs so
  nothing pokes below the hem at apex (the gown trails as a cone). Keep the arms in the elegant
  rest or a small raise.
- **cape (4 frames, side):** the flamenco flourish — a torso/arm gesture (retarget-free; key the
  `Spine*`/arm bones by hand) with a skirt sway. This is the one action where visible **arm**
  motion is worth the effort; key arms in *world* space too and eyeball each frame.

## Gotchas already paid for (don't re-learn these)

- **Mixamo can't rig this** (floor-length skirt = no leg separation → auto-rigger bounces off
  markers). And **Blender's binary FBX is misread by Mixamo** as "existing skeleton" — if you
  ever must upload, export **OBJ**. But you don't need Mixamo at all; hand-key the existing rig.
- **Mixamo mocap retarget is NOT viable** onto this rig: the dancer rests in an **A-pose**,
  Mixamo in a **T-pose**, so world-space `COPY_ROTATION` splays the arms; the two armatures also
  have different base orientations. Hand-keying sidesteps all of it.
- **The [1,1557] trap:** the vendor rig carries its own long baked animation. Always
  `animation_data_clear()` before keying and bake into a fresh action
  (`nla.bake(..., use_current_action=False)` / export with `bake_anim_use_all_actions=False`),
  or `render_sprites` samples a static tail and every frame looks identical.
- **`render_sprites --start/--end` mis-sampled** in this session (re-showed the rest pose) —
  prefer a clean `[1,N]` action + default-range sampling. Investigate before relying on it.
- **`view_layer.update()` per-bone per-frame is too slow** (2 min timeout for a full retarget);
  hand-keying ~5 bones × N frames is fine.
- **SourceKit false positives:** editing `GameView.swift` spams "Cannot find GameState /
  PlayerAction in scope." `build_app.sh` is authoritative — trust it.
- **Union crop changes the aspect:** every action's `dancerWidth` aspect must be re-derived from
  its own `pack_or_rename.sh` crop box (they differ per action). Height stays `dancerVisualHeight
  = 57.3`; feet/hem stay glued to the crop bottom.
- **Renders face LEFT;** `GameView` mirrors when facing right (climb is exempt). Keep the new
  renders left-facing to match.
- **Background is near-black:** the black Freestyle outline is invisible on it, so the **gold
  fill defines the silhouette** — keep her gold and legible on black (same lesson as the bull).

## Definition of done

- idle / climb / jump / cape hand-keyed in the feet-hidden gown style, rendered `--toon --color
  gold --outline`, cropped, installed, and each `dancerWidth` aspect updated.
- **Consistency pass:** all five actions share a hem baseline and read at the same ~57 pt height;
  standing↔walking↔climbing no longer pops between figures; feet never detach in any frame.
- Build green; **live-verified** in `conjugar://game` across idle/walk/climb/jump/cape.
- `docs/blog_notes.md` updated; raw FBX/textures stay git-ignored (only PNGs + license ship).

## Not in scope

- `render_sprites.py` `--toon`/`--realistic` changes (assets only).
- The `--realistic` (Vainglory) bonus look — a separate go decision on the *same* asset later.
- Re-opening the marketplace/paid-AI search (the dancer is bought and works).
