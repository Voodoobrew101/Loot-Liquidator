"""Subprocess contracts for the checked-in wrappers, regardless of PATH's Lua."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SHIMS = ROOT / "tools" / "lua51-shim"
NATIVE = os.environ.get("NATIVE_LUA51")


class ShimTests(unittest.TestCase):
    def run_lua(self, *args, source=b"", compiler=False):
        return subprocess.run(
            [sys.executable, str(SHIMS / ("luac5.1" if compiler else "lua5.1")), *args],
            input=source, capture_output=True, timeout=15,
        )

    def good(self, result, output=b""):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, output)
        self.assertEqual(result.stderr, b"")

    def bad(self, result):
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(result.stderr)
        self.assertNotIn(b"Traceback", result.stderr)

    def test_explicit_and_implicit_stdin(self):
        for args in [(), ("-",)]:
            self.good(self.run_lua(*args, source=b'io.write(_VERSION)'), b'Lua 5.1')
            self.good(self.run_lua(*args))

    def test_stdin_arguments_and_chunk_returns(self):
        self.good(self.run_lua("-", "a b", "", "-x", "caf\u00e9", source=b'''
            assert(arg[0] == "-")
            assert(type(arg[-1]) == "string")
            assert(select('#', ...) == 4)
            local a,b,c,d = ...
            assert(a == arg[1] and b == '' and c == '-x' and d == arg[4])
            io.write(d)
            return 42, 'ignored', {1}
        '''), "caf\u00e9".encode())

    def test_file_paths_args_and_shebang(self):
        with tempfile.TemporaryDirectory(prefix="lua shim ") as directory:
            path = Path(directory) / "caf\u00e9 script.lua"
            path.write_bytes(b'#!/usr/bin/env lua5.1\nassert(arg[0] == (...)); io.write(arg[2])')
            self.good(self.run_lua(str(path), str(path), "works"), b"works")
            self.good(self.run_lua("-p", str(path), compiler=True))

    def test_errors_and_exit_status(self):
        for source in [b"invalid @ syntax", b"error('runtime failure')", b"error(string.char(255))"]:
            self.bad(self.run_lua("-", source=source))
        for compiler in [False, True]:
            args = ["-p"] if compiler else []
            self.bad(self.run_lua(*args, "/nonexistent/lua-shim-script", compiler=compiler))
        for code in [0, 7]:
            result = self.run_lua("-", source=f"os.exit({code})".encode())
            self.assertEqual(result.returncode, code)

    def test_raw_bytes_and_binary_chunks(self):
        source = b'io.write("\xff", string.char(0), "caf\xc3\xa9")'
        expected = b"\xff\0caf\xc3\xa9"
        self.good(self.run_lua("-", source=source), expected)
        # Generate bytecode in this same embedded runtime, never load a foreign ABI.
        dumped = self.run_lua("-", source=b'io.write(string.dump(function() io.write("binary") end))')
        self.assertEqual(dumped.returncode, 0, dumped.stderr)
        self.assertTrue(dumped.stdout.startswith(b"\x1bLua"))
        self.good(self.run_lua("-", source=dumped.stdout), b"binary")
        self.good(self.run_lua("-p", "-", source=dumped.stdout, compiler=True))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bytes.lua"
            path.write_bytes(source)
            self.good(self.run_lua(str(path)), expected)
            self.good(self.run_lua("-p", str(path), compiler=True))
        self.bad(self.run_lua("-", source=b"\0\xff"))
        self.bad(self.run_lua("-p", "-", source=b"\0\xff", compiler=True))

    def test_compiler_stdin_checks_without_execution(self):
        for args in [("-p",), ("-p", "-")]:
            self.good(self.run_lua(*args, compiler=True))
            self.good(self.run_lua(*args, source=b'error("must not run")', compiler=True))
            self.bad(self.run_lua(*args, source=b"invalid @ syntax", compiler=True))

    def test_compiler_checks_all_files(self):
        with tempfile.TemporaryDirectory() as directory:
            paths = [Path(directory) / f"{i}.lua" for i in range(3)]
            for path, source in zip(paths, [b"bad @ one", b"error('never run')", b"bad @ two"]):
                path.write_bytes(source)
            result = self.run_lua("-p", *map(str, paths), compiler=True)
            self.bad(result)
            self.assertIn(b"0.lua", result.stderr)
            self.assertIn(b"2.lua", result.stderr)
            self.assertNotIn(b"never run", result.stderr)

    def test_unsupported_options_fail_explicitly(self):
        for args in [("-e", "print(1)"), ("-i",), ("-v",)]:
            self.bad(self.run_lua(*args))
        for args in [(), ("file.lua",), ("-o", "out"), ("-p", "-l")]:
            self.bad(self.run_lua(*args, compiler=True))

    @unittest.skipUnless(NATIVE, "set NATIVE_LUA51 to compare against native Lua 5.1")
    def test_native_stdin_comparison(self):
        # CI explicitly selects apt-installed native Lua for this comparison.
        # The shim under test is always selected by its absolute repository path.
        source = b"assert(arg[1] == 'x'); assert((...) == 'x'); io.write(_VERSION)"
        native = subprocess.run([NATIVE, "-", "x"], input=source,
                                capture_output=True, timeout=15)
        shim = self.run_lua("-", "x", source=source)
        self.assertEqual((shim.returncode, shim.stdout, shim.stderr),
                         (native.returncode, native.stdout, native.stderr))


if __name__ == "__main__":
    unittest.main()
