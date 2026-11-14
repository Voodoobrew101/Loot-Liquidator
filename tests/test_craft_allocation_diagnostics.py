"""Portable JSON/zlib checks for the actual Lua-generated diagnostic payload."""
import base64
import importlib.util
import json
from pathlib import Path
import unittest
import zlib

spec = importlib.util.spec_from_file_location('validator', 'tools/validate_craft_export.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


class DiagnosticTransport(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = Path('/tmp/loot-craft-allocation-diagnostics.json').read_bytes()
        cls.page = json.loads(cls.raw)

    def test_real_zlib_transport_preserves_every_field(self):
        # Portable codec only. This does not simulate WoW's native codec/client.
        packed = dict(schemaVersion='loot-liquidator.cast-transfer/1',
                      encoding='zlib-base64', uncompressedBytes=len(self.raw),
                      payload=base64.b64encode(zlib.compress(self.raw)).decode())
        self.assertEqual(validator.unpack_transfer(packed), self.page)
        self.assertFalse(self.page['automaticMechanicsPromotion'])

    def test_bounded_allowlist_and_unknown_fields(self):
        for diagnostic in self.page['diagnostics']:
            detail = diagnostic['craftAllocation']
            self.assertLess(len(json.dumps(detail, separators=(',', ':'))), 32768)
            self.assertEqual(set(detail) - {'version', 'requestState', 'allocation', 'schematic', 'failure'}, set())
            for item in detail['allocation'].get('allocationEntries', []):
                self.assertNotIn('unknown', item)
            self.assertLessEqual(len(detail['allocation'].get('allocationEntries', [])), 16)
            for slot in detail['schematic'].get('slots', {}).get('schematicSlots', []):
                self.assertLessEqual(len(slot.get('reagents', {}).get('allowedReagents', [])), 8)
        self.assertNotIn(b'PRIVATE', self.raw)
        self.assertNotIn(b'do-not-store-me', self.raw)

    def test_empty_arrays_and_deepest_fields_survive(self):
        empty = [d for d in self.page['diagnostics']
                 if d['craftAllocation']['allocation'].get('allocationEntries') == []]
        self.assertTrue(empty)
        bounded = next(d['craftAllocation'] for d in self.page['diagnostics']
                       if d['craftAllocation']['allocation'].get('truncated'))
        self.assertEqual(bounded['schematic']['slots']['schematicSlots'][0]
                         ['reagents']['allowedReagents'][0]['itemID'], 11)
        for record in self.page['records']:
            self.assertNotIn('craftAllocation', record)


if __name__ == '__main__':
    unittest.main()
