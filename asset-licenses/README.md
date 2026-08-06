# Asset licenses

License paper trail for third-party media bundled in Conjugar (per
`docs/game_design_research.md` §4). Each entry records the asset, its source, and the
license under which it is reused. App-facing credits live in `Info.creditsText`
(`Conjugar/Supporting/Localizable.xcstrings`).

## Game music

- **`Conjugar/flamencoLoop.mp3`** (gameplay), **`Conjugar/Audio/spanishTension.mp3`**
  and **`Conjugar/Audio/spanishGuitarStandoff.mp3`** (both bundled but unwired) — three
  royalty-free **Pond5** tracks: *"Flamenco Adventure"*, *"Spanish Tension"*, and
  *"Spanish Guitar Standoff"*. **Pond5 Content License** — commercial use OK, **no
  attribution required** (the app's "Game Music" credit is a courtesy). Encoded from the
  WAV masters to 192 kb/s / 44.1 kHz stereo MP3; masters live in the git-ignored
  `audio-sources/` folder. See `pond5-game-music.txt`. Gameplay loops
  `flamencoLoop.mp3` (holds "Flamenco Adventure") via `numberOfLoops = -1`; the other two
  are staged for future onboarding / game-end / boss-fight scenes.

## Game sound effects

- **`pop.mp3`, `chomp.mp3`, `moo.mp3`, `shieldActivate.mp3`, `soccerKick.mp3`** —
  reused from the sibling apps **Konjugieren** and **Conjuguer**, where they were
  sourced from **Pixabay** (<https://pixabay.com>). **Pixabay Content License** —
  commercial use OK, **no attribution required** (the app's "Game Sounds" credit is a
  courtesy). See `game-sounds-pixabay.txt`.

- **`Conjugar/Audio/{castanetLow,castanetHigh,palmas,crowdOle,snort,stompThud,capeWhoosh,tensionSting}.mp3`**
  — the boss fight **"La Llamada"** dance-off SFX pack (paso-left/right castanet cues,
  olé palmas, crowd olé, bull snort, stomp thud, cape whoosh, freeze-slot tension sting),
  downloaded fresh from
  **Pixabay** and trimmed/normalized to 192 kb/s MP3. The two paso cues are one
  castanet click pitch-shifted low/high. **Pixabay Content License** — commercial use
  OK, **no attribution required** (courtesy "Game Sounds" credit). Per-file provenance
  (id · uploader · title) in `pixabay-game-sfx.txt`.

## Game sprites

- **`Conjugar/Assets.xcassets/Game/dancer_{idle,walk,climb,jump,cape}_*`** — the
  player's sprite-animation frames (one flipbook per action), rendered from
  **Mixamo** mocap clips (Breathing Idle / Walking / Climbing Ladder / Jump /
  Taunt) on the stock **"X Bot"** character — the same character across all five,
  so scale matches (FBX → Blender orthographic render via
  `tools/blender/render_sprites.py`). **Mixamo/Adobe license** — royalty-free for
  commercial use, **no attribution required**; only the raw assets may not be
  resold standalone (shipping rendered sprites in-app is fine). The source FBX
  files are **git-ignored** (raw-asset restriction + public/AGPL repo); only the 2D
  sprites ship. See `mixamo-dancer.txt`. The X Bot mannequin is a placeholder for
  the eventual custom flamenco dancer.

## Original app sounds

- `applause1-3`, `buzz`, `chime`, `chirp`, `gun`, `sadTrombone1-4`, `silence` —
  created by **Sound Jay** (<https://www.soundjay.com>), reused under Sound Jay's
  terms (incorporation into commercial/non-commercial projects permitted; Sound Jay
  retains ownership). Credited under "Sound Jay" in `Info.creditsText`.
