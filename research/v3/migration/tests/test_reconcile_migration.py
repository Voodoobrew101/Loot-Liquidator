"""Safety checks for the read-only-by-default migration regeneration helper."""
import importlib.util
import pathlib
import unittest
from unittest import mock

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "tools" / "reconcile_migration.py"
spec = importlib.util.spec_from_file_location("reconcile_migration", SCRIPT)
rm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rm)


class MigrationReconcileSafety(unittest.TestCase):
    def test_plan_is_read_only(self):
        with mock.patch.object(rm, "run", side_effect=AssertionError("must not run")), \
             mock.patch.object(rm, "clean_branch", side_effect=AssertionError("must not inspect branch")):
            self.assertEqual(rm.main([]), 0)

    def test_protected_and_dirty_branches_are_refused(self):
        with mock.patch.object(rm, "git", side_effect=["main"]):
            with self.assertRaisesRegex(RuntimeError, "protected"):
                rm.clean_branch()
        with mock.patch.object(rm, "git", side_effect=["research/isolated", " M research/v3/queue.json"]):
            with self.assertRaisesRegex(RuntimeError, "not clean"):
                rm.clean_branch()

    def test_rejects_changes_to_original_worker_evidence(self):
        with mock.patch.object(rm, "git", return_value=" M research/v3/evidence/midnight/original.jsonl"):
            with self.assertRaisesRegex(RuntimeError, "unexpected path"):
                rm.changes()

    def test_reports_only_derived_paths(self):
        with mock.patch.object(rm, "git", return_value=" M research/v3/migration/manifest/links.jsonl\n?? research/v3/migration/reports/new.json"):
            self.assertEqual(rm.changes(), ["research/v3/migration/manifest/links.jsonl", "research/v3/migration/reports/new.json"])

    def test_derived_outputs_only(self):
        self.assertFalse(any("evidence/midnight" in prefix for prefix in rm.ALLOWED))
        self.assertTrue(any("evidence/imported" in prefix for prefix in rm.ALLOWED))


if __name__ == "__main__":
    unittest.main()
