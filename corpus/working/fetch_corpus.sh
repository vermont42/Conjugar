#!/usr/bin/env bash
# Fetch the example-uses corpus into corpus/originals/ (gitignored, re-fetchable). Run from repo
# root. After fetching, run `python3 corpus/working/clean_corpus.py` to strip retrieval cruft
# (Gutenberg boilerplate, PDF running headers, OCR front matter — see that script's header).
# Provenance + licensing for every source is in docs/example-corpus-sources.md.
#
# Known gaps (not fetched here): Poema de Fernán González (only lending-restricted editions found);
# MX INEGI ENOE + AR INDEC IPC stats PDFs (came down non-extractable) — backfill later.
set -uo pipefail
cd "$(dirname "$0")/../originals" || exit 1
UA="Mozilla/5.0 ConjugarCorpus (language-learning research)"

pg()  { curl -sL --max-time 120 "https://www.gutenberg.org/ebooks/$1.txt.utf-8" -o "$2/$3.txt" && echo "  PG $1 -> $2/$3"; }
pdf() { curl -sL -A "$UA" --max-time 300 "$2" -o "$1/$3.pdf" && pdftotext -enc UTF-8 "$1/$3.pdf" "$1/$3.txt" && echo "  $1/$3 (pdf->txt)"; }

echo "== medieval =="
curl -sL --max-time 120 "https://archive.org/download/poemademiocid00men/poemademiocid00men_djvu.txt" -o medieval/cantar-de-mio-cid-menendezpidal-1913.txt && echo "  Cid (archive.org OCR, Menéndez Pidal 1913)"
pg 16625 medieval libro-de-buen-amor-juan-ruiz-1330
pdf medieval "https://www.bibliotecagonzalodeberceo.com/tesis/milagros.pdf" milagros-berceo

echo "== literature (Project Gutenberg, PD Spanish-original) =="
pg 17013 literature fortunata-y-jacinta-galdos-1887
pg 48818 literature marianela-galdos-1878          # clean Spanish-only Galdós (replaces the annotated Doña Perfecta PG 15725)
pg 17073 literature la-regenta-clarin-1885
pg 18005 literature pazos-de-ulloa-pardo-bazan-1886
pg 17223 literature pepita-jimenez-valera-1874
pg 29506 literature sombrero-tres-picos-alarcon-1874  # annotated ed.; clean_corpus.py slices the Spanish body out of the English apparatus
pg 14944 literature la-barraca-blasco-ibanez-1898
pg  2000 literature quijote-cervantes-1605

echo "== government (PD legal + CC-BY / reuse) =="
pdf government "https://www.boe.es/buscar/pdf/1996/BOE-A-1996-8930-consolidado.pdf" es-trlpi-ley-propiedad-intelectual
pdf government "https://www.ine.es/ine/planine/informe_anual_2024.pdf" es-ine-informe-anual-2024
pdf government "https://www.miteco.gob.es/content/dam/miteco/es/energia/files-1/pniec-2023-2030/PNIEC_2024_240924.pdf" es-miteco-pniec-2023-2030
pdf government "https://cdn.mitma.gob.es/portal-web-drupal/esmovilidad/20211203_Esmovilidad_Completo.pdf" es-mitma-movilidad-2030
pdf government "https://www.dane.gov.co/files/operaciones/GEIH/bol-GEIH-jul2025.pdf" co-dane-geih-jul2025

echo "== technology (digital-policy tier; reuse / CC-BY) =="
pdf technology "https://espanadigital.gob.es/sites/espanadigital/files/2022-07/Espa%C3%B1aDigital_2026.pdf" es-espana-digital-2026
pdf technology "https://www.gob.mx/cms/uploads/attachment/file/678863/Acuerdo_por_el_que_se_expide_la_Estrategia_Digital_Nacional.pdf" mx-estrategia-digital-nacional
pdf technology "https://colaboracion.dnp.gov.co/CDT/Conpes/Econ%C3%B3micos/3975.pdf" co-conpes-3975-transformacion-digital-ia
pdf technology "https://gobiernodigital.mintic.gov.co/692/articles-238514_recurso_1.pdf" co-mintic-gobierno-digital
pdf technology "https://www.boletinoficial.gob.ar/pdf/aviso/primera/195154/20220824" ar-agenda-digital-2022

echo "Done. Now run: python3 corpus/working/clean_corpus.py"
