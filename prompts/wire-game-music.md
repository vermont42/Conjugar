# Wire the new flamenco game music into Conjugar

Replace the bland placeholder game track with three purchased Pond5 flamenco tracks:
trim + optimize them, bundle them, wire gameplay music, and stage the other two for
features that don't exist yet (onboarding, boss fight, game-end scene).

This plan is self-contained so it can run in a **fresh session** with little prior
context. Read it top to bottom before starting; the "Current state" and "Gotchas"
sections prevent redoing finished work and botching the Xcode project file.

---

## Current state (already done in the prior session — do NOT redo)

The music-playback API was already generalized and the build is green:

- `Conjugar/Models/Music.swift` **exists** with one case:
  ```swift
  enum Music: String {
    case gameLoop = "flamencoLoop"
  }
  ```
- `Conjugar/Utils/SoundPlayer.swift` protocol method is now `func startMusic(_ music: Music)`.
- `SoundPlayerReal.startMusic(_:)` rebuilds its `AVAudioPlayer` when the requested track
  differs from the loaded one (`currentMusic`), and drops the saved playhead on a switch;
  `SoundPlayerDummy.startMusic(_ music: Music)` is a no-op.
- `Conjugar/Models/Game/GameState.swift:198` calls `Current.soundPlayer.startMusic(.gameLoop)`.
- Current bundled track: `Conjugar/flamencoLoop.mp3` (2.6 MB) — the CC-BY "Vaguely Spanish
  Guitar" placeholder we are replacing.

So the **playback plumbing is finished**. This plan is about the *audio files*, their
*bundling*, and *one new wiring point* (none — gameplay already calls `.gameLoop`), plus
staging two future tracks and the credits/CLAUDE.md bookkeeping.

---

## Inputs — the three purchased tracks (in `~/Downloads`)

Each has an identical `*_backup.wav` twin already; treat the non-backup as the working
original. **`ffprobe` crashes on this machine (Abort trap 6) — use `afinfo` to probe and
`ffmpeg` (has `libmp3lame`) to encode.**

| File (`~/Downloads`) | Duration | Format | Size | Role |
|---|---|---|---|---|
| `Flameno_Adventure.wav` *(sic — misspelled "Flameno")* | 142.56 s (2:22) | 44.1 kHz / 16-bit stereo | 25.1 MB | **Gameplay** — wire now |
| `Spanish_Tension.wav` | 134.99 s (2:14.99) | 48 kHz / 24-bit stereo | 38.9 MB | Onboarding / game-end — **stage only** |
| `Spanish_Guitar_Standoff.wav` | 42.67 s (0:42) | 44.1 kHz / 16-bit stereo | 7.5 MB | Boss fight — **stage only** |

Tracks are from Pond5 (royalty-free **Content License — no attribution required**). Onboarding,
boss fight, and game-end scenes **do not exist yet**, so their tracks get bundled and
enum'd but **not** wired to any play site.

---

## Target end state

- Three MP3s in the app bundle (~3.4 + ~3.1 + ~1.0 MB), in source control.
- Gameplay loops **Flamenco Adventure** instead of the placeholder.
- `Music` enum has cases for all three; only gameplay is played (by the existing
  `GameState` call).
- `Spanish_Tension` trimmed to remove the trailing silence at 2:09–2:14.
- Pristine original WAVs copied to a **git-ignored** repo subfolder; the converted/trimmed
  MP3s are the only audio committed.
- `CLAUDE.md` notes that the future onboarding feature should play `Music.onboarding`.
- Game-music credit updated (Pond5 needs none; the CC-BY casimps1 credit is now obsolete).
- Build + tests green; game verified to play the new track.

---

## Steps

### 1. Back up pristine originals to a git-ignored folder (user item 6)

Do this **first**, before any destructive edit.

```bash
cd /Users/josh/Desktop/workspace/Conjugar.mig
mkdir -p audio-sources
cp ~/Downloads/Flameno_Adventure.wav        audio-sources/Flamenco_Adventure.wav
cp ~/Downloads/Spanish_Tension.wav          audio-sources/Spanish_Tension.wav
cp ~/Downloads/Spanish_Guitar_Standoff.wav  audio-sources/Spanish_Guitar_Standoff.wav
```

