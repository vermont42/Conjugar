#!/usr/bin/env bash
# Copyright © 2026 Josh Adams. All rights reserved.
#
# Writes corpus/working/forms.json (the 1,000 most common verbs) and forms_all.json (every verb),
# the form → infinitive maps that the Python pipelines read (corpus/working/build_corpus_index.py
# and the other corpus/working builders, frequency/aggregate_gbooks.py), shaped
#
#   { "fue": ["ir", "ser"], "hablo": ["hablar"], … }
#
# Keys are every one-word form of two or more letters, lowercased, accents kept; values are
# sorted infinitives. It builds ConjugationMapTool, the macOS target that also writes the app's
# bundled ConjugationMap.lzfse, and runs it with --forms-json and --forms-all-json. One tool, one
# engine, so the pipelines and the app's search cannot disagree about what a form is.
#
# Run from anywhere:   scripts/write_forms_json.sh
# Both outputs are gitignored. Regenerate them when verbModelMap.xml or the engine changes.
#
# Until 2026-11-22 these files came from ConjugarTests/Models/CorpusFormsDumpTests, a disabled
# test harness that had to be enabled by hand to run. This script's forms_all.json was
# byte-identical to the harness's last, and its forms.json differed only in which verbs are the
# top 1,000, which the ranking of 2026-08-30 had moved.

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
working="$repo/corpus/working"

# A bare `xcodebuild -target` build writes ./build into the repository unless SYMROOT and
# OBJROOT point elsewhere. A scratch directory under TMPDIR keeps the tree clean, and reusing it
# across runs keeps rebuilds incremental.
build_root="${TMPDIR:-/tmp}/ConjugarConjugationMapTool-build"

xcodebuild -project "$repo/Conjugar.xcodeproj" -target ConjugationMapTool -configuration Release \
  SYMROOT="$build_root/Products" OBJROOT="$build_root/Intermediates" -quiet build

"$build_root/Products/Release/ConjugationMapTool" \
  --verb-map "$repo/Conjugar/Models/verbModelMap.xml" \
  --forms-json "$working/forms.json" \
  --forms-all-json "$working/forms_all.json"

echo "Wrote $working/forms.json and $working/forms_all.json"
