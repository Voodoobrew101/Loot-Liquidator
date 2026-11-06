#!/usr/bin/env python3
"""Translate reviewed, non-duplicated Midnight studies to the existing evidence pipeline.

This imports reported units and casts, never probabilities inferred from units.
Archived Looter cohorts already in the pinned v3 snapshot remain there exactly
once. Publication, gear bonuses and cast-hit counts stay unknown when unreported.
"""
import argparse
import json
from pathlib import Path

SOURCE = Path('research/mechanics/midnight-enchanting-yields-2026-11-06.json')
SNAPSHOT = Path('database/research/v3-snapshot/research/v3/evidence')
OUTPUT = Path('research/evidence/v3/midnight/2026-11-06-enchanting-yields.json')

# Reviewed scope: Shard Supplier and Radiant Shard results identify the rare
# Courtly variant. The same item ID can be upgraded to epic, so item ID alone
# is insufficient. This scope is an inference, recorded with the source notes.
REVIEWED_SCOPES = {
    'wowhead-mikimm-courtly-wrists-1000': {'inputRarity': 3, 'inputClassID': 4},
}


def snapshot_lineages(folder=SNAPSHOT):
    found = set()
    for path in sorted(folder.rglob('*.jsonl')):
        for line in path.read_text().splitlines():
            row = json.loads(line)
            if row.get('studyKey'):
                found.add(row['studyKey'])
    return found


def build(review, existing):
    sources = {source['id']: source for source in review['sources']}
    records, skipped = [], []
    for cohort in review['cohorts']:
        lineage = cohort['studyKey']
        if lineage in existing:
            skipped.append((lineage, 'Already present in the pinned research snapshot'))
            continue
        scope = REVIEWED_SCOPES.get(lineage)
        if scope is None:
            skipped.append((lineage, 'Exact input scope or counted denominator requires review'))
            continue
        casts = cohort.get('completedCastsReported')
        if isinstance(casts, bool) or not isinstance(casts, int) or casts <= 0:
            raise ValueError('Reviewed counted study has no positive completed-cast count')
        source = sources[cohort['sourceID']]
        if source.get('sourceType') != 'PRIMARY_FIRSTHAND_TOTALS' or not source['url'].startswith('https://'):
            raise ValueError('Reviewed study requires an original firsthand totals source')
        outputs = []
        for original in cohort['outputs']:
            units = original.get('totalUnitsReported')
            item = original.get('outputItemID')
            if any(isinstance(v, bool) or not isinstance(v, int) for v in (units, item)) or units < 0 or item <= 0:
                raise ValueError('Reported item identity and whole-number units are required')
            output = {'item': item, 'totalQuantity': units,
                      'fieldConfidence': {'expectedQuantity': 75}}
            # Hit counts are an independent measured field, never units/cast.
            if original.get('hitCasts') is not None:
                output['castsWithDrop'] = original['hitCasts']
            outputs.append(output)
        records.append({
            'method': 'Disenchant', 'input': cohort['inputItemID'], 'inputPerCast': 1,
            'casts': casts, 'outputs': outputs, 'source': source['url'], 'lineage': lineage,
            'observedDate': cohort.get('dataDate'), 'patch': cohort.get('patch'), 'stale': False,
            'recipeID': 13262, 'expansionID': 11, **scope,
            'referenceContextID': lineage, 'referenceConditions': {},
            'notes': 'Firsthand Courtly Wrists rare-variant reference; Disenchanting Delegate and '
                     'Shard Supplier maxed. Rarity inferred from the named path and shard outputs. '
                     'Actual skill, gear, item level, patch and date were not reported. Seven listed '
                     'unit totals share one denominator; unlisted outputs are not verified zero. '
                     'No hit counts or conditional ranges were supplied. The 75% mean confidence '
                     'is a conservative editorial cap, not an inferred probability or confidence interval.',
        })
    return records, skipped


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    records, skipped = build(json.loads(SOURCE.read_text()), snapshot_lineages())
    text = json.dumps(records, ensure_ascii=False, indent=2) + '\n'
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text() != text:
            parser.exit(1, 'Midnight evidence import stale: run python3 tools/import_midnight_enchanting.py\n')
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(text)
    print(f'MIDNIGHT ENCHANTING: {len(records)} counted study; '
          f'{sum("Already present" in reason for _, reason in skipped)} archived cohorts not duplicated; '
          f'{sum("Already present" not in reason for _, reason in skipped)} references held')


if __name__ == '__main__':
    main()
