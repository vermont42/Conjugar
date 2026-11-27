# Plan: Fix What the Pedagogy Review Found

**For:** a series of fresh Claude Code sessions, one phase per session as a rule. **Kind of work:**
quiz logic, the practice record, the quiz's views, analytics, staged privacy text, authored
Spanish content, tests, and prose. **Written:** 2026-11-27, in answer to
[`prompts/pedagogy_review.md`](../prompts/pedagogy_review.md). Josh answered its 23 decisions the same day, and each
answer is recorded under its decision.

This file is both the review and the plan. There is no separate review document, so the findings
are here in full: each has a label, its file and line, its evidence, how it was verified, and a
suggested fix. The phases at the end cite findings by label.

**Subject:** the code that [`plans/pedagogy_implementation.md`](pedagogy_implementation.md) built
from [`../Konjugieren/docs/pedagogy_research.md`](../../Konjugieren/docs/pedagogy_research.md), in
24 phases and a Closing, from `f263af3` (the commit before Phase 0) through `069b16c`.
**Reviewed at:** `2e5a74b`, so the review covers the code as it stands on `master`, including
what `a9637a0` (no quiz score), `c3bb034` (a kind for each quiz), and the rest of
[`verb_browse_fixes.md`](verb_browse_fixes.md) changed afterward. Nothing was fixed.
**Line numbers are those of `2e5a74b` and will drift as phases land, so find code by the type and
function each finding names.**

## Status

Each session that finishes a phase fills in its row, then writes a **How it differed** note under
that phase's heading. **Every phase waits for Josh before git.** A finished phase is "Awaiting
Josh", with the Commit cell empty, until he has tried the change and said to commit. The Commit
cell is filled only then.

