"""Check the distribution ZIP manifest, extraction, and every runtime checksum."""
import hashlib
from pathlib import Path
import sys
import tempfile
import zipfile

archive = Path(sys.argv[1])
root = Path('LootLiquidator')
toc = root / 'LootLiquidator.toc'
files = [toc] + [root / line.strip() for line in toc.read_text().splitlines()
                 if line.strip() and not line.lstrip().startswith('#')]
expected = {p.as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
with zipfile.ZipFile(archive) as package:
    assert package.testzip() is None
    assert len(package.namelist()) == len(expected)
    assert set(package.namelist()) == set(expected)
    assert all(Path(name).parts[0] == 'LootLiquidator' and '..' not in Path(name).parts for name in package.namelist())
    with tempfile.TemporaryDirectory() as folder:
        package.extractall(folder)
        for name, digest in expected.items():
            assert hashlib.sha256((Path(folder)/name).read_bytes()).hexdigest() == digest, name
print(f'PASS: {len(expected)} manifest files, ZIP extraction and runtime checksums; SHA256 {hashlib.sha256(archive.read_bytes()).hexdigest()}')
