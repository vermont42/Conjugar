#!/usr/bin/env python3
"""Split the 549-verb Phase 2 candidate set into chunk files for the
3-checker adversarial workflow."""
import os, math

HERE = os.path.dirname(os.path.abspath(__file__))
P1 = os.path.join(HERE, "phase1")
SRC = os.path.join(P1, "phase2_candidates.tsv")
OUT = os.path.join(P1, "phase2")
os.makedirs(os.path.join(OUT, "chunks"), exist_ok=True)

with open(SRC, encoding="utf-8") as f:
    lines = f.read().splitlines()
header, rows = lines[0], [l for l in lines[1:] if l.strip()]

CHUNK = 16
n = math.ceil(len(rows) / CHUNK)
for i in range(n):
    part = rows[i*CHUNK:(i+1)*CHUNK]
    p = os.path.join(OUT, "chunks", f"chunk_{i:02d}.tsv")
    with open(p, "w", encoding="utf-8") as o:
        o.write(header + "\n")
        o.write("\n".join(part) + "\n")
print(f"{len(rows)} verbs -> {n} chunks of <= {CHUNK} (chunk_00..chunk_{n-1:02d})")
print(f"chunk dir: {os.path.join(OUT,'chunks')}")
