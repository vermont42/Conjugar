# Boss Fight — Three Dance-Off Concepts (Toreo por Amor)

Response to `prompts/boss_fight.md` item 3: after the fifth summit, the player faces the
bull not in combat but in a **dance-off**; win, and the bull — impressed — releases the
matador. Josh picks one concept below; the winner gets a full implementation plan.

> **DECIDED (2026-07-13): Concept 1 — La Llamada — won.** Josh answered all 16 open
> questions (full bull fidelity, end scene included on `Music.onboarding`, boss gated on
> the first summit for now, relaxed compás timing, hearts hidden, Spanish jaleo in both
> localizations, …). The decisions and the implementation plan live in
> **`prompts/game_boss_llamada.md`** — Concepts 2 and 3 below are kept for the record
> (round-3 hard mode and a level-5 tile gimmick may still borrow from them).

> **Research behind this doc:** the game code (`Conjugar/Models/Game/*`,
> `Views/GameView.swift`) and a live drive of `conjugar://game` via ios-build-verify;
> the sibling catalogs (Konjugieren's four special mechanics + Conjuguer's five threats
> and RobotBoss template); dance-game mechanics (Bust a Groove, Space Channel 5, Rhythm
> Heaven); flamenco structure (compás, llamada, jaleo); and the bundled boss track
> (`spanishGuitarStandoff.mp3` — a **42.7 s seamless loop**, laid-back tension groove).
> Sources at the bottom.

---

## The vocabulary is already flamenco (a gift)

Flamenco's own terms name these mechanics better than any game jargon — and using them
doubles as Spanish-culture flavor, exactly like Konjugieren naming its mechanics
*Geisterstunde* and *Bratwurstkette*:

| Term | Meaning | Use in the game |
|---|---|---|
| **compás** | the rhythmic cycle | the timing window / round structure |
| **llamada** | a stomp meaning *"watch out — your turn!"* | the bull's call; the turn-change signal |
| **zapateado** | percussive footwork | stomp moves; Concept 3's whole mechanic |
| **palmas** | rhythmic clapping | crowd feedback; a clap SFX layer |
| **jaleo** | shouts of encouragement (*¡Olé! ¡Eso! ¡Vamos!*) | the judgment pops (instead of Perfect/Good/Miss) |
| **duende** | the untranslatable "magic" of a great performance | **the win meter** |
| **desplante / remate** | a defiant pose / a phrase-ending flourish | round-ending poses for dancer & bull |

Bonus theme note: in ballroom, the **paso doble** is literally the bullfight-as-dance —
so a finale where the bull and dancer end up dancing *together* is culturally on-the-nose
in the best way.

---

## Shared frame (applies to all three concepts)

Every concept plugs into the same staging, so choosing one doesn't change items 1, 2, or 4:

