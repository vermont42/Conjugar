#!/usr/bin/env python3
"""
render_sprites.py — Blender headless sprite renderer for Conjugar's game.

Renders an orthographic, side-view flipbook of a rigged/animated model to
transparent RGBA PNG frames, ready to drop into `Assets.xcassets` as the
per-frame imagesets the game's flipbook seam cycles by a 1-based index
(`GameState+Animation.swift` → `playerFrame` / `bullFrame`, rendered in
`GameView.swift`).

Typical headless run (from the repo root):

    blender -b -P tools/blender/render_sprites.py -- \
        --fbx tools/blender/source/dancer_walk.fbx \
        --actor dancer --action walk --frames 6 --size 192 \
        --out tools/blender/renders

Output: `<out>/<actor>_<action>/<action>_0001.png … _000N.png` (RGBA, transparent).
Then `pack_or_rename.sh` renames those to the Xcode convention
`<actor>_<action>_1.png … _N.png` (or packs a sheet).

If `--fbx` is omitted the *currently-open* scene is rendered instead, so the
render path can be smoke-tested on Blender's default cube:

    blender -b -P tools/blender/render_sprites.py -- --actor test --action cube --frames 1

See `tools/blender/README.md` for the full pipeline, render settings, and palette.

Notes
-----
* Frames are sampled evenly across the action's range as `[start, end)` — the
  half-open interval deliberately drops the cycle's closing frame (which equals
  the opening frame in a Mixamo loop), so the N frames tile seamlessly.
* Framing auto-fits the mesh bounds across the *whole* range by default, so a
  jump's peak or a stride's extremes are never clipped. Pass `--ortho` to pin it.
* Mixamo export must use **In Place** so the character stays centered; otherwise
  root motion inflates the auto-fit and the sprite shrinks.
"""

import argparse
import math
import os
import sys

import bpy
import mathutils


# --------------------------------------------------------------------------- args


def parse_args():
    """Parse only the args after the `--` separator Blender forwards to the script."""
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    p = argparse.ArgumentParser(prog="render_sprites.py", description=__doc__)
    p.add_argument("--fbx", default=None,
                   help="FBX to import; if omitted, the open scene is rendered.")
    p.add_argument("--actor", default="dancer", help="Actor name, e.g. dancer, bull.")
    p.add_argument("--action", default="walk", help="Action name, e.g. walk, climb.")
    p.add_argument("--frames", type=int, default=6,
                   help="How many frames to render (evenly sampled across the range).")
    p.add_argument("--size", type=int, default=192,
                   help="Square render size in px (3x target — 64pt sprite ≈ 192px).")
    p.add_argument("--ortho", type=float, default=0.0,
                   help="Orthographic scale; 0 = auto-fit to mesh bounds over the range.")
    p.add_argument("--margin", type=float, default=1.15,
                   help="Auto-fit padding multiplier around the mesh bounds.")
    p.add_argument("--view", default="side",
                   choices=["side", "side2", "front", "back"],
                   help="Camera profile: side=look -X, side2=+X, front=-Y, back=+Y.")
    p.add_argument("--engine", default="eevee",
                   choices=["eevee", "workbench", "cycles"],
                   help="Render engine (EEVEE default; auto-falls back to Workbench).")
    p.add_argument("--toon", action="store_true",
                   help="Apply a flat palette material (see --color).")
    p.add_argument("--color", default="gold", choices=["gold", "red", "none"],
                   help="Palette color for --toon: gold #CDA51B or red #C1001D.")
    p.add_argument("--start", type=int, default=-1, help="Override frame_start.")
    p.add_argument("--end", type=int, default=-1, help="Override frame_end.")
    p.add_argument("--out", default="tools/blender/renders",
                   help="Output root; frames go to <out>/<actor>_<action>/.")
    return p.parse_args(argv)


# ------------------------------------------------------------------------ palette

# Conjugar's signature colors (see docs/game_design_research.md §5). sRGB hex →
# Blender wants linear-ish floats; these are the plain 0–1 sRGB values, fine for
# a flat/toon look where exact color management isn't critical.
PALETTE = {
    "gold": (0xCD / 255, 0xA5 / 255, 0x1B / 255, 1.0),  # customYellow (dark) #CDA51B
    "red":  (0xC1 / 255, 0x00 / 255, 0x1D / 255, 1.0),  # customRed        #C1001D
}


# ------------------------------------------------------------------------- engine


def resolve_engine(name):
    """Map a friendly engine name to the identifier this Blender build exposes.

    Blender 4.2+ renamed EEVEE to `BLENDER_EEVEE_NEXT`; older builds use
    `BLENDER_EEVEE`. Pick whichever exists.
    """
    prop = bpy.types.RenderSettings.bl_rna.properties["engine"]
    available = {e.identifier for e in prop.enum_items}
    if name == "eevee":
        for cand in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
            if cand in available:
                return cand
    if name == "workbench" and "BLENDER_WORKBENCH" in available:
        return "BLENDER_WORKBENCH"
    if name == "cycles" and "CYCLES" in available:
        return "CYCLES"
    # Fall back to the first available engine (usually Workbench in -b).
    return next(iter(available))


