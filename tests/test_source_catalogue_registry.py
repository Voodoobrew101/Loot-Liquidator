"""Pinned catalogue discovery is explicit and never scientific approval."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from source_catalogue_registry import REGISTRY,DEFAULT_CATALOGUE,catalogue_paths

class CatalogueRegistryTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup);self.root=Path(self.tmp.name)
    def write(self,relative,value=None):
        path=self.root/relative;path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(json.dumps(value or {}),encoding='utf8');return path
    def registry(self,entries):self.write(REGISTRY,{'schemaVersion':1,'catalogues':entries})
    def entry(self,path='research/v3/evidence/master/future-review',identity='future',enabled=True):
        return {'catalogueID':identity,'path':path,'enabled':enabled}
    def test_empty_older_snapshot_does_not_require_a_catalogue(self):self.assertEqual(catalogue_paths(self.root),[])
    def test_older_standalone_models_or_manifest_are_retained(self):
        for name in ('admitted-models.json','manifest.json'):
            with self.subTest(name=name):
                p=self.write(DEFAULT_CATALOGUE/name)
                self.assertEqual(catalogue_paths(self.root),[DEFAULT_CATALOGUE]);p.unlink()
    def test_new_registry_discovers_any_undated_evidence_catalogue(self):
        entries=[self.entry('research/v3/evidence/master/future-v2','new'),self.entry('research/v3/evidence/other/later','next')]
        for e in entries:self.write(Path(e['path'])/'manifest.json')
        self.registry(entries)
        self.assertEqual(catalogue_paths(self.root),[Path(e['path']) for e in entries])
    def test_explicit_empty_and_disabled_registry_suppress_legacy_fallback(self):
        self.write(DEFAULT_CATALOGUE/'admitted-models.json');self.registry([])
        self.assertEqual(catalogue_paths(self.root),[])
        self.registry([self.entry(enabled=False)])
        self.assertEqual(catalogue_paths(self.root),[])
    def test_enabled_catalogue_requires_manifest_but_disabled_does_not(self):
        self.registry([self.entry()])
        with self.assertRaisesRegex(ValueError,'manifest.json'):catalogue_paths(self.root)
        self.registry([self.entry(enabled=False)]);self.assertEqual(catalogue_paths(self.root),[])
    def test_duplicate_id_or_path_is_rejected_even_if_disabled(self):
        for entries in ([self.entry(enabled=False),self.entry(identity='different',enabled=False)],
                        [self.entry(enabled=False),self.entry(path='research/v3/evidence/other',enabled=False)]):
            with self.subTest(entries=entries):
                self.registry(entries)
                with self.assertRaisesRegex(ValueError,'Duplicate'):catalogue_paths(self.root)
    def test_absolute_traversal_alias_and_outside_evidence_paths_rejected(self):
        for path in ('/tmp/out','C:/outside','../outside','research/v3/evidence/../outside',
                     'research/v3/evidence//master/a','research/v3/evidence/master/./a',
                     'research/v3/evidence/master/a/','research/v3/tools/a','research/v3/evidence',
                     'research\\v3\\evidence\\master\\a'):
            with self.subTest(path=path):
                self.registry([self.entry(path,enabled=False)])
                with self.assertRaises(ValueError):catalogue_paths(self.root)
    def test_invalid_schema_and_implicit_enabled_state_are_rejected(self):
        for document in ({'schemaVersion':True,'catalogues':[]},{'schemaVersion':2,'catalogues':[]},
                         {'schemaVersion':1,'catalogues':{}}, {'schemaVersion':1,'catalogues':[{'catalogueID':'x','path':'research/v3/evidence/a'}]}):
            with self.subTest(document=document):
                self.write(REGISTRY,document)
                with self.assertRaises(ValueError):catalogue_paths(self.root)
    def test_two_entries_cannot_alias_the_same_physical_catalogue(self):
        primary='research/v3/evidence/master/primary'
        self.write(Path(primary)/'manifest.json')
        alias=self.root/'research/v3/evidence/master/alias'
        try:alias.symlink_to(self.root/primary,target_is_directory=True)
        except OSError:self.skipTest('Host cannot create symlinks')
        self.registry([self.entry(primary,'first'),self.entry('research/v3/evidence/master/alias','second')])
        with self.assertRaisesRegex(ValueError,'Duplicate'):catalogue_paths(self.root)
    def test_catalogue_symlink_cannot_escape_snapshot(self):
        outside=self.root/'outside';outside.mkdir()
        target=self.root/'research/v3/evidence/master/link';target.parent.mkdir(parents=True)
        try:target.symlink_to(outside,target_is_directory=True)
        except OSError:self.skipTest('Host cannot create symlinks')
        self.registry([self.entry('research/v3/evidence/master/link',enabled=False)])
        with self.assertRaisesRegex(ValueError,'escapes'):catalogue_paths(self.root)

if __name__=='__main__':unittest.main()