- **Entry.** `checkReachedBull()` stops resetting and starts counting summits. Summits
  1–4 → the already-planned escape beat (`GameView.swift` TODO). Summit 5 →
  `enterBossFight()`: flags clear, `Music.gameLoop` stops, **`Music.bossFight` starts**
  (it's been staged for exactly this), and the girder field cross-fades into **el tablao**
  — one stage floor, bull on the left, dancer on the right, the matador watching from a
  pedestal. (The girders/ladders fade via a 0→1 transition scalar the view reads; no new
  screen, same `GameView`.)
- **The Duende meter** — a **tug-of-war bar** at the top: custom `dancer` symbol on one
  end, `bull` on the other. Good moves push the marker toward the bull; mistakes let it
  slide back. Fill it → win. This reads "dance-*off*" at a glance and replaces hearts
  during the boss (open question below).
- **Jaleo feedback.** Floating text pops in game gold/red — **¡Olé!** (perfect),
  **¡Bien!** (good), **¡Uy!** (miss) — plus 🎵👏🌹✨ emoji bursts and randomized crowd
  SFX. All emoji go through the existing `GlyphWarmer` warm-up list.
- **Family-friendly lose state.** The meter never kills anyone. Blow a round and the
  bull *showboats* (snorts, struts — his Bust-a-Groove "solo section") while the round
  rewinds: *"El toro no está impresionado…"* Try again immediately. No violence in either
  direction — during the dance-off the bull throws nothing.
- **Win beat (identical in all three).** Meter full → music resolves → the bull performs
  a **bow** (one new animation every concept needs) → he steps aside and the matador
  walks free → hand-off to item 4's end scene (`Music.onboarding`, per CLAUDE.md).
- **Scoring hook (item 2).** Every judgment has a point value (¡Olé! 100 / ¡Bien! 50),
  phrase bonuses scale by round, boss-clear bonus on top — drops straight into the future
  scoring/Game Center work.
- **Engineering skeleton.** A `GamePhase` enum on `GameState` (`.arcade`, `.bossIntro`,
  `.bossFight`, `.victory`), with all boss logic in a new **`GameState+BossFight.swift`**
  (the house one-file-per-mechanic pattern). The dance state machine is pure state + the
  existing `update(currentTime:)` tick, so Swift Testing suites can step it
  deterministically like `GameStateTests` does today. For screenshots/tests, add a debug
  entry — `conjugar://game?boss=1` or a `CONJUGAR_GAME_START_BOSS` launch env var,
  mirroring `CONJUGAR_GAME_TIME_SCALE`.
- **New SFX** (Pixabay, per the established `asset-licenses/` pipeline): palmas clap,
  castanet click, crowd "¡olé!", bull snort, stomp thud. Reuse today's `chime`/`chirp`/
  `pop`/`buzz`/`randomApplause`. Consider porting the siblings' `HapticPlayer` — every
  judged input wants a tap.

**Animation budget reality check** (from `prompts/game_bull_actions.md`): dancer moves
are cheap — Mixamo's mocap library is full of dance clips (samba/salsa/house/jazz
families; flamenco-specific existence unverified, nearest clip gets hand-picked) and the
per-action FBX → `render_sprites.py` pipeline is proven. **Bull moves are hand-keyed**
on the DEF/FK bones (Path B), each new action roughly a `walk`/`throw`-sized effort. The
concepts below are ranked partly by how many bull actions they demand.

---

## Concept 1 — **La Llamada** (echo duel)

*Simon × Space Channel 5, in flamenco clothes. The bull dances a phrase; you dance it back.*

**The loop.** The bull stomps a llamada (screen shakes — Conjuguer precedent), then
performs a short sequence of moves. Each move is a bull animation burst plus a **big cue
icon** popping above him with a distinct SFX note. Then the spotlight slides to the
dancer — *"¡Tu turno!"* — and the player repeats the sequence. Correct move: her sprite
dances it, 🎵 pops, meter ticks. Wrong or too slow: `buzz`, the bull smirks, marker
slides back.

**The move vocabulary maps onto controls the player already knows.** During the boss the
D-pad has no ladders to serve, so its slots become the **dance pad**:

