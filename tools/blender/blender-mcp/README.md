# blender-mcp addon (vendored)

`addon.py` is the Blender add-on for **blender-mcp** by Siddharth Ahuja
(<https://github.com/ahujasid/blender-mcp>), version **1.2**, vendored here so the
render pipeline is reproducible without a fresh download.

It is **dev tooling only** — it is *not* shipped in the app, so it needs no
`asset-licenses/` entry. It pairs with the MCP server registered via
`claude mcp add blender -- uvx blender-mcp`.

## Install into Blender

1. Blender → **Edit ▸ Preferences ▸ Add-ons ▸ Install…** → select this
   `addon.py` → enable **"Blender MCP"**.
2. In the 3D viewport press **`N`** → **BlenderMCP** tab → **Connect**
   (starts the socket on port 9876 that `uvx blender-mcp` talks to).
3. Leave Blender open while driving it from Claude.

## Caveat

blender-mcp executes arbitrary Python in your Blender session. **Save your work
before driving it**, and prefer the headless CLI (`render_sprites.py`) for
unattended batch renders.
