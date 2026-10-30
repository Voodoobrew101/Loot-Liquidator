"""Build a test ZIP containing only files declared by the addon manifest."""
from pathlib import Path
import sys, zipfile
root=Path('LootLiquidator')
manifest=root/'LootLiquidator.toc'
files=[manifest]+[root/line.strip() for line in manifest.read_text().splitlines() if line.strip() and not line.lstrip().startswith('#')]
assert len(files)==len(set(files)) and all(p.is_file() and p.parent==root for p in files)
output=Path(sys.argv[1]);output.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as archive:
    for p in files: archive.write(p,p.as_posix())
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist())=={p.as_posix() for p in files}
print(f'PASS: {output} contains exactly {len(files)} manifest-declared addon files')
