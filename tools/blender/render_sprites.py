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
                   help="Apply a banded cel palette material (see --color). EEVEE only.")
    p.add_argument("--color", default="gold", choices=["gold", "red", "none"],
                   help="Palette color for --toon: gold #CDA51B or red #C1001D.")
    p.add_argument("--bands", type=int, default=2, choices=[2, 3],
                   help="Cel shading bands: 2 (shadow+lit) or 3 (adds a highlight).")
    p.add_argument("--outline", action="store_true",
                   help="Add a black Freestyle silhouette outline. EEVEE only. "
                        "NOTE: inflates every silhouette -> GameView crop constants change.")
    p.add_argument("--outline-width", type=float, default=2.0,
                   help="Freestyle outline thickness in output px (at --size; 2 ≈ 1px on-screen).")
    p.add_argument("--realistic", action="store_true",
                   help="Rendered-realistic mode (the inverse of --toon): KEEP the mesh's "
                        "PBR materials, light with a 3-point + rim rig, AgX view transform, "
                        "AO/soft shadows/raytraced GI, and compositor bloom — NO cel bands, "
                        "NO outline. Use --size 512. A Vainglory-style art-direction spike.")
    p.add_argument("--hdri", default=None,
                   help="Optional .hdr/.exr for image-based lighting in --realistic mode "
                        "(adds natural rim + reflections on top of the 3-point rig).")
    p.add_argument("--samples", type=int, default=64,
                   help="Render samples for --realistic (EEVEE TAA / Cycles); higher = cleaner.")
    p.add_argument("--bloom", type=float, default=0.5,
                   help="Compositor bloom strength for --realistic (0 = off; ~0.5 subtle glow).")
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


# ---------------------------------------------------------------------- realistic
#
# The --realistic path is the deliberate near-inverse of --toon (below): it keeps
# the mesh's own PBR materials, lights for form + separation with a 3-point + rim
# rig (the rim/back light replaces the cel outline — it's how a premium render
# separates a figure from the ground), tonemaps through AgX with a compositor
# bloom for the warm HDR glow, and renders no Freestyle line. It exists to answer
# the Vainglory-style art-direction question at the game's real ~60pt sprite size.


def ensure_pbr_materials(meshes):
    """Guarantee every mesh has *some* Principled material so --realistic never
    renders a raw grey default. Meshes sourced with textures (Rodin/Sketchfab)
    keep theirs untouched — this only fills a genuinely empty slot list."""
    for obj in meshes:
        if obj.data.materials and any(m is not None for m in obj.data.materials):
            continue
        mat = bpy.data.materials.new("RealisticPBR")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        if bsdf:
            bsdf.inputs["Base Color"].default_value = (0.80, 0.62, 0.10, 1.0)  # gold-ish
            bsdf.inputs["Roughness"].default_value = 0.55
            # A little subsurface so bare skin/cloth doesn't read plastic.
            try:
                bsdf.inputs["Subsurface Weight"].default_value = 0.05
            except KeyError:
                pass
        obj.data.materials.append(mat)


