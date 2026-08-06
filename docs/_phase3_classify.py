#!/usr/bin/env python3
import os, re, glob
import importlib.util
# reuse loaders from the build script
spec = importlib.util.spec_from_file_location("bvm", os.path.join(os.path.dirname(os.path.abspath(__file__)), "_build_verbmap.py"))
bvm = importlib.util.module_from_spec(spec); spec.loader.exec_module(bvm)
oracle = bvm.load_oracle_glosses()
oldxml = bvm.load_old_xml_glosses()
homonyms = set(bvm.HOMONYMS.keys())

CONS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "glosses/phase1/phase2/consensus_all.tsv")
rows = [l.split("\t") for l in open(CONS, encoding="utf-8").read().splitlines()[1:] if l.strip()]

def source(inf):
    if inf in oracle: return "oracle"
    if inf in oldxml: return "oldxml"
    if inf in homonyms: return "footnote"
    return "authored"

from collections import Counter
by_dec_src = Counter()
oob_replace = []
for r in rows:
    inf, cur, dec, fin = r[0], r[1], r[2], r[3]
    s = source(inf)
    by_dec_src[(dec, s)] += 1
    if dec == "replace" and s != "authored":
        oob_replace.append((inf, cur, fin, s))

print("decision x source counts:")
for k in sorted(by_dec_src): print(f"  {k}: {by_dec_src[k]}")
print(f"\nREPLACE on out-of-bounds (slice edit = no-op, report-only): {len(oob_replace)}")
for inf, cur, fin, s in oob_replace: print(f"  {inf} [{s}]: {cur} -> {fin}")
