# Spike — a rendered-realistic dancer (Vainglory-style), for a go/no-go art decision

**This is a SPIKE, not a ship.** Goal: produce **one** side-by-side comparison image —
the current flat-cel gold dancer next to a *rendered-realistic* dancer — at the sizes the
game actually draws, so Josh can decide whether to pivot the game's art direction from
**stylized-flat cel** to **rendered-realistic** (à la `~/Desktop/vainglory.png`). The
output is a **decision artifact**, deliberately throwaway. Do the minimum that makes the
choice honest; do **not** rig, animate, wire, or productionize anything.

**The decision this informs (the fork):** Phases 1–7 of `game_toon_palette.md` deliberately
committed the game to a flat gold/red cel look with a black outline. Vainglory is the
*opposite* aesthetic — fully-textured PBR characters, dramatic 3-point + rim lighting,
bloom/HDR tonemapping, no cel outline (rim light separates figures). You cannot have both.
This spike exists to answer **"is the realistic look enough better, at our real sprite size,
to justify the pivot?"** — with two images, not two adjectives.

**What specifically to emulate** (not the whole game — the character read *plus its immediate
context*): a bespoke **costumed** character (not a mannequin), real materials (cloth/skin/metal),
a strong **key + rim/back light** giving form and separation, warm bloom + filmic tonemapping,
clean anti-aliased edges — **on a lit, atmospheric ground**, not floating on flat black.

**The size truth — corrected by `~/Desktop/vainglory2.png` (Vainglory on an actual iPhone):**
measured, Vainglory's **hero renders at only ~60pt tall** on-device (≈180px in a 1125px landscape
screen at 3×) and its minions at ~30–35pt. That is **the same on-screen scale as Conjugar's ~57pt
dancer** (`GameView.dancerVisualHeight = 57.3`). So the naive worry — "realistic detail dies at
56pt, so you'd have to draw the dancer much bigger" — is **wrong**; Vainglory proves a premium
read is achievable at exactly our size. It just comes from a **different place than texture
detail** (which genuinely does vanish at 60pt): it comes from **lighting (rim/back separation),
bloom/glow, clean color-blocking + anti-aliased silhouette, and — heavily — the lit, atmospheric
environment** the character sits in. Design the spike around *those* levers, judged at ~60pt, not
around cramming in fine detail or scaling the dancer up.

**Consequence for scope:** because so much of the premium is the **world**, the environment can
**not** be cleanly deferred the way an earlier read of this assumed. A beautifully-lit dancer
composited onto Conjugar's flat black + red-girder field will likely look *worse* than the cel
sprite, not better — it will read as a high-fidelity figure orphaned from its context. So the
comparison in Phase 4 **must** put the realistic dancer on at least a *minimally dressed* ground
(a lit floor with AO/gradient + a hint of atmosphere), or it stacks the deck against the pivot.

---

## Current state (what the spike starts from, 2026-07-11)
- **Dancer mesh = Mixamo X Bot** — a featureless grey mannequin, no costume/face/detail. This
  is *the* limiter; a realistic render of the X Bot would still look like a lit mannequin.
- **Render harness** = `tools/blender/render_sprites.py` (orthographic sprite renderer). It has
  a `--toon` cel path (`apply_cel_material`, `setup_outline`) that **clears** the mesh's own
  materials and applies a flat banded emission + Freestyle outline, on **EEVEE-Next**, with the
  **Standard** view transform. The realistic mode is the near-inverse of all of that.
- **This build exposes only `BLENDER_EEVEE_NEXT` headless** (`resolve_engine` probe found no
  `CYCLES`/`WORKBENCH` in the engine enum — verified 2026-07-11). So the spike likely renders on
  **EEVEE-Next**, not Cycles. EEVEE-Next is capable (AO, soft/contact shadows, screen-space GI,
  raytraced reflections, plus compositor bloom) — good enough to judge the look. **Re-check
  Cycles availability in Phase 2**; use it if it's actually there.
- **Comparison baseline** = the shipped cel dancer PNGs in
  `Conjugar/Assets.xcassets/Game/dancer_*.imageset/` (e.g. `dancer_idle_1.png`, `dancer_walk_1.png`).
- **Sourcing tools already wired:** blender-mcp exposes Sketchfab search/download
  (`mcp__blender__search_sketchfab_models` / `download_sketchfab_model` — how the bull was
  sourced), plus AI image/text-to-3D (`mcp__blender__generate_hyper3d_model_via_text`/
  `..._via_images` = Rodin, and Hunyuan3D). The `gemini-image` skill can make a concept image
  to drive image-to-3D.

## Read first
1. This file's **decision/fork** + **56pt truth** sections.
2. `~/Desktop/vainglory.png` — the target character read (costume, rim light, bloom).
3. `tools/blender/render_sprites.py` — `apply_cel_material`/`setup_outline` (what the realistic
   mode must **not** do), `configure_output` (view-transform + engine handling),
   `setup_light`/`setup_camera` (the lighting/camera to extend), `resolve_engine` (engine enum).
