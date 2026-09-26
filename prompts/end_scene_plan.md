# End-scene slideshow plan: two portraits and an iris wipe

Expands `prompts/end_scene.md` (Josh's brief) into an implementation plan. Decisions below were
settled with Josh on 2026-09-26; the reasoning for each is recorded so a fresh session can act
on it without re-asking.

## How to use this plan

The work runs in **two phases, each in its own fresh session**:

- **Phase 1: the images.** Generate candidates with both gemini-image and gpt-image, have Josh
  pick, and add the two winners to the asset catalog. Start it with "Run Phase 1 of
  prompts/end_scene_plan.md."
- **Phase 2: the game.** Build the slideshow, iris wipe, drag, toast, and caption around those
  images. Start it with "Run Phase 2 of prompts/end_scene_plan.md."

Both phases read the Goal and Decisions sections. Each phase then has its own section with
everything it needs. A session should not start work from the other phase.

At the end of a phase, the session updates the **Status** section below with what it produced,
so the next session starts from facts, not assumptions.

## Status

| Phase | State | Handoff notes |
|---|---|---|
| 1. Images | **Done** (2026-09-26) | **Los toreros:** `toreros-gpt-1.png` (gpt-image API, attempt 1, 3520x2336, ~$0.14). **La familia:** `familia-gpt-2.png` (gpt-image API, attempt 2, ~$0.17), then a pixel-only suit recolor, navy → the matador's royal blue (`prompts/end_scene_images/recolor_suit.py`, gain 1.5), giving `familia-gpt-2-royal.png`. Faces are byte-identical to the generation. Both were center-cropped 8 px per side to exact 3:2 and exported as JPEG q85: **`endScene_toreros` 3504x2336, 1.69 MB; `endScene_familia` 3504x2336, 1.12 MB.** Both are in `Assets.xcassets/Game/` and the build passes. The prompts ran exactly as written; no prompt changes. Gemini ran every image too (5056x3392) and lost both rounds on stiff poses and, for La familia, drifted faces. Josh kept the embroidered montera gpt-image gave him. No watermark removal was needed. All candidates and contact sheets are kept in `art-sources/end-scene/` for the blog. |
| 2. Game | **Done** (2026-09-26) | State in new `Models/Game/GameState+Slideshow.swift` (`EndSceneSlide` in `GameModels.swift`), view in `GameView.endSceneSlideLayer`. Built as planned, with these additions: VoiceOver pans also restart the hold; the drag is tracked with a `@GestureState` so a cancelled gesture can't leave the hold paused; the two JPEGs are decoded off the main thread when the end scene opens. The yellow ring stayed. Nine new `GameBossTests` cases; full suite passes (586 Swift Testing tests). Verified on iPhone 17 and iPad Pro 11-inch (M5), English and Spanish, including Reduce Motion. The TEMP hook in `SettingsView.swift` is removed. No image changes needed. |

The temporary Settings ▸ Play → end-scene hook (two `TEMP` lines in
`Conjugar/Views/SettingsView.swift`) was removed at the end of Phase 2. `conjugar://game/end`
remains the fast path to the end scene.

## Goal

The end scene of Toreo por Amor gains two still images that alternate with the existing live
scene:

1. **Los toreros**: the dancer, the bull, and the matador, facing the viewer and smiling. The
   bull, between them, wears a white garland.
2. **La familia**: Josh, Amanda, and their horse Vegas, posed the same way. Vegas, between
   them, wears a white garland.
3. **The live scene**, as it exists today.

Each change is an **iris wipe** (the film term Josh was reaching for): the incoming scene opens
out of a circle that grows from the center of the screen until it covers the old one. In older
cinematography usage an opening iris is an "iris in" and a closing one an "iris out", but usage
varies, so the code and docs call it an iris wipe.

The images are 3:2 landscape inside the game's portrait column, so they fill the column's height
and the player drags them sideways. A "Drag Me" toast teaches the gesture.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Sequence | The live reunion plays first, unchanged. Five seconds after the reunion burst, the iris opens on Los toreros, then La familia, then the live scene, and the cycle repeats until the player quits. | Keeps the matador's walk and the reunion burst as the payoff. The images reward the player who lingers. |
| Hold time | Each slide holds for 5 s once its iris has fully opened. | Josh's "every five seconds". Counting from the end of the wipe means every slide gets its full 5 s on screen. |
| Taps | Taps do nothing anywhere in the end scene. Only the X (quit) button closes the game. | Prevents accidental exits while dragging. This replaces today's "any tap dismisses" end-scene behavior. |
| Image size | Each image fills the full height of the play column and is about 3 screens wide on iPhone. It is dragged horizontally only, clamped at the edges. | Immersive, and each of the three figures gets roughly one screen. |
| Drag vs timer | While a finger is down, the countdown pauses. On release the 5 s countdown restarts. | Someone studying the picture should not have it wiped away mid-drag. |
| Overlays | During an image, the ¡Victoria! title, the "bull is impressed" line, and the confetti fade out. The X button, the toast, and the family caption remain. They return with the live scene. | The title sits where the faces are. |
| Toast | "Drag Me" / "¡Arrástrame!" appears when an image finishes opening, stays about 2 s, then fades. It stops appearing for the rest of the session once the player has dragged. | Teaches the gesture without nagging. |
| Caption | La familia carries a small caption at the bottom: "Josh (the developer), Amanda, and Vegas" / "Josh (el desarrollador), Amanda y Vegas". Los toreros has none. | Players won't otherwise know who these people are. |
| Setting and framing | Both images: waist-up studio portraits on the warm cream backdrop the app icons use, soft golden light. The animal's head and neck sit between the two people at about face height. | Matches the icons, keeps faces large, and makes the two images read as a pair. |
| Positions | Los toreros: dancer left, bull center, matador right. La familia: Amanda left (the dancer's place), Vegas center, Josh right (the matador's place). | Mirrors the roles across the two images and matches the game, where the matador stands to the dancer's right. |
| Josh's and Amanda's clothes | Their own outfits, recolored, plus one accent each. Josh: his suit in the matador's royal blue, white shirt, gold tie, and a gold montera. Amanda: her sleeveless ruched dress in the dancer's red, gold jewelry, and a red rose tucked above her ear. | Keeps them recognizably themselves while echoing the other pair. |
| Garland | White carnations for both animals. | The carnation (clavel) is Spain's emblematic flower and at home in flamenco. Change the prompt if roses read better. |
| Vegas's halter | Removed. | The garland is the neckwear; a halter competes with it. |
| Selection | Generate about 3 candidates per tool per image with both gemini-image and gpt-image. Claude drops any with likeness or anatomy problems and shows Josh the top 2 or 3 side by side. Josh makes the final pick. | Only Josh can judge likeness to Josh, Amanda, and Vegas. |

## Phase 1: the images

**Done when:** `endScene_toreros` and `endScene_familia` imagesets are in
`Conjugar/Assets.xcassets/Game/`, the app builds, Josh has approved both, and the Status table
records which tool produced each winner and its final pixel size.

**Out of scope:** any Swift code. Phase 2 owns the game.

### Source material

Copy every reference into a gitignored working folder, `art-sources/end-scene/`, so the
generation is reproducible and nothing depends on `~/Downloads`. Add `art-sources/` to
`.gitignore` beside `audio-sources/`.

| Reference | Path | Notes |
|---|---|---|
| Dancer | `Conjugar/Assets.xcassets/DancerIcon.appiconset/DancerIcon-light.png` | In profile, eyes closed, arms raised with castanets. The prompt must turn her to face the viewer with eyes open. |
| Bull | `Conjugar/Assets.xcassets/BullIcon.appiconset/BullIcon-light.png` | Head and chest only; dark brown coat, pale horns with black tips, mouth slightly open. |
| Matador | `Conjugar/Assets.xcassets/MatadorIcon.appiconset/MatadorIcon-light.png` | Waist-up, hands on hips, royal-blue and gold traje de luces, gold montera, pale gloves, already smiling. |
| Josh | `~/Downloads/Josh.jpg` (4256x2832) | **The main reference for Josh.** Front-on head and shoulders, even light, face about 1,000 px across. Dark hair combed back, blue-green eyes, closed-mouth smile, the same navy pinstripe suit and blue tie as the couple photo. |
| Amanda | `~/Downloads/Amanda.jpg` (500x501) | **A reference for Amanda, used with the couple photo.** Front-on studio portrait with a natural open smile. Face about 220 px across, so it adds a second view rather than more detail. Her hair is a darker honey blond here than in the couple photo. |
| Josh and Amanda | `~/Downloads/couple.jpg` (638x958) | Chest-up, heads tilted together. Amanda: lighter blond, sleeveless black ruched dress, amber-gold earrings, statement necklace. **Used for Amanda's likeness and outfit, and for the couple's relative heights.** Josh is on the left in the photo; the prompt moves him to the right. |
| Vegas | `~/Downloads/horse.jpg` (2448x2448) | Bay with a black mane and forelock, small white fleck on the forehead, leather halter. |

Image models keep a likeness better with several views of a person, so Amanda gets two
references. Josh's single sharp portrait is enough for him.

**Amanda's hair color: honey blond** (settled with Josh on 2026-09-26). It is the darker shade
in `Amanda.jpg`; `couple.jpg` shows it lighter. The La familia prompt says "honey-blond".

### Prompts

Store each prompt as a text file so every candidate can be regenerated exactly:
`prompts/end_scene_images/toreros.txt` and `prompts/end_scene_images/familia.txt`. The texts
below are the starting point. Each tool labels reference images by order, so pass the images in
the order the prompt names them.

**Los toreros** (Image 1 = dancer icon, Image 2 = bull icon, Image 3 = matador icon):

```text
A photorealistic celebratory group portrait in a 3:2 landscape frame, in the same painterly
studio-photograph style as the reference images: a warm cream seamless backdrop, soft golden
key light, gentle shallow depth of field.

Left: the flamenco dancer from Image 1. Keep her face, her black hair pulled back in a low bun,
the red rose over her ear, her red dress with red-and-gold ruffled sleeves, and her gold
embroidered, fringed manton shawl. She now faces the viewer with her eyes open and a warm,
joyful smile. One hand rests on the bull's neck.

Center: the fighting bull from Image 2. Keep his dark-brown coat and his pale, curved,
black-tipped horns. He faces the viewer head-on, his head and neck between the two people at
about their face height, with a gentle, happy expression, mouth slightly open so it reads as a
smile. A full, lush garland of white carnations hangs around his neck.

Right: the matador from Image 3. Keep his face, his dark hair, his gold montera, and his
royal-blue traje de luces with gold embroidery and white pearl trim, white shirt, gold tie and
waistcoat, and pale gloves. He faces the viewer with a broad smile, one gloved hand on the
bull's shoulder.

Framing: waist-up for both people, the three close together and filling the frame from edge to
edge, with a little headroom. All three faces sit in the upper-middle third. The bull's horns
are fully in frame and clear of the people's faces.

Avoid: text, logos, watermarks, extra people or animals, extra or missing fingers.
```

**La familia** (Image 1 = Josh.jpg, Image 2 = Amanda.jpg, Image 3 = couple.jpg,
Image 4 = horse.jpg, Image 5 = the chosen Los toreros image, used only for style and
composition):

```text
A photorealistic celebratory group portrait in a 3:2 landscape frame that matches the style,
lighting, backdrop, and composition of Image 5: a warm cream seamless backdrop, soft golden key
light, gentle shallow depth of field. Do not copy any person or animal from Image 5.

Images 1 to 3 show the two people. Image 1 is the man. Images 2 and 3 are the same woman (she
is the woman on the right in Image 3). Image 3 also shows their heights relative to each
other; keep that relationship.

Left: the woman from Images 2 and 3. Preserve her face, honey-blond hair, eyes, and open smile
exactly. She wears the sleeveless ruched dress from Image 3, now a deep red, with gold
earrings and a gold necklace, and a red rose tucked above her ear. She faces the viewer and
smiles warmly, one hand resting on the horse's neck.

Center: the horse from Image 4. Keep his bay coat, black mane and forelock, the small white
fleck on his forehead, and his head shape. He faces the viewer between the two people, his
head at about their face height, ears pricked, with soft eyes and a relaxed, happy expression.
No halter. A full, lush garland of white carnations hangs around his neck.

Right: the man from Image 1. Preserve his face, dark combed-back hair, blue-green eyes, and
build exactly. He wears the suit from Image 1, now royal blue, with a white shirt, a gold tie,
and a gold matador's montera. He faces the viewer with a broad smile, one hand on the horse's
shoulder.

Framing: waist-up for both people, the three close together and filling the frame from edge to
edge, with a little headroom. All three faces sit in the upper-middle third.

Avoid: changing either person's face, age, or build; text, logos, watermarks; extra people or
animals; extra or missing fingers.
```

Generate Los toreros first and choose it before starting La familia, because La familia uses
the winner as its style and composition reference. That is what makes the pair match.

La familia takes five references: pass `--edit` five times, in the order above. Both tools
accept that many (Gemini 3 Pro Image takes up to 14).

### Generating candidates

About three candidates per tool per image, so twelve in all. Filenames record the tool and the
attempt: `art-sources/end-scene/toreros-gemini-1.png`, `…-gpt-2.png`, and so on.

**gemini-image**, 3:2 at 4K on `gemini-3-pro-image-preview`:

```bash
/gemini-image --edit art-sources/end-scene/ref-dancer.png --edit art-sources/end-scene/ref-bull.png \
  --edit art-sources/end-scene/ref-matador.png --file prompts/end_scene_images/toreros.txt \
  -a 3:2 -s 4K -o art-sources/end-scene/toreros-gemini-1.png
```

This needs a skill change first: gemini-image accepts only one `--edit` image today, and Gemini 3
Pro Image accepts up to 14 references. See step 1 of the Phase 1 steps. Also confirm that
`3:2` works; the skill's help lists only five ratios, although the model supports more.

**gpt-image**, 3:2 at 3520x2336 through the API on `gpt-image-2.5-sunburst` (the default):

```bash
/gpt-image --api --edit art-sources/end-scene/ref-dancer.png --edit art-sources/end-scene/ref-bull.png \
  --edit art-sources/end-scene/ref-matador.png --file prompts/end_scene_images/toreros.txt \
  -s 3520x2336 -q high -o art-sources/end-scene/toreros-gpt-1.png
```

Josh's OpenAI API billing went through on 2026-09-26, so use the API, not Codex. Run one
candidate first and check the cost the script prints before generating the rest. 3520x2336 is
above the 2560x1440 that OpenAI calls experimental; if it misbehaves, fall back to `-a 3:2 -s 2K`
(2336x1552). Codex mode (`--codex`) remains a fallback, but it produces only about 1536x1024.

### Resolution

On an iPhone 17 the play column is 874 pt tall, which is 2622 px at 3x. A 3:2 image shown at that
height is about 3933 px wide. What each source provides:

| Source | Typical 3:2 output | At full height on iPhone 17 |
|---|---|---|
| gemini-image `-s 4K` | about 4K px wide | Sharp |
| gpt-image via the API, `-s 3520x2336` | 3520x2336 | Sharp (about 89% of native) |
| gpt-image via the API, `-a 3:2 -s 2K` (fallback) | 2336x1552 | Slightly soft (enlarged about 1.7x) |
| gpt-image via Codex (fallback only) | about 1536x1024 | Soft (enlarged about 2.5x) |

If a winner comes from one of the fallbacks, upscale it with an edit, for example
`--api --edit <winner> -s 3520x2336 -q high` with the instruction "Reproduce this image exactly
at higher resolution," or the same edit through gemini-image at `-s 4K`. Compare the upscale to
the original before accepting it, because an edit re-renders the image and can drift.

### Choosing

1. Claude reviews all candidates for each image and drops any with warped anatomy, extra
   fingers, a horn through a face, a lost garland, text or watermarks, or (for La familia) a
   poor likeness.
2. Claude builds a local contact sheet of the top 2 or 3 per image and opens it for Josh, with
   the tool and attempt under each image. This stays local, not a published artifact, because
   La familia uses family photos.
3. Josh picks one image per slot. Iterate with single, targeted prompt changes if none is
   right.

### Processing the winners

- Crop to exactly 3:2 if the output drifted, keeping the faces in the upper-middle third.
- Cap the longer edge at 3936 px and export as JPEG at about 85% quality, roughly 1 to 1.5 MB
  each. The images are photographic with no transparency, so JPEG is the right format.
- Add them as `Conjugar/Assets.xcassets/Game/endScene_toreros.imageset` and
  `…/endScene_familia.imageset`, one universal image each (no 1x/2x/3x variants).
- Gemini images carry a visible watermark at some account tiers. Run `/remove-watermark` on a
  Gemini winner only if one is visible. Both tools embed invisible provenance marks, which stay.

### Phase 1 steps

1. **Tooling.** Extend `~/.claude/skills/gemini-image` so `--edit` is repeatable, sending every
   image as a part ahead of the prompt, and confirm `-a 3:2` works. Keep the single-image form
   working, and update the skill's help text. gpt-image already supports repeated `--edit`.
   Confirm its API backend works: `~/.claude/skills/gpt-image/generate_image.py --dry-run test -o
   /tmp/t.png` should report `Backend: api`. If it says `codex`, the key is missing from
   `~/.claude/skills/gpt-image/.env`.
2. **Staging.** Create `art-sources/end-scene/`, add `art-sources/` to `.gitignore`, and copy the
   seven references in (three icons, `Josh.jpg`, `Amanda.jpg`, `couple.jpg`, `horse.jpg`).
   Write the two prompt files.
3. **Los toreros.** Generate about 3 candidates per tool, cull, show Josh a contact sheet, and get
   the pick. Iterate if needed.
4. **La familia.** Same, with the Los toreros winner as Image 5.
5. **Finalize assets.** Upscale if the winner came from a fallback size, crop, export, and add both
   imagesets. Build the app to confirm the catalog compiles.
6. **Wrap up.**
   - Update the Status table: Phase 1 done, each winner's tool and attempt, final pixel sizes and
     file sizes, and any prompt changes that made the difference (also edit the prompt files so
     they match what produced the winners).
   - Update `docs/project-structure.md` for `prompts/end_scene_images/`, the two imagesets, and the
     gitignored `art-sources/`.
   - Add a journal entry to `docs/blog_notes.md` on the image generation: how the two tools
     compared, which won and why, and what the likeness work took.

### Phase 1 risks

- **Likeness.** AI edits tend to beautify or drift faces. Josh's sharp portrait makes his
  likeness the easier one. Amanda's references are both small (faces about 220 to 250 px), so
  hers is the harder one, and two views are the mitigation. The prompt says to preserve faces,
  and Josh judges the result. If both tools fall short, try a face-only fix pass: edit the
  chosen image (Image 1) with `Josh.jpg` (Image 2) and `Amanda.jpg` (Image 3) attached and the
  instruction "restore these two faces to match Images 2 and 3 exactly; change nothing else."
- **The dancer's face.** The icon shows her in profile with her eyes closed, so a front view is
  partly invented. Accept some freedom here; she is a character, not a real person.
- **A smiling bull and horse.** Animals cannot smile, so ask for a relaxed, open-mouthed, happy
  expression and reject anything uncanny.
- **App size.** Two JPEGs add about 2 to 3 MB.

## Phase 2: the game

**Starts with:** confirm Phase 1 is marked done in the Status table and that
`Conjugar/Assets.xcassets/Game/endScene_toreros.imageset` and `endScene_familia.imageset`
exist. If they don't, stop and tell Josh.

**Done when:** the slideshow runs as the Decisions describe, tests pass, it is verified in the
simulator in English and Spanish on iPhone and iPad, the TEMP hook is gone, and the docs are
updated.

**Out of scope:** changing the images. If an image needs work, note it for Josh instead.

### State (GameState)

The slideshow is time-driven like the rest of the end scene, so it lives in `GameState` and
advances in `update(dt:)`. That way `CONJUGAR_GAME_TIME_SCALE` slows the iris for freeze-framing,
and Swift Testing can drive it.

- `enum EndSceneSlide { case live, toreros, familia }`, with `next`: live → toreros →
  familia → live.
- New state: `endSceneSlide` (current), `endSceneIncomingSlide` (non-nil during a wipe),
  `endSceneIrisProgress` (0…1), `endSceneSlideHold` (seconds left), `endSceneDragActive`,
  `endSceneHasDragged`, and `endSceneToastTime`.
- The cycle starts when the reunion burst fires (`endSceneBurstDone`), with a 5 s hold on the
  live scene.
- Hold countdown: pauses while `endSceneDragActive`, and restarts at 5 s when a drag ends. At
  zero, a wipe begins toward `next`.
- Wipe: `endSceneIrisProgress` rises over `endSceneIrisDuration` (0.9 s), eased with the existing
  `smoothstep`. At 1 the incoming slide becomes current, the hold restarts at 5 s, and if the new
  slide is an image and `endSceneHasDragged` is false, the toast starts.
- Sound: music continues throughout. While an image is up or opening, suppress the bull's
  vocalizations and the reunion chime, since those sounds come from things that are not
  visible. The live simulation keeps running underneath, so the bull is mid-dance when the live
  scene returns.
- Add all new fields to the existing reset path (the block that zeroes `endSceneTime` and its
  siblings) and to `debugJumpToEndScene()`.

New constants beside the other `endScene…` constants: `endSceneSlideHold = 5.0`,
`endSceneIrisDuration = 0.9`, `endSceneToastDuration = 2.0`.

### View (GameView)

- **Slide layer.** A new layer above the playfield and below `bossTapLayer`, `quitButton`, and
  the controls. For an image slide it draws the image at the column's height, offset
  horizontally by the drag.
- **Iris wipe.** The incoming slide is drawn over the current one and masked by a `Circle`
  centered in the column. Its diameter is `endSceneIrisProgress` × the column's diagonal, so the
  corners are covered at 1. A 3 pt `Color.customYellow` ring rides the circle's edge and fades
  out over the last 20% of the wipe; drop it if it looks busy. When the incoming slide is the
  live scene, the live playfield is already underneath, so the wipe instead reveals it by
  masking the outgoing image with the inverse circle (an even-odd fill).
- **Drag.** A `DragGesture` on the image layer sets `endSceneDragActive` on change and clears it
  on end. The horizontal offset is clamped so the image edges never pull inside the column. Each
  image opens centered, so the animal is in view first, and resets to center every time it
  returns.
- **Overlays.** `bossCards` (title and line) and the confetti fade out with the incoming image
  and back in with the live scene.
- **Toast.** "Drag Me" / "¡Arrástrame!" in the game's rounded display style: customYellow on a
  customRed plate, like `bossTitle` but smaller. Centered in the lower third, with a short
  left-right arrow motif.
- **Caption.** On La familia only, a small caption bar along the bottom of the column. It stays
  fixed while the image moves.
- **Taps.** In `bossTapLayer`, `.endScene` no longer calls `dismiss()`. Either leave the layer
  out of the end scene or make it swallow taps without acting. The quit button is the only way
  out.
- **Reduce Motion.** With `accessibilityReduceMotion`, the iris becomes a 0.4 s crossfade and the
  toast appears without motion.
- **VoiceOver.** Each image gets an accessibility label that describes it. The family label names
  Josh, Amanda, and Vegas. An `accessibilityAdjustableAction` pans the image a third at a time,
  so VoiceOver users can reach the whole picture.
- **iPad.** The column is already phone-shaped, so no special case is needed. Verify only.

### Strings

New `L.Game` accessors and catalog entries (`en` and `es`, both `translated`):

| Key | English | Spanish |
|---|---|---|
| `Game.dragMe` | Drag Me | ¡Arrástrame! |
| `Game.familyCaption` | Josh (the developer), Amanda, and Vegas | Josh (el desarrollador), Amanda y Vegas |
| `Game.torerosImageLabel` | The dancer, the bull, and the matador, smiling together; the bull wears a garland of white carnations | La bailaora, el toro y el matador, sonrientes; el toro lleva una guirnalda de claveles blancos |
| `Game.familyImageLabel` | Josh, the developer, and Amanda with their horse, Vegas, who wears a garland of white carnations | Josh, el desarrollador, y Amanda con su caballo, Vegas, que lleva una guirnalda de claveles blancos |

### Phase 2 steps

1. **State machine and tests.** `EndSceneSlide` and the new `GameState` fields and constants.
   Swift Testing cases in `GameBossTests`:
   - The cycle does not start before the reunion burst.
   - After the burst plus 5 s, a wipe to Los toreros begins.
   - A wipe completes after `endSceneIrisDuration`.
   - The order is live → toreros → familia → live.
   - An active drag pauses the hold, and its end restarts it at 5 s.
   - The toast starts on an image only until the first drag.
   - `debugJumpToEndScene()` and the reset path clear all slideshow state.
2. **View.** Slide layer, iris mask and ring, drag, overlay fades, toast, caption, and the taps
   change. Then Reduce Motion and VoiceOver.
3. **Strings.** `L.swift` and `Localizable.xcstrings`, validated with the JSON check in
   CLAUDE.md.
4. **Verify in the simulator.** Use the temporary Settings ▸ Play hook, plus
   `CONJUGAR_GAME_TIME_SCALE=0.1` to freeze-frame a wipe mid-circle. Screenshot the live scene,
   both images (centered and dragged to each edge), a mid-wipe frame, the toast, and the caption,
   in English and Spanish, on iPhone and iPad. Confirm taps no longer quit and X does.
5. **Clean up and document.**
   - Remove the two `TEMP` lines in `SettingsView.swift`: the `router.pendingEndScene = true`
     line, and restore `GameView()` in the `fullScreenCover`.
   - Update `docs/game.md`: the end-scene paragraph (the slideshow, and "only X closes"
     replacing "any tap dismisses") and a pointer to this plan's Phase 1 for the art sources and
     prompt files.
   - Update `docs/project-structure.md` for any new files, and add a journal entry to
     `docs/blog_notes.md` on the iris wipe and slideshow.
   - Update the Status table: Phase 2 done.
