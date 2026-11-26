# Privacy-Policy Lines Waiting for a Release

[`privacy_policy3.txt`](privacy_policy3.txt) describes what the **shipped** app sends, and Josh may
deploy it at any time. A signal, parameter, or value built on `master` gets its line in the
deployed policy on the day the release that sends it ships, not before. Until then the line waits
here. `CLAUDE.md` § No Release Before 2027 and [`release.md`](release.md) § On Release Day point
here.

**On release day:** splice every section below into both languages of `privacy_policy3.txt`, in
the order given, update its effective date in both, deploy it, and empty this file back down to
this introduction. New bullets go at the end of the list in section 2 (English) and sección 2
(Spanish), after the bullet about the minigame. Where a later section rewrites a line that an
earlier section added, the later wording wins.

**When adding a signal, parameter, or value on `master`:** add its lines here in English and
Spanish, in the policy's plain register, naming the bands rather than the code's parameter keys.
Name the plan and phase that added it. A new `source` value that the examples in the first lookup
bullet already cover ("for example") needs no new line; one that adds a new kind of surface does.

## Lookup signals (browse plan, Phase 2, 2026-11-22)

Adds `source` to `viewVerbView`, and the signals `finishSearch` and `leaveVerbView`. See
[`feature_architecture.md`](feature_architecture.md#analytics) for the vocabulary. The `source`
values sent today are the verb list, a search, the search's guess, a model's page, a widget, the
Random Verb control, a shortcut, a link, and `resume`; the bullet's examples name the kinds a
reader would recognize. Phase 5 (2026-11-22) added "a conjugation such as fue" / "una forma
conjugada como fue" to the search bullet's examples, when the match kinds `conjugation` and
`foldedConjugation` began to be sent. Phase 8 (2026-11-22) added "another verb's page" / "la página
de otro verbo" to the first bullet's examples, when `related` began to be sent.

### English

New bullets for the list in section 2:

```
- How you reached a verb's page: for example from a search, the verb list, a model's page, another verb's page, a widget, Control Center, a shortcut, or a link
- How far down a verb's page you scrolled (its top, the simple tenses, the compound tenses, the etymology, or the examples), and roughly how long the page was open (under 5 seconds, 5 to 15 seconds, 15 to 60 seconds, or longer)
- When a search of the verb list ends: whether you opened a verb, the kind of match that found it (for example the infinitive, a conjugation such as fue, a spelling without accents, an English meaning, or the app's guess at a misspelling), and rough counts: the length of what you typed (1 to 2 letters, 3 to 5, 6 to 9, or 10 or more), how many verbs matched (none, 1, 2 to 10, or more), and where the verb you opened stood in the list (first, second to fifth, or lower)
```

The paragraph after the list now reads:

```
Your quiz score and elapsed time are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not record your quiz answers, which verbs you look up, or any text you type. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

Nuevos puntos para la lista de la sección 2:

```
- Cómo llegó a la página de un verbo: por ejemplo, desde una búsqueda, la lista de verbos, la página de un modelo, la página de otro verbo, un widget, el Centro de control, un atajo o un enlace
- Hasta dónde se desplazó en la página de un verbo (el principio, los tiempos simples, los tiempos compuestos, la etimología o los ejemplos) y, aproximadamente, cuánto tiempo estuvo abierta la página (menos de 5 segundos, de 5 a 15 segundos, de 15 a 60 segundos o más)
- Cuando termina una búsqueda en la lista de verbos: si abrió un verbo, el tipo de coincidencia que lo encontró (por ejemplo, el infinitivo, una forma conjugada como fue, una grafía sin tildes, un significado en inglés o la conjetura de la aplicación ante una errata) y cifras aproximadas: la longitud de lo que escribió (de 1 a 2 letras, de 3 a 5, de 6 a 9, o 10 o más), cuántos verbos coincidieron (ninguno, 1, de 2 a 10, o más) y en qué lugar de la lista estaba el verbo que abrió (el primero, del segundo al quinto, o más abajo)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y el tiempo transcurrido se recopilan, pero, como todas estas estadísticas, están anonimizados y no están vinculados a su identidad (véase la sección 4). La aplicación no registra sus respuestas del cuestionario, qué verbos consulta ni ningún texto que escriba. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## The tense article button (browse plan, Phase 6, 2026-11-22)

Adds the signal `tapTenseArticle`, sent when the ⓘ beside a tense's heading on a verb page opens
that tense's article. It has no parameters and does not say which tense or which verb. It changes
the existing bullet about in-app actions rather than adding one.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, and opening a tense's article from a verb's page
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor y abrir el artículo de un tiempo verbal desde la página de un verbo
```

## Sharing a verb's page (browse plan, Phase 9, 2026-11-22)

Adds the signal `tapShareVerb`, sent on each tap of the share button on a verb's page. It has no
parameters and does not say which verb, or whether the learner went on to share. Copying a form
sends nothing. It rewrites the bullet about in-app actions that Phase 6 rewrote, so apply this
wording in place of that one.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, and tapping to share a verb's page
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo y tocar para compartir la página de un verbo
```

## Where a search began (browse plan, Phase 10, 2026-11-22)

Adds `source` to `finishSearch`: where the search began, which is the verb list itself, the Find a
Verb control in Control Center, the Find a Verb Home Screen quick action, or a link (Phase 11 will
add the Look Up a Verb shortcut, and should add "a shortcut" / "un atajo" to these examples). It rewrites the
search bullet that the section on lookup signals added, so apply this wording in place of that one.

### English

The bullet about searches in section 2 now reads:

```
- When a search of the verb list ends: where you began it (for example the verb list, Control Center, a Home Screen quick action, or a link), whether you opened a verb, the kind of match that found it (for example the infinitive, a conjugation such as fue, a spelling without accents, an English meaning, or the app's guess at a misspelling), and rough counts: the length of what you typed (1 to 2 letters, 3 to 5, 6 to 9, or 10 or more), how many verbs matched (none, 1, 2 to 10, or more), and where the verb you opened stood in the list (first, second to fifth, or lower)
```

### Spanish

El punto sobre las búsquedas, en la sección 2, queda así:

```
- Cuando termina una búsqueda en la lista de verbos: dónde la empezó (por ejemplo, en la lista de verbos, el Centro de control, una acción rápida de la pantalla de inicio o un enlace), si abrió un verbo, el tipo de coincidencia que lo encontró (por ejemplo, el infinitivo, una forma conjugada como fue, una grafía sin tildes, un significado en inglés o la conjetura de la aplicación ante una errata) y cifras aproximadas: la longitud de lo que escribió (de 1 a 2 letras, de 3 a 5, de 6 a 9, o 10 o más), cuántos verbos coincidieron (ninguno, 1, de 2 a 10, o más) y en qué lugar de la lista estaba el verbo que abrió (el primero, del segundo al quinto, o más abajo)
```

## Shortcuts and Spotlight (browse plan, Phase 11, 2026-11-22)

Begins sending `lookup` as the `source` of `viewVerbView` and `finishSearch`, when the Look Up a
Verb shortcut opens a page or a search, and `spotlight` as the `source` of `viewVerbView`, when a
verb's Spotlight entry is tapped. No signal or parameter is added. A search begun from the shortcut
is a new kind of surface for the search bullet, so it gains "a shortcut", as the section above
foresaw; Spotlight is a new one for the first bullet. Apply these two bullets in place of the
wording the sections above give them.

### English

The first bullet in section 2 now reads:

```
- How you reached a verb's page: for example from a search, the verb list, a model's page, another verb's page, a widget, Control Center, a shortcut, Spotlight, or a link
```

The bullet about searches in section 2 now reads:

```
- When a search of the verb list ends: where you began it (for example the verb list, Control Center, a Home Screen quick action, a shortcut, or a link), whether you opened a verb, the kind of match that found it (for example the infinitive, a conjugation such as fue, a spelling without accents, an English meaning, or the app's guess at a misspelling), and rough counts: the length of what you typed (1 to 2 letters, 3 to 5, 6 to 9, or 10 or more), how many verbs matched (none, 1, 2 to 10, or more), and where the verb you opened stood in the list (first, second to fifth, or lower)
```

### Spanish

El primer punto de la sección 2 queda así:

```
- Cómo llegó a la página de un verbo: por ejemplo, desde una búsqueda, la lista de verbos, la página de un modelo, la página de otro verbo, un widget, el Centro de control, un atajo, Spotlight o un enlace
```

El punto sobre las búsquedas, en la sección 2, queda así:

```
- Cuando termina una búsqueda en la lista de verbos: dónde la empezó (por ejemplo, en la lista de verbos, el Centro de control, una acción rápida de la pantalla de inicio, un atajo o un enlace), si abrió un verbo, el tipo de coincidencia que lo encontró (por ejemplo, el infinitivo, una forma conjugada como fue, una grafía sin tildes, un significado en inglés o la conjetura de la aplicación ante una errata) y cifras aproximadas: la longitud de lo que escribió (de 1 a 2 letras, de 3 a 5, de 6 a 9, o 10 o más), cuántos verbos coincidieron (ninguno, 1, de 2 a 10, o más) y en qué lugar de la lista estaba el verbo que abrió (el primero, del segundo al quinto, o más abajo)
```

## Recents, My Verbs, and the star (browse plan, Phase 12, 2026-11-22)

Adds the signal `tapStarVerb`, sent on each tap of the star on a verb's page, with one parameter,
`starred`: whether the verb is starred after the tap. It does not say which verb. Begins sending
`recent` and `myVerbs` as the `source` of `viewVerbView`, which the first bullet's "the verb list"
covers, so that bullet is unchanged. The app now keeps, on the device, a list of the verbs opened
and starred, so the paragraph after the list can no longer say that the app does not record which
verbs you look up. It now says the app does not send them, and a new paragraph says where the list
stays. This rewrites the bullet about in-app actions that Phase 9's section rewrote, and the
paragraph that the section on lookup signals rewrote; apply this wording in place of both.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, and starring or unstarring a verb (whether the verb is starred afterward, but not which verb)
```

The paragraph after the list now reads:

```
Your quiz score and elapsed time are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, which verbs you look up, or any text you type. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

A new paragraph follows it:

```
To show your recent and starred verbs in My Verbs, the app keeps a list of the verbs you open and star, with when you opened them and how often. The list stays on your device, in storage shared only with the app's own widgets. It is never sent to the developer or to anyone else, and it is deleted when you delete the app. You can clear the recent verbs, or remove any verb from the list, in My Verbs.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo y marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y el tiempo transcurrido se recopilan, pero, como todas estas estadísticas, están anonimizados y no están vinculados a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, qué verbos consulta ni ningún texto que escriba. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

Le sigue un párrafo nuevo:

```
Para mostrar sus verbos recientes y marcados con una estrella en Mis verbos, la aplicación guarda una lista de los verbos que abre y marca, con la fecha en que los abrió y cuántas veces. La lista se queda en su dispositivo, en un almacenamiento que solo comparte con los widgets de la propia aplicación. Nunca se envía al desarrollador ni a nadie más, y se borra al eliminar la aplicación. En Mis verbos puede borrar los verbos recientes o quitar cualquier verbo de la lista.
```

## Where a quiz began (browse plan, Phase 13, 2026-11-22)

Adds `source` to `startQuiz`, `quitQuiz`, and `completeQuiz`: where the quiz began, which is the
Quiz tab's Start (`tab`), the tab's My Verbs choice (`myVerbs`), Test Me on a verb's page
(`verbPage`), or a `quiz` link (`deeplink` unless the link names its surface), so that a
three-question quiz is not counted with the full one. No signal is added. A quiz over My Verbs or
over one verb posts no score to Game Center, so section 7 gains a sentence saying which scores are
submitted. These replace the existing quiz-lifecycle bullet and the Game Center paragraph.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), and where you began the quiz (for example the Quiz tab, My Verbs, a verb's page, or a link)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of a full quiz over all verbs is submitted; a quiz over My Verbs or over a single verb's page is not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario) y dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en la página de un verbo o desde un enlace)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de un cuestionario completo sobre todos los verbos; la de un cuestionario sobre Mis verbos o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## The review card (browse plan, Phase 15, 2026-11-22)

Adds the signals `viewReviewCard`, sent when the review card above the verb list appears, and
`tapRevealReviewCard`, sent when a tap reveals its conjugations. Neither has parameters, and neither
says which verb. Begins sending `reviewCard` as the `source` of `viewVerbView`, which the first
bullet's "the verb list" covers, so that bullet is unchanged. The list kept on the device now also
holds when each irregular verb is next due on the card. This rewrites the bullet about in-app
actions and the paragraph about the list, both as Phase 12's section gives them; apply this wording
in place of both.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, starring or unstarring a verb (whether the verb is starred afterward, but not which verb), and revealing the conjugations on a review card
```

A new bullet follows it:

```
- That a review card, which offers a verb you looked up some days ago, was shown
```

The paragraph about the list kept on the device now reads:

```
To show your recent and starred verbs in My Verbs, and to offer review cards, the app keeps a list of the verbs you open and star, with when you opened them, how often, and when each is next due for review. The list stays on your device, in storage shared only with the app's own widgets. It is never sent to the developer or to anyone else, and it is deleted when you delete the app. You can clear the recent verbs, or remove any verb from the list, in My Verbs.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata) y mostrar las conjugaciones de una tarjeta de repaso
```

Le sigue un punto nuevo:

```
- Que se mostró una tarjeta de repaso, que le ofrece un verbo que consultó hace unos días
```

El párrafo sobre la lista guardada en el dispositivo queda así:

```
Para mostrar sus verbos recientes y marcados con una estrella en Mis verbos, y para ofrecerle tarjetas de repaso, la aplicación guarda una lista de los verbos que abre y marca, con la fecha en que los abrió, cuántas veces y cuándo le toca repasar cada uno. La lista se queda en su dispositivo, en un almacenamiento que solo comparte con los widgets de la propia aplicación. Nunca se envía al desarrollador ni a nadie más, y se borra al eliminar la aplicación. En Mis verbos puede borrar los verbos recientes o quitar cualquier verbo de la lista.
```

## Collections (browse plan, Phase 16, 2026-11-22)

Adds the signals `viewCollection`, sent when a collection's page or a model's page opens, with
`collection` (which list: one of five fixed lists, or one of the 102 models, never a verb) and
`source` (the Models tab, a verb page's model pill, or a link, shared or not); and
`tapShareCollection`, with `collection`. A collection's quiz adds `collection` to `startQuiz`. Begins
sending `list` as the `source` of `viewVerbView` (a verb opened from a collection), a new kind of
surface for the first lookup bullet, and as the `source` of the quiz signals. A collection's quiz
posts no score to Game Center. These rewrite the first lookup bullet (Phase 2's section), the
quiz-lifecycle bullet and the Game Center paragraph (Phase 13's), and the in-app-actions bullet
(Phase 15's), and add one bullet; apply this wording in place of those. (The browse plan's Closing, 2026-11-22, restored "Spotlight" to the first bullet in both languages, which this section's first draft had dropped from Phase 11's wording.)

### English

The first bullet of Phase 2's section now reads:

```
- How you reached a verb's page: for example from a search, the verb list, a model's page, a collection of verbs, another verb's page, a widget, Control Center, a shortcut, Spotlight, or a link
```

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), and revealing the conjugations on a review card
```

A new bullet follows the bullet about review cards:

```
- Which collection of verbs you opened, such as the 100 most frequent verbs or the verbs of one model, and how you reached it (the Models tab, a verb's page, or a link)
```

The bullet about quiz lifecycle events now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a verb's page, a collection, or a link), and, for a quiz over a collection, which collection
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of a full quiz over all verbs is submitted; a quiz over My Verbs, a collection, or a single verb's page is not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El primer punto de la sección de la fase 2 queda así:

```
- Cómo llegó a la página de un verbo: por ejemplo, desde una búsqueda, la lista de verbos, la página de un modelo, una colección de verbos, la página de otro verbo, un widget, el Centro de control, un atajo, Spotlight o un enlace
```

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata) y mostrar las conjugaciones de una tarjeta de repaso
```

Un punto nuevo sigue al de las tarjetas de repaso:

```
- Qué colección de verbos abrió, como los 100 verbos más frecuentes o los verbos de un modelo, y cómo llegó a ella (la pestaña de modelos, la página de un verbo o un enlace)
```

El punto sobre los eventos del ciclo de vida de un cuestionario queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en la página de un verbo, en una colección o desde un enlace) y, si el cuestionario es sobre una colección, cuál
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de un cuestionario completo sobre todos los verbos; la de un cuestionario sobre Mis verbos, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Links on a quiz's correction (pedagogy plan, Phase 2, 2026-11-23)

Begins sending `quizCorrection` as the `source` of `viewVerbView` (the verb's page, opened from the
correction a quiz holds after a wrong answer) and of `viewCollection` (the verb's model's page,
opened the same way). It is a new kind of surface for the first lookup bullet and for the
collection bullet, so both are rewritten; apply this wording in place of the Collections section's.
Nothing about the answer, the verb, or whether it was right is sent.

(The verb browse fixes' Phase 2, 2026-11-25, made that last sentence true of `viewCollection`.
Until then the model's page sent its `collection` key with this source, which said which model the
learner had just missed, and for a model of one verb, such as ser's, which verb. It now sends
`source` alone. Josh decided that the wording below stays as it is.)

### English

The first bullet of Phase 2's section now reads:

```
- How you reached a verb's page: for example from a search, the verb list, a model's page, a collection of verbs, another verb's page, the correction of a quiz answer, a widget, Control Center, a shortcut, Spotlight, or a link
```

The bullet about collections now reads:

```
- Which collection of verbs you opened, such as the 100 most frequent verbs or the verbs of one model, and how you reached it (the Models tab, a verb's page, the correction of a quiz answer, or a link)
```

### Spanish

El primer punto de la sección de la fase 2 queda así:

```
- Cómo llegó a la página de un verbo: por ejemplo, desde una búsqueda, la lista de verbos, la página de un modelo, una colección de verbos, la página de otro verbo, la corrección de una respuesta del cuestionario, un widget, el Centro de control, un atajo, Spotlight o un enlace
```

El punto sobre las colecciones queda así:

```
- Qué colección de verbos abrió, como los 100 verbos más frecuentes o los verbos de un modelo, y cómo llegó a ella (la pestaña de modelos, la página de un verbo, la corrección de una respuesta del cuestionario o un enlace)
```

## Quiz levels (pedagogy plan, Phase 4, 2026-11-23)

The quiz's three difficulties became four levels, and the parameter `difficulty` on `startQuiz`,
`quitQuiz`, and `completeQuiz` became `level`, whose values are `beginner`, `elementary`,
`intermediate`, and `advanced`. The bullet that names the difficulty is rewritten in place. Nothing
new is sent.

### English

The bullet about the quiz's difficulty in section 2 now reads:

```
- Quiz level (beginner, elementary, intermediate, or advanced) when you start, quit, or complete a quiz
```

### Spanish

El punto sobre la dificultad del cuestionario, en la sección 2, queda así:

```
- El nivel del cuestionario (inicial, elemental, intermedio o avanzado) al comenzar, abandonar o terminar un cuestionario
```

## Rounds of ten, duration bands, and abandoned quizzes (pedagogy plan, Phase 6, 2026-11-23)

The quiz became rounds of ten questions, and a missed question is asked again. The exact elapsed
time on `quitQuiz` and `completeQuiz` became `duration`, a band from the quiz's start (0-3s, 3-15s,
15-40s, 40s-2m, 2m+). `completeQuiz` is now sent at each round's results with `questionCount`, the
questions asked so far (10, 20, …, re-asks not counted). `score` is sent only for the first round of
a quiz over all verbs, on its `completeQuiz` or on a quit during it. The new `abandonQuiz` is sent
at the next launch for each quiz the app was left during, with `level`, `source`, and
`questionNumber`. `questionNumber` counts no repeated question, so it does not reveal how many
answers were wrong. Only a quiz's first round of ten is submitted to Game Center. These rewrite the
score bullet, the question-number bullet, and the paragraph after the list in section 2 (where the
Phase 2 section's paragraph replaced it, this wording wins), and the Game Center paragraph of
section 7 (in place of the Collections section's wording).

### English

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; and, for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer) and how many questions it has asked when you complete a round of ten
```

The bullet about progress in a quiz now reads:

```
- How far you progressed in a quiz if you quit it, or if you leave the app during it (the question number reached, reported the next time you open the app)
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not record your quiz answers, how many of them were right, which verbs you look up, or any text you type. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted; the questions after them, and a quiz over My Verbs, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; y, en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más) y cuántas preguntas lleva al terminar una tanda de diez
```

El punto sobre el progreso en un cuestionario queda así:

```
- Su progreso en un cuestionario si lo abandona o si sale de la aplicación durante él (el número de pregunta alcanzado, que se comunica la próxima vez que abre la aplicación)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no registra sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Leaderboards by level (pedagogy plan, Phase 7, 2026-11-23)

Each quiz level has its own Game Center leaderboard, and the new `tapViewLeaderboard` is sent when
a learner opens one: from a quiz's results with `level`, the level of the board it opens, and from
Settings, which opens the list of every level's board, with no parameter. It rewrites the bullet
about in-app actions that the Collections section rewrote, and the Game Center paragraph of section
7 that the Phase 6 section rewrote; this wording wins over both.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, and opening a Game Center leaderboard (and which level's)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso y abrir una clasificación de Game Center (y de qué nivel)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Custom quizzes (pedagogy plan, Phase 8, 2026-11-23)

The Quiz tab's new Custom segment starts a quiz over tenses, verbs, or both that the learner
chose. Begins sending `custom` as the `source` of the quiz signals, a new kind of surface, and adds
`customChoice` to `startQuiz`: whether the learner chose tenses, verbs, or both, never which ones. A
custom quiz over a collection carries `collection`, as a collection's quiz does. A custom quiz
posts no score to Game Center. This rewrites the quiz-lifecycle bullet that the Collections section
rewrote, and the Game Center paragraph of section 7 that the Phase 7 section rewrote; this wording
wins over both. The choice is kept on the device between launches and sent nowhere, like the
settings, so it needs no line of its own.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a verb's page, a collection, or a link), for a quiz over a collection, which collection, and, for a custom quiz, whether you chose its tenses, its verbs, or both (but not which ones)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección, cuál y, si es personalizado, si usted eligió sus tiempos, sus verbos o ambos (pero no cuáles)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Practice sets (pedagogy plan, Phase 9, 2026-11-23)

A custom quiz can now be shared as a link or a QR code, and opening one shows the practice set it
names. New signals: sharing a practice set (`tapSharePracticeSet`, with how it was shared, a link
or a QR code, and what kind of choice it is, never which tenses or verbs), opening one
(`viewPracticeSet`, with whether the link could be read and where it came from), and keeping one as
the learner's custom quiz (`tapKeepPracticeSet`). The quiz signals gain two values of where a quiz
began, a shared link and a QR code. A practice set's quiz posts no score to Game Center. A shared
link carries the tenses and verbs it names, but it goes only where the learner sends it, never to
the developer, so it needs no line of its own. This rewrites the in-app-actions bullet that the
Leaderboards by level section rewrote, the quiz-lifecycle bullet, and the Game Center paragraph of
section 7 that the Custom quizzes section rewrote; this wording wins over all three.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, opening a Game Center leaderboard (and which level's), sharing a practice set as a link or a QR code (how it was shared, and whether it chooses tenses, verbs, or both, but not which ones), opening a shared practice set (and whether its link could be read), and keeping a shared practice set as your custom quiz
```

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection, which collection, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso, abrir una clasificación de Game Center (y de qué nivel), compartir una serie de práctica como enlace o código QR (cómo se compartió y si elige tiempos, verbos o ambos, pero no cuáles), abrir una serie de práctica compartida (y si su enlace se pudo leer) y guardar una serie de práctica compartida como su cuestionario personalizado
```

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## The practice record (pedagogy plan, Phase 10, 2026-11-23)

The quiz now keeps a practice record on the device: which conjugations each answer practiced, when
each is due again, and whether the last answer was right. The review card reads the same record.
It stays on the device, in the app's own storage, and is never sent. The new `tapResetPractice` is
sent, with no parameters, when the learner confirms Reset Practice in Settings. This rewrites the
paragraph after the list in section 2 that the Phase 6 section rewrote, and the in-app-actions
bullet that the Practice sets section rewrote; this wording wins over both.

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, opening a Game Center leaderboard (and which level's), sharing a practice set as a link or a QR code (how it was shared, and whether it chooses tenses, verbs, or both, but not which ones), opening a shared practice set (and whether its link could be read), keeping a shared practice set as your custom quiz, and resetting your practice record
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, the app keeps a record of which conjugations you have practiced and how your last answers went; that record stays on your device and is never sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso, abrir una clasificación de Game Center (y de qué nivel), compartir una serie de práctica como enlace o código QR (cómo se compartió y si elige tiempos, verbos o ambos, pero no cuáles), abrir una serie de práctica compartida (y si su enlace se pudo leer), guardar una serie de práctica compartida como su cuestionario personalizado y restablecer su registro de práctica
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, la aplicación guarda un registro de qué conjugaciones ha practicado y cómo le fueron sus últimas respuestas; ese registro se queda en su dispositivo y nunca se envía. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## Review and Practice My Mistakes (pedagogy plan, Phase 11, 2026-11-23)

The Quiz tab gains two sessions drawn from the practice record: Review, of the questions due for
review, and Practice My Mistakes, of the questions last answered wrongly. They begin sending
`review` and `mistakes` as the `source` of the quiz signals, a new kind of surface. **A record
session sends no counts:** its `completeQuiz` carries no `questionCount`, and its `quitQuiz` and
`abandonQuiz` carry no `questionNumber`, because a session shorter than ten is exactly as long as
the learner's due or missed questions, so its length would say how many answers were wrong. Nor
does it send a score or post one to Game Center. This rewrites the quiz-lifecycle bullet and the
Game Center paragraph of section 7 that the Practice sets section rewrote, and the score bullet and
the progress bullet that the Phase 6 section rewrote; this wording wins over all four.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection, which collection, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); and, except for a review or a practice of your mistakes, how many questions it has asked when you complete a round of ten
```

The bullet about progress in a quiz now reads:

```
- How far you progressed in a quiz if you quit it, or if you leave the app during it (the question number reached, reported the next time you open the app), except in a review or a practice of your mistakes, whose length would show how many of your answers were wrong
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); y, salvo en un repaso o en una práctica de sus errores, cuántas preguntas lleva al terminar una tanda de diez
```

El punto sobre el progreso en un cuestionario queda así:

```
- Su progreso en un cuestionario si lo abandona o si sale de la aplicación durante él (el número de pregunta alcanzado, que se comunica la próxima vez que abre la aplicación), salvo en un repaso o en una práctica de sus errores, cuya longitud mostraría cuántas de sus respuestas fueron incorrectas
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## The practice hub (pedagogy plan, Phase 12, 2026-11-23)

The quiz's results no longer offer the leaderboard. The Quiz tab does instead, with a small button
shown while the learner is signed in to Game Center, and its `tapViewLeaderboard` carries `level`,
the board it opens, and `source` with the one value `tab`. Settings' still sends the signal with no
parameter. The in-app-actions bullet already says "opening a Game Center leaderboard (and which
level's)", and where it was opened is no new kind of information, so the bullet does not change.
The Quiz tab now shows the last quiz's results (what was quizzed, the level, the day, how many
answers were right, and the score), which the app keeps on the device beside the practice record
and never sends. This rewrites the paragraph after the list in section 2 that the practice-record
section rewrote; this wording wins.

### English

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews and show how your last quiz went, the app keeps a record of which conjugations you have practiced, how your last answers went, and the results of your last quiz; that record stays on your device and is never sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos y mostrarle cómo le fue su último cuestionario, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas y los resultados de su último cuestionario; ese registro se queda en su dispositivo y nunca se envía. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## Verb Essentials (pedagogy plan, Phase 14, 2026-11-23)

The Quiz tab gains Verb Essentials, an exercise that asks irregular verbs' key forms (tengo, tuve,
tendré, tenido), five verbs a round. It begins sending `verbEssentials` as the `source` of the quiz
signals. Its `completeQuiz` keeps `questionCount`, since a round's length depends on no answer, but
a round is twenty questions, not ten, so the score bullet's "a round of ten" becomes "a round". It
sends no score and posts none to Game Center. This rewrites the quiz-lifecycle bullet, the score
bullet, and the first paragraph of section 7 that the Review and Practice My Mistakes section
rewrote; this wording wins over all three. The progress bullet does not change.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection, which collection, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); and, except for a review or a practice of your mistakes, how many questions it has asked when you complete a round
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); y, salvo en un repaso o en una práctica de sus errores, cuántas preguntas lleva al terminar una tanda
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Verb Models (pedagogy plan, Phase 15, 2026-11-23)