4. `prompts/game_toon_palette.md` + `tools/blender/README.md` (the cel pass this would replace)
   and `docs/blog_notes.md`'s 7/11/26 entry (the color-management war stories — AgX vs Standard,
   sRGB→linear — which the realistic path *reverses*: it WANTS AgX/Filmic).
5. `Conjugar/Views/GameView.swift` — `dancerVisualHeight` (56→57.3) and the sprite sizes, so the
   mock uses the real on-screen dimensions.

---

## Phase 1 — Source ONE costumed dancer mesh  [Claude, cheap-first]
The spike lives or dies on the mesh — a lit mannequin proves nothing. Get **one** textured,
**costumed** flamenco (or generic) dancer in a **single static pose** (idle/standing or a dance
pose). **No rig, no animation** — the spike judges the *rendered look*, not motion. Try in order,
stop at the first that yields a usable textured mesh:
- **A. Rodin text-to-3D** (`generate_hyper3d_model_via_text`, prompt e.g. *"flamenco dancer,
  ornate red-and-gold costume, ruffled dress, full body, game character, PBR textured"*) →
  `import_generated_asset`. Fastest; AI mesh topology may be rough but fine for a look test; no
  attribution burden.
- **B. Gemini concept → Rodin image-to-3D** (`gemini-image` to art-direct the costume, then
  `generate_hyper3d_model_via_images`). More control over the exact costume/palette.
- **C. Sketchfab** (`search_sketchfab_models` "flamenco dancer", downloadable + CC) →
  `download_sketchfab_model`. The bull precedent; also the most *shippable* path (log the license
  in `asset-licenses/` **iff** this ever leaves the spike — not required for a throwaway).

Keep the raw mesh under `tools/blender/source/` (git-ignored). If the mesh imports T-posed or
in a dull pose, a quick manual pose in the GUI is fine — but don't sink time; a neutral standing
pose is enough to judge materials + lighting.

## Phase 2 — Add a `--realistic` render mode to `render_sprites.py`  [Claude, headless iterate]
A new path that is the near-inverse of `--toon`. Keep it a **separate flag** — do not disturb
`--toon`. It must:
- **Keep the mesh's own PBR materials** (do NOT clear slots the way `apply_cel_material` does).
  If the source mesh has no textures, apply a simple believable PBR (cloth roughness, a little
  skin subsurface) so it doesn't read plastic.
- **Light for form + separation.** Extend `setup_light` into a **3-point rig**: a warm **key**,
  a dimmer cool **fill**, and a bright **rim/back light** (the rim is what replaces the cel
  outline — it's how Vainglory separates figures from the ground). Tune on one frame.
- **Realism features on.** EEVEE-Next: enable **ambient occlusion**, **soft/contact shadows**,
  **screen-space GI/reflections** if present. **Re-check for Cycles** (`resolve_engine`) — if
  actually available headless, offer `--engine cycles` for GI/soft-shadow/AO truth and use it.
- **Filmic post, not flat.** Set the view transform to **AgX (or Filmic)** — the *opposite* of
  the cel path's Standard (realistic wants HDR tonemapping) — and add a **compositor Glare
  (bloom)** node for the warm glow. This is where "premium" comes from; don't skip it.
- **No outline.** `--realistic` must not call `setup_outline`.
- **Higher res.** Render at `--size 512` (not 192) so detail exists to downsample.
- **Iterate on ONE frame** (key light angle, rim intensity, bloom threshold) before declaring done.

## Phase 3 — Render the spike frame(s)  [Claude, headless]
Render **1–3 frames** of the sourced dancer through `--realistic` at `--size 512`, side or a
slight 3/4 view (`--view side`; a 3/4 needs a small camera-azimuth nudge — optional). One strong
hero frame is the minimum; a couple of poses is a bonus. **Do not** render all 8 actions — this
is a look test, not the production set.

## Phase 4 — Build the comparison artifact  [Claude]
The deliverable. Put the **current cel dancer** and the **realistic dancer** side by side **at
Vainglory's real on-device scale**, since that scale (~60pt) is now known to be the decisive test:
- **Primary panel: ~57–60pt-tall** — the game's actual `dancerVisualHeight` (×3 = ~168px asset),
  i.e. exactly how big Vainglory draws its hero on an iPhone. This is *the* comparison.
- Secondary: a **~110pt-tall** blow-up only to show detail headroom — clearly labeled "not the
  game's size," so it doesn't flatter the realistic look dishonestly.
- **Ground matters (per the size-truth correction):** show the realistic dancer on a *minimally
  dressed* field — a lit floor with AO/gradient + faint atmosphere — **not** bare `customBackground`.
  For a fair fight, also show the *cel* dancer on the current flat field (its native habitat) so the
  contrast is look-vs-look, not context-vs-no-context. A red-girder swatch for scale is fine.
- Assemble as a self-contained **HTML Artifact** (the `Artifact` tool) — nicer for Josh to review
  and share — showing both looks at the ~60pt primary size (and the blow-up) with labels; or a
  `docs/` montage PNG if simpler. Consider an `ios-design-agent-skill` pass for an aesthetics critique.
- Caption the honest takeaways: does the realistic dancer read as *premium* at ~60pt? How much of
  that is the **lighting/rim/bloom** vs the **dressed ground**? Is the gold palette preservable as a
  **costume color** (gold dress) rather than a flat fill?

## Phase 5 — Decide + record  [Claude + Josh]
Write a short **findings** note (in the artifact and/or `docs/blog_notes.md`) with a **go/no-go
recommendation** and the *reasons*, covering:
- **Does it look meaningfully better at the sizes the game uses?** (The whole question.)
- **Cost to productionize** if "go": a costumed mesh must be **rigged** (Mixamo auto-rig or
  equivalent) and animated for **all 8 actions** (idle/walk/climb/jump/cape + bull idle/walk/throw),
  each re-lit and re-rendered; the outline work is discarded; the background likely also needs an
  atmospheric restyle to match, or the premium characters float on a flat field.
- **Brand fit:** can gold/red survive as costume/accent colors (recommended reconciliation) or does
  realism dilute the identity?
- **Bull:** the bull is already a real model — note whether the same `--realistic` treatment on it
  (cheap to try as a bonus frame) also improves, since a pivot is both actors.

If **go**, the next plan is the real thing (source + rig + animate + light + render + wire all 8,
plus background) — out of scope here. If **no-go**, keep the shipped cel look; the spike code stays
as an unmerged experiment.

## Definition of done
- One sourced **costumed** dancer mesh rendered through a new `--realistic` mode (kept materials,
  3-point + rim light, AO/soft-shadow, AgX + bloom, no outline, 512px).
- A **side-by-side comparison artifact**: cel vs realistic, each at **56pt and ~110pt** on the game's
  dark field, honestly labeled.
- A written **go/no-go recommendation** with reasons (look-at-size, productionization cost, brand fit).
- Nothing shipped, nothing wired, `--toon` untouched, no imageset swaps, no credits change.

## Gotchas
- **Judge at ~60pt, and know what carries at that size.** `vainglory2.png` proves a premium read
  IS achievable at Conjugar's ~57pt scale — so "it's too small to look good" is not a valid excuse
  for a weak result. But what carries at 60pt is **lighting (rim separation), bloom, clean AA,
  color-blocking, and the lit ground** — *not* fine texture/mesh detail, which vanishes. Spend the
  effort there. A gorgeous 512px render that's mush at 60pt means you optimized the wrong things,
  not that the size is hopeless.
- **Don't test the character on a bare field.** Half of Vainglory's premium at small size is the
  environment. Comparing a lit dancer on flat black against a cel dancer designed for flat black
  is a rigged fight — dress the ground minimally (Phase 4).
- **`--realistic` is the inverse of `--toon`.** AgX/Filmic (not Standard), keep materials (don't
  clear), bloom on, **no** outline, rim light instead of a cel edge. Don't copy the cel path's
  color handling — its sRGB→linear + Standard choices are wrong here.
- **Cycles may be unavailable headless** (only EEVEE-Next was in the enum on 2026-07-11). Don't
  block on Cycles; EEVEE-Next + AO + soft shadows + compositor bloom is enough to decide. Verify,
  don't assume, in Phase 2.
- **No rigging/animation in the spike.** A single static pose answers the look question. Rigging is
  the expensive part and belongs only in the *production* plan if this goes.
- **A mannequin proves nothing** — the mesh must be **costumed**. If sourcing stalls, that itself is
  data about productionization cost; surface it rather than rendering a lit X Bot and calling it the test.
- **SourceKit noise** editing `render_sprites.py` is irrelevant (it's a Blender script, not app code);
  correctness is "does `blender -b` render it."
- **Raw meshes stay git-ignored;** the spike ships no assets. Only the comparison artifact + the
  `--realistic` code are worth keeping, and only if Josh wants the experiment retained.

## Not in scope (belongs in the production plan iff "go")
- Rigging + animating all 8 actions, re-lighting/rendering the set, wiring into `GameView`, crop-box
  re-derivation — the full pipeline `game_toon_palette.md` ran, redone for realism.
- **Full background/environment restyle** — the spike mocks only a *minimal* dressed ground under
  the one dancer (Phase 4) to make the comparison fair. Actually rebuilding Conjugar's world to
  Vainglory-grade atmosphere (lit terrain, foliage, depth) is a big, separate effort — but note it
  is now understood as **load-bearing** for the pivot, not optional polish (per the size-truth
  correction), so a "go" decision is really a "go on characters **and** environment" decision.
- **Perspective/redesign** — Vainglory is 3/4 top-down real-time 3D; Conjugar is a 2D side-view
  platformer. Matching the *look* doesn't require this, and changing it is a game redesign, not art.
- **Real-time 3D characters** (vs pre-rendered sprites) — the truest way to match Vainglory, and the
  largest possible scope; explicitly not this spike.
