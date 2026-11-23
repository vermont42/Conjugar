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