The Quiz tab and each model's page gain the practice of a verb model: Verb Essentials over one
model's verbs alone, then mixed with the models the learner knows. It begins sending `modelAlone`
and `modelMixed` as the `source` of the quiz signals, and `startQuiz` names the model in
`collection` (`model-4A`), as a model's collection quiz already does. A mixed session sends no
`questionCount` or `questionNumber`, since its round can be short when the known models hold few
verbs, and which models are known comes from the learner's answers. Neither sends a score or posts
one to Game Center. Whether a model is known is computed on the device from the practice record and
never sent. This rewrites the quiz-lifecycle bullet, the score bullet, and the first paragraph of
section 7 that the Verb Essentials section rewrote; this wording wins over all three.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); and, except for a review, a practice of your mistakes, or a verb model's mixed practice, how many questions it has asked when you complete a round
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); y, salvo en un repaso, en una práctica de sus errores o en la práctica mezclada de un modelo de verbos, cuántas preguntas lleva al terminar una tanda
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Name the Form (pedagogy plan, Phase 16, 2026-11-23)

The Quiz tab gains Name the Form, an exercise that shows a form (fuera) and asks for its verb,
tense, and person, ten a round. It begins sending `recognition` as the `source` of the quiz
signals. Its `completeQuiz` keeps `questionCount`, since a round's length depends on no answer. It
sends no score and posts none to Game Center, and its answers are not kept in the practice record.
This rewrites the quiz-lifecycle bullet and the first paragraph of section 7 that the Verb Models
section rewrote; this wording wins over both. The score bullet does not change.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, the Name the Form exercise, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, the Name the Form exercise, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en el ejercicio Identifica la forma, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, del ejercicio Identifica la forma, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Complete the Sentence (pedagogy plan, Phase 17, 2026-11-23)

