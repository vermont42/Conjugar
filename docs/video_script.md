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

First Clip - six seconds
Starts out at top of VerbBrowseView. Sort by frequency (ser on top). Slowly scroll down for five seconds.
Label:
4,811 Spanish verbs — from abajar to zurrar, sorted alphabetically or by frequency.
4811 verbos españoles: de abajar a zurrar, ordenados alfabéticamente o por frecuencia.

Second Clip - six seconds
Starts out at top of ser's VerbView. Slowly scroll down for five seconds. (Conjugar has no compound-tense toggle — every tense is always shown, so nothing needs setting up first.)
Label:
Every conjugation of every verb — twenty tenses at a glance.
Todas las conjugaciones de cada verbo: veinte tiempos de un vistazo.

Third Clip - six seconds
Starts out on ModelBrowseView, default Irregularity sort (decir on top). Wait two seconds. Tap haber, the second row. Wait one second. Slowly scroll down for three seconds.
Label:
All 102 Spanish conjugation models.
Los 102 modelos de conjugación del español.

Fourth Clip - seven seconds
Starts out on QuizView. Start. Type answer. Submit. Repeat once.
Label:
Quiz mode: fifty timed questions to sharpen your conjugation skills.
Modo test: cincuenta preguntas cronometradas para afinar tus conjugaciones.

Fifth Clip - seven seconds
Starts out at top of InfoBrowseView. Scroll down so that Presente de Indicativo is centered. Tap it. Slowly scroll down.
Label:
From Proto-Indo-European to modern Spanish — the story behind every tense.
Del protoindoeuropeo al español moderno: la historia de cada tiempo verbal.
