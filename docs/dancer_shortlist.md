# Phase 1 — Marketplace dancer shortlist (2026-07-12)

Spike ref: `prompts/game_paid_dancer_bull_spike.md`. Phase 0 (bull) is **done** for $0.
This is the Phase 1 deliverable: the marketplace shortlist for the **dancer** mesh that
must clear the app-icon floor (female + flamenco dress + dynamic pose, read at 57 pt).

Browsed via Claude-in-Chrome across **CGTrader, TurboSquid, Sketchfab, and Fab (Epic)**
(Josh authenticated). Josh makes the final purchase and drops the file in
`tools/blender/source/` (git-ignored).

---

> **Decision (2026-07-12):** Phase 2 paid-AI **skipped** per Josh (free-trial pull failed on
> topology, same as the prior spike). Proceeding with **Candidate A** → Josh buys → Phase 3
> (Mixamo rig → 57 pt `--toon` acceptance test → animate → wire into `GameView`).

## TL;DR / recommendation

**Buy the Animod "Flamenco Dancer" on CGTrader for $6.99 (Candidate A).** It is the *only*
game-usable flamenco-dancer character mesh on any marketplace, it's a near-perfect match to
the app icon (woman, tiered red ruffled dress, hair in a bun with a flower, cream skin, clean
A-pose), it's textured FBX with real topology, and its license (Royalty-Free, no-AI) allows
embedding in a distributed app. It is **not pre-rigged**, so Phase 3 runs it through Mixamo
auto-rig — the floor-length tiered skirt is the one rigging risk to watch. At $6.99 the buy is
below the cost of *testing* riggability any other way; the idle 57 pt acceptance render doesn't
even need the rig (the model already ships in ~A-pose).

Everything else on the market is a 3D-print STL figurine, a dress-only asset, a statue/decor
piece, a mocap **animation** pack (no mesh), or an age-restricted/adult "dancer." **No
pre-rigged flamenco or Spanish female dancer in a dress exists** — exactly the scarcity the
spike predicted.

---

## Candidate A — Animod "Flamenco Dancer"  ⭐ RECOMMENDED

| | |
|---|---|
| **Look** | Woman in a tiered **red ruffled flamenco dress**, dark hair in a bun with a red flower, cream skin. Clean **A-pose**. Reads unmistakably as the icon's dancer. |
| **Rig** | **Not rigged** (no rig/animation feature listed). Needs **Mixamo auto-rig** in Phase 3. Single upright humanoid in A-pose = a good Mixamo candidate; the wide floor-length **tiered skirt** is the deform risk (Mixamo weights it to the legs). |
| **Topology / poly** | Polygon mesh, **21,049 faces / 13,299 verts**. UV-mapped, baked texture. Dimensions ~167 cm tall (real-world scale). |
| **Formats** | **FBX** (embedded, standard material, baked texture) + **MAX** (2016+, V-Ray) + zipped textures. FBX is the one we use. |
| **License** | **Royalty Free License (no AI)** — permits use/embedding in games & apps (distribution as part of the product; may not be resold as a standalone 3D asset). App-embedding **allowed**. Log in `asset-licenses/` on purchase. |
| **Price** | **CGTrader $6.99** (Weekend Sale, −30% from $9.99) · TurboSquid $9.99 · also on Sketchfab store. **Buy on CGTrader.** |
| **Seller** | aaanimod / Animod ("professional model production team … for game development and animation"), 38 reviews. |
| **Link** | https://www.cgtrader.com/3d-models/character/woman/flamenco-dancer-c7f4bf5a-7c34-4b81-8242-d5d99ab08413 |

**Why it wins:** it's the single asset that satisfies the icon *read* (dress + female form +
pose) in a game-usable format at a trivial price. The prior spike already established that the
render pipeline is fine and the mannequin mesh was the whole problem — this mesh fixes exactly
that.

---

## Candidate B — "Bustier Ruffled Flamenco Spanish Skirt Dress" (dress-only; fallback path)

A **wearable flamenco dress** (ruffled tiered skirt + bustier), **no body**. Use only if
Candidate A's skirt won't Mixamo-rig acceptably: fit this dress onto a clean **rigged base
female**, then rig/skin the combined mesh (more assembly work than Candidate A).

