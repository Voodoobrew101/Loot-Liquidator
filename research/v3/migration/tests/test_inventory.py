#!/usr/bin/env python3
"""Tests for research/v3/migration/tools/inventory.py (M01).

Run from the repository root:
  python3 -m unittest discover -s research/v3/migration/tests -v
"""
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tools"))
import inventory as inv  # noqa: E402


def write(root, rel, text):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


class NormalizeURL(unittest.TestCase):
    def test_reddit_variants_collapse(self):
        a = inv.normalize_url("https://www.reddit.com/r/woweconomy/comments/1f83cnd/aqirite_results/")
        b = inv.normalize_url("https://old.reddit.com/r/woweconomy/comments/1f83cnd")
        self.assertEqual(a, b)
        self.assertEqual(a, "reddit:1f83cnd")

    def test_reddit_comment_kept_distinct(self):
        post = inv.normalize_url("https://www.reddit.com/r/wow/comments/abc123/x/")
        comment = inv.normalize_url("https://www.reddit.com/r/wow/comments/abc123/x/def456/")
        self.assertNotEqual(post, comment)

    def test_wowhead_slug_dropped_comment_kept(self):
        a = inv.normalize_url("https://www.wowhead.com/item=52987/twilight-jasmine")
        b = inv.normalize_url("https://wowhead.com/item=52987")
        c = inv.normalize_url("https://www.wowhead.com/item=52987/twilight-jasmine#comments:id=12345")
        self.assertEqual(a, b)
        self.assertNotEqual(a, c)
        self.assertTrue(c.endswith("#c12345"))

    def test_wowhead_flavour_kept(self):
        self.assertNotEqual(inv.normalize_url("https://www.wowhead.com/wotlk/item=36912"),
                            inv.normalize_url("https://www.wowhead.com/item=36912"))

    def test_forum_thread_id(self):
        self.assertEqual(inv.normalize_url("https://us.forums.blizzard.com/en/wow/t/prospecting-needs-buff/2280780"),
                         "blizzforum:2280780")

    def test_trailing_punctuation(self):
        self.assertEqual(inv.normalize_url("https://warcraft.wiki.gg/wiki/Prospect)."),
                         inv.normalize_url("https://warcraft.wiki.gg/wiki/Prospect"))


class InventoryRun(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        r = self.root
        # v3 evidence citing one Reddit study, and an import note naming an old file
        write(r, "research/v3/evidence/w/a.jsonl", json.dumps({
            "id": "w-1", "type": "drop", "studyKey": "S-1",
            "source": {"url": "https://www.reddit.com/r/woweconomy/comments/aaa111/x/"},
            "originalSource": None, "notes": "Imported from research/evidence/observations/old.jsonl; x"}) + "\n")
        # imported old observation
        write(r, "research/evidence/observations/old.jsonl", json.dumps({
            "observationID": "S-1", "processing": {"completedOperations": 10},
            "outputs": [{"totalUnits": 3}], "source": {"url": "https://reddit.com/r/woweconomy/comments/aaa111"}}) + "\n")
        # markdown note with a new study URL and numeric claim
        write(r, "research/evidence/observations/note.md",
              "Original 104 casts of herbs: https://www.wowhead.com/item=1/x#comments:id=9\n")
        # markdown covered by URL already in v3
        write(r, "research/coordination/reviews/rev.md",
              "Checked 1,000 ore at https://old.reddit.com/r/woweconomy/comments/aaa111/\n")
        # TSM audit row with null sample field only -> not study data
        write(r, "research/coordination/submissions/w/audit.jsonl",
              json.dumps({"sampleOperations": None, "inputItemID": 1}) + "\n")
        # bad JSON line
        write(r, "research/ledger/broken.jsonl", "{not json\n")
        # tooling, and something inside v3 that must be ignored
        write(r, "research/tools/x.js", "// https://github.com/Voodoobrew101/Loot-Liquidator\n")
        write(r, "research/v3/README.md", "ignored")
        self.out = os.path.join(r, "out")

    def tearDown(self):
        shutil.rmtree(self.root)

    def rows(self):
        return {json.loads(l)["path"]: json.loads(l) for l in open(os.path.join(self.out, "inventory.jsonl"))}

    def test_dispositions(self):
        inv.run(self.root, self.out, commit="test")
        rows = self.rows()
        self.assertNotIn("research/v3/README.md", rows)
        self.assertEqual(rows["research/evidence/observations/old.jsonl"]["disposition"], "imported")
        self.assertEqual(rows["research/evidence/observations/note.md"]["disposition"], "candidate-unmigrated")
        self.assertEqual(rows["research/coordination/reviews/rev.md"]["disposition"], "covered-by-url")
        self.assertEqual(rows["research/coordination/submissions/w/audit.jsonl"]["studyObjects"], 0)
        self.assertEqual(rows["research/ledger/broken.jsonl"]["parseErrors"], 1)
        self.assertEqual(rows["research/tools/x.js"]["disposition"], "process-artifact")
        self.assertEqual(rows["research/tools/x.js"]["urls"], 0, "self links are not sources")
        self.assertEqual(rows["research/evidence/observations/old.jsonl"]["studyIDsInV3"], 1)

    def test_registry_and_snapshot(self):
        snap = inv.run(self.root, self.out, commit="test")
        self.assertEqual(snap["snapshotCommit"], "test")
        self.assertEqual(snap["historicalFiles"], 6)
        reg = {json.loads(l)["key"]: json.loads(l) for l in open(os.path.join(self.out, "url-registry.jsonl"))}
        self.assertTrue(reg["reddit:aaa111"]["inV3"])
        self.assertEqual(reg["reddit:aaa111"]["historicalFiles"], 2)
        self.assertFalse(reg["wowhead:item=1#c9"]["inV3"])

    def test_idempotent(self):
        inv.run(self.root, self.out, commit="test")
        first = {f: open(os.path.join(self.out, f), "rb").read() for f in sorted(os.listdir(self.out))}
        inv.run(self.root, self.out, commit="test")
        second = {f: open(os.path.join(self.out, f), "rb").read() for f in sorted(os.listdir(self.out))}
        self.assertEqual(first, second)

    def test_does_not_modify_sources(self):
        before = {}
        for dp, _, fs in os.walk(os.path.join(self.root, "research")):
            for f in fs:
                p = os.path.join(dp, f)
                before[p] = open(p, "rb").read()
        inv.run(self.root, self.out, commit="test")
        for p, data in before.items():
            self.assertEqual(open(p, "rb").read(), data, p)


if __name__ == "__main__":
    unittest.main()