The Quiz tab gains Complete the Sentence, an exercise that asks for the verb missing from a short
sentence, ten a round. It begins sending `sentences` as the `source` of the quiz signals. Its
`completeQuiz` keeps `questionCount`, since a round's length depends on the sentences at the
learner's level and on no answer. It sends no score and posts none to Game Center. Its answers are
kept in the practice record on the device, as the default quiz's are, which the paragraph after
the list already covers. The results' Example Use, which shows a verb's example sentence on a right
answer's row, sends nothing, since only right rows offer it. This rewrites the quiz-lifecycle
bullet and the first paragraph of section 7 that the Name the Form section rewrote; this wording
wins over both. The score bullet does not change.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, the Name the Form exercise, the Complete the Sentence exercise, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, the Name the Form exercise, the Complete the Sentence exercise, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en el ejercicio Identifica la forma, en el ejercicio Completa la frase, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, del ejercicio Identifica la forma, del ejercicio Completa la frase, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Mastery (pedagogy plan, Phase 19, 2026-11-24)

Adds the signal `viewMastery`, sent with no parameters when the Mastery page, reached from the Quiz
tab, appears. It carries nothing: not the level, and nothing of what the page shows. The page shows,
from the practice record kept on the device, which regular patterns and irregular verbs the learner
has mastered, so the paragraph after the list names it. This rewrites the screens bullet of section
2, which no earlier section here rewrote, and the paragraph after the list that the practice-hub
section rewrote; this wording wins.

