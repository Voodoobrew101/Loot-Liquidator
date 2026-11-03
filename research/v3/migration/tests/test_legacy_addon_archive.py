"""The consolidated addon must coexist with reproducible historical research inputs."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "research/v3/tools"))
import import_existing as importer


class LegacyAddonArchive(unittest.TestCase):
    def test_archive_is_identical_to_reviewed_original_git_blobs(self):
        archive = ROOT / "research/legacy-addon-v0.9.70"
        provenance = json.loads((archive / "PROVENANCE.json").read_text(encoding="utf-8"))
        self.assertEqual(set(provenance["files"]), {"GameData.lua", "StatYieldProfiles.lua", "ResearchDB.lua"})
        for name, info in provenance["files"].items():
            raw = (archive / name).read_bytes()
            original = subprocess.check_output(["git", "show", provenance["sourceCommit"] + ":" + info["originalPath"]], cwd=ROOT)
            self.assertEqual(raw, original, name)
            self.assertEqual(hashlib.sha256(raw).hexdigest(), info["sha256"])

    def test_importer_uses_archive_and_records_its_actual_provenance(self):
        expected = "research/legacy-addon-v0.9.70/GameData.lua"
        self.assertEqual(importer.gamedata_source(), expected)
        disenchant, recipes, tokens = importer.import_gamedata()
        self.assertEqual((len(disenchant), len(recipes), len(tokens)), (52, 8, 1))
        for row in disenchant + recipes + tokens:
            self.assertEqual(row["migratedFrom"]["path"], expected)
        self.assertFalse((ROOT / "GameData.lua").exists())


if __name__ == "__main__":
    unittest.main()