| | |
|---|---|
| **Rig** | Dress mesh only, not rigged. Would be skinned to a base-female rig. |
| **Topology / poly** | Low-poly, **17,489 polys**, all quads/tris, clean non-overlapping UVs, CGTrader-verified FBX. |
| **Formats** | **FBX + OBJ** + PBR textures (Diffuse/Normal/Specular/AO/UV). |
| **License** | Royalty Free (no AI). Seller terms **explicitly allow derivative retexture/reshape** (so recoloring green → the game's gold+red is fine) as long as it doesn't resemble the original. |
| **Price** | **CGTrader $5.00** (−50% from $10). |
| **Link** | https://www.cgtrader.com/3d-models/character/clothing/bustier-ruffled-flamenco-spanish-skirt-dress |

**Caveat:** stock colorway is green — would need retexture to gold+red anyway, and it needs a
separately-sourced rigged base female. Net: more work than Candidate A for a similar end state.
Documented as the "dress + rigged base" fallback, not a first choice.

---

## Candidate C (path, not a specific buy) — rigged base female + retexture

The spike's fallback (c): buy a **pre-rigged** female character in *any* dress and retexture to
gold+red, to skip Mixamo entirely. **Not recommended** — the pre-rigged pool for
"spanish/female dancer" is **ballerinas (tutu) and cheerleaders**: wrong costume; a tutu/cheer
skirt won't read as a flamenco gown at 57 pt even retextured. So the rig-de-risk this path
promises comes with a costume that fails the icon read. Prefer Mixamo-rigging Candidate A; if
the skirt fails, go to Candidate B or Fiverr.

> **Note on the CGTrader "adult content" gate (checked, 2026-07-12).** Some rigged
> "female dancer" listings (e.g. "RIGGED Ballerina," a genuinely clean, fully-clothed,
> well-rigged pink-leotard ballerina) sit behind an **18+ confirmation**. On inspection this
> is **not** erotic content — these models are built on **Adobe Fuse** base figures (an
> anatomically-complete nude body under separately-modelled garments), and the seller's
> preview set includes a nude/underwear **base-body topology render**, which CGTrader
> auto-flags. It's marketplace conservatism about the base mesh, not an erotic dance. So the
> 18+ gate is **not** itself a disqualifier — the costume (tutu ≠ flamenco gown) is.

---

## Phase 2 note — paid-AI lottery (free-trial pull, 2026-07-12)

Fired one Rodin image-to-3D pull on `dancer_concept_front.png` (free-trial key; `bbox`
hint `[1,2,5]` to bias upright). **Failed the riggability bar the same way the prior spike
did:** head-on it reads as a gold-gown dancer (textures much improved), but the side profile
shows a **detached lower body, a needle-spike artifact, and floating bits** — non-manifold,
fragmented, limbs unattached → would not Mixamo-rig. Two independent AI-gen attempts on a
ruffled-dress figure have now both died on topology. Paid tiers buy better textures on the
same broken mesh, so the lottery's expected value is low. **Prefer Candidate A + Mixamo.** If
Josh still wants the paid shot, it needs him to auth Meshy.ai/Tripo3D in Chrome or paste a paid
Rodin key (I can't create accounts or pay).

## What was searched (coverage)

- **CGTrader:** `flamenco dancer`, `spanish dancer` (+Rigged filter), `flamenco dress`.
- **TurboSquid:** `flamenco dancer` (4 results total; +rigged = 0). The one good one is the
  **same Animod model** at $9.99.
- **Sketchfab (downloadable):** `flamenco dancer` — same Animod model + statues/sketches/a
  genderless rumba mocap mannequin.
- **Fab (Epic):** `flamenco dancer` — all **mocap animation packs**, no character mesh.

**Market reality:** flamenco-specific = one model (Animod), everywhere. STL figurines, dresses,
statues, animation packs, and adult "dancer" models fill the rest. This matches the spike's
prediction ("a flamenco-specific rigged model is rare").

---

## Next step for Josh

1. Buy **Candidate A** on CGTrader ($6.99): https://www.cgtrader.com/3d-models/character/woman/flamenco-dancer-c7f4bf5a-7c34-4b81-8242-d5d99ab08413
   (I can't enter payment on your behalf — the buy click is yours.)
2. Drop the downloaded FBX + textures into `tools/blender/source/` (git-ignored).
3. Then Phase 3: Mixamo auto-rig → run the **57 pt `--toon` idle acceptance test** against
   `icon1024.png` → if it clears, animate the 8 actions and wire into `GameView`.

If you'd rather I also spend the cheap **Phase 2 paid-AI lottery** ticket (feed
`dancer_concept_front.png` to Meshy/Tripo/Rodin-Pro) in parallel, say so — but Candidate A is
the reliable path and I'd rig it first.