### English

The first bullet in section 2 now reads:

```
- Which screens you visit (verbs, verb models, quiz, quiz results, mastery, info articles, settings, the onboarding tour, and the tutor)
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, and show which conjugations you have mastered, the app keeps a record of which conjugations you have practiced, how your last answers went, and the results of your last quiz; that record stays on your device and is never sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

El primer punto de la sección 2 queda así:

```
- Las pantallas que usted visita (verbos, modelos de verbos, cuestionario, resultados del cuestionario, dominio, artículos informativos, ajustes, la introducción y el tutor)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario y mostrarle qué conjugaciones domina, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas y los resultados de su último cuestionario; ese registro se queda en su dispositivo y nunca se envía. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## Speed Round (pedagogy plan, Phase 20, 2026-11-24)

The Quiz tab gains the Speed Round, sixty seconds of questions on what the practice record says the
learner has mastered, counting right answers. It begins sending `speedRound` as the `source` of the
quiz signals. It sends no `questionCount` or `questionNumber`, since a round's length is how many
questions were answered in a minute, which measures the answers themselves. It sends no score and
posts none to Game Center. The round records nothing in the practice record. It keeps one personal
best, the most right answers in a round, on the device beside the last quiz's results, and never
sends it, so the paragraph after the list names it. This rewrites the quiz-lifecycle bullet and the
first paragraph of section 7 that the Complete the Sentence section rewrote, the score bullet that
the Verb Models section rewrote, and the paragraph after the list that the Mastery section rewrote;
this wording wins over all four.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); and, except for a review, a practice of your mistakes, a verb model's mixed practice, or the Speed Round, how many questions it has asked when you complete a round
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, show which conjugations you have mastered, and keep your Speed Round best, the app keeps a record of which conjugations you have practiced, how your last answers went, the results of your last quiz, and your most right answers in a Speed Round; that record stays on your device and is never sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, a collection, or a single verb's page, are not. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en el ejercicio Identifica la forma, en el ejercicio Completa la frase, en la Ronda rápida, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); y, salvo en un repaso, en una práctica de sus errores, en la práctica mezclada de un modelo de verbos o en la Ronda rápida, cuántas preguntas lleva al terminar una tanda
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario, mostrarle qué conjugaciones domina y guardar su récord en la Ronda rápida, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas, los resultados de su último cuestionario y su mayor número de respuestas correctas en una Ronda rápida; ese registro se queda en su dispositivo y nunca se envía. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, del ejercicio Identifica la forma, del ejercicio Completa la frase, de la Ronda rápida, sobre una colección o sobre la página de un solo verbo, no. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Daily session and streak (pedagogy plan, Phase 21, 2026-11-24)

