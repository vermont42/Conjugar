"""
gen_dancer_action.py — hand-key one dancer action on the purchased flamenco-gown
rig and export a baked FBX for render_sprites.py.

    blender -b -P tools/blender/gen_dancer_action.py -- --action idle

House style (see prompts/game_dancer_finish_actions.md): floor-length gown, FEET
HIDDEN (shoe mesh deleted), animate the gown+torso with world-space bone rotations
keyed from rest each frame. Skeleton is the vendor's own 63-bone Mixamo-named rig;
the skirt (MASkirt_03) is skinned to hips+legs, so subtle leg motion sways the hem.
"""
import bpy, math, sys
from mathutils import Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ACTION = argv[argv.index("--action") + 1] if "--action" in argv else "idle"

FRAMES = {"idle": 2, "jump": 3, "cape": 4, "climb": 4}[ACTION]
SRC = "tools/blender/source/Flamenco_Dancer.fbx"
OUT = f"tools/blender/source/dancer_{ACTION}_gown.fbx"

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
bpy.ops.import_scene.fbx(filepath=SRC)
# Kill the vendor's long baked clip ([1,1557] trap) BEFORE keying.
for o in list(bpy.data.objects):
    o.animation_data_clear()
# Feet hidden: delete the shoe mesh AND the bare-legs mesh. The skirt (MASkirt_03)
# is skinned to the hip+leg BONES, not to the leg mesh, so the hem still sways when
# we rotate the leg bones — but with the leg mesh gone nothing pokes below the hem
# (rotating the legs otherwise pushes the bare-leg geometry out as thin gold strands).
for o in [x for x in bpy.data.objects
          if x.type == 'MESH' and any(k in x.name for k in ['Sho', 'HeA_M', 'Leg'])]:
    print("deleting mesh", o.name)
    bpy.data.objects.remove(o, do_unlink=True)

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
PB = arm.pose.bones


def reset(bones):
    for b in bones:
        PB[b].matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()


def _rot(b, axis, deg):
    """Rotate bone b's ORIENTATION about a world axis, pivoting at the bone's own
    head (translation preserved). Pre-multiplying a plain Matrix.Rotation would
    pivot about the WORLD ORIGIN instead — tolerable for the walk's tiny leg
    angles, but a big arm raise then swings the hand on a huge arc through the
    body. Parent-first order + update-between gives correct FK (children inherit)."""
    cur = PB[b].matrix.copy()
    m = Matrix.Rotation(math.radians(deg), 4, axis) @ cur
    m.translation = cur.translation
    PB[b].matrix = m
    bpy.context.view_layer.update()


def worldX(b, deg):   # swing fore/aft + up/down (visible in a side profile)
    _rot(b, 'X', deg)


def worldY(b, deg):
    _rot(b, 'Y', deg)


def hipZ(dz):
    h = PB['Hips']
    m = h.matrix.copy()
    m.translation.z += dz
    h.matrix = m
    bpy.context.view_layer.update()


# Per-action driven-bone sets + angle logic. All rotations absolute-from-rest.
if ACTION == "idle":
    driven = ['Spine', 'Spine1', 'Hips']

    def pose(i):
        s = (i - 1) / (FRAMES - 1)          # 0 -> 1 breathe
        worldX('Spine', 2.5 * s)
        worldX('Spine1', 1.5 * s)
        hipZ(-0.012 * s)

elif ACTION == "jump":
    driven = ['LeftUpLeg', 'LeftLeg', 'RightUpLeg', 'RightLeg',
              'Hips', 'Spine', 'LeftArm', 'RightArm']
    # crouch (1) -> rise (2) -> apex (3). Leg-bone angles now only shape the SKIRT
    # (leg mesh deleted): crouch gathers/compresses the hem, apex straightens to a
    # smooth cone. The lift itself is the Hips-Z translation; arms raise into apex.
    CROUCH = {'upleg': 15, 'leg': 28, 'hipz': -0.10, 'spine': 10, 'arm': 8}
    RISE = {'upleg': 6, 'leg': 10, 'hipz': 0.00, 'spine': 3, 'arm': 16}
    APEX = {'upleg': 4, 'leg': 8, 'hipz': 0.18, 'spine': -4, 'arm': 34}
    STAGES = [CROUCH, RISE, APEX]

    def pose(i):
        s = STAGES[i - 1]
        worldX('LeftUpLeg', s['upleg'])
        worldX('LeftLeg', s['leg'])
        worldX('RightUpLeg', s['upleg'])
        worldX('RightLeg', s['leg'])
        worldX('Spine', s['spine'])
        worldX('LeftArm', s['arm'])
        worldX('RightArm', s['arm'])
        hipZ(s['hipz'])

elif ACTION == "cape":
    driven = ['Spine', 'Spine1', 'Spine2',
              'LeftArm', 'LeftForeArm', 'RightArm', 'RightForeArm',
              'LeftUpLeg', 'RightUpLeg']

    def pose(i):
        p = 2 * math.pi * (i - 1) / FRAMES
        # torso rock
        worldX('Spine', 4 * math.sin(p))
        worldX('Spine1', 3 * math.sin(p))
        worldX('Spine2', 2 * math.sin(p))
        # flamenco arm flourish: both arms raised overhead, curved forearms, sweeping
        araise = 125 + 22 * math.sin(p)
        worldX('LeftArm', araise)
        worldX('LeftForeArm', 40)
        worldX('RightArm', araise - 18)
        worldX('RightForeArm', 40)
        # skirt sway (opposite-phase legs → hem swings fore/aft in profile)
        worldX('LeftUpLeg', 7 * math.sin(p))
        worldX('RightUpLeg', -7 * math.sin(p))

elif ACTION == "climb":
    driven = ['LeftArm', 'LeftForeArm', 'RightArm', 'RightForeArm',
              'Spine', 'Hips', 'LeftUpLeg', 'RightUpLeg']

    def pose(i):
        p = 2 * math.pi * (i - 1) / FRAMES
        # arm-over-arm reach overhead, viewed from behind. Quarter-phase (sin vs cos)
        # so all 4 frames are distinct poses — plain opposite-phase sin would make
        # frames 1 and 3 identical (sin 0 == sin π), killing the alternation.
        worldX('LeftArm', 150 + 30 * math.sin(p))
        worldX('LeftForeArm', 18)
        worldX('RightArm', 150 + 30 * math.cos(p))
        worldX('RightForeArm', 18)
        worldX('Spine', -4)                 # slight lean into ladder
        worldX('LeftUpLeg', 6 * math.sin(p))
        worldX('RightUpLeg', -6 * math.sin(p))
        hipZ(0.03 * math.sin(2 * p))        # vertical bob = climbing

else:
    sys.exit(f"unknown action {ACTION}")

for i in range(1, FRAMES + 1):
    scene.frame_set(i)
    reset(driven)
    pose(i)
    for b in driven:
        PB[b].keyframe_insert('rotation_quaternion', frame=i)
        PB[b].keyframe_insert('location', frame=i)

bpy.ops.object.mode_set(mode='OBJECT')
scene.frame_start = 1
scene.frame_end = FRAMES
objs = [o for o in bpy.data.objects if o.type in ('MESH', 'ARMATURE')]
bpy.ops.object.select_all(action='DESELECT')
for o in objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.fbx(filepath=OUT, use_selection=True, add_leaf_bones=False,
    bake_anim=True, bake_anim_use_all_bones=True, bake_anim_use_nla_strips=False,
    bake_anim_use_all_actions=False, path_mode='STRIP')
print(f"[gen_dancer_action] wrote {OUT} ({FRAMES} frames, action={ACTION})")