| Cue icon | Move | Input | Dancer anim | Bull demo anim |
|---|---|---|---|---|
| ⬅️ / ➡️ | paso (side-step) | left/right buttons | reuse `walk` burst | reuse `walk` burst |
| ⬆️ | ¡olé! pose (arms up) | up slot (now always visible) | new: `ole` (Mixamo) | new: **rear-up** (seed from `throw`'s reared head) |
| 🦶 | zapateado stomp | jump button (re-labeled) | new: `stomp` (Mixamo) | new: **hoof-stomp** |
| 🧣 cape | cape flourish | new button beside jump | reuse `cape` | reuse `throw` head-snap |

(The cape cue icon can literally be the existing `cape_pickup` sprite.)

**Rounds.** Three coplas: sequences of 3 → 4 → 5 moves, two phrases each, replay speed
rising. Round 3 twist: a 🔥 cue means **freeze** — input *nothing* for one beat
(Simon-says fake-out, and a wink at item 1's fireballs). Timing is generous
(~±0.4 s windows, no beat-lock) — it's a *memory* duel, with on-beat inputs earning
¡Olé! over ¡Bien! as gravy.

```
 ✕            💃 ●━━━━━◐━━━━━○ 🐂          ← Duende tug-of-war
                 ⬅  ⬆  🦶  ⬅               ← the bull's call, icon by icon
      🐂 (stomps, rears, struts)      🤵   ← matador watches
 ══════════════ el tablao ══════════════
              💃 ¡Tu turno!
        🌹 👏  ¡OLÉ!  👏 🌹                ← jaleo pops
      [⬆olé]
 [⬅paso][ ][➡paso]        (🧣cape) (🦶stomp)
```

**Asset budget.** Bull: 2 new hand-keyed actions (rear-up, stomp) + **bow** (shared) —
the heaviest bull ask of the three, and the reason this concept shines: the bull visibly
*dances*. Dancer: 2 new Mixamo actions (ole, stomp). Everything else is emoji + existing
sprites.

**Why it fits.** It's the strongest *duel* narrative (the track is literally called
"Spanish Guitar Standoff"); turn-taking suits the tension-and-release groove of the
42.7 s loop; difficulty scales by memory length with zero rhythm-precision risk; the
state machine is trivially unit-testable; and Space Channel 5 proved call-and-response
dancing carries a whole game.

**Risks.** Reads as "memory game" more than "rhythm game" (mitigation: on-beat bonus);
bull demo animations are the cost center — a v1 can lean on big cue icons + modest bull
bursts, then upgrade.

---

## Concept 2 — **Lluvia de Rosas** (falling-cue rhythm stage)

*A pocket DDR/Taiko: the crowd showers the stage and you catch the beat.*

**The loop.** The bull dances continuously on the left (one looping sway — his showboat).
From the top, the adoring crowd rains cues down **three lanes**: 🌹 roses (lane 1),
🎵 notes (lane 2), 👏 claps (lane 3), falling toward a glowing **stage line** above the
dancer. Tap the matching button as each cue crosses the line: ¡Olé! (tight), ¡Bien!
(loose), ¡Uy! (miss). Hit streaks tier up her dancing (sway → paso → full flourish, a
Bust-a-Groove enthusiasm ladder); misses make the bull smug. Occasionally a **🔥
fireball** falls in a lane — *don't* tap it (rest note; item-1 tie-in). Survive two loops
of the track with the Duende meter above the threshold.

**Controls.** Three thumb buttons in a row (replacing the D-pad during the boss):
🌹 / 🎵 / 👏 — or simply left / jump / right re-skinned, zero new gesture code.

```
 ✕            💃 ●━━━━◐━━━━━○ 🐂
        🌹        🎵        👏            ← cues falling in 3 lanes
        │         │         🔥           ← fireball: let it pass!
      🐂 (dancing loop)           🤵
 ═════════▂▂▂▂▂▂▂▂▂▂▂▂▂═════════       ← glowing stage line
              💃 (combo tier 2!)
         ¡BIEN!  ✨ x12 combo
      [ 🌹 ]   [ 🎵 ]   [ 👏 ]
```

**Beatmap & sync.** A hand-authored chart — an array of `(time, lane)` over the 42.7 s
loop (charted by ear; the short loop keeps it a lunch-break job, and density ramps per
loop). Sync comes from the *music*, not the frame clock: expose
`AVAudioPlayer.currentTime` as `SoundPlayer.musicPlayhead`, position each cue as a pure
function of `hitTime − playhead`, judge on that same delta — drift-free regardless of
frame jitter. Windows ~±0.15 s / ±0.35 s.

**Asset budget.** The lightest: bull needs only a looping sway (reuse `walk` in place +
`idle`, or one cheap new 2-frame head-bob) + shared **bow**; dancer gets 1–2 Mixamo dance
loops for the combo tiers; cues are pure emoji.

**Why it fits.** The most *musical* concept — the only one where the player literally
plays the song; instantly understood by anyone who's seen a rhythm game; naturally deep
scoring (combos, accuracy %) for item 2; endlessly re-chartable for replayability.

**Risks.** The bull is a bystander rather than an opponent (weakest duel framing);
hand-charting + timing-window tuning is real polish work; rhythm precision on a
`TimelineView` loop demands the playhead-sync discipline above (solved, but it must be
done right). Emoji cue readability at speed needs testing on small screens.

---

## Concept 3 — **El Tablao** (lit-floor footwork duel)

*Dance = footwork. The floor lights a path; answer it with your feet.*

**The loop.** The stage floor is **five big tiles**. The bull dances his llamada by
*walking his pattern* — tiles flash gold under his hooves in sequence, each with a stomp
thud. Then the floor dims and the dancer must **walk/jump the same path**, stomping each
tile in order before the compás runs out (a sweeping beat bar, not a twitch timer).
Correct tile: it blooms gold, 🎵 pop. Wrong tile or timeout: it flashes red, `buzz`,
round rewinds. This is Simon **with your feet** — which is exactly what zapateado is.

**Controls: none new at all.** Left/right walk and jump already exist; a stomp is
"arrive on tile" (auto) or "jump in place" for double-stomp tiles. The only UI change is
that up/down never appear (no ladders on the tablao).

**Rounds.** R1: 3-tile paths. R2: 4–5 tiles, one tile has a **planted flag** 🚩 you must
*jump over* mid-path (item-1 tie-in as terrain). R3: 6-tile paths with **double-stomp**
tiles (jump in place) and the bull dancing *simultaneously* on the same floor as a moving
obstacle to path around — a true shared-stage duel.

```
 ✕            💃 ●━━━◐━━━━━━○ 🐂
      🐂 ← his demo: walks 2→4→1,
            tiles flash as he stomps       🤵
 ═════[1]══[2]══[3]══[4]══[5]═════        ← the lit tablao
        ▲ gold=next  ▲ red=wrong  🚩=jump over!
              💃 (your turn — beat bar sweeping)
              ¡ESO! 👏
 [⬅]  [➡]                        ( 🦶 jump/stomp )
```

**Asset budget.** The cheapest: tiles are SwiftUI `RoundedRectangle`s with glow states;
both actors *reuse* `walk`/`jump` almost entirely; one new stomp accent each is optional
polish; shared **bow** for the win. Zero new buttons, zero new emoji beyond feedback.

**Why it fits.** Footwork-as-dancing is the most authentically *flamenco* mechanic of
the three; it reuses the platformer's movement physics and controls (the code the player
has practiced for five levels becomes the boss-fight skill); art cost is minimal; round 3's
shared-floor dance genuinely feels like two dancers negotiating a stage.

