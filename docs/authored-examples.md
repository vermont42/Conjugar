# Authored examples (Claude-original)

The 39 verbs below had **no clean *verbal* use in any open-licensed corpus tier** (literature /
government / technology / medieval). Their surface form collides with a common noun or adjective
(`documentar`↔*documento*, `entrevistar`↔*entrevista*, `regular` the adjective), a homograph of a
different verb (`salgar`↔*salga* of *salir*, `hacendar`↔*haciendo* of *hacer*, `jamar`↔*jamás* the
adverb), or the verb simply does not occur in a finite/infinitive/gerund form anywhere in the
21-text corpus — so corpus mining (pipeline steps C and the step-D tail rescue) could not place
them.

These example sentences are therefore **original, AI-authored content written by Claude (Opus
4.8)** — not sourced from any document. In `ExampleUses.json` each carries `"source": "Claude
(Opus 4.8)"` (and `"line": null`) so its provenance is explicit and queryable; nothing here is
attributed to a corpus source it did not come from. (Conjuguer and Konjugieren handled their
corpus stragglers the same way — see Conjuguer's `docs/authored-examples.md`.)

Each sentence uses the verb in a genuinely **verbal** form (the `Form` column). The nine verbs
marked † did have corpus candidates, but every one was a noun/adjective or a homograph of another
verb (the step-D tail rescue rejected them); the other thirty never appear verbally in the corpus
at all.

| Rank | Verb | Form | Spanish | English |
|---|---|---|---|---|
| 295 | especializar† | especializarse | Tras terminar la carrera, decidió especializarse en cirugía cardiovascular. | After finishing her degree, she decided to specialize in cardiovascular surgery. |
| 392 | regular† | regula | Una ley reciente regula el uso de los drones sobre las ciudades. | A recent law regulates the use of drones over cities. |
| 465 | hacendar† | hacendó | Con lo que ganó en las Indias, se hacendó en un valle fértil cerca de su pueblo natal. | With what he earned in the Indies, he set himself up with an estate in a fertile valley near his native town. |
| 535 | encabezar | encabezaba | El general encabezaba la columna montado en un caballo blanco. | The general led the column mounted on a white horse. |
| 563 | ultimar | ultimaron | Los diplomáticos ultimaron los detalles del tratado en una última sesión nocturna. | The diplomats finalized the details of the treaty in a final late-night session. |
| 596 | equipar | equipó | El ayuntamiento equipó las escuelas con ordenadores y conexión a internet. | The town council equipped the schools with computers and internet access. |
| 602 | protagonizar | protagonizó | La actriz protagonizó la película que se llevó todos los premios aquel año. | The actress starred in the film that swept every award that year. |
| 611 | jamar† | jamó | Llegó del campo muerto de hambre y se jamó medio pan de una sentada. | He came in from the fields starving and wolfed down half a loaf in one sitting. |
| 627 | archivar | archivó | La secretaria archivó los expedientes por orden alfabético antes de cerrar la oficina. | The secretary filed the records in alphabetical order before closing the office. |
| 650 | paginar | paginó | El editor paginó el manuscrito para calcular cuántos pliegos necesitaría la imprenta. | The editor paginated the manuscript to work out how many sheets the press would need. |
| 678 | violar† | violó | Al construir sin licencia, la empresa violó la normativa urbanística del municipio. | By building without a permit, the company violated the town's planning regulations. |
| 708 | acondicionar† | acondicionaron | Antes de la mudanza, los operarios acondicionaron el local para que sirviera de oficina. | Before the move, the workers fitted out the premises so it could serve as an office. |
| 755 | numerar | numeró | El escribano numeró todas las páginas del legajo antes de sellarlo. | The clerk numbered every page of the file before sealing it. |
| 763 | entrevistar | entrevistó | La reportera entrevistó a los supervivientes pocas horas después del rescate. | The reporter interviewed the survivors just hours after the rescue. |
| 780 | comportar | comportaron | Los niños se comportaron ejemplarmente durante toda la ceremonia. | The children behaved impeccably throughout the entire ceremony. |
| 784 | rodrigar | rodriga | En primavera el viñador rodriga las cepas para que los sarmientos no se arrastren por el suelo. | In spring the vine-grower stakes the vines so the shoots do not trail along the ground. |
| 795 | documentar | documentó | El periodista documentó cada denuncia con fotografías y testimonios firmados. | The journalist documented each accusation with photographs and signed testimonies. |
| 807 | donar | donó | Al morir, el coleccionista donó todos sus cuadros al museo de la ciudad. | Upon his death, the collector donated all his paintings to the city museum. |
| 842 | egresar | egresan | Miles de estudiantes egresan cada año de las universidades públicas del país. | Thousands of students graduate each year from the country's public universities. |
| 859 | licenciar† | licenciaron | Al terminar el servicio militar, licenciaron a toda la quinta el mismo día. | When their military service ended, they discharged the entire draft class on the same day. |
| 863 | emocionar | emocionó | El discurso del anciano emocionó hasta las lágrimas a todos los presentes. | The old man's speech moved everyone present to tears. |
| 869 | nominar | nominó | La academia nominó su primera novela a varios premios internacionales. | The academy nominated her first novel for several international awards. |
| 875 | congelar | congelaron | El invierno fue tan crudo que se congelaron las cañerías de toda la casa. | The winter was so harsh that the pipes throughout the house froze. |
| 876 | postular | postuló | El candidato se postuló para el cargo con un programa de reformas ambicioso. | The candidate ran for the office on an ambitious platform of reforms. |
| 900 | debutar | debutó | La joven soprano debutó en el teatro de la ópera con un papel exigente. | The young soprano made her debut at the opera house in a demanding role. |
| 916 | alertar | alertó | El vigía alertó a la aldea en cuanto divisó las velas enemigas en el horizonte. | The lookout alerted the village as soon as he spotted the enemy sails on the horizon. |
| 933 | catalogar† | catalogar | El bibliotecario tardó meses en catalogar los manuscritos recién donados al archivo. | The librarian took months to catalog the manuscripts newly donated to the archive. |
| 934 | medicar | medicó | El veterinario medicó al caballo para aliviarle el dolor de la pata. | The vet medicated the horse to ease the pain in its leg. |
| 947 | lesionar | lesionó | El delantero se lesionó la rodilla en el primer entrenamiento de la temporada. | The forward injured his knee in the first training session of the season. |
| 952 | infectar | infectó | La herida se infectó por no haberla limpiado a tiempo. | The wound became infected because it had not been cleaned in time. |
| 963 | laborar | laboraban | Los campesinos laboraban la tierra de sol a sol sin descanso. | The peasants worked the land from dawn to dusk without rest. |
| 965 | adentrar | adentraron | Los excursionistas se adentraron en el bosque hasta perder de vista el sendero. | The hikers ventured deep into the forest until they lost sight of the trail. |
| 970 | respectar | respecta | Por lo que respecta a los gastos de viaje, la empresa los reembolsará íntegramente. | As regards travel expenses, the company will reimburse them in full. |
| 971 | empatar | empataron | Los dos equipos empataron a un gol en el último minuto del partido. | The two teams tied one goal apiece in the last minute of the match. |
| 974 | visar | visó | El cónsul visó los pasaportes de los emigrantes antes de que embarcaran. | The consul stamped the emigrants' passports before they boarded. |
| 977 | puntualizar | puntualizó | El ministro puntualizó que la medida solo afectaría a las grandes empresas. | The minister clarified that the measure would affect only large companies. |
| 985 | adir | adir | El único heredero decidió adir la herencia pese a las deudas que la gravaban. | The sole heir decided to accept the inheritance despite the debts burdening it. |
| 994 | salgar† | salgaban | Los pastores salgaban las reses en los apriscos para mantenerlas sanas. | The shepherds gave salt to the cattle in the pens to keep them healthy. |
| 999 | seriar | seriar | La fábrica empezó a seriar los motores para abaratar los costes de producción. | The factory began mass-producing the engines to bring down production costs. |

† corpus candidates existed but were all noun/adjective or wrong-verb homographs.
