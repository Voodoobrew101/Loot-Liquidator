import importlib.util
import json
from pathlib import Path
import sys
import tempfile

spec = importlib.util.spec_from_file_location('token_import', 'tools/import_token_research.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
runtime = Path(sys.argv[1]) / 'att-runtime-export.json'
data = json.loads(runtime.read_text())
assert data['records'] and data['completeUniverse'] is False
fresh = next(r for r in data['records'] if r['tokenID'] == 900003)
assert fresh['provenance']['note'] == 'quote " backslash \\ newline\n雪'
assert fresh['details'][0]['cost'][0] == ['i', 900003, 2]
gear = next(r for r in data['records'] if r['tokenID'] == 268226)
assert gear['itemMetadata']['contexts'][0][1]['difficultyID'] == 2
assert 'collected' not in gear['itemMetadata']['contexts'][0][0]
staged = module.stage([runtime])
assert staged['coverage']['removalReady'] is False
assert 900005 in staged['coverage']['cappedTokenIDs']
assert 900004 in staged['coverage']['unresolvedTokenIDs']
assert 268226 in staged['coverage']['unresolvedTokenIDs']  # source preserved; latest lookup unresolved
assert any(s['raw'].get('itemMetadata') for s in staged['snapshots'])
assert all(c['runtimeEligible'] is False and c['rewardQuantity'] is None for c in staged['candidates'])
assert any(s['raw'].get('details') for s in staged['snapshots'])
with tempfile.TemporaryDirectory() as folder:
    root = Path(folder)
    path = root / 'direct.txt'
    path.write_text('# existing direct-token format\nkind|inputID|inputQty|rewardID|rewardQty|vendorID|otherCosts|observations|lastSeen\n'
        'merchant|900100|2|900101|1|5|currency:10:50|9|100\n'
        'att_open_candidate|900200|1|900201|1||Unverified ATT cache|8|100\n')
    result = module.stage([runtime, path])
    direct = next(c for c in result['candidates'] if c['tokenID'] == 900100)
    legacy = next(c for c in result['candidates'] if c['tokenID'] == 900200)
    assert direct['inputQuantity'] == 2 and direct['sourceKind'] == 'DIRECT_CLIENT'
    assert legacy['inputQuantity'] is None and legacy['sourceKind'] == 'ATT_LEGACY_CACHE'
    # Repeated sightings/imports are not samples, approvals or output yields.
    assert len(module.stage([path, path])['candidates']) == 2
    partial = dict(data, page=1, pages=2)
    p = root / 'partial.json'
    p.write_text(json.dumps(partial))
    assert module.stage([p])['coverage']['missingPages'] == [{'pages': 2, 'page': 2}]
    p.write_text(json.dumps(dict(data, automaticApproval=True)))
    try:
        module.stage([p])
    except ValueError:
        pass
    else:
        raise AssertionError('must reject a claimed automatic approval')
print('PASS: actual Lua JSON export roundtrip, original metadata/costs, candidate-only imports, legacy quantity placeholders and incomplete coverage')