def setup_light_3point(args, meshes):
    """Cinematic 3-point rig for --realistic: warm key, cool fill, bright rim/back.

    All three are *area* lights (soft, form-defining shadows) aimed at the subject
    centre. Positions are derived from the camera axis so the rig follows --view:
      - key  : camera side, high, offset left — warm, dominant.
      - fill : camera side, low, offset right — cool, dim (lifts the shadow side).
      - rim  : BEHIND the subject, high — bright, cool-white; rims the silhouette
               and separates the figure from the ground (the outline's job in cel).
    Energies are a tuned starting point; iterate on one frame per the spike plan."""
    scene = bpy.context.scene
    fstart, fend = effective_range(args)
    lo, hi, center = bounds_over_range(meshes, fstart, fend)
    size = max(max(hi - lo), 0.5)
    view_dir, _ = VIEWS[args.view]
    cam_side = (-view_dir).normalized()               # subject → camera
    up = mathutils.Vector((0.0, 0.0, 1.0))
    side_axis = cam_side.cross(up).normalized()       # horizontal, ⟂ camera axis
    dist = max(size * 2.2, 2.0)

    def add_area(name, direction, energy, color, area_size):
        d = bpy.data.lights.new(name, type="AREA")
        d.energy = energy
        d.color = color
        d.size = max(size * area_size, 0.4)
        obj = bpy.data.objects.new(name, d)
        scene.collection.objects.link(obj)
        obj.location = center + direction.normalized() * dist
        aim = (center - obj.location).normalized()
        obj.rotation_euler = aim.to_track_quat("-Z", "Y").to_euler()
        return obj

    # Key:fill ~6:1 for dramatic, form-defining shadow (not flat); rim dominant so
    # the back edge separates the figure from a dark ground. Energies tuned down
    # from a first overexposed pass — AgX rolls off highlights, so keep it moderate.
    add_area("KeyLight",  cam_side + up * 0.9 + side_axis * 0.8,
             energy=600, color=(1.0, 0.85, 0.62), area_size=0.9)
    add_area("FillLight", cam_side + up * 0.2 - side_axis * 1.0,
             energy=100, color=(0.60, 0.72, 1.0), area_size=1.4)
    add_area("RimLight",  -cam_side + up * 1.1 + side_axis * 0.3,
             energy=1500, color=(0.85, 0.90, 1.0), area_size=0.5)

    # A dark, low world so the rim reads as separation and the render keeps HDR
    # contrast (the opposite of the cel path's bright white ambient). An HDRI, if
    # supplied, replaces this for natural image-based rim + reflections.
    world = bpy.data.worlds.get("RealWorld") or bpy.data.worlds.new("RealWorld")
    world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    if args.hdri and os.path.exists(os.path.abspath(args.hdri)):
        env = nt.nodes.new("ShaderNodeTexEnvironment")
        env.image = bpy.data.images.load(os.path.abspath(args.hdri))
        bg = nt.nodes.new("ShaderNodeBackground")
        bg.inputs["Strength"].default_value = 1.0
        nt.links.new(env.outputs["Color"], bg.inputs["Color"])
        nt.links.new(bg.outputs["Background"], out.inputs["Surface"])
    else:
        bg = nt.nodes.new("ShaderNodeBackground")
        bg.inputs["Color"].default_value = (0.02, 0.02, 0.03, 1.0)
        bg.inputs["Strength"].default_value = 0.3
        nt.links.new(bg.outputs["Background"], out.inputs["Surface"])
    scene.world = world


def setup_realistic_engine(scene, engine_id, args):
    """Turn on the realism features the look depends on: raytraced GI/AO + soft
    shadows on EEVEE-Next (or samples/denoise on Cycles), and the AgX HDR view
    transform (the inverse of the cel path's Standard). Every attribute is set
    defensively — EEVEE-Next's property names shift between Blender versions."""
    def _try(obj, attr, val):
        try:
            setattr(obj, attr, val)
            return True
        except (AttributeError, TypeError):
            return False

    # AgX filmic tonemapping + a touch of contrast (realistic WANTS this; cel bans it).
    _try(scene.view_settings, "view_transform", "AgX")
    _try(scene.view_settings, "look", "AgX - Medium High Contrast")

    if engine_id.startswith("BLENDER_EEVEE"):
        ee = scene.eevee
        _try(ee, "taa_render_samples", args.samples)
        _try(ee, "use_shadows", True)
        _try(ee, "use_raytracing", True)   # EEVEE-Next: SSGI + raytraced reflections/AO
        _try(ee, "use_gtao", True)         # legacy EEVEE ambient occlusion (harmless if absent)
        try:
            rt = ee.ray_tracing_options
            _try(rt, "use_denoise", True)
        except AttributeError:
            pass
    elif engine_id == "CYCLES":
        _try(scene.cycles, "samples", max(args.samples, 128))
        _try(scene.cycles, "use_denoising", True)


def setup_bloom(scene, strength):
    """Compositor Glare (Bloom) node for the warm HDR glow. EEVEE-Next removed the
    old `eevee.use_bloom`, so bloom is now strictly a compositor pass — which is
    also what the spike plan calls for. `strength` maps to the Glare mix (subtle)."""
    if strength <= 0.0:
        return
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    rl = nt.nodes.new("CompositorNodeRLayers")
    glare = nt.nodes.new("CompositorNodeGlare")
    types = {i.identifier for i in glare.bl_rna.properties["glare_type"].enum_items}
    glare.glare_type = "BLOOM" if "BLOOM" in types else "FOG_GLOW"
    for attr, val in (("quality", "HIGH"), ("threshold", 1.0), ("size", 8),
                      # Glare mix: -1 = image only, +1 = glare only. Bias toward the
                      # image and add a little glow on top.
                      ("mix", -1.0 + min(max(strength, 0.0), 1.0))):
        try:
            setattr(glare, attr, val)
        except (AttributeError, TypeError):
            pass
    comp = nt.nodes.new("CompositorNodeComposite")
    nt.links.new(rl.outputs["Image"], glare.inputs["Image"])
    nt.links.new(glare.outputs["Image"], comp.inputs["Image"])