**Risks.** The least flashy — "walking on lit tiles" needs strong juice (glow, palmas
layer, screen shake) to read as *dancing*; five ~70 pt tiles is a spatially tight
performance space on a phone; the bull's demo is expressive only through pathing, not
through dance poses.

---

## Comparison

| | 1 · La Llamada | 2 · Lluvia de Rosas | 3 · El Tablao |
|---|---|---|---|
| Duel narrative ("dance-*off*") | ★★★ | ★ | ★★ |
| Musicality | ★★ (on-beat bonus) | ★★★ (plays the song) | ★★ (compás bar) |
| New controls to build | 1–2 buttons (pad morph) | 3-button row (reskin) | **none** |
| Bull animation cost | **high** (2 new + bow) | low (bow + optional bob) | low (reuse walk + bow) |
| Dancer animation cost | 2 new Mixamo | 1–2 new Mixamo | ~0 new |
| Code risk | low (pure state machine) | medium (playhead sync + charting) | low (reuses physics) |
| Scoring depth (item 2) | medium | **high** (combo/accuracy) | medium |
| Unit-testability | ★★★ | ★★ (needs playhead fake) | ★★★ |
| Wow factor | bull *dances* | screen full of rhythm | floor comes alive |

## Recommendation

**Concept 1 — La Llamada** — with a deliberate upgrade path. It's the truest to the brief
(a *dance-off* the bull can lose graciously), the track is literally a standoff,
call-and-response has the strongest pedigree for exactly this fantasy (Space Channel 5,
Bust a Groove), difficulty scales cleanly, and its cost center (bull dance animations) is
also its spectacle — the moment the bull visibly dances is the screenshot, the App Store
frame, and the blog-post hero.

