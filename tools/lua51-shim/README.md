# Embedded Lua 5.1 test wrappers

These Python executables use `lupa.lua51` (actual embedded Lua 5.1). They are a
small fallback for repository tests, not native Lua CLI replacements or WoW
client validation. CI tests Lupa 2.8 with Python 3.12; other versions are not
covered by that job. Install from the normal PyPI registry in your environment:

```sh
python3 -m pip install 'lupa==2.8'
python3 tests/test_lua51_shim.py -v
PATH="$PWD/tools/lua51-shim:$PATH" bash tests/run.sh
```

Run these commands from the checkout root. The regression launches the checked-in
wrappers by absolute path through the current Python interpreter, regardless of
other Lua executables on PATH. It fails if Lupa is absent rather than skipping
shim coverage. Optionally set `NATIVE_LUA51=/path/to/native/lua5.1` for a small
stdin/argument comparison against an independently installed native executable.
Do not point that variable at another wrapper. CI uses `/usr/bin/lua5.1` from apt.

The dedicated `lupa-shim` CI job runs those contracts and the full suite with the
checked-in wrappers on PATH. The existing native Lua job remains separate. The
suite includes deterministic generator checks, byte comparison of compiled
ItemDB, package validation and addon regressions. Full suite runs on the same
machine must be serialized because some fixtures use fixed `/tmp/loot-*` paths.

## Supported commands

- `lua5.1 FILE [ARG ...]`: load and execute one file.
- `lua5.1 - [ARG ...]`: load and execute standard input until EOF.
- `lua5.1` without arguments: read standard input until EOF, without a REPL.
- `luac5.1 -p [FILE|- ...]`: syntax-check each input without executing it; no
  inputs means standard input. No bytecode file is written.

The runner sets `arg[0]` to the selected file or `-`, `arg[-1]` to the wrapper
path, and positive indices to script arguments. Arguments also reach the chunk
as varargs. Arguments after the file or `-` are script data, including strings
that start with a hyphen. Prefix a filename beginning with a hyphen with `./`.
Source loading uses Lua's `loadfile` (`nil` for stdin), including its normal
shebang handling. Lua strings remain bytes; filesystem paths and command-line
arguments use Python's filesystem encoding, with no UTF-8 decoding of Lua source
or binary chunks at the Python boundary. Same-runtime bytecode is tested, but
cross-version/architecture bytecode compatibility is not promised.

Successful execution exits zero regardless of chunk return values. Load/runtime
errors exit nonzero with a diagnostic; numeric `os.exit` codes pass through.
Lupa formats interpreter error diagnostics, so exact native diagnostic bytes and
traceback layout are not promised. The syntax checker reports all input errors
and exits nonzero if any input fails.

Other native options (`-e`, `-i`, `-l`, `-v`, compiler output/listing options,
`--`, etc.), native CLI environment initialization and interactive sessions are
unsupported. This wrapper executes trusted repository code with Lua's standard
libraries; it is not a sandbox for untrusted scripts.

## Integration with the pending documentation refresh

PR #57 (`0744c2a9e39368ec96af960cc6793418c9ec16df`) is a separate, unmerged
main-based documentation candidate. Its `AFTER_PATCH.md` correctly describes
the old shim's stdin failure at that candidate's base. This shim fix does not
modify PR #57. When combining the two candidates, replace that paragraph with
a link to this guide and the commands above, explicitly distinguishing embedded
validation from the native CI job and live-client QA. Do not retain a claim that
the corrected checked-in shim lacks stdin support. A local combined check is
integration evidence only, not authorization to merge or release either PR.