# --------------------------------------------------------------------------- toon


def _scaled(color_rgba, factor):
    """Multiply the RGB of an sRGB-float color by `factor`, clamped to 1.0."""
    r, g, b, a = color_rgba
    return (min(r * factor, 1.0), min(g * factor, 1.0), min(b * factor, 1.0), a)


def _srgb_to_linear(color_rgba):
    """Convert an sRGB-float RGBA to linear, as Blender color sockets expect.

    PALETTE stores plain sRGB hex fractions; a Blender color input is linear, so
    an emission fed the raw sRGB value renders too bright (the red drifts to hot
    pink). Converting here means the Standard view transform's linear→sRGB output
    lands back on the exact palette hex (#CDA51B / #C1001D)."""
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b, a = color_rgba
    return (lin(r), lin(g), lin(b), a)


def apply_cel_material(meshes, color_rgba, bands=2):
    """Replace materials with one cel-shaded (banded) emission material. EEVEE only.

    Node graph:
        Diffuse BSDF (white) → Shader to RGB → ColorRamp (Constant) → Emission
        → Material Output

    The white Diffuse + Shader-to-RGB turn the scene lighting into a 0–1
    luminance that the *Constant*-interpolation ColorRamp quantizes into flat
    bands; the ramp's stops carry the palette colors, so the whole mesh is one
    hue and only the bands do the shaping (deliberate — the silhouette stays
    uniform, matching the flat-color intent of the original v1). Shader to RGB
    is an EEVEE-only node, so this look requires EEVEE.

    Bands (from the `--color` base):
      shadow    = base × 0.55   (threshold at fac ≥ 0.33 becomes lit)
      lit       = base
      highlight = min(base × 1.2, 1.0)   (3-band only, fac ≥ 0.66)
    """
    mat = bpy.data.materials.new("ConjugarCel")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()

    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    diffuse.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    diffuse.inputs["Roughness"].default_value = 1.0

    to_rgb = nt.nodes.new("ShaderNodeShaderToRGB")

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    cr = ramp.color_ramp
    cr.interpolation = "CONSTANT"
    els = cr.elements
    els[0].position = 0.0
    els[0].color = _srgb_to_linear(_scaled(color_rgba, 0.55))   # shadow
    els[1].position = 0.33
    els[1].color = _srgb_to_linear(color_rgba)                  # lit
    if bands >= 3:
        hi = els.new(0.66)
        hi.color = _srgb_to_linear(_scaled(color_rgba, 1.2))    # highlight

    emission = nt.nodes.new("ShaderNodeEmission")
    output = nt.nodes.new("ShaderNodeOutputMaterial")

    links = nt.links
    links.new(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    links.new(to_rgb.outputs["Color"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], emission.inputs["Color"])
    links.new(emission.outputs["Emission"], output.inputs["Surface"])

    for obj in meshes:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    return mat


def setup_outline(width_px=2.0):
    """Add a black cel outline via Blender's Freestyle silhouette line renderer.

    Freestyle draws a pixel-width line along the model's outer silhouette (and the
    view-contour of overlapping limbs), which gives a crisp, deterministic drawn
    edge over the cel fill. It renders into the transparent PNG, so the outline is
    part of the sprite's alpha silhouette.

    Chosen over the inverted-hull Solidify trick: under this build's EEVEE-Next the
    flipped-normal + backface-cull shell either culled the rim away or swallowed
    the whole figure (verified on a probe pass) — Freestyle is deterministic and
    its thickness is directly in output pixels, which is what we tune against.

    IMPORTANT: the line extends ~half its width past the mesh silhouette, so it
    inflates every union-crop box — the GameView dancer/bull size constants keyed
    to those crops must be re-derived after enabling this (see the plan's Phase 4).
    """
    scene = bpy.context.scene
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = "ABSOLUTE"   # width in px, not scaled by DPI
    scene.render.line_thickness = width_px

    view_layer = scene.view_layers[0]
    view_layer.use_freestyle = True
    fs = view_layer.freestyle_settings
    lineset = fs.linesets[0]
    lineset.select_silhouette = True   # the outer contour — the actual outline
    lineset.select_border = True       # open-mesh boundary edges
    lineset.select_contour = True      # view-contour of overlapping limbs (hand-drawn read)
    lineset.select_crease = False      # skip interior crease clutter
    lineset.select_edge_mark = False
    lineset.linestyle.color = (0.0, 0.0, 0.0)
    lineset.linestyle.thickness = width_px


# -------------------------------------------------------------------------- render


def configure_output(args, engine_id):
    scene = bpy.context.scene
    scene.render.engine = engine_id
    scene.render.film_transparent = True
    # A cel render wants the palette's *literal* hex, so bypass the default AgX
    # view transform (it shifts saturated reds toward pink and mutes the gold).
    # Standard passes the emission colors through, keeping #CDA51B / #C1001D true.
    if args.toon:
        try:
            scene.view_settings.view_transform = "Standard"
        except (AttributeError, TypeError):
            pass
    elif args.realistic:
        # Realistic wants HDR filmic tonemapping — the opposite of the cel path.
        try:
            scene.view_settings.view_transform = "AgX"
        except (AttributeError, TypeError):
            pass
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
    # The cel material's Shader-to-RGB node and the outline are EEVEE-only, and a
    # silent Workbench fallback would erase the toon look entirely — so require
    # EEVEE up front and fail loudly rather than degrade.
    if args.toon and not engine_id.startswith("BLENDER_EEVEE"):
        sys.exit(f"[render_sprites] --toon requires EEVEE (Shader to RGB is EEVEE-only), "
                 f"but the resolved engine is {engine_id}. Aborting instead of falling "
                 f"back to Workbench (which would silently ruin the cel look).")

    # Realistic needs a shading engine (EEVEE-Next or Cycles); Workbench has no
    # PBR/AO/GI and would flatten the look. If `--engine` resolved to Workbench,
    # fall back to EEVEE rather than render a look-test that proves nothing.
    if args.realistic and not (engine_id.startswith("BLENDER_EEVEE") or engine_id == "CYCLES"):
        eevee = resolve_engine("eevee")
        if eevee.startswith("BLENDER_EEVEE"):
            print(f"[render_sprites] --realistic: {engine_id} can't shade PBR; "
                  f"using {eevee} instead.", file=sys.stderr)
            engine_id = eevee
        else:
            sys.exit(f"[render_sprites] --realistic needs EEVEE or Cycles, but only "
                     f"{engine_id} is available. Aborting.")

    setup_camera(args, meshes)

    if args.realistic:
        # Inverse of --toon: keep PBR materials, 3-point + rim rig, AgX + bloom,
        # AO/soft shadows, NO cel bands, NO outline.
        ensure_pbr_materials(meshes)
        setup_light_3point(args, meshes)
        setup_realistic_engine(bpy.context.scene, engine_id, args)
        setup_bloom(bpy.context.scene, args.bloom)
    else:
        setup_light(args)
        if args.toon and args.color != "none":
            apply_cel_material(meshes, PALETTE[args.color], bands=args.bands)
            if args.outline:
                setup_outline(width_px=args.outline_width)

    try:
        written, out_dir = render_frames(args, engine_id)
    except Exception as exc:  # EEVEE can fail headless on some GPUs; fall back.
        # Never fall back for a toon OR realistic render — Workbench has neither the
        # cel node graph nor PBR/AO/GI, so a silent Workbench render would ruin both.
        if engine_id.startswith("BLENDER_EEVEE") and not args.toon and not args.realistic:
            print(f"[render_sprites] {engine_id} render failed ({exc}); "
                  f"falling back to Workbench.", file=sys.stderr)
            written, out_dir = render_frames(args, "BLENDER_WORKBENCH")
            engine_id = "BLENDER_WORKBENCH"
        else:
            raise

    # Belt-and-suspenders: a toon render must have run on EEVEE.
    if args.toon and not engine_id.startswith("BLENDER_EEVEE"):
        sys.exit(f"[render_sprites] toon render ended on {engine_id}, not EEVEE. Aborting.")

    print(f"[render_sprites] engine={engine_id} size={args.size} "
          f"view={args.view} frames={len(written)} toon={args.toon} "
          f"realistic={args.realistic} outline={args.outline} -> {out_dir}")
    for w in written:
        print("  wrote", w)


if __name__ == "__main__":
    main()
