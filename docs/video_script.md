# Script and Playbook for iOS App Store Previews

Adapted from the sibling app Conjuguer (French), `../Conjuguer/docs/video_script.md`, for
Conjugar's Spanish content: Spanish verbs and exemplars, Conjugar's own counts (4,811 verbs,
102 models, 20 conjugated tenses, 50 quiz questions), and Spanish rather than French label
copy. The structure — five clips, 32 seconds, the size table, the preflight — is unchanged.

Ensure that videos are exactly 32 seconds *without* transitions. There are 5 clips, so 4 half-second transitions between them shrink the length by two seconds, to 30. (FCP's default transition duration is 1 second; this assumes it has been set to 0.5 second in Settings ▸ Editing.)

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
cuatro mil ochocientos once verbos españoles: de abajar a zurrar, ordenados alfabéticamente o por frecuencia.
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
Quiz mode: fifty timed questions to sharpen your conjugation skills.
Modo test: cincuenta preguntas cronometradas para afinar tus conjugaciones.
IPA: [ˈmo.ðo ˈtes(t) ‖ siŋˈkwen.ta pɾeˈɣun.tas kɾo.no.meˈtɾa.ðas ˈpa.ɾa a.fiˈnaɾ tus koŋ.xu.ɣaˈsjo.nes]

Fifth Clip - seven seconds
Starts out at top of InfoBrowseView. Scroll down so that Presente de Indicativo is near top of screen. Tap it. Slowly scroll down to bottom.
Label:
From Proto-Indo-European to modern Spanish — the story behind every tense.
Del protoindoeuropeo al español moderno: la historia de cada tiempo verbal.
IPA: [del ˌpɾo.to.in.do.ew.ɾoˈpe.o al es.paˈɲol moˈðeɾ.no ‖ la isˈto.ɾja ðe ˈka.ða ˈtjem.po βeɾˈβal]
