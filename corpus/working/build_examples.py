#!/usr/bin/env python3
"""Deterministic bookends for the example-mining pass (stage C of example-uses-pipeline.md).

The LLM middle — selecting the best candidate per verb and translating it — runs as parallel
`Agent` subagents (one per shard). This script handles the cheap deterministic ends around it:

  shard modern    : split corpus/working/corpus_index.json  into ~SHARD_SIZE-verb shards under
                    corpus/working/shards/modern_NNN.json   (schema {doc,line,token,text}).
  shard medieval  : split corpus/working/medieval_index.json into shards/medieval_NNN.json
                    (schema {work,ref,os,token}).
  report modern   <ExampleUses.json>      : coverage + source balance + null/uncovered tail.
  report medieval <MedievalExamples.json> : coverage + per-work balance.

Sharding is RESUMABLE: verbs already present in the corresponding output JSON (if it exists) are
skipped, so a re-shard after a partial mine only re-emits the verbs still missing. Pass the output
path to skip against, e.g.:
  python3 build_examples.py shard modern   corpus/json/ExampleUses.json
  python3 build_examples.py shard medieval corpus/json/MedievalExamples.json
(omit the path to shard every verb).

  aggregate modern   : merge mined_modern_*.json   -> ExampleUses.json (dual-write).
  aggregate medieval : merge mined_medieval_*.json -> MedievalExamples.json (dual-write).

Usage:
  python3 build_examples.py shard     {modern|medieval} [output.json]
  python3 build_examples.py aggregate {modern|medieval}
  python3 build_examples.py report    {modern|medieval}  output.json
"""
import glob
import json
import os
import shutil
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
MODERN_INDEX = os.path.join(HERE, "corpus_index.json")
MEDIEVAL_INDEX = os.path.join(HERE, "medieval_index.json")
SPECIAL_INDEX = os.path.join(HERE, "special_index.json")  # step F: unranked medieval verbs' modern index
SHARDS_DIR = os.path.join(HERE, "shards")
SHARD_SIZE = 30

# Dual-home targets (canonical export + the bundled copy the app loads), mirroring Etymologies.json.
JSON_DIR = os.path.join(REPO, "corpus", "json")
MODELS_DIR = os.path.join(REPO, "Conjugar", "Models")
WORKS = {"cid", "berceo", "lba"}


def _load_done(output_path):
    """Return the set of verbs already present in a finished output JSON (empty if absent)."""
    if not output_path or not os.path.exists(output_path):
        return set()
    with open(output_path, encoding="utf-8") as handle:
        return set(json.load(handle))


def shard(kind, output_path=None):
    index_path = {"modern": MODERN_INDEX, "medieval": MEDIEVAL_INDEX,
                  "special": SPECIAL_INDEX}[kind]
    with open(index_path, encoding="utf-8") as handle:
        index = json.load(handle)
    done = _load_done(output_path)
    verbs = [v for v in index if v not in done]  # index order is already ranked/balanced
    if not os.path.isdir(SHARDS_DIR):
        os.makedirs(SHARDS_DIR)
    # Clear only this kind's shards (the two kinds coexist in the same dir).
    for name in os.listdir(SHARDS_DIR):
        if name.startswith(f"{kind}_"):
            os.remove(os.path.join(SHARDS_DIR, name))
    count = 0
    for count, start in enumerate(range(0, len(verbs), SHARD_SIZE)):
        chunk = {v: index[v] for v in verbs[start:start + SHARD_SIZE]}
        path = os.path.join(SHARDS_DIR, f"{kind}_{count:03d}.json")
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(chunk, handle, ensure_ascii=False, indent=1)
    total = count + 1 if verbs else 0
    skipped = len(index) - len(verbs)
    print(f"{kind}: {len(verbs)} verbs -> {total} shards of <= {SHARD_SIZE} "
          f"({skipped} already done, skipped) in {os.path.relpath(SHARDS_DIR)}")


def _author_of(source):
    if not source:
        return "?"
    base = os.path.basename(source)
    return base.split("-")[0] if "-" in base else base


def report_modern(path):
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    rows = list(data.values()) if isinstance(data, dict) else data
    by_source = defaultdict(int)
    nulls = 0
    for ex in rows:
        if ex.get("es"):
            by_source[_author_of(ex.get("source"))] += 1
        else:
            nulls += 1
    total = len(rows)
    print(f"modern examples       : {total}")
    print(f"  with a sentence     : {total - nulls}")
    print(f"  null (no good use)  : {nulls}")
    print("\nplaced examples by source (even-mix check):")
    for author, n in sorted(by_source.items(), key=lambda kv: -kv[1]):
        print(f"  {n:4d}  {author}")


