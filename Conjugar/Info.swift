//
//  Info.swift
//  Conjugar
//
//  Created by Joshua Adams on 7/1/17.
//  Copyright © 2017 Josh Adams. All rights reserved.
//

import Foundation

struct Info {
  static let infos = ["""
*Purpose & Use*

^Purpose^

In Spanish, conjugation, a concept defined in %Terminology%, is important for the reasons stated there. People raised in Spanish-speaking countries learn conjugation passively, and people who engage in formal Spanish study learn conjugation as part of that study.

But there exists another category of Spanish-learners: people, like the author of ~Conjugar~, who live in non-Spanish-speaking countries, who are currently unable to engage in formal study of Spanish, but who are exposed to Spanish vocabulary by one means or another. Here is an example of the challenge that these learners face.

I knew, from exposure to Spanish in a previous job, that "ir" means "to go" and that "ir" has certain forms starting with "va-". But this knowledge did not allow me to communicate with Spanish-speakers I encountered. For instance, to express the thought "I'm going to the office", I might have said "ir a la oficina" or "va a la oficina". But these sentences were nonsensical to Spanish-speakers because the conjugations were incorrect. The correct (and understandable) sentence is "$voY$ a la oficina".

There are excellent resources for Spanish-verb conjugation. The website ~SpanishDict.com~ and the book ~"Spanish Verbs Made Simple(r)"~ are two of them. I used these resources when I wrote Spanish, but they were unavailable when I spoke Spanish extemporaneously. At some point, I realized that I needed a way to practice conjugating Spanish verbs so that correct conjugations sprang to mind when I was speaking.

This was the genesis of ~Conjugar~, the app you have in your hands. ~Conjugar~ allows you practice conjugating, via quizzes, ~all~ Spanish verb tenses so that correct conjugations are in your brain at the exact moment you need them. ~Conjugar~ gamifies this experience by scoring each practice session and potentially uploading it to Game Center, allowing you to compete against the global Spanish-verb-conjugation community. Some tenses are rare except in archaic or formal texts and are therefore unhelpful for most learners. ~Conjugar~ therefore provides three difficulty levels for practice sessions. ~Easy~ tests the three most important tenses. ~Moderate~ tests all tenses that Spanish-speakers commonly use. ~Difficult~ tests ~all~ tenses, including a few that you are unlikely unless you are reading, for example, ~El ingenioso hidalgo don Quixote de la Mancha~.

^Use^

Navigation in ~Conjugar~ occurs primarily via the tab bar at the bottom of the screen. Descriptions of these tabs follow.

~Conjugar~ starts on the ~Browse~ tab. This tab has three lists of Spanish verbs: a list of many irregular verbs, including all the important ones; a list of many regular verbs; and a list that combines the previous two. Swap these lists by tapping a red button above the tab bar. When you find a verb you would like to know more about, tap it. ~Conjugar~ then displays a screen with ~all~ conjugations of that verb. This screen is helpful for learning because it calls out, by highlighting in red, parts of conjugations that are irregular. For example, the presente de indicativo, first-person singular conjugation of "dar" has an irregular "y", so ~Conjugar~ displays this conjugation as "$voY$". Tap any conjugation to hear it spoken. Tap ~< Browse~ in the top-left corner to return to the ~Browse~ tab.

Tap ~Quiz~ in the tab bar to start a quiz. When you are ready to start, tap ~Start~ on the bottom-left corner of the screen. ~Conjugar~ will then present you a set of fifty Spanish verbs to conjugate. When you are done, ~Conjugar~ will report and score your results, uploading the score to Game Center if it represents a personal best. Tap ~< Quiz~ in the top-left corner to return to the ~Quiz~ tab. You can then start a new quiz.

Tap ~Settings~ in the tab bar to access settings.

One class of conjugations, those of ~vosotros~, is important in Spain but largely absent in Latin America. If your goal is to communicate with Latin-American Spanish-speakers, you may want to have ~Conjugar~ omit ~vosotros~ conjugations from quizzes. If so, tap ~Latin America~ in the ~Region~ section.

In recognition of the added difficulty of learning ~vosotros~ conjugations, ~Conjugar~ assigns higher scores to quizzes that include ~vosotros~ conjugations.

Spanish verb tenses may be roughly grouped into three classes. The first class consists of the bare minimum of tenses you will need to express yourself in Spanish. If your goal is only to express yourself in Spanish, tap ~Easy~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The second class consists of the tenses that native Spanish speakers regularly use in conversation and writing. If your goal is to understand spoken-and-written Spanish, tap ~Moderate~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on these tenses. The third class consists of all the Spanish verb tenses, including a few that are considered archaic or are rarely used except in formal writing. If your goal is to understand archaic-or-formal Spanish texts, tap ~Difficult~ in the ~Difficulty~ section. ~Conjugar~ will quiz you on ~all~ Spanish verb tenses.

In recognition of the relative difficulties of learning to conjugate the ~Easy~, ~Moderate~, and ~Difficult~ classes, ~Conjugar~ assigns higher scores to ~Moderate~ quizzes than to ~Easy~ quizzes and assigns higher scores to ~Difficult~ quizzes than to ~Moderate~ quizzes.

Tap ~Info~ in the tab bar to access information about ~Conjugar~, terminology, and the tenses.
""", """
*Terminology*

A ~verb~ is a kind of word that stands for an action in a sentence. In the sentence, "Celina Zambon is dancing the flamenco," "to dance" is the verb. Verb ~tense~s express, among other things, temporality. In the example sentence, the verb tense expresses that the action is currently taking place. In English, to a limited degree, and in Spanish, to a near-total degree, the ~subject~ or actor in the sentence, combined with the tense, determines the exact form of the verb used. This is the verb ~conjugation~. In English, the example sentence's combination of subject and tense results in the conjugation "is dancing".

A subject ~pronoun~ is a word that stands in for a subject. In English, the subject pronouns are "I", "you, "she/he/it", "we", "y'all", and "they".

In both English and Spanish, subjects have the ~singular~ or ~plural~ number. They are also ~first person~, ~second person~, or ~third person~. English subject pronouns correspond to the following person/number combinations:

first person, singular: ~I~
second person, singular: ~you~
third person, singular: ~he/she/it~
first person, plural: ~we~
second person, plural: ~y'all~
third person, plural: ~they~

The first- and third-person pronouns in Spanish are straightforward:

first person, singular: ~yo~
third person, singular: ~ella~ (feminine)/~él~ (masculine)
first person, plural: ~nosotros~
third person, plural: ~ellas~ (feminine)/~ellos~ (masculine)

The second-person pronouns in Spanish are more complicated in that they encode two informality levels, formal and informal. Further, these pronouns differ in Spain and most of Latin America.

^Spain^

second person, singular, informal: tú
second person, singular, formal: usted
second person, plural, informal: vosotros
second person, plural, formal: ustedes

^Most of Latin America^

second person, singular, informal: tú
second person, singular, formal: usted
second person, plural, informal: ustedes
second person, plural, formal: ustedes

Usted and ustedes use the él and ellos conjugations, respectively.

The difference between the two regions is that "ustedes" has replaced "vosotros" in Latin America. This replacement means that Spanish-learners in Spain must learn conjugations for six person-number combinations, but Spanish-learners in Latin America must learn conjugations for only five.

In parts of Latin America, "vos" has replaced "tú" and uses different conjugations. This phenomenon is called "voseo". Due to developer time constraints, ~Conjugar~ does not attempt to describe voseo in greater detail or quiz the vos conjugations.
"""]
  
  static let infoTitles = ["Info & Use", "Terminology"]
}
