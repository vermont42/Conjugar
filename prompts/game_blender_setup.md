# Plan — Blender / Asset-Generation Toolchain Setup

**Goal:** stand up the 3D→2D-sprite pipeline that will replace the prototype's
numbered-frame placeholders with real animation frames, and **prove it end-to-end on one
action** (the flamenco dancer's **walk cycle**). Success = a real rendered walk cycle
animating in the running Conjugar prototype, plus a repeatable, documented render harness.
Fresh-session task; read the context first.

## Read first
1. `docs/game_design_research.md` — **§3 (asset-generation & animation pipeline)** is the
   spec this plan operationalizes. Especially **§3.3** (dancer via Mixamo), **§3.6**
   (Blender role, automation, concrete render settings), **§3.7** (Xcode integration).
2. `prompts/game.md` (spec) and `prompts/game_prototype.md` (what we're feeding frames
   into — the walk action currently renders `Text("\(i)")`; the end-to-end test swaps that
   for `Image("dancer_walk_\(i)")`).
3. The **decided pipeline** (from research): concept art (**Gemini**) → 3D mesh (**stock
   Mixamo character** first; **image-to-3D** for the custom dancer later) → rig + mocap
   (**Mixamo**, free/royalty-free) → **Blender** orthographic render to transparent PNG
   frames → `Assets.xcassets`. Stills (bullfighter, capes, backgrounds) come from Gemini.

## Environment note (who runs what)
This machine is macOS. Several steps are **GUI / interactive / login-gated** and should be
run by **Josh** (use the `! <command>` prompt prefix for shell installs so output lands in
the session; do GUI logins manually). **Claude** does the scriptable parts: adding the MCP
server, writing/running the render harness, driving Blender via MCP once connected, and the
one-line prototype swap. Each phase below marks **[Josh]** / **[Claude]**.

---

## Two ways we'll drive Blender (set up both)
- **(A) Headless CLI — the workhorse, most robust.** `blender -b model.blend -P
  tools/blender/render_sprites.py -- <args>`. No GUI, no MCP; Claude can run it via Bash.
  This does the repeatable batch frame-rendering.
- **(B) blender-mcp — interactive.** Lets Claude drive a *live* Blender for scene setup,
  one-offs, and — usefully — it wires in **image-to-3D** (Hunyuan3D, Hyper3D Rodin) and
  **Sketchfab/PolyHaven** downloads (great for sourcing the bull later). Needs the Blender
  GUI running with the addon "Connected"; executes arbitrary Python (save first).

---

## Phase 0 — Prereqs & install  [Josh runs installs, Claude verifies]
- **Blender** (aim 4.2 LTS or newer, min 3.0): `brew install --cask blender` (or download
  from blender.org). Verify: `blender --version`.
- **uv** (for `uvx blender-mcp`): `brew install uv`.
- **ImageMagick** (sprite-sheet packing / slicing): `brew install imagemagick`. Verify:
  `magick --version`.
- Python 3.10+ available (Blender bundles its own for scripts; system Python only for
  tooling). Verify `python3 --version`.
- **[Claude]** Confirm each is on PATH via Bash and record versions.

## Phase 1 — Wire blender-mcp + smoke test  [Josh: addon+connect · Claude: register+test]
- **[Josh]** Install the Blender addon: download `addon.py` from
  `https://github.com/ahujasid/blender-mcp`, then Blender → *Edit ▸ Preferences ▸ Add-ons ▸
  Install…* → enable **"Blender MCP"**. In the 3D viewport sidebar (`N`), open the
  **BlenderMCP** tab and click **Connect** (starts the socket the server talks to, default
  port 9876). Leave Blender open.
- **[Claude]** Register the server with Claude Code:
  `claude mcp add blender -- uvx blender-mcp` (stdio). Then, in a session where the tool is
  available, **smoke-test**: ask Blender (via MCP) to clear the scene, add a cube, set an
  orthographic camera, and render a frame — confirm a PNG comes back. (The blender-mcp tools
  surface via ToolSearch like other MCP tools.)
- **Gotcha:** interactively-authenticated MCP servers can be absent in headless/cron runs,
  and blender-mcp needs the GUI + "Connect" live. If MCP wiring is fiddly, **don't block** —
  Phase 3's headless CLI path needs neither MCP nor the GUI and is sufficient for rendering.

## Phase 2 — Accounts & first animation source  [Josh: logins/exports · Claude: advises]
- **[Josh] Mixamo** (`https://www.mixamo.com`, free with an Adobe account): for the **first,
  fastest** validation, pick a **stock Mixamo character** (skip custom-mesh work entirely),
  apply a **Walking** clip, and **Download → FBX** (choose 30 fps, "with skin"). Save to
  `tools/blender/source/dancer_walk.fbx`. License: royalty-free commercial, no attribution,
  only can't resell raw assets — fine for an embedded app (log it in `asset-licenses/`).
- **[Josh, later]** Custom flamenco dancer: generate a concept with the **`gemini-image`
  skill** (front/side turnaround, Conjugar red+gold), then either **image-to-3D** (Meshy or
  Tripo — both include auto-rig) or hand-build a base humanoid; upload to Mixamo to auto-rig
  + retarget walk/idle/climb/jump/**dance**. (Not needed to prove the pipeline — do it after
  Phase 4.)
- **[Claude]** Confirm the `gemini-image` skill is available for concept/stills, and
  `remove-watermark` for cleaning Gemini output. Note stills we'll want later: bullfighter
  (1 frame), capes, platform/ladder art if we upgrade from primitives, background, HUD.

## Phase 3 — Author the render harness  [Claude]
Create `tools/blender/`:
- **`render_sprites.py`** — a Blender Python script that:
  - imports the FBX (or operates on the open scene),
  - sets **EEVEE** render engine, **Film ▸ Transparent ON**, output **PNG / RGBA**,
  - adds an **orthographic** camera, **side view** (platformer profile), and frames the
    action (set `camera.data.ortho_scale`, or auto-fit to the mesh bounds across the whole
    frame range so a jump's peak isn't clipped),
  - (optional, palette) a Sun + a flat/**toon** material (Diffuse BSDF + ColorRamp) tuned to
    **Conjugar's palette** — customRed `#C1001D`, customYellow `#CDA51B` (see §3.6/§5);
    render the raw model first, add toon once it works,
  - for the chosen **action + frame range**, renders each frame to
    `tools/blender/renders/<actor>_<action>/<action>_####.png`,
  - is **parameterizable** via `--` CLI args: `--actor dancer --action walk --frames N
    --size 288 --ortho 2.2 --out <dir>` (pick a 3× target size, e.g. 96 pt → 288 px).
- **`pack_or_rename.sh`** — either rename frames to the Xcode convention
  `dancer_walk_1.png … dancer_walk_N.png`, **or** pack a sheet:
  `magick montage renders/dancer_walk/*.png -geometry 96x96 -tile 8x1 -background
  transparent -filter Catrom dancer_walk_sheet.png` (grid sized to N).
- **`README.md`** — document the full pipeline (Mixamo → FBX → `render_sprites.py` → rename/
  pack → `Assets.xcassets`), with exact commands, the render settings from §3.6, the palette
  hex, and how to add a new action.
- **Test headless** on the Phase-2 FBX:
  `blender -b tools/blender/source/dancer_walk.fbx -P tools/blender/render_sprites.py --
  --actor dancer --action walk --frames 8 --out tools/blender/renders`.
  Confirm N transparent PNGs land. Pick **N ≈ 6–8** frames (RaceRunner used ~10 at 10 fps);
  use Mixamo "frame reduction" or sample every k-th frame to hit N.

## Phase 4 — End-to-end validation (the real proof)  [Claude + Josh]
- Copy the rendered `dancer_walk_1..N.png` (with @2x/@3x or a single 3× asset) into a new
  **`Conjugar/Assets.xcassets/Game/`** imageset group (auto-adds — the catalog is in a
  synchronized group).
- In the prototype's `GameView`, **swap the walk action's placeholder** from
  `Text("\(currentFrame)")` to `Image("dancer_walk_\(currentFrame)").resizable()
  .interpolation(.none)` — a one-line change if the prototype kept the frame-index seam
  (it should; see `game_prototype.md` "Notes").
- **Pre-decode** the frames once at load (see research §2.2) so there's no per-frame decode
  hitch. Build + run (`ios-build-verify`), open **Settings → Play**, and confirm the dancer
  **walks with real frames** while every other actor still shows numbers. That single
  action animating from the real toolchain proves the whole pipeline.

## Phase 5 — Document & scaffold  [Claude]
- Commit `tools/blender/` (script + README).
- Create **`asset-licenses/`** with a short `README.md` (per the CC-BY decision in research
  §4): one entry per sourced asset — Mixamo animation, any Sketchfab model, CC-BY track/SFX
  — recording Title / Author / Source-URL / License, plus the downloaded license
  certificate/deed. (These will be surfaced in the app's future Credits screen.)
- Add a `docs/blog_notes.md` entry summarizing the toolchain (per CLAUDE.md).

---

## The bull (quadruped) — note for a later session
Not part of this setup's validation (the dancer is the fast win). When ready: source a
**pre-rigged bull** (Sketchfab "Simple Rigged Bull" — **verify its per-model license**,
log in `asset-licenses/`) or rig one with Blender **Rigify's quadruped meta-rig**, then
hand-key walk / climb / throw / defeat, and render through the **same `render_sprites.py`**
harness. This is the animation cost-center (no Mixamo shortcut for quadrupeds); budget time.
blender-mcp's Hunyuan3D/Rodin + Sketchfab integration (Phase 1) helps source/generate the
mesh.

## Concrete render settings (from research §3.6)
- Camera **Orthographic**, side view; set `ortho_scale` to fit the action's extremes.
- **Film ▸ Transparent ON**; output **PNG, RGBA**.
- Sun light + flat/**toon** material (Diffuse BSDF + ColorRamp) in the Conjugar palette;
  optional Solidify-modifier outline for a drawn look.
- Headless: `blender -b file.blend -P render_sprites.py` (script sets the frame range and
  renders); or `-a` to render the scene's animation range.
- Pack: `magick montage *.png -geometry WxH -tile CxR -background transparent -filter
  Catrom sheet.png`; or keep loose PNGs as imagesets named `dancer_walk_1…N`.

## Definition of done
- `blender --version`, `magick --version`, `uv --version` all succeed (versions recorded).
- **(Bonus)** blender-mcp smoke test renders a cube from a Claude session.
- `tools/blender/render_sprites.py` renders a Mixamo walk to **N transparent numbered PNGs**
  headlessly, documented in `tools/blender/README.md`.
- The **prototype shows a real rendered dancer walk cycle** (walk action only) in place of
  the numbers — pipeline proven end-to-end.
- `asset-licenses/` scaffolded; blog note added.

## Gotchas
- blender-mcp executes arbitrary Python and needs the GUI "Connected" — **save before
  driving it**, and prefer the **headless CLI** for batch renders (robust, unattended).
- Mixamo export: pick **30 fps + frame reduction** (or sample every k-th frame) to land ~6–8
  clean cycle frames; a raw 30-frame walk is more than the flipbook needs.
- Match the **frame-index seam** the prototype already uses, so real art is a one-line swap
  (`Text` → `Image`). Keep the numbered-frame fallback for un-rendered actions.
- Log **every** sourced asset in `asset-licenses/` as you go — cheap now, painful to
  reconstruct later.
