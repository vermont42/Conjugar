# Spike — paid/marketplace assets to clear the app-icon floor (dancer) + give the bull character

**This is a SPIKE with a small budget, not an open commission.** Goal: get the in-game
**dancer** to at least the quality of **Conjugar's own app icon** (the agreed *floor*;
Vainglory-level realism is a *bonus*, not the bar), and give the **bull** real character
(accents, or full realism) instead of reading as a flat red blob — by **sourcing better
assets cheap-first** (marketplace + a paid-AI lottery ticket), not by re-doing the render
pipeline. Josh is willing to pay for assets; Fiverr is the explicit fallback if self-serve
assets don't clear the bar. The output is a **go/decision** on which asset to buy + a
render-test proving it clears the floor — *then* (if it does) wiring it in.

**The reframe that drives this spike (read this first):** the render pipeline is **not** the
problem. `render_sprites.py --toon` already cel-shades correctly, and the new `--realistic`
mode (added in the prior spike) does lit/rim/bloom. The problem is the **mesh**: the shipped
dancer is the Mixamo **X-Bot mannequin** — no dress, no female form — so no shading can make
it read as the icon. **Fix the mesh, keep the pipeline.** One good, *riggable* dancer mesh,
run through the existing `--toon`, clears the floor immediately — and the *same* mesh can go
through `--realistic` later for the Vainglory bonus. So this spike is fundamentally an
**asset-sourcing** exercise with a fixed, cheap acceptance test.

**The floor, concretely — `Conjugar/Assets.xcassets/AppIcon.appiconset/icon1024.png`:** a
clean **flat-vector flamenco dancer** — red dress with **gold wavy ruffle bands** at the hem,
black hair in a bun, cream skin, a dynamic one-arm-raised pose, blue ground. The in-game
dancer must read as unmistakably *her*: a woman, a flamenco dancer, with a real dress — not a
genderless mannequin. Match the icon's **read**, not necessarily its exact palette (see the
palette note in Gotchas).

---

## Current state (what this spike starts from, 2026-07-12)

- **Prior spike verdict (see `docs/blog_notes.md` 2026-07-11 entry + the published artifact):**
  free-tier Rodin AI 3D gen **failed** three ways (incoherent blobs / a flat cardboard slab) —
  do **not** repeat free text/image-to-3D and expect a usable figure. A premium *look* is
  achievable and on-brand; the blocker is a *riggable, animatable* mesh shaped like the icon.
- **The render pipeline is done and reusable:** `tools/blender/render_sprites.py` has both
  `--toon` (banded cel, `--color gold`/`red`, Freestyle `--outline`) and the new **`--realistic`**
  (keep PBR materials, 3-point + rim light, AgX, compositor bloom, no outline, `--size 512`,
  EEVEE-Next only — **no Cycles** headless on this build). Pipeline how-to: `tools/blender/README.md`.
  The Mixamo→FBX→render→`pack_or_rename.sh`→`Assets.xcassets/Game/` flow is documented there.
- **Reference art already in `tools/blender/source/` (git-ignored):** `dancer_concept_front.png`
  (clean A-pose front, gold gown + red ruffles — good AI image-to-3D input **and** an artist
  reference) and `dancer_realistic_hero.png` (the Vainglory-style hero Josh liked — use as the
  *target* pin for any commission/AI brief).
- **The bull is already a real mesh** (Sketchfab "Simple Rigged Bull" by Leo_Aguiar, **CC BY 4.0**;
  `asset-licenses/sketchfab-bull.txt`; `tools/blender/source/bull*.fbx` / `bull.blend`). Its
  *shape* is fine; it only reads as a blob because `--toon` fills it flat red with no accents.
- **In-game sizing:** `GameView.dancerVisualHeight = 57.3`; the pipeline auto-fits ortho by body
  height, and `pack_or_rename.sh` prints each action's `WxH` crop that the `GameView` size
  constants are keyed to (idle/walk/climb/jump/cape for the dancer; idle/walk/throw for the bull).
- **Blender MCP integrations are enabled** (Poly Haven, Rodin, Sketchfab, Hunyuan) but Rodin is on
  the **free trial** key and Sketchfab has **no** key. Paid AI or Sketchfab-download needs a real
  key pasted in the BlenderMCP sidebar panel (N-panel → BlenderMCP), then reconnect.
- **Claude-in-Chrome MCP is available, and Josh will authenticate in Chrome to whatever service the
  implementer needs.** So the implementer can *drive the browser directly* — search and evaluate
  TurboSquid/CGTrader/Sketchfab/Fab listings (wireframe, rig tab, license terms), and log into
  Meshy/Tripo/Rodin-Pro — with Josh signing in and confirming any **purchase/checkout himself**
  (never enter payment/credentials on his behalf; hand the actual buy click to him). This makes the
  Phase 1 shortlist and Phase 2 paid-AI runs first-class, not blocked on API keys.

