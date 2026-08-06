# Conjugar Game — Asset, Animation & Architecture Research

Research companion to `prompts/game.md` (the Donkey-Kong-inspired flamenco/bull game).
This document answers Josh's three research questions, synthesizes the three existing
in-house games, and proposes a concrete architecture, asset pipeline, and music plan.

> **Status:** research + recommendation only. No game code written yet. Sources are
> listed at the bottom; codebase claims cite `file:line` in the sibling repos.

---

## 0. TL;DR — the three direct questions

1. **Is Blender the right tool?** — **Yes, as the *render/animation* stage of a
   pipeline, not the whole thing.** The winning technique is **pre-rendered 3D
   sprites**: build a 3D model → rig it → animate it → point an *orthographic* camera
   at it → render each frame to a transparent PNG → pack into a sprite sheet. Blender
   is ideal here, is fully scriptable (Python + headless CLI), has dedicated
   sprite-sheet add-ons, and Claude can drive it directly via the **blender-mcp** MCP
   (which also wires in image-to-3D generators and Sketchfab/PolyHaven).

2. **How do you animate a dancer or bull?** — **Skeletal rigging.** The "wireframe"
   Josh half-remembered is an **armature** (a bone skeleton inside the mesh); binding
   mesh to bones is **skinning / weight-painting**. You then drive the bones via
   **mocap** (recorded motion), **keyframing** (hand-authored), or **rotoscoping**
   (tracing footage — the RaceRunner way). *"Ragdoll" is a different thing:*
   physics-driven limpness, good for a bull-defeat flop, not controlled dancing.
   - **Dancer (humanoid): use [Mixamo].** Upload a humanoid mesh, it **auto-rigs** it
     (click ~10 joints) and gives ~2,500 free mocap clips — incl. walk, jump, and
     **dance** — royalty-free for commercial games, no attribution. Turns weeks of
     animation into an afternoon.
   - **Bull (quadruped): the hard asset.** No Mixamo for quadrupeds. Use Blender's
     **Rigify** quadruped meta-rig, or start from a **pre-rigged bull** (there's a CC
     "Simple Rigged Bull" on Sketchfab), then hand-key or source quadruped mocap.

3. **Can Gemini specify exact animation frames?** — **No, Josh's suspicion is
   correct** (for frame-exact cycles). First-hand testing of Nano Banana Pro: it
   **outputs no alpha channel** (flat RGB → needs a `#00FF00` chroma-key +
   post-process), **drifts the character's proportions between calls** (fatal for a
   smooth cycle), and **won't hold a uniform frame grid**. Gemini's real value is
   *concept/turnaround sheets*, *static one-frame assets* (bullfighter, capes,
   backgrounds, HUD), and *seeding the 3D pipeline* (image → image-to-3D). The
   country flags are real flags — just ship flag image assets; nothing to generate.