Add to `.gitignore` (append under a new comment; the file already has an "# Other" block):

```
# Original purchased audio (Pond5 WAV masters — converted MP3s are committed instead)
audio-sources/
```

Verify: `git status` must **not** list `audio-sources/`.

### 2. Trim the trailing silence from Spanish_Tension (user item 1)

The track is 134.99 s; the user reports 2:09–2:14 (129–134 s) is silence, i.e. the tail.
**Confirm the audio truly ends by ~2:09**, then truncate there.

```bash
# Confirm where audio ends (try a higher noise floor since -50dB found nothing):
ffmpeg -nostats -hide_banner -i ~/Downloads/Spanish_Tension.wav \
  -af silencedetect=noise=-40dB:d=1 -f null - 2>&1 | grep -i silence
```

- If the last `silence_start` is ~129 s (2:09) → truncate at **129.0 s**.
- If audio actually continues past 2:09, adjust the cut so no audible content is lost, or
  ask the user. Do not blindly cut into music.

The truncation happens as part of encoding in step 3 (`-t 129`). No separate WAV is needed
(the untrimmed master is already saved in `audio-sources/`).

### 3. Encode all three WAV → MP3 (user item 2)

192 kbps CBR, 44.1 kHz, stereo (transparent for background music; matches the existing
`flamencoLoop.mp3` scale). Resample Spanish_Tension from 48 kHz. Strip metadata.

```bash
cd /Users/josh/Desktop/workspace/Conjugar.mig

# Gameplay — overwrite the existing bundled placeholder in place (see Gotchas: keeps the
# filename flamencoLoop.mp3, so NO Xcode project edit is needed for the gameplay track).
ffmpeg -y -i ~/Downloads/Flameno_Adventure.wav \
  -map_metadata -1 -codec:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
  Conjugar/flamencoLoop.mp3

# Onboarding (staged) — trimmed to 2:09.
ffmpeg -y -i ~/Downloads/Spanish_Tension.wav -t 129 \
  -map_metadata -1 -codec:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
  /tmp/spanishTension.mp3

# Boss fight (staged).
ffmpeg -y -i ~/Downloads/Spanish_Guitar_Standoff.wav \
  -map_metadata -1 -codec:a libmp3lame -b:a 192k -ar 44100 -ac 2 \
  /tmp/spanishGuitarStandoff.mp3

# Sanity-check sizes + durations:
ls -la Conjugar/flamencoLoop.mp3 /tmp/spanishTension.mp3 /tmp/spanishGuitarStandoff.mp3
for f in Conjugar/flamencoLoop.mp3 /tmp/spanishTension.mp3 /tmp/spanishGuitarStandoff.mp3; do afinfo "$f" | grep -i "estimated duration"; done
```

Expected: ~3.4 MB / ~3.1 MB / ~1.0 MB; durations 142.6 s / 129 s / 42.7 s.

> The gameplay track's bundled name stays `flamencoLoop.mp3` even though it now holds
> "Flamenco Adventure" — that's deliberate (zero project-file churn). Update the comment on
> `Music.gameLoop` to say so. If you'd rather rename it semantically, that requires the
> project-file work in the Gotchas section — optional, not recommended for this pass.

### 4. Bundle the two staged tracks (user item 3)

`Conjugar/flamencoLoop.mp3` is already in the target (overwritten in place), so gameplay
needs nothing here. The **two staged MP3s** must be added to the app target. The root
`Conjugar/` folder is **not** a synchronized group — its mp3s are explicit `project.pbxproj`
references — so a dropped-in file at the root would **not** auto-bundle.

**Recommended:** create a synchronized `Audio/` group once, then files just drop in.

1. Create the folder and move the two MP3s:
   ```bash
   mkdir -p Conjugar/Audio
   mv /tmp/spanishTension.mp3        Conjugar/Audio/spanishTension.mp3
   mv /tmp/spanishGuitarStandoff.mp3 Conjugar/Audio/spanishGuitarStandoff.mp3
   ```
