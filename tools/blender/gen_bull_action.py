"""
gen_bull_action.py — hand-key one bull dance action on the Simple Rigged Bull's
DEF bones and export a baked FBX for render_sprites.py.

    blender -b -P tools/blender/gen_bull_action.py -- --action stomp   # stomp|rear|bow

Why DEF bones (Path B, see prompts/game_bull_actions.md): the FBX round-trip strips
Rigify's control logic (0 constraints/drivers on the imported `rig`), so posing the
`*_ik`/`torso` controls does nothing. The mesh is skinned to the `DEF-` bones and the
model's own baked clip keys them directly — so, like the shipped idle/walk/throw, each
dance action is keyed on the DEF bones, quaternion channels, In-Place (no root
translation, or the render auto-fit inflates and the sprite shrinks).

Rig geometry (rest pose; bull runs along Y, head at −Y, Z up; `--view side` = camera
on −X shows a LEFT-facing profile). Motion for a side actor is all in the Y-Z plane,
so every key is a rotation about the bone's LOCAL X axis (matching bull_throw), applied
identically to L and R so the profile silhouette stays clean:

  - Neck→head chain  DEF-spine.006 … .011  — clean FK chain; + = head down/forward
    (the goring thrust), − = reared up/back (the throw's windup). Cumulative down the
    chain, so small per-bone angles compound into a big head sweep.
  - Upper-back pitch  DEF-spine.004/.005    — same local-X ≈ world-X; − pitches the
    chest+head UP (rear), + drops the chest DOWN (bow). Pivots at the withers.
  - Front legs  DEF-front_thigh/shin/foot (.L/.R) — hang off ORG-shoulder, NOT the DEF
    spine, so they're keyed independently to paw (rear) or fold (bow/stomp).

POSES below are per-frame {bone: degrees-about-local-X}. Frame i (1-based) is authored
at scene frame i; render_sprites.py samples [1, N+1) → frames 1..N. The three counts
match GameState.bullFrameCounts: stomp 3, rear 4, bow 4. bow's final frame is a HELD
bow (it freezes during .victory), so pose 4 ≈ pose 3's depth, settled.
"""
import bpy, math, sys
from mathutils import Quaternion

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ACTION = argv[argv.index("--action") + 1] if "--action" in argv else "stomp"

BLEND = "tools/blender/source/bull.blend"
OUT = f"tools/blender/source/bull_{ACTION}.fbx"

# Neck/head chain and the leg bones we drive. L/R keyed identically (side profile).
NECK = [f"DEF-spine.{i:03d}" for i in range(6, 12)]          # .006 … .011
BACK = ["DEF-spine.004", "DEF-spine.005"]
FRONT_THIGH = ["DEF-front_thigh.L", "DEF-front_thigh.R"]
FRONT_SHIN = ["DEF-front_shin.L", "DEF-front_shin.R"]
FRONT_FOOT = ["DEF-front_foot.L", "DEF-front_foot.R"]

# ---- Pose tables: action -> list of frames, each {bone: local-X degrees} ----------
# Angles were dialled in INTERACTIVELY through blender-mcp with live viewport feedback
# and Josh's per-pose sign-off (2026-07-13), replacing a first headless pass whose big
# rotations tore the mesh (giraffe-stretched neck, straight-bar forelegs, tangled bow).
# The lesson baked in here: keep pitches MODEST and SPREAD across joints — the imported
# DEF chain is fragmented (spine.004 parents to root, not .003), so there's no single
# bone that rigidly pivots the whole front about the hips; any large FK pitch shears the
# continuous mesh. So the rear is a moderate pawing lift (not vertical), the stomp's
# head-slam only dips to chest level (nose stays above the feet), and the bow is a
# clean kneel with the forelegs folded under — each verified not to distort.

def _leg(thigh=0.0, shin=0.0, foot=0.0):
    """Same angles on both L/R front-leg bones (side profile → mirror-identical)."""
    d = {}
    for s in ("L", "R"):
        if thigh: d[f"DEF-front_thigh.{s}"] = thigh
        if shin:  d[f"DEF-front_shin.{s}"] = shin
        if foot:  d[f"DEF-front_foot.{s}"] = foot
    return d

def _spine(**kw):
    """Per-bone spine angles, e.g. _spine(s4=-8, s5=-8, s6=-5) → DEF-spine.004/.005/.006."""
    return {f"DEF-spine.{int(k[1:]):03d}": v for k, v in kw.items()}

def _merge(*dicts):
    out = {}
    for d in dicts:
        out.update(d)
    return out