# --------------------------------------------------------------------------- geom


def mesh_objects(subset=None):
    src = subset if subset else list(bpy.data.objects)
    return [o for o in src if o.type == "MESH"]


def clear_scene():
    """Delete everything in the scene — notably Blender's default startup Cube,
    which otherwise sits at the origin (z −1…+1) and occludes an imported
    character's legs. Called before an FBX import so the stage is clean."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def action_frame_range():
    """Widest keyframe range across all animated objects, or None if unanimated.
    Preferred over scene.frame_start/end: the FBX importer parks the scene range
    at a default (e.g. 1–250) far longer than the actual clip, so sampling the
    scene range lands most frames on a static hold."""
    lo = hi = None
    for obj in bpy.data.objects:
        ad = obj.animation_data
        if ad and ad.action:
            fr = ad.action.frame_range
            lo = fr[0] if lo is None else min(lo, fr[0])
            hi = fr[1] if hi is None else max(hi, fr[1])
    if lo is None:
        return None
    return int(math.floor(lo)), int(math.ceil(hi))


def effective_range(args):
    """Resolve the frame range: explicit --start/--end win, else the action's
    keyframe range, else the scene range."""
    scene = bpy.context.scene
    fstart = args.start if args.start >= 0 else None
    fend = args.end if args.end >= 0 else None
    if fstart is None or fend is None:
        ar = action_frame_range()
        if ar:
            if fstart is None:
                fstart = ar[0]
            if fend is None:
                fend = ar[1]
    if fstart is None:
        fstart = scene.frame_start
    if fend is None:
        fend = scene.frame_end
    return fstart, fend


def import_fbx(path):
    """Import an FBX and return the objects it added."""
    abspath = os.path.abspath(path)
    if not os.path.exists(abspath):
        raise FileNotFoundError(f"FBX not found: {abspath}")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=abspath, automatic_bone_orientation=True)
    return [o for o in bpy.data.objects if o not in before]


def bounds_over_range(meshes, fstart, fend, samples=12):
    """World-space AABB of `meshes` sampled across [fstart, fend], evaluated so
    armature deformation (a walk stride, a jump peak) is included, never clipped."""
    scene = bpy.context.scene
    lo = [math.inf] * 3
    hi = [-math.inf] * 3
    span = max(1, samples - 1)
    frames = sorted({int(round(fstart + (fend - fstart) * i / span)) for i in range(samples)})
    for f in frames:
        scene.frame_set(f)
        dg = bpy.context.evaluated_depsgraph_get()
        for obj in meshes:
            ev = obj.evaluated_get(dg)
            mw = ev.matrix_world
            for corner in ev.bound_box:
                world = mw @ mathutils.Vector(corner)
                for k in range(3):
                    lo[k] = min(lo[k], world[k])
                    hi[k] = max(hi[k], world[k])
    if not math.isfinite(lo[0]):        # no meshes / no geometry
        return mathutils.Vector((0, 0, 0)), mathutils.Vector((1, 1, 1)), mathutils.Vector((0, 0, 0.5))
    lo_v, hi_v = mathutils.Vector(lo), mathutils.Vector(hi)
    return lo_v, hi_v, (lo_v + hi_v) / 2


# ------------------------------------------------------------------------- camera


# view -> (world view direction, indices of the two in-plane dims for ortho_scale)
VIEWS = {
    "side":  (mathutils.Vector((-1, 0, 0)), (1, 2)),   # camera on +X, looks -X; plane Y-Z
    "side2": (mathutils.Vector((1, 0, 0)),  (1, 2)),   # camera on -X, looks +X; plane Y-Z
    "front": (mathutils.Vector((0, -1, 0)), (0, 2)),   # camera on +Y, looks -Y; plane X-Z
    "back":  (mathutils.Vector((0, 1, 0)),  (0, 2)),   # camera on -Y, looks +Y; plane X-Z
}


def setup_camera(args, meshes):
    scene = bpy.context.scene
    fstart, fend = effective_range(args)
    lo, hi, center = bounds_over_range(meshes, fstart, fend)
    dims = hi - lo

    view_dir, plane = VIEWS[args.view]
    if args.ortho > 0.0:
        ortho_scale = args.ortho
    else:
        ortho_scale = max(dims[plane[0]], dims[plane[1]], 0.001) * args.margin

    cam_data = bpy.data.cameras.new("SpriteCam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    cam_data.sensor_fit = "AUTO"

    cam = bpy.data.objects.new("SpriteCam", cam_data)
    scene.collection.objects.link(cam)

    # Stand well back along the view axis (ortho ⇒ distance doesn't affect size)
    # and open the clip range to comfortably contain the whole subject.
    reach = max(dims) + max(ortho_scale, 1.0)
    distance = reach * 3.0
    cam.location = center - view_dir.normalized() * distance
    cam.rotation_euler = view_dir.to_track_quat("-Z", "Y").to_euler()
    cam_data.clip_start = 0.01
    cam_data.clip_end = distance * 4.0

    scene.camera = cam
    return cam


def setup_light(args):
    """A key sun plus a soft ambient world so shadowed sides read as a clear
    sprite rather than a near-black silhouette. (Workbench uses its own studio
    light and ignores the sun; the world ambient is harmless to it.)"""
    view_dir, _ = VIEWS[args.view]
    sun_data = bpy.data.lights.new("SpriteSun", type="SUN")
    sun_data.energy = 4.5
    sun = bpy.data.objects.new("SpriteSun", sun_data)
    bpy.context.scene.collection.objects.link(sun)
    # Tilt the light off the pure view axis so there's a little form-defining shade.
    tilt = view_dir.normalized() + mathutils.Vector((0, 0, 0.6)) + mathutils.Vector((0.4, 0.3, 0))
    sun.rotation_euler = (-tilt).to_track_quat("-Z", "Y").to_euler()

    # Ambient fill via the world background. film_transparent keeps the PNG
    # background clear, but the world still lifts the shadow side out of black.
    world = bpy.data.worlds.get("SpriteWorld") or bpy.data.worlds.new("SpriteWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
        bg.inputs["Strength"].default_value = 0.5
    bpy.context.scene.world = world


# --------------------------------------------------------------------------- toon


def apply_flat_material(meshes, color_rgba):
    """Replace materials with one flat, palette-colored Principled material.

    A deliberately simple v1 (the plan: 'render the raw model first, add toon
    once it works'). To upgrade to a true cel look, insert a Shader-to-RGB →
    ColorRamp (constant interpolation) between the BSDF and the material output —
    see README. EEVEE only.
    """
    mat = bpy.data.materials.new("ConjugarFlat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color_rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 1.0
        # Specular input renamed across versions; set whichever exists.
        for key in ("Specular IOR Level", "Specular"):
            if key in bsdf.inputs:
                bsdf.inputs[key].default_value = 0.0
                break
    for obj in meshes:
        obj.data.materials.clear()
        obj.data.materials.append(mat)


# -------------------------------------------------------------------------- render


def configure_output(args, engine_id):
    scene = bpy.context.scene
    scene.render.engine = engine_id
    scene.render.film_transparent = True
    img = scene.render.image_settings
    img.file_format = "PNG"
    img.color_mode = "RGBA"
    scene.render.resolution_x = args.size
    scene.render.resolution_y = args.size
    scene.render.resolution_percentage = 100


def sample_frames(scene, args):
    fstart, fend = effective_range(args)
    n = max(1, args.frames)
    if fend > fstart:
        # Half-open [fstart, fend): drops the loop-closing duplicate frame.
        return [int(round(fstart + (fend - fstart) * i / n)) for i in range(n)]
    return [fstart] * n


def render_frames(args, engine_id):
    scene = bpy.context.scene
    configure_output(args, engine_id)
    out_dir = os.path.abspath(os.path.join(args.out, f"{args.actor}_{args.action}"))
    os.makedirs(out_dir, exist_ok=True)
    picks = sample_frames(scene, args)
    written = []
    for idx, f in enumerate(picks, start=1):
        scene.frame_set(f)
        path = os.path.join(out_dir, f"{args.action}_{idx:04d}.png")
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        written.append(path)
    return written, out_dir


# ---------------------------------------------------------------------------- main


def main():
    args = parse_args()

    if args.fbx:
        clear_scene()  # remove the default startup Cube before importing.
        imported = import_fbx(args.fbx)
        meshes = mesh_objects(imported) or mesh_objects()
    else:
        meshes = mesh_objects()

    engine_id = resolve_engine(args.engine)
    setup_camera(args, meshes)
    setup_light(args)

    if args.toon and args.color != "none":
        apply_flat_material(meshes, PALETTE[args.color])

    try:
        written, out_dir = render_frames(args, engine_id)
    except Exception as exc:  # EEVEE can fail headless on some GPUs; fall back.
        if engine_id.startswith("BLENDER_EEVEE"):
            print(f"[render_sprites] {engine_id} render failed ({exc}); "
                  f"falling back to Workbench.", file=sys.stderr)
            written, out_dir = render_frames(args, "BLENDER_WORKBENCH")
            engine_id = "BLENDER_WORKBENCH"
        else:
            raise

    print(f"[render_sprites] engine={engine_id} size={args.size} "
          f"view={args.view} frames={len(written)} -> {out_dir}")
    for w in written:
        print("  wrote", w)


if __name__ == "__main__":
    main()
