#!/usr/bin/env python3
"""Strip retrieval cruft from corpus/originals/**/*.txt before indexing.

Removes the boilerplate that confuses mining agents — the stuff "at the start of the document,
on every page, and at the end":

  * Project Gutenberg — keep only the text between the `*** START … ***` and the end marker
    (both the modern `*** END … ***` and the older `End of Project Gutenberg's <title>` form),
    and drop a leading "Produced by …" line.
  * Annotated student editions (e.g. El sombrero de tres picos, PG 29506) — a Spanish body
    wrapped in an English `PREFACE`/`INTRODUCTION` front matter and `NOTES`/`VOCABULARY` back
    matter: keep only the Spanish story.
  * PDF-derived text (form-feed paginated) — drop running headers/footers repeated on most
    pages, standalone page numbers, "Página N", and dotted-leader table-of-contents lines.
  * Cantar de Mio Cid (archive.org OCR) — slice to the poem body (drop Menéndez Pidal's modern
    Introducción), strip the uppercase "CANTAR DEL DESTIERRO/DE LAS BODAS" running page headers,
    the back-of-book "Cantar primero/segundo/tercero" índice, the Internet Archive front matter,
    and the printer's colophon tail.

In place + idempotent. `corpus/originals` is gitignored and re-fetchable (see `fetch_corpus.sh`);
this script is tracked so the transform is reproducible. Run from anywhere:
    python3 corpus/working/clean_corpus.py

Note: separating the medieval *verse* from each edition's modern editorial *introduction/notes*
is a deeper content step (the `grokked/` stage), not retrieval-cruft removal. This script does the
Cid's intro slice because its structure allows it cleanly; Berceo's and the Libro de buen amor's
short editorial intros are left for `grokked/`.
"""
import re
import collections
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
ORIG = ROOT / "corpus" / "originals"

GB_START = re.compile(r'\*\*\*\s*START OF (?:THE|THIS) PROJECT GUTENBERG.*?\*\*\*', re.I)
GB_END = re.compile(r'(?:\*\*\*\s*END OF (?:THE|THIS) PROJECT GUTENBERG.*?\*\*\*|^End of (?:the )?Project Gutenberg.*$)', re.I | re.M)
PRODUCED = re.compile(r'^\s*(Produced by|Transcrib|E-text prepared|Updated editions|Distributed Proofread|\*\*\* )', re.I)

DOTTED = re.compile(r'(?:\.\s?){6,}')                    # TOC leader, contiguous or OCR-spaced dots
PAGE_NUM = re.compile(r'^\s*\d{1,4}\s*$')                 # bare page/stanza number (digits only — spares "vi", "os")
PAGINA = re.compile(r'^\s*(?:P[áa]gina|Page|P[áa]g\.?)\s+\S+\s*$', re.I)

# Annotated-edition section headers (English apparatus wrapping a Spanish body).
ANN_NOTES = re.compile(r'^\s*(?:NOTES|VOCABULARY)\s*$')
ANN_INTRO = re.compile(r'^\s*(?:INTRODUCTION|PREFACE)\s*$')
ROMAN_CHAPTER = re.compile(r'^\s*(?:I{1,3}|IV|VI{0,3}|IX|XI{0,3}|X)\s*$')  # standalone chapter numeral

CID_HEADER = re.compile(r'CANTAR\s+(?:DEL|DE)\s+(?:LAS\s+BODAS|DESTIERRO|LA\s+AFRENTA|CORPES)')  # UPPERCASE running head
CID_INDICE = re.compile(r'^\s*Cantar\s+(?:primero|segundo|tercero)\b', re.I)  # back-of-book table of contents
CID_TAIL = re.compile(r'(ESTE\s+LIBRO\s+SE\s+ACAB|PLEASE\s+DO\s+NOT\s+REMOVE|CARDS\s+OR\s+SLIPS|UNIVERSITY\s+OF\s+TORONTO|TIPOGRAF[IÍ]A)', re.I)
IA_FRONT = re.compile(r'(Digitized\s+by\s+the\s+Internet\s+Archive|archive\.org/details|funding\s+from|EX-?LIBRIS)', re.I)


