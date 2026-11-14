"""Replay exact historical sources through generator, compiler and redemption cost."""
import json
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import research_v3_tokens as tokens
from evidence_to_baselines import lua

lua_bin = sys.argv[1]
fixture = ROOT / 'tests/fixtures/token-source-applicability'
snapshot = ROOT / 'database/research/v3-snapshot'
revision = json.loads((snapshot / 'SNAPSHOT.json').read_text())['commit']
rows = tokens.load_rows(snapshot)
held_ids = {rid for rule in json.loads((ROOT / 'database/research/token-admission.json').read_text())['exclusions'] for rid in rule['recordIDs']}
rows += [r for r in tokens.load_rows(fixture) if r['id'] in held_ids]
with patch.object(tokens, 'load_rows', return_value=rows):
    guarded = tokens.build_tokens(snapshot, revision)[0]
    with patch.object(tokens, 'token_admission', side_effect=lambda rows: (rows, Counter())):
        original = tokens.build_tokens(snapshot, revision)[0]

with tempfile.TemporaryDirectory(prefix='ll-token-epoch-') as folder:
    folder = Path(folder)
    compiled = {}
    for label, records in [('guarded', guarded), ('original', original)]:
        baseline = folder / (label + '.lua')
        baseline.write_text("local b=assert(loadfile('database/research-v3-baselines.lua'))(); b.tokenRewards=" + lua(records) + '; return b\n')
        out = folder / (label + '-compiled.lua')
        subprocess.run([lua_bin, 'tools/compile_itemdb.lua', str(out), 'database/evidence-baselines.lua', str(baseline), 'database/disenchant-category-baselines.lua'], cwd=ROOT, check=True, capture_output=True)
        compiled[label] = out
    # A future refresh containing ONLY these held rows must not change any byte
    # of today's compiled database, including all 307 tokens and ATT class masks.
    if compiled['guarded'].read_bytes() != (ROOT / 'LootLiquidator/ItemDBRuntime.lua').read_bytes():
        raise AssertionError('Guarded exact-source fixture changed compiled database')
    subprocess.run([lua_bin, 'tests/test_token_source_runtime.lua', str(compiled['guarded']), str(compiled['original'])], cwd=ROOT, check=True)
print('TOKEN SOURCE COMPILER: unchanged compiled bytes; all three original regressions reproduced')
