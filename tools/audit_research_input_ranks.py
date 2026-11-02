"""D1c7: compare source-stated input ranks/IDs with sourced item-page mappings.

Read-only: does not fill missing values, infer ranks, or rewrite evidence.
Audits real drop studies after the pinned research calculator's corrections.
Unknown identities are reported separately, not treated as contradictory data.
"""
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import research_v3_to_baselines as v3

CATALOG = Path(__file__).resolve().parent.parent / 'database/research/input-ranks.json'


def audit(rows, catalog):
    names = {name.strip().lower(): entry for name, entry in catalog['items'].items()}
    report = {'matched': 0, 'unresolved': [], 'conflicts': []}
    for row in rows:
        if row.get('type') != 'drop':
            continue
        entry = names.get((row.get('inputName') or '').strip().lower())
        if entry is None:
            continue
        rank = str(row.get('inputRank'))
        actual = row.get('inputItemID')
        expected = entry['ranks'].get(rank)
        detail = {'recordID': row.get('id'), 'file': row.get('_file'),
                  'name': row.get('inputName'), 'rank': row.get('inputRank'),
                  'itemID': actual, 'expectedItemID': expected, 'source': entry['source']}
        if expected is None or actual is None:
            report['unresolved'].append(detail)
        elif actual != expected:
            report['conflicts'].append(detail)
        else:
            report['matched'] += 1
    return report


def main():
    catalog = json.loads(CATALOG.read_text(encoding='utf-8'))
    module = v3.load_calculator(v3.DEFAULT_SNAPSHOT)
    rows = [row for row in module.load() if v3.is_counted(row, module)]
    report = audit(rows, catalog)
    print(json.dumps(report, indent=2))
    return 1 if report['conflicts'] else 0


if __name__ == '__main__':
    sys.exit(main())
