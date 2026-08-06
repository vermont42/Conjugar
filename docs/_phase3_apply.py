#!/usr/bin/env python3
"""Phase 3 apply: rewrite slice_*.tsv from the Phase 2 consensus.
- replace: set gloss to final_gloss, clear flag.
- keep:    leave gloss, clear flag (confirmed).
- flag:    leave gloss, set flag=1 (genuine residual).
- verbs not in consensus: untouched.
"""
import os, glob

HERE = os.path.dirname(os.path.abspath(__file__))
GL = os.path.join(HERE, "glosses")
CONS = os.path.join(GL, "phase1/phase2/consensus_all.tsv")

dec = {}   # inf -> (decision, final_gloss)
for l in open(CONS, encoding="utf-8").read().splitlines()[1:]:
    if not l.strip(): continue
    p = l.split("\t")
    dec[p[0]] = (p[2], p[3])

changed_gloss = 0
cleared_flag = 0
set_flag = 0
for path in sorted(glob.glob(os.path.join(GL, "slice_*.tsv"))):
    out = []
    for line in open(path, encoding="utf-8").read().splitlines():
        if not line.strip() or line.startswith("#"):
            out.append(line); continue
        parts = line.split("\t")
        inf = parts[0]
        gloss = parts[1] if len(parts) > 1 else ""
        had_flag = len(parts) >= 3 and parts[2].strip() == "1"
        if inf in dec:
            d, fin = dec[inf]
            if d == "replace" and fin != gloss:
                gloss = fin; changed_gloss += 1
            if d == "flag":
                newflag = True
                if not had_flag: set_flag += 1
            else:
                newflag = False
                if had_flag: cleared_flag += 1
        else:
            newflag = had_flag  # untouched
        if newflag:
            out.append(f"{inf}\t{gloss}\t1")
        else:
            out.append(f"{inf}\t{gloss}")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

print(f"glosses replaced : {changed_gloss}")
print(f"flags cleared    : {cleared_flag}")
print(f"flags set        : {set_flag}")
