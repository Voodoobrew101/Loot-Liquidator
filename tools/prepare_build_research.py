#!/usr/bin/env python3
"""Resolve one research snapshot, review it, and build ItemDB in this workspace.

Fetching is explicit in the caller. This command never commits, pushes, creates
pull requests, changes an addon version, or changes a scheduler. With no ref it
reproduces the committed pin; --research-ref archives an already fetched exact
commit before running the same generators and confidence/counting policies.
"""
import argparse
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
import sys

import research_build_review
import research_v3_to_baselines as v3

ROOT = Path(__file__).resolve().parent.parent
GENERATORS = ('import_midnight_enchanting.py', 'reference_calculators.py', 'skill_quality_to_rules.py',
              'specialization_effects.py', 'research_v3_to_baselines.py', 'evidence_to_baselines.py',
              'capture_observations.py', 'att_token_references.py', 'disenchant_categories.py')


def command_plan(python=sys.executable):
    # Some legacy adapters read each other's generated output. Preserve the
    # existing two-pass fixed-point chain rather than introducing new math.
    commands = [[python, 'tools/import_profession_catalog.py'],
                [python, 'tools/profession_profile_rules.py'],
                [python, 'tools/profession_effect_inventory.py'],
                [python, 'tools/gathering_study_baselines.py']]
    for _ in range(2):
        commands.extend([python, 'tools/' + generator] for generator in GENERATORS)
    commands.append([python, 'tools/recycling_capture_baselines.py', '--check'])
    return commands


def prepare(research_ref=None, lua=None, run=subprocess.run, root=ROOT):
    root = Path(root).resolve()
    previous = Path.cwd()
    os.chdir(root)
    try:
        if research_ref:
            # refresh resolves the ref once and archives immutable source bytes.
            v3.refresh(research_ref, v3.DEFAULT_SNAPSHOT)
        for command in command_plan():
            run(command, check=True, cwd=root)
        review_path = Path('database/research/build-study-review.json')
        review = research_build_review.write_review(v3.DEFAULT_SNAPSHOT, review_path)
        run([*(lua or [os.environ.get('LUA51', 'lua5.1')]), 'tools/compile_itemdb.lua',
             'LootLiquidator/ItemDBRuntime.lua'], check=True, cwd=root)
        source = json.loads((v3.DEFAULT_SNAPSHOT / 'SNAPSHOT.json').read_text())
        manifest = {'schemaVersion': 1, 'policy': research_build_review.POLICY,
                    'researchSnapshot': source, 'automatedReview': review,
                    'runtimeSHA256': sha256(Path('LootLiquidator/ItemDBRuntime.lua').read_bytes()).hexdigest(),
                    'sourceEvidencePreserved': True, 'generatedInBuildWorkspace': True,
                    'automaticPullRequests': False}
        world_review_path = Path('database/research/gathering-study-review.json')
        if world_review_path.exists():
            world_review_bytes = world_review_path.read_bytes()
            world_review = json.loads(world_review_bytes)
            manifest['nativeGatheringReview'] = {
                'path': world_review_path.as_posix(),
                'sha256': sha256(world_review_bytes).hexdigest(),
                'summary': world_review['summary'],
                'policy': world_review['policy'],
                'rowCountsAreNotIndependentOperations': True,
            }
        path = Path('database/research/build-research-manifest.json')
        path.write_text(json.dumps(manifest, sort_keys=True, ensure_ascii=False, indent=2) + '\n',
                        encoding='utf-8', newline='\n')
        print(f"BUILD RESEARCH: {source['commit']} — {review['reviewedRows']} rows automatically reviewed, "
              f"{review['baselineRecords']} baseline records; no research PR or source commit")
        return manifest
    finally:
        os.chdir(previous)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--research-ref', help='Already fetched Git ref/commit; omitted means committed snapshot')
    parser.add_argument('--lua', nargs='+', help='Lua 5.1 runner, optionally followed by wrapper arguments')
    args = parser.parse_args(argv)
    prepare(args.research_ref, args.lua)
    return 0


if __name__ == '__main__':
    sys.exit(main())
