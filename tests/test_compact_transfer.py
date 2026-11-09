"""Cross-check the copy widget's exact JSON with real portable zlib/base64."""
import base64
import copy
import importlib.util
import json
import hashlib
from pathlib import Path
import unittest
import zlib

spec = importlib.util.spec_from_file_location('export_validator', 'tools/validate_craft_export.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)
raw = Path('/tmp/loot-latest-batch.json').read_bytes()
data = json.loads(raw)
binary = zlib.compress(raw, 9)
encoded = base64.b64encode(binary).decode('ascii')
transfer = {'schemaVersion': 'loot-liquidator.cast-transfer/1', 'encoding': 'zlib-base64',
            'uncompressedBytes': len(raw), 'payload': encoded}
wire = json.dumps(transfer, separators=(',', ':'), sort_keys=True)
Path('/tmp/loot-transfer-zlib.bin').write_bytes(binary)
Path('/tmp/loot-transfer-base64.txt').write_text(encoded)
Path('/tmp/loot-transfer-wire.json').write_text(wire)


class CompactTransferTests(unittest.TestCase):
    def test_live_pr49_transfer_and_operator_count_review(self):
        folder = Path('research/integration/measured-captures/2026-11-07-pr49-20-cast-check')
        source = (folder / 'export-page-1.json').read_bytes()
        packet_bytes = (folder / 'compact-export.json').read_bytes()
        original = json.loads(source)
        self.assertEqual(validator.unpack_transfer(json.loads(packet_bytes)), original)
        review = json.loads((folder / 'coverage-review.json').read_text())
        self.assertEqual(review['sourceDecodedSHA256'], hashlib.sha256(source).hexdigest())
        self.assertEqual(review['sourceWireSHA256'], hashlib.sha256(packet_bytes).hexdigest())
        self.assertEqual(review['operatorConfirmedAttemptCount'], 20)
        self.assertTrue(review['operatorConfirmedNoInterruptedOrFailedDisenchants'])
        self.assertEqual(set(review['sourceRecordIDs']), {r['operationID'] for r in original['records']})
        self.assertEqual(len(review['sourceRecordIDs']), 20)
        self.assertTrue(all(r['castStartSeen'] and r['outputCoverage']=='complete' and r['recorderRevision']==4
                            and r['method']=='Disenchant' and r['recipeID']==13262 for r in original['records']))
        self.assertFalse(validator.compile_baselines([original])['baselines'], 'raw global flag is preserved')
        subset = json.loads((folder / 'reviewed-disenchant-subset.json').read_text())
        self.assertEqual(subset['records'], original['records'])
        self.assertEqual(subset['contexts'], original['contexts'])
        self.assertEqual(subset['diagnostics'], original['diagnostics'])
        expected_studies = copy.deepcopy(original['studies'])
        expected_studies[original['exportStudyID']].pop('globalCoverageGap')
        self.assertEqual(subset['studies'], expected_studies)
        reviewed = validator.compile_baselines([subset])
        self.assertEqual(sum(b['operations'] for b in reviewed['baselines']), 20)
        self.assertFalse(reviewed['excludedCohorts'])
        self.assertFalse(review['runtimePromotion'])

    def test_exact_latest_batch_roundtrip_and_validation(self):
        self.assertLess(len(wire), 65536)
        self.assertEqual(validator.unpack_transfer(transfer), data)
        self.assertEqual(validator.validate([transfer]), validator.validate([data]))
        self.assertEqual(validator.compile_baselines([transfer]), validator.compile_baselines([data]))
        self.assertEqual(len(data['records']), 169)
        self.assertEqual(data['totalRetainedRecords'], 683)
        self.assertEqual(len(data['diagnostics']), 50)
        self.assertTrue(data['studies'][data['exportStudyID']]['coverageGaps']['Disenchant:13262'])

    def test_raw_exports_are_still_supported(self):
        self.assertIs(validator.unpack_transfer(data), data)

    def test_corruption_missing_codec_and_malformed_lengths_fail_closed(self):
        changes = [
            {'encoding': 'unknown'}, {'uncompressedBytes': -1},
            {'uncompressedBytes': 16777217}, {'uncompressedBytes': len(raw)-1},
            {'uncompressedBytes': len(raw)+1}, {'payload': 'not base64!'},
            {'payload': encoded[:-4]}, {'payload': base64.b64encode(binary+b'extra').decode()},
            {'payload': base64.b64encode(zlib.compress(b'{broken')).decode()},
        ]
        for change in changes:
            with self.subTest(change=list(change)):
                damaged = copy.deepcopy(transfer);damaged.update(change)
                with self.assertRaises(ValueError): validator.unpack_transfer(damaged)


if __name__ == '__main__':
    print(f'Compact latest batch: {len(raw)} JSON bytes -> {len(wire)} copy bytes; 169 records, 50 diagnostics retained')
    unittest.main()
