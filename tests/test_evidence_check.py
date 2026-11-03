"""D1b step 1: research evidence records are checked; bad ones are set aside with a reason, never dropped."""
import contextlib
import copy
import io
import json
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'tools'))
import evidence_check as ec  # noqa: E402

passed = 0


def ok(condition, label):
    global passed
    assert condition, label
    passed += 1


GOOD = {
    'method': 'Prospect', 'input': 36912, 'inputPerCast': 5, 'casts': 412,
    'outputs': [{'item': 36917, 'castsWithDrop': 74, 'totalQuantity': 81, 'min': 1, 'max': 2}],
    'source': 'https://example.org/saronite', 'lineage': 'example-2024-user123',
    'observedDate': '2025-08', 'patch': '11.2.0', 'stale': False,
    'skill': None, 'minimumSkill': None,
    'stats': {'resourcefulness': None, 'multicraft': None, 'specPoints': None, 'gearBonusSkill': None},
    'notes': 'Proposal section 3 example.',
}
MECHANIC = {
    'kind': 'mechanic', 'profession': 'Jewelcrafting', 'metric': 'resourcefulness',
    'effect': 'Chance to refund part of the input', 'appliesTo': 'Prospect, Midnight ores',
    'numbers': {'procPerPoint': None, 'refundShare': 0.3},
    'source': 'https://example.org/talent', 'patch': '12.0.5', 'notes': 'In our own words.',
}


def reasons_for(change, base=GOOD):
    record = copy.deepcopy(base)
    change(record)
    return ec.check_record(record)[1]


def bad(change, fragment, label, base=GOOD):
    reasons = reasons_for(change, base)
    ok(any(fragment in r for r in reasons), f'{label}: expected "{fragment}" in {reasons}')


# The proposal's own examples pass.
ok(ec.check_record(copy.deepcopy(GOOD)) == ('evidence', []), 'section 3 example is usable')
ok(ec.check_record(copy.deepcopy(MECHANIC)) == ('mechanic', []), 'section 3b example is usable')

# Section 3 rules.
bad(lambda r: r.update(casts=0), 'casts must be', 'casts > 0')
bad(lambda r: r['outputs'][0].update(castsWithDrop=413), 'larger than casts', 'castsWithDrop <= casts')
bad(lambda r: r['outputs'][0].update(totalQuantity=70), 'smaller than castsWithDrop', 'totalQuantity >= castsWithDrop')
bad(lambda r: r['outputs'][0].update(min=3, max=2), 'min is larger than max', 'min <= max')
bad(lambda r: r.update(source='http://example.org'), 'https://', 'source must be https')
bad(lambda r: r.update(input=-5), 'positive whole number', 'input ID positive')
bad(lambda r: r['outputs'][0].update(item=1.5), 'item must be', 'output ID whole')
bad(lambda r: r.update(input=True), 'positive whole number', 'bool is not an item ID')

# Published percentage: with a sample size it is fine; without one casts is null (weak guess).
ok(reasons_for(lambda r: r.update(casts=50, outputs=[{'item': 36917, 'chance': 0.18}])) == [], 'chance + casts usable')
ok(reasons_for(lambda r: r.update(casts=None, outputs=[{'item': 36917, 'chance': 0.18}])) == [], 'chance without sample size usable')
bad(lambda r: r.update(casts=None), 'needs casts', 'counts need casts')
bad(lambda r: r.update(outputs=[{'item': 36917, 'chance': 18}]), 'between 0 and 1', 'chance is a fraction')
bad(lambda r: r['outputs'][0].update(chance=0.18), 'not both', 'counts or chance, not both')
bad(lambda r: r['outputs'][0].pop('castsWithDrop'), 'needs castsWithDrop', 'output needs counts or chance')