The Quiz tab gains the Daily Session, ten questions at the learner's level, filled first from what
the practice record has due. Finishing one a day builds a streak, and a streak broken by one missed
day is repaired by two sessions the next day. Settings gains an optional daily reminder, a local
notification at a time the learner picks, for which the app asks permission only when it is turned
on. The quiz signals gain two `source` values, `daily` for a session started from the Quiz tab and
`reminder` for one started by tapping the reminder. A daily session's `completeQuiz` carries a new
`streak` parameter, the streak's length in bands (`1`, `2-6`, `7-29`, `30+`), and, as every round of
ten does, `questionCount`. It sends no score and posts none to Game Center. A new signal,
`tapDailyReminder`, is sent when the reminder is turned on or off in Settings, with `enabled` set to
`true`, `false`, or `denied` (turned on, then refused permission). The streak, the days on which a
session was finished, is kept on the device beside the practice record and never sent but as that
band. The reminders are written and scheduled on the device. This rewrites the quiz-lifecycle
bullet, the score bullet, and the paragraph after the list that the Speed Round section rewrote,
and the in-app-actions bullet that the practice-record section rewrote; this wording wins over all
four. Section 7 does not change, since it already names only the quiz over all verbs as posting.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, the daily session, a daily reminder you tapped, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For a quiz over all verbs, the score of its first ten questions, when you complete them or quit during them; for every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); and, except for a review, a practice of your mistakes, a verb model's mixed practice, or the Speed Round, how many questions it has asked when you complete a round; and, when you complete a daily session, roughly how many days your streak of daily sessions has reached (1, 2 to 6, 7 to 29, or 30 or more)
```

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, opening a Game Center leaderboard (and which level's), sharing a practice set as a link or a QR code (how it was shared, and whether it chooses tenses, verbs, or both, but not which ones), opening a shared practice set (and whether its link could be read), keeping a shared practice set as your custom quiz, resetting your practice record, and turning the daily reminder on or off (and whether notifications were refused)
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, show which conjugations you have mastered, keep your Speed Round best, and keep your streak of daily sessions, the app keeps a record of which conjugations you have practiced, how your last answers went, the results of your last quiz, your most right answers in a Speed Round, and the days on which you finished a daily session; that record stays on your device and is never sent. If you turn on the daily reminder, the app writes and schedules its notifications on your device, and nothing about them is sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en el ejercicio Identifica la forma, en el ejercicio Completa la frase, en la Ronda rápida, en la sesión diaria, en un recordatorio diario que tocó, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En un cuestionario sobre todos los verbos, la puntuación de sus diez primeras preguntas, al terminarlas o al abandonarlo durante ellas; en todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); y, salvo en un repaso, en una práctica de sus errores, en la práctica mezclada de un modelo de verbos o en la Ronda rápida, cuántas preguntas lleva al terminar una tanda; y, al terminar una sesión diaria, cuántos días aproximadamente lleva su racha de sesiones diarias (1, de 2 a 6, de 7 a 29, o 30 o más)
```

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso, abrir una clasificación de Game Center (y de qué nivel), compartir una serie de práctica como enlace o código QR (cómo se compartió y si elige tiempos, verbos o ambos, pero no cuáles), abrir una serie de práctica compartida (y si su enlace se pudo leer), guardar una serie de práctica compartida como su cuestionario personalizado, restablecer su registro de práctica y activar o desactivar el recordatorio diario (y si se rechazaron las notificaciones)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario, mostrarle qué conjugaciones domina guardar su récord en la Ronda rápida y llevar la cuenta de su racha de sesiones diarias, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas, los resultados de su último cuestionario, su mayor número de respuestas correctas en una Ronda rápida y los días en que terminó una sesión diaria; ese registro se queda en su dispositivo y nunca se envía. Si activa el recordatorio diario, la aplicación redacta y programa sus notificaciones en su dispositivo, y no se envía nada sobre ellas. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## Personal bests and achievements (pedagogy plan, Phase 22, 2026-11-24)

