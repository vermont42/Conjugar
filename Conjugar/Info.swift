//
//  Info.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

struct Info {
  let heading: String
  let difficulty: Difficulty
  let text: String
  let infoString: NSAttributedString

  private init(heading: String, difficulty: Difficulty, text: String) {
    guard let encodedHeading = heading.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
      fatalError("Could not URL encode heading \(heading).")
    }
    self.heading = encodedHeading
    self.difficulty = difficulty
    self.text = String(String.headingSeparator) + heading + String(String.headingSeparator) + "\n\n" + text
    infoString = self.text.infoString
  }

  static let infos: [Info] = [
    Info(heading: Localizations.Info.purposeAndUseHeading, difficulty: .easy, text: NSLocalizedString("purposeAndUseText", value:
"""
^Purpose^

In Spanish, conjugation, a concept defined in %terminology%, is important for the reasons stated there. People raised in Spanish-speaking countries learn conjugation passively, and people who engage in formal Spanish learn conjugation as part of that study.

But there exists another category of Spanish-learners: people, like the developer of ~Conjugar~, who live in non-Spanish-speaking countries, who are currently unable to engage in formal study of Spanish, but who are exposed to Spanish vocabulary by one means or another. Here is an example of the challenge that these learners face.

The developer of ~Conjugar~ knew, from exposure to Spanish in a previous job, that "ir" means "to go" and that "ir" has certain conjugations starting with "va-". But this knowledge did not allow him to communicate with Spanish-speakers he encountered. For instance, to express the thought "I'm going to the office", he might have said "ir a la oficina" or "va a la oficina". But these sentences were nonsensical to Spanish-speakers because the conjugations were incorrect. The correct (and understandable) sentence was (and is) "$voY$ a la oficina".

There are excellent resources for Spanish-verb conjugation. The website ~SpanishDict.com~ and the book ~Spanish Verbs Made Simple(r)~ are two of them. The developer of ~Conjugar~ used these resources when he wrote Spanish, but they were unavailable when he spoke Spanish extemporaneously. At some point, he realized that he needed a way to practice conjugating Spanish verbs so that correct conjugations sprang to mind when he was speaking.

This was the genesis of ~Conjugar~, the app whose majesty now envelops you. ~Conjugar~ allows you practice conjugating, via quizzes, ~all~ Spanish verb tenses so that correct conjugations are in your brain at the exact moment you need them. ~Conjugar~ gamifies this experience by scoring each practice session and potentially uploading it to Game Center, allowing you to compete against the global Spanish-verb-conjugation community. Some tenses are rare except in archaic or formal texts and are less useful for many learners. ~Conjugar~ therefore provides three difficulty levels for practice sessions. ~Easy~ tests the three most important tenses. ~Moderate~ tests all tenses that Spanish-speakers commonly use. ~Difficult~ tests ~all~ tenses, including a few that you are unlikely to encounter unless you are reading, for example, ~El ingenioso hidalgo don Quixote de la Mancha~.

^Use^

Primary navigation in ~Conjugar~ occurs via the tab bar at the bottom of the screen. Descriptions of these tabs follow.

~Conjugar~ starts on the ~Browse~ tab. This tab has three lists of Spanish verbs: a list of many irregular verbs, a list of many regular verbs, and a list that combines the other two. Swap these lists by tapping a yellow button above the tab bar. When you find a verb you would like to know more about, tap it. ~Conjugar~ then displays a screen with ~all~ conjugations of that verb. This screen is helpful for learning because it calls out, by highlighting in $RED$, parts of conjugations that are irregular. For example, the %presente de indicativo%, first-person singular conjugation of "dar" has an irregular "y", so ~Conjugar~ displays this conjugation as "$doY$". Tap any conjugation to hear it spoken. Tap ~Browse~ in the top-left corner to return to the ~Browse~ tab.

Tap ~Quiz~ in the tab bar to start a quiz. Tap ~Start~ on the bottom-left corner of the screen. ~Conjugar~ will then present you a set of fifty Spanish verbs to conjugate. Conjugate.

If a letter in a word like "habló" requires an accent mark and you input, for example, "hablo", you will receive partial credit for that conjugation. To input an accented letter, hold your finger on ("long press") the letter you want to accent, "o" in this example, swipe to the accented letter, "ó" in this example, and release.

When you are done with the quiz, ~Conjugar~ will report and score your results, uploading the score to Game Center if it represents a personal best. Tap ~Quiz~ in the top-left corner to return to the ~Quiz~ tab. You can then start a new quiz.

Tap ~Settings~ in the tab bar to access settings.

One class of conjugations, those of ~vosotros~, is important in Spain but largely absent in Latin America. If your goal is to communicate with Latin-American Spanish-speakers, you may want to have ~Conjugar~ omit ~vosotros~ conjugations from quizzes. If so, tap ~Latin America~ in the ~Region~ section.

In recognition of the added difficulty of learning ~vosotros~ conjugations, ~Conjugar~ assigns higher scores to quizzes that include these conjugations.

Spanish verb tenses may be roughly grouped into three classes. The first class consists of the bare minimum of tenses you will need to express yourself in Spanish. If your goal is only to express yourself in Spanish, tap ~Easy~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The second class consists of the tenses that native Spanish speakers regularly use in conversation and writing. If your goal is to understand spoken-and-written Spanish, tap ~Moderate~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The third class consists of all the Spanish verb tenses, including a few that are considered archaic or are rarely used except in formal writing. If your goal is to understand archaic-or-formal Spanish texts, tap ~Difficult~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on ~all~ Spanish verb tenses.

In recognition of the relative difficulties of learning to conjugate the ~Easy~, ~Moderate~, and ~Difficult~ classes of verbs, ~Conjugar~ assigns higher scores to ~Moderate~ quizzes than to ~Easy~ quizzes and assigns higher scores to ~Difficult~ quizzes than to ~Moderate~ quizzes.

As described elsewhere in ~Conjugar~, %voseo% is a phenomenon whereby certain Spanish speakers use the pronoun ~vos~ and its conjugations instead of ~tú~ and its conjugations.

In the ~Settings~ section "Browse Tú and/or Vos", tap "Vos" to see ~vos~ conjugations instead of ~tú~ conjugations on the ~Browse~ tab. Tap "Both" to see both.

In the ~Settings~ section "Quiz Tú or Vos", tap "Vos" to be quizzed on ~vos~, rather than ~tú~, conjugations.

Tap ~Info~ in the tab bar to access information about ~Conjugar~, %terminology%, and the tenses. Near the bottom of the screen is a $RED$ widget for filtering information about tenses by the difficulty mode in which they are quizzed. The three options are ~Easy~; ~Easy~ and ~Moderate~; and ~Easy~, ~Moderate~, and ~Difficult~.
""", comment: "")),
Info(heading: Localizations.Info.terminologyHeading, difficulty: .easy, text: NSLocalizedString("terminologyText", value:
"""
^Verb^

A ~verb~ is a kind of word that stands for an action in a sentence. In the sentence "Celina Zambon dances the flamenco", "to dance" is the verb. Verb ~tense~s express, among other things, temporality. In the example sentence, the verb tense could express that the action is currently taking place. (That said, "is dancing" would specify this more precisely.) In English, to a limited degree, and in Spanish, to a near-total degree, the ~subject~ or actor in the sentence, combined with the tense, determines the exact form of the verb used. This is the verb ~conjugation~. In English, the example sentence's combination of subject and tense results in the conjugation "dances".

The ~infinitivo~ is an invariant form of the verb than ends in -ar, -er, or -ir. The ~infinitivo~ does not indicate time, number, or person. "Bailar" is an infinitivo that means "to dance". Spanish dictionaries and ~Conjugar~'s Browse tab list the infinitivo forms of verbs.

The ~verb stem~ is the inifinitivo minus the -ar, -ir, or -er ending.

^Pronoun^

A subject ~pronoun~ is a word that stands in for a subject. In English, the subject pronouns are ~I~, ~you~, ~he/she/it~, ~we~, ~y'all~, and ~they~.

In both English and Spanish, subject pronouns have the ~singular~ or ~plural~ number. They are also ~first person~, ~second person~, or ~third person~. English subject pronouns correspond to the following person/number combinations:

first person, singular: ~I~
second person, singular: ~you~
third person, singular: ~he/she/it~
first person, plural: ~we~
second person, plural: ~y'all~
third person, plural: ~they~

The first- and third-person subject pronouns in Spanish are straightforward for English-speakers:

first person, singular: ~yo~
third person, singular: ~él~ (masc.)/~ella~ (fem.)
first person, plural: ~nosotros~ (masc.)/~nosotras~ (fem.)
third person, plural: ~ellos~ (masc.)/~ellas~ (fem.)

"Fem." means that a pronoun refers to female subjects, and "masc." means that a pronoun refers to male subjects.

The second-person subject pronouns in Spanish are more complicated in that they encode two formality levels, formal and informal. Further, uses of these pronouns differ between Spain and Latin America.

~Spain~

second person, singular, informal: ~tú~
second person, singular, formal: ~usted~
second person, plural, informal: ~vosotros~ (masc.)/~vosotras~ (fem.)
second person, plural, formal: ~ustedes~

~Much of Latin America~

second person, singular, informal: ~tú~
second person, singular, formal: ~usted~
second person, plural, informal: ~ustedes~
second person, plural, formal: ~ustedes~

Usted and ustedes use the él and ellos conjugations, respectively.

The difference between the two regions is that ~ustedes~ has replaced ~vosotros~/~vosotras~ in Latin America. This replacement means that Spanish-learners in Spain must learn conjugations for six person-number combinations, but Spanish-learners in Latin America must learn conjugations for only five.

In parts of Latin America, ~vos~ has replaced ~tú~ and uses different conjugations. This phenomenon is called %voseo%. Tap the blue word for a description of this phenomenon.

^Order and Presentation of Conjugations^

Treatises on Spanish verbs, when presenting the conjugations for a particular tense, present the conjugations in the following subject-pronoun order: yo, tú, él, nosotros, vosotros, ellos. In the interests of clarity and brevity, ~Conjugar~ does the same. For example, ~Conjugar~ would present the %presente de indicativo% conjugations of ~ser~ as follows:

$soY$, $ERes$, $ES$, $sOmos$, $sOis$, $sOn$

Red letters in conjugations represent irregularities. A verb is considered irregular if any of its conjugations differs from the conjugation of a regular ~ar~, ~ir~, or ~er~ verb.
""", comment: "")),
Info(heading: "Presente de Indicativo", difficulty: .easy, text: NSLocalizedString("presenteDeIndicativoText", value:
"""
^Uses^

The ~presente de indicativo~ is a Spanish verb tense that is used to express the following:

• Present action:

"Malteamos." = "We are malting."

• Habitual action:

"Malteamos." = "We have a habit of malting." or "We malt."

• Emphasis on present action:

"Sí, malteamos." = "Yes, we ~do~ malt."

^Conjugation^

Regular ~ar~, ~ir~, and ~er~ verbs are conjugated in the presente de indicativo by adding the following endings to the verb stem:

AR: -o, -as, -a, -amos, -áis, -an
IR: -o, -es, -e, -imos, -ís, -en
ER: -o, -es, -e, -emos, -éis, -en

Examples:

habl~ar~: hablo, hablas, habla, hablamos, habláis, hablan
sub~ir~: subo, subes, sube, subimos, subís, suben
com~er~: como, comes, come, comemos, coméis, comen

Two verbs that are irregular in the presente de indicativo deserve especial note.

~Estar~, in the presente de indicativo, is used, in conjunction with the %gerundio%, to emphasize an action's ongoing nature. For example, to translate the sentence "I am reading", one might say "$estoY leYendo$".

~Haber~, in the presente de indicativo, is used, in conjunction with the %participio%, to form the %perfecto de indicativo%, a popular verb tense in Spanish-speaking countries. Tap the blue links for descriptions.

Some other verbs that are irregular in the presente de indicativo appear below. Tap the ~Browse~ tab for translations and conjugations.

caber, caer, conocer, conducir, construir, crecer, dar, decir, dormir, hacer, huir, ir, jugar, lucir, oír, pedir, pensar, perder, poner, saber, salir, ser, sentir, tener, traer, valer, venir, ver
""", comment: "")),
Info(heading: "Futuro de Indicativo", difficulty: .easy, text: NSLocalizedString("futuroDeIndicativoText", value:
"""
^Uses^

The ~futuro de indicativo~ is a Spanish Verb tense that is used to express the following:

• A future action:

"El año próximo, visitaré Buenos Aires." = "Next year, I shall/will visit Buenos Aires."

• Uncertainty or probability - inference, rather than direct knowledge:

"¿Quién estará tocando a la puerta?" "Será Fabio." = "Who (do you suppose) is knocking at the door?" "It must be Fabio." or "Who will that be knocking at the door?" "That'll be Fabio."

• Command, prohibition, or obligation:

"No llevarás a ese hombre a mi casa." = "Do not bring that man to my house." or "You will not bring that man to my house."

This form is also used to assert a command, prohibition, or obligation in English.

• Courtesy:

"¿Te importará encender la televisión?" = "Would you mind turning on the television?"

Another common way to represent the future is with a %presente de indicativo% conjugation of ~ir~ followed by an infinitivo verb: "Quizás $VOY$ a viajar a Bolivia en el verano. = "Perhaps I'm going to travel to Bolivia in the summer."

^Conjugation^

The futuro de indicativo uses the %raíz futura% as a stem. The following endings are attached to it:

-é, -ás, -á, -emos, -éis, -án

Example (hablar): hablaré, hablarás, hablará, hablaremos, hablaréis, hablarán

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Pretérito", difficulty: .easy, text: NSLocalizedString("pretéritoText", value:
"""
^Uses^

The ~pretérito~ is a Spanish verb tense that is used to express the following:

• An action that was done in the past:

"Ayer, encontré la flor que tú me $dIste$." = "Yesterday, I found the flower that you $gAve$ me."

This use expresses an action that is viewed as a completed event. It is often accompanied by adverbial expressions of time, such as "ayer", "anteayer", or "la semana pasada".

• An action that interrupts another action:

"Estábamos cenando la cena cuando entró Eduardo." = "We were having dinner when Eduardo $cAme$ in."

This expresses an event that happened (and was completed) while another action was taking place.

• A general truth:

"Las Filipinas $FUeron$ parte del Imperio Español." = "The Philippines were part of the Spanish Empire."

This expresses a past relationship that is viewed as finished.

^Conjugation^

Regular ~ar~, ~ir~, and ~er~ verbs are conjugated in the pretérito by adding the following endings to the verb stem:

AR: -é, -aste, -ó, -amos, -astéis, -aron
IR: -í, -iste, -ió, -imos, -isteis, -ieron
ER: -í, -iste, -ió, -imos, -isteis, -ieron

Examples:

habl~ar~: hablé, hablaste, habló, hablamos, hablastéis, hablaron
sub~ir~: subí, subiste, subió, subimos, subisteis, subieron
com~er~: comí, comiste, comió, comimos, comisteis, comieron

Some verbs that are irregular in the pretérito appear below. Tap the ~Browse~ tab for translations and conjugations.

andar, caber, conducir, dar, decir, estar, haber, hacer, ir, poder, poner, querer, saber, ser, tener, traer, venir

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Condicional", difficulty: .moderate, text: NSLocalizedString("condicionalText", value:
"""
^Uses^

The ~condicional~ is used to express the following:

• Courtesy:

"Señor, ¿$podRía$ darme una copa de vino?" = "Sir, could you give me a glass of wine?"

This use softens a request, making it more polite.

• Polite expression, using querer, of a desire:

"Q$ueRría$ ver la película esta semana." = "I would like to see the film this week."

• In a then clause whose realization depends on a hypothetical if clause:

"Si yo $FUera$ rico, viajaría a Sudamérica." = "If I $WERE$ rich, (then) I would travel to South America."

• Speculation about past events:

"¿Cuántas personas asistieron a la investidura del Presidente?" "No lo $sÉ$; $habRía$ unas 5.000." = "How many people attended the President's inauguration?" "I do not know; there must have been about 5,000."

In this context, the speaker's knowledge is indirect, unconfirmed, or approximate.

• A future action in relation to the past:

"Cuando $ERa$ pequeño, pensaba que me gustaría ser médico." = "When I $WAS$ young, I thought that I would like to be a doctor."

This use expresses future action that was imagined in the past.

• A suggestion:

"Yo que tú, lo olvidaría completamente." = "If I $WERE$ you, I would forget him completely."

^Conjugation^

Like the %futuro de indicativo%, the condicional uses the %raíz futura% as a stem. To form the condicional, the following endings are attached to the raíz futura:

-ía, -ías, -ía, -íamos, -íais, -ían

Example (hablar): hablaría, hablarías, hablaría, hablaríamos, hablaríais, hablarían

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Imperfecto de Indicativo", difficulty: .moderate, text: NSLocalizedString("imperfectoDeIndicativoText", value:
"""
^Uses^

Like the %pretérito% and %perfecto de indicativo%, the ~imperfecto de indicativo~ is used for past events. But the imperfecto de indicativo is used for:

• A habitual or repeated action:

"Cada año mi familia $iBa$ a Puerto Rico." = "Each year my family $WENT$ to Rich Port."

"El gato saltaba al sofá muy a menudo." = "The cat often jumped on the couch."

• A "used to" action:

"Yo leía el diário." = "~I~ used to read the newspaper."

• A background event during which another event in the same sentence occurred:

"Mientras cruzaba la calle, me atropelló un coche." = "While I was crossing the road, a car $rAn$ me over."

^Conjugation^

Regular ~ar~, ~ir~, and ~er~ verbs are conjugated in the imperfecto de indicativo by adding the following endings to the verb stem:

AR: -aba, -abas, -aba, -ábamos, -abais, -aban
IR: -ía, -ías, -ía, -íamos, -íais, -ían
ER: -ía, -ías, -ía, -íamos, -íais, -ían

Examples:

habl~ar~: hablaba, hablabas, hablaba, hablábamos, hablabais, hablaban
sub~ir~: subía, subías, subía, subíamos, subíais, subían
com~er~: comía, comías, comía, comíamos, comíais, comían

Only three verbs are irregular in the imperfecto de indicativo: ir, ser, and ver. Tap the ~Browse~ tab for translations and conjugations.

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Presente de Subjuntivo", difficulty: .moderate, text: NSLocalizedString("presenteDeSubjuntivoText", value:
"""
^Uses^

The ~presente de subjuntivo~ is used to express:

• A command:

"Nos manda que $platiQUemos$." = "He is ordering us to talk."

• Emotional state:

"Tengo miedo de que Colombia no gane la Copa América este año." = "I fear that Colombia will not win the America Cup this year."

• Doubt:

"Dudo que $venGas$ mañana." = "I doubt that thou $wilT$ come tomorrow."

^Conjugation^

Regular ~ar~, ~ir~, and ~er~ verbs are conjugated in the presente de subjuntivo by adding the following endings to the verb stem:

AR: -e, -es, -e, -emos, -éis, -en
IR: -a, -as, -a, -amos, -áis, -an
ER: -a, -as, -a, -amos, -áis, -an

Examples:

habl~ar~: hable, hables, hable, hablemos, habléis, hablen
sub~ir~: suba, subas, suba, subamos, subáis, suban
com~er~: coma, comas, coma, comamos, comáis, coman

Some verbs that are irregular in the presente de subjuntivo appear below. Tap the ~Browse~ tab for translations and conjugations.

caber, caer, conducir, conocer, construir, crecer, dar, decir, dormir, estar, ir, haber, hacer, huir, jugar, lucir, oír, pedir, pensar, perder, poner, saber, sentir, ser, salir, tener, traer, valer, venir, ver
""", comment: "")),
Info(heading: "Imperfecto de Subjuntivo 1", difficulty: .difficult, text: NSLocalizedString("imperfectoDeSubjuntivo1Text", value:
"""
^Use^

The ~imperfecto de subjuntivo 1~ serves a variety of purposes similar to those of the %presente de subjuntivo% but puts actions in the past. Here are some example uses of this tense.

• A command:

"Nos mandó que platicáramos." = "He ordered us to talk."

• Emotional state:

"Temía que Colombia no ganara la Copa América este año." = "I feared that Colombia would not win the America Cup this year."

• Doubt:

"Dudaba que $vIniera$ hoy." = "I doubted that you would come today."

Grammarians consider the imperfecto de subjuntivo 1 and the %imperfecto de subjuntivo 2% to be different variants of the same tense called simply "imperfecto de subjuntivo". In modern Spanish, uses of the two variants do not differ. The developer of ~Conjugar~ has treated these variants as separate tenses with different names for pedagogical purposes.

^Conjugation^

Verbs are conjugated in the imperfecto de subjuntivo 1 by removing the -ron ending from the ellos %pretérito% form of the verb and adding the following ending, depending on the person and number of the subject:

yo: -ra
tú: -ras
él: -ra
nosotros: -ramos
vosotros: -rais
ellos: -ran

Example (cantar): cantara, cantaras, cantara, cantáramos, cantarais, cantaran

As shown in the example, the vowel before the ending of the nosotros conjugation has an acute accent to reflect the stressing of that syllable.

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Imperfecto de Subjuntivo 2", difficulty: .difficult, text: NSLocalizedString("imperfectoDeSubjuntivo2Text", value:
"""
^Use^

The ~imperfecto de subjuntivo 2~ serves a variety of purposes similar to those of the %presente de subjuntivo% but puts actions in the past. Here are some example uses of this tense.

• A command:

"Nos mandó que platicásemos." = "He ordered us to talk."

• Emotional state:

"Temía que Colombia no ganase la Copa América este año." = "I feared that Colombia would not win the America Cup this year."

• Doubt:

"Dudaba que $vIniese$ hoy." = "I doubted that you would come today."

Grammarians consider the imperfecto de subjuntivo 2 and the %imperfecto de subjuntivo 1% to be different variants of the same tense called simply "imperfecto de subjuntivo". In modern Spanish, uses of the two variants do not differ. The developer of ~Conjugar~ has treated these variants as separate tenses with different names for pedagogical purposes.

^Conjugation^

Verbs are conjugated in the imperfecto de subjuntivo 2 by removing the -ron ending from the ellos %pretérito% form of the verb and adding the following ending, depending on the person and number of the subject:

yo: -se
tú: -ses
él: -se
nosotros: -semos
vosotros: -seis
ellos: -sen

Example (cantar): cantase, cantases, cantase, cantásemos, cantaseis, cantasen

As shown in the example, the vowel before the ending of the nosotros conjugation has an acute accent to reflect the stressing of that syllable.

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Futuro de Subjuntivo", difficulty: .difficult, text: NSLocalizedString("futuroDeSubjuntivoText", value:
"""
^Use^

The ~futuro de subjunctivo~ is no longer used in modern Spanish, except in legal language and some fixed expressions.

"Donde fueres, $haZ$ lo que vieres." = "When in Rome, do as the Romans do." = "Cum Romae fueritis, Romano vivite more."

In these expressions, this tense is used to express doubt or uncertainty about whether some event will happen in the future. In modern Spanish, the %presente de subjuntivo% replaces the futuro de subjuntivo. Here are examples of the futuro de subjuntivo:

"Cuando hablaren..." = "Whenever they might speak..."

"$venGa$ lo que $vIniere$" = "come what may"

"El que matare al rey será castigado." = "Whoever kills the king will be punished."

This last example is from a Spanish criminal law. The use of the futuro de subjuntivo in this law alludes to the remoteness of the possibility that the Spanish king will be killed. ¡Viva el Rey!

^Conjugation^

Verbs are conjugated in the futuro de subjuntivo by removing the -ron ending from the ellos %pretérito% form of the verb and adding the following ending, depending on the person and number of the subject:

yo: -re
tú: -res
él: -re
nosotros: -remos
vosotros: -reis
ellos: -ren

Example (cantar): cantare, cantares, cantare, cantáremos, cantareis, cantaren

As shown in the example, the vowel before the ending of the nosotros conjugation has an acute accent to reflect the stressing of that syllable.

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Imperativo Positivo", difficulty: .moderate, text: NSLocalizedString("imperativoPositivoText", value:
"""
^Use^

The ~imperativo positivo~ is used in Spanish to express commands.

"Levanten la mano derecha." = "Raise your right hand(s)."

"Regresad." = "Y'all come back."

"D$I$lo." = "Say it."

"Tejamos." = "Let's knit."

^Conjugation^

For conjugation of the imperativo positivo, nosotros, usted, and ustedes use the %presente de subjuntivo% conjugation. Tú uses the %presente de indicativo% conjugation minus the final s. Vosotros uses the infinitivo minus the final r, plus d.

Thus, for regular ~ar~, ~ir~, and ~er~ verbs, the endings are as follows. Note that there are no yo forms.

AR: -a, -e, -emos, -ad, -en
IR: -e, -a, -amos, -id, -an
ER: -e, -a, -amos, -ed, -an

Examples:

habl~ar~: habla, hable, hablemos, hablad, hablen
sub~ir~: sube, suba, subamos, subid, suban
com~er~: come, coma, comamos, comed, coman

The following verbs have irregular tú imperativo positivo conjugations:

componer: $compóN$
decir: $dI$
hacer: $haZ$
ir: $VE$
obtener: $obtÉn$
ponder: $poN$
salir: $saL$
ser: $sÉ$
tener: $teN$
venir: $veN$
""", comment: "")),
Info(heading: "Imperativo Negativo", difficulty: .moderate, text: NSLocalizedString("imperativoNegativoText", value:
"""
^Use^

The ~imperativo negativo~ is used in Spanish to express negative commands.

"No levanten la mano derecha." = "Don't raise your right hand(s)."

"No regreséis." = "Don't come back, y'all."

"No lo $dIGa$." = "Don't say it."

"No tejamos." = "Let's not knit."

^Conjugation^

For conjugation of the imperativo negativo, the word "no" is prepended to the %presente de subjuntivo% conjugation. Thus, for regular ~ar~, ~ir~, and ~er~ verbs, the endings are as follows. Note that there are no yo forms.

AR: -e, -es, -e, -emos, -éis, -en
IR: -a, -as, -a, -amos, -áis, -an
ER: -a, -as, -a, -amos, -áis, -an

Examples:

habl~ar~: no hables, no hable, no hablemos, no habléis, no hablen
sub~ir~: no subas, no suba, no subamos, no subaís, no suban
com~er~: no comas, no coma, no comamos, no comáis, no coman
""", comment: "")),
Info(heading: "Participio", difficulty: .moderate, text: NSLocalizedString("participioText", value:
"""
^Use^

The ~participio~ corresponds to the English -en, -ed, or -t form of a verb. This form is used following the auxiliary verb ~haber~ to form various compound tenses, including the %perfecto de indicativo%: "(Yo) $hE$ hablado." = "I have $spOken$."

^Form^

The participio is formed by adding the following endings to the verb stem:

~ar~ verbs: -ado

Examples: hablado ("$spOken$"); cantado ("$sUng$"); bailado ("danced")

~er~ verbs: -ido

Examples: bebido ("$drUnk$"); leído (requires acute accent; "$reaD$"); comprendido ("$understOOd$")

~ir~ verbs: -ido

Examples: vivido ("lived"); sentido ("$fElt$"); hervido ("boiled")

When the participio is used as an adjective, it inflects for both gender and number. Example: "una lengua hablada en España" = "a language spoken in Spain"

The following verbs have irregular participios:

abrir: $abIERTo$
cubrir: $cubIERTo$
decir: $dICHo$
escribir: $escriTo$
hacer: $hECHo$
morir: $mUERTo$
poner: $pUESTo$
pudrir: $pOdrido$
resolver: $resUELTo$
romper: $roTo$
ver: $vISTo$
volver: $vUElTo$

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Gerundio", difficulty: .moderate, text: NSLocalizedString("gerundioText", value:
"""
^Uses^

The ~gerundio~ has a variety of uses. The gerundio of hacer, haciendo, can mean "doing", "while doing", "by doing", "because of one's doing", or "through doing".

The gerundio is also used to form a progressive construction called verbal periphrasis. Example: "$estoY haciendo$" ("I $AM$ doing")

The gerundio cannot be used as an adjective and, unlike in most European languages, has no corresponding adjectival forms. The archaic participio presente, which ended in -ante or -iente and formerly filled this function, in some cases survives as an adjective. For example, "$dUrmiente$" = "sleeping", and "interesante" = "interesting". But such cases are limited. Usually, alternate constructions are appropriate. Whereas in English one would say "the crying baby", one would say in Spanish "el bebé que llora", which literally means "the baby who is crying".

^Form^

The gerundio is formed by adding the following endings to the verb stem:

~ar~ verbs: -ando

Examples: hablando ("speaking"); cantando ("singing"); bailando ("dancing")

~er~ verbs: -iendo

Examples: bebiendo ("drinking"); cediendo ("yielding"); comprendiendo ("understanding")

~ir~ verbs: -iendo

Examples: viviendo ("living"); decidiendo ("deciding"); compartiendo ("sharing")

The following verbs have irregular gerundios:

bullir: $bullEndo$
caer: $caYendo$
construir: $construYendo$
dormir: $dUrmiendo$
hervir: $hIrviendo$
huir: $huYendo$
ir: $Yendo$
leer: $leYendo$
medir: $mIdiendo$
oír: $oYendo$
poder: $pUdiendo$
sentir: $sIntiendo$
tañer: $tañEndo$
traer: $traYendo$

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Raíz Futura", difficulty: .easy, text: NSLocalizedString("raízFuturaText", value:
"""
^Uses^

The ~raíz futura~ forms of verbs are used as stems for the %condicional% and %futuro de indicativo% tenses. Tap those tenses for descriptions of them.

^Form^

For all but twelve verbs, the raíz futura is identical to the infinitivo. For example, the raíz futura form of ~bailar~ is "bailar-".

The following verbs have irregular raíz futura forms:

caber: $cabR$-
decir: $dIR$-
haber: $habR$-
hacer: $haR$-
poder: $podR$-
poner: $ponDr$-
querer: $querR$-
saber: $sabR$-
salir: $salDr$-
tener: $tenDr$-
valer: $valDr$-
venir: $venDr$-
""", comment: "")),
Info(heading: "Perfecto de Indicativo", difficulty: .moderate, text: NSLocalizedString("perfectoDeIndicativoText", value:
"""
^Uses^

The ~perfecto de indicativo~ has virtually the same use as the tense sometimes called, in English, the "present perfect".

"Te $hE dICHo$ mi opinión." = "I have $tOLD$ you my opinion." or "I $tOLD$ you my opinion, and it hasn't changed."

In Spanish, as in English, this tense implies that an action, although completed in the past, has continuing effects, truth, or relevance in the present.

^Conjugation^

In the perfecto de indicativo, the %presente de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$hEmos hablado$" = "we have $spOken$"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Pretérito Anterior", difficulty: .difficult, text: NSLocalizedString("pretéritoAnteriorText", value:
"""
^Use^

The ~pretérito anterior~ is very rare in spoken Spanish, but it is sometimes used in formal written language, where it is almost entirely limited to subordinate clauses. Thus, it is usually introduced by temporal conjunctions such as cuando, apenas, or en cuanto. This tense is used to express an action that ended immediately before another past action.

"Cuando $hUbieron llegado$ todos, empezó la ceremonia." = "When everyone had arrived, the ceremony $begAn$."

"Apenas María $hUBO terminado$ la canción, su padre entró." = "As soon as Mary had finished the song, her father $cAme$ in."

^Conjugation^

In the pretérito anterior, the %pretérito% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$hUBE hablado$" = "I had $spOken$"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Pluscuamperfecto de Indicativo", difficulty: .difficult, text: NSLocalizedString("pluscuamperfectoDeIndicativoText", value:
"""
^Use^

The ~pluscuamperfecto de indicativo~ expresses a past action that occurred prior to another past action. This tense is used in practically the same manner as the English "past perfect" tense.

"Cuando bajé a la cocina, mis hijos ya habían preparado el desayuno." = "When I went downstairs to the kitchen, the children had already prepared breakfast."

^Conjugation^

In the pluscuamperfecto de indicativo, the %imperfecto de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$había hablado$" = "it had $spOken$"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Futuro Perfecto", difficulty: .difficult, text: NSLocalizedString("futuroPerfectoText", value:
"""
^Use^

The ~futuro perfecto~ is used to indicate a future action that will be finished before another action.

"Cuando yo llegue a la fiesta, ya se $habRán$ marchado todos." = "When I get to the party, everyone will already have $leFT$."

^Conjugation^

In the futuro perfecto, the %futuro de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$habRé hablado$" = "I will have $spOken$"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Condicional Compuesto", difficulty: .difficult, text: NSLocalizedString("condicionalCompuestoText", value:
"""
^Use^

The ~condicional compuesto~ refers to a hypothetical past action.

"Yo $habRía hablado$ si me $hUbieran dado$ la oportunidad." = "I would have $spOken$ if they had given me the opportunity."

^Conjugation^

In the condicional compuesto, the %condicional% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$habRías decidido$" = "you would have decided"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Perfecto de Subjuntivo", difficulty: .difficult, text: NSLocalizedString("perfectoDeSubjuntivoText", value:
"""
^Use^

The ~perfecto de subjuntivo~ expresses doubt, uncertainty, disbelief, or an emotional state with respect to a past action or to an action that will be complete before some other action.

"Lamentan que él no $haYa podido$ regresar a la casa." = "They regret that he $WAS$ unable to return home."

"Es posible que al finales de este siglo Colombia no $haYa ganado$ la Copa América." = "At the end of the century, it's possible that Colombia will not have $wOn$ the America Cup."

"Dudo que $haYas venido$ antes del final de la película." = "I doubt that you will have come before the end of the movie."

^Conjugation^

In the perfecto de subjuntivo, the %presente de subjuntivo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$haYa hablado$" = "I $spOke$" or "I have $spOken$"

See %credits% for Wikipedia attribution.
""", comment: "")),
Info(heading: "Pluscuamperfecto de Subjuntivo 1", difficulty: .difficult, text: NSLocalizedString("pluscuamperfectoDeSubjuntivo1Text", value:
"""
^Use^

The ~pluscuamperfecto de subjuntivo 1~ expresses doubt, uncertainty, or an emotional state with respect to an action occurring before another past action. As shown in the following example, this tense co-occurs with the %condicional compuesto%. This tense is used in the same manner as the English "third conditional" tense.

"Si me $hUbiera traÍdo$ una chaqueta, ahora no $tendRía$ frío." = "If I had $brOUGHT$ a jacket, I wouldn't be cold now."

Grammarians consider the pluscuamperfecto de subjuntivo 1 and the %pluscuamperfecto de subjuntivo 2% to be different variants of the same tense called simply "pluscuamperfecto de subjuntivo". In modern Spanish, uses of the two variants do not differ. The developer of ~Conjugar~ has treated these variants as separate tenses with different names for pedagogical purposes.

^Conjugation^

In the pluscuamperfecto de subjuntivo 1, the %imperfecto de subjuntivo 1% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$hUbiera hablado$" = "I had $spOken$"
""", comment: "")),
Info(heading: "Pluscuamperfecto de Subjuntivo 2", difficulty: .difficult, text: NSLocalizedString("pluscuamperfectoDeSubjuntivo2Text", value:
"""
^Use^

The ~pluscuamperfecto de subjuntivo 2~ expresses doubt, uncertainty, or an emotional state with respect to an action occurring before another past action. As shown in the following example, this tense co-occurs with the %condicional compuesto%.

"Si me $hUbiese traÍdo$ una chaqueta, ahora no $tendRía$ frío." = "If I had $brOUGHT$ a jacket, I wouldn't be cold now."

Grammarians consider the pluscuamperfecto de subjuntivo 2 and the %pluscuamperfecto de subjuntivo 1% to be different variants of the same tense called simply "pluscuamperfecto de subjuntivo". In modern Spanish, uses of the two variants do not differ. The developer of ~Conjugar~ has treated these variants as separate tenses with different names for pedagogical purposes.

^Conjugation^

In the pluscuamperfecto de subjuntivo 2, the %imperfecto de subjuntivo 2% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$hUbiese hablado$" = "I had $spOken$"
""", comment: "")),
Info(heading: "Futuro Perfecto de Subjuntivo", difficulty: .difficult, text: NSLocalizedString("futuroPerfectoDeSubjuntivoText", value:
"""
^Use^

The ~futuro perfecto de subjuntivo~ expresses an uncertain, future act as finished in relation to a future event. This tense is no longer used in Spanish except in formal or legal texts.

"Si para Navidad no $hUbiere vUELTo$, no me esperéis." = "If he has not returned by Christmas, do not wait for me."

^Conjugation^

In the futuro perfecto de subjuntivo, the %futuro de subjuntivo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: "$hUbiere hablado$" = "I would (or shall) have $spOken$"

See %credits% for Word Reference attribution.
""", comment: "")),
Info(heading: Localizations.Info.questionsAndAnswersHeading, difficulty: .easy, text: NSLocalizedString("questionsAndAnswersText", value:
"""
~Q:~ How can I contact the developer of ~Conjugar~?

~A:~ Email vermontcoder@gmail.com.

~Q:~ There is a verb missing from the ~Browse~ list. What gives?

~A:~ ~Conjugar~'s goal is to teach Spanish-verb conjugation, not to serve as a dictionary. ~SpanishDict.com~ and ~Spanish Verbs Made Simple(r)~ are better choices if you seek exhaustivity. That said, feel free to email ~Conjugar's~ developer at vermontcoder@gmail.com if you would like to see a verb added.

~Q:~ Why does ~Conjugar~ use Spanish names for tenses rather than English, for example, %presente de indicativo% rather than "present indicative"?

~A:~ Admittedly, English tense names would perhaps be more approachable for the learner in certain cases, for example, %raíz futura%. English speakers might better understand the term "future stem". But perhaps because of his years working as a lawyer and software developer, ~Conjugar~'s developer values precision in language. English tense names are imprecise when applied to Spanish tenses. For example, the English "gerund" can act as an adjective, but the Spanish %gerundio% cannot. "Gerund" is, in that sense, inaccurate when applied to the %gerundio%. The same goes for other English tense names and Spanish tenses, to varying degrees.

~Q:~ I've seen the terms "mood" and "aspect" in descriptions of verb tenses, but ~Conjugar~ does not use these terms. Also, the %participio%, %gerundio%, and %raíz futura% are not really tenses.

~A:~ Was that a question? You are correct that ~Conjugar~ does not use these two terms, and those three things are not usually described as "tenses". With respect to terminology, bear in mind that ~Conjugar~'s purpose is to teach Spanish-verb conjugation, not to teach English Spanish-verb-conjugation nomenclature. With respect to the participio, gerundio, and raíz futura, ~Conjugar~'s developer does consider those three things to be tenses, if "tense" is taken to mean "a systematic way of changing verbs for a specific purpose". This definition, though absent, on information and belief, from any dictionary, serves ~Conjugar~'s pedagogical purpose well enough.

~Q:~ Why is Conjugar free?

~A:~ The developer's goals in creating ~Conjugar~ were to learn Spanish-verb conjugation and a software-development technique, programmatic layout, not to earn a living. That said, money is useful, and the developer will implement a tip jar or some other type of in-app purchase if download numbers justify the effort.
""", comment: "")),
Info(heading: "Voseo", difficulty: .easy, text: NSLocalizedString("voseoText", value:
"""
^Background^

In certain parts of Latin America, when addressing one person informally, Spanish speakers use the pronoun ~vos~ and its conjugations instead of the pronoun ~tú~ and its conjugations. This phenomenon, ~voseo~, is ubiquitous in Argentina and occurs, to varying degrees, in all of Latin America except in Dominican Republic and Puerto Rico. Unfortunately, ~vos~ conjugations vary by country and region, complicating matters for the Spanish-learner, but the Real Academia Española (RAE), an authority on the Spanish language, provides model conjugations. These conjugations have some value because a Spanish-speaker from Medellín, Colombia reported to ~Conjugar~'s developer that he uses them. For the sake of expediency, ~Conjugar~ adopts the RAE’s ~vos~ conjugations.

^Conjugation^

~Vos~ conjugations broadly resemble those of ~tú~ and, to a lesser extent, ~vosotros~. In the %presente de indicativo%, the endings are -ás, -ís, and -és for regular AR, IR, and ER verbs, respectively. Examples: hablás, subís, comés.

In the %imperativo positivo%, the endings are -á, -í, and -é for regular AR, IR, and ER verbs, respectively. Examples: hablá, subí, comé. Two irregular ~vos~ %imperativo positivo% verbs are ir ($ANDÁ$) and dar ($dA$).

In the following tenses, the ~vos~ endings are identical to the ~tú~ endings: %pretérito%, %imperfecto de indicativo%, %futuro de indicativo%, %condicional%, %presente de subjuntivo%, %imperfecto de subjuntivo 1%, %imperfecto de subjuntivo 2%, %futuro de subjuntivo%, and %imperativo negativo%.

Compound-tense ~vos~ conjugations are identical to their ~tú~ counterparts.

Certain verbs that change vowels in the ~yo~, ~tú~, ~él~, and ~ellos~ conjugations, but not in the ~nosotros~ or ~vosotros~ conjugations, do not change vowels in the ~vos~ conjugation. Examples: Tú $mUEves$. Vos movés. Yo $pIerdo$. Vos perdés. Ella $pUEde$. Vos podés. In this sense, ~vos~ conjugations are more regular than those of ~yo~, ~tú~, ~él~, and ~ellos~.

See %Credits% for Wikipedia and RAE attribution.
""", comment: "")),
Info(heading: Localizations.Info.creditsHeading, difficulty: .easy, text: NSLocalizedString("creditsText", value:
"""
^Conjugar^

Josh Adams developed ~Conjugar~ and has released its source code under the GNU Affero General Public License, available here: %https://github.com/vermont42/Conjugar/blob/master/LICENSE%

~Conjugar~'s source code lives here: %https://github.com/vermont42/Conjugar/%

^Wikipedia^

Descriptions of the %pretérito%, %futuro de indicativo%, %condicional%, %participio%, %gerundio%, %imperfecto de indicativo%, %futuro de subjuntivo%, %imperfecto de subjuntivo 1%, %imperfecto de subjuntivo 2%, %perfecto de indicativo%, %pluscuamperfecto de indicativo%, %futuro perfecto%, %pretérito anterior%, %condicional compuesto%, and %perfecto de subjuntivo% have been borrowed, in part, from Wikipedia's article on Spanish verbs, %https://en.wikipedia.org/wiki/Spanish_verbs%. The description of %voseo% is informed by Wikipedia's article on ~voseo~, %https://en.wikipedia.org/wiki/Voseo%, as well as the Real Academia Española's conjugations, %http://www.rae.es%. Modifications to Wikipedia's content include, but are not entirely limited to, formatting and the addition of example irregular verbs. Wikipedia has licensed the content of the Spanish-verb and ~voseo~ articles under the Creative Commons Attribution-Share-Alike License 3.0, available at %https://creativecommons.org/licenses/by-sa/3.0/%. All of ~Conjugar~'s developer's modifications of Wikipedia content are licensed under that license, as well as under the Affero license.

^Word Reference^

The description and example of the %futuro perfecto de subjuntivo% are from a post by user kunvla in the following Word Reference thread: %https://forum.wordreference.com/threads/futuro-compuesto-subjuntivo.1375438/% With respect to reuse of this content, Word Reference states the following: "You are free to quote short passages or definitions from threads in the Forums outside the forums."

^Icons^

Christine Daughtry created the app icon.

Borja Santos Lobo created the dancer icon and released it under the Creative Commons Attribution-Share-Alike License 3.0, available at %https://creativecommons.org/licenses/by-sa/3.0/%.

Saeful Muslim created the bull icon and released it under the Creative Commons Attribution-Share-Alike License 3.0, available at %https://creativecommons.org/licenses/by-sa/3.0/%.

Mariela Peña created the gear and question-mark icons.

^Translation^

Margarita Gracia proofread the translation of Conjugar into Spanish, provided corrections to tense descriptions, and improved several examples of tense usage.

Ferran Poveda provided corrections to the Spanish translations.

^Sound Jay^

Sound Jay (%https://www.soundjay.com%) created all sounds in ~Conjugar~ and graciously "allow[s] ... incorporat[ion of these sounds] into ... projects, be it for commercial or non-commercial use." Sound Jay "and its licensors retain all ownership rights to the sound files".

^Unit Testing^

Dominik Hauser wrote code that inspired a unit-testing technique that ~Conjugar~ uses. Hauser released this code, available at %https://github.com/dasdom/TestingNavigationDemo%, under the MIT License, reproduced above.

^Accented Characters^

Sheila Smith suggested clarifying how to input accented characters like ó.

^Accessibility & Readme^

Bruno Scheele contributed to accessibility and the readme.

^App Preview^

~Conjugar~'s app preview uses the song "Arroz Con Pollo" by Kevin MacLeod (incompetech.com). Attribution follows.

Arroz Con Pollo by Kevin MacLeod
Link: %https://incompetech.filmmusic.io/song/3381-arroz-con-pollo%
License: %http://creativecommons.org/licenses/by/4.0/%
""", comment: ""))
]
}