## The acceptance test (the whole spike hinges on this — cheap, do it for every candidate)

> **Rig → `--toon` at 57 pt → hold next to the app icon.**
> 1. Get the candidate to a clean, upright, textured mesh (marketplace models often ship
>    **pre-rigged** — skip Mixamo; AI-gen meshes need Mixamo auto-rig, which needs clean
>    single-mesh humanoid topology in A/T-pose).
> 2. Render one **idle** frame: `render_sprites.py --fbx <candidate> --actor dancer --action idle
>    --toon --color gold --outline --frames 1 --size 192 --view side`.
> 3. Downscale to ~57 pt tall and compare against `icon1024.png`. **Pass = reads as a female
>    flamenco dancer with a dress at 57 pt.** If it passes, it's a buy; if not, next candidate.

A candidate that can't clear this at *idle* will not clear it across 8 animated actions — fail
fast, before spending or before sinking time into rigging.

---

## Phase 0 — Bull character, for $0 (do this first; no purchase)  [Claude, free]
The bull likely needs **no new asset** — just accents or realism. Try, in order, stop when it
reads as *a bull* (not a bull-shaped blob) at 57 pt:
- **A. Cel accents on the existing `--toon` bull.** Extend the toon material / add a second
  material slot so the bull isn't one flat red: a darker muzzle + hooves + horn tips, a lit
  highlight band, a visible eye. Optionally a small gold/red flag or ribbon prop for character.
  Keep it in the cel language so it still matches the dancer's cel look.
