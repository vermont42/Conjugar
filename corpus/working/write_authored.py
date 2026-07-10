#!/usr/bin/env python3
"""Emit corpus/working/mined_authored.json — the Claude-authored residue (pipeline step D).

These 39 ranked verbs have NO clean *verbal* use in any open-licensed corpus tier: their surface
form collides with a common noun/adjective (*documento*, *entrevista*, *regular*), a homograph of a
different verb (*salga*→salir, *haciendo*→hacer, *jamás*→adverb), or the verb simply does not occur
finitely in the 21-text corpus. Each sentence below is therefore ORIGINAL, AI-authored content by
Claude (Opus 4.8) — not sourced from any document — and carries `source = "Claude (Opus 4.8)"`,
`line = null`, so its provenance is explicit and never attributed to a corpus. Every sentence uses
the verb in a genuinely VERBAL form (the `token`). Documented in docs/authored-examples.md.

The schema matches the mined_*.json shards so build_examples.py's aggregate_modern globs it in.
"""
import json
import os

AUTHOR = "Claude (Opus 4.8)"

# verb: (token, es, en)
ENTRIES = {
    "acondicionar": ("acondicionaron",
        "Antes de la mudanza, los operarios acondicionaron el local para que sirviera de oficina.",
        "Before the move, the workers fitted out the premises so it could serve as an office."),
    "adentrar": ("adentraron",
        "Los excursionistas se adentraron en el bosque hasta perder de vista el sendero.",
        "The hikers ventured deep into the forest until they lost sight of the trail."),
    "adir": ("adir",
        "El único heredero decidió adir la herencia pese a las deudas que la gravaban.",
        "The sole heir decided to accept the inheritance despite the debts burdening it."),
    "alertar": ("alertó",
        "El vigía alertó a la aldea en cuanto divisó las velas enemigas en el horizonte.",
        "The lookout alerted the village as soon as he spotted the enemy sails on the horizon."),
    "archivar": ("archivó",
        "La secretaria archivó los expedientes por orden alfabético antes de cerrar la oficina.",
        "The secretary filed the records in alphabetical order before closing the office."),
    "catalogar": ("catalogar",
        "El bibliotecario tardó meses en catalogar los manuscritos recién donados al archivo.",
        "The librarian took months to catalog the manuscripts newly donated to the archive."),
    "comportar": ("comportaron",
        "Los niños se comportaron ejemplarmente durante toda la ceremonia.",
        "The children behaved impeccably throughout the entire ceremony."),
    "congelar": ("congelaron",
        "El invierno fue tan crudo que se congelaron las cañerías de toda la casa.",
        "The winter was so harsh that the pipes throughout the house froze."),
    "debutar": ("debutó",
        "La joven soprano debutó en el teatro de la ópera con un papel exigente.",
        "The young soprano made her debut at the opera house in a demanding role."),
    "documentar": ("documentó",
        "El periodista documentó cada denuncia con fotografías y testimonios firmados.",
        "The journalist documented each accusation with photographs and signed testimonies."),
    "donar": ("donó",
        "Al morir, el coleccionista donó todos sus cuadros al museo de la ciudad.",
        "Upon his death, the collector donated all his paintings to the city museum."),
    "egresar": ("egresan",
        "Miles de estudiantes egresan cada año de las universidades públicas del país.",
        "Thousands of students graduate each year from the country's public universities."),
    "emocionar": ("emocionó",
        "El discurso del anciano emocionó hasta las lágrimas a todos los presentes.",
        "The old man's speech moved everyone present to tears."),
    "empatar": ("empataron",
        "Los dos equipos empataron a un gol en el último minuto del partido.",
        "The two teams tied one goal apiece in the last minute of the match."),
    "encabezar": ("encabezaba",
        "El general encabezaba la columna montado en un caballo blanco.",
        "The general led the column mounted on a white horse."),
    "entrevistar": ("entrevistó",
        "La reportera entrevistó a los supervivientes pocas horas después del rescate.",
        "The reporter interviewed the survivors just hours after the rescue."),
    "equipar": ("equipó",
        "El ayuntamiento equipó las escuelas con ordenadores y conexión a internet.",
        "The town council equipped the schools with computers and internet access."),
    "especializar": ("especializarse",
        "Tras terminar la carrera, decidió especializarse en cirugía cardiovascular.",
        "After finishing her degree, she decided to specialize in cardiovascular surgery."),
    "hacendar": ("hacendó",
        "Con lo que ganó en las Indias, se hacendó en un valle fértil cerca de su pueblo natal.",
        "With what he earned in the Indies, he set himself up with an estate in a fertile valley near his native town."),
    "infectar": ("infectó",
        "La herida se infectó por no haberla limpiado a tiempo.",
        "The wound became infected because it had not been cleaned in time."),
    "jamar": ("jamó",
        "Llegó del campo muerto de hambre y se jamó medio pan de una sentada.",
        "He came in from the fields starving and wolfed down half a loaf in one sitting."),
    "laborar": ("laboraban",
        "Los campesinos laboraban la tierra de sol a sol sin descanso.",
        "The peasants worked the land from dawn to dusk without rest."),
    "lesionar": ("lesionó",
        "El delantero se lesionó la rodilla en el primer entrenamiento de la temporada.",
        "The forward injured his knee in the first training session of the season."),
    "licenciar": ("licenciaron",
        "Al terminar el servicio militar, licenciaron a toda la quinta el mismo día.",
        "When their military service ended, they discharged the entire draft class on the same day."),
    "medicar": ("medicó",
        "El veterinario medicó al caballo para aliviarle el dolor de la pata.",
        "The vet medicated the horse to ease the pain in its leg."),
    "nominar": ("nominó",
        "La academia nominó su primera novela a varios premios internacionales.",
        "The academy nominated her first novel for several international awards."),
    "numerar": ("numeró",
        "El escribano numeró todas las páginas del legajo antes de sellarlo.",
        "The clerk numbered every page of the file before sealing it."),
    "paginar": ("paginó",
        "El editor paginó el manuscrito para calcular cuántos pliegos necesitaría la imprenta.",
        "The editor paginated the manuscript to work out how many sheets the press would need."),
    "postular": ("postuló",
        "El candidato se postuló para el cargo con un programa de reformas ambicioso.",
        "The candidate ran for the office on an ambitious platform of reforms."),
    "protagonizar": ("protagonizó",
        "La actriz protagonizó la película que se llevó todos los premios aquel año.",
        "The actress starred in the film that swept every award that year."),
    "puntualizar": ("puntualizó",
        "El ministro puntualizó que la medida solo afectaría a las grandes empresas.",
        "The minister clarified that the measure would affect only large companies."),
    "regular": ("regula",
        "Una ley reciente regula el uso de los drones sobre las ciudades.",
        "A recent law regulates the use of drones over cities."),
    "respectar": ("respecta",
        "Por lo que respecta a los gastos de viaje, la empresa los reembolsará íntegramente.",
        "As regards travel expenses, the company will reimburse them in full."),
    "rodrigar": ("rodriga",
        "En primavera el viñador rodriga las cepas para que los sarmientos no se arrastren por el suelo.",
        "In spring the vine-grower stakes the vines so the shoots do not trail along the ground."),
    "salgar": ("salgaban",
        "Los pastores salgaban las reses en los apriscos para mantenerlas sanas.",
        "The shepherds gave salt to the cattle in the pens to keep them healthy."),
    "seriar": ("seriar",
        "La fábrica empezó a seriar los motores para abaratar los costes de producción.",
        "The factory began mass-producing the engines to bring down production costs."),
    "ultimar": ("ultimaron",
        "Los diplomáticos ultimaron los detalles del tratado en una última sesión nocturna.",
        "The diplomats finalized the details of the treaty in a final late-night session."),
    "violar": ("violó",
        "Al construir sin licencia, la empresa violó la normativa urbanística del municipio.",
        "By building without a permit, the company violated the town's planning regulations."),
    "visar": ("visó",
        "El cónsul visó los pasaportes de los emigrantes antes de que embarcaran.",
        "The consul stamped the emigrants' passports before they boarded."),
}


def main():
    out = {}
    for verb, (token, es, en) in ENTRIES.items():
        for field, val in (("es", es), ("en", en)):
            assert '"' not in val, f"{verb}: ASCII quote in {field}"
        assert token in es, f"{verb}: token {token!r} not in es sentence"
        out[verb] = {"es": es, "en": en, "source": AUTHOR, "line": None, "token": token}
    out = dict(sorted(out.items()))
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "mined_authored.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=1)
    print(f"wrote {len(out)} authored entries -> {os.path.relpath(path)}")


if __name__ == "__main__":
    main()