def collapse(text):
    text = text.replace('﻿', '')
    text = re.sub(r'[ \t]+\n', '\n', text)   # trailing whitespace
    text = re.sub(r'\n{3,}', '\n\n', text)    # >=3 newlines -> paragraph break
    return text.strip() + '\n'


def clean_gutenberg(text):
    m1 = GB_START.search(text)
    if m1:
        text = text[m1.end():]
    m2 = GB_END.search(text)
    if m2:
        text = text[:m2.start()]
    lines = [l for l in text.split('\n') if not PRODUCED.match(l)]

    # Annotated student edition: Spanish body wrapped in English front/back matter. The signature
    # is standalone English NOTES + VOCABULARY back-matter headers (a plain Spanish novel has
    # neither). Keep only the Spanish story between the INTRODUCTION essay and the NOTES section.
    # Use the LAST 'NOTES'/'INTRODUCTION' occurrence, because the edition's own contents page near
    # the top lists "NOTES"/"VOCABULARY"/"INTRODUCTION" — the real sections are the later ones.
    notes_pos = [i for i, l in enumerate(lines) if l.strip() == 'NOTES']
    vocab_pos = [i for i, l in enumerate(lines) if l.strip() == 'VOCABULARY']
    if notes_pos and vocab_pos:
        end = notes_pos[-1]
        intro_pos = [i for i, l in enumerate(lines) if l.strip() in ('INTRODUCTION', 'PREFACE') and i < end]
        start = 0
        if intro_pos:
            start = next((i for i in range(intro_pos[-1] + 1, end) if ROMAN_CHAPTER.match(lines[i])), intro_pos[-1] + 1)
        if end - start > 100:   # sanity guard: never slice a body down to almost nothing
            lines = lines[start:end]
    return '\n'.join(lines)


def clean_paginated(text):
    pages = text.split('\f')
    head, foot = collections.Counter(), collections.Counter()
    for p in pages:
        nb = [l.strip() for l in p.split('\n') if l.strip()]
        for l in nb[:2]:
            head[l] += 1
        for l in nb[-2:]:
            foot[l] += 1
    threshold = max(3, len(pages) * 0.30)
    boiler = {k for k, c in list(head.items()) + list(foot.items()) if c >= threshold and 0 < len(k) <= 80}
    out = []
    for p in pages:
        for line in p.split('\n'):
            s = line.strip()
            if s in boiler or PAGINA.match(line) or PAGE_NUM.match(line) or DOTTED.search(line):
                continue
            out.append(line.rstrip())
    return '\n'.join(out)


def clean_cid(text):
    lines = text.split('\n')
    start = next((i for i, l in enumerate(lines) if CID_HEADER.search(l)), 0)
    out = []
    for l in lines[start:]:
        if CID_TAIL.search(l):
            break
        if CID_HEADER.search(l) or CID_INDICE.match(l) or IA_FRONT.search(l) or PAGE_NUM.match(l):
            continue
        out.append(re.sub(r'[ \t]{2,}', ' ', l).rstrip())   # collapse OCR double-spacing
    return '\n'.join(out)


def main():
    report = []
    for path in sorted(ORIG.rglob('*.txt')):
        raw = path.read_text(encoding='utf-8', errors='replace')
        before = raw.count('\n') + 1
        if GB_START.search(raw):
            kind, cleaned = 'gutenberg', clean_gutenberg(raw)
        elif path.name.startswith('cantar-de-mio-cid'):
            kind, cleaned = 'cid-ocr', clean_cid(raw)
        elif '\f' in raw:
            kind, cleaned = 'paginated', clean_paginated(raw)
        else:
            kind, cleaned = 'plain', raw
        cleaned = collapse(cleaned)
        path.write_text(cleaned, encoding='utf-8')
        after = cleaned.count('\n') + 1
        report.append((str(path.relative_to(ORIG)), kind, before, after))

    w = max(len(r[0]) for r in report)
    print(f"{'file'.ljust(w)}  {'kind':<10} {'lines: before':>13} -> {'after':>7}  removed")
    for name, kind, b, a in report:
        print(f"{name.ljust(w)}  {kind:<10} {b:>13} -> {a:>7}  {b - a:>6}")


if __name__ == '__main__':
    main()
