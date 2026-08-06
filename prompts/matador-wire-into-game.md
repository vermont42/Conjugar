# Plan — wire the matador (kidnapped-bullfighter goal figure) into the game

**Goal:** the matador **sprite asset is DONE and approved** (see below). This session's job
is to get it **into the running game**: bake the render into `Assets.xcassets/Game/`, place
the matador **standing next to the bull on the top platform** in `GameView`, log the
purchase/license, credit + blog it, and verify live in `conjugar://game`. No new 3D/art work
is required — the look is signed off; this is asset-packing + SwiftUI wiring.

## What the matador is (design)

`prompts/game.md` decision #1–2: the game is Donkey-Kong-shaped — the flamenco **dancer** is
the player, the **bull** is the antagonist on the topmost platform, and **"next to the bull is
a bullfighter that the bull kidnapped."** The player rescues the bullfighter to win. Crucially:
**"the bullfighter needs only one frame."** So the matador is a **static, single-frame GOAL
figure** on the top platform beside the bull — no animation, no rig in-game, just one sprite.
Recolor spec (`prompts/matador.md`): a **blue** suit (dominant, so it's neither the gold dancer
nor the red bull), **gold** vest + montera, **pink** socks, **dark-red** shoes (quoting the
bull's hooves), facing the viewer, **hands on hips**, feet shoulder-width, no muleta.

## Current state — DONE before this session (2026-07-12)

- **Sourced + bought.** CGTrader vfxsinghbu **"Matador - Bullfighter Rigged"** (model
  **#5905689**, $42.50, **CGTrader Royalty-Free (no-AI)**), a Daz **Genesis 8 Male**. Same
  store/license path as the dancer. Josh purchased it.
- **Full purchase preserved + git-ignored** under `tools/blender/source/` (the `source/` rule
  in `tools/blender/.gitignore` covers it): `matador.blend` (rigged, 81 MB), `matador.fbx`,
  `matador_tex.rar` (textures, 254 MB), plus the derived `matador_clean.blend` and the
  ready-to-render **`matador_posed.blend`**.
- **Generator committed:** `tools/blender/gen_matador.py` cleans the scene (drops ~25 junk
  objects + the cape, hides the heavy vendor hair), **clears the Daz IK constraints** and poses
  the arms **hands-on-hips in pure FK**, and repositions/scales the **montera** onto the head.
  Raw `matador.blend` → `matador_posed.blend` in one command.
- **Render mode committed:** `render_sprites.py` gained **`--matador`** (per-garment cel color
  map `MATADOR_MESH_COLORS`: jacket/pants=blue, vest/hat=gold, socks=pink, shoes=dark-red =
  `red×0.60` bull-hoof, shirt=cream, body=skin) and now **skips `hide_render` meshes** (so the
  hidden hair neither renders nor inflates the auto-fit). New palette hues: `blue/pink/skin/cream`.
- **Approved render on disk:** `tools/blender/renders/matador_idle/idle_0001.png` (384 px,
  `--view back` = the FACE, `--toon --matador --outline`). Josh signed off after three tweak
  rounds (hands-on-hips not "reins"; solid montera; montera raised so the eyes + a little
  forehead show). **Acceptance test PASSED** beside the bull + dancer.

### Regenerate / re-render (if ever needed)
```bash
# raw purchase -> posed blend (clean + pose + hat)
blender -b tools/blender/source/matador.blend -P tools/blender/gen_matador.py
# posed blend -> sprite PNG.  --view back = FACE (the model faces -Y).
blender -b tools/blender/source/matador_posed.blend -P tools/blender/render_sprites.py -- \
    --actor matador --action idle --frames 1 --size 512 --view back \
    --toon --matador --outline --out tools/blender/renders
```

## Read first
1. This file, and `prompts/matador.md` (look spec) + `prompts/game.md` decision #1 (role).
2. `tools/blender/README.md` — esp. **"The bull"** (the `--size 512` + `.interpolation(.high)`
   resolution lesson) and the crop-box→`GameView`-constants coupling. Add a **"The matador"**
   section as part of Phase 4.
3. `tools/blender/render_sprites.py` (`--matador`, `apply_matador_materials`,
   `MATADOR_MESH_COLORS`) and `tools/blender/gen_matador.py` (pose/hat params + the IK-cleared
   pure-FK note).
4. `Conjugar/Views/GameView.swift` — how the **bull** is drawn on the top platform, and the
   dancer/bull sizing helpers (`dancerVisualHeight`, `dancerWidth(_:)`, `bullCrop(_:)`,
   `bullScale`, feet offsets). The matador reuses this crop-px→pt pattern.
5. `Conjugar/Models/Game/GameModels.swift` + `GameState.swift` — `Platform` (level 0 = bottom,
   highest level = top, where the bull lives), and how the bull's on-screen position is derived.

---

## Phase 1 — Finalize + bake the sprite  [render → crop → imageset]
1. **Re-render at `--size 512`** (per the bull's resolution lesson — the matador may display
   fairly large next to the bull; 512 keeps the face/montera crisp on device). Command above.
2. **Crop + name:** `tools/blender/pack_or_rename.sh rename matador idle` →
   `tools/blender/dist/matador_idle_1.png`. **Record the printed `WxH` crop box** — it drives
   the Phase-2 size constant.
3. **Add the imageset:** drop the PNG into a new
   `Conjugar/Assets.xcassets/Game/matador.imageset/` (single 3× asset; the `Game/` catalog is
   in a synchronized group, so **no `project.pbxproj` edit**). One frame → no flipbook, so a
   plain `matador` name (not `matador_idle_1`) is fine — pick one and be consistent.

## Phase 2 — Place the matador next to the bull  [GameView]
The matador is a **static `Image("matador")`**, so this is placement + sizing, not animation.
1. **Find the bull's top-platform placement** in `GameView.swift` (its position on the highest
   `Platform` and how `bullScale`/`bullCrop` map crop-px → screen pt). Place the matador on the
   **same platform, beside the bull** (e.g. a fixed horizontal offset to the side the bull is
   *not* facing, or the opposite end of the top girder — pick what reads as "captive beside the
   captor"; confirm with a screenshot).
2. **Size it** with the crop box from Phase 1, mirroring the dancer's "constant visual height,
   width from aspect" approach: pick a `matadorVisualHeight` (a standing man ≈ the bull's body
   height or a touch taller — start by eye against the bull, then tune), derive width from
   `cropW/cropH`, and a feet offset so his shoes sit **on** the girder surface (`Platform.surfaceY`).
3. **Facing:** he faces the viewer (front render) — **no mirroring** (unlike the dancer/bull).
4. **Interpolation:** use `.interpolation(.high)` (the 512→display downscale; nearest-neighbor
   frays the outline — the bull lesson). `.resizable()`.
5. **MVP = static beside the bull.** The full design has the bull **escape upward with the
   bullfighter** the first four times the player reaches the top (`game.md`); wiring the matador
   to *ride along* with the bull's escape is a **follow-up**, not required here. Leave a
   `// TODO(matador escape beat)` and note it in the blog entry. Don't build the final fight
   scene here either.

## Phase 3 — License + credits + blog
1. **`asset-licenses/cgtrader-matador.txt`** — mirror `cgtrader-flamenco-dancer.txt`: Asset,
   Source URL (`https://www.cgtrader.com/3d-models/character/fantasy-character/matador-bullfighter-rigged`),
   Model ID **#5905689**, Author **vfxsinghbu**, License **CGTrader Royalty Free (no AI)**,
   Price **$42.50 (Weekend Sale, -50% from $85.00), purchased 2026-07-12**, Formats (OBJ/BLEND/
   DAE/C4D/GLTF/FBX). **Add the Genesis-8 note:** the base figure is Daz Genesis 8 Male; our use
   is **2D rendered sprites baked into the app only — the 3D mesh is never redistributed**, which
   is the least-risk use and matches the dancer precedent. Raw assets stay git-ignored.
2. **Credits screen** (Info ▸ Credits) — add an art credit line if the other rendered game assets
   have one (check how the bull/dancer are credited; match it).
3. **`docs/blog_notes.md`** — a "Matador goal figure" entry: sourced the male counterpart to the
   dancer on CGTrader (Genesis 8, separate garment meshes → the new `--matador` per-garment cel
   mode); the IK-cleared **pure-FK** hands-on-hips pose + the montera reposition; blue-dominant
   recolor (distinct from gold dancer / red bull, shoes quoting the bull's hooves); static
   one-frame goal figure beside the bull; the escape-beat + fight scene left as follow-ups.

## Phase 4 — Verify live + document the pipeline
1. Build (`~/.claude/skills/ios-build-verify/scripts/build_app.sh`).
2. Drive **`conjugar://game`** (see CLAUDE.md; `CONJUGAR_GAME_TIME_SCALE`/`_DISABLE_FLAGS` env
   vars to calm the field), screenshot the **top platform** showing the **bull + matador** side
   by side, correctly sized and feet-planted. Confirm he reads as a matador beside the bull and
   the outline separates him from the black field.
3. **`tools/blender/README.md`** — add a **"The matador"** section documenting the
   `gen_matador.py` → `render_sprites.py --matador` pipeline, `--view back` = face, the Genesis-8
   IK-clear/pure-FK pose, the montera vertex-reposition, and the per-garment color map.
4. Commit to the **`migration`** branch (only PNGs + Swift + docs + the two tool scripts ship;
   raw `.blend/.fbx/.rar` stay git-ignored).

## Key facts the fresh session needs (don't rediscover)
- **`--view back` shows the FACE** — the Genesis-8 model faces **−Y**. `--view front` shows his back.
- **`--matador` requires `--toon`.** Per-garment split is by mesh-name substring
  (`MATADOR_MESH_COLORS`); the Cape mesh is *deleted* in `gen_matador.py`, not colored.
- **The Daz rig has IK constraints** that override FK; `gen_matador.py` clears all 255 pose-bone
  constraints so the static pose is pure FK. **For future animation** (Josh asked): the mesh is
  fully rigged and animatable — restore/drive the IK targets (`lHand_IK`/`rHand_IK`) or hand-key
  FK like `gen_dancer_action.py`, then render N frames through `render_sprites.py --matador`.
- **Crop boxes drive `GameView` size constants** (the recurring trap) — take the matador's
  `WxH` from `pack_or_rename.sh`, don't guess.
- **Resolution:** render 512 + `.interpolation(.high)` for a large-ish display (bull lesson);
  don't upscale a small render.

## Definition of done
- `matador.imageset` in `Assets.xcassets/Game/`; matador **stands beside the bull on the top
  platform** in `GameView`, correctly sized (from its crop box) and feet-planted, facing the
  viewer, reading as a matador at game size.
- `asset-licenses/cgtrader-matador.txt` (with the Genesis-8 render-only note) + a Credits line
  + a `docs/blog_notes.md` entry; `tools/blender/README.md` "The matador" section.
- App builds; verified live in `conjugar://game` with a screenshot of the bull + matador; the
  escape-beat/fight-scene left as noted follow-ups. Committed to `migration`.

## Gotchas
- **One static frame** — resist building a flipbook or the escape/fight animation now.
- **Genesis-8 license framing** — safe *because* it ships only as 2D sprites; say so in the
  license file; never commit the raw 3D.
- **SourceKit false positives** editing `GameView.swift` — `build_app.sh` is authoritative.
- **Don't reuse the dancer/bull crop numbers** for the matador — re-capture his own.
- The approved 384 px render is on disk; re-render at 512 for shipping (same look, more pixels).
