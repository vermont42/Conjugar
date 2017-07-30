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
    guard let encodedHeading = heading.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { fatalError("Could not URL encode heading \(heading).") }
    self.heading = encodedHeading
    self.difficulty = difficulty
    self.text = text
    infoString = text.infoString
  }
  
  static let infos: [Info] = [
Info(heading: "Purpose & Use", difficulty: .easy, text: """
*Purpose & Use*

^Purpose^

In Spanish, conjugation, a concept defined in %terminology%, is important for the reasons stated there. People raised in Spanish-speaking countries learn conjugation passively, and people who engage in formal Spanish learn conjugation as part of that study.

But there exists another category of Spanish-learners: people, like the developer of ~Conjugar~, who live in non-Spanish-speaking countries, who are currently unable to engage in formal study of Spanish, but who are exposed to Spanish vocabulary by one means or another. Here is an example of the challenge that these learners face.

The developer of ~Conjugar~ knew, from exposure to Spanish in a previous job, that "ir" means "to go" and that "ir" has certain conjugations starting with "va-". But this knowledge did not allow him to communicate with Spanish-speakers he encountered. For instance, to express the thought "I'm going to the office", he might have said "ir a la oficina" or "va a la oficina". But these sentences were nonsensical to Spanish-speakers because the conjugations were incorrect. The correct (and understandable) sentence was (and is) "$voY$ a la oficina".

There are excellent resources for Spanish-verb conjugation. The website ~SpanishDict.com~ and the book ~"Spanish Verbs Made Simple(r)"~ are two of them. The developer of ~Conjugar~ used these resources when he wrote Spanish, but they were unavailable when he spoke Spanish extemporaneously. At some point, he realized that he needed a way to practice conjugating Spanish verbs so that correct conjugations sprang to mind when he was speaking.

This was the genesis of ~Conjugar~, the app whose majesty now envelops you. ~Conjugar~ allows you practice conjugating, via quizzes, ~all~ Spanish verb tenses so that correct conjugations are in your brain at the exact moment you need them. ~Conjugar~ gamifies this experience by scoring each practice session and potentially uploading it to Game Center, allowing you to compete against the global Spanish-verb-conjugation community. Some tenses are rare except in archaic or formal texts and are less useful for many learners. ~Conjugar~ therefore provides three difficulty levels for practice sessions. ~Easy~ tests the three most important tenses. ~Moderate~ tests all tenses that Spanish-speakers commonly use. ~Difficult~ tests ~all~ tenses, including a few that you are unlikely to encounter unless you are reading, for example, ~El ingenioso hidalgo don Quixote de la Mancha~.

^Use^

Primary navigation in ~Conjugar~ occurs via the tab bar at the bottom of the screen. Descriptions of these tabs follow.

~Conjugar~ starts on the ~Browse~ tab. This tab has three lists of Spanish verbs: a list of many irregular verbs, a list of many regular verbs, and a list that combines the other two. Swap these lists by tapping a red button above the tab bar. When you find a verb you would like to know more about, tap it. ~Conjugar~ then displays a screen with ~all~ conjugations of that verb. This screen is helpful for learning because it calls out, by highlighting in $RED$, parts of conjugations that are irregular. For example, the presente de indicativo, first-person singular conjugation of "dar" has an irregular "y", so ~Conjugar~ displays this conjugation as "$doY$". Tap any conjugation to hear it spoken. Tap ~Browse~ in the top-left corner to return to the ~Browse~ tab.

Tap ~Quiz~ in the tab bar to start a quiz. Tap ~Start~ on the bottom-left corner of the screen. ~Conjugar~ will then present you a set of fifty Spanish verbs to conjugate. When you are done, ~Conjugar~ will report and score your results, uploading the score to Game Center if it represents a personal best. Tap ~Quiz~ in the top-left corner to return to the ~Quiz~ tab. You can then start a new quiz.

Tap ~Settings~ in the tab bar to access settings.

One class of conjugations, those of ~vosotros~, is important in Spain but largely absent in Latin America. If your goal is to communicate with Latin-American Spanish-speakers, you may want to have ~Conjugar~ omit ~vosotros~ conjugations from quizzes. If so, tap ~Latin America~ in the ~Region~ section.

In recognition of the added difficulty of learning ~vosotros~ conjugations, ~Conjugar~ assigns higher scores to quizzes that include these conjugations.

Spanish verb tenses may be roughly grouped into three classes. The first class consists of the bare minimum of tenses you will need to express yourself in Spanish. If your goal is only to express yourself in Spanish, tap ~Easy~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The second class consists of the tenses that native Spanish speakers regularly use in conversation and writing. If your goal is to understand spoken-and-written Spanish, tap ~Moderate~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The third class consists of all the Spanish verb tenses, including a few that are considered archaic or are rarely used except in formal writing. If your goal is to understand archaic-or-formal Spanish texts, tap ~Difficult~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on ~all~ Spanish verb tenses.

In recognition of the relative difficulties of learning to conjugate the ~Easy~, ~Moderate~, and ~Difficult~ classes of verbs, ~Conjugar~ assigns higher scores to ~Moderate~ quizzes than to ~Easy~ quizzes and assigns higher scores to ~Difficult~ quizzes than to ~Moderate~ quizzes.

Tap ~Info~ in the tab bar to access information about ~Conjugar~, %terminology%, and the tenses.
"""),
Info(heading: "Terminology", difficulty: .easy, text: """
*Terminology*

^Verb^

A ~verb~ is a kind of word that stands for an action in a sentence. In the sentence "Celina Zambon is dancing the flamenco", "to dance" is the verb. Verb ~tense~s express, among other things, temporality. In the example sentence, the verb tense expresses that the action is currently taking place. In English, to a limited degree, and in Spanish, to a near-total degree, the ~subject~ or actor in the sentence, combined with the tense, determines the exact form of the verb used. This is the verb ~conjugation~. In English, the example sentence's combination of subject and tense results in the conjugation "is dancing".

The ~un~conjugated form of a Spanish verb is the ~infinitivo~. All infinitivos end in -ar, -ir, or -er. "Bailar" is an infinitivo that means "to dance". Spanish dictionaries and ~Conjugar~'s Browse tab list the infinitivo forms of verbs.

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

"Fem." means that a pronoun refers to female subjects, and "masc" means that a pronoun refers to male subjects.

The second-person subject pronouns in Spanish are more complicated in that they encode two formality levels, formal and informal. Further, uses of these pronouns differ in Spain and Latin America.

~Spain~

second person, singular, informal: ~tú~
second person, singular, formal: ~usted~
second person, plural, informal: ~vosotros~ (masc.)/~vosotras~ (fem.)
second person, plural, formal: ~ustedes~

~Most of Latin America~

second person, singular, informal: ~tú~
second person, singular, formal: ~usted~
second person, plural, informal: ~ustedes~
second person, plural, formal: ~ustedes~

Usted and ustedes use the él and ellos conjugations, respectively.

The difference between the two regions is that ~ustedes~ has replaced ~vosotros~/~vosotras~ in Latin America. This replacement means that Spanish-learners in Spain must learn conjugations for six person-number combinations, but Spanish-learners in Latin America must learn conjugations for only five.

In parts of Latin America, ~vos~ has replaced ~tú~ and uses different conjugations. This phenomenon is called "voseo". Due to developer time constraints, ~Conjugar~ does not attempt to describe voseo in greater detail or quiz the ~vos~ conjugations.

^Order and Presentation of Conjugations^

Treatises on Spanish verbs, when presenting the conjugations for a particular tense, present the conjugations in the following subject-pronoun order: yo, tú, él, nosotros, vosotros, ellos. In the interests of clarity and brevity, ~Conjugar~ does the same. For example, ~Conjugar~ would present the %presente de indicativo% conjugations of ~ser~ as follows:

$soY$, $ERes$, $ES$, $sOmos$, $sOis$, $sOn$

Red letters in conjugations represent irregularities. A verb is considered irregular if any of its conjugations differs from the conjugation of a regular ~ar~, ~ir~, or ~er~ verb.
"""),
Info(heading: "Presente de Indicativo", difficulty: .easy, text: """
*Presente de Indicativo*

^Uses^

The ~presente de indicativo~ is a Spanish verb tense that is used to express the following:

• Present action:

"Malteamos." = "We are malting."

• Habitual action:

"Malteamos." = "We have a habit of malting." or "We malt."

• Emphasis on present action:

"Sí, malteamos." = "Yes, we ~do~ malt."

^Conjugation^

Regular AR, IR, and ER verbs are conjugated in the presente de indicativo by adding the following endings to the verb stem:

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
"""),
Info(heading: "Futuro de Indicativo", difficulty: .easy, text: """
*Futuro de Indicativo*

^Uses^

The ~futuro de indicativo~ is a Spanish Verb tense that is used to express the following:

• A future action:

"El año próximo, visitaré Buenos Aires." = "Next year, I shall/will visit Buenos Aires."

• Uncertainty or probability - inference, rather than direct knowledge

"¿Quién estará tocando a la puerta?" "Será Fabio." = "Who (do you suppose) is knocking at the door?" "It must be Fabio." or "Who will that be knocking at the door?" "That'll be Fabio."

• Command, prohibition, or obligation:

"No llevarás a ese hombre a mi casa." = "Do not bring that man to my house." or, more accurately, "You will not bring that man to my house."

This form is also used to assert a command, prohibition, or obligation in English.

• Courtesy:

"¿Te importará encender la televisión?" = "Would you mind turning on the television?"

Another common way to represent the future is with a %presente de indicativo% conjugation of ~ir~ followed by an Infinitivo verb: "Quizás $VOY$ a viajar a Bolivia en el verano. = "Perhaps I'm going to travel to Bolivia in the summer."

^Conjugation^

The Futuro de Indicativo uses the %raíz futura% as a stem. The following endings are attached to it:

-é, -ás, -á, -emos, -éis, -án

Example: hablaré, hablarás, hablará, hablaremos, hablaréis, hablarán

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Pretérito", difficulty: .easy, text: """
*Pretérito*

^Uses^

The ~pretérito~ is a Spanish verb tense that is used to express the following:

• An action that was done in the past

"Ayer, encontré la flor que tú me $dIste$." = "Yesterday, I found the flower that you gave me."

This use expresses an action that is viewed as a completed event. It is often accompanied by adverbial expressions of time, such as "ayer", "anteayer", or "la semana pasada".

• An action that interrupts another action

"Tomábamos la cena cuando entró Eduardo." = "We were having dinner when Eduardo came in."

This expresses an event that happened (and was completed) while another action was taking place.

• A general truth

"Las Filipinas $FUeron$ parte del Imperio Español." = "The Philippines were part of the Spanish Empire."

This expresses a past relationship that is viewed as finished.

^Conjugation^

Regular AR, IR, and ER verbs are conjugated in the pretérito by adding the following endings to the verb stem:

AR: -é, -aste, -ó, -amos, -astéis, -aron
IR: -í, -iste, -ió, -imos, -isteis, -ieron
ER: -í, -iste, -ió, -imos, -isteis, -ieron

Examples:

habl~ar~: hablé, hablaste, habló, hablamos, hablastéis, hablaron
sub~ir~: subí, subiste, subió, subimos, subisteis, subieron
com~er~: comí, comiste, comió, comimos, comisteis, comieron

Some verbs that are irregular in the pretérito appear below. Tap the ~Browse~ tab for translations and conjugations.

andar, caber, conducir, dar, decir, estar, haber, hacer, ir, poder, poner, querer, sabar, ser, tener, traer, venir

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Condicional", difficulty: .moderate, text: """
*Condicional*

^Uses^

The ~condicional~ is used to express the following:

• Courtesy:

"Señor, ¿$podRía$ darme una copa de vino?" = "Sir, could you give me a glass of wine?"

This use softens a request, making it more polite.

• Polite expression, using querrer, of a desire:

"Q$ueRría$ ver la película esta semana." = "I would like to see the film this week."

• In a then clause whose realization depends on a hypothetical if clause:

"Si yo $FUera$ rico, viajaría a Sudamérica." = "If I were rich, (then) I would travel to South America."

• Speculation about past events:

"¿Cuantas personas asistieron a la inauguración del Presidente?" "No lo $sÉ$; $habRía$ unas 5.000." = "How many people attended the President's inauguration?" "I do not know; there must have been about 5,000."

In this context, the speaker's knowledge is indirect, unconfirmed, or approximate.

• A future action in relation to the past:

"Cuando $ERa$ pequeño, pensaba que me gustaría ser médico." = "When I was young, I thought that I would like to be a doctor."

This use expresses future action that was imagined in the past.

• A suggestion:

"Yo que tú, lo olvidaría completamente." = "If I were you, I would forget him completely."

^Conjugation^

Like the %futuro de indicativo%, the condicional uses the %raíz futura% as a stem. To form the condicional, the following endings are attached to the raíz futura:

-ía, -ías, -ía, -íamos, -íais, -ían

Example: hablaría, hablarías, hablaría, hablaríamos, hablaríais, hablarían

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Imperfecto de Indicativo", difficulty: .moderate, text: """
*Imperfecto de Indicativo*

^Uses^

Like the %pretérito% and %perfecto de indicativo%, the ~imperfecto de indicativo~ is used for past events. But the imperfecto de indicativo is used for:

• A habitual or repeated action:

"Cada año mi familia $iBa$ a Puerto Rico." = "Each year my family went to Rich Port."

"Frecuentemente el gato saltaba al sofá." = "The cat often jumped on the couch."

• A "used to" action:

"Yo leía el diário." = "~I~ used to read the newspaper."

• A background event during which another event in the same sentence occurred:

"Mientras cruzaba la calle, me atropelló un coche." = "While I was crossing the road, a car ran over me."

^Conjugation^

Regular AR, IR, and ER verbs are conjugated in the imperfecto de indicativo by adding the following endings to the verb stem:

AR: -aba, -abas, -aba, -ábamos, -abais, -aban
IR: -ía, -ías, -ía, -íamos, -íais, -ían
ER: -ía, -ías, -ía, -íamos, -íais, -ían

Examples:

habl~ar~: hablaba, hablabas, hablaba, hablábamos, hablabais, hablaban
sub~ir~: subía, subías, subía, subíamos, subíais, subían
com~er~: comía, comías, comía, comíamos, comíais, comían

Only three verbs are irregular in the imperfecto de indicativo: ir, ser, and ver. Tap the ~Browse~ tab for translations and conjugations.

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Presente de Subjuntivo", difficulty: .moderate, text: """
*Presente de Subjuntivo*

^Uses^

The ~presente de subjuntivo~ is used to express:

• A command:

"Nos manda que $platiQUemos$." = "He is ordering us to talk."

• Emotional state:

"Temo que Colombia no gane la Copa América este año." = "I fear that Colombia will not win the America Cup this year."

• Doubt:

"Dudo que $venGas$ mañana." = "I doubt that thou wilt come tomorrow."

^Conjugation^

Regular AR, IR, and ER verbs are conjugated in the presente de subjuntivo by adding the following endings to the verb stem:

AR: -e, -es, -e, -emos, -éis, -en
IR: -a, -as, -a, -amos, -áis, -an
ER: -a, -as, -a, -amos, -áis, -an

Examples:

habl~ar~: hable, hables, hable, hablemos, habléis, hablen
sub~ir~: suba, subas, suba, subamos, subáis, suban
com~er~: coma, comas, coma, comamos, comáis, coman

Some verbs that are irregular in the presente de subjuntivo appear below. Tap the ~Browse~ tab for translations and conjugations.

caber, caer, conducir, conocer, construir, crecer, dar, decir, dormir, estar, ir, haber, hacer, huir, jugar, lucir, oír, pedir, pensar, perder, poner, saber, sentir, ser, salir, tener, traer, valer, venir, ver
"""),
Info(heading: "Imperfecto de Subjuntivo 1", difficulty: .difficult, text: """
*Imperfecto de Subjuntivo 1*

^Use^

^Conjugation^

"""),
Info(heading: "Imperfecto de Subjuntivo 2", difficulty: .difficult, text: """
*Imperfecto de Subjuntivo 2*

^Use^

^Conjugation^

"""),
Info(heading: "Futuro de Subjuntivo", difficulty: .difficult, text: """
*Futuro de Subjuntivo*

^Use^

^Conjugation^

"""),
Info(heading: "Imperativo Positivo", difficulty: .moderate, text: """
*Imperativo Positivo*

^Use^

The ~imperativo positivo~ is used in Spanish to express commands.

"Levanten la mana derecha." = "Raise your right hand."

"Regresad." = "Y'all come back."

"Lo $dI$." = "Say it."

"Tejamos." = "Let's knit."

^Conjugation^

For conjugation of the imperativo positivo, nosotros, usted, and ustedes use the %presente de subjuntivo% conjugation. Tú uses the %presente de indicativo% conjugation minus the final s. Vosotros uses the infinitivo minus the final r, plus d.

Thus, for regular AR, IR, and ER verbs, the endings are as follows. Note that there are no yo forms.

AR: -a, -e, -emos, -ad, -en
IR: -e, -a, -amos, -id, -an
ER: -e, -a, -amos, -ed, -an

Examples:

habl~ar~: habla, hable, hablemos, hablad, hablen
sub~ir~: sube, suba, subamos, subid, suban
com~er~: come, coma, comamos, comed, coman

The following verbs have irregular tú imperativo positivo conjugations:

componer: $compÓn$
decir: $dI$
haber: $hE$
hacer: $haZ$
ir: $VE$
obtener: $obtÉn$
ponder: $poN$
salir: $saL$
ser: $sÉ$
tener: $teN$
venir: $veN$
"""),
Info(heading: "Imperativo Negativo", difficulty: .moderate, text: """
*Imperativo Negativo*

^Use^

The ~imperativo negativo~ is used in Spanish to express negative commands.

"No levanten la mana derecha." = "Don't raise your right hand."

"No regreséis." = "Don't come back, y'all."

"No lo $dIGa$." = "Don't say it."

"No tejamos." = "Let's not knit."

^Conjugation^

For conjugation of the imperativo negativo, the word "no" is prepended to the %presente de subjuntivo% conjugation. Thus, for regular AR, IR, and ER verbs, the endings are as follows. Note that there are no yo forms.

AR: -e, -es, -e, -emos, -éis, -en
IR: -a, -as, -a, -amos, -áis, -an
ER: -a, -as, -a, -amos, -áis, -an

Examples:

habl~ar~: no hables, no hable, no hablemos, no habléis, no hablen
sub~ir~: no subas, no suba, no subamos, no subaís, no suban
com~er~: no comas, no coma, no comamos, no comáis, no coman
"""),
Info(heading: "Participio", difficulty: .moderate, text: """
*Participio*

^Use^

The ~participio~ corresponds to the English -en or -ed form of a verb. This form is used following the auxiliary verb ~haber~ to form various compound tenses, including the %perfecto de indicativo%: "(Yo) $hE$ hablado." = "I have spoken."

^Form^

The participio is formed by adding the following endings to the verb stem:

-ar verbs: ~-ado~

Examples: hablado ("spoken"); cantado ("sung"); bailado ("danced")

-er verbs: ~-ido~

Examples: bebido ("drunk"); leído (requires accent mark; "read"); comprendido ("understood")

-ir verbs,: ~-ido~

Examples: vivido ("lived"); sentido ("felt"); hervido ("boiled")

When the participio is used as an adjective, it inflects for both gender and number. Example: "una lengua hablada en España" = "a language spoken in Spain"

The following verbs have irregular participios:

abrir: $abIERTo$
cubrir: $cubIERTo$
decir: $dICHo$
escribir: $esciTo$
hacer: $hECHo$
morir: $mUERTo$
poner: $pUESTo$
pudrir: $pOdrido$
resolver: $resUELTo$
romper: $roTo$
ver: $vISTo$
volver: $vUElvo$

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Gerundio", difficulty: .moderate, text: """
*Gerundio*

^Uses^

The ~gerundio~ has a variety of uses. The gerundio of hacer, haciendo, can mean "doing", "while doing", "by doing", "because of one's doing", or "through doing".

The gerundio is also used to form progressive constructions, such as "$estoY haciendo$" ("I am doing").

The gerundio cannot be used as an adjective and, unlike in most European languages, generally has no corresponding adjectival forms. The archaic participio presente, which ended in -ante or -iente and formerly filled this function, in some cases survives as an adjective. For example, "durmiente" = "sleeping", and "interesante" = "interesting". But such cases are limited. Usually, alternate constructions are appropriate. Whereas in English one would say "the crying baby", one would say in Spanish "el bebé que llora", which literally means "the baby who is crying".

^Form^

The gerundio is formed by adding the following endings to the verb stem:

-ar verbs: ~-ando~

Examples: hablando ("speaking"); cantando ("singing"); bailando ("dancing")

-er verbs: ~-iendo~

Examples: bebiendo ("drinking"); cediendo ("transferring"); comprendiendo ("understanding")

-ir verbs,: ~-iendo~

Examples: viviendo ("living"); decidiendo ("deciding"); herviendo ("boiling")

The following verbs have irregular gerundios:

bullir: $bullEndo$
caer: $caYendo$
construir: $construYendo$
dormir: $dUrmiendo$
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
"""),
Info(heading: "Raíz Futura", difficulty: .easy, text: """
*Raíz Futura*

^Uses^

The ~raíz futura~ forms of verbs are used to form the %condicional% and %futuro de indicativo% tenses. Tap those tenses for descriptions of them.

^Form^

For all but twelve verbs, the raíz futura is identical to the infinitivo. For example, the raíz futura form of ~bailar~ is "bailar".

The following verbs have irregular raíz futura forms:

caber: $cabR$
decir: $dIR$
haber: $habR$
hacer: $haR$
poder: $podR$
poner: $ponDr$
querer: $querR$
saber: $sabR$
salir: $salDr$
tener: $tenDr$
valer: $valDr$
venir: $venDr$
"""),
Info(heading: "Perfecto de Indicativo", difficulty: .moderate, text: """
*Perfecto de Indicativo*

^Uses^

The ~perfecto de indicativo~ has virtually the same use as the tense sometimes called, in English, the present perfect.

"Te $hE dICHo$ mi opinión." = "I have told you my opinion." or "I told you my opinion, and it hasn't changed."

In Spanish, as in English, this tense implies that an action, although completed in the past, has continuing effects, truth, or relevance in the present.

In most of Spain, the tense has an additional use: to express a past action or event that is contained in an unfinished period of time in the present.

"Este mes ha llovido mucho, pero hoy hace buen día." = "It rained a lot this month, but today is a fine day."

^Conjugation^

In the perfecto de indicativo, the %presente de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $hEmos hablado$

See %credits% for Wikipedia attribution.
"""),
Info(heading: "Pretérito Anterior", difficulty: .difficult, text: """
*Pretérito Anterior*

^Use^

^Conjugation^

In the pretérito anterior, the %pretérito% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $hUBE hablado$
"""),
Info(heading: "Pluscuamperfecto de Indicativo", difficulty: .difficult, text: """
*Pluscuamperfecto de Indicativo*

^Use^

^Conjugation^

In the pluscuamperfecto de indicativo, the %imperfecto de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $había hablado$
"""),
Info(heading: "Futuro Perfecto", difficulty: .difficult, text: """
*Futuro Perfecto*

^Use^

^Conjugation^

In the futuro perfecto, the %futuro de indicativo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $habRé hablado$
"""),
Info(heading: "Condicional Compuesto", difficulty: .difficult, text: """
*Condicional Compuesto*

^Use^

^Conjugation^

In the condicional compuesto, the %condicional% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $habRía hablado$
"""),
Info(heading: "Perfecto de Subjuntivo", difficulty: .difficult, text: """
*Perfecto de Subjuntivo*

^Use^

^Conjugation^

In the perfecto de subjuntivo, the %presente de subjuntivo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $haYa hablado$
"""),
Info(heading: "Pluscuamperfecto de Subjuntivo 1", difficulty: .difficult, text: """
*Pluscuamperfecto de Subjuntivo 1*

^Use^

^Conjugation^

In the pluscuamperfecto de subjuntivo 1, the %imperfecto de subjuntivo 1% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $hUbiera hablado$
"""),
Info(heading: "Pluscuamperfecto de Subjuntivo 2", difficulty: .difficult, text: """
*Pluscuamperfecto de Subjuntivo 2*

^Use^

^Conjugation^

In the pluscuamperfecto de indicativo 2, the %imperfecto de subjuntivo 2% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $hUbiese hablado$
"""),
Info(heading: "Futuro Perfecto de Subjuntivo", difficulty: .difficult, text: """
*Futuro Perfecto de Subjuntivo*

^Use^

^Conjugation^

In the futuro perfecto de subjuntivo, the %futuro de subjuntivo% conjugation of ~haber~ is used as an auxiliary, and it is followed by the %participio% of the verb to be conjugated.

Example: $hUbiere hablado$
"""),
Info(heading: "Credits", difficulty: .easy, text: """
*Credits*

^MIT License^

~Conjugar~'s source code is licensed under the MIT license, reproduced here:

Copyright 2017 Josh Adams

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

^Wikipedia^

Descriptions of the %pretérito%, %futuro de indicativo%, %condicional%, %participio%, %gerundio%, %imperfecto de indicativo%, and %perfecto de indicativo% have been borrowed, in part, from Wikipedia's article on Spanish verbs, %https://en.wikipedia.org/wiki/Spanish_verbs%. Modifications to Wikipedia's content include, but are not entirely limited to, formatting and the addition of example irregular verbs. In a case of one hand washing the other, ~Conjugar~'s developer has corrected the Wikipedia article's description of the %gerundio%, which stated, as of July 8, 2017, that only one verb has an irregular %gerundio%. Wikipedia has licensed the content of the Spanish-verb article under the Creative Commons Attribution-Share-Alike License 3.0, available at %https://creativecommons.org/licenses/by-sa/3.0/%. All of ~Conjugar~'s developer's modifications of Wikipedia content are licensed under that license, as well as under the MIT license.
""")]
}
