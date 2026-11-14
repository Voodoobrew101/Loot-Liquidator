"""Hold three reviewed aliases, not original cohorts or valid range enrichment."""
import copy
import hashlib
import itertools
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
FIXTURE = Path('tests/fixtures/legacy-cohort-admission')
IDS = {'legacy-20261110-24701', 'legacy-20261110-24703', 'legacy-20261110-24704'}
KEYS = {'wowhead-gee-comment-930224-14-headband-8-units', 'wowhead-looter-186057-7-cumulative-tbc-wotlk-mirror'}
POLICY = Path('database/research/retail-admission.json')

def rows():
    source = json.loads((FIXTURE/'SOURCES.json').read_text())
    out = []
    for name, info in source['files'].items():
        raw = (FIXTURE/name).read_bytes()
        if hashlib.sha256(raw).hexdigest() != info['sha256']:
            raise ValueError('Immutable source changed: '+name)
        out += [dict(json.loads(s), _file=info['path']) for s in raw.decode().splitlines() if s.strip()]
    return out

def build(data, bypass=False, observe=None):
    mod = v3.load_calculator(SNAPSHOT)
    original = mod.build
    def checked(rr):
        if observe is not None: observe.append(copy.deepcopy(rr))
        return original(rr)
    with patch.object(mod, 'load', return_value=data), patch.object(mod, 'build', side_effect=checked), patch.object(v3, 'load_calculator', return_value=mod):
        if bypass:
            with patch.object(v3, 'retail_admission', side_effect=lambda rr:(rr, {})): return v3.build(SNAPSHOT)[0]
        return v3.build(SNAPSHOT)[0]

def material(records, item, output):
    return next(m for r in records if r.get('inputItemID') == item for m in r['materials'] if m['id'] == output)