Then graft the others in as evolution rather than alternatives:
- **Round-3 hard mode** can demand on-beat echoes — Concept 2's timing judgment inside
  Concept 1's structure.
- **El Tablao's lit tiles** make a great *level-5 gimmick* during the climb (the floor
  pulses under the bull's flags), keeping that idea without spending the boss on it.

If the bull-animation budget feels too rich for a first playable: ship La Llamada v1 with
big cue icons + modest bull bursts (walk/throw reuse), and upgrade his moves after the
mechanic proves fun — the state machine doesn't care which sprites play.

## Open questions for Josh

1. **Hearts during the boss** — hide them (meter is the only currency, retries free) or
   spend a heart per failed round (carries climb performance into the boss)?
2. **Bull v1 fidelity** — hand-key the two new bull dance actions up front, or ship the
   icon-led v1 first?
3. **New SFX pack** (palmas, castanets, olé crowd, snort, stomp) from Pixabay via the
   existing license pipeline — any objection?
4. **Boss debug entry** — `conjugar://game?boss=1` or launch-env var (or both)?
5. Should the dance-off's Spanish jaleo strings (¡Olé!/¡Bien!/¡Uy!/¡Tu turno!) stay
   Spanish in the English localization (flavor) or localize? (My vote: Spanish in both —
   it's a Spanish-learning app; the words are the lesson.)

## Sources

**In-repo:** `Conjugar/Models/Game/*`, `Views/GameView.swift`, `prompts/game.md`,
`prompts/game_bull_actions.md`, `docs/game_design_research.md`, `Models/Music.swift` +
`afinfo` on `Conjugar/Audio/spanishGuitarStandoff.mp3` (42.71 s); live drive of
`conjugar://game` (ios-build-verify). Sibling catalogs: Konjugieren
(`Models/Game/GameState+{Fussball,Bratwurstkette,Geisterstunde,Robot}.swift`,
`docs/bratwurst-icon-prompts.md`) and Conjuguer (`Models/Game/GameState+*.swift`,
`prompts/new-game-mechanics.md`, RobotBoss template).

**Web:**
- Bust a Groove mechanics: [Wikipedia](https://en.wikipedia.org/wiki/Bust_a_Groove), [Bust a Groove Wiki](https://bust-a-groove.fandom.com/wiki/Bust_A_Groove), [Hardcore Gaming 101](https://www.hardcoregaming101.net/bust-a-groove/)
- Space Channel 5 call-and-response: [Wikipedia](https://en.wikipedia.org/wiki/Space_Channel_5), [Space Channel 5 Wiki](https://spacechannel5.fandom.com/wiki/Space_Channel_5), [Hardcore Gaming 101](https://www.hardcoregaming101.net/space-channel-5/)
- Rhythm Heaven design (teach the beat, audio-first, simple inputs): [GamesRadar+ review](https://www.gamesradar.com/games/action/rhythm-heaven-groove-review/), [DualShockers review](https://www.dualshockers.com/rhythm-heaven-groove-review/), [TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/RhythmHeaven)
- Flamenco structure (compás/palmas/zapateado/llamada/jaleo): [Tablao Flamenco 1911](https://tablaoflamenco1911.com/en/flamenco-compas-and-rhythm/), [The Flamenco Guide](https://theflamencoguide.com/flamenco-compas/), [El Palacio Andaluz](https://elflamencoensevilla.com/en/palmas-in-flamenco/)
- Paso doble = the bullfight as dance: [Wikipedia](https://en.wikipedia.org/wiki/Pasodoble), [WikiDanceSport](https://www.wikidancesport.com/wiki/paso-doble/)
- Mixamo dance mocap availability: [Mixamo docs](https://helpx.adobe.com/creative-cloud/help/mixamo-rigging-animation.html), [Mixamo Dance Project](https://www.behance.net/gallery/66504927/MIXAMO-DANCE-PROJECT)