- **B. Ship the `--realistic` bull with a red-brown PBR skin.** The prior spike's `--realistic`
  bull already reads as sculpted marble; give it a believable red-brown hide (Principled base
  color + roughness, a little SSS) so it's a *realistic* bull. Only viable if the dancer also
  goes realistic (don't mix a cel dancer with a realistic bull).
- **C. If both disappoint,** a cheap marketplace "stylized/lowpoly bull" or a tiny accents
  commission — but exhaust A/B first. Log the outcome; the bull is secondary to the dancer.

## Phase 1 — Marketplace dancer shortlist (the reliable path)  [Claude shortlists via Chrome → Josh buys]
Browse the stores via **Claude-in-Chrome** (Josh auths as needed; he clicks the final purchase).
Present Josh **3–5 candidates** to choose/buy; he only pays for a winner. For each: thumbnail,
price, **rig status** (pre-rigged? humanoid? Mixamo-compatible?), topology/poly notes, format
(FBX/glTF/blend), and — critically — **license (must allow embedding in a distributed app)**.
- **Where:** TurboSquid, CGTrader, Sketchfab Store (paid), Epic **Fab** (formerly Unreal
  Marketplace/Sketchfab), Unity Asset Store. Search: *"flamenco dancer rigged"*, *"spanish
  dancer rigged character"*, *"flamenco dress character"*, and the fallback *"female dancer
  rigged"*.
- **Reality:** a *flamenco*-specific rigged model is rare. Fallbacks, in order: (a) a rigged
  female **dancer** whose costume can be re-textured/re-skinned to a flamenco gown; (b) a rigged
  base female + a separate flamenco-dress model; (c) a rigged female in *any* dress, retex to
  gold+red. The icon read (dress + female form + pose) matters more than literal flamenco couture.
- **License gate (hard):** reject "editorial only" / "no redistribution" models. Prefer Royalty-
  Free with app-embedding allowed. Log the chosen license in `asset-licenses/`.
- Deliver the shortlist as a short doc (or artifact); Josh picks + purchases + drops the file in
  `tools/blender/source/` (git-ignored).

## Phase 2 — Paid-AI image-to-3D lottery (cheap upside, in parallel)  [Claude via key or Chrome]
A cheap parallel shot: *if* paid AI clears the bar free Rodin missed, it's ~10× cheaper than a
commission. Feed the **existing** `dancer_concept_front.png` (clean A-pose) as image-to-3D input
at full fidelity:
- **Tools:** Rodin **Gen-2 / Pro** (paste a paid key into the BlenderMCP panel → drivable here),
  or **Meshy.ai** / **Tripo3D** (own accounts/keys). Prefer a mode that outputs **quad topology +
  rigged** if offered (some paid tiers do auto-rig).
- **Honest risk:** a figure in a ruffled dress is exactly what tripped free gen; paid gen has
  better textures but **rig topology is still the failure mode**. Treat as a lottery ticket, not
  the plan. Run the acceptance test immediately; don't polish a mesh that fails at idle.

## Phase 3 — Integrate the winner  [Claude]
Once a candidate passes the 57 pt acceptance test and is licensed:
1. **Rig** (if not pre-rigged): Mixamo auto-rig (upload clean humanoid, place markers), or use the
   model's own rig if Mixamo-compatible.
2. **Animate the 8 actions** — dancer idle/walk/climb/jump/cape (Mixamo clips: Breathing Idle,
   Walking, Climbing, Jump, Taunt — *In Place*) + bull idle/walk/throw (hand-keyed on its rig, as
   the prior bull pass did). Match N to `GameState.*FrameCounts`.
3. **Render** through `render_sprites.py` — `--toon --color gold --outline` for the icon-matching
   floor (or `--realistic` for the Vainglory bonus; pick ONE look for both actors — don't mix).
4. **Re-derive crop constants:** `pack_or_rename.sh` prints each action's new `WxH`; update
   `GameView.swift` (`dancerWidth(_:)` aspects, `dancerVisualHeight`, `bullCrop(_:)`/`bullScale`,
   feet offsets) exactly as the toon/outline pass did — don't reuse old crop numbers.
5. **Wire + verify live:** swap the imagesets in `Assets.xcassets/Game/`, drive
   `conjugar://game` (time-scale env var to freeze-frame), confirm each action reads and the
   dancer/bull are sized right relative to platforms.

## Phase 4 — Decide + record  [Claude + Josh]
Short findings note in `docs/blog_notes.md` + a before/after (old mannequin vs new dancer at 57 pt,
against the icon): what was bought, cost, license, which path won (marketplace vs paid-AI vs
Fiverr), whether the floor is cleared, and whether to also do the `--realistic` bonus. If **no**
self-serve asset clears the bar, hand off to **Fiverr** with a brief (see Gotchas) — this spike's
render-test + reference art (`dancer_realistic_hero.png`, the icon) *is* the brief.

## Definition of done
- Bull reads as *a bull with character* at 57 pt (Phase 0 free-fix, or a cheap asset).
- A dancer asset that **passes the 57 pt acceptance test against the app icon**, is **licensed for
  app distribution** (logged in `asset-licenses/`), rigged, animated across all its actions,
  rendered through the existing pipeline, wired into `GameView`, and verified live.
- Findings + cost/license/path recorded; `--toon`/`--realistic` code unchanged (assets only).

## Gotchas
- **It's a mesh problem, not a shader problem.** Don't "fix" the dancer by tweaking `--toon`.
  The pipeline is fine; the mannequin is the fault. Spend the budget on the *mesh*.
- **Rig topology is the real risk, and why marketplace ≫ AI gen for animation.** Mixamo auto-rig
  needs a clean single watertight-ish humanoid in A/T-pose; AI-gen meshes (messy topology, fused
  limbs, a dress welded to legs) often can't be rigged or deform horribly. Prefer **pre-rigged**
  marketplace models. Test riggability *before* buying where possible (many stores show wireframe).
- **License is a hard gate, not a footnote.** "Editorial use only" / "no redistribution" models
  cannot ship in the app. Verify app-embedding is allowed *before* purchase; log it in
  `asset-licenses/` like the CC-BY bull.
- **Palette decision — the icon vs the game diverge, on purpose.** The **icon** is a *red* dress
  with *gold* ruffles; the **game** made the dancer **gold** (hero) and the bull **red** (villain)
  for silhouette contrast against the red girders. Recommendation: keep the game's **gold dancer /
  red bull** hero-villain scheme (it's an established gameplay read), but shape her like the icon —
  i.e. the `dancer_realistic_hero.png` inversion (gold gown, red ruffle trim) is the target, not
  the icon's exact red. Confirm with Josh if in doubt; don't silently recolor.
- **Vainglory is the bonus, the icon is the floor — don't overspend chasing realism.** A clean
  `--toon` render of a real dancer mesh clears the floor. `--realistic` is a *later* option on the
  *same* asset; it also drags in the environment-restyle cost the prior spike flagged as
  load-bearing. Clear the floor first; treat realism as a separate go decision.
- **EEVEE-Next only, no Cycles headless** on this build — fine for both `--toon` and `--realistic`.
- **Keep raw/purchased meshes git-ignored** under `tools/blender/source/`; only PNGs + license
  files ship. Don't commit a paid `.fbx`/`.blend`.
- **If it goes to Fiverr:** the brief writes itself from this repo — pin `icon1024.png` (floor),
  `dancer_realistic_hero.png` (bonus target), the 8 action list + frame counts, "In Place / side
  profile / faces left," 57 pt on-screen size, and the deliverable format (rigged FBX for the 3D
  path, or a numbered PNG **sprite sheet** in the flat-icon style for the 2D path — the single most
  on-brand option if commissioning 2D).

## Not in scope
- Re-touching `render_sprites.py` `--toon`/`--realistic` (they work; this is assets only).
- The full Vainglory environment restyle (a separate, larger go decision per the prior spike).
- Any purchase without a passing 57 pt acceptance-test render and a distribution-safe license.