class LegacyCohortAdmissionTests(unittest.TestCase):
    def test_immutable_source_identity_and_distinct_enrichment(self):
        rr=rows(); bad=[r for r in rr if r['id'] in IDS]
        self.assertEqual(len(bad),3);self.assertEqual({r['studyKey'] for r in bad},KEYS)
        self.assertTrue(all(r.get('replaces') is None for r in rr))
        r=next(r for r in rr if r['id']=='legacy-20261110-24701')
        self.assertEqual((r['casts'],r['totalQuantity']),(14,8));self.assertIn('made 14',r['quote'])
        good=next(r for r in rr if r['id']=='legacy-20261110-24702')
        self.assertNotIn(good['studyKey'],KEYS)
        self.assertEqual((good['casts'],good['castsWithDrop'],good['totalQuantity'],good['minSeen'],good['maxSeen']),(None,1,2,2,2))

    def test_original_policy_regression_and_exact_preservation(self):
        rr=rows(); expected=[r for r in rr if r['id'] not in IDS]
        kept,notes=v3.retail_admission(rr)
        self.assertEqual(kept,expected);self.assertEqual(sum(notes.values()),3)
        self.assertEqual(build(rr),build(expected,True))
        self.assertNotEqual(build(rr),build(rr,True))

    def test_false_crafted_denominator_removed_not_invented(self):
        rr=[r for r in rows() if r.get('inputItemID')==13866]
        control=copy.deepcopy(rr[0]);control.update(id='independent',studyKey='independent',casts=10,totalQuantity=5,castsWithDrop=1,minSeen=None,maxSeen=None)
        control['source']['url']='https://example.invalid/independent-completed-casts'
        before=material(build(rr+[control],True),13866,16203)
        after=material(build(rr+[control]),13866,16203)
        self.assertEqual(before['expectedQuantity']['samples'],12)
        self.assertEqual(after['expectedQuantity']['samples'],5)
        self.assertEqual(after['expectedQuantity']['value'],.5)
        self.assertEqual(before['minQuantity'],after['minQuantity'])
        self.assertEqual(after['minQuantity']['value'],2)
        # No synthetic completed denominator for the retained original author.
        originals=[r for r in rr if r['id'] not in IDS]
        self.assertTrue(all(r['casts'] is None for r in originals))

    def test_same_estimate_repeat_and_quantity_status(self):
        rr=[r for r in rows() if r.get('inputItemID')==186057]
        before=build(rr,True);after=build(rr)
        for output in (11176,16202):
            b=material(before,186057,output);a=material(after,186057,output)
            self.assertEqual((b['dropChance']['samples'],a['dropChance']['samples']),(7,3.5))
            self.assertEqual(b['dropChance']['value'],a['dropChance']['value'])
            self.assertLess(a['dropChance']['confidence'],b['dropChance']['confidence'])
        b=material(before,186057,11176);a=material(after,186057,11176)
        self.assertEqual(b['expectedQuantity']['status'],'measured')
        self.assertEqual(a['expectedQuantity']['status'],'provisional')
        self.assertAlmostEqual(b['expectedQuantity']['value'],a['expectedQuantity']['value'])
        self.assertEqual(a['expectedQuantity']['samples'],3.5)

    def test_id_or_key_global_aliases_and_unrelated_control(self):
        for source in [r for r in rows() if r['id'] in IDS]:
            for change in ('id','studyKey','_file'):
                r=dict(source);r[change]='independent-label'
                self.assertEqual(v3.retail_admission([r])[0],[])
            independent=dict(source,id='independent',studyKey='independent',_file='elsewhere')
            self.assertEqual(v3.retail_admission([independent])[0],[independent])
            self.assertEqual(v3.retail_admission([dict(independent,id=source['id'])])[0],[])

    def test_before_both_passes_even_reference_kinds(self):
        sources=[r for r in rows() if r['id'] in IDS]
        control=copy.deepcopy(sources[0]);control.update(id='independent',studyKey='independent',casts=10,totalQuantity=5,minSeen=1,maxSeen=2)
        control['source']['url']='https://example.invalid/control'
        for kind in ('study','reference','tsm-table','compiled-research',None):
            held=[dict(r,sourceKind=kind,minSeen=50,maxSeen=100,totalQuantity=9000) for r in sources]
            data=held+[control];before=copy.deepcopy(data);calls=[]
            self.assertEqual(build(data,observe=calls),build([control]))
            self.assertEqual(calls,[[control],[control]]);self.assertEqual(data,before)

    def test_policy_order_permutations_preserve_other_holds(self):
        policy=json.loads(POLICY.read_text());rr=rows()
        # One synthetic probe for every pre-existing hold, without coupling rule positions.
        for rule in policy['exclusions']:
            rr.append({'id':rule['recordIDs'][0],'studyKey':'unrelated','type':'drop'})
        expected=v3.retail_admission(rr)
        original=Path.read_text
        for rules in itertools.permutations(policy['exclusions']):
            def read(path,*a,**kw):
                if path.resolve()==POLICY.resolve():return json.dumps(dict(policy,exclusions=list(rules)))
                return original(path,*a,**kw)
            with patch.object(Path,'read_text',read):self.assertEqual(v3.retail_admission(rr),expected)

    def test_loader_corrections_before_gate_and_replacement_limit(self):
        mod=v3.load_calculator(SNAPSHOT);source=next(r for r in rows() if r['id']=='legacy-20261110-24701')
        with tempfile.TemporaryDirectory(prefix='ll-legacy-admission-') as tmp:
            root=Path(tmp);ev=root/'research/v3/evidence';ev.mkdir(parents=True)
            (ev/'rows.jsonl').write_text(json.dumps(source)+'\n')
            fixes=root/'research/v3/corrections.jsonl'
            fixes.write_text(json.dumps({'recordID':source['id'],'field':'casts','value':None})+'\n')
            with patch.object(mod,'ROOT',str(root)),patch.object(mod,'EVIDENCE',str(ev)):
                loaded=mod.load();self.assertIsNone(loaded[0]['casts']);self.assertTrue(loaded[0]['_corrected'])
                self.assertEqual(v3.retail_admission(loaded)[0],[])
                # Loader replacement runs first; gate does not restore an independent replaced row.
                independent=dict(source,id='independent',studyKey='independent')
                replacement=dict(source,replaces='independent')
                (ev/'rows.jsonl').write_text('\n'.join(map(json.dumps,[independent,replacement]))+'\n')
                loaded=mod.load();self.assertEqual([r['id'] for r in loaded],[source['id']])
                self.assertEqual(v3.retail_admission(loaded)[0],[])

    def test_24702_24705_originals_and_unrelated_rows_survive(self):
        rr=rows();kept,_=v3.retail_admission(rr);keptids={r['id'] for r in kept}
        for ident in ('legacy-20261110-24702','legacy-20261110-24705','legacy-20261106-004101','legacy-20261106-004102','legacy-20261106-601','legacy-20261106-602'):
            self.assertIn(ident,keptids)
        self.assertEqual([r for r in rr if r['id'] not in IDS],kept)

if __name__=='__main__':unittest.main()