4. **Stack — will pure SwiftUI stay performant with frame animation?** — **Yes** (§2.2).
   Match the siblings' pure-SwiftUI engine; the game frame-animates only **~2** actors at
   once (dancer + bull), so the only real cost is image *decode*, removed by pre-decoding
   frames or drawing `context.resolve()`-cached images in a `Canvas`. The whole escalation
   ladder (ZStack → `Canvas`+`TimelineView` → `.drawingGroup()`) is pure SwiftUI — so the
   **SpriteKit/`SpriteView` fallback is dropped** (SpriteKit isn't de jure deprecated, but
   it's neglected and shipped iOS 26 framerate regressions — your "de facto" read is fair).

---

## 1. What the three in-house games teach us

### 1.1 RaceRunner (2017, SpriteKit) — the only one with real frame animation

- **Animation model:** arrays of `SKTexture` cycled by
  `SKAction.animate(with: textures, timePerFrame: 0.1)` wrapped in `repeatForever`
  — i.e. **10 fps flipbook** (`GameScene.swift:30,269`). **10 jogger frames**, **11
  horse frames**, each with **separate east/west sets** so the sprite faces its travel
  direction, plus a stationary frame (`RunnerIcons.swift:17-18`).
- **Assets:** one `.imageset` per frame in `Images.xcassets`, named
  `direction + index + avatar` (`east1Runner`, `west11Horse`, `stationaryHorse`).
  Loaded with `SKTexture(imageNamed:)`.
- **Asset provenance (corroborates the brief):** joggers were **hand-drawn** on a
  uniform 30×30 grid (@1x/@2x/@3x); horses were **traced from Muybridge's "The Horse
  in Motion"** — the tell is that each of the 11 gallop frames has a slightly
  different pixel bounding box (128×81, 128×82, 134×79…), the fingerprint of cropping
  separate photographs. The frames actually predate the minigame — they were built in
  2015 for the animated map avatar (`RunnerIcons.swift` header) and reused.
- **Physics/control:** CoreMotion tilt applies a force to the player body; collision
  is `SKPhysicsBody` + contact delegate.
- **Reusable idea:** an **ordered array of frames advanced by a per-frame index**, with
  **direction-specific arrays swapped by facing**. That concept ports to SwiftUI
  verbatim. The SpriteKit machinery (SKAction/SKTexture/physics) does not — but
  **`SpriteView` can host an `SKScene` inside SwiftUI** if we ever want it back.

### 1.2 Konjugieren & Conjuguer (2026, pure SwiftUI) — the "house architecture"

These two are **architecturally near-identical**, and they define the pattern Conjugar's
game should follow for codebase consistency:

| Concern | How both siblings do it |
|---|---|
| **State** | One `@MainActor @Observable final class GameState`, held by the view as `@State`. Entities are **value-type `Codable` structs in arrays** (`enemies: [Enemy]`, `bullets: [Bullet]`…). ~120 tuning constants as `static let` at the top. |
| **Game loop** | `GeometryReader → TimelineView(.animation) → ZStack`. The body stays a *pure* render; the tick runs in **`.onChange(of: timeline.date) { gameState.update(currentTime:) }`**. `update` computes its own **delta-time**, discards hitches (`dt` outside `(0,1)`), and clamps to a `1/30 s` floor to prevent tunneling. |
| **Update contract** | A fixed ordered pipeline: **move everything → resolve all collisions → check win/lose**, split into `update…`/`collide…` free-functions across `GameState+*.swift` extension files (one file per mechanic). |
| **Rendering** | Every entity is an ordinary `Image`/`Text`(emoji)/`Shape` pinned with **`.position(x:y:)`**. **No sprite sheets, no frame animation.** "Animation" = position updates + `.scaleEffect(x: ±1)` to mirror facing + `sin(sineTime)` for pulse/bob. |
| **Collision** | Brute-force **AABB** via one `rectsIntersect(ax,ay,aSize,bx,by,bSize)` helper over small arrays. No spatial partitioning. |
| **Launch** | From the **Settings tab** as `.fullScreenCover(isPresented: $showingGame) { GameView() }`, gated by a button with a TipKit tip + a `tapPlayGame` analytics signal. |
| **Difficulty** | Konjugieren: discrete **waves** (`enemySpeed = 21 · 1.02^(wave-1)`). Conjuguer: **emergent** (endless spawns + rotating "special mechanics"). |
| **Mechanics docs** | Both document mechanics in a localized Info string — Konjugieren `Info.gameText`, Conjuguer `Info.gameInstructionsText`. (Correction to the brief: Conjuguer's mechanics *are* documented, just under a different key.) |

**Controls diverge — and Conjuguer's is the one we want.**
- Konjugieren = **tilt** (`CMMotionManager`, reads `gravity.x`, dead-zone + sensitivity·dt).
- Conjuguer = **on-screen buttons** in the bottom-left. This is the pattern for
  Conjugar. The idiom (`GameView.swift:400-423`, `GameState.swift:463-481`):
  - Each button is an SF-Symbol `Image` in a **64×64 frame** with
    `.contentShape(Rectangle())` (whole square tappable), driven by a
    **`DragGesture(minimumDistance: 0)`** used as press-and-hold:
    `.onChanged { setPressed(true) }` / `.onEnded { setPressed(false) }`. (A
    `Button` only fires on tap-*up* and gives no held state — hence the gesture.)
  - The gesture only flips **intent booleans** (`movingLeft`/`movingRight`) on the
    `@Observable` state. The **game loop reads them each frame** and integrates
    `playerX ± speed·dt`. Decoupling *gesture-sets-intent / loop-consumes-intent* is
    the key idiom, and it generalizes cleanly to Conjugar's **4 directions + jump +
    cape** by adding one boolean and one button each.
  - Conjuguer only needs 2 buttons / 1 axis (its ship rides a fixed bottom row), so
    Conjugar is the first sibling to need **vertical movement, ladders, and a jump** —
    see §2.3.

---

## 2. Recommended game architecture for Conjugar

### 2.1 Verdict: stay pure-SwiftUI (match the siblings), and add frame animation on top

Adopt the Konjugieren/Conjuguer house architecture wholesale — `@Observable GameState`,
`TimelineView(.animation)` loop, value-type structs, AABB, `GameState+*.swift` per
mechanic, `.fullScreenCover` from Settings, Conjuguer's press-and-hold buttons. It's
proven across two shipped apps, consistent with Conjugar's SwiftUI-first codebase, and
fully testable in Swift Testing.

**The one thing the siblings lack — frame animation — is the whole point of this game,
and it drops into their render model trivially.** A frame-animated sprite is just an
`Image` whose *name* changes each tick:

```swift
// In GameState (per animated actor): an animation phase advanced by dt.
var dancerPhase: Double = 0          // seconds into the current cycle
enum DancerAction { case idle, walk, climb, jump, cape, victory, hurt }
var dancerAction: DancerAction = .idle
var dancerFacing: CGFloat = 1        // +1 right, -1 left

// In update(dt:):
dancerPhase += dt

// In the ZStack (GameView):
let frames = dancerFrames[gameState.dancerAction]          // ["dancer_walk_0", ...]
let i = Int(gameState.dancerPhase * fps) % frames.count    // fps ≈ 10, RaceRunner-style
Image(frames[i])
  .resizable().interpolation(.none)                        // crisp pixels if pixel-art
  .frame(width: 48, height: 64)
  .scaleEffect(x: gameState.dancerFacing, y: 1)            // mirror to face travel dir
  .position(x: gameState.dancerX, y: gameState.dancerY)
```

This is RaceRunner's `[SKTexture]`-cycled-by-index idea, re-expressed in the sibling
ZStack: the "current texture" is `frames[i]`, and facing is the siblings'
`scaleEffect(x: ±1)` mirror. No SpriteKit needed. Frames live in `Assets.xcassets`
(imageset per frame, RaceRunner naming) or a **Sprite Atlas** folder for packing.
**Pre-decode the frames once at load, not per frame** — that's the whole performance
trick, and §2.2 explains why it keeps pure SwiftUI fast.

### 2.2 Will pure SwiftUI stay performant with frame animation? (Yes)

This is exactly the right question to ask, because the siblings never stress it. Short
answer: **yes, comfortably** for a game of this shape — and the escalation path, if it
ever tightens, is *also* pure SwiftUI, so SpriteKit never needs to enter the picture.

**Why the workload is tiny.** At any instant this game frame-animates only **~2** actors —
the dancer and the bull. Everything else is static or transform-animated: the bullfighter
is one frame; the flag "barrels" tumble as a rotated *static* image (exactly how Conjuguer
spins its emoji projectiles); capes, platforms, ladders, and HUD don't animate. The
siblings already re-evaluate a `ZStack` of *dozens* of positioned entities every display
refresh in pure SwiftUI with no trouble — adding frame animation just means ~2 of those
leaves swap their image each tick. That is not a rendering challenge.

**The one real cost is image *decode*, not the swapping.** If you point
`Image("dancer_walk_3")` at a fresh asset every frame and let the system decode on demand,
you can get decode churn/hitches. Two standard fixes, either one sufficient:
- **Pre-decode once at load.** Warm every frame into a decoded `UIImage`/`CGImage` at game
  start (Conjuguer already does this for emoji via `GlyphWarmer`) and render
  `Image(uiImage:)`. Cycling the same ~8 cached frames then costs essentially nothing;
  asset-catalog images are also cached by the system after first decode.
- **`Canvas` + `context.resolve()`.** Resolve each frame image once into a
  `GraphicsContext.ResolvedImage` and draw the *resolved* image each tick — the documented
  technique to "avoid re-rendering static content over and over every frame." No per-frame
  decode.

**Two pure-SwiftUI rendering strategies, with a decision rule:**
1. **ZStack of positioned `Image`s — the default.** Matches the siblings exactly, most
   readable (which you value), and more than adequate for ~2 animated + ~20 static sprites.
   **Start here.**
2. **`TimelineView(.animation)` + `Canvas` — the escalation.** Immediate-mode GPU drawing
   that collapses many sprites into few draw calls; the proven pure-SwiftUI game-loop
   pattern (tick `Canvas` from `TimelineView`, draw `context.resolve()`-cached frames).
   Konjugieren already uses `Canvas` for its particle field, so there's in-house precedent.
   Move rendering here only if profiling shows the ZStack hitching. The headroom is huge:
   the OctopusKit engine draws **5,000+ sprites at 60 fps on an iPhone XS** (a 2018 phone)
   in pure Swift — orders of magnitude beyond this game.
   - `.drawingGroup()` (Metal-flatten a heavy subtree) is a further lever, but apply it
     **reactively to a measured hitch, not preemptively** — misapplied, it can *slow* a view.

**Frame-budget sanity check:** 60 Hz gives 16.6 ms/frame; 120 Hz ProMotion gives 8.3 ms
(~5 ms usable after system overhead). Advancing a few dozen struct positions + AABB +
blitting ~2 cached images is microseconds of that. `TimelineView(.animation)` already
targets the display refresh, and drives 120 fps on ProMotion for free.

**On SpriteKit (your deprecation point — you're right in spirit).** It isn't *formally*
deprecated: at WWDC 2025 Apple soft-deprecated **SceneKit** ("critical-bug-only"
maintenance → migrate to RealityKit) but did **not** name SpriteKit. Practically, though,
SpriteKit "hasn't seen a major update in ages," and — tellingly — it shipped **framerate-drop
regressions on iOS 26** that needed beta hotfixes. Betting a *new* game on a neglected
framework that's *currently regressing on the shipping OS* is precisely the risk you're
sensing. Since pure SwiftUI (ZStack → `Canvas` → `.drawingGroup()`) covers every performance
tier this game could plausibly need, **this recommendation drops the earlier
SpriteKit/`SpriteView` fallback entirely.** RaceRunner stays a *conceptual* reference (the
flipbook idea), never a runtime dependency.

### 2.3 Donkey-Kong specifics the siblings don't cover

New systems to build (none are hard in the dt-integration model):

- **Platforms & gravity.** Player has `velocityY`; apply gravity each tick; when
  falling onto a platform's top edge (AABB against thin platform rects), snap and zero
  `velocityY`. Horizontal buttons set `velocityX` intent as in Conjuguer.
- **Ladders.** When the player's x overlaps a ladder rect and Up/Down is held, enter a
  `climbing` state that disables gravity and moves `playerY ± climbSpeed·dt`; play the
  **climb** animation. Leave climbing at the ladder's ends or on a horizontal press.
- **Jump.** The jump button is an **impulse**, not a held intent: on press set
  `velocityY = -jumpImpulse` (only if grounded). It's the one control that's tap, not
  press-and-hold — a plain closure on touch-down is fine.
- **Flags = "barrels".** Spawn from the bull, descend platform-to-platform under
  gravity, roll along each platform, drop at platform ends. These are the siblings'
  moving projectiles — **transform-based, no frames needed** (rotate/tumble a static
  flag image as it moves, exactly how Conjuguer tumbles emoji projectiles). Each flag
  that touches the player costs **25% health** (brief matches the siblings' 25%/hit).
- **Capes = "hammer" power-up.** A pickup on a platform; while active, the player's
  **cape animation** plays and flag-collision destroys the flag instead of damaging.
- **Five-ascent structure + boss.** Reaching the bull 4× → bull escapes up a level with
  the bullfighter (advance the "level"/layout). 5th → the **final bullfight scene**
  (its own mini-state); win → rescue → victory dance.

### 2.4 File layout (mirrors the siblings)

```
Conjugar/Models/Game/
  GameState.swift                 // @Observable core: state, constants, update(), lifecycle
  GameModels.swift                // Player, Flag, Cape, Platform, Ladder, Bull, Bullfighter structs
  GameState+Physics.swift         // gravity, platform snap, ladder climb, jump
  GameState+Flags.swift           // bull throws flags; flag descent/rolling
  GameState+Bull.swift            // bull walk/climb/throw AI; escape; final fight
  GameState+Animation.swift       // per-actor frame tables + phase advance helpers
  GameState+Collisions.swift      // AABB dispatcher (rectsIntersect)
Conjugar/Views/
  GameView.swift                  // TimelineView loop, ZStack render, 4-dir+jump+cape buttons, HUD
Conjugar/Assets.xcassets/Game/    // sprite frames (imagesets or Sprite Atlas) + stills
```

Launch: add a "Game" card to `SettingsView` (`.fullScreenCover { GameView() }`), matching
both siblings. Persist a high score via `Settings`/`GetterSetter`. Document mechanics in a
new localized `Info.gameText`-style string (Info tab), per house convention.

---

## 3. The asset-generation & animation pipeline (core research)

### 3.1 The big idea: pre-rendered 3D sprites

Model once in 3D, animate with a rig, then render orthographic frames to 2D. This is how
Donkey Kong Country and early Diablo got fluid 2D animation. It gives smooth motion, easy
re-renders (change palette/angle and re-render, no redrawing), and consistent proportions
across frames — the exact thing Gemini *can't* guarantee.

### 3.2 Concepts, disambiguated (answering "ragdolls or wireframes?")

- **Armature / rig / skeleton** — the bones inside the mesh. *This is the "wireframe."*
- **Skinning / weight-painting** — binding mesh vertices to bones so the mesh deforms.
- **Keyframing** — hand-authoring poses at keyframes; software interpolates between.
- **Mocap (motion capture)** — recorded real motion applied to the rig (Mixamo = free
  mocap library).
- **Rotoscoping** — tracing real footage frame-by-frame (RaceRunner's horses). The 2026
  twist: "video-to-sprite" AI tools automate this.
- **Ragdoll** — *physics* simulation of a limp jointed body. **Not** for authored dance;
  possibly a fun bull-defeat flop effect.

For Conjugar: **rig + mocap** for the dancer (Mixamo), **rig + keyframe/mocap** for the
bull, then **render to sprites** for both.

### 3.3 Pipeline A — the flamenco dancer (humanoid, the easy one)

1. **Concept.** Gemini/Nano Banana Pro: a flamenco-dancer character sheet in Conjugar's
   red+gold palette (front/side/action). Use its multi-shot character-reference to lock
   the design. This is *reference*, not final frames.
2. **Mesh.** Either (a) **image-to-3D** from the concept (Meshy or Tripo — both include
   auto-rigging; Rodin/Hunyuan3D for higher-fidelity mesh then rig separately), or (b)
   start from a free base humanoid (e.g. MakeHuman/Blender) and style it.
3. **Rig + animate — [Mixamo].** Upload the humanoid FBX/OBJ → auto-rig (click ~10
   joints) → apply mocap clips: **idle, walk, jump, ladder-climb** (there are
   climbing clips), plus a **flamenco/dance** clip for the victory and a **hit
   reaction** for damage. Export **FBX per action**, choosing frame rate and
   "frame reduction." Mixamo is **royalty-free for commercial games, no attribution**;
   only restriction is you can't resell the raw assets standalone (shipping inside the
   app is fine).
4. **Render — Blender.** Import FBX. Orthographic **side-view** camera (platformers are
   side-on). Flat/toon shading in the Conjugar palette. Transparent film (RGBA). Render
   each action's frames to PNG (see §3.6). ~8 frames per walk cycle at 10–12 fps reads
   as smooth (RaceRunner used 10).
5. **Pack + slice.** A Blender sprite-sheet add-on, or ImageMagick `montage`, or export
   loose per-frame PNGs straight into `Assets.xcassets`.
6. **Facing.** Render one direction; mirror in SwiftUI with `scaleEffect(x: -1)` (sibling
   idiom) — half the frames. (RaceRunner rendered both; mirroring is cheaper.)

### 3.4 Pipeline B — the bull (quadruped, the cost center)

No Mixamo shortcut for four-legged animals. Options, cheapest-effort first:

1. **Pre-rigged bull.** Grab a CC-licensed rigged bull (e.g. Sketchfab "Simple Rigged
   Bull," which itself uses Blender's Rigify basic-quadruped). If it ships with a walk
   cycle, you're most of the way there; add **climb**, **throw-flag**, and
   **final-fight** actions by keyframing.
2. **Rigify quadruped meta-rig.** Rig a bull mesh (generated via Hunyuan3D/Meshy or
   sourced) with Blender's built-in Rigify quadruped rig, then keyframe cycles. More
   control, more work.
3. **Quadruped mocap pack.** Scarcer/often paid; only if hand-keying proves too slow.

The bull needs fewer distinct animations than the dancer (idle/paw, walk, climb, throw,
defeat) but each is hand-authored, so **budget the most time here.** Consider stylizing
the bull to reduce animation fidelity needs (a chunkier, cartoonier bull hides
imperfect motion — and fits the palette-forward art direction).

### 3.5 Where Gemini fits — and where it fails

**Fails (do not use for):** frame-exact animation cycles. Documented first-hand: no
alpha channel (flat RGB), proportion drift between generation calls, non-uniform grids.

**Excellent for (use it here):**
- **Concept art & turnaround sheets** to seed the 3D models (Nano Banana Pro's
  character-reference consistency is genuinely strong for a single locked character).
- **Static one-frame assets:** the **bullfighter** (brief says one frame is enough),
  **capes**, platform/ladder tiles, the background (an arena/plaza), HUD, title art.
- **Seeding image-to-3D** (Gemini image → Meshy/Tripo/Rodin/Hunyuan3D).

**Practical Gemini gotcha:** it can't do transparency. Generate on a flat
**`#00FF00`** background and chroma-key it out (HSV-based, plus a thin white outline the
key can find), or hand-cut in an editor. There's a `remove-watermark` skill and a
`gemini-image` skill available in this session, so I can generate stills directly when we
get there.

**Don't generate the flags at all** — flags of Spanish-speaking countries are real,
standardized images; ship them as assets (or draw simple vector versions). ~20 countries
gives natural visual variety for the "barrels."

**Dedicated AI sprite tools** (Spritesheets.ai, Musely, SpriteFlow, AutoSprite, Scenario)
exist and some are *video-to-grid* — which pairs with the RaceRunner rotoscoping
heritage (film/find flamenco footage → sprite sheet). Consistency for a specific branded
character is still shaky, so treat them as **prototyping / fallback**, not the main path.

### 3.6 Blender: role, automation, and concrete settings

Blender is the render hub, and it's **highly automatable**, which matters because Claude
can help operate it:

- **blender-mcp** (ahujasid) lets Claude run arbitrary Python in Blender, set
  cameras/lighting, render, **and** it integrates **Hunyuan3D** + **Hyper3D Rodin**
  (image/text-to-3D) and **Sketchfab/PolyHaven** downloads — i.e. much of the pipeline
  can be driven from here. Setup: install its `addon.py`, add the MCP server to the
  Claude config, "Connect to Claude" in Blender's sidebar. Requires Blender 3.0+,
  Python 3.10+, `uv`. (Caveat: it executes arbitrary Python — save first.)
- **Headless CLI** for batch renders: `blender -b scene.blend -P render_frames.py` (or
  `-a` to render the animation range). Good for re-rendering all actions after a palette
  tweak.
- **Sprite-sheet add-ons:** "Sprite Sheet Generator" / "Sprite Sheet Maker" (Blender
  Extensions) and chrishayesmu's "Blender-Spritesheet-Renderer" automate multi-angle,
  multi-action packing.

**Concrete render recipe** (from the Blender→ImageMagick workflow):
- Camera: **Orthographic**, side view; set orthographic *scale* so the whole animation
  fits (check every frame's extremes — a jump peaks higher).
- Render Properties → Film → **Transparent** ON. Output: **PNG, RGBA**.
- Lighting: a Sun + a flat/toon material (Diffuse BSDF + ColorRamp) for a clean,
  palette-controlled look; optional Solidify-modifier outline for a drawn feel.
- Render all frames: `Ctrl+F12` (or headless `-a`) to a clean per-action folder.
- Pack: `magick montage *.png -geometry 128x128 -tile 8x8 -background transparent
  -filter Catrom spritesheet.png` (tile grid sized to frame count).
- Or skip packing: drop loose per-frame PNGs into `Assets.xcassets` as imagesets named
  `dancer_walk_0…7` and cycle by index (§2.1).

### 3.7 Integration back into Xcode

- **Loose imagesets** (RaceRunner style): simplest; `Image("dancer_walk_0")` +
  index. Use `.interpolation(.none)` for crisp pixel-art scaling.
- **Sprite Atlas** folder in `Assets.xcassets`: Xcode packs frames into a texture atlas
  for better memory/perf if frame counts get large.
- Provide @2x/@3x (iPhone 17 is 3×). Render at 3× target size and downscale, or render
  three sizes.
- Warm first-use glyph/image cost like Conjuguer's `GlyphWarmer` if you see a first-draw
  hitch.

---

## 4. Music & sound effects

### 4.1 Music (background) — permissive flamenco

**Decided (Josh): CC-BY is acceptable.** So the bar is **CC-BY or more permissive**, and we
lead with a *composed* flamenco piece rather than CC0 loops. The only obligation this adds is
a **Credits screen** (below); in exchange we get the fuller, more musical options.

- **Primary pick — a CC-BY flamenco track:** **casimps1 "Vaguely Spanish Guitar" (CC-BY 3.0,
  ccMixter)** or **BFCMUSIC "Luna de Fuego" (CC-BY 4.0, FMA)**. Loop-edit an internal 8–16-bar
  section in Audacity (zero-crossing cut + tail crossfade). I'll verify the live license page
  and audition the loop when we build audio.
- **No-credit alternatives, still available** if you'd rather skip attribution for the *music*
  specifically: **Pixabay** flamenco (its own license — commercial OK, no credit, biggest
  catalog, but verify per-track provenance) or the **CC0 Signature Sounds "Spanish Guitar
  Loops"** pack (loop-ready).

**Licensing recap for an App Store + AGPL app:** CC0 and CC-BY are both safe and
AGPL-compatible (code and audio are *aggregated*, not merged — CC-BY never reaches into your
Swift). **Avoid CC-BY-NC** (an App Store release reads as commercial), **CC-BY-SA** unless
you'll release your loop-edit under it, YouTube Audio Library *standard* tracks (YouTube-only),
and Uppbeat's free tier (needs a paid plan).

**The one thing CC-BY requires — a Credits screen.** Add a **Credits / Acknowledgements** row
(Info or Settings tab) listing a **TASL** line per CC-BY asset — *Title, Author, Source-link,
License-link* (e.g. *"'Vaguely Spanish Guitar' by casimps1 (ccMixter), CC BY 3.0 — trimmed &
looped"*). Keep an **`asset-licenses/`** folder in the repo with each asset's license deed +
source URL. Because CC-BY is now the **project-wide** asset bar (not just music), this same
screen + folder also covers CC-BY **3D models** (e.g. a pre-rigged Sketchfab bull — verify its
per-model license) and CC-BY **sound effects** — which usefully widens the asset pool.

### 4.2 Sound effects — reuse + Pixabay (Josh's steer)

Two sources, in order:

1. **Reuse from the existing apps/games.** RaceRunner, Konjugieren, and Conjuguer already
   ship broad SFX libraries — pops, hits, buzzes, applause, a sad-trombone game-over, and
   animal sounds (RaceRunner's scream/neigh; Conjuguer's cluck/egg-crack/chomp) — played
   through a **`Current.soundPlayer`** DI seam (`Models/Sound.swift` + `Utils/SoundPlayer*.swift`
   in the siblings). Conjugar's game should adopt the same seam, and many existing cues map
   straight onto this game: flag-hit thud, cape-smash, jump, climb, level-up sting, applause
   on rescue, sad-trombone on death.
2. **Pixabay** (`pixabay.com`) sound-effects search for anything the siblings don't have —
   bull snort/bellow, flamenco *olé*/hand-claps, castanets, crowd murmur, cape *whoosh*.
   Pixabay SFX carry the **same Pixabay Content License** as its music: **commercial use
   OK, no attribution required**, only "don't redistribute the raw file standalone" (which
   embedding in the app satisfies). Big catalog, low friction.

Reuse first, fill gaps from Pixabay (and, now that CC-BY is fine, CC-BY sounds from
Freesound/ccMixter — credit them on the same Credits screen). Log every grab (download the
per-asset license certificate) into the shared `asset-licenses/` paper trail.

---

## 5. Color palette & art direction

Conjugar's actual asset-catalog colors (light / dark), to drive every game asset:

| Token | Light | Dark | Use in game |
|---|---|---|---|
| `customRed` | `#C1001D` | `#C1001D` | **The signature.** Matador cape, bull accents, danger/health-low, flag red. |
| `customYellow` (gold) | `#8A6600` | `#CDA51B` | **The signature #2.** Spanish gold — capes, sand/arena, UI accents, coins. |
| `customBlue` | `#1E56E0` | `#5587FF` | Sky, cool accents, some flags. |
| `customGreen` | `#1E7A36` | `#30D158` | Foliage, some flags, "safe"/health-high. |
| `customBackground` | white | black | Base background. |
| `customForeground` | black | white | Text/line art. |

**The theme is a gift:** a bull + flamenco + matador-cape + Spanish-flag game maps almost
one-to-one onto Conjugar's existing **red (#C1001D) + gold (#CDA51B)**. Art-direct the
whole game around red/gold with the arena sand in gold and the danger elements in red;
it will feel native to the app. Render the 3D assets with a flat/toon shader tuned to
these hex values so sprites and UI share one palette (and stay light/dark correct — mind
that background/foreground invert between modes).

---

## 6. Recommended phased plan

1. **Prototype the shell (pure SwiftUI, no art).** `GameState` + `TimelineView` loop +
   platforms/ladders/gravity/jump + 4-dir+jump+cape buttons (Conjuguer idiom) + flag
   "barrels" as colored rects + AABB + health + Settings launch. Prove the Donkey-Kong
   feel with placeholder shapes. *(Cheapest way to de-risk the game design.)*
2. **Stand up the asset pipeline on ONE action.** Dancer **walk cycle** end-to-end:
   Gemini concept → image-to-3D → Mixamo walk → Blender orthographic render → imagesets
   → cycle in the ZStack. This validates the whole toolchain before investing in all
   actions. Set up blender-mcp so Claude can help.
3. **Fill out the dancer** (idle, climb, jump, cape, victory, hurt) via Mixamo + Blender.
4. **Tackle the bull** (the cost center): source/rig, then walk/climb/throw/defeat.
5. **Stills via Gemini:** bullfighter (1 frame), capes, background, HUD, title.
6. **Flags:** drop in real country-flag assets.
7. **Music & SFX:** Path A (CC0) music to start; wire a `Current.soundPlayer` seam and
   reuse sibling sound effects, filling gaps from Pixabay; add `music-licenses/`.
8. **Polish:** the 5-ascent structure, final bullfight scene, score, Info-tab mechanics
   text, TipKit discovery, haptics/SFX (sibling patterns).

Each phase is independently shippable-to-`migration`-branch and blog-note-worthy.

---

## 7. Open decisions for Josh

- **Architecture:** **settled — pure SwiftUI** (SpriteKit/`SpriteView` fallback dropped;
  see §2.2). Only sub-choice: render in the sibling **ZStack** model first (recommended,
  most readable) and escalate to `Canvas`+`TimelineView` only if profiling demands — or
  build on `Canvas` from day one if you'd prefer the more scalable renderer up front.
- **Dancer mesh origin:** AI image-to-3D from a Gemini concept, vs a hand-built/base
  humanoid. (Image-to-3D is faster; hand-built is more controllable.)
- **Bull fidelity/style:** realistic vs chunky-cartoon (cartoon hides animation
  imperfection and suits the palette-forward look — recommended).
- **Do you have Blender installed**, and do you want me to set up **blender-mcp** so I can
  drive the render step directly?
- **Music:** **decided — CC-BY** (which also becomes the project-wide asset bar; adds a
  Credits screen + `asset-licenses/` folder). Remaining sub-pick is *which* track — I'll
  audition **casimps1 "Vaguely Spanish Guitar"** vs **BFCMUSIC "Luna de Fuego"** when we
  build audio.
- **Frame rate/counts:** start at RaceRunner's 10 fps / ~8-frame cycles unless you want
  smoother.

---

## Sources

**In-house codebases** (explored July 2026): `RaceRunner/RaceRunner/GameScene.swift`,
`RunnerIcons.swift`, `Images.xcassets`; `Konjugieren/Konjugieren/Models/Game/*` +
`Views/GameView.swift`; `Conjuguer/Conjuguer/Models/Game/*` + `Views/GameView.swift`.
Conjugar palette: `Conjugar/Assets.xcassets/custom{Red,Yellow,Blue,Green,Background,Foreground}.colorset`.

**Web research:**
- Blender→sprite-sheet: [Blender Sprite Sheet Generator add-on](https://extensions.blender.org/add-ons/sprite-sheet-generator/), [Blender-Spritesheet-Renderer](https://github.com/chrishayesmu/Blender-Spritesheet-Renderer), [CoderNunk Blender+ImageMagick tutorial](https://codernunk.com/tutorials/sprite-sheet-from-3d/)
- Blender automation: [blender-mcp (ahujasid)](https://github.com/ahujasid/blender-mcp)
- Mixamo: [rigging/animation docs](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html), [license FAQ](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)
- Image-to-3D 2026: [best-of comparison](https://www.buildmvpfast.com/articles/best-llms-2026-guide/3d-modeling-ai), [Meshy game-asset guide](https://www.meshy.ai/blog/best-ai-tools-for-3d-game-assets)
- Gemini/Nano Banana for sprites (first-hand): [Robotic Ape lessons learned](https://roboticape.com/2026/03/07/generating-game-sprites-with-gemini-image-generation-nano-banana-pro-lessons-learned/), [Nano Banana Pro character sheets](https://selfielab.me/blog/nano-banana-pro-consistent-character-sheets-guide-20260216)
- AI sprite generators: [Spritesheets.ai](https://www.spritesheets.ai/), [Musely](https://musely.ai/tools/sprite-sheet-generator)
- Quadruped/bull: [Rigify manual](https://docs.blender.org/manual/en/2.81/addons/rigging/rigify.html), [Sketchfab "Simple Rigged Bull"](https://sketchfab.com/3d-models/simple-rigged-bull-c1984e43c4014dc5bc332a8fd6b15280)
- SwiftUI runtime: [SpriteView docs](https://developer.apple.com/documentation/spritekit/spriteview), [Hacking with Swift: integrate SpriteKit via SpriteView](https://www.hackingwithswift.com/quick-start/swiftui/how-to-integrate-spritekit-using-spriteview)
- Music sources: [Signature Sounds CC0 Spanish Guitar Loops](https://signaturesounds.org/store/p/free-download-spanish-guitar-loops-cc0), [ccMixter](https://ccmixter.org/), [FMA flamenco](https://freemusicarchive.org/genre/flamenco), [Pixabay flamenco](https://pixabay.com/music/search/flamenco/), [CC ShareAlike interpretation](https://wiki.creativecommons.org/wiki/ShareAlike_interpretation)

[Mixamo]: https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html
