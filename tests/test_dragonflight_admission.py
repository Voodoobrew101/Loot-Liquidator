"""One held cohort, two transcriptions; global reviewed identities, not item bans."""
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode = True
sys.path.insert(0, 'tools')
import research_v3_to_baselines as v3
SNAPSHOT = Path('database/research/v3-snapshot')
FIXTURE = Path('tests/fixtures/dragonflight-admission')
IDS = ['dragonflight-20261108-840011', 'dragonflight-20261109-204001']
HASHES = {'pdpaul-earlier-file.jsonl':'b06661f77ed0acf91d2a304fd1d99d6e53bc8831b45458c382759bfa353fe99c',
          'pdpaul-new.jsonl':'6e5c8014d45241c0eba0bed840a8751aa1050c12a0f18f8b6147ee753025fca9'}

def rows(all_rows=False):
    out=[]
    for file,digest in HASHES.items():
        raw=(FIXTURE/file).read_bytes()
        if hashlib.sha256(raw).hexdigest()!=digest: raise ValueError('Immutable source changed')
        out += [dict(json.loads(line), _file=file) for line in raw.decode().splitlines() if line.strip()]
    return out if all_rows else [r for r in out if r['id'] in IDS]

def build(data, bypass=False, observe=None):
    module=v3.load_calculator(SNAPSHOT)
    original=module.build
    def checked(data):
        if observe is not None: observe.append(copy.deepcopy(data))
        return original(data)
    with patch.object(module,'load',return_value=data), patch.object(module,'build',side_effect=checked), patch.object(v3,'load_calculator',return_value=module):
        if bypass:
            with patch.object(v3,'retail_admission',side_effect=lambda rs:(rs,{})): return v3.build(SNAPSHOT)
        return v3.build(SNAPSHOT)

class DragonflightAdmissionTests(unittest.TestCase):
    def test_source_identity(self):
        source=rows()
        self.assertEqual([r['id'] for r in source],IDS)
        self.assertEqual(len(rows(True)),12)
        for r in source:
            self.assertEqual((r['casts'],r['totalQuantity'],r['outputItemID']),(10,25,194123))
            self.assertIsNone(r['inputItemID']);self.assertIsNone(r['castsWithDrop'])
            self.assertIn('Draconic Disenchantment maxed',r['specialization'])
            self.assertIsNone(r['replaces'])

    def test_original_admission_and_new_only_noop(self):
        original=build(rows(),True)[0]
        self.assertEqual(original,build(rows()[:1],True)[0])
        self.assertEqual(len(original),1)
        self.assertEqual(original[0]['gearKey'],'gear:9:2:weapon')
        self.assertEqual(original[0]['materials'][0]['expectedQuantity']['value'],2.5)
        self.assertEqual(build(rows())[0],[])

    def test_each_identity_global_and_renamed_copy(self):
        for source in rows():
            for changed in ('id','studyKey','_file'):
                r=copy.deepcopy(source);r[changed]='renamed-independent-label'
                self.assertEqual(v3.retail_admission([r])[0],[])
            # Both identifiers changed is a distinct review identity, regardless of URL/text/material.
            control=dict(source,id='independent',studyKey='independent',_file='elsewhere')
            self.assertEqual(v3.retail_admission([control])[0],[control])
            reused=dict(control,id=source['id'])
            self.assertEqual(v3.retail_admission([reused])[0],[]) # global ID contract

    def test_pre_range_pre_count_and_no_leakage(self):
        source=rows(); control=copy.deepcopy(source[0])
        control.update(id='independent',studyKey='independent',casts=7,totalQuantity=14,minSeen=1,maxSeen=2)
        control['source']['url']='https://example.invalid/independent-synthetic-test'
        for r in source:
            r.update(minSeen=50,maxSeen=100,totalQuantity=9000)
        before=copy.deepcopy(source+[control]);calls=[]
        actual=build(source+[control],observe=calls)[0]
        self.assertEqual(actual,build([control])[0])
        self.assertEqual(calls,[[control],[control]])
        self.assertEqual(source+[control],before)
        self.assertEqual(actual[0]['materials'][0]['expectedQuantity']['value'],2)

    def test_source_kind_does_not_bypass_hold(self):
        for kind in ('study','reference','tsm-table','compiled-research',None):
            source=rows()
            for r in source:r['sourceKind']=kind
            calls=[];self.assertEqual(build(source,observe=calls)[0],[])
            self.assertEqual(calls,[[],[]])

    def test_independent_same_material_and_unrelated_rows_preserved(self):
        source=rows(True)
        expected=[r for r in source if r['id'] not in IDS]
        actual=build(source)[0]
        self.assertEqual(actual,build(expected)[0])
        self.assertGreater(len(actual),0)
        admitted,notes=v3.retail_admission(source)
        self.assertEqual(admitted,expected);self.assertEqual(sum(notes.values()),2)

    def test_replacement_retaining_study_identity_held(self):
        source=rows()
        for r in source:
            replacement=dict(r,id='replacement',replaces=r['id'])
            self.assertEqual(v3.retail_admission([replacement])[0],[])
            different=dict(replacement,studyKey='new-review-identity')
            self.assertEqual(v3.retail_admission([different])[0],[different])

    def test_loader_replacement_precedes_admission_documented_limit(self):
        module=v3.load_calculator(SNAPSHOT)
        control=dict(rows()[0],id='independent',studyKey='independent')
        replacement=dict(rows()[1],replaces='independent')
        with tempfile.TemporaryDirectory(prefix='ll-df-admission-') as tmp:
            root=Path(tmp);evidence=root/'evidence';evidence.mkdir()
            (evidence/'fixture.jsonl').write_text('\n'.join(json.dumps(r) for r in [control,replacement])+'\n')
            with patch.object(module,'EVIDENCE',str(evidence)),patch.object(module,'ROOT',str(root)):
                loaded=module.load()
        self.assertEqual([r['id'] for r in loaded],[replacement['id']])
        self.assertEqual(v3.retail_admission(loaded)[0],[])
        # No claim that the policy restores the independently replaced row.

    def test_classic_hold_unchanged(self):
        original=[json.loads(s) for s in Path('tests/fixtures/retail-admission/mop-looter.jsonl').read_text().splitlines()]
        self.assertEqual(v3.retail_admission(original)[0],[])

if __name__=='__main__': unittest.main()
