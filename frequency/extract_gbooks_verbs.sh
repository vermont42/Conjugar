#!/usr/bin/env bash
#
# Fetch the three Spanish 1-gram shards of the Google Books Ngram 2020 (v3) release and keep
# only the `_VERB`-tagged rows.
#
#   source:  http://storage.googleapis.com/books/ngrams/books/20200217/spa/
#   license: CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/)
#   volume:  631 MB + 1,114 MB + 1,478 MB compressed; ~830 MB of TSV kept
#
# Each shard is downloaded to a temporary `.gz`, filtered, and the `.gz` deleted, so the
# 3.2 GB of downloads leave only frequency/gbooks/verb_{0,1,2}.tsv behind. Those are
# gitignored -- the committed artifact is gbooks-verb-lemmas.json, which aggregate_gbooks.py
# derives from them. Re-run this only to rebuild that JSON.
#
# Downloading rather than piping `curl | gunzip` straight through costs the disk space of one
# shard and buys resumability: the third shard takes twenty minutes and Google reset the
# connection partway through it on the first attempt, which a pipeline cannot recover from
# (curl's retry restarts the transfer, but gunzip has already eaten half a stream). `-C -`
# picks up where the bytes stopped.
#
# Each kept line is `<form>_VERB<TAB><year>,<count>,<volumes><TAB>...`.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/gbooks"
BASE="http://storage.googleapis.com/books/ngrams/books/20200217/spa"

mkdir -p "$OUT"
for i in 0 1 2; do
  dest="$OUT/verb_$i.tsv"
  archive="$OUT/1-0000$i-of-00003.gz"
  if [ -s "$dest" ]; then
    echo "shard $i: $dest already present, skipping" >&2
    continue
  fi
  echo "shard $i: downloading $BASE/1-0000$i-of-00003.gz" >&2
  curl -sSfL --retry 10 --retry-delay 5 --retry-all-errors -C - \
    -o "$archive" "$BASE/1-0000$i-of-00003.gz"
  echo "shard $i: filtering" >&2
  gunzip -c "$archive" | LC_ALL=C command grep -a $'^[^\t]*_VERB\t' > "$dest.partial"
  mv "$dest.partial" "$dest"
  rm -f "$archive"
  echo "shard $i: $(wc -l < "$dest" | tr -d ' ') verb rows, $(du -h "$dest" | cut -f1)" >&2
done
echo "done: $OUT" >&2
