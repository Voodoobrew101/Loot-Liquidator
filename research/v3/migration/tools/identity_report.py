#!/usr/bin/env python3
"""M05: which studies does study identity merge, and does it drop any different numbers?

Read-only. For every estimate group it lists studies (file + studyKey, as in S7/M05) that share one
identity and classifies the group:
  identical  every merged row reports the same numbers (a true copy, correctly counted once)
  partial    numbers differ, but only inside a listed partial copy (a swapped label, usually)
  differing  numbers differ, so independent results are being dropped

Two identities are measured on the same rows so one run shows before and after:
  legacy   the pre-M05 rule: (source URL, inputRank, casts, studyKey if no casts)
  current  build_estimates.study_identity()
The report also lists what needs a human eye: partial copies, copy rows removed from a vaguer
estimate group, pairs from one source that share 2+ non-zero rows yet count as separate cohorts,
small studies contained in another from one source but below the partial-copy bar, and studies with
equal numbers under different sources (not merged: only originalSource can say).

Usage, from the repository root:
  python3 research/v3/migration/tools/identity_report.py [--json OUT.json]
Deterministic: sorted output, no timestamps.
"""
import argparse
import json
import os
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import build_estimates as b  # noqa: E402


def legacy_identity(r):
    src = r.get("originalSource") or (r.get("source") or {}).get("url") or r.get("studyKey") or r.get("id")
    return (src, r.get("inputRank"), r.get("casts"), r.get("studyKey") if not r.get("casts") else None)


def same_numeric_rows_across_copies(merged_rows):
    """Compare whole per-study multisets, not one row against a different rank/variant.

    Family groups can contain R2 and R3 rows, or two unknown-rank materials with
    the same display name. A second transcription may add item IDs without changing
    the measurements. Unnumbered labels do not establish a numerical conflict.
    This is diagnostic only: it does not establish material identity or alter the
    estimator's actual deduplication.
    """
    by_study = defaultdict(list)
    for r in merged_rows:
        numbers = b.row_numbers(r)
        if any(x is not None for x in numbers):
            by_study[b.study_ref(r)].append(
                (str(r.get("inputRank")), str(r.get("outputRank")), numbers)
            )
    signatures = [tuple(sorted(v, key=repr)) for v in by_study.values()]
    return len(signatures) > 1 and all(v == signatures[0] for v in signatures[1:])


def collisions(rows, identity, partial_refs=frozenset()):
    """Estimate groups where studies share an identity -> how the merged rows compare."""
    names = b.name_maps(rows)
    groups = defaultdict(lambda: defaultdict(list))
    for r in rows:
        k = b.key_of(r, names) if b.is_study_row(r) else None
        if k:
            groups[k][identity(r)].append(r)
    out = []
    for k in sorted(groups, key=lambda k: (k[0], k[1], str(k[2]))):
        merged = [v for v in groups[k].values() if len({b.study_ref(r) for r in v}) > 1]
        if not merged:
            continue
        differ = [r for v in merged if not same_numeric_rows_across_copies(v) for r in v
                  if not same_report(r, v[0], identity is legacy_identity) and b.study_ref(r) != b.study_ref(v[0])]
        kind = "identical"
        if differ:
            kind = "partial" if {b.study_ref(r) for r in differ} <= partial_refs else "differing"
        out.append({"method": k[0], "input": k[1], "output": str(k[2]), "kind": kind,
                    "lostCasts": sum(r.get("casts") or 0 for r in differ),
                    "studies": sorted({r.get("studyKey") or r.get("id") for v in merged for r in v})})
    return out


def same_report(r, other, exact):
    # The legacy count stays exact so it can be compared with the figures in the plan.
    if exact:
        return b.row_numbers(r) == b.row_numbers(other)
    return b.row_numbers(r) == b.row_numbers(other) or b.numbers_agree(b.row_numbers(r), b.row_numbers(other))


def counts(found):
    c = Counter(x["kind"] for x in found)
    return {"groups": len(found), "differing": c["differing"], "identical": c["identical"], "partial": c["partial"],
            "droppedMaterialCasts": sum(x["lostCasts"] for x in found if x["kind"] == "differing")}


def study_sources(rows):
    sources = {}
    for r in rows:
        if b.is_study_row(r):
            sources.setdefault(b.study_ref(r), b.source_key(r))
    return sources


