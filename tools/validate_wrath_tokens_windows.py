"""Run token regressions with the workspace's existing Lua 5.1 runtime on Windows."""
from pathlib import Path
import os
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT.parent / '.tools' / 'python313'))
from lupa.lua51 import LuaRuntime

os.chdir(ROOT)
scratch = ROOT.parent / '.validation' / 'wrath-tokens'
scratch.mkdir(parents=True, exist_ok=True)


def run(file, *args):
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().arg = runtime.table_from(dict(enumerate([file, *args])))
    runtime.globals().validation_tmp = scratch.as_posix()
    runtime.execute('''local open=io.open
        io.open=function(path, mode)
            if path:sub(1,5)=='/tmp/' then path=validation_tmp..'/'..path:sub(6) end
            mode=mode or 'r'
            if not mode:find('b',1,true) then mode=mode..'b' end
            return open(path,mode)
        end''')
    print('RUN', file, flush=True)
    runtime.execute('assert(loadfile(...))()', file)
    return runtime


if '--generate' in sys.argv:
    run('tools/compile_itemdb.lua', 'LootLiquidator/ItemDBRuntime.lua')
    raise SystemExit(0)

compiled = (scratch / 'ItemDBRuntime.lua').as_posix()
run('tools/compile_itemdb.lua', compiled)
assert Path(compiled).read_bytes() == (ROOT / 'LootLiquidator/ItemDBRuntime.lua').read_bytes()
for file in ['test_token_catalog.lua', 'test_token_value_pipeline.lua',
             'test_token_transmog_priority.lua', 'test_wayward_tokens.lua',
             'test_appearance_collection.lua', 'test_transmog_alts.lua',
             'test_badge_decision.lua', 'test_client_regressions.lua',
             'test_cleanup_regressions.lua', 'test_modernization.lua']:
    args = [scratch.as_posix()] if file == 'test_token_catalog.lua' else []
    run('tests/' + file, *args)
print('PASS: token compiler and runtime regressions', flush=True)
