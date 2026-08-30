#!/usr/bin/env python3
"""CORPES XXI + Google Books -> frequency/verb-counts.json, one row per distinct infinitive.

Reads the two sources downloaded per frequency/README.md and produces the counts that
`docs/_build_verbmap.py` writes into `verbModelMap.xml` as `hi` / `gb` / `hp`, plus a
report. The app derives its 1…4,811 ranks from those counts at parse time, so nothing here
assigns a rank that has to be maintained: adding a verb never renumbers the others.

Primary key, `hi`: the Real Academia Española's CORPES XXI 1.5 lemma frequencies, the bare
infinitive plus its `-se` lemma. CORPES lemmatizes 416 pronominal verbs with the clitic
attached (`arrepentirse`, `suicidarse`, `adentrarse`), which Conjugar keys bare, so the sum
is what recovers them. Tie-breaker, `gb`: Google Books verb-form tokens summed through the
app's own paradigms (see aggregate_gbooks.py). Where CORPES saw nothing at all, `hi` is an
estimate from `gb` through a log-log fit, flagged `hp` and clamped so an estimate can never
enter the top of the list; the handful of verbs neither source knows take an editorial
count from editorial-counts.json.

Run from the repo root:  python3 frequency/build_counts.py [--dry-run]
"""

import argparse
import collections
import json
import math
import os
import re
import sys
import unicodedata
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FREQ = os.path.join(ROOT, "frequency")
VERB_MAP = os.path.join(ROOT, "Conjugar", "Models", "verbModelMap.xml")
CORPES_ZIP = os.path.join(FREQ, "corpes_lemas.zip")
CORPES_MEMBER = "frecuencia_lemas_corpes_1_5.txt"
GBOOKS = os.path.join(FREQ, "gbooks-verb-lemmas.json")
EDITORIAL = os.path.join(FREQ, "editorial-counts.json")
OUT = os.path.join(FREQ, "verb-counts.json")
REPORT = os.path.join(FREQ, "report.md")

# The estimate ceiling is the measured count at this rank, so no estimated verb can rank
# above roughly the thousandth measured one. Recomputed every run; never hard-coded.
CLAMP_RANK = 1000
MIN_R_SQUARED = 0.75
MIN_SPEARMAN = 0.85
# Verbs CORPES XXI 1.5 has no lemma for in either spelling: 42 that Google Books counts and
# 4 that nothing counts. The 2026-08-28 research measured 48, before the two malformed keys
# were corrected (reeligir -> reelegir, sobre(e)ntender -> sobrentender); CORPES has both
# corrected spellings, so they left the unmeasured set and reeligir took its Google Books
# count with it.
EXPECTED_PROVISIONAL = 46
GAP_THRESHOLD = 100

# U+007F sorts above every ASCII letter, so an infinitive's enye becomes `n` + this and
# lands after every n-word; the leading `n` keeps it below every o-word.
AFTER_LETTERS = "\u007f"


def spanish_key(word):
    """Mirrors `compare(_:locale:)` under `Locale(identifier: "es")`.

    Two tailorings matter. CLDR's Spanish collation makes enye a letter of its own,
    ordered between `n` and `o` (`&N < ñ`), so `ñoñear` sorts after `nadar` and before
    `obrar` rather than among the n-words. Accents and the dieresis are secondary
    differences, so they separate only spellings that are otherwise identical -- which is
    why the raw word is the second element of the key rather than the first.
    """
    folded = word.replace("ñ", "n" + AFTER_LETTERS)
    stripped = "".join(
        character for character in unicodedata.normalize("NFD", folded)
        if not unicodedata.combining(character)
    )
    return (stripped.lower(), word)


def target_infinitives():
    """The map's distinct infinitives, plus whatever `fr` ranks it still carries."""
    text = open(VERB_MAP, encoding="utf-8").read()
    infinitives = re.findall(r'<verb in="([^"]+)"', text)
    old_ranks = {}
    for infinitive, attributes in re.findall(r'<verb in="([^"]+)"([^/]*)/>', text):
        match = re.search(r'\bfr="(\d+)"', attributes)
        if match:
            old_ranks[infinitive] = int(match.group(1))
    return sorted(set(infinitives), key=spanish_key), old_ranks