2. Register `Audio` as a `PBXFileSystemSynchronizedRootGroup`, mirroring the existing
   `Models`/`Views`/`Utils` entries. In `Conjugar.xcodeproj/project.pbxproj`:
   - Add a group entry alongside lines ~128–136 (generate a fresh 24-hex-char UUID):
     ```
     <NEWUUID> /* Audio */ = {isa = PBXFileSystemSynchronizedRootGroup; explicitFileTypes = {}; explicitFolders = (); path = Audio; sourceTree = "<group>"; };
     ```
   - Add `<NEWUUID> /* Audio */,` to the **Conjugar app target's** `fileSystemSynchronizedGroups = ( … );` array (the first of the three at ~line 269 — confirm it's the app target, not the widget/tests).
   - Add `<NEWUUID> /* Audio */,` to the children of the `Conjugar` group in `mainGroup` so it shows in the navigator (find the group whose `path = Conjugar;` children list the existing root files).
3. **Build immediately** (step 7) to confirm the project file still parses and the two
   MP3s land in the bundle.

> Zero-edit fallback if the pbxproj edit feels risky: drop the two MP3s into an existing
> synchronized group that already bundles resources (e.g. `Conjugar/Supporting/`, which
> bundles `Localizable.xcstrings`). They'll bundle with no project edit, at the cost of
> semantic tidiness. If you do this, the `Music` raw values stay the bare filenames.

### 5. Add the `Music` enum cases + gameplay wiring (user items 4-5)

Gameplay is already wired (`GameState` → `.gameLoop`), so only the enum grows. In
`Conjugar/Models/Music.swift`:

```swift
enum Music: String {
  /// Flamenco Adventure (Pond5) — the gameplay loop. File name is legacy: the bundled
  /// `flamencoLoop.mp3` now holds Flamenco Adventure (overwritten in place).
  case gameLoop = "flamencoLoop"

  /// Spanish Tension (Pond5) — bed for the future onboarding flow and game-end scene.
  /// NOT wired yet (those scenes don't exist). See CLAUDE.md.
  case onboarding = "spanishTension"

  /// Spanish Guitar Standoff (Pond5) — the future boss-fight loop. NOT wired yet.
  case bossFight = "spanishGuitarStandoff"
}
```

Do **not** add any `startMusic(.onboarding)` / `startMusic(.bossFight)` call — those
scenes don't exist. `SoundPlayerReal` already loops via `numberOfLoops = -1`.

> Loop-seam note for later: `spanishGuitarStandoff` is a purpose-built loop; MP3 encoder
> padding can leave a faint gap at the wrap. Fine for now (unwired). When the boss scene is
> built, if a click is audible, re-encode that one gapless (CAF/AAC) or trim to an exact bar.

### 6. Note the onboarding intent in `CLAUDE.md` (user item 4, revised)

Onboarding isn't wired here — capture the intent instead. Add near the game/audio
discussion (e.g. after the "Game sound & music" material, or in the game section). Suggested text:

> **Planned onboarding music.** Conjugar has no onboarding flow yet (the sibling apps
> Conjuguer and Konjugieren do). When one is built, it should play `Music.onboarding`
> (Pond5's "Spanish Tension", bundled at `Conjugar/Audio/spanishTension.mp3`) as a looping
> bed — `Current.soundPlayer.startMusic(.onboarding)` on the onboarding view's `.onAppear`
> and `Current.soundPlayer.stopMusic()` on `.onDisappear`. The same track is also the
> intended game-end-scene music. The future boss fight should likewise use
> `Music.bossFight` ("Spanish Guitar Standoff").

### 7. Update the game-music credit (`Localizable.xcstrings`)

The `^Game Music^` / `^Música del Juego^` blocks (en at line ~665, es at ~671) credit the
now-removed CC-BY "Vaguely Spanish Guitar". Pond5's Content License requires **no**
attribution, so replace the block with a short courtesy note (mirroring the existing
`^Game Sounds^` Pixabay-courtesy wording). Example en replacement body:

> The flamenco/bull game's music is from Pond5 (%https://www.pond5.com%): "Flamenco
> Adventure" (gameplay), "Spanish Tension", and "Spanish Guitar Standoff". The Pond5
> Content License permits commercial use with no attribution required; this note is a
> courtesy.

**Foot-guns (from CLAUDE.md):** these values contain ASCII `"` and `%…%` markers, so
**edit via `python3` on the raw file, not the Edit tool** (which would unescape the quotes).
Update **both** `en` and `es`, keep each value one physical JSON line (`\n` not literal
newlines), then validate:

```bash
python3 -c "import json; json.load(open('Conjugar/Supporting/Localizable.xcstrings'))"
```

### 8. Build, test, verify (do not skip)

```bash
~/.claude/skills/ios-build-verify/scripts/build_app.sh        # must succeed
~/.claude/skills/ios-build-verify/scripts/run_tests.sh        # TEST SUCCEEDED
```

Then confirm the new track actually plays in the game:

```bash
S=~/.claude/skills/ios-build-verify/scripts
"$S/launch_app.sh"
UDID=$(xcrun simctl list devices booted -j | python3 -c "import sys,json;print(json.load(sys.stdin)['devices'].popitem()[1][0]['udid'])")
xcrun simctl openurl "$UDID" conjugar://game
"$S/screenshot.sh" game-music
```

Listen (or confirm via the audio session) that gameplay now plays Flamenco Adventure, not
the old placeholder. The two staged tracks should be present in the built `.app` bundle
but silent (unwired) — verify they were copied:

```bash
APP=$(ls -d ~/Library/Developer/Xcode/DerivedData/Conjugar-*/Build/Products/Debug-iphonesimulator/Conjugar.app | head -1)
ls "$APP" "$APP/Audio" 2>/dev/null | grep -iE "flamencoLoop|spanishTension|spanishGuitarStandoff"
```

### 9. Log the work

Append a note to `docs/blog_notes.md` (per CLAUDE.md convention): the three Pond5 tracks,
the trim + 192 kbps MP3 optimization (WAV ~25/39/7.5 MB → MP3 ~3.4/3.1/1.0 MB), gameplay
now on "Flamenco Adventure", the two staged tracks + the `Music` enum, the git-ignored
`audio-sources/` masters, and the credit swap to Pond5's no-attribution license.

---

## Gotchas / risks

- **`ffprobe` aborts (Abort trap 6)** on this machine — use `afinfo` (probe) and `ffmpeg`
  (encode). Both `ffmpeg` and `afconvert` are installed.
- **The root `Conjugar/` folder is not a synchronized group.** Overwriting `flamencoLoop.mp3`
  in place is safe (existing ref); *new* root files need explicit pbxproj refs. That's why
  the plan overwrites for gameplay and uses a synchronized `Audio/` group for the staged
  tracks — build-verify right after the pbxproj edit.
- **`.xcstrings` editing:** ASCII quotes must be edited with `python3`, not the Edit tool;
  validate JSON after; update both `en` and `es`; grep is useless inside it (one giant line).
- **SourceKit false positives:** editing these files will spew "Cannot find type 'Music' /
  'Sound' / 'Current' in scope" — ignore them; `build_app.sh` is authoritative.
- **Don't wire onboarding / boss / game-end** — those scenes don't exist. Only gameplay
  plays music this pass.
- **Keep originals out of git** — only the converted/trimmed MP3s are committed; the WAV
  masters live in git-ignored `audio-sources/`.

---

## Checklist (maps to the user's items)

- [ ] (6) Pristine WAV masters copied to git-ignored `audio-sources/`
- [ ] (1) Spanish_Tension trailing silence trimmed at 2:09 (verified first)
- [ ] (2) All three encoded to 192 kbps / 44.1 kHz MP3
- [ ] (3) Three MP3s bundled in the target (gameplay overwrite + `Audio/` group)
- [ ] (5) Gameplay loops Flamenco Adventure (via existing `.gameLoop` call)
- [ ] (4) `Music.onboarding` / `Music.bossFight` added but unwired; CLAUDE.md onboarding note added
- [ ] Game-music credit updated to Pond5 (both en + es), xcstrings validates
- [ ] Build + tests green; game verified in simulator
- [ ] `docs/blog_notes.md` updated
