"""Preserve one reviewed historical positive quantity without admitting a study.

Exact loaded-row fingerprints include all source/provenance/count fields and
normalized _file. Any changed or ambiguous source fails closed. See
docs/LEGACY-REFERENCE-RANGE.md for evidence and removal conditions.
"""
import hashlib
import json

# Canonical JSON SHA256, including provenance. These are reviewed constants,
# never claims read from source metadata or a source-supplied correction rule.
REVIEWED = {'legacy-20261110-24914': '484f2c7ee159d8b8217d561b51ec083e6ac09d6bd6a17bdfa0b6bb185bca6934', 'legacy-20261106-004102': '3ac75069fcbd94f04c91be0d7d164d3bc53d1678b94280e725319b0ebc0c3b63'}
TARGET = 'legacy-20261110-24914'


def preserve_reference_range(rows):
    """Return input unchanged except the exact reference's two missing bounds.

    Called after the research loader's replacements/corrections. No raw row is
    mutated or resurrected; an upstream repair automatically makes this a no-op.
    """
    found = {key: [] for key in REVIEWED}
    for row in rows:
        key = row.get('id')
        if isinstance(key, str) and key in found:
            found[key].append(row)
    for key, digest in REVIEWED.items():
        if len(found[key]) != 1:
            return rows
        try:
            encoded = json.dumps(found[key][0], sort_keys=True,
                                 separators=(',', ':'), ensure_ascii=True,
                                 allow_nan=False).encode('utf-8')
        except (TypeError, ValueError):
            return rows
        if hashlib.sha256(encoded).hexdigest() != digest:
            return rows
    target = found[TARGET][0]
    return [dict(row, minSeen=2, maxSeen=2) if row is target else row
            for row in rows]