def report_medieval(path):
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    by_work = defaultdict(int)
    verbs_with = 0
    total_lines = 0
    for _verb, arr in data.items():
        if arr:
            verbs_with += 1
        for ex in arr:
            by_work[ex.get("work", "?")] += 1
            total_lines += 1
    print(f"medieval verbs        : {len(data)}")
    print(f"  with >=1 example    : {verbs_with}")
    print(f"  total example lines : {total_lines}")
    print("\nlines by work:")
    for work, n in sorted(by_work.items(), key=lambda kv: -kv[1]):
        print(f"  {n:4d}  {work}")


def _dual_write(basename, data):
    """Write `data` (already assembled) to both corpus/json/ and Conjugar/Models/."""
    blob = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    for directory in (JSON_DIR, MODELS_DIR):
        os.makedirs(directory, exist_ok=True)
        with open(os.path.join(directory, basename), "w", encoding="utf-8") as handle:
            handle.write(blob)
    print(f"dual-wrote {basename} -> corpus/json/ and Conjugar/Models/ ({len(data)} verbs)")


def aggregate_modern():
    """Merge mined_modern_*.json AND mined_tail_*.json shards into ExampleUses.json (placed entries
    only). The tail shards (step D tail rescue) re-mine the verbs the main modern pass returned null
    for; their keys are disjoint from the modern-placed set, so this is a clean union. The
    remaining null verbs are handled by the Claude-authored residue (merge_authored)."""
    merged, nulls, warnings = {}, [], []
    shards = (sorted(glob.glob(os.path.join(HERE, "mined_modern_*.json")))
              + sorted(glob.glob(os.path.join(HERE, "mined_tail_*.json")))
              + sorted(glob.glob(os.path.join(HERE, "mined_authored*.json")))
              + sorted(glob.glob(os.path.join(HERE, "mined_special_*.json")))
              + sorted(glob.glob(os.path.join(HERE, "mined_special_authored*.json"))))
    for path in shards:
        for verb, ex in json.load(open(path, encoding="utf-8")).items():
            if not ex or ex.get("es") is None:
                nulls.append(verb)
                continue
            entry = {k: ex.get(k) for k in ("es", "en", "source", "line", "token")}
            for field in ("es", "en"):
                if '"' in (entry[field] or ""):
                    warnings.append(f'{verb}: ASCII quote in {field}')
            merged[verb] = entry
    merged = dict(sorted(merged.items()))
    _dual_write("ExampleUses.json", merged)
    print(f"placed {len(merged)}; null/deferred-to-D {len(nulls)}")
    if warnings:
        print("WARNINGS:")
        for w in warnings:
            print("  ", w)
    print("null tail:", ", ".join(sorted(nulls)) or "(none)")


def aggregate_medieval():
    """Merge mined_medieval_*.json shards into MedievalExamples.json (non-empty arrays only)."""
    merged, empty, warnings = {}, [], []
    for path in sorted(glob.glob(os.path.join(HERE, "mined_medieval_*.json"))):
        for verb, arr in json.load(open(path, encoding="utf-8")).items():
            if not arr:
                empty.append(verb)
                continue
            clean = []
            for ex in arr:
                item = {k: ex.get(k) for k in ("work", "ref", "os", "tr")}
                if item["work"] not in WORKS:
                    warnings.append(f'{verb}: bad work {item["work"]!r}')
                for field in ("os", "tr"):
                    if '"' in (item[field] or ""):
                        warnings.append(f'{verb}: ASCII quote in {field}')
                clean.append(item)
            merged[verb] = clean
    merged = dict(sorted(merged.items()))
    _dual_write("MedievalExamples.json", merged)
    lines = sum(len(v) for v in merged.values())
    by_work = defaultdict(int)
    for arr in merged.values():
        for ex in arr:
            by_work[ex["work"]] += 1
    print(f"verbs with >=1 example {len(merged)}; empty {len(empty)}; total lines {lines}")
    print("lines by work:", dict(sorted(by_work.items(), key=lambda kv: -kv[1])))
    if warnings:
        print("WARNINGS:")
        for w in warnings:
            print("  ", w)


def main():
    argv = sys.argv
    if len(argv) >= 3 and argv[1] == "shard" and argv[2] in ("modern", "medieval", "special"):
        shard(argv[2], argv[3] if len(argv) >= 4 else None)
    elif len(argv) >= 3 and argv[1] == "aggregate" and argv[2] == "modern":
        aggregate_modern()
    elif len(argv) >= 3 and argv[1] == "aggregate" and argv[2] == "medieval":
        aggregate_medieval()
    elif len(argv) >= 4 and argv[1] == "report" and argv[2] == "modern":
        report_modern(argv[3])
    elif len(argv) >= 4 and argv[1] == "report" and argv[2] == "medieval":
        report_medieval(argv[3])
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