**Josh answered all 23 decisions on 2026-11-27**, each under its heading in
[Decisions for Josh](#decisions-for-josh), so no phase waits on one. The last column names the
decisions a phase builds.

| Phase | Status | Date | Commit | Findings | Decisions it builds, all answered 2026-11-27 |
|---:|---|---|---|---|---|
| 1 | Not started | | | C1, C2, C10, C11 | D1 |
| 2 | Not started | | | L1, L2, L3, L4, C4 | D2, D3, D4, D5 |
| 3 | Not started | | | L5, L6, P7, and from G2 the schedule's comment and Mastery's intro | D6, D7 |
| 4 | Not started | | | L10, L11, L12, L13 | D8, D9, D10 |
| 5 | Not started | | | L7, L8, L19 | D11, D12, D13 |
| 6 | Not started | | | L14, L15, and from S4 what a level asks | D14, D15 |
| 7 | Not started | | | L9, L18, L21, C6 | D16, D17 |
| 8 | Not started | | | L16, and from T2 the challenge's pins | D18 |
| 9 | Not started | | | L17, L20, C3, C7, C8 | D19 |
| 10 | Not started | | | P1, P2, P3, P4, P6 | D20, D21, D22 |
| 11 | Not started | | | P5, G1, G2, G3, G4, G5 | None; Josh reads the staged text |
| 12 | Not started | | | C5, C12 | D23 |
| 13 | Not started | | | C9, A1, A2, A3, A4 | None |
| 14 | Not started | | | S1, S3, S4, S6, S8 | None |
| 15 | Not started | | | S2, S5, S7 | None |
| 16 | Not started | | | T1 to T9 | None |
| Closing | Not started | | | The audit | None |

## Verdict

The work is sound in its construction. The tree is green: `run_tests.sh` reports 1,499 Swift
Testing tests in 93 suites and 11 XCTest tests, in 79 seconds, in the simulator's language, which
is English (`en-US`). SwiftLint reports 0 violations in 353 files. The engine stayed `nonisolated`,
every random choice a quiz makes goes through its seeded generator, the authored content passes
its machine check, and no signal carries a score, an answer, a count of right or wrong answers,
or a verb the quiz drew. The phase notes are honest about what a session decided without asking,
which is what made most of these findings findable. One finding is a visible defect a learner can
reach in two taps ([C1](#c1)). None loses data.

What the review found is mostly of one kind, the same kind Konjugieren's review found, because
the port carried the designs. **Each feature was built to its phase, and several later phases
changed what an earlier one meant without revisiting it.** The re-ask was built before My
Mistakes existed. The second attempt was built for a typing slip and then given to grammatical
errors. The box of the ladder was built to schedule reviews and then read as mastery, as
achievements, and as the Speed Round's way in. Nine things deserve attention before the 2027
release, in this order:

1. **A quiz link that arrives over the results starts a quiz beneath them** ([C1](#c1)). The
   results stay on screen and list the new quiz's ten questions as missed. The quiz's own Live
   Activity, which lingers on the Lock Screen after a round, sends that link.
2. **My Mistakes is emptied by the quiz's own re-ask** ([L1](#l1)). A missed question returns
   three questions later with its answer just shown, and a right answer there takes the miss off
   the list.
3. **A real error, once repaired, counts as known** ([L2](#l2)). "tení", then "tuve" after being
   told tener is irregular in the pretérito, moves the item up the ladder.
4. **A review never asks the form that was missed** ([L3](#l3)). A miss on tengas or tuvieran is
   reviewed as tengo or tuve, a miss on era as soy, and a miss on pensamos as another verb's
   nosotros.
5. **Mastery can be reached without producing the conjugation** ([L4](#l4), [L5](#l5)): by
   answering tienes and ten for tengo, or by tapping Reveal on the review card twice.
6. **Opening a verb's page erases its mastery** ([L6](#l6)), from any screen, the correction's
   own link and the widget included.
7. **A third of Beginner rounds ask a command nobody gives** ([L7](#l7)): "(tú) ¡he!" of haber,
   "(ustedes) ¡existan!", "(tú) ¡puede!". Two in five Beginner questions are commands at all
   ([L8](#l8)).
8. **A signal can name the verb a quiz asks** ([P1](#p1)), for a quiz over any model that holds
   one verb, and the browse fix for a correction's link left a second path open ([P2](#p2)).
9. **A link can tear down a quiz running in a sheet** ([C2](#c2)) with no `quitQuiz`, which the
   next launch then reports as an abandoned quiz.

The rest is edge cases, staged prose that the code has made untrue, duplication, tests that prove
less than their names say, and two files that have grown past what one reader can hold.

## Method

I read `Quiz.swift`, `QuizQuestion`, `QuizScope`, `QuizLevel`, `QuizDraw`, `QuizDueItems`,
`QuizRecordSession`, the practice record (`PracticeRecord`, `ReviewSchedule`, `PracticeStore`,
`PracticeItemMapping`), `AnswerSlip`, `AnswerDiagnosis`, `Analytics.swift`, and the submit,
finish, and quit paths of `QuizView` myself. Six Opus subagents each reviewed one area
independently, with no view of my conclusions or of Konjugieren's review: grading and feedback;
levels, the draw, rounds, and practice sets; the practice record and what reads it; the new kinds
of question and their authored content; the daily features with an audit of every signal; and the
quiz's views and structure. I then ran or re-read the code behind every finding of theirs that I
ranked above Low. Each finding carries one of these labels, the four Konjugieren's review uses:

| Label | Meaning |
|---|---|
| **Run** | Confirmed by running code: two temporary probe suites (31 tests, since deleted), the app on "Conjugar iPhone 17", or a reviewer's Python over the bundled JSON and `verbModelMap.xml`. |
| **Read** | I traced it in the code myself. |
| **Reviewer** | A subagent reported it with file and line; I did not re-trace it. |
| **Suspected** | Plausible from the code, with the unchecked step named. |

What ran: the full suite and SwiftLint as a baseline; the probe suites, which drew about 1,700
rounds, graded about sixty wrong answers, drove quizzes through misses, re-asks, repairs, a quit
challenge, and a session across midnight, moved items through the record with injected dates,
measured a practice set's links and QR codes, and compared sixty days of the challenge in tú and
in vos; and the app, once, to finish a challenge and open a `quiz/start` link over its results.

Only after my own findings were written down did I read Konjugieren's review,
[`../Konjugieren/plans/pedagogy_fixes.md`](../../Konjugieren/plans/pedagogy_fixes.md), and check
each of its findings here. [Konjugieren's Findings, Checked Here](#konjugierens-findings-checked-here)
says which carried over in the port. All of its phases were "Not started" when I read it, so none
of its fixes had landed. A seventh subagent checked its test findings against Conjugar's tests.

**Not covered:** VoiceOver by ear, a real device, the iPad simulator, a Spanish-language device,
and a real day passing. The 741 sentences were checked mechanically and about a hundred were
read; the 45 choice items were all read. `GameCenterReal`'s threading was read only at its call
sites. The findings labelled Suspected name the step nobody took.

**What the review left behind.** The probe suites are deleted. The run in the app left "Conjugar
iPhone 17" with five misses in its practice record and today's Beginner challenge taken.

## What Holds Up

So that a later session knows what was examined and found sound:

- **Grading.** The accepted answers are expanded and the learner's answer is never folded, so a
  misspelling cannot pass. Case, spacing, and composed against decomposed accents never count (Run:
  "hablo" with a combining accent is habló). Only the asked person's pronoun is stripped, and
  nothing before a command. ñ is strict. The two imperfect subjunctives are kept apart outside a
  sentence, and the swap is named ("That is the -se form. The -ra form was asked."). vos variants
  reach only vos questions. A question gets one second attempt at most.
- **The ladder.** A right answer climbs only when due, so nothing climbs twice in a day. A wrong
  one restarts. Due dates use calendar days, so a daylight-saving change cannot move one. No item
  can be stranded: an item the level will not ask still reaches Review.
- **The re-ask's bookkeeping.** A miss returns once, never twice, and `questionReached` and
  `questionCount` exclude re-asks, so the Closing's privacy check holds.
- **The seed.** No unseeded `.random`, `.shuffled()`, or `randomElement()` is on any quiz path,
  and no `Set` or `Dictionary` order reaches a seeded draw: `QuizDraw` sorts its classes first.
- **The draw's floors.** Half the drawn questions are irregular, exactly; at least two ask a core
  verb; the rare-compound rule holds; regular verbs take the endings in turn.
- **Ranking.** What posts is the first ten questions of a default quiz's first round, to the
  level fixed at the start. The leaderboard and achievement identifiers and points match
  `GameCenterResources.gamekit`.
- **The streak's logic**, traced through consecutive days, a missed day with one and with two
  sessions, two missed days, and a 25-hour day.
- **Analytics.** See [Privacy](#privacy). Decision 5 holds at HEAD, and the staged policy covers
  every signal, key, and value in English and Spanish but for [P5](#p5).
- **Content.** 741 sentences and 45 choice items load. No duplicate identifiers, sentences, or
  English lines; every code valid; every ¿ and ¡ paired. The machine checks run, compare every
  blank with the engine in tú and in vos, and are guarded against an empty file.
- **The browse fixes in this code.** `viewCollection` drops `collection` after a correction, the
  kinds pin what ranks, and every test's `Quiz` has its own `PracticeStore`. One of those fixes is
  incomplete ([S3](#s3)) and one left a second path open ([P2](#p2)).

## Findings

Severity is my judgment: **High** is wrong behavior a learner would meet or a promise broken,
**Medium** is wrong in an edge case or a real hazard for maintenance, and **Low** is tidying.

## What the Learner Is Taught

These are the places where a built feature undercuts the aim its suggestion stated, judged
against Spanish.

<a id="l1"></a>
### L1. A right re-ask takes the miss out of My Mistakes (Run, High)

`PracticeRecord.recordAnswer` (`Shared/PracticeRecord.swift:146-152`) sets
`entry.lastAnswerWasRight = isCorrect` on every answer, and `missedItems()` (`:195-207`) keeps
only entries where it is false. `Quiz.process(proposedAnswer:)` (`Quiz.swift:820-834`) records
each answer and then inserts a re-ask of every missed question, `Quiz.reaskGap` questions later
(`VerbEssentials.reaskPlacement`, `VerbEssentials.swift:173`), and the re-ask's answer is recorded
like any other.

The probe missed the first question of a quiz, tener's ustedes command. `missedItems()` held
`key:tener:yo_presente`. It answered the rest right, the re-ask among them, and `missedItems()`
was empty. So a learner who finishes her rounds finds My Mistakes almost always empty: only a miss
whose re-ask is also missed, a quit before the re-ask, or a challenge question stays. The worst
case is the round's last question, whose re-ask is the very next thing asked (Run: question 10
missed, question 11 its re-ask), one tap after the correction showed the answer.

T3.2's rule is "an item leaves the list once answered right". Phase 10's note says "a re-ask is
another answer", Phase 11's says the rule, and nobody tried the two together:
`QuizRecordSessionTests`' test of a mistake leaving involves no re-ask.

**Fix.** Tell `recordAnswer` what kind of answer it records. A right re-ask, and a right second
attempt ([L2](#l2)), leave `lastAnswerWasRight` alone. See [D2](#d2).

<a id="l2"></a>
### L2. A diagnosed error, once repaired, counts as right in the record (Run, High)

`Quiz.process` gives a second attempt to a slip or to any diagnosed error (`Quiz.swift:786-796`),
and the final answer is recorded with `isCorrect: result != .noMatch` (`:822`), with no word of
how it was reached. `PracticeStore.recordAnswer`'s comment (`PracticeStore.swift:153-154`) gives
Phase 10's reason: "a slip's right second attempt counts as right, since one letter was all that
stood between the learner and the conjugation." Phase 13 then routed every diagnosis through the
same second attempt, and the comment is no longer the whole truth.

The probe typed "tení" for tener's yo pretérito, was told "That is the regular form, but tener is
irregular in the Pretérito. Try once more.", and typed "tuve". The item went to box 1 with
`lastAnswerWasRight == true`, and nothing reached My Mistakes. With the item due in box 1, the
same exchange would have made it mastered. Every class of diagnosis takes this path: the regular
form, a missing stem change, another tense, another person, the other imperfect subjunctive.

`docs/feature_architecture.md:754` and `:760`, and the plan (`:1782`), still say only that a
slip's second attempt is right.

**Fix.** Record a repaired diagnosis as something other than right. See [D3](#d3). Correct the
comment and the two doc lines either way.

<a id="l3"></a>
### L3. A review never asks the form that was missed (Run, High)

One key conjugation stands for dozens of cells: `PracticeItem.Key.init(tense:)`
(`PracticeItemMapping.swift:121-136`) sends the whole presente, the presente de subjuntivo, both
imperatives, and the imperfecto to the yo presente. A review of the item, in Review, in My
Mistakes, and among the default quiz's due items, asks the first askable irregular cell built on
the key, and `Key.cells` puts the key's own cell first (`:140-147`; `QuizDraw.recordQuestions`,
`QuizDueItems.swift:51`). The record keeps no note of which cell was missed.

The probe recorded four misses and asked My Mistakes what it would ask:

| Missed | The item | What My Mistakes asks |
|---|---|---|
| tengas (presente de subjuntivo, tú) | `key:tener:yo_presente` | yo tengo |
| era (imperfecto, él) | `key:ser:yo_presente` | yo soy |
| tuvieran (imperfecto de subjuntivo) | `key:tener:yo_preterito` | yo tuve |
| pensamos (presente, nosotros) | `pattern:presente_de_indicativo:fp:ar` | ganar, nosotros |

The learner then answers tengo, which she knows, the mistake leaves the list, and tengas is never
asked again by anything that remembers it. The last row is the boot error: "piensamos" for
pensamos is diagnosed well at the moment ("In pensar, the stem does not change here."), but
pensamos is a regular cell, so the miss is filed under a pattern and reviewed on a wholly regular
verb. That pensar keeps its stem in nosotros is not revisited.

Josh accepted the mapping on 2026-11-22, "accepting that a slip in tienes counts against tengo".
That sentence is about what a miss counts against. What a review then asks was decided in Phase
10's session, to solve a different problem (a key whose own cell is regular), and the consequence
above is in no note.

**Fix.** An optional field on `PracticeRecord.Entry` for the cell last missed, and for a pattern
the verb. Review and My Mistakes ask that cell where the settings allow it, and otherwise draw
among the irregular cells built on the key, as `speedRoundCells` already does, in place of always
the key's own. See [D4](#d4).

<a id="l4"></a>
### L4. An answer credits a key conjugation it never showed (Run, Medium)

The other side of [L3](#l3). Every irregular cell built on a key raises it when answered right.
The probe answered tienes on day 1 and the tú command ten on day 4: `key:tener:yo_presente` was
mastered, in box 2, and the learner never wrote the g of tengo. era on day 1 and eran on day 4
mastered ser's yo presente, which is soy. Mastery, the Speed Round's entry, and the achievements
all read that box.

**Fix.** See [D5](#d5). The option I would choose is Konjugieren's: a wrong answer on any cell
built on the key still sends the item back, and a right one raises it only on a cell that shows
what the key shows, judged by comparing the letters the engine marks irregular in the two forms.

<a id="l5"></a>
### L5. Revealing the review card twice masters a verb never typed (Run, Medium)

`VerbBrowseReviewCard.reveal()` (`VerbBrowseReviewCard.swift:103`) calls
`PracticeStore.recordReview`, which moves every due item of the card up a box
(`ReviewSchedule.reviewed`, `Shared/ReviewSchedule.swift:44-47`). There is no step at which the
learner says whether she knew them.

The probe looked tener up on day 1, revealed its card on day 2, and revealed it again on day 5.
All three of tener's key conjugations were mastered and among the Speed Round's items, and a
reviewer reports that achievement progress is sent on each reveal. Phase 16 decided that
recognizing a form "is no evidence of producing it" and moves nothing. A reveal is weaker
evidence than that. The card's rule comes from browse Phase 15, before the box meant anything but
a due date.

**Dismissing the card hides its items from today's Review** (Run). `dismiss()` (`:120`) snoozes
an unrevealed card's due items to tomorrow. The probe had three items due, dismissed the card,
and had none: they left today's Review count and today's daily session too.

**Fix.** See [D6](#d6).

<a id="l6"></a>
### L6. Opening a verb's page erases what the quiz recorded about it (Run, Medium)

`VerbView.send(_:)` (`VerbView.swift:211-218`) calls `Current.practice.recordLookup` for every
visit whose source is not `resume`, and `PracticeStore.recordLookup` (`PracticeStore.swift:165-172`)
sends all of the verb's key conjugations back to the first box unless the source is the review
card. The probe put tener's yo presente in box 3 and opened the page from a correction, the
widget, a related verb, and search: box 0 each time.

"A lookup suggests the verb was forgotten" was set for the browse plan, before anything read the
box as mastery, and the browse review recorded the widget's case as a cost of that decision. The
consequences as built:

- A mastered verb opened to read its etymology, or because the widget showed it, loses its
  mastery, leaves the Speed Round (which can lock again below five items), and needs two right
  answers a key over four or more days to return.
- A miss of tuve already resets that key. Tapping the correction's own link to the verb then
  resets tengo and tendré as well.
- Test Me can never promote. Opening the page puts the items in box 0, due tomorrow, so three
  right answers find nothing due and change nothing.
- A learner who consults a verb more often than its interval can never master it.

**Fix.** See [D7](#d7).

<a id="l7"></a>
### L7. The quiz asks commands that nobody gives (Run, Medium)

Nothing in the draw knows that some verbs are not commanded. `QuizDraw.coreVerbs`
(`QuizDraw.swift:30`) holds haber, the draw guarantees two core questions a round, and every
command cell takes any verb of the band. At Beginner two of the pool's five weights are the
imperativo positivo ([L8](#l8)).

The probe drew 200 Beginner rounds in the Latin America region. **66 of them, a third, asked a
command of haber, poder, deber, parecer, existir, querer, saber, ocurrir, or resultar.** The
commonest were haber's: "(tú) ¡he!" 16 times, "(ustedes) ¡hayan!" 12, "(usted) ¡haya!" 7. Others:
"(usted) ¡deba!", "(tú) ¡puede!", "(ustedes) ¡existan!", "(tú) ¡parece!", "(usted) ¡ocurra!". The
first question of the round I started in the app to check [C1](#c1) was "haber, imperativo
positivo, 3S". The daily challenge and the quiz widget draw through the same `QuizDraw`, so they
inherit it.

The research report criticized Conjuguer for exactly this ("it can ask for the imperative of
faillir and for persons of falloir that do not exist"). Phase 4 foresaw restricted cells ("the
generator must draw a verb that fits the cell") and decided only the condicional's.

Spanish is not German here. The engine already knows the truly defective verbs (abolir, llover),
and forms such as sepa and quiera are real commands ("sepan que…"). The list is one of usage, and
it is Josh's to rule on.

**Fix.** A list of verbs whose commands the quiz does not ask, honored wherever a question is
drawn (`QuizDraw.questions`, `recordQuestions`, the Speed Round's draw, and so the challenge and
the widget), and haber out of the core role in a command cell. See [D11](#d11).

<a id="l8"></a>
### L8. The weights do not follow use within a level (Run, Medium)

`QuizPoolEntry.weight` (`QuizLevel.swift:162-172`) is fixed per tense at every level. What a
learner meets, against the shares `docs/tense_frequency.md` measured:

| Level | What the weights give | Measured |
|---|---|---|
| Beginner (presente 3, commands 2) | Commands are 40% of every round (Run: 811 of 2,000 questions) | The imperativo positivo is 1.2% of verb words, the presente 42.9% |
| Intermediate (total weight 23) | Commands are 4 of 23, 17%. The imperativo negativo weighs 2, as the presente de subjuntivo and the futuro do | The imperativo negativo is 0.1% |
| Advanced (total 34; Run over 900 questions) | The two imperfectos de subjuntivo are 11%, against the presente de subjuntivo's 6%. The nine compound tenses are 27%. The futuro de subjuntivo, its perfecto, and the pretérito anterior are 8% | The two imperfectos de subjuntivo are about 2.4% together, the presente de subjuntivo 9.4% |

Josh chose the weights on 2026-11-23, and Phase 4's note records a Beginner quiz of "eighteen
presentes and twelve commands". What the note does not weigh is that a level with two tenses
turns a weight of 2 into two questions in five. The two imperfectos de subjuntivo are one tense
written two ways, and each takes a tense's weight. Phase 4 also records that the *Plan curricular
del Instituto Cervantes* was never checked, because its site was down that day ([G4](#g4)).

**Fix.** See [D12](#d12).

<a id="l9"></a>
### L9. Verb Essentials and Verb Models never ask where the -ir stem changers are irregular (Run, Medium)

`VerbEssentials.questions(for:)` (`VerbEssentials.swift:36-38`) asks the four key cells, and
`ModelPracticeGroup.items` (`ModelPractice.swift:38-48`) keeps a key only when its own cell is
irregular. For pedir, seguir, sentir, dormir, servir, morir, construir, and oír the yo pretérito
is regular (pedí, dormí, construí). The probe:

- Verb Essentials asks pedir for pido, pedí, pediré, pedido. The pedí blank records
  `pattern:preterito:fs:ir`. pidió, pidieron, pidiera, and pidiendo are never asked.
- A model's "known" counts only the yo presente for these models: the group items of pedir's
  model are `key:pedir:yo_presente`, `key:servir:yo_presente`, and so on. The mixed round
  therefore cannot tell sentir's model from pensar's.
- A lookup of pedir does schedule `key:pedir:yo_preterito`, and the review card and Review ask
  it as pidió (`PracticeItem.irregularCells(of:builtOn:)`), so the record already knows the item.
  No exercise moves it.

The browse review's G2 corrected the comment that claimed the yo pretérito carries these verbs'
subjunctives. This is that fact's consequence in the two exercises built on the four forms.

**Fix.** Keep the four-form line where it is shown and shared. In the exercises, when a key's own
cell is regular for the verb and an irregular cell is built on the key, ask the first such cell
(él pidió), with the row naming the person, and count that item in the model's group. See
[D16](#d16).

<a id="l10"></a>
### L10. The slip rule calls some grammatical errors typing slips (Run, Medium)

`QuizQuestion.isSlip` (`AnswerSlip.swift:42-55`) calls an answer a slip when it is one edit from
an accepted spelling and is not another cell of the verb. In Spanish most real errors are caught
first by a diagnosis: the probe typed 36 classic errors, and pedió, dormió, podiendo, conoco,
siguo, empezé, quereré, ponido, tenes, and piensamos were each named. Four kinds get through as
"Almost! Try once more.", and under [L2](#l2) a repaired slip is a right answer in the record:

- **The j-stem pretérito.** dijieron for dijeron, trajieron, tradujieron. That these verbs take
  -eron is the rule being learned, and the error is one inserted letter.
- **The analogical -s.** hablastes for hablaste.
- **The y of oír and its kin.** oies for oyes. `endingIBecomesY` is diagnosed for leió and not
  here.
- **The four-letter minimum counts the frame's words.** `AnswerSlip.isSlip` (`:29`) counts the
  letters of the composed answer, "no" and a reflexive pronoun included. "ds" typed into
  `(tú) ¡no [ ]!` for no des is a slip, though the learner wrote two letters and "sot" for soy is
  refused for being too short.

Three smaller holes nearby (Run): a grave accent is not an accent ("sè" for sé is not a slip,
because `bareMarks` lacks U+0300); a trailing period is a wrong letter ("soy." goes to the
correction, since `AnswerFrame.framePunctuation` trims only ¡ ! ¿ ?); and "no arrepientas" typed
into `¡no te [ ]!` is composed as "no te no arrepientas", wrong at once, though "no hables" typed
into `¡no [ ]!` is right.

**Fix.** The minimum counts the blank's own letters, the auxiliary of a compound included and
the frame's words not. Add the grave accent and strip a trailing period. The first three need
new diagnosis lines or a ruling: see [D8](#d8).

<a id="l11"></a>
### L11. A reflexive-only verb's command is right without its pronoun (Run, Medium)

`QuizQuestion.shownSpellings` (`QuizQuestion.swift:106-111`) accepts a reflexive-only verb's form
with or without its pronoun. For a finite cell and a negative command the frame supplies the
pronoun, so the bare form cannot even be typed. The affirmative command's frame supplies nothing
(`AnswerFrame.quizFrame`, `AnswerFrame.swift:165-166`), so there the rule accepts a form Spanish
does not have. The probe:

- atreverse, tú command: "atreve" earns 10 points. So do "queja" and "arrepiente".
- "atrevte", a typo of either, is corrected to "atreve", because `difference(from:)` shows the
  nearest accepted spelling. The correction teaches the wrong form.

These verbs are asked: atrever ranks 406, quejar 590, arrepentir 818. The bare gerund
(arrepintiendo) is fine, since me estoy arrepintiendo is Spanish. The variant audit's row 13
rests on "the quiz asks no pronominal verb", which was true when it was written.

**Fix.** In `shownSpellings`, add the bare form only where the frame supplies the pronoun or the
form is a gerundio. See [D9](#d9).

<a id="l12"></a>
### L12. Some diagnoses name the wrong lesson (Run, Low)

Phase 13's rule was "a wrong diagnosis is worse than none". None of these lines is false. Each
points away from what the learner needs.

- **dice, tiene, viene for the tú command.** `AnswerDiagnoser.regularForm()`
  (`AnswerDiagnosis.swift:258-268`) builds the regular form from a model with no features, which
  for decir is "dece". So "dice" for di gets "That is the form of the Presente de Indicativo
  (él).", while "hace" for haz and "pone" for pon get "That is the regular form, but hacer is
  irregular in the Imperativo Positivo." It is one error, the textbook rule that the tú command is
  the él presente. The doc comment on `diagnosis(of:)` (`:96-99`) and
  `docs/feature_architecture.md:993` both say dice gets the regular-form line.
- **A dropped accent that lands on a rare tense.** "hablare" for hablaré gets "That is the form
  of the Futuro de Subjuntivo.", at Elementary, which never shows that tense. "hablara" for
  hablará gets "That is the form of the Imperfecto de Subjuntivo 1." The lesson is the accent.
- **"esta" for está** gets "That is the regular form, but estar is irregular in the Presente de
  Indicativo." The learner dropped an accent.

**Fix.** In `regularForm()`, also count the form built with only the spelling and stem-vowel
features as regular. For the accent cases, see [D10](#d10).

<a id="l13"></a>
### L13. "vayamos" is marked wrong for ir's nosotros command (Run, Low)

The engine gives ir's nosotros command as vamos. The probe typed "vayamos" and was told "That is
the form of the Presente de Subjuntivo." Both are standard as the exhortation, and the negative
is no vayamos. `plans/pedagogy_variant_audit.md` did not cover it. Phase 0's aim was to stop
marking correct Spanish wrong.

Also for a ruling: "que hable" typed for a presente de subjuntivo is wrong at once, with no
second attempt, though many courses drill the subjunctive behind que. A subject pronoun in the
same place is forgiven.

**Fix.** See [D10](#d10).

<a id="l14"></a>
### L14. A round can ask the same question twice (Run, Medium)

Two paths, and two neighbors.

- **Due items.** `Quiz.draw` (`Quiz.swift:464-466`) draws the due questions and the mixed
  questions apart, and neither knows of the other. With three core verbs due at Beginner, the
  probe found the same verb, tense, and person twice in 21 of 200 rounds. The second asking is
  trivial, and if the first was wrong it clears the mistake ([L1](#l1)).
- **Small scopes.** `scopedQuestions` fills a round of ten by repeating
  (`allowingRepeat: true`, `Quiz.swift:599`). A collection's quiz over ser's model, one verb, at
  Beginner repeated a question in 50 of 50 rounds, and so did abolir's model of four verbs. A
  re-ask can add a third asking.
- **The last question's re-ask comes next** (Run). `reaskPlacement` is
  `min(index + 1 + reaskGap, questions.count)`, so a miss on question 10 is re-asked at once, and
  on question 9 after one other. That follows the design, re-asked before the results, and for
  those two questions it tests only what the correction just showed.
- **Submitting the same answer again spends the second attempt** (Read). After "Try once more.",
  Check stays enabled and Return still submits (`QuizView.swift:859-871`), and `Quiz.process`
  grades the unchanged text as the second attempt (`:786-801`). A double tap goes straight to the
  correction and a re-ask.

**Fix.** Draw without replacement over verb, tense, and person within a round, the due items
included, and across a session's rounds while unasked questions remain. Ignore a second attempt
equal to the first, with the line announced again. What a scope with fewer than ten distinct
questions does is [D14](#d14).

<a id="l15"></a>
### L15. What a ranked round holds (Run for the mix, Read for the rest; Low)

- **The mix is promised for ten and made for nine.** From Elementary up every default round has a
  choice question, so the mixed draw is nine and `cells.count / 2` is four. The probe's 200 rounds
  a level: Beginner has five irregular questions of ten, and the other three levels have exactly
  four of nine typed questions, every round. `docs/feature_architecture.md` § Quiz says the counts
  are exact "at thirty questions or ten", and `QuizVerbMixTests.aTenQuestionQuizMixesToo` accepts
  half "rounded either way". Due items take up to three more slots outside the mix.
- **A ranked round mixes in the learner's own due items.** `QuizScope.mixesDueItems` is
  `isRanked` (`QuizScope.swift:188-190`). A learner with three items due answers three of her own
  weak points in the round that posts to the level's board and sets her best, while
  `mixesChoiceQuestions`' comment says the choice is there "so that every ranked round of a level
  asks the same mix".
- **A choice of two is 10 of a ranked round's 100 points**, from about fifteen items a level and
  region, with nothing remembered across sessions.

**Fix.** See [D15](#d15), then correct the doc to say what holds.

<a id="l16"></a>
### L16. The daily challenge is not taken once, and not the same for everyone (Run, Medium)

- **A quit challenge can be taken again with its answers seen.** `PracticeStore.recordChallenge`
  is called only from `Quiz.finish()` (`Quiz.swift:1000-1002`). The probe answered four of five
  questions wrongly, each correction showing its answer, and quit. Nothing was kept, the second
  start asked the same five in the same order, and the shared text then reports 50 of 50. The
  string under the row says "Take it once". Phase 23's session decided this without asking.
- **A vos learner's challenge is easier.** `DailyChallenge.questions(for:secondSingular:)`
  (`DailyChallenge.swift:155-163`) turns a tú cell into the same verb's vos cell, and the draw's
  balance is made for tú. vos forms of stem changers and of the short commands are regular
  (incluye and incluí, haz and hacé, atente and atenete). Over sixty Beginner days from
  2026-11-24 the probe found the two challenges differing in irregular questions on 29 days, and
  on 26 the vos challenge had fewer than the two irregular questions the tú one always has. At the
  other levels it is 5 to 7 days in 60. Two friends then compare scores over different questions.
- **Tomorrow's can be previewed.** `DailyChallengeRequest` (`:319-344`) accepts any date, so a
  hand-made link opens tomorrow's challenge and marks it taken (Run).
- **Twelve results.** `recordChallenge` keeps the last twelve (`PracticeStore.swift:146`). Twelve
  challenges opened from links push today's out, and today's can then be taken again. The
  comment on `challengeResults` says forgetting one "would let its challenge be taken again"
  (Reviewer).
- **A stale row.** `QuizView.challengeRow` (`:615-630`) computes the key when the hub renders and
  its button captures it. Left open across midnight, the row starts yesterday's challenge (Read).
- **Across versions.** The draw uses the standard library's sampling over the verb list, so two
  app versions can draw different challenges for one link. `DailyChallenge.draw`'s comment and
  `docs/feature_architecture.md:1753` say so. The link does not, and the string says "the same
  for everyone today".

**Fix.** See [D18](#d18).

<a id="l17"></a>
### L17. The Speed Round's clock counts ticks, not time (Read; the scrolling part Suspected, Medium)

`Quiz.startTimer` (`Quiz.swift:1074-1081`) schedules a repeating one-second `Timer`, and
`clockTicked` adds one to `elapsedTime` (`:1085-1093`). The round ends when sixty ticks have
arrived.

- **Leaving the app pauses the minute** (Read). Nothing in `QuizView` watches the scene's phase.
  A suspended app's timer does not fire, so a learner who leaves to look an answer up comes back
  to the same second.
- **Scrolling** (Suspected). `Timer.scheduledTimer` runs in the run loop's default mode, which
  does not fire while a scroll view is being dragged, and the question sits in a `ScrollView`
  (`QuizView.swift:793-794`). The unchecked step is holding a finger on the card during a round
  and watching the time left.
- **The model starts a round with too few items** (Run). `SpeedRound.minimumMasteredCount` is
  enforced only by the hub's row. `Quiz.start(scope: .speedRound())` started with three.
- **Every quiz redraws once a second** (Reviewer). `.onChange(of: quiz.speedRoundSecondsLeft)`
  (`QuizView.swift:166`) reads `elapsedTime` in `body` for every kind of quiz, with the clock
  hidden too.

**Fix.** Keep a deadline as a `Date` read from the injected clock, and let the timer only refresh
the display, in the common run-loop modes. Enforce the minimum in `Quiz.start`. What leaving the
app should do is [D19](#d19).

<a id="l18"></a>
### L18. Complete the Sentence names the tense, so the sentence need not be read (Read, Medium)

`QuizView.questionCard` (`:1043-1050`) shows the tense under the verb for a sentence, and
`answerSection` (`:984-990`) shows the English line from the start. "Quiero que me [ ]" with
"decir · presente de subjuntivo" can be answered without reading quiero que. The plan's own case
for T5.5 in Spanish was that a subjunctive trigger is a sentence's whole reason for its tense.
The sentence still decides the person and gives the verb a meaning. Phase 18 holds a choice
question's English until the choice, because English aspect gives the answer away. Here the
English is harmless only because the tense is already shown.

Hiding the label is not free: a reviewer found blanks that then admit a second tense (anunciaría
or anunciará), so it needs a flag or alternates per sentence.

**Fix.** See [D17](#d17).

<a id="l19"></a>
### L19. Advanced draws nearly half its verbs from beyond the 1,000 most frequent (Run, Low)

`QuizLevel.advanced.band` is nil, every verb, and `QuizDraw` draws uniformly within a band. Of 900
Advanced questions the probe drew, 421 asked a verb ranked beyond 1,000 and 175 one beyond 3,000:
desmoralizar, detraer, agriar, pormenorizar, retrotraer. A learner migrated from Difficult, which
drew from curated common verbs, now meets these in half her questions. T2.1's aim was to draw
from what is used. The ladder gave Advanced "the whole corpus, by choice", and the choice of a
uniform draw over it was not weighed.

**Fix.** See [D13](#d13).

<a id="l20"></a>
### L20. Two lines promise a review the learner will not get (Reviewer, Low)

- **The reminder.** `DailyReminderPlan.reminders` (`DailyReminder.swift:73`) counts every due
  item the settings allow: "Your daily session is ready, with 30 conjugations due for review."
  The daily session asks only due items the level asks and the band holds, ten at most
  (`Quiz.draw`, `:459-462`).
- **The Review row.** "The next review is tomorrow" comes from `PracticeRecord.nextDue(after:)`
  (`:210-212`), over every entry. The count beside it filters by `QuizDraw.canAsk`. A vosotros
  pattern missed in Spain, with the region since set to Latin America, makes the row promise a
  review that tomorrow is empty.

**Fix.** One function answers "would this session ask this item", and both lines count with it.

<a id="l21"></a>
### L21. Small points in the authored content and its screens (Low)

- **`querer.imperfectoDeSubjuntivo1.1`** (Run). "Buenas noches, {quisiera} una mesa para dos, por
  favor." accepts "quisiese" for full points, because a sentence accepts either imperfect
  subjunctive (`QuizQuestion.shownSpellings`, `:119-124`). The courtesy quisiera does not
  alternate with -se. A reviewer's script found it is the only -ra sentence with no trigger
  before its blank.
- **`pretender.pluscuamperfectoDeIndicativo.1`** (Reviewer). "Yo {había pretendido} llegar
  temprano, pero había mucho tráfico." A speaker would say pretendía.
- **`Choice.reasonNegativeCommand`** (Read) is circular: "A negative command takes the imperativo
  negativo, never the presente de indicativo." The diagnosis line says it better: negative
  commands use the subjunctive.
- **A choice's row in the results** (Reviewer). `Quiz.submitChoice` (`:935-936`) stores the
  chosen form without the frame's words and the right one with them, so the row reads "Your
  Answer: hablas · Correct Answer: no hables", and shows neither sentence. A sentence's row names
  "Imperfecto de Subjuntivo 1" (`ResultsView.swift:321`) where the card said imperfecto de
  subjuntivo and -se was accepted.
- **Name the Form shows the red letters** (Reviewer). The prompt is the engine's marked form, so
  it tells the learner that the form is irregular and where, which a reader never sees.
- **The pools are thin at the bottom** (Script). At Beginner 76 of 100 verbs have one sentence,
  and at Elementary 199 of 299. A level and region have about fifteen choices. The next batch
  should lean there.
- **Phase 18's note** says three choice items are second person. Four are.

## Correctness

<a id="c1"></a>
### C1. A quiz link over the results starts a quiz beneath them (Run, High)

`QuizView`'s handler for `router.pendingQuizStart` (`QuizView.swift:124-131`) calls
`startQuiz(scope:)` whenever no quiz is in progress. `startQuiz` (`:1250-1262`) resets
`navigationPath` and never sets `showingResults = false`, and the results are pushed with
`.navigationDestination(isPresented: $showingResults)`, which is not part of the path. The daily
session's and the challenge's handlers both check `showingResults` and call `startFromResults`.
This one does not.

In the app: I finished a challenge, and on its results ran
`xcrun simctl openurl 6318CA93-7FB5-4E19-B318-915010531F76 conjugar://quiz/start`. The gun
sounded and the results stayed. They now read "Correct: 0 / 10" over ten rows, each a red ✕, each
naming a question of the quiz that had just started underneath with its clock running:
`ResultsView.resultRow` (`ResultsView.swift:289-291`) takes an unanswered question for a miss.

A learner reaches this in two taps. The quiz's Live Activity ends with the default dismissal
policy (`LiveActivitiesReal.swift:41`), so it stays on the Lock Screen for up to four hours after
a round, and its `widgetURL` is `quiz/start` (`QuizLiveActivity.swift:56`). The Quick Quiz
control and the Start a Quiz shortcut send the same link.

**Fix.** Route `pendingQuizStart` through `startFromResults` when the results are up, as the
other two handlers do. Better, one pure function decides what each of the three requests does
given the quiz's state, the results, and a taken challenge, with a test. See [C10](#c10) for the
activity.

<a id="c2"></a>
### C2. A link can tear down a quiz running in a sheet (Run for the router and the model; the dismissal Read, Medium)

`QuizSheet`'s comment (`QuizSheet.swift:13-15`) and `docs/feature_architecture.md` § Test Me say
that every quiz started in the sheet "ends with `quitQuiz` or `completeQuiz`".
`interactiveDismissDisabled` stops only a swipe. Three paths end one without either:

- **A practice set.** `AppRouter.handle(url:)` (`AppRouter.swift:138-139`) clears
  `pendingPracticeSet` for any link that resolves, which dismisses the set's sheet
  (`MainTabView.swift:121`) and the quiz sheet nested in it (`PracticeSetView.swift:62-66`). The
  probe confirmed the router's half: a `verb/hablar` link cleared a waiting set. A reminder's tap
  or a widget does the same to a student mid-question.
- **A model's practice from the hub.** The sheet is hosted by `ModelPracticeCard`
  (`ModelPracticeCard.swift:93-95`) inside `ModelPracticeListView`, which is pushed on the Quiz
  tab's path. A `quiz/start` or `quiz/daily` link makes `startQuiz` reset that path (`:1261`),
  which pops the sheet's host.
- **Test Me on another tab** (Suspected). A `quiz/start` link switches to the Quiz tab and starts
  its quiz, with gun, clock, and Live Activity. Whether SwiftUI keeps the other tab's sheet up
  across the switch is the unchecked step.

What is left behind (Run): the probe dropped a started quiz without quitting it. Its
`QuizAbandonment` entry stayed, so the next launch sends `abandonQuiz` as though the app had been
left, and its clock was still running. `Quiz` has no `deinit`, so nothing ever invalidates the
repeating timer.

Josh decided on 2026-11-24 not to fix the reverse case, a set's link dropped while another sheet
is up. These were not part of that decision.

**Fix.** See [D1](#d1). Whatever he chooses, a quiz in a sheet that goes away while in progress
quits properly (`quitQuiz`, the entry cleared, the timer stopped), and the comment and the doc
say what is then true.

<a id="c3"></a>
### C3. A daily session that crosses midnight counts for the day it ends (Run, Medium)

`Quiz.finish()` records the session at `now()` (`Quiz.swift:996-999`). The probe began a session
at 23:58 on the 23rd and finished it at 00:02: it was keyed to the 24th. The day it was begun on
reads as missed, and if that session was the second of a repair, the streak is lost. Finishing in
the last minutes of a day is how people keep streaks.

**Fix.** Record the session for the day it began.

<a id="c4"></a>
### C4. The quiz's injected clock reaches only part of the quiz (Read, Medium)

`Quiz` takes `now: () -> Date` and uses it for the default round's due items (`Quiz.swift:470`)
and the streak (`:997-998`). Everything else reads the wall clock: `practice.recordAnswer`
(`:822`, through its `at: .now` default), a record session's items (`:446`), `canContinue`
(`:212`), `askableCount` (`:217`), `startDate` (`:724`), `durationBand` (`:198`), and
`LastQuizResult`'s date.

In the app the two clocks agree. In a test they do not, so no test can ask whether a miss on day
0 is due in day 1's session. `DailySessionTests`' repair across four days sets its clock to four
dates and records every answer in the real present.

**Fix.** Pass `now()` to each. The fixes for [L1](#l1) to [L4](#l4) need this to be tested
honestly, so it belongs to their phase.

<a id="c5"></a>
### C5. A shared practice set: what comes in, what goes out, and its QR code (Run, Low)

- **An incoming list is not capped.** `PracticeSet.maximumListCount` (100) applies only in
  `init(sharing:level:myVerbs:)`. `PracticeSet.init?(url:)` (`PracticeSet.swift:43-61`) keeps
  every known infinitive. The probe opened a link of 500: all 500 were kept, Keep stores them, and
  the set's own QR code is then nil, at which `PracticeSetQRView` shows nothing.
- **A link names its own source.** `AppRouter.handle(url:)` takes `source` from the link, so a
  set's link carrying `source=tab` reports the Quiz tab on `viewPracticeSet` and on the quiz's
  signals (Run).
- **The cap does not keep the code coarse.** The comment on `maximumListCount` says it keeps "a
  projected QR code coarse enough to scan from the back of a classroom", and `QRCode`'s says a
  hundred verbs fit "well inside its capacity". The probe measured, at the medium correction
  level the app uses:

  | List | Link | Modules a side |
  |---|---:|---:|
  | The 100 longest infinitives, every tense | 2,013 bytes | 171, of 177 at most |
  | The 100 most frequent verbs, every tense | 1,272 bytes | 139 |
  | The 100 most frequent verbs, one tense | 814 bytes | 111 |
  | The 30 most frequent verbs, one tense | 250 bytes | 63 |
  | A pattern list (`verbs=goVerbs`), one tense | 67 bytes | 39 |

  `PracticeSetTests.theLongestListFitsACode` checks only that an image came back.
- **A shared My Verbs carries the sharer's recent lookups** (Read). `init(sharing:…)` shares the
  first 100 of My Verbs, which is the starred verbs followed by up to twenty opened lately and
  not starred. A teacher who starred this week's verbs also hands the class whatever else she
  looked up, and the menu says only "My Verbs".

**Fix.** Cap a decoded list. Accept only `sharedLink` and `qrCode` as a set's source. Say so when
no code can be made. See [D23](#d23) for what a shared My Verbs carries and how many verbs a code
holds.

<a id="c6"></a>
### C6. A choice that asks nothing leaves Start live and silent (Run, Low)

A custom quiz of the presente de subjuntivo over abolir's model (agredir, abolir, transgredir,
balbucir) has no askable cell. The probe: `CustomQuiz.isEmpty` is false, so the tab enables
Start, and `Quiz.start` returns false. On the tab nothing happens. As a practice set, the sheet
opens on `Color.clear` and a Done button (`QuizView.swift:57-62`).

**Fix.** Disable Start with a line that says why, decided by a cheap "has an askable cell" check,
and show the same line in the sheet when a start fails.

<a id="c7"></a>
### C7. The reminder's reschedules can overtake one another (Suspected, Medium)

`ReminderSchedulerReal.schedule` (`ReminderSchedulerReal.swift:32-57`) starts a new unstructured
`Task` on each call, which fetches the pending requests, removes the reminder's, and adds the new
ones, awaiting between steps. The time picker's setter fires as it is scrubbed
(`SettingsView.swift:242-246`), and `MainTabView` and `Quiz.finish()` call it too. Two tasks can
interleave, so an older plan's `add` can land after a newer plan's removal. The unchecked step is
the order in which the notification center completes the calls.

Two neighbors (Reviewer): a reminder already delivered today stays in Notification Center after
the session is finished, and Settings' "notifications are off" line (`.task(id: isOnScreen)`,
`SettingsView.swift:58-63`) does not refresh when the learner returns from the Settings app
having allowed them.

**Fix.** The identifiers are deterministic, so remove them by name without the fetch, or keep one
stored task and cancel it before the next. Remove today's delivered reminder on finish. Check
again when the scene becomes active.

<a id="c8"></a>
### C8. Two calendars the code does not mean to use (Run for the streak; the rest Read, Low)

- **The streak's days are named in the learner's calendar system.** `DailyStreak.dayKey`
  (`DailyStreak.swift:142-163`) formats with the calendar it is passed, which is
  `PracticeStore`'s, which is `Calendar.current`. With a Japanese calendar the probe's key was
  `0008-11-23`, and under the Gregorian calendar the next day that streak read as none.
  `Shared/CalendarDay.swift` exists so that a calendar setting cannot move a day, and the
  challenge uses it. The streak and the reminder's identifiers do not.
- **The store keeps the calendar of launch.** `PracticeStore.init(getterSetter:calendar: = .current)`
  stores a snapshot, and `Current.practice` lives for the process. After a change of time zone
  with the app suspended, the streak's and the schedule's days follow the old zone while
  `DailyReminderPlan` and `CalendarDay` read the new one.

**Fix.** Build the streak's keys with `CalendarDay`. Hold `Calendar.autoupdatingCurrent`, and
pass the store's calendar to the reminder's plan.

<a id="c9"></a>
### C9. The accent keys follow the size class, not the device (Read; the sheet's case Suspected, Medium)

`QuizView` puts the letter keys in the keyboard's toolbar when the width is compact (`:98-103`)
and under the field when it is regular (`:994-996`). The comment gives the reason: iPadOS's
keyboard shows no toolbar items. That is a fact about the device, and the code tests a layout
class. An iPad in Split View, in Slide Over, or in a narrow Stage Manager window is compact, so
its keys go to a toolbar that iPadOS never shows, and the learner has none. `VerbBrowseView`
decides the same question by `UIDevice.current.userInterfaceIdiom` (`:24`).

The unchecked step is whether a `QuizSheet` on an iPad reports a compact width, which would leave
Test Me, a collection's quiz, a model's practice, and a practice set without keys there.

**Fix.** Put the keys under the field on an iPad whatever the width. Check a sheet and a
one-third Split View on "Conjugar iPad Pro 11".

<a id="c10"></a>
### C10. The Live Activity after a quiz ends (Read, Low)

- `QuizActivityAttributes.ContentState.isFinished` is set and read nowhere in the widget, so a
  finished activity looks like one in progress.
- `LiveActivitiesReal.end` (`:35-42`) uses the default dismissal for a quit too. A quiz quit at
  question 4 leaves "4/10" on the Lock Screen for up to four hours.
- The `widgetURL` is on the Dynamic Island's presentation only (`QuizLiveActivity.swift:56`). A
  tap on the Lock Screen's opens the app on whatever tab was last.
- Its link is `quiz/start`, which starts a new quiz whatever the old one's state ([C1](#c1)).
- `totalQuestions` is `questions.count` (`Quiz.swift:1060`), which counts re-asks, so the
  activity's "of 10" becomes "of 11" at the first miss.

**Fix.** Show the final state when finished, dismiss at once on a quit, link the Lock Screen's
view, and have a finished activity open the Quiz tab without starting anything.

<a id="c11"></a>
### C11. `Quiz` trusts the view to call it in order (Run, Low)

- `process(proposedAnswer:)` has no guard that the quiz is in progress and not held, which
  `submitChoice` and `continueAfterCorrection` have. The probe called it twice during a held
  correction: two results for one question, and two re-asks.
- It has no guard against a choice question. A typed wrong answer to one inserts a re-ask the app
  never makes (Run), and several tests' drivers answer a choice that way ([T6](#t6)).
- `QuizView.continueAfterCorrection()` (`:1396-1405`) runs the view's `finish()` whenever the
  state is finished, even when the model's own guard returned early. Only the button's
  visibility prevents a second applause and a second `completeQuiz`.
- A quit and a completion are both `QuizState.finished`, and `canContinue` tells them apart by
  `results.count == questions.count` (`:205`).

**Fix.** The guards, a `quit` state of its own, and the three answer paths returning one outcome
that the view switches over. [S1](#s1) describes the shape.

<a id="c12"></a>
### C12. Four small stores are replaced silently when they fail to decode (Read, Low)

The browse fixes' C12 made `PracticeStore.init` copy an unreadable practice record aside. The
last result, the level bests, the streak, and the challenge results sit beside it
(`PracticeStore.swift:65-73`), each falling back to empty on a failed decode and overwritten by
the next write. Nothing has shipped, so nothing is at risk today.

Two neighbors (Reviewer): `PracticeStore.reset()` leaves the unreadable-record backup on the
device, an older copy of what the learner just asked to erase, and a review card already on
screen stays after a reset, offering a verb whose schedule is gone.

**Fix.** Back each up as the record is. Add a test that decodes a pinned string of today's format
for each, so that a changed format fails a test and not a learner. Clear the backup on reset, and
have the card choose again.

## Privacy

Decision 5: no signal may carry an answer, a score, an accuracy, or a verb. Since 2026-11-24 no
mode sends `score`.

**The audit.** A reviewer read `Analytics.swift`, `AnalyticsReal`, and every call site (50
`signal(name:` calls), and I read `Analytics.swift` and the three quiz signals' call sites
myself. The rule holds at HEAD: `ParameterKey` has no `score` case; `questionNumber` and
`questionCount` exclude re-asks and are absent where a round's length depends on answers
(`QuizScope.sendsQuestionCounts`); the streak band counts days; `tapShareChallenge` carries the
level and never the result; no signal says an achievement was earned or a best beaten; nothing
calls TelemetryDeck outside `AnalyticsReal`. The staged policy's last wording of each bullet
agrees between English and Spanish and covers every signal, key, and value, with the exceptions
under [P5](#p5), and `docs/release.md` § On Release Day applies it. The table of every signal is
in [Phase 11](#phase-11-the-staged-policy-and-the-docs)'s brief, for its session to re-run.

The findings are the edges.

<a id="p1"></a>
### P1. A quiz over a one-verb model names the verb it asks (Read, Medium)

`QuizView.startQuiz` sends `scope.collectionKey` as `collection` (`QuizView.swift:1268-1270`). A
model's key is `model-` and its class, and the browse review's probe counted 29 models that hold
one verb, ser, ir, estar, haber, poder, querer, decir, saber, ver, and dar among them. Three
routes send such a key on `startQuiz`:

- a model page's own Quiz button (`VerbCollectionView.swift`, through `QuizScope.collection`);
- a custom quiz over a model, which `CustomQuizModelList` (`CustomQuizView.swift:117-131`) offers
  for every model, the one-verb ones included (`CustomQuiz.swift:227`);
- a practice set over a model (`PracticeSet.swift:78`).

A model's practice alone is not offered for a one-verb model, so `modelAlone` is safe.
`tapShareCollection` sends the key too.

`docs/feature_architecture.md:106` says "a collection names a list, never a verb", three lines
under its own admission (`:103`) that a one-verb model's key is the verb. The browse fixes' P1
closed this for one signal and one source, and Phase 2's note left the rest as something "Josh
may want to know". It is still undecided.

**Fix.** See [D20](#d20).

<a id="p2"></a>
### P2. The browse fix for a correction's link left Share open (Read, Medium)

Phase 2 of the browse fixes made `VerbCollection.signalView` omit the key when the source is a
quiz correction. The page that link opens still shows the model's bar, and `VerbCollectionBar`
(`VerbCollectionView.swift:83-145`) hides only its Quiz button beneath a quiz. Its Share button
is unconditional, and `share()` sends `tapShareCollection` with `collection.key`. So after a
wrong answer, the correction's link and one tap name the model of the verb just missed, which for
29 models is the verb. The note in `docs/privacy_policy_pending.md:390-393` says the leak is
closed.

**Fix.** Carry the request's source to the bar, so that the one rule (no key after a correction)
lives in one place. With [D20](#d20)'s first option the bar sends only the class, which settles
it for models by itself.

<a id="p3"></a>
### P3. A second round of My Mistakes says that more than ten were missed (Run, Low)

A record session sends no counts. But `QuizView.finish()` sends `completeQuiz` for every round,
and `canContinue` offers Ten More only while unasked items remain. The probe gave a learner
fourteen mistakes: the first round asked ten and offered another. A second `completeQuiz` with
`source: mistakes` in one session therefore means more than ten items were missed. The staged
text says such a session does not report "how many questions it has asked".

A weaker neighbor (Reviewer): `duration` is sent for a record session, and a session as long as
the learner's mistakes runs as long as they are many.

**Fix.** See [D21](#d21).

<a id="p4"></a>
### P4. Some sources exist only after the record says something (Read, Low)

The Speed Round's row is a button only once five items are mastered, a model's Mixed button only
once another model is known, and Review and My Mistakes only with something due or missed. So
`startQuiz` with `source: speedRound` says at least five items are mastered, and `modelMixed`
that a model is known. Phase 2's note accepted `quizCorrection` as a surface. These were never
put to Josh for Conjugar. See [D22](#d22).

<a id="p5"></a>
### P5. The staged policy against the code (Read, Low)

- **The progress bullet says more is sent than is.** Its last wording
  (`docs/privacy_policy_pending.md:706`, Spanish `:732`) excepts only "a review or a practice of
  your mistakes". The code also sends no `questionNumber` for a model's mixed practice or the
  Speed Round. Phases 15 and 20 rewrote the score bullet and not this one.
- **"(but not which ones)."** The quiz-lifecycle bullet's last wording (`:1196`, Spanish `:1222`)
  says that for a custom quiz or a practice set the app records whether it chooses tenses, verbs,
  or both, "(but not which ones)". A custom quiz or a set over a pattern list or a model sends
  which, as the clause before it says of "a quiz over a collection or a verb model". The two
  clauses read as contradicting each other. The fix follows [D20](#d20)'s answer.
- **`abandonQuiz` carries `level` and `source`.** The level bullet (`:435`, Spanish `:443`) says
  the level is sent "when you start, quit, or complete a quiz".
- **"The app does not send … how many of them were right"** (`:1265`) sits beside section 7,
  which says the first ten questions' score goes to Game Center. Adding "to the developer" would
  make both true.
- **One phrase in the Spanish** (`:1279`): "mostrarle y compartir cómo le fueron sus desafíos"
  makes the app the one who shares. The learner shares.

**Fix.** Restage each, in both languages, for Josh to read.

<a id="p6"></a>
### P6. Decision 5 is held by vigilance, in a view no test reaches (Read, Medium)

The API is `signal(name:parameters: [String: String])`, and `AnalyticsSpy` records without
checking. Which parameters each quiz signal carries is decided in `QuizView` (`startQuiz`,
`:1263-1274`; `finish()`, `:1426-1437`; `quit()`, `:1448-1456`), and nothing in `ConjugarTests`
refers to `QuizView`: a search for `completeQuiz` finds only the wire-name tables. `a9637a0`
removed the score by editing the view, with no test to say it stayed removed.
`QuizScope.sendsQuestionCounts` is a conjunction of negatives, so a new kind of quiz sends counts
unless someone remembers to except it ([S3](#s3)). That is how [P1](#p1) passed two audits.

**Fix.** In order of cost:

1. Build the three quiz signals in the model, as functions of a `Quiz`, and test them: no score,
   no counts for a record session, a mixed model practice, or the Speed Round, and a streak only
   for a daily session.
2. An allow-list of every parameter key and its values (integers as a pattern), with
   `AnalyticsSpy.signal` recording an issue for anything outside it. Every test that drives a
   quiz, a search, or a page then guards Decision 5 for free.
3. A closed `enum Signal` whose cases carry typed payloads, so that a collection's parameter
   cannot be built from a model and a record session cannot express a count.

<a id="p7"></a>
### P7. The analytics vocabulary decides what the app does (Read, Low)

`PracticeStore.recordLookup` reschedules unless the `AnalyticsSource` is `.reviewCard`
(`PracticeStore.swift:170`). `VerbView.send` records an open unless it is `.resume`.
`VerbCollection.signalView` branches on `.quizCorrection`. Renaming or splitting a reporting
value would silently change review scheduling.

**Fix.** Pass what the behavior depends on by name, such as whether a visit reschedules, and keep
`AnalyticsSource` for reporting. [L6](#l6)'s fix rewrites this code and should carry it.

## Gaps and Docs

<a id="g1"></a>
### G1. `docs/feature_architecture.md` says things the code does not do (Read unless noted, Low)

- `:106`: "a collection names a list, never a verb" ([P1](#p1)).
- `:754`, `:760`: only a slip's second attempt counts as right ([L2](#l2)).
- `:764`: the due items are "placed at random among a draw of seven". That is Beginner only.
  From Elementary up the draw is six, and the round is shuffled afterward anyway.
- `:993`: "dice" for di gets the regular-form line ([L12](#l12)).
- `:1018`: "arepiento is shown arrepiento rather than me arrepiento". In the app the frame
  composes "me arepiento", whose nearest spelling is me arrepiento (Run).
- `:1027`: "Half points: only the accent marks differ." Phase 3 removed the partial match.
- `:1185-1187`: the signals' table omits the Speed Round from the modes that send no counts.
- `:1223-1225`: Review "gives the days to the next due item" ([L20](#l20)).
- § Quiz: the counts are exact "at thirty questions or ten" ([L15](#l15)).
- The hub's paragraph lists Review, My Mistakes, Last Quiz, and View Leaderboard. The hub now
  also has the Daily Session, the Daily Challenge, Mastery, the Exercises, and Achievements
  (Reviewer).
- § Test Me: every sheet quiz ends with `quitQuiz` or `completeQuiz` ([C2](#c2)).

<a id="g2"></a>
### G2. Comments and one string that say what the code does not (Read unless noted, Low)

- `QuizSheet` (`:13-15`): [C2](#c2).
- `QuizScope.Kind` (`QuizScope.swift:12-14`): "the switches below make it decide" ([S3](#s3)).
  The header says `collection(_:title:)` is in `VerbCollection+Text.swift`. It is in this file.
- `ReviewSchedule`'s header (`Shared/ReviewSchedule.swift:15-16`): an item missed late in the
  evening "waits until the next morning". It is due at midnight, so a miss at 23:58 is drawn as a
  due review by a Ten More at 00:01.
- `PracticeStore.recordAnswer` (`:153-154`): the slip's reason for a rule that now covers
  diagnoses ([L2](#l2)). `Quiz.firstAttempts`, `ConjugationResult.secondAttemptMatch`, and
  `QuizQuestion.grade(_:)` each describe the second attempt as a slip's alone (Reviewer).
- `PracticeStore.challengeResults`: forgetting a result "would let its challenge be taken again",
  under a cap that forgets ([L16](#l16)).
- `PracticeRecord`'s header: "never sent anywhere". Achievement progress figured from it goes to
  Game Center, as the staged policy says.
- `QuizQuestion.diagnosis(of:)` (`AnswerDiagnosis.swift:96-99`): [L12](#l12).
- `VerbEssentials.verbs` (`:61-64`): "verbs the session has asked come only once every other
  verb has been". With `limitsCompounds`, an asked base verb is drawn before an unasked compound
  (Reviewer).
- `PracticeSet.maximumListCount` and `QRCode.image(for:)`: [C5](#c5).
- `Quiz.Fixture.standsIn(for:)` and the `case .speedRound: break` in `Quiz.start` (`:325-326`):
  the guard at `:290` makes both unreachable as written (Reviewer).
- **`Mastery.intro`** (the string, in both languages) says an item is mastered "once its next
  review is a week or more away". The code asks only whether the box is the third or later
  (`Mastery.swift:19-26`), so an item overdue by a month is mastered, and the string does not say
  that a lookup starts it over.

<a id="g3"></a>
### G3. Provenance where the plan's rule forbids it (Read, Low)

- `ConjugarTests/Models/LearnerVerbsTests.swift:275`: "before Phase 3 of the fixes plan".
- `ConjugarTests/Models/DailyChallengeTests.swift:144`: "The text Josh approved on 2026-11-24".
- `docs/feature_architecture.md:1193-1195`: "until Josh removed it on 2026-11-24, so that
  Conjugar agrees with Conjuguer and Konjugieren … (Konjugieren's Decision 5)".
- The browse fixes put `// MARK:` lines back: five in `Models/VerbBrowseSearch.swift`, two in
  `Models/VerbBrowseReviewCard.swift`, and six in `ConjugarTests/Views/VerbBrowseSearchTests.swift`
  (Reviewer). The pedagogy code has none.

<a id="g4"></a>
### G4. What the notes left open (Read, Low)

- **The *Plan curricular* was never checked.** Phase 4's note says the ladder was checked only
  against `docs/tense_frequency.md`, because cvc.cervantes.es was down that day, and that "a
  later session could still compare it". None did. It bears on [L8](#l8): whether a command
  belongs at A1 at all.
- **The Game Center alert greets the first visit to the Quiz tab** (`maybePromptGameCenter`,
  `QuizView.swift:1507-1521`), which Phase 12's note left for Josh. It can appear over a first
  quiz started by a link.
- **`ChangeLevelTip` is attached only in Settings**, though the hub's level tile sits beside
  Start (Reviewer).
- **Wording Josh has not judged**, by the notes' own account: `L.PracticeSession`'s strings and
  Reset Practice's description.

<a id="g5"></a>
### G5. `plans/pedagogy_variant_audit.md` rests on a premise that changed (Reviewer, Low)

Row 13 (`:41`, `:64`) rules on iros and -aos "while the quiz asks no pronominal verb".
Reflexive-only verbs are drawn now ([L11](#l11)). The ruling still holds. The audit also never
weighed vayamos ([L13](#l13)).

## Accessibility and Localization

Nobody has listened to any of this, as the phase notes say of every phase. These are read from
the code.

<a id="a1"></a>
### A1. VoiceOver reads the quiz's Spanish in the English voice (Reviewer, Medium)

The prompt read most often is the one left untagged. `QuizView.questionCard` shows the verb
(`:1020`) and the tense (`:1044`) as plain text, and so does `ResultsView.resultRow` (`:317`,
`:321`), while `VerbEssentialsRowLabel`, `MasteryPatternTableView`, `QuizCorrectionView`, and the
My Verbs chips tag the same strings Spanish. In the English interface "hablar · Presente de
Indicativo" is read with English phonetics. The same holds for the Spanish inside a diagnosis
line (`QuizCorrectionView.swift:210-212`, and `secondAttemptPrompt`) and inside a choice's reason
and its announcements (`ChoiceQuestionView`, `L.Choice.announceRight` and `announceWrong`).

**Fix.** `Text(spanish:)` for the four, and attributed announcements with the Spanish runs
tagged, as `QuizCorrectionView` tags an answer.

<a id="a2"></a>
### A2. Refocusing the field probably takes VoiceOver off what it was told to read (Suspected, Medium)

- `.onChange(of: quiz.isHeld)` (`QuizView.swift:930-943`) moves VoiceOver's focus to the
  correction, then `refocusAnswer` (`:1171-1184`) gives the field the keyboard about 100 ms
  later. A text field that becomes first responder normally takes VoiceOver's cursor and speaks
  itself. Phase 2's note says "focus moves to the correction".
- `submit()` (`:1336-1337`) posts the "Almost!" or diagnosis announcement and at once refocuses
  the field, whose own speech would cut the announcement off.
- A choice both announces its reason and focuses it, so the reason may be read twice.
- `.accessibilityAction(.magicTap)` sits on the `NavigationStack` (`:160-164`), so a Magic Tap on
  a verb page pushed from a held correction would continue the quiz behind it, restart its clock,
  and focus a field that is off screen.

The unchecked step for each is the order of events with VoiceOver running on a device.

**Fix.** Check by ear first. Then, under VoiceOver, delay or skip the refocus, post the
announcements at high priority, and require `navigationPath.isEmpty` for the Magic Tap.

<a id="a3"></a>
### A3. Rows, targets, and one fixed width (Reviewer, Low)

- **The results' rows** (`ResultsView.swift:297-308`): the right and wrong icons have no label,
  so VoiceOver reads the symbols' names, and each row is about six elements. One element a row
  with a built label would read "hablar, presente, yo. Correct. Your answer: hablo".
- **The score strip** (`QuizView.scoreStrip`, `:1230-1248`) reads the score and the clock as bare
  numbers. The Speed Round's strip labels its own.
- **Tap targets under 44 points**, estimated from fonts and padding: Name the Form's chips, about
  34 (`RecognitionChoicesView.swift:110-121`); a correction's links, about 32
  (`QuizCorrectionView.swift:180-183`); the results' Example Use toggle, about 16
  (`ResultsView.swift:255-261`); and the hub's leaderboard and achievements buttons on an iPhone
  (`QuizView.swift:388`, `:403`).
- **The Verb Models list's rows** are an `onTapGesture` with a button trait
  (`ModelPracticeListView.swift:34-46`), which Full Keyboard Access cannot reach, and say nothing
  of being open or closed.
- **A sentence's field is 170 points wide** (`AnswerFrameView.sentenceFieldWidth`, `:88`). At
  accessibility text sizes a compound answer will not fit.
- **Return on an empty answer** (Suspected): `submit()` returns at its guard (`:1315`) without
  refocusing, where Name the Form's incomplete answer does refocus. On an iPhone the keyboard and
  its letter keys would go. The notes say the software keyboard was mostly not tried.

<a id="a4"></a>
### A4. Localization hygiene (Reviewer, Low)

- Two interpolations put auto-extracted keys in the catalog: `Text("\(Image(...)) \(L.Quiz.askedAgain)")`
  (`ResultsView.swift:327`) made `"%@ %@"`, and an accessibility label at `QuizView.swift:1215`
  made `"%@: %lld"`. Both are in `Localizable.xcstrings` in the state "new", untranslated.
- Punctuation is appended in code at `QuizView.swift:1414` and `:1421` and at
  `ResultsView.swift:334`, `:342`, `:351`, and `:361`.
- `PersonalBest.best` and `SpeedRound.best` are the same string. "Score 85" in the results is
  "Score: 85" on the hub.
- Accessors with no caller: `L.Quiz.tense`, `.restart`, `.verb`, `.pronoun`, `.lastAnswer`,
  `.progress`, and `.elapsed`, and `L.Results.time`. They predate this work.

## Smells, Duplication, and Elegance

<a id="s1"></a>
### S1. Every mode is a parallel path through `Quiz` (Read, Medium)

`Quiz.swift` is 1,442 lines: 25 observed stored properties and 12 unobserved. It draws
(`:373-681`), grades and holds (`:770-972`), finishes with its side effects (`:974-1067`), and
carries 330 lines of DEBUG fixtures (`:1112-1442`).

- **Three answer paths repeat one block.** `process` (`:813-840`), `processRecognition`
  (`:884-912`), and `submitChoice` (`:935-939`) each append to four parallel arrays
  (`proposedAnswers`, `correctAnswers`, `results`, `firstAttempts`), and the first two repeat the
  re-ask and correction block word for word, comment included. `ResultsView.resultRow` guards
  every read of those arrays with `index < count`, which is what [C1](#c1) then shows as misses.
- **Loose optionals encode one phase.** `correction`, `chosenOption`, `firstAttempt`,
  `firstAttemptDiagnosis`, `firstAttemptRecognition`, and `speedRoundMiss`. A correction and a
  chosen option together are representable, and the view would then draw two Continue buttons.
  Six more fields mean something only after a finish.
- **`QuizQuestion`'s kind is three optionals** (`recognition`, `sentence`, `choice`), of which
  `choice` implies `sentence`, and the views test them in different orders (`QuizView.swift:963`,
  `:977`, `:984`, `:1010`, `:1017`, `:1034`, `:1043`).
- **`Quiz.draw` is an if-chain whose order matters** (`:406-467`): `isVerbEssentials` is true of
  a model's practice, so the `modelPractice` test must come first, and a new kind falls through
  to the default draw.
- **The level and the region are hidden parameters of the draw**, set on the quiz before it and
  restored after a failed one (`:331-341`).
- **Dependencies come three ways.** `settings`, `gameCenter`, the practice store, the reminder's
  scheduler, and the clock are injected. `Current.liveActivities` and `Current.getterSetter` are
  read directly, and the model imports TipKit to donate to a tip.

Most of this review's findings are of that shape: a rule written for one mode and reached by
another.

**A simpler shape.** A `QuizQuestion.Kind` enum (typed, recognition, sentence, choice) in place
of the optionals. One `QuestionPhase` (answering; awaiting a second attempt, with its reason;
held, with its correction or choice). One `AnsweredQuestion` in place of the four arrays, and one
private function that records an answer for all three paths. A `quit` state of its own. The draw
as a `switch` over `scope.kind`. Short of that, moving the fixtures to `Quiz+Fixtures.swift`
costs an hour and takes 330 lines out of the file.

<a id="s2"></a>
### S2. `QuizView` is the question, the hub, two hosts, and an input controller (Reviewer, Medium)

1,858 lines, 15 `@State` properties, about 23 computed views and 19 functions, four private
structs, and a mode flag, `sheetScope`, branched in eleven places. No test refers to any quiz
view. The seams:

- **The hub** (`:217-785`, `:1581-1858`): a `QuizHubView` with a model that computes its rows
  from the practice store, the settings, and one injected date. Today the hub reads
  `Current.practice` for the streak, the challenge, the bests, and the last result, and the
  injected `quiz` for `askableCount` and `speedRoundItems`, which is why its rules (Review off at
  0, the Speed Round locked below five, a taken challenge offering Share) cannot be tested, and
  why the row goes stale at midnight ([L16](#l16)).
- **The question** (`:792-1248`, with `submit`, `choose`, and `continueAfterCorrection`).
- **The answer being typed.** The same reset of `answer`, `answerSelection`, `recognitionTense`,
  and `recognitionPerson` is written by hand in seven places, and `startQuiz` alone forgets
  `answerSelection`. A small value type with `insert(_:)`, `recognitionAnswer(for:)`, and
  `reset()` would be pure and testable.
- **Focus.** "Clear, sleep, set `fieldFocused`" is written six times (`:911-917`, `:947-952`,
  `:1171-1184`, `:1304-1311`, `:1478-1484`, `:1498-1504`), and no task is cancelled.
- **Two hosts.** The tab owns the stack, the router's three requests, and the results' push. The
  sheet shows the results in place. Splitting them removes `sheetScope`.

<a id="s3"></a>
### S3. A new kind of quiz still inherits most rules by default (Read, Medium)

The browse fixes' Phase 12 gave `QuizScope` a `Kind` whose comment says "the switches below make
it decide, rather than a flag it might forget to add itself to". Only `Kind.runsInSheet` is a
switch. `sendsQuestionCounts` (`QuizScope.swift:173-175`), `shufflesQuestions` (`:182-184`),
`continues` (`:202-204`), `startsLiveActivity` (`:211-213`), and `showsVerbLink` (`:216-218`) are
still conjunctions of negatives. A new kind sends question counts, is shuffled, offers Ten More,
and starts the Live Activity unless someone remembers otherwise. The first is the privacy rule
([P6](#p6)), and it fails open. The phase's note says it left "the other readers of single
flags" alone, so this is an incomplete fix and not a regression.

The same shape elsewhere: the tip's donation in `Quiz.finish` (`Quiz.swift:993`),
`QuizView.sessionTitle` (`:197-215`, which also duplicates `LastQuizResult`'s title,
`LastQuizResult.swift:113-150`), `ResultsView`'s button and summary chains, and
`QuizView.anotherRound` (`:1490`), where any kind but a daily session starts a Speed Round.

Stored fields can also disagree with the kind: `.collection` carries no collection, which lives
in `collectionKey` beside it; `.custom` and `.practiceSet` store a `CustomQuiz` beside `verbs`;
and `continues` asks `questionCount >= roundLength` to mean "not Test Me".

**Fix.** Each rule a `switch kind` with no default, `sendsQuestionCounts` first. A title on the
kind, used by both sites. Each mode's own state in its case.

<a id="s4"></a>
### S4. One rule, written more than once (Read unless noted, Low)

- **Normalizing an answer:** `AnswerSpelling.normalized`, `ConjugationMatch.normalized(_:accents: .exact)`,
  and `VerbSearch.normalized` (`VerbSearch.swift:222`) are the same lowercase-and-collapse
  (Reviewer).
- **Folding accents:** `SpellingComparison.fold` removes every diacritic and
  `ConjugationMatch.bareSpelling` the acute, the diaeresis, and the tilde, which is
  [L10](#l10)'s grave accent.
- **The -ra and -se pairing:** `AnswerDiagnoser.otherImperfectSubjunctive`
  (`AnswerDiagnosis.swift:299-304`) and `DisplayTense.otherImperfectSubjunctive`
  (`GapSentence.swift:254-266`).
- **"Would this level ask it":** the same closure in `Quiz.dueQuestions` (`:470-472`), in the
  Speed Round's branch of `Quiz.draw` (`:414-416`), and in `Mastery.layout` (`:186-188`).
  [L20](#l20) needs a fourth.
- **A regular verb for a pattern:** drawn in `QuizDraw.recordQuestions`
  (`QuizDueItems.swift:55-73`) and again in `speedRoundQuestions` (`SpeedRound.swift:84-100`),
  each with its own constant of eight attempts.
- **Days:** `DailyStreak.dayNumber`, `PracticeRecord.daysBetween`, the reminder's identifiers,
  and `WidgetSnapshotWriter.dayNumber`, beside `CalendarDay`. `DailyChallenge.calendar`,
  `dayString`, and `date(fromDayString:)` only forward to it.
- **Loading bundled JSON:** `GapSentences.all` (`GapSentence.swift:224-235`) and
  `ChoiceQuestions.all` (`ChoiceQuestion.swift:255-266`) are one block (Reviewer).
- **`sessionAllows` and `settingsAllow`** (`Quiz.swift:643-650`) differ by a region, and `verb`,
  `tense`, and `currentPersonNumber` restate `currentQuestion`.

<a id="s5"></a>
### S5. `PracticeStore` holds six things, each saved its own way (Read, Low)

The record, the last result, the Speed Round's best, the level bests, the streak, and the
challenge results. Two encode through a `json` property, two through `JSONEncoder` written out
at the call, and one as a number's text. `reset()` writes empty strings because `GetterSetter`
cannot remove a key. Reset Practice itself is three calls and a signal in
`SettingsView` (`:184-191`): the store's reset, `learnerVerbs.forgetOpenHistory()`, and
`Current.rescheduleReminders()`.

**Fix.** One `Current.resetPractice()`, and one small helper that stores a `Codable` under a key
with [C12](#c12)'s backup.

<a id="s6"></a>
### S6. Work repeated on every answer and every frame (Reviewer; the timing Suspected, Low)

- `Quiz.process` computes a wrong answer's diagnosis at `:787` and again at `:837`, and `grade`
  is recomputed inside `diagnosis(of:)` and `isSlip(_:)`, each rebuilding `shownSpellings`.
  `isAnotherCell` conjugates about 150 cells per accepted spelling, per candidate. All of it runs
  on the main actor at each submit.
- `ModelPracticeGroup.items` is computed, up to 40 engine calls a model, and `known(in:)` runs it
  for all 94 models. `ModelPracticeCard.body` and each of `ModelPracticeListView`'s 65 rows call
  it on every redraw. Nobody timed it. The value never changes, so it can be stored.
- `QuizView`'s body is re-evaluated every second ([L17](#l17)), and it reads
  `quiz.essentialsRows` twice (`:812`, `:1043`), which conjugates the verb's key forms each time.

<a id="s7"></a>
### S7. The quiz's views repeat each other (Reviewer, Low)

| What | Where | Extract as |
|---|---|---|
| Verb chips with "+N more" | `QuizView.myVerbChips` (`:742-765`), `PracticeSetView.verbChips` (`:140-162`) | One view |
| The gold capsule chip | `QuizView` `:747-753`, `PracticeSetView` `:145-151`, `QuizCorrectionView` `:180-184`, `RecognitionChoicesView` `:110-120` | A modifier in `Modifiers.swift` |
| The hub's tile background | `QuizView` `:1624-1628`, `:1670-1674`, `:1790-1794` | A modifier |
| The breathing Start button and the hero symbol | `QuizView` `:771-785` and `:491-499`, `PracticeSetView` `:121-136` and `:75-80` | Shared views |
| The Continue button | `QuizCorrectionView` `:124-132`, `ChoiceQuestionView` `:47-57` | One button |
| The count line | `ResultsView.countLine` (`:207-225`), `LastQuizResultRow.resultLine` (`QuizView.swift:1692-1702`) | One formatter |
| Seconds as text | `Int.timeString` and `Quiz.formatMinutesSeconds` | One format |
| A hand-written reading width | `QuizView` `:884-885`, `ResultsView` `:88-89` | `.readingWidth()` |

`ModelPracticeListView` could be `AdaptiveRows` with a row label, which would give the iPad a
grid, and `CustomQuizModelList`'s detail line restates what `ModelRowLabel` shows. Nothing the
browse fixes changed broke the quiz's screens.

<a id="s8"></a>
### S8. Small things (Read unless noted, Low)

- `QuizDraw.questions(cells:level:using:)` has no caller, and `QuizDraw.verbs(for:)` only tests.
  `Quiz.stop()` is public and only `quit()` calls it. `QuizScope.verbEssentials(_:)` takes a list
  that only tests pass, and `QuizScope.modelPractice` fills `verbs`, which nothing reads
  (Reviewer).
- `SplitMix64` seeds the quiz, the daily challenge, and the widget's day, and lives in
  `Models/Game/GameModels.swift`.
- The `grading`, `screenshot`, and `choices` fixtures stand in for the ranked quiz, so on a
  simulator they post to Game Center's fake and set the level's best (Reviewer).
- `QuizDraw.mixing` places the due questions at random, and `drawRound` then shuffles the round,
  so the placement matters only where nothing is shuffled.
- `AnswerDiagnoser.spelling()` takes `forms(of:).first` from a `Set` (`AnswerDiagnosis.swift:205`),
  an arbitrary element, harmless today.

## Tests

Josh asked whether the tests that use a seeded generator prove what they claim. Most do. Every
random choice a quiz makes goes through the generator a test hands it, `QuizVerbMixTests` and
`QuizLevelTests` check real distributions over many draws with stated tolerances, and the
function-level tests of the choice draw and of a model's verbs use pools small enough that chance
cannot pass them. A seventh reviewer checked Konjugieren's test findings here. The findings are
the exceptions. All are Reviewer unless noted.

<a id="t1"></a>
### T1. Assertions that cannot fail (Read for the first, Medium)

- `ChoiceQuestionTests.noChoiceAtBeginnerOrOutsideTheDefaultQuiz` (`:320-321`) starts one quiz
  and then asserts on a second, new one, whose `questions` are empty, so `allSatisfy` is true
  whatever the code does. Beginner's "no choice" is untested.
- `GameCenterFakeTests.submitScoreAndShowLeaderboardsAndAchievements` asserts nothing.
- `DailyChallengeTests.theWidgetsQuestionAgreesWithTheChallenge` (`:169-194`) compares the
  widget's verb, tense, pronoun, and identifier with the function the widget itself calls
  (`WidgetSnapshotWriter.swift:299`). Its check of the answer is real.
- Values compared with what produced them: `ChoiceQuestionTests` `:375`, `QuizHubTests` `:138`,
  `QuizScopeTests` `:272`, `SpeedRoundTests` `:304`.
- `GapSentenceTests.everyLevelAsksSentencesAndBeginnerOnlyItsTenses`: the second half is true by
  construction, since `isAskable(at:)` filters by the level's pool.

<a id="t2"></a>
### T2. The determinism tests see one process (Medium)

`DailyChallengeTests.theSameKeyDrawsTheSameChallenge` (`:57-66`) and
`QuizLevelTests.aSeedDrawsTheSameQuiz` (`:158-167`) draw twice in one process. Neither can see a
toolchain that samples differently, nor the removal of a sort that fixes a dictionary's order
(`QuizDraw.swift:198`), since that order is fixed within a process. `theSeedIsPinned` pins the
key's hash. `VerbDrawTests.theSeededGeneratorKeepsItsSequence` does pin `SplitMix64`'s first two
outputs, which Konjugieren lacked. Nothing pins what `Int.random`, `shuffled`, or
`randomElement` return for that generator, and no challenge's draw is pinned, as
`DailyChallenge.draw`'s comment says. The choice is drawn from the generator before the mixed
draw, so adding one item to `ChoiceQuestions.json` reshuffles every seeded default quiz.

**Fix.** Pin the sampling's outputs, and one challenge's draw over a small made-up verb list, so
that a verb import does not break it. Phase 8 takes these.

<a id="t3"></a>
### T3. Single-seed tests that chance would usually pass (Medium)

Each checks "distinct", "new", or "never twice running" on one seed against a pool large enough
that chance obliges. The share is the reviewer's estimate of how often the test would pass with
its guarantee deleted, from the pools' sizes or a script.

| Test | Guarantee | Passes without it |
|---|---|---:|
| `SpeedRoundTests.everyQuestionAsksAMasteredItemEachInTurnAndNeverTwiceRunning` (`:121-149`) | No item twice running | About 33% to 64% |
| `SpeedRoundTests.theRoundDrawsMoreAsItGoes` (`:322-341`) | The same, across a batch | About 48% |
| `VerbEssentialsTests.aRoundDrawsDistinctVerbsWithAnIrregularKeyConjugationFromTheBand` (`:100-110`) and `aRoundAsksFiveVerbsOfTheLevelsBandEachAsOneStep` (`:168-181`) | Five distinct verbs | About 84% |
| `VerbEssentialsTests.fiveMoreVerbsAreNewAndContinueTheSteps` (`:291-307`) | Fresh verbs first | About 62% |
| `GapSentenceTests.aRoundTakesOneSentenceAVerbAndTheUnaskedFirst` (`:266-276`), `aBeginnerRoundAsksTenSentencesOfItsTensesFromTenVerbs` (`:293-301`), and `aFinishedRoundKeepsItsResultAndTenMoreAsksNewSentences` (`:327-342`) | One sentence a verb; new sentences in Ten More | About 86% to 90% |
| `ChoiceQuestionTests.aRankedRoundScoresOutOfOneHundredAndTenMoreAsksANewChoice` (`:378-398`) | A choice not yet asked | About 97% |
| `RecognitionTests.aFinishedRoundKeepsItsResultAndTenMoreShowsNewForms` (`:299-316`) | No form shown twice | About 85% to 90% (Suspected) |

**Fix.** Loop over 100 or more seeds, or shrink the pool until chance cannot oblige.

<a id="t4"></a>
### T4. Tests that prove less than their names say (Read for the first two, Medium)

- `QuizPracticeTests.theDefaultQuizMixesInAtMostThreeDueItemsTheMostOverdueFirst` (`:99-112`)
  checks that the quiz has ten questions and then calls `QuizDraw.dueQuestions` directly.
  Passing `limit: 10` in `Quiz.draw` leaves it green.
- `SpeedRoundTests.nothingMasteredStartsNothingAndFiveStartARound` never tries four, and the
  model starts a round with three ([L17](#l17), Run).
- `GapSentenceTests.aVosLearnerIsAskedVos` (`:303-310`) asserts only that no question is tú. 94
  of the 741 sentences are second person, so a round of ten may hold none.
- `PracticeSetTests.aListAsksItsVerbsInOrder` tests the stored order. `scopedQuestions` shuffles
  the verbs before asking.
- `AnswerFrameTests.everyCellsWrittenAnswerFillsItsFrame` claims every cell the quiz can ask and
  iterates `DisplayTense.conjugatedTenses`, which holds neither the gerundio nor the participio.
- No test asserts that a model's first round draws five distinct verbs.

<a id="t5"></a>
### T5. The mix is tested on a quiz the app never starts (Read, Low)

`QuizVerbMixTests` and `QuizLevelTests.aQuizAsksEachWeightAtItsShare` draw thirty-question
`allVerbs` scopes, which are unranked, so they hold no choice question and no due items. The
`questionCount == roundLength` clause of `isRanked` exists to tell them from the app's quiz. The
one test of a real round, `aTenQuestionQuizMixesToo`, accepts four or five irregular questions of
nine where the code gives exactly four ([L15](#l15)). Nothing tests a ranked round with due items
mixed in.

<a id="t6"></a>
### T6. The drivers answer a choice by typing, and every suite writes its own (Run for the first, Low)

- Six suites' drivers answer whatever question is on screen through `process(proposedAnswer:)`,
  the choice included: `QuizTests` `:48`, `QuizRoundTests` `:33-46`, `QuizLeaderboardTests`
  `:28-32`, `QuizHubTests` `:25-34`, `QuizPersonalBestTests` `:32-43`, and `QuizScopeTests`
  `:275-288`. A wrong typed answer there inserts a re-ask the app never makes ([C11](#c11)). Only
  `ChoiceQuestionTests` uses `submitChoice`.
- `func makeQuiz` is defined in 18 files, a settings fake with a level and region is built 24
  times, `rightAnswer` 11 times, and there are 24 hand-written loops that answer until a quiz
  ends.
- Nothing guards the tests against a `CONJUGAR_QUIZ_FIXTURE` default left in the simulator.
  `Quiz.fixtureRun` reads `UserDefaults.standard` inside `Quiz.start`.
- Many tests never quit their quiz. Each leaves a `QuizAbandonment` entry in the shared
  `Current.getterSetter` and a repeating timer that nothing stops ([C2](#c2)).

<a id="t7"></a>
### T7. The wall clock, shared generators, and the simulator's language (Low)

- `.claude/rules/testing.md` asks for a fixed calendar and date. `daysAgo` in
  `QuizPracticeTests` (`:23-25`), `QuizRecordSessionTests` (`:30-32`), `QuizHubTests`
  (`:36-38`), and `SpeedRoundTests` (`:23-25`), and `DailySessionTests`' helper, count back from
  `Date.now` in 86,400-second days. `QuizHubTests` `:142` could fail at midnight.
- A `private static var generator` is shared by the tests of five suites (`QuizPracticeTests`
  `:179`, `QuizRecordSessionTests` `:272`, `SpeedRoundTests` `:95`, `VerbEssentialsTests` `:39`,
  `ModelPracticeTests` `:52`), so what each test draws depends on the order they ran in.
- Three helpers draw from the system's generator, so a failure could not be reproduced:
  `QuizTests` `:35`, `QuizScopeTests` `:33`, and `VerbCollectionTests` `:184`.
- Six tests assert English text (`AnswerDiagnosisTests.linesInEnglish`, `RecognitionTests`
  `:263-264` and `:309`, `GapSentenceTests` `:337`, `ChoiceQuestionTests.aReasonNamesItsTenses`,
  `DailyChallengeTests.theSharedTextIsTheAgreedText`), and the scheme's test action sets no
  language. The suite passes because Conjugar's simulator is English.

<a id="t8"></a>
### T8. Numbers tied to today's verbs, and names nothing pins (Low)

- `ModelPracticeTests` asserts 94 groups and 65 practiced alone (`:82-83`), the verb counts of
  particular models (`:68`, `:94-97`, `:315`), and the first three exemplars (`:103`).
  `MasteryTests` asserts 46 and 50 (`:124-125`). None says it is a tripwire, and the next verb
  import breaks each.
- No literal pins `tapDailyReminder`'s `enabled` values, `viewPracticeSet`'s `invalid`,
  `tapSharePracticeSet`'s `method` values, or the names `tapResetPractice`,
  `tapKeepPracticeSet`, and `viewMastery`.
- `Achievement.points` is read only by tests. The identifiers and points match
  `GameCenterResources.gamekit/gameCenterResources.json` today, checked by hand. No test
  compares them.
- `StandardVariants`' tables are keyed by 26 infinitives. All are in the verb map today
  (Script). No test sweeps them, and seven participle keys (refreír, suscribir, describir,
  prescribir, circunscribir, proscribir, adscribir) have no graded example, so a renamed verb
  would lose its variant silently.
- The two content checks are one loop and three helpers written twice (`GapSentenceTests`
  `:46-114`, `ChoiceQuestionTests` `:58-156`), and the choice check lacks the sentences' guard
  against a tú-only word outside the braces.

<a id="t9"></a>
### T9. What has no test (Low)

Beyond what the findings above name, by risk:

1. A miss, then a right re-ask, and what My Mistakes holds ([L1](#l1)).
2. A repaired diagnosis and the record ([L2](#l2)).
3. The parameters of `startQuiz`, `completeQuiz`, and `quitQuiz` ([P6](#p6)), and anything else
   in a quiz view.
4. What each of the three quiz links does over the results or a sheet ([C1](#c1), [C2](#c2)).
5. The challenge's key around midnight, and `DailyChallenge.draw` when all twenty attempts
   repeat a verb.
6. Choice exclusion across more than one Ten More.
7. A mixed model round when the known models change between rounds.
8. Decomposed accents in an answer, which work (Run) and are pinned nowhere.

<a id="konjugierens-findings-checked-here"></a>
## Konjugieren's Findings, Checked Here

Read after the findings above were written down. IDs are those of
[`../Konjugieren/plans/pedagogy_fixes.md`](../../Konjugieren/plans/pedagogy_fixes.md), all of
whose phases were "Not started" on 2026-11-27. A finding Konjugieren later fixes is still a
finding here, since the port carried the defect.

### Carried over in the port

| Konjugieren | Here | Evidence |
|---|---|---|
| L2: a right re-ask empties My Mistakes | [L1](#l1), the same code | Run |
| L3: a repaired diagnosis counts as right | [L2](#l2), the same code | Run |
| L4: the slip rule calls grammatical errors slips | [L10](#l10), narrower. Most classic Spanish errors are diagnosed first. dijieron, hablastes, and oies get through, and the minimum counts the frame's words here where it counted a digraph's letters there | Run |
| L5: an answer credits a key conjugation it never showed | [L4](#l4), narrower. A regular cell is a pattern here, so only irregular cells raise a key: tienes and ten for tengo | Run |
| L6: two reveals master a verb | [L5](#l5), the same code | Run |
| L7: opening a page erases the record | [L6](#l6), the same code | Run |
| L8: diagnoses that mislead | [L12](#l12), in part. No line here is false. Three point away from the lesson | Run |
| L9: a round asks a question twice | [L14](#l14). The default draw keeps its own questions distinct here (`QuizDraw`'s `fits`). Repeats come from due items and small scopes | Run |
| L11: the mix is for the drawn questions | [L15](#l15). Four of nine at three levels, every round | Run |
| L12: a quit challenge is taken again | [L16](#l16), the same code | Run |
| L13: "the same on every device" within one build | [L16](#l16). Here the code's comment and `feature_architecture.md` already say so. The link and the hub's string do not | Read |
| L14, the score: a choice of two in the ranked score | [L15](#l15) | Read |
| L15: the clock counts ticks | [L17](#l17). Here nothing watches the scene's phase at all | Read |
| L16: a ranked round mixes in due items | [L15](#l15) | Read |
| L17: the reminder counts what its session will not ask | [L20](#l20) | Reviewer |
| L19: dismissing the card hides its items | [L5](#l5) | Run |
| L21: the frame's own word typed into the blank | In part. "no hables" typed into `¡no [ ]!` is right here. "no arrepientas" typed into `¡no te [ ]!` becomes "no te no arrepientas", wrong at once, and a trailing period is a wrong letter ([L10](#l10)) | Run |
| C1: the reminder's unordered tasks | [C7](#c7) | Suspected |
| C2: the store keeps its calendar | [C8](#c8) | Read |
| C3: a session across midnight | [C3](#c3) | Run |
| C5: a failed decode replaced by nothing | [C12](#c12), in part. The browse fixes saved the record itself. Four small stores remain | Read |
| C6: the injected clock | [C4](#c4) | Read |
| C7: the challenge's smaller holes | [L16](#l16): twelve results, future dates, the stale row. A link to a taken challenge of another day opens the hub and shows nothing of it here too | Run and Read |
| C8: the cap does not keep a QR code coarse | [C5](#c5). 171 modules of 177 for the worst hundred | Run |
| C9: a shared My Verbs carries recent lookups | [C5](#c5) | Read |
| P1: a one-verb group's key names the verb | [P1](#p1). Models here, 29 of them, against 18 ablaut groups | Read |
| P2: the browse fix left Share open | [P2](#p2), the same code | Read |
| P3: a second round of My Mistakes | [P3](#p3) | Run |
| P4: sources that exist only after the record says something | [P4](#p4) | Read |
| P7: "(not which)" is untrue of a collection | [P5](#p5) | Read |
| P8: Decision 5 held by vigilance | [P6](#p6). Here the parameters are also assembled in a view | Read |
| P9: the analytics vocabulary decides behavior | [P7](#p7) | Read |
| G2: `feature_architecture.md`'s analytics rows | [G1](#g1) | Read |
| G4: comments that say what the code does not | [G2](#g2): the schedule's header, the record's comment, and `Mastery.intro` | Read |
| S1, S2, S3: the modes' parallel paths, `QuizView`, the kind beside its fields | [S1](#s1), [S2](#s2), [S3](#s3) | Read |
| S4, S5: one rule written several times | [S4](#s4) | Read |
| S7: the store holds six things, and Reset lives in a view | [S5](#s5). Here Reset does forget first opens | Read |
| S8: small things | [S8](#s8), and [C11](#c11) for the missing guard against a choice | Read |
| T2: the determinism tests see one process | [T2](#t2). `SplitMix64`'s first two outputs are pinned here. The sampling and a draw are not | Reviewer |
| T3: single-seed tests that chance would pass | [T3](#t3) | Reviewer |
| T4: at most three due items is not shown | [T4](#t4) | Read |
| T5: numbers tied to today's verbs | [T8](#t8) | Reviewer |
| T6: drivers that type into a choice, and a fixture default nothing guards | [T6](#t6) | Run and Reviewer |
| T7: the suite depends on the simulator's language | [T7](#t7) | Reviewer |
| T9: what has no test | [T9](#t9) | Reviewer |
| G5: `StandardVariants`' keys are unchecked | [T8](#t8) | Reviewer |

### Did not carry over

- **L10: a custom quiz of verbs alone lifts the level's restrictions.** `CustomQuiz.pool(level:)`
  returns the level's own pool when no tense is chosen, and Conjugar restricts no cell to certain
  verbs.
- **L14, the English: a choice's English answers it.** Conjugar holds the English until the
  choice, which is the fourth of the Closing's porting notes.
- **P5: a staged paragraph says nothing on the screen is sent.** No such sentence is staged here.
- **P6: the staged text omits the wrong answers kept for the Tutor.** Conjugar keeps none: there
  is no `QuizErrorHistory`. The staged paragraphs do say that opened verbs and practiced
  conjugations are kept on the device.
- **P10: a comment says the right answer reaches telemetry.** No such comment here.
- **G3: `docs/release.md` lacks the Camera's QR check.** It passed on 2026-11-24 and is recorded.
- **G4, the challenge's comment.** Conjugar's says the tests pin "the seed and the draw's
  determinism rather than a list of questions", which is what they do.
- **S6: one set of strings holds three kinds of key.** Each draw here takes the session's earlier
  questions and reads its own kind from them.
- **T1: two tests assert five strong questions.** No test here asserts an exact count on a ranked
  round. The one test of a real round is looser than the code ([T5](#t5)).
- **T4's other three.** Conjugar has no pause to test. Its reminder test runs on the injected
  clock, at ten in the morning. Its wrong-round test asserts that the round started.
- **T6's shared state.** No pedagogy suite assigns `Current`, and every `Quiz` has its own store,
  which the browse fixes' Phase 13 did.

### Do not apply to Spanish

- **L1, as stated** (the Imperativ of the modals, persons German lacks). Conjugar's engine marks
  the truly defective verbs. The Spanish counterpart is [L7](#l7), which is about use and not
  about forms that do not exist.
- **L4's digraph parts, L20** (a digraph marked as an error), **C4** (the Swiss ß in Name the
  Conjugation), and **T8** (content checks that fold ß) rest on umlauts and ß. Spanish has no
  accepted respelling, and both content checks compare the engine's form.
- **L8's particulars** (the weak-verb line, Duden's doublets) and **D4** and **D8** are German
  grammar. Conjugar's counterparts are [L12](#l12) and [D8](#d8).
- **L18** names German sentences. Conjugar's own are under [L21](#l21).
- **G1** concerns Konjugieren's research report. Conjugar has none of its own.

### Found here and not in Konjugieren's review

[C1](#c1) (a quiz link over the results), [C2](#c2) (a sheet's quiz torn down), [L3](#l3) (a
review never asks the form missed), [L8](#l8) (the weights), [L9](#l9) (the -ir stem changers in
the exercises), [L11](#l11) (a reflexive command without its pronoun), [L13](#l13) (vayamos),
[L18](#l18) (a sentence that names its tense), [L19](#l19) (Advanced's verbs), the vos learner's
challenge in [L16](#l16), the uncapped list and the borrowed source in [C5](#c5), [C6](#c6),
the calendar system in [C8](#c8), [C9](#c9) (the accent keys), [C10](#c10) (the Live Activity),
[A1](#a1) to [A4](#a4), and the progress bullet in [P5](#p5). Several are Spanish alone. C1, C2,
L3, C6, C10, A2, and the uncapped list may exist in Konjugieren too. I did not look, as the
prompt asked.

<a id="decisions-for-josh"></a>
## Decisions for Josh

Each was a question the code cannot settle. **Josh answered all 23 on 2026-11-27**, taking the
recommendation each time, and the answer follows each decision. The options are kept so that a
later reader can see what was weighed. Where Konjugieren's plan records his answer to the same
question that day, the recommendation was that answer. Build to the answer. Where an answer
leaves a list, a line, or an entry for Josh to review, the phase says so, and its session brings
him that before building on it.

<a id="d1"></a>
**D1. What happens to a quiz in a sheet when a link arrives?** ([C2](#c2))

- (a) The sheet's quiz stays. A `quiz/start`, `quiz/daily`, or `quiz/challenge` link, and a
  waiting practice set, wait until it ends.
- (b) The link wins, and the sheet's quiz is quit as Quit would quit it.
- (c) As now.

**Recommended: (a).** It agrees with Josh's ruling of 2026-11-25 for the browse fixes, that a
link closes the game and leaves alone the sheets that views own. Under any answer, a quiz that
does go away quits properly.

**Answered (Josh, 2026-11-27): (a). The sheet's quiz stays, and the link or the waiting practice set waits until it ends.**

<a id="d2"></a>
**D2. When does a miss leave My Mistakes?** ([L1](#l1))

- (a) On a right answer that is neither a re-ask nor a repaired second attempt: in a later
  question on the same item, or in My Mistakes itself.
- (b) As now, on any right answer, the re-ask's included.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27).** A right re-ask and a right
second attempt, a slip's included, leave the miss on the list.

**Answered (Josh, 2026-11-27): (a). A right re-ask and a right second attempt, a slip's included, leave the miss on the list.**

<a id="d3"></a>
**D3. What does a repaired diagnosis do to the record?** ([L2](#l2))

- (a) It counts as wrong for the record: the item starts over and enters My Mistakes. The half
  points stay.
- (b) It counts as neither: the item keeps its box and its due date, and enters My Mistakes.
- (c) As now, it counts as right.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27).** A slip's repair still counts as
right for the box, once [L10](#l10) has made a slip mean a typing slip.

**Answered (Josh, 2026-11-27): (a). A repaired diagnosis counts as wrong for the record. A slip's repair still counts as right for the box.**

<a id="d4"></a>
**D4. Should a review ask the form that was missed?** ([L3](#l3))

- (a) Yes. The record remembers the cell last missed, and for a pattern the verb. Review and My
  Mistakes ask that cell while the miss stands, and otherwise draw among the irregular cells
  built on the key.
- (b) Only the draw: a review asks any irregular cell built on the key, not always the key's own.
- (c) As now.

**Recommended: (a).** Konjugieren's review did not ask this. Its D5 answers the other half
([D5](#d5) here). The remembered cell is an optional field, so stored records still decode.

**Answered (Josh, 2026-11-27): (a). The record remembers the cell last missed, and for a pattern the verb.**

<a id="d5"></a>
**D5. Which answers may raise an irregular verb's key conjugation?** ([L4](#l4))

- (a) A wrong answer on any cell built on the key still sends the item back. A right answer
  raises it only on a cell that shows what the key shows: for the yo presente, a cell with the
  same irregular letters (tenga for tengo, not tienes or ten); for the yo pretérito, a cell on the
  same stem.
- (b) The cells that show something else (tienes, ten, era) become items of their own or
  patterns.
- (c) As now.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27).** The rule should come from the
engine, by comparing the letters it marks irregular in the two forms, and not from a list of
persons.

**Answered (Josh, 2026-11-27): (a). A right answer raises a key only on a cell that shows what the key shows, judged from the engine's marked letters.**

<a id="d6"></a>
**D6. How far can the review card raise an item, and what does dismissing it do?** ([L5](#l5))

- (a) A reveal raises an item no further than the second box, so that only a typed answer reaches
  mastery.
- (b) After the reveal the card asks "Knew them" or "Didn't", and only the first raises.
- (c) A reveal reschedules and never raises.
- (d) As now.

And for a card dismissed unrevealed: (i) hide the card for the day and leave its items due for
Review and the daily session, or (ii) as now, snooze the items.

**Recommended: (a), and (i), Josh's answers for Konjugieren (2026-11-27).** An item already in
the second box or above is rescheduled by a reveal at its own box.

**Answered (Josh, 2026-11-27): (a), and (i). A reveal raises an item to the second box at most, and a dismissal hides the card for the day and leaves its items due. This replaces the browse plan's rules that a revealed card always moves an item up and that a dismissal snoozes it.**

<a id="d7"></a>
**D7. When does opening a verb's page send its key conjugations back to the first box?**
([L6](#l6))

- (a) Never. A lookup only enters items that are not yet in the record.
- (b) Only from search, the one route that says "I had to look this up": a result, the guess, and
  Look Up a Verb. Not from a correction's link, My Verbs, a related verb, a model or a
  collection, the widget, Spotlight, or a link.
- (c) From any route, but one box down rather than to the start.
- (d) As now.

**Recommended: (b), Josh's answer for Konjugieren (2026-11-27).** There it replaced his earlier
rulings, the widget's included. Every other route enters a verb's items if they are new and
demotes nothing, and Test Me's right answers can then raise an item.

**Answered (Josh, 2026-11-27): (b). Only search demotes: a result, the guess, and Look Up a Verb. This replaces the earlier rule that any open but the review card's restarts the verb, the widget's included.**

<a id="d8"></a>
**D8. Are dijieron, hablastes, and oies typing slips?** ([L10](#l10))

- (a) Leave them as slips. Simplest.
- (b) Name them, with new lines for Josh to review in both languages, such as "After the j of
  this pretérito, the ending is -eron." and "The tú pretérito has no final s."
- (c) Wrong at once, with no second attempt.

**Recommended: (b), by Josh's answer to the like question for Konjugieren (its D4,
2026-11-27).** Under [D3](#d3) a repaired one then counts as wrong for the record.

**Answered (Josh, 2026-11-27): (b). The three errors are named, with new lines that Josh reviews in both languages before they ship.**

<a id="d9"></a>
**D9. Is a reflexive-only verb's command right without its pronoun?** ([L11](#l11))

- (a) No. Only atrévete is right. "atreve" is one edit short of nothing accepted, so it goes to
  the correction, which shows atrévete.
- (b) As now.

**Recommended: (a).** The bare gerundio stays accepted.

**Answered (Josh, 2026-11-27): (a). Only the form with its pronoun is right for a reflexive-only verb's affirmative command. The bare gerundio stays accepted.**

<a id="d10"></a>
**D10. Three rulings on what is right and what a line says.** ([L12](#l12), [L13](#l13))

- **vayamos.** Accept it beside vamos for ir's nosotros command? **Recommended: yes**, after the
  session reads the *Diccionario panhispánico de dudas* on ir and brings Josh the entry, as Phase
  0's audit did for its rows.
- **A leading que** before a subjunctive ("que hable"). Forgive it, as a subject pronoun is
  forgiven? **Recommended: yes**, for the subjunctive tenses only.
- **A dropped accent that lands on a tense the session does not ask** (hablare for hablaré).
  Name the tense, or say "Almost!"? **Recommended: "Almost!"** when the answer differs from a
  right one only in accents and the cell it matches is in a tense outside the session's pool.
  Within the pool, hablo for habló keeps its line.

**Answered (Josh, 2026-11-27): vayamos is accepted once the session has read the *Diccionario panhispánico de dudas* on ir and shown Josh the entry; a leading que is forgiven before the subjunctive tenses only; and an accent-only miss that lands on a tense outside the session's says "Almost!".**

<a id="d11"></a>
**D11. Which commands should the quiz never ask?** ([L7](#l7))

- (a) No command of haber, and none of the verbs on a list Josh reviews: verbs said of things
  rather than to people (ocurrir, suceder, existir, resultar, parecer, gustar and its kind) and,
  if he wishes, poder, deber, and soler. The rule holds in every quiz, the challenge and the
  widget included. The verb page is left alone.
- (b) haber only, by a rule in the code.
- (c) As now.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27)**, with a shorter list than
German's: sepa and quiera are commands people give, so saber and querer stay. The session drafts
the list from the 1,000 most frequent verbs and brings it to Josh before marking any.

**Answered (Josh, 2026-11-27): (a). No command of haber, and none of the verbs on a list the session drafts and Josh reviews before any is marked. saber and querer stay.**

<a id="d12"></a>
**D12. The weights.** ([L8](#l8))

- (a) Commands weigh 1 at every level, so a Beginner round is one command in four. The two
  imperfectos de subjuntivo weigh 1 each, a tense's weight between them.
- (b) Commands weigh 1 at Beginner only.
- (c) As now.

And should a session first check the ladder against the *Plan curricular*, as Phase 4 meant to?

**Recommended: (a), and yes.** Konjugieren's review did not ask about weights, so this has no
answer to borrow.

**Answered (Josh, 2026-11-27): (a), and yes. Commands weigh 1 at every level and the two imperfectos de subjuntivo 1 each, after a session has compared the ladder with the *Plan curricular* and brought Josh any disagreement.**

<a id="d13"></a>
**D13. Which verbs does Advanced draw?** ([L19](#l19))

- (a) Every verb, but weighted toward use: most questions from the 1,000 most frequent, and the
  rest from beyond.
- (b) A band of its own, such as the 3,000 most frequent.
- (c) As now, uniformly over all 4,811.

**Recommended: (a).** It keeps "every verb" true of the level and stops rare verbs from being
half of it.

**Answered (Josh, 2026-11-27): (a). Every verb, weighted toward use. The session proposes the share that comes from the 1,000 most frequent and tells Josh what it chose.**

<a id="d14"></a>
**D14. What does a round do when its scope has fewer than ten distinct questions?** ([L14](#l14))

- (a) It is shorter. A one-verb model at Beginner asks what it has.
- (b) It repeats to reach ten, with repeats as far apart as the round allows.

And should Ten More avoid the questions of the session's earlier rounds while others remain? And
should a second attempt identical to the first be ignored?

**Recommended: (a), and yes, Josh's answers for Konjugieren (2026-11-27), and yes.**

**Answered (Josh, 2026-11-27): (a), yes, and yes. A small scope's round is shorter, Ten More avoids the session's earlier questions while others remain, and a second attempt identical to the first is ignored.**

<a id="d15"></a>
**D15. What is the mix a promise about, and what does a ranked round hold?** ([L15](#l15))

- **The mix.** (a) The whole round of ten: draw ten, then let due items and the choice take slots
  of matching role and irregularity where they can. (b) The drawn questions alone, with the doc
  corrected to say so.
- **Due items in a ranked first round.** (a) Keep them. (b) Mix them in from Ten More on, so that
  every ranked round is the level's own mix. (c) Rank only a round with none.
- **The choice question's ten points.** (a) Keep the round out of 100. (b) Leave the choice out
  of the posted score.

**Recommended: the mix (a), due items (b), the points (a), Josh's answers for Konjugieren
(2026-11-27).** The second narrows the rule that a default session mixes in up to three due
items: the first round would have none, and Ten More, the daily session, and Review ask them.

**Answered (Josh, 2026-11-27): the mix (a), due items (b), the points (a). The mix is of the whole round of ten, due items join from Ten More on, and the choice keeps its ten points. The second narrows the rule that a default session mixes in up to three due items.**

<a id="d16"></a>
**D16. Should the exercises ask a key's irregular cell when its own is regular?** ([L9](#l9))

- (a) Yes. Verb Essentials and Verb Models ask él pidió where pedí is regular, the row names the
  person, and the model's group counts that item. The four-form line shown and shared stays
  yo's.
- (b) As now.

**Recommended: (a).**

**Answered (Josh, 2026-11-27): (a). The exercises ask a key's first irregular cell where its own is regular. The four-form line stays yo's.**

<a id="d17"></a>
**D17. How much should Complete the Sentence say about the tense?** ([L18](#l18))

- (a) As now: the tense is named, and the English shows from the start.
- (b) The tense is hidden where a flag on the sentence says its context forces it (a subjunctive
  trigger, a si clause, ojalá), which means a pass over the 741 sentences for second answers.
- (c) Only the mood is named, with the same pass.

**Recommended: (a) for now, and (b) with the next batch of sentences**, when someone is reading
them anyway. Under (b) or (c) the English moves to after the answer.

**Answered (Josh, 2026-11-27): (a) for now, and (b) with the next batch of sentences. Nothing is built for this until then.**

<a id="d18"></a>
**D18. Three rulings on the daily challenge.** ([L16](#l16))

- **A quit challenge.** (a) It is taken from its first answer, with its unanswered questions
  counted wrong, and leaving the app during one counts as quitting it. (b) It may be taken again,
  and its result cannot be shared. (c) As now.
- **Across versions.** (a) Accept "the same within a version", and put a content version in the
  link, so that the app can say when a friend's link comes from another version. (b) Freeze a
  list of verbs for each level. (c) Put the five questions in the link.
- **tú and vos.** (a) The challenge draws no second-person-singular cell whose tú and vos forms
  differ in irregularity, so that both learners answer questions of the same kind. (b) The key
  gains the second person, and a tú learner and a vos learner have different challenges. (c) As
  now.

**Recommended: (a) and (a), Josh's answers for Konjugieren (2026-11-27), and (a).** The third is
Conjugar's alone. Phase 23's session chose today's behavior without asking.

**Answered (Josh, 2026-11-27): (a), (a), and (a). A challenge is taken from its first answer, the link carries a content version, and the draw takes no second-person-singular cell whose tú and vos forms differ in irregularity.**

<a id="d19"></a>
**D19. Does leaving the app pause the Speed Round?** ([L17](#l17))

- (a) No. The minute is a minute.
- (b) Yes, with the clock measured in time rather than ticks.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27).**

**Answered (Josh, 2026-11-27): (a). The minute is a minute.**

<a id="d20"></a>
**D20. May a quiz or share signal name a model?** ([P1](#p1), [P2](#p2), [P5](#p5))

- (a) No. `startQuiz` and `tapShareCollection` send `collection: model` for any model, of one
  verb or of forty. The five fixed lists keep their keys.
- (b) Only the 29 one-verb models are withheld.
- (c) Keep the keys, and say in the docs and the policy that a model's name is sent and that for
  some models it is a verb.

**Recommended: (a), Josh's answer for Konjugieren's ablaut groups (2026-11-27).** There the
answer was not asked of `viewCollection`, which kept a group's key outside a correction, as the
browse fixes decided. Ask Josh whether that holds here too.

**Answered (Josh, 2026-11-27): (a) for `startQuiz` and `tapShareCollection`. `viewCollection` keeps a model's key outside a correction, as the browse fixes decided.**

<a id="d21"></a>
**D21. How often does a Review or My Mistakes session report its completion?** ([P3](#p3))

- (a) Once, at its first round. A later round sends no `completeQuiz`.
- (b) Each round, as now, with the staged sentence corrected to say that a second round shows
  more than ten were due or missed.

**Recommended: (a), Josh's answer for Konjugieren (2026-11-27).** Ask also whether a record
session should send `duration`.

**Answered (Josh, 2026-11-27): (a), and a Review or My Mistakes session sends no `duration` either.**

<a id="d22"></a>
**D22. Are `speedRound`, `modelMixed`, `review`, and `mistakes` surfaces?** ([P4](#p4))

Each can be sent only after the record says something about how the learner did. Extend to them
the rule that a source names a surface and not a count, and record it? Or stop sending them?

**Recommended: they are surfaces, Josh's answer for Konjugieren (2026-11-27)**, recorded in the
staged policy's notes.

**Answered (Josh, 2026-11-27): they are surfaces, and stay.**

<a id="d23"></a>
**D23. Two rulings on a shared practice set.** ([C5](#c5))

- **What a shared My Verbs carries.** (a) The starred verbs alone. (b) As now, with the menu
  saying how many verbs go.
- **The cap.** A list of 30 makes a code a classroom can scan. A list of 100 does not. Which
  matters more for a QR code, and should a link, which has no such limit, keep 100?

**Recommended: (a), and 30 verbs for a QR code, 100 for a link, Josh's answers for Konjugieren
(2026-11-27).** The QR screen says so when the list is longer than its code carries.

**Answered (Josh, 2026-11-27): (a), and 30 verbs for a QR code, 100 for a link.**

**Smaller questions a session should put to Josh when it reaches them,** each recorded where it
arises: where the Game Center alert first appears ([G4](#g4)); whether `ChangeLevelTip` belongs
on the hub's level tile ([G4](#g4)); whether Name the Form's prompt shows the red letters
([L21](#l21)); and the wording [G4](#g4) lists as never judged.

## How to Work This Plan

**Choosing a phase.** Take the lowest-numbered phase that is not done and whose dependencies are
done. Each phase names them. If a phase proves too large
for one session, split it, say so in its row, and leave the remainder "Partly done". Phases 2, 5,
and 14 are the likeliest to need it.

**Find code by name.** Every finding gives a type and a function with its line. The line is that
of `2e5a74b`.

**A finding labelled Suspected or Reviewer is not yet a fact.** Confirm it in the code, or by
running something, before fixing it. If it turns out not to be real, say so under the finding and
in **How it differed**, and move on.

**Ask Josh rather than guess.** His answers of 2026-11-27 are under Decisions for Josh, and each
phase restates the ones it builds. Where an answer does not settle a question that comes up, ask
him before building the part that depends on it, and record his answer and its date under the
decision and in the phase's **How it differed**.

**What this plan leaves to you.** The phases say what to fix and what must hold afterward. Each
finding suggests a fix, and a better one is welcome. Record in **How it differed** anything that
departs from the phase as written. A later session relies on that note more than on the phase
text.

**Every phase finishes the same way.**

1. Each fix gets a test that fails without it, in Swift Testing, following
   [`.claude/rules/testing.md`](../.claude/rules/testing.md). Run the new test against the old
   code first and see it fail. Where a property is guaranteed by construction, test it over many
   seeds or on a pool small enough that chance cannot pass it. Inject dates and calendars, and do
   not read the wall clock. Give every `Quiz` a `PracticeStore` of its own.
2. Build and run the suite with the `ios-build-verify` skill, as `CLAUDE.md` describes. **Read
   the run's `Test run with N tests` line, not only its exit status**: a `--only-testing`
   selector that names a suite by its display string runs zero tests and still says "Test
   Succeeded". The baseline at `2e5a74b` is 1,499 Swift Testing tests in 93 suites, plus 11 XCTest
   tests, in about 79 seconds, in English. Conjugar's simulator runs in English, so no
   `-testLanguage` flag is needed. Say in the note which language the suite ran in.
3. Run `swiftlint` from the repo root. The tree stays at zero violations.
4. For a change a learner can see, launch the app and look, on "Conjugar iPhone 17"
   (`6318CA93-7FB5-4E19-B318-915010531F76`) and "Conjugar iPad Pro 11"
   (`3033197E-B596-4C49-AAD8-43373B9D254C`), as `CLAUDE.md` § Running the App in the Simulator
   describes. Never use another project's simulators. Name the UDID in every `simctl` command.
   Boot the iPad only for its check and shut it down afterward. Josh tries changes on an iPhone,
   so the session's check is the only one the iPad gets. The quiz's `CONJUGAR_QUIZ_FIXTURE`
   launch argument gives fixed questions. To seed the App Group's defaults, write the container's
   own plist with `plutil` while the app is terminated. Say in **How it differed** what was tried
   on each device.
5. Localize any new string in English and Spanish, following `CLAUDE.md` and
   [`.claude/rules/localization.md`](../.claude/rules/localization.md). Never use the Edit tool
   to add or change an ASCII `"` inside an `.xcstrings` value. A new quiz state needs a VoiceOver
   announcement a learner can act on, with its Spanish tagged Spanish.
6. A change to a signal, a parameter, or a value is staged in
   [`docs/privacy_policy_pending.md`](../docs/privacy_policy_pending.md) in both languages and
   reflected in [`docs/feature_architecture.md`](../docs/feature_architecture.md#analytics). No
   signal may carry an answer, a score, an accuracy, or a verb.
7. Update [`docs/project_structure.md`](../docs/project_structure.md) for new, renamed, or
   repurposed files, and correct any other doc the fix makes untrue. A task left for release time
   goes in [`docs/release.md`](../docs/release.md).
8. Under each finding fixed, in this file, add a line saying it was fixed on `master`, with the
   date and the phase, and how if not as suggested. Fill in the Status row with "Awaiting Josh",
   leave its Commit cell empty, write **How it differed**, and append a journal entry to
   `docs/blog_notes.md` (`## <Title> (YYYY-MM-DD)`, narrative, no em dashes between clauses).
9. **Stop before git.** Do not run `git add`, `git commit`, or `git push`, and do not create a
   branch. Leave the changes in the working tree on `master` and tell Josh what changed and how
   to try it: which screens to open, and what to type or tap, on which device. Each phase's
   **Tell Josh to try** is the start of that message. Only when he says he has tried it and to
   commit is anything committed, and only then does the row become "Done" with its hash in the
   Commit cell. This holds for every phase and the Closing.

**A probe is not a test.** A temporary suite that prints what the code does is a good way to
confirm a finding. Delete it before the phase's final run, since it changes the test count.

**Comments say why the code is as it is, never how it came to be.** No phase numbers, plan
names, sibling apps, dates of decisions, or `// MARK:` lines in code, in test names, or in
long-lived docs. That history belongs in this file's notes and the journal.
`plans/sweep_comments.md` has the full rule.

**No release before 2027.** Everything accumulates on `master`. Nothing here has reached a
learner, so no stored format needs a migration unless the code already promises one. A new field
on a stored record is optional, so that records written before it still decode.

**Conjugar only.** Do not port a fix to Konjugieren or Conjuguer, and do not edit their files.
The Closing lists what would carry over.

**Subagents.** No phase requires them. A session that delegates follows the pedagogy plan's rule,
Sonnet subagents, and reads and checks their work itself. Josh may overrule that.

## Decisions Already Made

These bound the fixes. Each is Josh's, from the pedagogy plan and the browse fixes. His 23 answers of 2026-11-27 are under
[Decisions for Josh](#decisions-for-josh). Three of them replace an earlier ruling: [D6](#d6) the
review card's, [D7](#d7) the lookup's, and [D15](#d15) the due items' place in a default quiz's
first round.

- **Practice, not examination** (Decision 2). Where a choice between the two arises, choose
  practice.
- **No signal carries an answer, a score, an accuracy, or a verb** (Decision 5), and no mode
  sends `score` (2026-11-24).
- **A right second attempt and a right re-ask earn half points** (T1.6). No fix here changes
  points.
- **Re-ask once, not until correct** (T3.1).
- **Neither imperfect subjunctive is accepted for the other** outside a sentence, and the swap is
  named (2026-11-22).
- **Levels are chosen, not earned**, and what was opened does not shape the default quiz (T2.4).
- **The kinds of practice item** are an irregular verb's key conjugations and a regular pattern
  (2026-11-22). [D4](#d4) and [D5](#d5) ask what a review asks and what raises an item, not
  whether to keep the kinds.
- **A sentence accepts every form it allows**, either imperfect subjunctive included.
- **The four key conjugations are yo's** (tengo · tuve · tendré · tenido), and no "principal
  parts" label appears anywhere. [D16](#d16) changes what two exercises ask, not the line.
- **The sad trombone stays**, and so does the collection progress that Clear leaves.
- **A link that arrives during the game closes the game. Sheets that views own are left alone**
  (2026-11-25). A practice set's link dropped behind another sheet is left as it is
  (2026-11-24).
- **`viewCollection` after a correction carries no `collection`**, and the staged wording about
  it stays (2026-11-25).
- **The practice record's migration is deleted at release time**, by a step in `docs/release.md`.

Defaults this plan chose without asking, because the review left one reasonable course. Josh may
overrule any of them:

- **[C1](#c1).** A quiz link that arrives over the results pops them and starts the quiz, as a
  daily session's link does.
- **[C3](#c3).** A daily session counts for the day it began.
- **[C9](#c9).** An iPad has the letter keys under the field at any width.
- **[C10](#c10).** A quit dismisses the Live Activity at once, and a finished one opens the Quiz
  tab without starting a quiz.
- **[L10](#l10).** The slip's four-letter minimum counts the blank's own letters, a grave accent
  is an accent, and a trailing period is ignored.
- **[C5](#c5).** A decoded list is capped as a shared one is, and a set's link may name only
  `sharedLink` or `qrCode` as its source.

## Phase 1: Links, Sheets, and the Live Activity

**Findings:** [C1](#c1), [C2](#c2), [C10](#c10), [C11](#c11). **Depends on:** nothing.
**Decisions:** [D1](#d1), answered.

- One pure function decides what a `quiz/start`, `quiz/daily`, or `quiz/challenge` request does,
  given whether a quiz is in progress, whether results are on screen, whether a sheet's quiz is
  running, and whether the challenge is taken. `QuizView`'s three handlers call it. A request
  over the results pops them first.
- A quiz in a sheet that leaves the hierarchy while in progress quits: `quitQuiz` is sent, its
  `QuizAbandonment` entry is cleared, and its timer is stopped. `Quiz` invalidates its timer
  when it is deallocated.
- **A link during a sheet's quiz ([D1](#d1)).** The sheet's quiz stays. `AppRouter` keeps a
  waiting practice set, and the tab holds the three quiz requests, until the sheet's quiz ends. A model's practice started from the hub must not be popped by the tab's own
  `navigationPath` reset.
- `Quiz.process(proposedAnswer:)` and `processRecognition` refuse an answer while the quiz is
  held or not in progress, and `process` refuses a choice question. Fix the tests' drivers that
  type an answer into a choice ([T6](#t6)) in the same change, or the suite breaks.
- A quit is a state of its own, and `canContinue` asks it.
- The Live Activity: a finished one reads as finished, a quit dismisses it at once, the Lock
  Screen's view carries a link, that link opens the Quiz tab without starting a quiz, and
  `totalQuestions` does not count re-asks.
- Correct `QuizSheet`'s comment and `docs/feature_architecture.md` § Test Me.

**Done when** tests pin: the request function for every combination of its inputs; a quiz
dropped mid-question leaves no `QuizAbandonment` entry and has sent `quitQuiz`; `process` called
during a held correction changes nothing; a typed answer to a choice question changes nothing.
And in the simulator: `conjugar://quiz/start` over the results shows the first question, with no
row of the new quiz anywhere; a reminder's link during a practice set's quiz does what D1 says.

**Tell Josh to try:** finish a round, lock the phone, and tap the quiz's Live Activity. Start a
practice set's quiz from a link and, mid-question, tap a daily reminder or the verb widget. Quit
a quiz at question 4 and look at the Lock Screen.

**How it differed:**

## Phase 2: What an Answer Does to the Record

**Findings:** [L1](#l1), [L2](#l2), [L3](#l3), [L4](#l4), [C4](#c4). **Depends on:** nothing.
Phase 4 decides what a slip is, and this phase's table already treats a slip and a diagnosis
apart, so neither waits for the other. **Decisions:** [D2](#d2), [D3](#d3), [D4](#d4),
[D5](#d5).

- Thread `Quiz`'s injected clock to every read and write of the record first:
  `practice.recordAnswer`, a record session's items, `canContinue`, `askableCount`, `startDate`,
  `durationBand`, and the last result's date. The tests below need it.
- `PracticeRecord.recordAnswer` learns what kind of answer it records:

  | Answer | The box | `lastAnswerWasRight` |
  |---|---|---|
  | Right at the first attempt | Up when due, as now, where [D5](#d5) allows | True, which takes a miss off My Mistakes |
  | Wrong | Back to the first, as now | False |
  | A slip's right repair | Up when due, as now | Left as it was ([D2](#d2)) |
  | A diagnosis's right repair | Back to the first ([D3](#d3)) | False ([D3](#d3)) |
  | A right re-ask | Unchanged, as now, since the item is not due | Left as it was ([D2](#d2)) |

  The half points are untouched throughout.
- **The cell missed ([D4](#d4)).** `PracticeRecord.Entry` gains optional fields for the cell
  last missed and, for a pattern, its verb. `QuizDraw.recordQuestions` asks that cell while the
  miss stands and the settings allow it, and otherwise draws among the irregular cells built on
  the key. A right answer that clears the miss clears the fields.
- **What raises a key ([D5](#d5)).** `PracticeItem.exercised(by:)` says, with the item, whether
  a right answer on that cell may raise it. The rule comes from the engine's marked letters.
- Correct `PracticeStore.recordAnswer`'s comment, the comments [G2](#g2) lists on the second
  attempt, and `docs/feature_architecture.md:754` and `:760`.

**Done when** tests pin, with injected dates: a miss, then a right re-ask, leaves the item in My
Mistakes, and a right first answer on it in a later round takes it off; the same for a miss on a
round's last question; "tení" then "tuve" leaves the item in the first box and in My Mistakes,
with 5 points; a slip's repair raises a due item and does not clear a miss; a miss on tengas is
asked again as tengas, on era as era, and on pensamos as pensar's nosotros; tienes and ten right,
three days apart, do not master tengo, and tengo twice does; a wrong tienes sends tengo back; a
miss on day 0 is due in day 1's daily session; a record written before the new fields decodes.

**Tell Josh to try:** miss a question, answer its re-ask right, finish, and open Practice My
Mistakes. Type "tení" for tuve, then "tuve", and look at My Mistakes and Mastery.

**How it differed:**

## Phase 3: Lookups and the Review Card

**Findings:** [L5](#l5), [L6](#l6), [P7](#p7), and from [G2](#g2) the schedule's header and
`Mastery.intro`. **Depends on:** nothing, though it edits `PracticeRecord` as Phase 2 does, so
take them in order. **Decisions:** [D6](#d6), [D7](#d7).

- `PracticeStore.recordLookup` and `VerbView.send` take what they need by name (whether this
  visit reschedules, whether it is a return), not an `AnalyticsSource` to compare.
- **A lookup ([D7](#d7)).** Only a verb opened from search sends its
  key conjugations back to the first box: a result, the guess, and Look Up a Verb. Name the
  routes in one place. Every other route enters a verb's items if they are new and changes
  nothing else.
- **A reveal ([D6](#d6)).** It raises a due item to the second box at most. An item already there
  or above is rescheduled at its own box.
- **A dismissal ([D6](#d6)).** A card dismissed unrevealed is hidden for the day, and its items
  stay due. The day's dismissal needs remembering somewhere other than the items' due dates.
- Reword `ReviewSchedule`'s header and `Mastery.intro`, in both languages, to say what the code
  then does. Correct `docs/feature_architecture.md` § The Review Card and the practice record's
  section.

**Done when** tests pin: a verb in the fourth box keeps its box when opened from a correction,
My Verbs, a related verb, a model, the widget, Spotlight, and a link, and returns to the first
when opened from search; a correction's link leaves the keys that were not missed where they
were; Test Me's right answers on a verb just opened from its page raise a due item; a lookup and
two reveals leave a verb in the second box, not mastered, with no achievement progress; a card
dismissed unrevealed leaves today's Review count unchanged and does not return that day.

**Tell Josh to try:** open a mastered verb from the widget and from a correction, and look at
Mastery. Search a verb, then reveal its card on two later days.

**How it differed:**

## Phase 4: A Slip Is a Typing Slip, and Lines That Teach

**Findings:** [L10](#l10), [L11](#l11), [L12](#l12), [L13](#l13). **Depends on:** nothing.
**Decisions:** [D8](#d8), [D9](#d9), [D10](#d10). Josh reviews every new line in both languages.

- `AnswerSlip`'s minimum counts the blank's own letters. A grave accent folds as an acute does,
  and a trailing period is ignored. "no arrepientas" typed into `¡no te [ ]!` does not double the
  frame's "no".
- **The three errors ([D8](#d8)).** New classes of diagnosis, each an
  exact construction as `regularForm()` is: the j-stem pretérito with -ieron, the tú pretérito
  with a final s, and the y of oyes left as i. Draft a line for each in English and Spanish and
  bring them to Josh.
- **A reflexive command ([D9](#d9)).** `shownSpellings` adds the bare form only where the frame
  supplies the pronoun, and for a gerundio.
- **dice, tiene, viene.** `regularForm()` also counts the form built with only the spelling and
  stem-vowel features, so that all the tú commands get one line. Correct the comment on
  `diagnosis(of:)` and `docs/feature_architecture.md:993`.
- **The rulings of [D10](#d10):** vayamos, after the entry is read and shown to Josh; a leading
  que before a subjunctive; and an accent-only miss that lands outside the session's tenses.
  Record what is added to `StandardVariants` in `plans/pedagogy_variant_audit.md`, and correct
  its row 13 ([G5](#g5)).

**Done when** tests pin, each failing on the old code: "ds" in a negative command's blank is not
a slip, and "hablez" still is; "sè" is a slip of sé; "soy." is right; dijieron, hablastes, and
oies get what D8 says; "atreve" is wrong for atrévete, its correction shows atrévete, and
arrepintiendo is still right; dice, tiene, and viene get the line hace gets; hablare for hablaré
gets what D10 says, and hablo for habló keeps its line; vayamos and "que hable" are graded as
Josh ruled.

**Tell Josh to try:** with `-CONJUGAR_QUIZ_FIXTURE slips` and `diagnoses`, the answers in each
question's comment, and the new ones above.

**How it differed:**

## Phase 5: What the Quiz Asks

**Findings:** [L7](#l7), [L8](#l8), [L19](#l19). **Depends on:** nothing. **Decisions:**
[D11](#d11), [D12](#d12), [D13](#d13). Josh reviews the list of verbs before any is marked.

- **The list ([D11](#d11)).** Draft the verbs whose commands the quiz does not ask, from the
  1,000 most frequent, with a reason for each, and bring it to Josh. Put the list where one
  function can answer "does the quiz ask this cell of this verb".
- Every draw refuses an excluded cell: `QuizDraw.questions` (haber leaves the core role in a
  command cell), `recordQuestions` (a due item whose only askable cells are excluded waits for
  Review), the Speed Round's draw, a scoped and a custom quiz, the challenge, and the widget's
  question. Check that no authored sentence or choice asks one. The verb page is left alone.
- **The weights ([D12](#d12)).** Compare the ladder with the *Plan curricular*'s inventories
  first and bring Josh any disagreement. Then commands weigh 1 at every level and the two
  imperfectos de subjuntivo 1 each. `QuizLevelTests` pins each level's shares.
- **Advanced's verbs ([D13](#d13)).** Every verb, weighted toward use, built in `QuizDraw`,
  where a band's verbs are drawn. Propose the share that comes from the 1,000 most frequent and
  tell Josh what was chosen.
- Update `docs/feature_architecture.md` § Quiz, the Info article "Purpose/Use" if it names the
  shares, and the README if it does.

**Done when** a test draws 1,000 default rounds a level and finds no excluded cell; the
challenge's draw over 60 days has none; two core questions a round still hold at Beginner; the
shares of commands and of the two imperfectos de subjuntivo match D12 within a stated tolerance
over many seeds; and Advanced's share of verbs beyond the 1,000 most frequent is what D13 says.

**Tell Josh to try:** five Beginner rounds and five Advanced rounds, reading what is asked.

**How it differed:**

## Phase 6: Distinct Questions and the Ranked Round

**Findings:** [L14](#l14), [L15](#l15), and from [S4](#s4) one answer to "would this level ask
it". **Depends on:** Phase 5, which edits the same draw. **Decisions:** [D14](#d14),
[D15](#d15).

- **Distinct questions ([D14](#d14)).** A round's questions are distinct in verb, tense, and
  person, the due items included. Ten More avoids the session's earlier questions while unasked
  ones remain. A scope with fewer than ten distinct questions gets a
  shorter round, and `completeQuiz`'s `questionCount` can then be below ten for a small scope:
  that says how small the scope is, not how the learner did, and it is a new value to stage.
- A second attempt identical to the first is ignored, with the line announced again.
- **The mix and the ranked round ([D15](#d15)).** Draw ten slots with
  their roles and irregularity, let the choice and, in Ten More, the due items take matching
  slots where they can, and mix due items in from Ten More on. Extract the default round's
  composition into one pure function in `QuizDraw` that tests can call.
- One `QuizLevel` function answers whether the level asks a cell, and `Quiz.dueQuestions`, the
  Speed Round's draw, and `Mastery.layout` call it. Phase 9's reminder count will too.
- The re-ask of a round's last two questions is left where it is. Josh was not asked to move it.
- Correct `docs/feature_architecture.md` § Quiz on the mix and on the due items.

**Done when** tests pin, over many seeds: no round of any scope repeats a question; a one-verb
model at Beginner asks what it has and offers no Ten More; a round from `Quiz.start` has the
irregular count D15 promises at every level, choice included; a first round with items due does
what D15 says; the same answer submitted twice leaves the second attempt unspent.

**Tell Josh to try:** a collection's quiz on ser's model at Beginner. In Name the Form, a
part-wrong answer and a double tap on Check.

**How it differed:**

## Phase 7: The Exercises and Their Content

**Findings:** [L9](#l9), [L18](#l18), [L21](#l21), [C6](#c6). **Depends on:** Phase 2, for the
record's rules. **Decisions:** [D16](#d16), [D17](#d17).

- **The irregular cell ([D16](#d16)).** Verb Essentials and Verb Models ask the first irregular
  cell built on a key whose own cell is regular for the verb, the row names the person, and
  `ModelPracticeGroup.items` counts the item. Store `items` once, since it never changes
  ([S6](#s6)).
- **The sentence's tense ([D17](#d17)).** Nothing is built now. Record in the note, and where
  the next batch of sentences will be planned, that the batch flags the sentences whose context
  forces their tense, hides the tense there, and moves the English to after the answer.
- Rewrite `querer.imperfectoDeSubjuntivo1.1` as a subordinate clause, or give a sentence a way to
  refuse the other imperfect subjunctive. Replace `pretender.pluscuamperfectoDeIndicativo.1`.
  Reword `Choice.reasonNegativeCommand` in both languages. Run `scripts/gap_sentences.py` and both
  content suites.
- A choice's row in the results shows what was chosen and what was right in the same form, and
  a sentence's row names its tense as its card did.
- A custom quiz or a practice set with no askable cell says so, on the tab and in the sheet.
- Ask Josh about Name the Form's red letters when the phase reaches it.

**Done when** tests pin: Verb Essentials asks pedir, dormir, and construir for an irregular
pretérito cell, and that answer moves `key:…:yo_preterito`; a model of -ir stem changers is not
known until that item is; "quisiese" is graded as the rewritten sentence requires; a custom quiz
of the presente de subjuntivo over abolir's model cannot be started and says why.

**Tell Josh to try:** Verb Essentials until pedir or dormir comes up. A custom quiz of the
presente de subjuntivo over abolir's model.

**How it differed:**

## Phase 8: The Daily Challenge

**Findings:** [L16](#l16), and from [T2](#t2) the challenge's pins. **Depends on:** Phases 5 and
6, which change what the challenge draws. **Decisions:** [D18](#d18).

- **Taken from its first answer.** A challenge's result is kept as it goes. A quit, or the next launch after the app was left during one, closes it with the
  unanswered questions counted wrong, and that result shows on the hub and can be shared. A
  challenge started and quit before any answer is not taken.
- **tú and vos.** `DailyChallenge.draw(for:)` takes no second-person-singular cell whose tú and
  vos forms differ in irregularity, so one challenge serves both learners.
- **Across versions.** The link carries a content version derived from
  what the draw reads, and a link from another version opens a note saying the questions may
  differ, then the learner's own challenge for that day. Replace the standard library's sampling
  on the challenge's path with a bounded pick, a shuffle, and an element pick over the
  generator's `next()`, so that a toolchain cannot move the draw. Move `SplitMix64` to a file of
  its own.
- Results kept by key with a cap far above what links can fill, a date after today refused, the
  hub's key computed at the tap, and a taken challenge's result shown when its link is opened.
- The pins: the generator's first outputs, the sampling's outputs, and one challenge's draw over
  a small made-up verb list, so that a verb import does not break it.
- Correct the comment on `PracticeStore.challengeResults`, the hub's string if "the same for
  everyone" needs a qualifier, and stage the link's new parameter.

**Done when** tests pin: a challenge quit after one answer is taken, with four questions wrong,
and cannot be started again; one quit before any answer can; twelve challenges from links do not
reopen today's; a link dated tomorrow starts nothing; over 60 days and every level a tú
learner's and a vos learner's challenges have the same count of irregular questions; a link with another content version is recognized.

**Tell Josh to try:** start today's challenge, miss one, quit, and look at the hub. Switch the
quiz to vos and compare a challenge with a friend's in tú.

**How it differed:**

## Phase 9: Clocks, Calendars, and the Reminder

**Findings:** [L17](#l17), [L20](#l20), [C3](#c3), [C7](#c7), [C8](#c8). **Depends on:** Phase 2
for the injected clock, and Phase 6 for the level's function. **Decisions:** [D19](#d19).

- The quiz's clock is a start date and, for the Speed Round, a deadline, read from the injected
  clock. The timer refreshes the display and runs in the common run-loop modes. Before fixing the
  scrolling part of [L17](#l17), confirm it: start a Speed Round in the simulator, hold the card,
  and watch the time left.
- **Leaving the app ([D19](#d19)).** The minute runs. A Speed Round whose deadline
  passed while the app was away ends when it returns, with the question on screen dropped as at
  any time-up.
- `Quiz.start` refuses a Speed Round below `SpeedRound.minimumMasteredCount`, and only the Speed
  Round's own view observes its seconds.
- The reminder's count, and the Review row's "next review", are what their sessions would ask.
- `ReminderSchedulerReal.schedule` cannot be overtaken by an earlier call. Today's delivered
  reminder is removed when the session is finished. Settings checks notification permission
  again when the scene becomes active.
- `PracticeStore` holds `Calendar.autoupdatingCurrent`, the streak's keys come from
  `CalendarDay`, and the reminder's plan takes the store's calendar.
- A daily session counts for the day it began.

**Done when** tests pin: a Speed Round ends at its deadline whatever the ticks; one cannot start
with four mastered items; the reminder says what a Beginner's session will ask; two plans
scheduled in quick succession leave only the second's requests, through a scheduler the test can
order; a session from 23:58 to 00:02 extends the first day's streak; a streak recorded under a
Japanese calendar reads the same under a Gregorian one.

**Tell Josh to try:** a Speed Round, leaving the app for twenty seconds in the middle. A daily
session begun just before midnight.

**How it differed:**

## Phase 10: Privacy in the Code

**Findings:** [P1](#p1), [P2](#p2), [P3](#p3), [P4](#p4), [P6](#p6). **Depends on:** nothing.
**Decisions:** [D20](#d20), [D21](#d21), [D22](#d22).

- Build the guard of [P6](#p6) first: the three quiz signals assembled in the model and tested,
  then the allow-list, with `AnalyticsSpy` recording an issue for a key or value outside it. Run
  the suite and see what it catches before changing a call site.
- `QuizScope.sendsQuestionCounts` becomes a switch over the kind with no default ([S3](#s3)).
- **A model's key ([D20](#d20)).** `startQuiz` and `tapShareCollection` send
  `collection: model` for any model, and one function on `VerbCollection` gives the value a
  signal may carry, so that no call site reads `key` for a signal. `viewCollection` keeps a
  model's key outside a correction.
- The collection bar's Share sends nothing that names the model on a page opened from a
  correction. Carry the request's source to the bar, so that the rule lives in one place.
- **A record session ([D21](#d21))** sends one `completeQuiz`, at its first round, and no
  `duration` on any signal. Stage both.
- **The surfaces ([D22](#d22))** stay. Phase 11 records the ruling in the staged policy's notes.

**Done when** a test starts a quiz over each one-verb model, by each route (the model's own
quiz, a custom quiz, a practice set), and no signal's parameters contain the verb or its class; a
test shares a model opened from a correction and finds no key; My Mistakes over two rounds sends
one `completeQuiz` and no `duration`; and every existing test passes under the allow-list.

**Tell Josh to try:** nothing on screen changes. Tell him what each signal now carries.

**How it differed:**

## Phase 11: The Staged Policy and the Docs

**Findings:** [P5](#p5), [G1](#g1), [G2](#g2), [G3](#g3), [G4](#g4), [G5](#g5). **Depends on:**
Phase 10, since the text must say what the code then does. **Decisions:** none, but the staged
text will be published under Josh's name, so he reads every changed sentence in both languages
before the commit.

- Restage the progress bullet with all four exceptions, the quiz-lifecycle bullet's "(but not
  which ones)" as [D20](#d20) makes it true, the level bullet with a quiz left unfinished, "to
  the developer" in the sentence about right answers, and the Spanish phrase about sharing.
- Record in the pending file's notes that the sources of [D22](#d22) are surfaces and how often
  a record session reports ([D21](#d21)).
- Correct every line [G1](#g1) lists in `docs/feature_architecture.md`, and bring its hub
  paragraph up to date. Correct the comments [G2](#g2) lists that no earlier phase reached.
- Remove the provenance [G3](#g3) lists, the `// MARK:` lines among it.
- [G4](#g4)'s open items go to Josh as questions, and what he decides is built here or listed
  for a later phase.
- Re-run the audit as a table in this phase's note: every signal, key, and value at HEAD, its
  call site, and the line of the policy or its pending file that covers it. At `2e5a74b` the
  quiz's rows were:

  | Signal | Parameters and values | Sent from |
  |---|---|---|
  | `startQuiz` | `level`; `source`; `collection` (a list's or a model's key, for a collection's quiz, a custom quiz or practice set over one, and a model's practice); `customChoice` (`tenses`, `verbs`, `both`) | `QuizView.startQuiz` |
  | `completeQuiz` | `duration` (five bands); `level`; `source`; `questionCount` (re-asks not counted; absent for a record session, a mixed model practice, and the Speed Round); `streak` (four bands, a daily session only) | `QuizView.finish` |
  | `quitQuiz` | `duration`; `level`; `source`; `questionNumber` (the same exceptions) | `QuizView.quit` |
  | `abandonQuiz` | `level`; `source`; `questionNumber` (the same exceptions) | `QuizAbandonment.reportAndClear` |
  | `tapDailyReminder` | `enabled` (`true`, `false`, `denied`) | `SettingsView` |
  | `tapShareChallenge` | `level` | `DailyChallengeResult.signalShare` |
  | `tapSharePracticeSet` | `customChoice`; `method` (`link`, `qrCode`) | `PracticeSet.signalShare` |
  | `viewPracticeSet` | `outcome` (`opened`, `invalid`); `source` | `PracticeSetView` |
  | `tapViewLeaderboard`, `tapViewAchievements` | `level` and `source` `tab` from the hub; nothing from Settings | `QuizView`, `SettingsView` |
  | `tapKeepPracticeSet`, `tapResetPractice`, `viewMastery`, `viewQuizView`, `viewResultsView` | None | Their views |

**Done when** every row of the new table has its line in both languages, no doc line [G1](#g1)
lists is still untrue, and a search for the provenance [G3](#g3) lists finds nothing.

**Tell Josh to try:** read the restaged sentences, English and Spanish.

**How it differed:**

## Phase 12: Sharing and the Small Stores

**Findings:** [C5](#c5), [C12](#c12). **Depends on:** nothing. **Decisions:** [D23](#d23).

- A decoded list is capped, a set's link names only `sharedLink` or `qrCode`, and the QR screen
  says so when no code can be made or when the list is longer than its code carries.
- **A shared My Verbs, and the two caps ([D23](#d23)).** A shared My Verbs is the starred verbs
  alone, the menu and the set's summary say "starred verbs", a link carries up to 100, and a code
  the first 30. `theLongestListFitsACode` reads the densest code back and bounds its
  link's length. Correct the two comments.
- The last result, the level bests, the streak, and the challenge results are backed up before
  an unreadable one is overwritten, through one helper ([S5](#s5)). A test decodes a pinned
  string of today's format for each of the five stored things.
- Reset Practice clears the unreadable-record backup, and the review card chooses again after a
  reset.

**Done when** tests pin: a link of 500 verbs yields the cap; `source=tab` on a set's link is
reported as a link; a shared My Verbs holds no verb that is not starred; a list of 40 makes a
link of 40 and a code of 30; the worst-case code decodes to its own
link; a malformed stored streak leaves its bytes under a second key; each pinned string decodes.

**Tell Josh to try:** share My Verbs as a QR code with more verbs than the code carries, and scan
it from across a room.

**How it differed:**

## Phase 13: VoiceOver, Targets, and the iPad's Keys

**Findings:** [C9](#c9), [A1](#a1), [A2](#a2), [A3](#a3), [A4](#a4). **Depends on:** nothing.
**Decisions:** none.

- On an iPad the letter keys sit under the field at any width. Check a sheet's quiz and a
  one-third Split View on "Conjugar iPad Pro 11".
- The question card's verb and tense, the results' rows, the diagnosis lines, and a choice's
  reason are tagged Spanish where they are Spanish.
- **Listen first.** Turn VoiceOver on in the simulator, or ask Josh to on his phone, and confirm
  each part of [A2](#a2) before changing it. Then fix what is real.
- One element a results row, labels on the score strip, 44-point targets for the four controls
  [A3](#a3) names, a real button for the Verb Models list's rows, a scaled width for a
  sentence's field, and a refocus after Return on an empty answer if that proves real.
- The two auto-extracted catalog keys go, the punctuation moves into the strings, and the dead
  accessors are deleted.

**Done when** `VoiceOverLabelTests` pins the spoken line of a results row and of the question
card with its Spanish tagged; the catalog holds neither `"%@ %@"` nor `"%@: %lld"`; and the note
says what was heard, on which device, for each part of A2.

**Tell Josh to try:** with VoiceOver on, answer a question wrongly and listen for the correction,
then answer one a letter off and listen for "Almost!".

**How it differed:**

## Phase 14: One Shape for a Quiz's Modes

**Findings:** [S1](#s1), [S3](#s3), [S4](#s4), [S6](#s6), [S8](#s8). **Depends on:** Phases 1, 2,
5, 6, 7, 8, 9, and 10, which all edit `Quiz.swift`. Refactoring under them would make each
harder. **Decisions:** none.

This phase changes no behavior. The suite's count and every expectation stay as they are, and a
test that must change is a sign that something moved.

- The fixtures move to `Quiz+Fixtures.swift`, and the fixture switch is skipped while unit tests
  run.
- `QuizQuestion` takes one kind in place of its three optionals. `Quiz` keeps one phase for the
  question on screen, one record per answered question in place of four arrays, and one function
  that records an answer for all three paths.
- Every rule of `QuizScope` is a switch over the kind, each mode's own state rides in its case,
  and `Quiz.draw`, the tip's donation, both titles, and `ResultsView`'s chains ask the kind.
- One normalizer, one pairing of the imperfect subjunctives, one regular verb for a pattern, one
  loader for bundled JSON, and `CalendarDay` for every day. A wrong answer's diagnosis is
  computed once.
- The small things of [S8](#s8).

**Done when** `Quiz.swift` holds `Quiz` and little else, no property of `QuizScope` infers the
mode from a count or a nil, and the suite passes unchanged.

**Tell Josh to try:** one round of each mode, since nothing should have changed.

**How it differed:**

## Phase 15: The Hub and the Store

**Findings:** [S2](#s2), [S5](#s5), [S7](#s7). **Depends on:** Phase 14. **Decisions:** none.

- A `QuizHubView` with a model that computes its rows from the practice store, the settings, and
  one injected date, and that refreshes when the day changes. The question's screen, the answer
  being typed, and the focus helper become types of their own, and the tab and the sheet become
  two hosts.
- `Current.resetPractice()`, and one helper for storing a `Codable` under a key.
- The shared pieces of [S7](#s7)'s table, and `AdaptiveRows` for the Verb Models list if it
  fits.
- This phase changes the Quiz tab's code and should not change its look. Compare screenshots of
  the hub, a question, and the results before and after, in English and Spanish, on both
  devices.

**Done when** `QuizView.swift` shows a question and nothing of the hub, the hub's rows are tested
through its model with an injected date (Review off at 0, the Speed Round locked below five, a
taken challenge offering Share), and no screenshot differs.

**Tell Josh to try:** the hub and one round, on his phone.

**How it differed:**

## Phase 16: Tests That Prove What They Claim

**Findings:** [T1](#t1) to [T9](#t9). **Depends on:** every phase before it, each of which took
the tests of its own findings. This phase takes what is left. **Decisions:** none.

- Rewrite each test the Tests findings name. For each, break the code under test by hand, see
  the new test fail, and restore the code. Say in the note which mutation each was tried
  against.
- One helper file for what the suites repeat: a quiz with its own store and seed, a driver that
  answers each kind of question as the app would, and the signal reader.
- Give each test its own generator, a fixed calendar, and fixed dates.
- Pin the wire values and names that no literal pins, and compare `Achievement`'s identifiers
  and points with `GameCenterResources.gamekit`'s file.
- The behaviors [T9](#t9) lists as untested that no earlier phase covered.

**Done when** each rewritten test has failed against its mutation, no test in the pedagogy files
reads the wall clock for a date it compares, and no suite shares a generator between tests.

**Tell Josh to try:** nothing on screen changes. Tell him the suite's new count and time.

**How it differed:**

## Closing

- Run the full suite and `swiftlint`, and read the count.
- Confirm that every finding in this file carries a line: fixed, found not to be real, or left
  with its reason.
- Re-read this plan's phase notes for anything a phase deferred, and either do it or list it
  where Josh will find it.
- Confirm that the pedagogy plan's Closing audit and Phase 11's table here agree with
  `Analytics.swift` at HEAD.
- Write what would carry over to Konjugieren and Conjuguer, as the earlier plans' Closings did.
  The findings under [Found here and not in Konjugieren's review](#found-here-and-not-in-konjugierens-review)
  are the start of that list. Neither sibling is to be changed.
- Mark this plan finished in its Status section.

**How it differed:**