def _scale(pose, f):
    """A gentler fraction of a peak pose — used for lead-in / hold frames. A scaled-down
    version of a clean pose is inherently clean, so only the peaks needed sign-off."""
    return {b: v * f for b, v in pose.items()}

# Approved PEAK poses (the extreme frame of each action).
REAR_PEAK = _merge(_spine(s4=-8, s5=-8, s6=-5),                 # moderate front lift
                   _leg(thigh=-28, shin=-42, foot=-15))        # forelegs lifted + folded
BOW_PEAK = _merge(_spine(s4=5, s5=4, s6=3, s9=-4, s10=-4),      # chest down, muzzle kept up
                  _leg(thigh=14, shin=-34, foot=-12))          # front knees folded (kneel)

POSES = {
    # STOMP (3): gentle head/chest-up anticipation, then a percussive head-slam that only
    # dips to chest level (nose above the feet) with a small foreleg stamp, then settle.
    "stomp": [
        _spine(s4=-8, s5=-8, s6=-5),                                       # 1 up (anticipation)
        _merge(_spine(s5=2, s6=4, s7=5, s8=4), _leg(thigh=9, shin=-5)),    # 2 head-slam + stamp
        _merge(_spine(s6=2, s7=2, s8=1), _leg(thigh=3)),                   # 3 settle
    ],
    # REAR (4): gather → moderate front lift with forelegs pawing → held. Scaled from the
    # approved peak so every lead-in frame is a gentler (hence clean) version of it.
    "rear": [
        _scale(REAR_PEAK, 0.25),                                # 1 gather
        _scale(REAR_PEAK, 0.60),                                # 2 lifting
        REAR_PEAK,                                              # 3 peak (approved)
        _scale(REAR_PEAK, 0.92),                                # 4 held flourish
    ],
    # BOW (4): dip → fold → deep kneeling bow, held. Frame 4 == peak so it freezes cleanly
    # during .victory (the game caps bullPhase on the last frame).
    "bow": [
        _scale(BOW_PEAK, 0.30),                                 # 1 dip begins
        _scale(BOW_PEAK, 0.65),                                 # 2 folding
        BOW_PEAK,                                               # 3 deep bow (approved)
        BOW_PEAK,                                               # 4 held bow
    ],
}

frames = POSES[ACTION]
N = len(frames)
# Append a trailing duplicate of the final pose (the shipped bull_throw idiom): these
# are one-shots, so the last authored pose (stomp settle / rear flourish / held bow)
# must survive render_sprites' half-open [start, end) sampling, which otherwise drops
# the closing frame. With N+1 keys the render (--frames N, default range) samples the
# first N real poses and drops only the duplicate — and it's robust to the FBX
# exporter shifting the action's start frame (it lands at frame 2, not 1).
frames = frames + [frames[-1]]
NKEYS = len(frames)

# ---- Build the action --------------------------------------------------------------
bpy.ops.wm.open_mainfile(filepath=BLEND)
arm = bpy.data.objects['rig']
mesh = bpy.data.objects['bull 01']

# Fresh action; don't disturb the saved bull_throw.
arm.animation_data_clear()
arm.animation_data_create()
act = bpy.data.actions.new(name=f"bull_{ACTION}")
arm.animation_data.action = act

bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
PB = arm.pose.bones
for pb in PB:
    pb.rotation_mode = 'QUATERNION'

for i, pose in enumerate(frames, start=1):
    bpy.context.scene.frame_set(i)
    # Reset every bone we might touch across the whole action, so a bone keyed on one
    # frame but not another returns to rest rather than holding a stale pose.
    for b in NECK + BACK + FRONT_THIGH + FRONT_SHIN + FRONT_FOOT:
        PB[b].rotation_quaternion = Quaternion((1, 0, 0, 0))
    for b, deg in pose.items():
        PB[b].rotation_quaternion = Quaternion((1, 0, 0), math.radians(deg))
    for b in NECK + BACK + FRONT_THIGH + FRONT_SHIN + FRONT_FOOT:
        PB[b].keyframe_insert(data_path="rotation_quaternion", frame=i)

bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = NKEYS

# ---- Export one FBX with just this action ------------------------------------------
bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True)
mesh.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(
    filepath=OUT,
    use_selection=True,
    add_leaf_bones=False,
    bake_anim=True,
    bake_anim_use_all_actions=False,
    bake_anim_use_nla_strips=False,
    bake_anim_step=1.0,
)
print(f"WROTE {OUT}  ({N} frames, action bull_{ACTION})")
