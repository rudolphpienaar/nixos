import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "home/files/nsi.py"
BACKEND = """import json, os, pathlib, sys, time
name = pathlib.Path(sys.argv[0]).name
with open(os.environ['NSI_TEST_LOG'], 'a') as log:
    log.write(json.dumps([name, *sys.argv[1:]]) + '\\n')
if name == 'nix':
    time.sleep(float(os.environ.get('NSI_TEST_EVAL_DELAY', '0')))
    print(json.dumps({'valid': os.environ.get('NSI_TEST_VALID', '1') == '1',
                      'present': os.environ.get('NSI_TEST_PRESENT', '0') == '1'}))
else:
    if os.environ.get('NSI_TEST_CONCURRENT_EDIT'):
        pathlib.Path(sys.argv[3], 'home/extra-packages.json').write_text('["outside-edit"]\\n')
    sys.exit(int(os.environ.get('NSI_TEST_REBUILD_STATUS', '0')))
"""


class NsiTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        (self.repo / "home").mkdir(parents=True)
        self.extra = self.repo / "home/extra-packages.json"
        self.extra.write_text("[]\n")
        self.baseline = self.repo / "home/packages.nix"
        self.original = "{ pkgs, ... }: { home.packages = with pkgs; [ (wrapOBS { plugins = [ droidcam-obs ]; }) ]; }\n"
        self.baseline.write_text(self.original)
        self.log = self.root / "commands.jsonl"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("nix", "nh"):
            executable = self.bin / name
            executable.write_text(f"#!{sys.executable}\n{BACKEND}")
            executable.chmod(0o755)
        self.environment = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "XDG_CACHE_HOME": str(self.root / "cache"),
            "NSI_TEST_LOG": str(self.log),
        }

    def command(self, *args, hostname="vendian"):
        return [sys.executable, str(SCRIPT), str(self.repo), hostname, *args]

    def run_nsi(self, *args, hostname="vendian"):
        return subprocess.run(
            self.command(*args, hostname=hostname),
            env=self.environment,
            capture_output=True,
            text=True,
            timeout=10,
        )

    def calls(self):
        return (
            [json.loads(line) for line in self.log.read_text().splitlines()]
            if self.log.exists()
            else []
        )

    def test_add_uses_host_flake_and_leaves_nested_nix_untouched(self):
        result = self.run_nsi("python3Packages.ipython")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads(self.extra.read_text()), ["python3Packages.ipython"]
        )
        self.assertEqual(self.baseline.read_text(), self.original)
        self.assertIn(f"{self.repo}#nixosConfigurations.vendian", self.calls()[0])
        self.assertNotIn("<nixpkgs>", " ".join(self.calls()[0]))
        self.assertEqual(
            self.calls()[1],
            ["nh", "os", "switch", str(self.repo), "--hostname", "vendian"],
        )

    def test_callisto_is_selected_without_changing_script(self):
        result = self.run_nsi("hello", hostname="callisto")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[1][-1], "callisto")

    def test_existing_baseline_package_is_not_rebuilt(self):
        self.environment["NSI_TEST_PRESENT"] = "1"
        result = self.run_nsi("vim")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.extra.read_text(), "[]\n")
        self.assertEqual(len(self.calls()), 1)

    def test_existing_extra_package_is_not_duplicated(self):
        self.extra.write_text('["hello"]\n')
        result = self.run_nsi("hello")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.extra.read_text(), '["hello"]\n')
        self.assertEqual(len(self.calls()), 1)

    def test_non_package_attribute_does_not_edit(self):
        self.environment["NSI_TEST_VALID"] = "0"
        result = self.run_nsi("lib")
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.extra.read_text(), "[]\n")
        self.assertEqual(len(self.calls()), 1)

    def test_invalid_tokens_never_reach_nix(self):
        for token in ("--upgrade", "foo..bar", "foo;touch", ".", "a.${bad}"):
            with self.subTest(token=token):
                result = self.run_nsi(token)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(self.extra.read_text(), "[]\n")
        self.assertEqual(self.calls(), [])

    def test_dry_run_does_not_edit_or_rebuild(self):
        result = self.run_nsi("--dry-run", "hello")
        self.assertEqual(result.returncode, 0)
        self.assertIn("Would add hello", result.stdout)
        self.assertEqual(self.extra.read_text(), "[]\n")
        self.assertEqual(len(self.calls()), 1)

    def test_failed_rebuild_restores_exact_previous_contents(self):
        self.extra.write_text('[ "existing" ]\n')
        self.environment["NSI_TEST_REBUILD_STATUS"] = "7"
        result = self.run_nsi("hello")
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.extra.read_text(), '[ "existing" ]\n')
        self.assertIn("restored", result.stderr)

    def test_failed_rebuild_preserves_an_outside_edit(self):
        self.environment.update(
            NSI_TEST_REBUILD_STATUS="7", NSI_TEST_CONCURRENT_EDIT="1"
        )
        result = self.run_nsi("hello")
        self.assertEqual(result.returncode, 7)
        self.assertEqual(json.loads(self.extra.read_text()), ["outside-edit"])
        self.assertIn("left intact", result.stderr)

    def test_concurrent_installs_do_not_lose_declarations(self):
        self.environment["NSI_TEST_EVAL_DELAY"] = "0.1"
        processes = [
            subprocess.Popen(
                self.command(package),
                env=self.environment,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            for package in ("hello", "cowsay")
        ]
        for process in processes:
            _, error = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, error)
        self.assertEqual(set(json.loads(self.extra.read_text())), {"hello", "cowsay"})


if __name__ == "__main__":
    unittest.main()