# Honest nulls, typos and other shape checks.
bad(lambda r: r.pop('lineage'), 'missing field', 'lineage required')
bad(lambda r: r.update(cast=10), 'unknown field', 'typo is caught')
bad(lambda r: r.update(method='Pickpocket'), 'method must be', 'method list')
bad(lambda r: r.update(stale='no'), 'stale must be', 'stale is true/false')
bad(lambda r: r.update(observedDate='Aug 2025'), 'observedDate', 'date format')
bad(lambda r: r.update(patch='latest'), 'patch must', 'patch format')
bad(lambda r: r.update(skill=40, minimumSkill=50), 'below minimumSkill', 'skill >= minimumSkill')
bad(lambda r: r['stats'].update(mastery=10), 'unknown field', 'stats keys')
bad(lambda r: r.update(outputs=[]), 'non-empty list', 'outputs needed')
bad(lambda r: r['outputs'].append(dict(r['outputs'][0])), 'listed twice', 'no duplicate outputs')
ok(reasons_for(lambda r: r.update(method='Disenchant', input='gear:9:4:armor', inputPerCast=1)) == [], 'gear key for disenchant')
bad(lambda r: r.update(input='gear:9:4:armor'), 'only for Disenchant', 'gear key only for disenchant')
ok(reasons_for(lambda r: [r.pop(k) for k in ('skill', 'minimumSkill', 'stats', 'notes')]) == [], 'optional fields can be left out')

# Mechanics and check records.
bad(lambda r: r.update(metric='luck'), 'metric must be', 'mechanic metric list', MECHANIC)
bad(lambda r: r['numbers'].update(refundShare='about a third'), 'numbers:', 'mechanic numbers are numbers', MECHANIC)
bad(lambda r: r.update(kind='rumour'), 'kind must be', 'unknown kind')
check = {'kind': 'check', 'recordId': 'midnight/a.json#0', 'result': 'confirmed', 'saw': '412 casts, 74 drops'}
ok(ec.check_record(dict(check)) == ('check', []), 'check record usable')
bad(lambda r: r.update(result='looks fine'), 'result must be', 'check result list', check)
bad(lambda r: r.update(recordId='record 3'), 'recordId must', 'check record ID format', check)

# Folder run: usable and set-aside records are both kept in the report; nothing is deleted.
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    (root / 'midnight').mkdir()
    bad_record = dict(GOOD, casts=0)
    good_path = root / 'midnight' / '2026-11-01-ores.json'
    good_path.write_text(json.dumps([GOOD, bad_record, MECHANIC]))
    (root / 'legacy').mkdir()
    (root / 'legacy' / '2026-11-02-checks.json').write_text(json.dumps([
        dict(check, recordId='midnight/2026-11-01-ores.json#0'),
        dict(check, recordId='midnight/2026-11-01-ores.json#1', result='mismatch'),
    ]))
    (root / 'broken.json').write_text('{not json')
    (root / 'QUEUE.md').write_text('# not a record file')
    before = good_path.read_text()
    report = ec.check_folder(root)
    ok(report['files'] == 3, 'only .json files are read')
    ids = {e['id']: e for e in report['usable']}
    ok(set(ids) == {'midnight/2026-11-01-ores.json#0', 'midnight/2026-11-01-ores.json#2',
                    'legacy/2026-11-02-checks.json#0', 'legacy/2026-11-02-checks.json#1'}, 'usable IDs')
    aside = {e['id']: e for e in report['setAside']}
    ok(set(aside) == {'midnight/2026-11-01-ores.json#1', 'broken.json'}, 'set-aside IDs')
    ok('casts must be' in aside['midnight/2026-11-01-ores.json#1']['reasons'][0], 'reason is kept')
    ok('warning' in ids['legacy/2026-11-02-checks.json#1'], 'check on a set-aside record is flagged')
    ok('warning' not in ids['legacy/2026-11-02-checks.json#0'], 'check on a usable record is fine')
    ok(good_path.read_text() == before, 'files are never edited')
    text = ec.summary(report)
    ok(text.startswith('EVIDENCE CHECK: 3 file(s), 4 usable') and '2 set aside' in text, 'summary line')
    with contextlib.redirect_stdout(io.StringIO()):
        codes = (ec.main([str(root)]), ec.main([str(root), '--strict']))
    ok(codes == (0, 1), 'exit status only fails with --strict')

# The real folder (may be empty or missing) can always be checked.
real = ec.check_folder(Path(__file__).resolve().parent.parent / 'research' / 'evidence' / 'v3')
ok(isinstance(real['usable'], list), 'real evidence folder checks without crashing')

print(f'EVIDENCE CHECK TESTS: {passed} passed, 0 failed; real folder: {ec.summary(real).splitlines()[0]}')
