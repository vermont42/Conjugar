"""
gen_matador.py — clean, pose (hands-on-hips), and hat the purchased matador mesh,
producing matador_posed.blend for render_sprites.py --matador.

    blender -b tools/blender/source/matador.blend -P tools/blender/gen_matador.py

Then render the single static sprite (--view back shows the FACE — the model faces -Y):

    blender -b tools/blender/source/matador_posed.blend -P tools/blender/render_sprites.py -- \
        --actor matador --action idle --frames 1 --size 384 --view back \
        --toon --matador --outline --out tools/blender/renders

The matador is the game's kidnapped-bullfighter GOAL figure — one STATIC front frame
(prompts/game.md: "next to the bull is a bullfighter that the bull kidnapped … the
bullfighter needs only one frame"). Source: CGTrader vfxsinghbu "Matador - Bullfighter
Rigged" (model #5905689), a Daz **Genesis 8 Male**. The costume ships as SEPARATE garment
meshes (MJacket/Pants/Vest/Socks/Shoes/Shirt/Hat/body), so render_sprites.py --matador
colors each garment via a per-object name map (blue suit, gold vest+montera, pink socks,
dark-red = bull-hoof shoes, cream shirt, skin). See tools/blender/README.md "The matador".

House notes (paid the hard way):
- The Daz rig ships **IK constraints** (lHand_IK/rHand_IK) that pin the hands to their
  rest targets and OVERRIDE FK rotations — so ALL pose-bone constraints are cleared first
  and the arms are posed in **pure FK**. (For future ANIMATION, restore/drive IK instead,
  or hand-key FK like gen_dancer_action.py — the rig is fully animatable.)
- The scene ships ~25 junk/reference objects (cube/hako/Icosphere/maru*/triang*/…) and a
  second sun; keep ONLY meshes parented to the Genesis8Male armature.
- The vendor hair/brows/lashes are ~460k verts (invisible at 57 pt, and the montera covers
  the scalp) — hidden for a ~40x render speedup (render_sprites skips hide_render meshes).
- The Hat ships displaced off to the character's left AND skinned to a bone; detach it
  (drop armature modifier + parent) and move/scale its VERTICES in world space.
- The elbow "fold" that brings the hand onto the hip is a rotation about WORLD-Z (vertical),
  not Y; worldY only swings the forearm fore/aft.
"""
import bpy, math, os
from mathutils import Matrix, Vector

ARM_NAME = "Genesis8Male"
DROP_MESHES = {"MFCape.Shape"}   # cape/muleta — spec says none
HIDE_FROM_RENDER = {"aprilyshFrankieHairG8M_282929.Shape", "DuaneBrows_177468.Shape",
                    "Genesis8MaleEyelashes.Shape"}  # heavy vendor hair; montera covers scalp

# ---- pose (pure FK; degrees). Left arm; right mirrors with flipped signs. ----
SHLDR_LOWER_Y = 5      # worldY on ShldrBend: small = elbows stay WIDE (akimbo)
SHLDR_BACK_X  = 8      # worldX on ShldrBend: elbow a touch back
ELBOW_FOLD_Z  = 150    # worldZ on ForearmBend: fold the forearm IN onto the hip
ELBOW_DOWN_X  = 0      # worldX on ForearmBend: extra down/fore tilt
HAND_CURL_X   = -35    # worldX on Hand: pitch the fingers down onto the hip
HAND_CURL_Z   = 15     # worldZ on Hand: yaw the fingers in toward the body
# ---- montera: raised so eyes + a little forehead show; dome still covers the crown ----
HAT_CENTER = Vector((0.0, -0.02, 1.89))
HAT_SCALE  = Vector((1.08, 0.92, 1.10))   # x=width, y=depth, z=height


# === clean: keep the armature + its garment/body meshes; drop cape + all junk ===
arm = bpy.data.objects.get(ARM_NAME)
assert arm and arm.type == "ARMATURE", "no Genesis8Male armature"
keep = {arm}
for o in bpy.data.objects:
    if o.type == "MESH" and o.parent is arm and o.name not in DROP_MESHES:
        keep.add(o)
for o in [x for x in bpy.data.objects if x not in keep]:
    bpy.data.objects.remove(o, do_unlink=True)   # bpy.ops.delete is unreliable headless
for name in HIDE_FROM_RENDER:
    o = bpy.data.objects.get(name)
    if o:
        o.hide_render = True
        o.hide_viewport = True


# === pose: clear IK constraints (pure FK), then rotate the arms hands-on-hips ===
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="POSE")
PB = arm.pose.bones
MW = arm.matrix_world   # identity here (armature at origin, scale 1)
ncon = sum(len(pb.constraints) for pb in PB)
for pb in PB:
    for c in list(pb.constraints):
        pb.constraints.remove(c)
bpy.context.view_layer.update()
print(f"[gen_matador] cleared {ncon} pose-bone constraints (pure FK)")


def _rot(b, axis, deg):
    """Rotate pose bone about a WORLD axis, pivoting at its own head (translation
    preserved). Parent-first + update-between = correct FK (children inherit)."""
    cur = PB[b].matrix.copy()
    m = Matrix.Rotation(math.radians(deg), 4, axis) @ cur
    m.translation = cur.translation
    PB[b].matrix = m
    bpy.context.view_layer.update()


def pose_arm(side):
    s = 1.0 if side == "l" else -1.0
    _rot(f"{side}ShldrBend", "Y", SHLDR_LOWER_Y * s)
    _rot(f"{side}ShldrBend", "X", SHLDR_BACK_X)
    _rot(f"{side}ForearmBend", "Z", ELBOW_FOLD_Z * s)
    _rot(f"{side}ForearmBend", "X", ELBOW_DOWN_X)
    _rot(f"{side}Hand", "X", HAND_CURL_X)
    _rot(f"{side}Hand", "Z", HAND_CURL_Z * s)


pose_arm("l")
pose_arm("r")
bpy.ops.object.mode_set(mode="OBJECT")


# === montera: detach + reposition/scale its VERTICES in world space ===
hat = bpy.data.objects.get("Hat.Shape")
if hat:
    for m in list(hat.modifiers):
        if m.type == "ARMATURE":
            hat.modifiers.remove(m)
    hat.parent = None
    bpy.context.view_layer.update()
    me = hat.data
    mw = hat.matrix_world
    ws = [mw @ v.co for v in me.vertices]
    lo = Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws)))
    hi = Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws)))
    center = (lo + hi) / 2
    mwi = mw.inverted()
    for v, w in zip(me.vertices, ws):
        d = w - center
        v.co = mwi @ (HAT_CENTER + Vector((HAT_SCALE.x * d.x, HAT_SCALE.y * d.y, HAT_SCALE.z * d.z)))
    me.update()
    hat.hide_render = False
    hat.hide_viewport = False
    print(f"[gen_matador] montera placed at {[round(v,3) for v in HAT_CENTER]} scale {list(HAT_SCALE)}")

out = os.path.join(os.path.dirname(bpy.data.filepath), "matador_posed.blend")
bpy.ops.wm.save_as_mainfile(filepath=out)
print("[gen_matador] wrote", out)
