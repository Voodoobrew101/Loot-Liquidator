"""Stamp a simple version after merged PRs; reruns never lower the version."""
import os
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
toc = root / 'LootLiquidator/LootLiquidator.toc'
core = root / 'LootLiquidator/Core.lua'
current = re.search(r'^## Version: (\d+)\.(\d+)\.(\d+)$', toc.read_text(), re.M)
if not current:
    raise SystemExit('Expected a numeric addon version')
major, minor, patch = map(int, current.groups())
version = f'{major}.{minor}.{max(patch, int(os.environ["VERSION_PATCH"]))}'
toc.write_text(re.sub(r'^## Version: .*$', f'## Version: {version}', toc.read_text(), flags=re.M))
text, count = re.subn(r'^LA.version = ".*"$', f'LA.version = "{version}"', core.read_text(), flags=re.M)
if count != 1:
    raise SystemExit('Expected exactly one runtime version')
core.write_text(text)
