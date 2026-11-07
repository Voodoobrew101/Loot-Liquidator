"""Cross-check the copy widget's exact JSON with real portable zlib/base64."""
import base64
import copy
import importlib.util
import json
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
