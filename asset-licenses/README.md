# Asset licenses

License paper trail for third-party media bundled in Conjugar (per
`docs/game_design_research.md` §4). Each entry records the asset, its source, and the
license under which it is reused. App-facing credits live in `Info.creditsText`
(`Conjugar/Supporting/Localizable.xcstrings`).

## Game music

- **`Conjugar/flamencoLoop.mp3`** — *"Vaguely Spanish Guitar"* by Clarence Simpson
  (casimps1), via **ccMixter**. Licensed **CC BY 3.0**
  (<https://creativecommons.org/licenses/by/3.0/>). Instrumental nylon-string
  Spanish/flamenco guitar. See `flamencoLoop-vaguely-spanish-guitar.txt`.
  Attribution is given in the app's Credits screen ("Game Music" block). The real
  track (2:55 stereo mp3) is in place and loops gaplessly in-game via
  `numberOfLoops = -1`.

## Game sound effects

- **`pop.mp3`, `chomp.mp3`, `cow.mp3`, `shieldActivate.mp3`, `soccerKick.mp3`** —
  reused from the sibling apps **Konjugieren** and **Conjuguer**, where they were
  sourced from **Pixabay** (<https://pixabay.com>). **Pixabay Content License** —
  commercial use OK, **no attribution required** (the app's "Game Sounds" credit is a
  courtesy). See `game-sounds-pixabay.txt`.

## Game sprites

- **`Conjugar/Assets.xcassets/Game/dancer_walk_1…6`** — the player's walk-cycle
  sprite frames, rendered from a **Mixamo** "Walking" mocap clip on the stock
  **"X Bot"** character (FBX → Blender orthographic render via
  `tools/blender/render_sprites.py`). **Mixamo/Adobe license** — royalty-free for
  commercial use, **no attribution required**; only the raw assets may not be
  resold standalone (shipping rendered sprites in-app is fine). The source FBX is
  **git-ignored** (raw-asset restriction + public/AGPL repo); only the 2D sprites
  ship. See `mixamo-dancer-walk.txt`. The X Bot mannequin is a placeholder for the
  eventual custom flamenco dancer.

## Original app sounds

- `applause1-3`, `buzz`, `chime`, `chirp`, `gun`, `sadTrombone1-4`, `silence` —
  created by **Sound Jay** (<https://www.soundjay.com>), reused under Sound Jay's
  terms (incorporation into commercial/non-commercial projects permitted; Sound Jay
  retains ownership). Credited under "Sound Jay" in `Info.creditsText`.