The app keeps the best ranked score at each level, the score of a quiz over all verbs' first ten
questions, on the device beside the practice record, and shows it on the results and the Quiz tab.
It is never sent; the score itself was already sent and posted as before. Conjugar gains eight Game
Center achievements for mastering conjugations. While the learner is signed in to Game Center, the
app sends Game Center each achievement's progress as a percentage, figured on the device from the
practice record, and only when it has risen. No analytics signal says that an achievement was
earned. A new signal, `tapViewAchievements`, is sent when View Achievements is tapped, with `source`
`tab` from the Quiz tab and nothing from Settings. This rewrites the in-app-actions bullet and the
paragraph after the list that the daily-session section rewrote, and the first paragraph of section
7 that the Speed Round section rewrote; this wording wins over all three. It also mends the Spanish
paragraph's missing comma after "domina".

### English

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, opening a Game Center leaderboard (and which level's), opening Game Center's achievements, sharing a practice set as a link or a QR code (how it was shared, and whether it chooses tenses, verbs, or both, but not which ones), opening a shared practice set (and whether its link could be read), keeping a shared practice set as your custom quiz, resetting your practice record, and turning the daily reminder on or off (and whether notifications were refused)
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, show which conjugations you have mastered, keep your Speed Round best and your best score at each level, and keep your streak of daily sessions, the app keeps a record of which conjugations you have practiced, how your last answers went, the results of your last quiz, your most right answers in a Speed Round, your best score at each level, and the days on which you finished a daily session; that record stays on your device and is never sent. If you turn on the daily reminder, the app writes and schedules its notifications on your device, and nothing about them is sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level, and for achievements. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, the daily session, a collection, or a single verb's page, are not. While you are signed in to Game Center, the app also sends it your progress toward each of Conjugar's achievements, as a percentage, which Game Center keeps and shows you; the app figures that progress on your device from your practice record, and the record itself is not sent. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso, abrir una clasificación de Game Center (y de qué nivel), abrir los logros de Game Center, compartir una serie de práctica como enlace o código QR (cómo se compartió y si elige tiempos, verbos o ambos, pero no cuáles), abrir una serie de práctica compartida (y si su enlace se pudo leer), guardar una serie de práctica compartida como su cuestionario personalizado, restablecer su registro de práctica y activar o desactivar el recordatorio diario (y si se rechazaron las notificaciones)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario, mostrarle qué conjugaciones domina, guardar su récord en la Ronda rápida y su mejor puntuación en cada nivel, y llevar la cuenta de su racha de sesiones diarias, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas, los resultados de su último cuestionario, su mayor número de respuestas correctas en una Ronda rápida, su mejor puntuación en cada nivel y los días en que terminó una sesión diaria; ese registro se queda en su dispositivo y nunca se envía. Si activa el recordatorio diario, la aplicación redacta y programa sus notificaciones en su dispositivo, y no se envía nada sobre ellas. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel, y para los logros. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, del ejercicio Identifica la forma, del ejercicio Completa la frase, de la Ronda rápida, de la sesión diaria, sobre una colección o sobre la página de un solo verbo, no. Mientras tenga la sesión iniciada en Game Center, la aplicación también le envía su progreso hacia cada uno de los logros de Conjugar, como un porcentaje, que Game Center guarda y le muestra; la aplicación calcula ese progreso en su dispositivo a partir de su registro de práctica, y el registro mismo no se envía. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## Daily challenge (pedagogy plan, Phase 23, 2026-11-24)

The Quiz tab gains the Daily Challenge: five questions a day for each level and region, the same on
every device on that date, taken once, whose result can be shared as text with a link that opens
the same challenge. The quiz widget's question is now the first of the day's challenge, and a tap
beside its answers opens the challenge. The quiz signals gain three `source` values: `challenge`
for a challenge started from the Quiz tab, `challengeLink` for one opened from a shared result's
link, and `challengeWidget` for one opened from the quiz widget. A challenge's `completeQuiz` sends
`questionCount`, always five, and no score; it posts none to Game Center. A new signal,
`tapShareChallenge`, is sent when Share Result is tapped, with `level`, the level of the challenge
shared; it never says the result. The results of the last twelve challenges are kept on the device
beside the practice record and never sent. This rewrites the quiz-lifecycle bullet that the
daily-session section rewrote, the in-app-actions bullet and the paragraph after the list that the
personal-bests section rewrote, and the first paragraph of section 7 that the personal-bests section
rewrote; this wording wins over all four. The score bullet does not change, since "how many
questions it has asked when you complete a round" already covers a challenge's five.

### English

The bullet about quiz lifecycle events in section 2 now reads:

```
- Quiz lifecycle events (starting, quitting, or completing a quiz), where you began the quiz (for example the Quiz tab, My Verbs, a custom quiz of your own choosing, a review of what is due, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model alone or mixed with the models you know, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, the daily session, a daily reminder you tapped, the daily challenge, a daily challenge someone shared with you, the quiz widget, a practice set someone shared with you as a link or a QR code, a verb's page, a collection, or a link), for a quiz over a collection or a verb model, which one, and, for a custom quiz or a practice set, whether it chooses tenses, verbs, or both (but not which ones)
```

The bullet about in-app actions in section 2 now reads:

```
- Certain in-app actions: opening the game, reshowing the onboarding tour, tapping to rate or review the app, sending a message to the tutor, opening a tense's article from a verb's page, tapping to share a verb's page, tapping to share a collection of verbs (and which collection), starring or unstarring a verb (whether the verb is starred afterward, but not which verb), revealing the conjugations on a review card, opening a Game Center leaderboard (and which level's), opening Game Center's achievements, sharing a practice set as a link or a QR code (how it was shared, and whether it chooses tenses, verbs, or both, but not which ones), opening a shared practice set (and whether its link could be read), keeping a shared practice set as your custom quiz, tapping to share the result of a daily challenge (and which level's challenge, but not the result), resetting your practice record, and turning the daily reminder on or off (and whether notifications were refused)
```

The paragraph after the list now reads:

```
Your quiz score and the rough duration of a quiz are collected, but, like all of these analytics, they are anonymized and are not tied to your identity (see Section 4). The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, show which conjugations you have mastered, keep your Speed Round best and your best score at each level, keep your streak of daily sessions, and show and share how your daily challenges went, the app keeps a record of which conjugations you have practiced, how your last answers went, the results of your last quiz, your most right answers in a Speed Round, your best score at each level, the days on which you finished a daily session, and the results of your last daily challenges; that record stays on your device and is never sent. A daily challenge's result leaves your device only if you share it yourself. If you turn on the daily reminder, the app writes and schedules its notifications on your device, and nothing about them is sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

The first paragraph of section 7 now reads:

```
Conjugar integrates with Apple Game Center for quiz leaderboards, one for each quiz level, and for achievements. When you submit a score, Game Center handles that data according to Apple's privacy policy. Only the score of the first ten questions of a quiz over all verbs is submitted, to the leaderboard of the level the quiz was taken at; the questions after them, and a quiz over My Verbs, a custom quiz, a shared practice set, a review, a practice of your mistakes, the Verb Essentials exercise, the practice of a verb model, the Name the Form exercise, the Complete the Sentence exercise, the Speed Round, the daily session, the daily challenge, a collection, or a single verb's page, are not. While you are signed in to Game Center, the app also sends it your progress toward each of Conjugar's achievements, as a percentage, which Game Center keeps and shows you; the app figures that progress on your device from your practice record, and the record itself is not sent. The developer does not have access to your Game Center identity or personal information through this integration.
```

### Spanish

El punto sobre los eventos del ciclo de vida de un cuestionario, en la sección 2, queda así:

```
- Los eventos del ciclo de vida de un cuestionario (comenzar, abandonar o terminar un cuestionario), dónde lo empezó (por ejemplo, en la pestaña del cuestionario, en Mis verbos, en un cuestionario personalizado que usted eligió, en un repaso de lo pendiente, en una práctica de sus errores, en el ejercicio Lo esencial del verbo, en la práctica de un modelo de verbos, solo o mezclado con los modelos que conoce, en el ejercicio Identifica la forma, en el ejercicio Completa la frase, en la Ronda rápida, en la sesión diaria, en un recordatorio diario que tocó, en el desafío diario, en un desafío diario que alguien le compartió, en el widget del cuestionario, en una serie de práctica que alguien le compartió como enlace o código QR, en la página de un verbo, en una colección o desde un enlace), si el cuestionario es sobre una colección o un modelo de verbos, cuál y, si es personalizado o una serie de práctica, si elige tiempos, verbos o ambos (pero no cuáles)
```

El punto sobre las acciones dentro de la aplicación, en la sección 2, queda así:

```
- Ciertas acciones dentro de la aplicación: abrir el juego, volver a mostrar la introducción, tocar para valorar o reseñar la aplicación, enviar un mensaje al tutor, abrir el artículo de un tiempo verbal desde la página de un verbo, tocar para compartir la página de un verbo, tocar para compartir una colección de verbos (y cuál), marcar o desmarcar un verbo con una estrella (si el verbo queda marcado, pero no de qué verbo se trata), mostrar las conjugaciones de una tarjeta de repaso, abrir una clasificación de Game Center (y de qué nivel), abrir los logros de Game Center, compartir una serie de práctica como enlace o código QR (cómo se compartió y si elige tiempos, verbos o ambos, pero no cuáles), abrir una serie de práctica compartida (y si su enlace se pudo leer), guardar una serie de práctica compartida como su cuestionario personalizado, tocar para compartir el resultado de un desafío diario (y de qué nivel es el desafío, pero no el resultado), restablecer su registro de práctica y activar o desactivar el recordatorio diario (y si se rechazaron las notificaciones)
```

El párrafo que sigue a la lista queda así:

```
Su puntuación y la duración aproximada de un cuestionario se recopilan, pero, como todas estas estadísticas, están anonimizadas y no están vinculadas a su identidad (véase la sección 4). La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario, mostrarle qué conjugaciones domina, guardar su récord en la Ronda rápida y su mejor puntuación en cada nivel, llevar la cuenta de su racha de sesiones diarias, y mostrarle y compartir cómo le fueron sus desafíos diarios, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas, los resultados de su último cuestionario, su mayor número de respuestas correctas en una Ronda rápida, su mejor puntuación en cada nivel, los días en que terminó una sesión diaria y los resultados de sus últimos desafíos diarios; ese registro se queda en su dispositivo y nunca se envía. El resultado de un desafío diario solo sale de su dispositivo si usted mismo lo comparte. Si activa el recordatorio diario, la aplicación redacta y programa sus notificaciones en su dispositivo, y no se envía nada sobre ellas. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

El primer párrafo de la sección 7 queda así:

```
Conjugar se integra con Apple Game Center para las clasificaciones de los cuestionarios, una para cada nivel, y para los logros. Cuando usted envía una puntuación, Game Center trata esos datos conforme a la política de privacidad de Apple. Solo se envía la puntuación de las diez primeras preguntas de un cuestionario sobre todos los verbos, a la clasificación del nivel en que se hizo; la de las preguntas siguientes y la de un cuestionario sobre Mis verbos, de un cuestionario personalizado, de una serie de práctica compartida, de un repaso, de una práctica de sus errores, del ejercicio Lo esencial del verbo, de la práctica de un modelo de verbos, del ejercicio Identifica la forma, del ejercicio Completa la frase, de la Ronda rápida, de la sesión diaria, del desafío diario, sobre una colección o sobre la página de un solo verbo, no. Mientras tenga la sesión iniciada en Game Center, la aplicación también le envía su progreso hacia cada uno de los logros de Conjugar, como un porcentaje, que Game Center guarda y le muestra; la aplicación calcula ese progreso en su dispositivo a partir de su registro de práctica, y el registro mismo no se envía. El desarrollador no tiene acceso a su identidad de Game Center ni a su información personal a través de esta integración.
```

## No quiz score (pedagogy plan, after the Closing, 2026-11-24)

`completeQuiz` and `quitQuiz` no longer send `score`, which a quiz over all verbs sent for its first
ten questions. Josh removed it so that Conjugar agrees with Conjuguer and Konjugieren, which send no
score, and because a score sent on a quit counted the right answers before it. The deployed policy
discloses the score, so its bullet and the paragraph after the list change. This rewrites the score
bullet that the daily-session section rewrote and the paragraph after the list that the
daily-challenge section rewrote; this wording wins over both. Section 7 does not change: the score
of a quiz over all verbs' first ten questions still goes to Game Center, and the best at each level
is still kept on the device and never sent.

### English

The bullet about the quiz score and elapsed time in section 2 now reads:

```
- For every quiz, roughly how long it ran when you quit or complete a round (under 3 seconds, 3 to 15 seconds, 15 to 40 seconds, 40 seconds to 2 minutes, or longer); except for a review, a practice of your mistakes, a verb model's mixed practice, or the Speed Round, how many questions it has asked when you complete a round; and, when you complete a daily session, roughly how many days your streak of daily sessions has reached (1, 2 to 6, 7 to 29, or 30 or more)
```

The paragraph after the list now reads:

```
The rough duration of a quiz is collected, but, like all of these analytics, it is anonymized and is not tied to your identity (see Section 4). Your quiz score is not collected. The app does not send your quiz answers, how many of them were right, which verbs you look up, or any text you type. To schedule your reviews, show how your last quiz went, show which conjugations you have mastered, keep your Speed Round best and your best score at each level, keep your streak of daily sessions, and show and share how your daily challenges went, the app keeps a record of which conjugations you have practiced, how your last answers went, the results of your last quiz, your most right answers in a Speed Round, your best score at each level, the days on which you finished a daily session, and the results of your last daily challenges; that record stays on your device and is never sent. A daily challenge's result leaves your device only if you share it yourself. If you turn on the daily reminder, the app writes and schedules its notifications on your device, and nothing about them is sent. That you searched is recorded, with the rough counts above; what you typed is not. That you opened a verb's page is recorded; which verb is not.
```

### Spanish

El punto sobre la puntuación y el tiempo transcurrido, en la sección 2, queda así:

```
- En todo cuestionario, cuánto duró aproximadamente al abandonarlo o al terminar una tanda (menos de 3 segundos, de 3 a 15 segundos, de 15 a 40 segundos, de 40 segundos a 2 minutos, o más); salvo en un repaso, en una práctica de sus errores, en la práctica mezclada de un modelo de verbos o en la Ronda rápida, cuántas preguntas lleva al terminar una tanda; y, al terminar una sesión diaria, cuántos días aproximadamente lleva su racha de sesiones diarias (1, de 2 a 6, de 7 a 29, o 30 o más)
```

El párrafo que sigue a la lista queda así:

```
La duración aproximada de un cuestionario se recopila, pero, como todas estas estadísticas, está anonimizada y no está vinculada a su identidad (véase la sección 4). Su puntuación en los cuestionarios no se recopila. La aplicación no envía sus respuestas del cuestionario, cuántas acertó, qué verbos consulta ni ningún texto que escriba. Para programar sus repasos, mostrarle cómo le fue su último cuestionario, mostrarle qué conjugaciones domina, guardar su récord en la Ronda rápida y su mejor puntuación en cada nivel, llevar la cuenta de su racha de sesiones diarias, y mostrarle y compartir cómo le fueron sus desafíos diarios, la aplicación guarda un registro de qué conjugaciones ha practicado, cómo le fueron sus últimas respuestas, los resultados de su último cuestionario, su mayor número de respuestas correctas en una Ronda rápida, su mejor puntuación en cada nivel, los días en que terminó una sesión diaria y los resultados de sus últimos desafíos diarios; ese registro se queda en su dispositivo y nunca se envía. El resultado de un desafío diario solo sale de su dispositivo si usted mismo lo comparte. Si activa el recordatorio diario, la aplicación redacta y programa sus notificaciones en su dispositivo, y no se envía nada sobre ellas. Se registra que usted hizo una búsqueda, con las cifras aproximadas indicadas arriba, pero no lo que escribió. Se registra que abrió la página de un verbo, pero no de cuál.
```

## My Verbs and the collections' progress (verb browse fixes plan, Phase 3, 2026-11-25)

No signal, parameter, or value is added or removed. What the list kept on the device is for, and
what forgets it, changed: a collection now counts every verb ever opened, Clear and a swipe in My
Verbs no longer forget that, and Settings' Reset Practice does. This rewrites the paragraph about
the list kept on the device, as the review card's section gives it; apply this wording in place of
that one.

### English

The paragraph about the list kept on the device now reads:

```
To show your recent and starred verbs in My Verbs, to show how many of a collection's verbs you have looked up, and to offer review cards, the app keeps a list of the verbs you open and star, with when you opened them, how often, and when each is next due for review. The list stays on your device, in storage shared only with the app's own widgets. It is never sent to the developer or to anyone else, and it is deleted when you delete the app. You can clear the recent verbs, or remove any verb, in My Verbs; the collections still count every verb you have opened. Reset Practice in Settings forgets which verbs you have opened and how often.
```

### Spanish

El párrafo sobre la lista guardada en el dispositivo queda así:

```
Para mostrar sus verbos recientes y marcados con una estrella en Mis verbos, para mostrar cuántos verbos de una colección ha consultado y para ofrecerle tarjetas de repaso, la aplicación guarda una lista de los verbos que abre y marca, con la fecha en que los abrió, cuántas veces y cuándo le toca repasar cada uno. La lista se queda en su dispositivo, en un almacenamiento que solo comparte con los widgets de la propia aplicación. Nunca se envía al desarrollador ni a nadie más, y se borra al eliminar la aplicación. En Mis verbos puede borrar los verbos recientes o quitar cualquier verbo; las colecciones siguen contando todos los verbos que ha abierto. Restablecer práctica, en Configuración, olvida qué verbos ha abierto y cuántas veces.
```

## The Related Verbs card and time in view (verb browse fixes plan, Phase 5, 2026-11-25)

Adds `related`, the Related Verbs card at the bottom of a verb's page, to `leaveVerbView`'s
`deepestSection`. A visit to a page now also ends when the page opens a sheet over itself (a
tense's article, Test Me) and begins again, as `resume`, when the sheet closes, so the time
reported is time the page was in view. This rewrites the second bullet of the lookup signals'
section; apply this wording in place of that one.

### English

```
- How far down a verb's page you scrolled (its top, the simple tenses, the compound tenses, the etymology, the examples, or the related verbs), and roughly how long the page was in view (under 5 seconds, 5 to 15 seconds, 15 to 60 seconds, or longer)
```

### Spanish

```
- Hasta dónde se desplazó en la página de un verbo (el principio, los tiempos simples, los tiempos compuestos, la etimología, los ejemplos o los verbos relacionados) y, aproximadamente, cuánto tiempo estuvo a la vista la página (menos de 5 segundos, de 5 a 15 segundos, de 15 a 60 segundos o más)
```
