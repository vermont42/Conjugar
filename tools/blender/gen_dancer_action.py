"""
gen_dancer_action.py — hand-key one dancer action on the purchased flamenco-gown
rig and export a baked FBX for render_sprites.py.

    blender -b -P tools/blender/gen_dancer_action.py -- --action idle

House style (see prompts/game_dancer_finish_actions.md): floor-length gown, FEET
HIDDEN (shoe mesh deleted), animate the gown+torso with world-space bone rotations
keyed from rest each frame. Skeleton is the vendor's own 63-bone Mixamo-named rig;
the skirt (MASkirt_03) is skinned to hips+legs, so subtle leg motion sways the hem.
"""
import bpy, bmesh, math, sys
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
ACTION = argv[argv.index("--action") + 1] if "--action" in argv else "idle"

FRAMES = {"idle": 2, "jump": 3, "cape": 4, "capeWalk": 6, "climb": 4}[ACTION]
# Actions where the dancer holds a red muleta in front of her (rendered by
# render_sprites.py --cape as a second, red cel material on the "Muleta" mesh).
CAPE_ACTIONS = {"cape", "capeWalk"}
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


def hand_world(bone):
    """World-space position of a hand bone head (armature carries a 0.0254 scale +
    90°-X import rotation, so go through matrix_world, not the pose matrix alone)."""
    return (arm.matrix_world @ PB[bone].matrix).translation


def make_muleta():
    """A stylized red muleta (matador's cape): a flared cloth that hangs DOWN (−Z) and
    FORWARD (−Y, the way she faces) from its origin, so placing the origin at her hands
    each frame drapes the cape in front of her. Built in the Y-Z plane (normal ±X) so
    the side camera sees its full face; a tiny X billow keeps the cel shading from
    reading as a degenerate edge. Not skinned — the frame loop keyframes its LOCATION
    to follow the hands, so the arm swing carries the cape up and down."""
    me = bpy.data.meshes.new("Muleta")
    obj = bpy.data.objects.new("Muleta", me)
    scene.collection.objects.link(obj)
    bm = bmesh.new()
    nx, nz, W, H = 4, 6, 0.30, 0.62
    grid = [[None] * (nz + 1) for _ in range(nx + 1)]
    for i in range(nx + 1):
        for k in range(nz + 1):
            fy, fz = i / nx, k / nz
            y = -W * fy * (0.65 + 0.6 * fz)     # flare wider toward the hanging bottom
            z = -H * fz
            x = 0.03 * math.sin(fz * math.pi)   # slight billow so it isn't edge-on flat
            grid[i][k] = bm.verts.new((x, y, z))
    for i in range(nx):
        for k in range(nz):
            bm.faces.new((grid[i][k], grid[i + 1][k], grid[i + 1][k + 1], grid[i][k + 1]))
    bm.to_mesh(me)
    bm.free()
    return obj


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
    # Standing still, holding the muleta in front and SWINGING it up and down (a
    # veronica-style pass). Arms sweep fore/up so the hands — and the cape keyframed
    # to follow them — rise and fall. Legs neutral (she's planted).
    driven = ['Spine', 'LeftArm', 'LeftForeArm', 'RightArm', 'RightForeArm']

    def pose(i):
        p = 2 * math.pi * (i - 1) / FRAMES
        # NEGATIVE worldX swings the arms up-and-FORWARD (−Y, the way she faces);
        # positive would throw them up-and-back. Sweep ~−40°..−110° = cape low↔high.
        swing = -(46 + 30 * math.sin(p))    # arms held forward, sweep ~−16°..−76°
        worldX('LeftArm', swing)
        worldX('LeftForeArm', -50)
        worldX('RightArm', swing)
        worldX('RightForeArm', -50)
        worldX('Spine', -3 * math.sin(p))   # slight torso follow-through

elif ACTION == "capeWalk":
    # Walking while holding the muleta out in front (steadier than the swing). Arms
    # hold forward with a small bob; legs reuse the shipped walk's subtle sway so the
    # skirt hem swishes exactly like the capeless walk (they must read as one gait).
    driven = ['LeftArm', 'LeftForeArm', 'RightArm', 'RightForeArm',
              'LeftUpLeg', 'LeftLeg', 'RightUpLeg', 'RightLeg', 'Hips']

    def pose(i):
        p = 2 * math.pi * (i - 1) / FRAMES
        hold = -(70 + 6 * math.sin(p))      # arms forward (−Y), small bob
        worldX('LeftArm', hold)
        worldX('LeftForeArm', -35)
        worldX('RightArm', hold)
        worldX('RightForeArm', -35)
        worldX('LeftUpLeg', 10 * math.sin(p))
        worldX('LeftLeg', 18 * max(0.0, math.sin(p - math.pi / 2)))
        worldX('RightUpLeg', 10 * math.sin(p + math.pi))
        worldX('RightLeg', 18 * max(0.0, math.sin(p + math.pi / 2)))
        hipZ(-0.025 * abs(math.sin(p)))

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

muleta = make_muleta() if ACTION in CAPE_ACTIONS else None

for i in range(1, FRAMES + 1):
    scene.frame_set(i)
    reset(driven)
    pose(i)
    for b in driven:
        PB[b].keyframe_insert('rotation_quaternion', frame=i)
        PB[b].keyframe_insert('location', frame=i)
    if muleta is not None:
        # Drape the cape from the hands: origin at the hand midpoint, nudged forward
        # (−Y) so it hangs clearly in front of the gown. Follows the arm swing.
        hold = (hand_world('LeftHand') + hand_world('RightHand')) / 2
        hold += Vector((0.0, -0.06, 0.02))
        muleta.location = hold
        muleta.keyframe_insert('location', frame=i)

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
