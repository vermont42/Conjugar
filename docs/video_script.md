# Script and Playbook for iOS App Store Previews

Adapted from the sibling app Conjuguer (French), `../Conjuguer/docs/video_script.md`, for
Conjugar's Spanish content: Spanish verbs and exemplars, Conjugar's own counts (4,811 verbs,
102 models, 20 conjugated tenses, 30 quiz questions), and Spanish rather than French label
copy. The structure — five clips, 32 seconds, the size table, the preflight — is unchanged.

Ensure that videos are exactly 32 seconds *without* transitions. There are 5 clips, so 4 half-second transitions between them shrink the length by two seconds, to 30. (FCP's default transition duration is 1 second; this assumes it has been set to 0.5 second in Settings ▸ Editing.)

**Target 30.000 s exactly.** 30 s is the App Store's hard *maximum* and it is inclusive — a
file measuring 30.000000 s is accepted. Every second of a preview is precious, so spend all
thirty. What is *not* accepted is 30.015 s, which is what a careless delivery pass produces
from a perfectly good 30.000 s master: see **The 30.015 s trap** below.

## App Store preview specifications

Sizes, which are **not** the screenshot sizes — conflating the two got all four of
Conjuguer's 2.0 previews rejected with *"The app preview dimensions should be:
886 × 1920px or 1920 × 886px"*:

| Device | Preview size | Notes |
|---|---|---|
| iPhone | **886 × 1920** | One file serves *every* current iPhone class (6.9″, 6.5″, 6.3″, 6.1″). |
| iPad | **1200 × 1600** | Covers 13″, 12.9″, 11″, 10.5″. |

Record at native simulator resolution and let the Final Cut project scale down; the project resolution is what gets
delivered.

Shoot the sweep twice — once with the simulator in English, once in Spanish — mirroring the
two-language screenshot bundles in `docs/screenshots/version_N/`. Each clip below carries its
English label first and its Spanish label second.

Verify before uploading:

```bash
scripts/verify_store_media.sh ~/Desktop/Final/Conjugar
```

## Delivering the files

Compressor's export already conforms on everything App Store Connect enforces — 886 × 1920
/ 1200 × 1600, SAR 1:1, H.264 High ≤ L4.0, 30 fps, an AAC track, and exactly 30.000 s. The
delivery pass is cleanup for two cosmetic advisories: Final Cut writes a stray timecode
track (3 streams instead of 2), and Compressor's AAC lands near 128 kbps against the
256 kbps spec. Both shipped fine on Konjugieren 1.2, so this is polish, not a blocker.

```bash
cd ~/Desktop/Final/Conjugar && mkdir -p upload
for f in *.mov; do
  ffmpeg -v error -y -i "$f" \
    -map 0:v:0 -map 0:a:0 \
    -c:v copy -c:a aac -b:a 256k -ar 48000 -ac 2 \
    -dn -sn -shortest -map_metadata -1 -movflags +faststart \
    "upload/$f"
done
```

The video is **stream-copied**, so the H.264 bitstream stays bit-identical to the master —
no generational loss, and no risk of disturbing the profile/level. Confirm it with
`ffmpeg -v error -i in.mov -map 0:v:0 -f md5 -` run against both files; the hashes must
match. Only the audio is transcoded. `-map_metadata -1` is not optional: with `-dn` alone,
the mov muxer re-creates a timecode track from the video stream's metadata.

### The 30.015 s trap

The obvious delivery pass is a pure remux — `-c copy` for *both* streams — and it is
**wrong**. It yields **30.015 s**, over the cap, from a master that measures exactly
30.000 s. Every file gains the same silent 15 ms.

Compressor writes a QuickTime **edit list** that trims the audio track back to the last
video frame. The AAC track physically holds 1409 frames — 1409 × 1024 ÷ 48000 = 30.058 s of
samples — and the edit list is the only thing hiding that tail. `ffmpeg -c copy` discards
edit lists, so the full audio track redefines the container duration.

`-t 30` does not rescue it. Under `-c copy` ffmpeg can only cut on AAC packet boundaries,
and 30.000 s is 1406.25 packets — there is no packet to cut on, so the output stays
30.015 s.

**Re-encoding the audio is what fixes it.** `-shortest` stops the AAC encoder when the
900th video frame does, giving 1407 frames and a container duration of exactly
**30.000000**. This also explains the previously unattributed 30.015 s file in the sibling
app Konjugieren's 1.2 delivery: same symptom, same 15 ms, same step.

Always re-probe after any delivery pass — the failure is invisible in the picture:

```bash
ffprobe -v error -show_entries format=duration,nb_streams -of csv=p=0 upload/file.mov
# expect 2,30.000000
```

## Recording the clips

**Nothing about how the simulator is launched or recorded affects App Store Connect.**
Two capture-time facts matter: *which device* you record — that alone fixes the native
pixel size, and therefore the aspect and the Spatial Conform the clip needs — and that the
capture is the device *framebuffer*, not the Mac screen. Everything ASC enforces
(886 × 1920, SAR 1:1, H.264 High ≤ L4.0, ≤ 30 fps, 15–30 s, an AAC track) is imposed in
Final Cut and the export, and the capture satisfies none of it — Simulator's Record Screen writes
H.264 High at **Level 5.0**, variable frame rate, at native 1320 × 2868, with no audio
track. That is fine and expected.

Both recording simulators ship with the current Xcode and are already installed
(iOS 26.3). The sibling app's `../Conjuguer/docs/app-store-preview-videos.md` carries the
narrative behind the choices.

| Deliverable | Simulator | Native capture | On the timeline |
|---|---|---|---|
| iPhone — 886 × 1920 | `iPhone 17 Pro Max` | 1320 × 2868 | Spatial Conform **Fill** (crops the 0.24% aspect difference instead of letterboxing) |
| iPad — 1200 × 1600 | `iPad Pro 13-inch (M5)` | 2064 × 2752 | exactly 3:4 — no crop, no letterbox |

### Launch and record

1. `open -a Simulator`, then **File ▸ Open Simulator ▸ iOS 26.3 ▸ iPhone 17 Pro Max**
   (or `xcrun simctl boot 'iPhone 17 Pro Max' && open -a Simulator`).
2. Install the current build by pressing **Run** in Xcode with that simulator selected as
   the destination.
3. Set the language and pin the 9:41 status bar **once per (device, language) pass**, not
   between takes — this is also how the English/Spanish double sweep above is set up, the
   status bar is in frame for every second of every clip, and changing the system language
   requires a reboot:
   ```bash
   scripts/prep_screenshot_sim.sh 'iPhone 17 Pro Max' en    # then again with es
   scripts/prep_screenshot_sim.sh 'iPad Pro 13-inch (M5)' en
   ```
   `xcrun simctl launch "$UDID" biz.joshadams.Conjugar -AppleLanguages '(es)' -AppleLocale
   es_ES` switches only the *app* without a reboot. Fine for rehearsing a clip, wrong for a
   take: the status bar stays in the old language, and on iPad it renders a date.
4. Record with **Simulator ▸ File ▸ Record Screen**; stop with **File ▸ Stop Recording**.
   The file lands on the Desktop as `Simulator Screen Recording …`.

Record Screen captures the framebuffer at **native pixel resolution**; the window zoom
(Physical Size / Point Accurate / Pixel Accurate) does not change the output. If a
scripted capture is ever wanted instead, `xcrun simctl io <udid> recordVideo --codec h264
--mask black <file>` produces an equally acceptable master — the choice is convenience,
never conformance. (`--codec h264` is worth passing there because `simctl`'s default is
HEVC, unlike Record Screen's.)

### The one way hand-recording ruins a preview

Do **not** use macOS screen recording (⌘⇧5, or QuickTime ▸ New Screen Recording) aimed at
the Simulator window. That captures the *window* at point size × display scale, with
chrome and rounded window corners baked in — on the order of 860 × 1864 instead of
1320 × 2868 — and no Spatial Conform recovers it without upscaling. Simulator's own
Record Screen is framebuffer-based and immune.

### Check each capture before editing

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,sample_aspect_ratio -of csv=p=0 \
  ~/Desktop/'Simulator Screen Recording iPhone 17 Pro Max ….mov'   # expect 1320,2868,1:1
```

Dimensions are the one defect the export cannot repair, and wrong dimensions are exactly
what got Conjuguer's four 2.0 previews rejected.

Ensure that language and region are English and United States or Spanish and Spain. Ensure that hardware keyboard is disconnected. Ensure that values in `Conjugar/Utils/KillSwitches.swift` are `false`.

Each clip carries an **IPA** line for the Spanish label. Broad transcription, **Latin
American** (seseo, yeísmo); for a Peninsular read, swap [s] → [θ] in ⟨z⟩ and ⟨ce/ci⟩ only.
`‖` is the phrase break at the colon. Sandhi is transcribed as spoken, so *once verbos* →
[ˈon.se ˈβeɾ.βos] but *un vistazo* → [um bisˈta.so].

First Clip - six seconds
Starts out at top of VerbBrowseView. Sort by frequency (ser on top). Slowly scroll down for five seconds.
Label:
4,811 Spanish verbs — from abajar to zurrar, sorted alphabetically or by frequency.
4811 verbos españoles: de abajar a zurrar, ordenados alfabéticamente o por frecuencia.
IPA: [ˈkwa.tɾo mil o.t͡ʃoˈsjen.tos ˈon.se ˈβeɾ.βos es.paˈɲo.les ‖ de a.βaˈxaɾ a suˈrar ‖ oɾ.ðeˈna.ðos al.faˌβe.ti.kaˈmen.te o poɾ fɾeˈkwen.sja]

Second Clip - six seconds
Starts out at top of ser's VerbView. Slowly scroll down for five seconds.
Label:
Every conjugation of every verb — twenty tenses at a glance.
Todas las conjugaciones de cada verbo: veinte tiempos de un vistazo.
IPA: [ˈto.ðas las koŋ.xu.ɣaˈsjo.nes de ˈka.ða ˈβeɾ.βo ‖ ˈbejn.te ˈtjem.pos de um bisˈta.so]

Third Clip - six seconds
Starts out on ModelBrowseView, default Irregularity sort (decir on top). Wait two seconds. Tap haber, the second row. Wait one second. Slowly scroll conjugation table (iPhone).
Label:
All 102 Spanish conjugation models.
Los 102 modelos de conjugación del español.
IPA: [los ˈsjen.to ðos moˈðe.los de koŋ.xu.ɣaˈsjon del es.paˈɲol]

Fourth Clip - seven seconds
Starts out on QuizView. Start. Type answer. Submit.
Label:
Quiz mode: thirty timed questions to sharpen your conjugation skills.
Modo test: treinta preguntas cronometradas para afinar tus conjugaciones.
IPA: [ˈmo.ðo ˈtes(t) ‖ ˈtɾejn.ta pɾeˈɣun.tas kɾo.no.meˈtɾa.ðas ˈpa.ɾa a.fiˈnaɾ tus koŋ.xu.ɣaˈsjo.nes]

Fifth Clip - seven seconds
Starts out at top of InfoBrowseView. Scroll down so that Presente de Indicativo is near top of screen. Tap it. Slowly scroll down to bottom.
Label:
From Proto-Indo-European to modern Spanish — the story behind every tense.
Del protoindoeuropeo al español moderno: la historia de cada tiempo verbal.
IPA: [del ˌpɾo.to.in.do.ew.ɾoˈpe.o al es.paˈɲol moˈðeɾ.no ‖ la isˈto.ɾja ðe ˈka.ða ˈtjem.po βeɾˈβal]
