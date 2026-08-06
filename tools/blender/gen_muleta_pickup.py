"""
gen_muleta_pickup.py — build the standalone red muleta used as the CAPE PICKUP icon
on the platforms (replacing the 🧣 emoji), so the collectible matches the muleta the
dancer carries. Same cloth shape as gen_dancer_action.py's make_muleta(), rendered
alone; render_sprites.py --cape paints the "Muleta" mesh red.

    blender -b -P tools/blender/gen_muleta_pickup.py
    blender -b -P tools/blender/render_sprites.py -- --fbx tools/blender/source/muleta_pickup.fbx \
        --actor cape --action pickup --toon --color gold --outline --cape --frames 1 --size 256 --view side
"""
import bpy, bmesh, math

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
me = bpy.data.meshes.new("Muleta")
obj = bpy.data.objects.new("Muleta", me)
scene.collection.objects.link(obj)

bm = bmesh.new()
# A flowing muleta: flared, curling forward at the bottom, with folds (billow) so the
# cel bands read as cloth and a scalloped hem so it isn't a flat flag. Standalone it
# has no hand/pose to sell it, so the SHAPE has to carry the "cape" read on its own.
nx, nz, W, H = 6, 8, 0.36, 0.66
grid = [[None] * (nz + 1) for _ in range(nx + 1)]
for i in range(nx + 1):
    for k in range(nz + 1):
        fy, fz = i / nx, k / nz
        y = -W * fy * (0.5 + 1.0 * fz)               # flare wider toward the bottom
        z = -H * fz + 0.10 * fy * fz                 # bottom-front curls upward (flow)
        if k == nz:                                  # scalloped hem
            z += 0.045 * math.sin(fy * math.pi * 2.5)
        # vertical folds (S-curve across the drop) + a forward curl low down → cel folds
        x = 0.12 * math.sin(fz * math.pi) + 0.07 * math.sin(fy * math.pi * 2.0) * fz
        grid[i][k] = bm.verts.new((x, y, z))
for i in range(nx):
    for k in range(nz):
        bm.faces.new((grid[i][k], grid[i + 1][k], grid[i + 1][k + 1], grid[i][k + 1]))
bm.to_mesh(me)
bm.free()

bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.fbx(filepath="tools/blender/source/muleta_pickup.fbx",
                         use_selection=True, path_mode='STRIP')
print("[gen_muleta_pickup] wrote tools/blender/source/muleta_pickup.fbx")