def read_corpes():
    """The `V` rows of the lemma list: {lemma: absolute frequency}.

    Tab-separated, CRLF, two header lines, then one row per lemma: *Elemento*, a
    one-letter word class, the absolute *Frecuencia*, and two per-million columns.
    """
    lemmas = collections.Counter()
    tokens = 0
    with zipfile.ZipFile(CORPES_ZIP) as archive:
        with archive.open(CORPES_MEMBER) as handle:
            for raw in handle:
                fields = raw.decode("utf-8").rstrip("\r\n").split("\t")
                if len(fields) < 3 or fields[1].strip() != "V":
                    continue
                frequency = fields[2].strip()
                if not frequency.isdigit():
                    continue
                lemmas[fields[0].strip()] += int(frequency)
                tokens += int(frequency)
    return lemmas, tokens


def fit_calibration(rows):
    """Least squares of log(hi) on log(gb), over the verbs both sources count."""
    points = [
        (math.log(row["gbooks"]), math.log(row["hits"]))
        for row in rows.values()
        if row.get("hits", 0) > 0 and row.get("gbooks", 0) > 0 and not row.get("estimate")
    ]
    count = len(points)
    mean_x = sum(x for x, _ in points) / count
    mean_y = sum(y for _, y in points) / count
    covariance = sum((x - mean_x) * (y - mean_y) for x, y in points)
    variance = sum((x - mean_x) ** 2 for x, _ in points)
    slope = covariance / variance
    intercept = mean_y - slope * mean_x
    residuals = sorted(y - (intercept + slope * x) for x, y in points)
    r_squared = 1 - sum(r ** 2 for r in residuals) / sum((y - mean_y) ** 2 for _, y in points)
    percentiles = [residuals[int(p * (count - 1))] for p in (0.05, 0.25, 0.5, 0.75, 0.95)]
    return intercept, slope, r_squared, count, percentiles


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="report only; write nothing")
    arguments = parser.parse_args()

    targets, old_ranks = target_infinitives()
    corpes, corpes_tokens = read_corpes()
    gbooks = json.load(open(GBOOKS, encoding="utf-8"))
    editorial = json.load(open(EDITORIAL, encoding="utf-8")) if os.path.exists(EDITORIAL) else {}

    rows = {}
    direct = rescued = both = unmeasured = 0
    for infinitive in targets:
        row = {}
        bare = corpes.get(infinitive)
        pronominal = corpes.get(infinitive + "se")
        if bare is not None:
            row["corpes"] = bare
        if pronominal is not None:
            row["corpes_se"] = pronominal
        if bare is not None and pronominal is not None:
            both += 1
        elif bare is not None:
            direct += 1
        elif pronominal is not None:
            rescued += 1
        else:
            unmeasured += 1
        if bare is not None or pronominal is not None:
            row["hits"] = (bare or 0) + (pronominal or 0)
        count = gbooks.get(infinitive, 0)
        if count:
            row["gbooks"] = count
        rows[infinitive] = row

    measured = sorted((row["hits"] for row in rows.values() if "hits" in row), reverse=True)
    clamp = measured[CLAMP_RANK - 1]
    intercept, slope, r_squared, fit_count, percentiles = fit_calibration(rows)

    tiers = collections.defaultdict(list)
    for infinitive in targets:
        row = rows[infinitive]
        if "hits" in row:
            continue
        if row.get("gbooks", 0) > 0:
            estimated = min(int(round(math.exp(intercept + slope * math.log(row["gbooks"])))), clamp)
            tier = "gbooks-fit"
            reason = f"{row['gbooks']:,} Google Books tokens through the fit"
        elif infinitive in editorial:
            estimated = min(int(editorial[infinitive]["count"]), clamp)
            tier = "editorial"
            reason = editorial[infinitive]["reason"]
        else:
            tiers["unresolved"].append(infinitive)
            continue
        row["hits"] = estimated
        row["estimate"] = {"count": estimated, "tier": tier, "reason": reason}
        tiers[tier].append(infinitive)

    provisional = [i for i in targets if "estimate" in rows[i]]

    def sort_key(infinitive):
        row = rows[infinitive]
        # An absent Google Books count sorts below a present one, matching the app's rule.
        return (-row.get("hits", -1), -row.get("gbooks", -1), spanish_key(infinitive))

    ordered = sorted(targets, key=sort_key)
    ranks = {infinitive: index + 1 for index, infinitive in enumerate(ordered)}

    failures = []
    if tiers["unresolved"]:
        failures.append(
            f"{len(tiers['unresolved'])} infinitives have neither a measured nor an estimated "
            f"count; add them to editorial-counts.json: "
            f"{', '.join(sorted(tiers['unresolved'], key=spanish_key))}")
    if r_squared < MIN_R_SQUARED:
        failures.append(f"calibration R^2 {r_squared:.3f} is below {MIN_R_SQUARED}")
    if ordered[:3] != ["ser", "estar", "tener"]:
        failures.append(f"top three are {ordered[:3]}, not ser/estar/tener")
    over_clamp = [i for i in provisional if rows[i]["estimate"]["count"] > clamp]
    if over_clamp:
        failures.append(f"estimates above the clamp {clamp}: {over_clamp}")
    if len(provisional) != EXPECTED_PROVISIONAL:
        failures.append(f"{len(provisional)} provisional counts, expected {EXPECTED_PROVISIONAL}")

    shared = [i for i in targets if i in old_ranks]
    spearman, movers = None, []
    if len(shared) > 1:
        new_order = {v: i for i, v in enumerate(sorted(shared, key=lambda v: ranks[v]))}
        old_order = {v: i for i, v in enumerate(sorted(shared, key=lambda v: old_ranks[v]))}
        size = len(shared)
        spearman = 1 - 6 * sum((new_order[v] - old_order[v]) ** 2 for v in shared) / (
            size * (size * size - 1))
        # Ranked by the move a reader would notice -- the change in the number on the badge --
        # rather than by position within the shared set, which compresses the tail moves that
        # are the whole point (the esTenTen tagger's noun-as-verb artifacts).
        movers = sorted(shared, key=lambda v: -abs(ranks[v] - old_ranks[v]))[:20]
        if spearman < MIN_SPEARMAN:
            failures.append(f"Spearman vs the old fr ranks {spearman:.4f} is below {MIN_SPEARMAN}")

    # Every CORPES verb lemma the map has no row for, big enough to be worth a look. Input
    # to a later verb-list audit, not to this pipeline; supersedes docs/freq_unmatched.txt.
    target_set = set(targets)
    gaps = sorted(
        ((lemma, count) for lemma, count in corpes.items()
         if count >= GAP_THRESHOLD and lemma not in target_set
         and not (lemma.endswith("se") and lemma[:-2] in target_set)),
        key=lambda pair: -pair[1])

    hit_groups = collections.Counter(rows[i]["hits"] for i in targets)
    pair_groups = collections.Counter((rows[i]["hits"], rows[i].get("gbooks")) for i in targets)

    lines = []
    write = lines.append
    write("# Frequency build report\n")
    write("Generated by `frequency/build_counts.py`. See `frequency/README.md` for provenance.\n")

    write("## Coverage\n")
    write(f"- {len(targets):,} distinct infinitives in `verbModelMap.xml`.")
    write(f"- CORPES XXI 1.5: {len(corpes):,} verb lemmas, {corpes_tokens:,} tokens.")
    write(f"- Matched directly on the bare infinitive: {direct:,}.")
    write(f"- Rescued by the `-se` lemma alone: {rescued:,}.")
    write(f"- Counted under both spellings, summed: {both:,}.")
    write(f"- Measured in CORPES one way or another: {direct + rescued + both:,} "
          f"({100 * (direct + rescued + both) / len(targets):.1f}%).")
    write(f"- Unmeasured, so estimated: {unmeasured:,}.")
    write(f"- Google Books counts {sum(1 for i in targets if rows[i].get('gbooks')):,} of them.")
    write(f"- Verbs sharing an `hi` with another verb: "
          f"{sum(size for size in hit_groups.values() if size > 1):,} in "
          f"{sum(1 for size in hit_groups.values() if size > 1):,} groups; "
          f"{sum(1 for size in pair_groups.values() if size > 1):,} groups survive the Google "
          f"Books tie-break.\n")

    write("## Calibration\n")
    write(f"- Least squares over the {fit_count:,} verbs both sources count nonzero: "
          f"`log(hi) = {intercept:.4f} + {slope:.4f}·log(gb)`, R² = {r_squared:.4f}.")
    write(f"- Residual percentiles (log): 5th {percentiles[0]:.3f}, Q1 {percentiles[1]:.3f}, "
          f"median {percentiles[2]:.3f}, Q3 {percentiles[3]:.3f}, 95th {percentiles[4]:.3f} "
          f"(×{math.exp(percentiles[0]):.2f}…×{math.exp(percentiles[4]):.2f} of the fit).")
    write(f"- Clamp, the measured `hi` at rank {CLAMP_RANK:,}: {clamp:,}.\n")

    write('## Estimated counts (`hp="y"`)\n')
    for tier in ("gbooks-fit", "editorial"):
        chosen = sorted(tiers[tier], key=lambda v: ranks[v])
        write(f"### {tier} ({len(chosen)})\n")
        for infinitive in chosen:
            estimate = rows[infinitive]["estimate"]
            write(f"- `{infinitive}` → {estimate['count']:,} hits, rank #{ranks[infinitive]:,} "
                  f"— {estimate['reason']}")
        write("")

    write("## Pronominal rescues\n")
    rescues = sorted((i for i in targets if "corpes" not in rows[i] and "corpes_se" in rows[i]),
                     key=lambda v: ranks[v])
    write(f"{len(rescues)} verbs CORPES lists only with the clitic attached:\n")
    for infinitive in rescues:
        write(f"- `{infinitive}` ← `{infinitive}se` {rows[infinitive]['corpes_se']:,}, "
              f"rank #{ranks[infinitive]:,}")
    write("")
    summed = sorted((i for i in targets if "corpes" in rows[i] and "corpes_se" in rows[i]),
                    key=lambda v: ranks[v])
    write(f"{len(summed)} exist in both spellings and simply sum: "
          + ", ".join(f"`{i}` ({rows[i]['corpes']:,} + {rows[i]['corpes_se']:,})" for i in summed)
          + "\n")

    write("## Top 30\n")
    write(", ".join(ordered[:30]) + "\n")

    write("## The tail\n")
    for rank in (988, 1000, 2000, 3000, 4000, 4500, len(ordered)):
        verb = ordered[rank - 1]
        write(f"- #{rank:,} `{verb}` — {rows[verb]['hits']:,} hits"
              + (" (estimated)" if "estimate" in rows[verb] else ""))
    write("")

    write("## Continuity with the retired esTenTen ranks\n")
    if spearman is None:
        write("No `fr=` ranks remain in the verb map to compare against.\n")
    else:
        write(f"Spearman over the {len(shared)} verbs both rankings have: {spearman:.4f}.\n")
        write("Biggest movers:\n")
        for infinitive in movers:
            write(f"- `{infinitive}`: #{old_ranks[infinitive]:,} → #{ranks[infinitive]:,} "
                  f"({rows[infinitive]['hits']:,} hits)")
        write("")

    write("## Gaps: CORPES verbs the map has no row for\n")
    write(f"{len(gaps):,} verb lemmas with {GAP_THRESHOLD}+ hits are absent from "
          "`verbModelMap.xml` (excluding the `-se` spellings of verbs it does have). Input to a "
          "later verb-list audit, not to this pipeline. The G-rating pass removed sixteen of "
          "them on purpose.\n")
    for lemma, count in gaps[:120]:
        write(f"- `{lemma}` {count:,}")
    if len(gaps) > 120:
        write(f"- …and {len(gaps) - 120:,} more")
    write("")

    report = "\n".join(lines)
    print(report)

    if failures:
        print("\nGATE FAILURES:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        sys.exit(1)

    if arguments.dry_run:
        print("\n--dry-run: nothing written.")
        return

    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump({i: rows[i] for i in targets}, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    open(REPORT, "w", encoding="utf-8").write(report + "\n")
    print(f"\nWrote {OUT} and {REPORT}.")


if __name__ == "__main__":
    main()
