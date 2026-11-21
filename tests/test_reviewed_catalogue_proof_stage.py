"""Source fingerprints end before operation aliases and native ID inference.

The fixture preserves the exact52 public rows/108 facts found in the catalogue
regression, plus their original interpreter and file-scoped correction records.
"""
from collections import Counter
from copy import deepcopy
from hashlib import sha256
import json
from pathlib import Path
import sys
import tempfile
import unittest
import warnings
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
import research_v3_to_baselines as bridge
from reviewed_source_catalogue import CATALOGUE,canonical_hash,reviewed_context_facts,source_rows

FIXTURE=Path(__file__).with_name('fixtures')/'catalogue-proof-stage-regression.json'

class ReviewedCatalogueProofStageTests(unittest.TestCase):
    def setUp(self):
        # Preserve the exact legacy interpreter fixture, including its reader.
        warning_scope=warnings.catch_warnings();warning_scope.__enter__()
        self.addCleanup(warning_scope.__exit__,None,None,None)
        warnings.simplefilter('ignore',ResourceWarning)
        self.fixture=json.loads(FIXTURE.read_text(encoding='utf8'))
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        for name,text in self.fixture['files'].items():
            self.assertEqual(sha256(text.encode()).hexdigest(),self.fixture['fileSHA256'][name])
            path=self.root/name;path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(text,encoding='utf8',newline='\n')
        folder=self.root/CATALOGUE;folder.mkdir(parents=True)
        (folder/'admitted-models.json').write_text(json.dumps({'schemaVersion':1,'revision':'proof-regression',
            'models':[],'facts':self.fixture['facts']}),encoding='utf8')
        self.module=bridge.load_calculator(self.root)
    @staticmethod
    def index(rows):return {(r['_file'],r['id']):r for r in rows}
    def locator(self,scope):
        file,line=scope['locator'].rsplit(':',1)
        row=json.loads((self.root/file).read_text(encoding='utf8').splitlines()[int(line)-1])
        return (file,row['id']),row
    def test_all52_correction_fingerprints_are_before_derived_inference(self):
        proof=self.index(self.module.load_reviewed_source_rows())
        numeric=self.index(bridge.resolve_ranked_outputs(bridge.preserve_reference_range(self.module.load())))
        changes=Counter()
        self.assertEqual(len(self.fixture['scopes']),52)
        for scope in self.fixture['scopes']:
            k,raw=self.locator(scope)
            self.assertEqual(canonical_hash(raw),scope['expectedSHA256'])
            self.assertEqual(canonical_hash(proof[k]),scope['expectedEffectiveSHA256'])
            self.assertNotEqual(canonical_hash(numeric[k]),scope['expectedEffectiveSHA256'])
            if proof[k]['method']!=numeric[k]['method']:
                changes['operationAliases']+=1
                self.assertEqual((proof[k]['method'],numeric[k]['method']),('Disenchant','Craft'))
            else:
                changes['nativeOutputIDs']+=1
                self.assertNotEqual(proof[k].get('outputItemID'),numeric[k].get('outputItemID'))
            for count in ('casts','castsWithDrop','totalQuantity','inputsProcessed','inputsPerCast'):
                self.assertEqual(proof[k].get(count),numeric[k].get(count),'derived identity must not rewrite source counters')
        self.assertEqual(changes,{'nativeOutputIDs':47,'operationAliases':5})
    def test_all108_facts_reach_consumer_despite_derived_identity_changes(self):
        facts=reviewed_context_facts(self.root)['facts']
        self.assertEqual(len(facts),108)
        self.assertEqual({f['factID'] for f in facts},{f['factID'] for f in self.fixture['facts']})
        numeric=self.index(bridge.resolve_ranked_outputs(bridge.preserve_reference_range(self.module.load())))
        # Reproduce the previous failure: these are not source fingerprints.
        for fact in self.fixture['facts']:
            checked,reason=source_rows(self.root,fact['sourceRows'],effective=numeric)
            self.assertIsNone(checked)
            self.assertEqual(reason,'reviewed source correction layer changed')
    def test_genuine_append_only_source_correction_expires_exact_affected_facts(self):
        target=self.fixture['scopes'][0];k,raw=self.locator(target)
        before={f['factID'] for f in reviewed_context_facts(self.root)['facts']}
        affected={f['factID'] for f in self.fixture['facts'] if any(
            r.get('sourceFile')==k[0] and r.get('sourceRecordID')==k[1] for r in f['sourceRows'])}
        self.assertTrue(affected);self.assertLess(len(affected),len(before))
        correction={'recordID':k[1],'file':k[0],'field':'specialization','value':'Changed specialization context in regression fixture',
            'reason':'Regression demonstrates that real source corrections still expire scoped review receipts.'}
        with (self.root/'research/v3/corrections.jsonl').open('a',encoding='utf8')as stream:
            stream.write(json.dumps(correction)+'\n')
        after={f['factID'] for f in reviewed_context_facts(self.root)['facts']}
        self.assertEqual(after,before-affected)
        current=self.index(bridge.load_calculator(self.root).load_reviewed_source_rows())
        self.assertNotEqual(canonical_hash(current[k]),target['expectedEffectiveSHA256'])
        self.assertEqual(canonical_hash(self.locator(target)[1]),target['expectedSHA256'],'immutable raw evidence unchanged')

if __name__=='__main__':unittest.main()
