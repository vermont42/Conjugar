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
