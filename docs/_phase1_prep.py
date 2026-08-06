#!/usr/bin/env python3
"""Phase 1 prep: build blind-input files (infinitive<TAB>rx) per slice so the
blind-gloss agent never sees the current gloss (anti-anchoring)."""
import os, re, glob

HERE = os.path.dirname(os.path.abspath(__file__))
ANNEX = os.path.join(HERE, "annex_b_verb_models.md")
GLOSS_DIR = os.path.join(HERE, "glosses")
OUT_DIR = os.path.join(GLOSS_DIR, "phase1")
os.makedirs(OUT_DIR, exist_ok=True)

ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*([\w-]+)\s*\|\s*(.*?)\s*\|$")
MARKER_RE = re.compile(r"\s*\((se|DEF|1|2)\)")

rx_set = set()
with open(ANNEX, encoding="utf-8") as f:
    for line in f:
        m = ROW_RE.match(line.rstrip("\n"))
        if not m:
            continue
        verb_cell = m.group(2)
        if verb_cell == "Verb":
            continue
        bare = MARKER_RE.sub("", verb_cell).strip()
        if re.search(r"\(se\)", verb_cell):
            rx_set.add(bare)

n_slices = 0
n_verbs = 0
n_rx = 0
for path in sorted(glob.glob(os.path.join(GLOSS_DIR, "slice_*.tsv"))):
    name = os.path.basename(path).replace("slice_", "blind_")
    out = os.path.join(OUT_DIR, name)
    with open(path, encoding="utf-8") as f, open(out, "w", encoding="utf-8") as o:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            inf = line.split("\t")[0].strip()
            rx = "1" if inf in rx_set else "0"
            if rx == "1":
                n_rx += 1
            o.write(f"{inf}\t{rx}\n")
            n_verbs += 1
    n_slices += 1

print(f"rx infinitives in annex: {len(rx_set)}")
print(f"slices: {n_slices}, verbs: {n_verbs}, rx-in-slices: {n_rx}")
print(f"wrote blind inputs to {OUT_DIR}")