def near_copies(sources, vectors):
    """Same source, separate cohorts, 2+ equal non-zero rows: coincidence, or a re-count to look at."""
    by_source = defaultdict(list)
    for s in sorted(sources):
        by_source[sources[s]].append(s)
    out = []
    for src, members in sorted(by_source.items()):
        for i, s in enumerate(members):
            for o in members[i + 1:]:
                if vectors[s] == vectors[o]:
                    continue
                shared = Counter(vectors[s]) & Counter(vectors[o])
                nonzero = sum(n for e, n in shared.items() if any(e[3]))
                if nonzero >= 2:
                    out.append({"source": src, "a": s[1], "b": o[1], "sharedNonZero": nonzero,
                                "rowsA": len(vectors[s]), "rowsB": len(vectors[o])})
    return out


def small_subsets(sources, vectors):
    """Contained in a study from one source but with under 2 non-zero rows, so counted separately."""
    by_source = defaultdict(list)
    for s in sorted(sources):
        by_source[sources[s]].append(s)
    out = []
    for src, members in sorted(by_source.items()):
        for s in members:
            for o in members:
                if (vectors[s] != vectors[o] and len(vectors[s]) < len(vectors[o])
                        and b.batch_family(s) != b.batch_family(o)
                        and any(x is not None for e in vectors[s] for x in e[3])
                        and b.rows_covered(vectors[s], vectors[o], labelled=True)):
                    out.append({"source": src, "study": s[1], "file": s[0], "within": o[1], "rows": len(vectors[s])})
    return out


def cross_source_matches(sources, vectors):
    """Equal numbers under different sources. Counted separately until originalSource links them."""
    by_vector = defaultdict(list)
    for s in sorted(sources):
        if sum(1 for e in vectors[s] if any(e[3])) >= 2:
            by_vector[vectors[s]].append(s)
    return [{"studies": [s[1] for s in members], "sources": sorted({sources[s] for s in members})}
            for members in by_vector.values() if len({sources[s] for s in members}) > 1]


def report(rows):
    vectors, partial, pooled = b.study_vectors(rows)
    sources = study_sources(rows)
    sizes = Counter(b.study_ref(r) for r in rows if b.is_study_row(r))
    partial_refs = {s for pair in partial for s in pair}
    before = collisions(rows, legacy_identity)
    after = collisions(rows, lambda r: b.study_identity(r, vectors), partial_refs)
    misplaced = b.misplaced_copies(rows, b.name_maps(rows), vectors, {})
    return {
        "pooledStudies": [{"pool": p[1], "file": p[0], "firstBatch": o[1]} for p, o in sorted(pooled.items())],
        "legacy": counts(before), "current": counts(after),
        "stillDiffering": [x for x in after if x["kind"] == "differing"],
        "mergedWithConflicts": [x for x in after if x["kind"] == "partial"],
        "partialCopies": [{"copy": c[1], "copyFile": c[0], "copyRows": sizes[c], "original": o[1],
                           "originalFile": o[0], "originalRows": sizes[o],
                           "kind": "relabeled" if sizes[c] == sizes[o] else "subset"} for c, o in partial],
        "misplacedCopyRows": sorted(r["id"] for r in rows if id(r) in misplaced),
        "nearCopies": near_copies(sources, vectors),
        "smallSubsets": small_subsets(sources, vectors),
        "crossSourceMatches": cross_source_matches(sources, vectors),
        "cohortsRestored": sorted({s for x in before if x["kind"] == "differing" for s in x["studies"]}
                                  - {s for x in after for s in x["studies"]}),
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--json")
    a = ap.parse_args(argv)
    d = report(b.load())
    print("legacy ", d["legacy"])
    print("current", d["current"])
    print(f"pooled studies {len(d['pooledStudies'])}; partial copies {len(d['partialCopies'])}; misplaced copy rows {len(d['misplacedCopyRows'])}; "
          f"near copies {len(d['nearCopies'])}; small subsets {len(d['smallSubsets'])}; "
          f"cross-source matches {len(d['crossSourceMatches'])}; "
          f"studies no longer merged {len(d['cohortsRestored'])}")
    if a.json:
        with open(a.json, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(d, fh, indent=1, sort_keys=True)
            fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
