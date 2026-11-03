#!/usr/bin/env python3
"""Safely regenerate v3 migration *derived* files on an isolated, clean branch.

Does not change original evidence, merge, stage, commit, or push. A failed
regression is a review blocker, not permission to alter source observations.
"""
import argparse
import hashlib
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[4]
STEPS = (
    ("import", "research/v3/tools/import_existing.py", "--report", "research/v3/migration/reports/M03b-import-data.json"),
    ("inventory", "research/v3/migration/tools/inventory.py"),
    ("link", "research/v3/migration/tools/link_sources.py"),
    ("extract-check", "research/v3/migration/tools/extract_batch.py", "write", "--check"),
    ("dispositions", "research/v3/migration/tools/dispositions.py"),
    ("validate", "research/v3/migration/tools/validate.py"),
    ("report", "research/v3/migration/tools/report.py"),
)
ALLOWED = (
    "research/v3/evidence/imported/",
    "research/v3/migration/manifest/",
    "research/v3/migration/reports/",
)


def git(*args):
    # Porcelain status starts with a meaningful blank for unstaged changes.
    # strip() shifts the first row's columns and removes its first path letter.
    return subprocess.run(["git", *args], cwd=ROOT, text=True, capture_output=True, check=True).stdout.rstrip("\r\n")


def clean_branch():
    branch = git("branch", "--show-current")
    if not branch or branch in ("main", "master", "implementation/five-agent-completion"):
        raise RuntimeError("refusing to regenerate on a protected/shared branch")
    if git("status", "--porcelain", "--untracked-files=all"):
        raise RuntimeError("working tree is not clean; commit or move existing work first")
    return branch


def changes():
    paths = git("status", "--porcelain", "--untracked-files=all").splitlines()
    result = []
    for line in paths:
        path = line[3:].strip().strip('"')
        if " -> " in path:
            raise RuntimeError("unexpected rename: " + path)
        if not path.startswith(ALLOWED):
            raise RuntimeError("regeneration touched unexpected path: " + path)
        result.append(path)
    return sorted(result)


def digest(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()


def run(*args, allow_failure=False):
    print("$", " ".join(args), flush=True)
    result = subprocess.run(args, cwd=ROOT)
    if result.returncode and not allow_failure:
        raise RuntimeError("command failed (exit %d): %s" % (result.returncode, " ".join(args)))
    return result.returncode


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="regenerate derived files in this clean isolated branch")
    args = parser.parse_args(argv)
    print("Regeneration plan (derived files only):")
    for step in STEPS:
        print("  ", sys.executable, *step[1:])
    print("  ", sys.executable, "-m unittest discover -s research/v3/migration/tests -v")
    print("  ", sys.executable, "research/v3/migration/tools/report.py --check")
    if not args.apply:
        print("No files changed. Use --apply on an isolated branch after source review.")
        return 0
    print("Isolated branch:", clean_branch())
    for step in STEPS:
        run(sys.executable, *step[1:])
        changes()  # fail immediately if a generator writes outside permitted paths
    test_rc = run(sys.executable, "-m", "unittest", "discover", "-s", "research/v3/migration/tests", "-v", allow_failure=True)
    # Even on a failing test, retain generated files for review; do not silently fix tests.
    changed = changes()
    print("Derived files changed:", len(changed))
    for path in changed:
        print("  SHA256", digest(path), path)
    if test_rc:
        print("Regression tests still fail: inspect and reconcile source/expectations before commit.", file=sys.stderr)
        return 1
    run(sys.executable, "research/v3/migration/tools/report.py")  # capture passing test status
    run(sys.executable, "research/v3/migration/tools/report.py", "--check")
    run(sys.executable, "research/v3/migration/tools/dispositions.py", "--check")
    run("git", "diff", "--check")
    print("All checks passed. Review the derived diff before committing; no files were staged.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        print("ERROR:", exc, file=sys.stderr)
        sys.exit(2)
