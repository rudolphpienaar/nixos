#!/usr/bin/env python3
"""Add a shared package declaration and rebuild the selected workstation."""

import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


PACKAGE = re.compile(r"[A-Za-z0-9_+\-]+(?:\.[A-Za-z0-9_+\-]+)*")


def atomic_write(path, data):
    metadata = path.stat()
    fd, temporary = tempfile.mkstemp(prefix=".nsi-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(data)
            os.fchown(output.fileno(), metadata.st_uid, metadata.st_gid)
            os.fchmod(output.fileno(), metadata.st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def package_status(repo, hostname, package):
    parts = "[ " + " ".join(json.dumps(part) for part in package.split(".")) + " ]"
    expression = """system:
      let
        pkgs = system.pkgs;
        candidate = pkgs.lib.attrByPath PARTS null pkgs;
        valid = pkgs.lib.isDerivation candidate;
        declared = system.config.home-manager.users.rudolph.home.packages
          ++ system.config.environment.systemPackages;
      in {
        inherit valid;
        present = valid && builtins.elem candidate.outPath (map (p: p.outPath) declared);
      }
    """.replace("PARTS", parts)
    result = subprocess.run(
        [
            "nix",
            "eval",
            "--json",
            "--no-write-lock-file",
            f"{repo}#nixosConfigurations.{hostname}",
            "--apply",
            expression,
        ],
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(
            f"Could not evaluate {hostname}'s pinned packages:\n{result.stderr.strip()}"
        )
    return json.loads(result.stdout)


def main(repo, hostname, arguments):
    parser = argparse.ArgumentParser(
        prog="nsi",
        description=f"Add a shared package declaration and rebuild {hostname}.",
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="validate without editing or rebuilding"
    )
    parser.add_argument(
        "package", help="Nixpkgs attribute, e.g. lazygit or python3Packages.ipython"
    )
    args = parser.parse_args(arguments)
    if not PACKAGE.fullmatch(args.package) or args.package.startswith("-"):
        parser.error(
            "expected a package attribute such as lazygit or python3Packages.ipython"
        )

    path = repo / "home/extra-packages.json"
    try:
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "nsi"
        cache.mkdir(parents=True, exist_ok=True)
        key = hashlib.sha256(str(repo.resolve()).encode()).hexdigest()
        with (cache / f"{key}.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            previous = path.read_bytes()
            packages = json.loads(previous)
            if not isinstance(packages, list) or not all(
                isinstance(p, str) for p in packages
            ):
                raise ValueError(
                    f"Expected a JSON list of package attributes in {path}"
                )

            status = package_status(repo, hostname, args.package)
            if not status["valid"]:
                print(
                    f"Not an installable package in {hostname}'s pinned Nixpkgs: {args.package}",
                    file=sys.stderr,
                )
                return 2
            if status["present"] or args.package in packages:
                print(f"Already declared in {hostname}'s configuration: {args.package}")
                return 0
            if args.dry_run:
                print(f"Would add {args.package} to {path} and rebuild {hostname}.")
                return 0

            updated = (json.dumps([*packages, args.package], indent=2) + "\n").encode()
            atomic_write(path, updated)
            print(f"Added {args.package}; rebuilding {hostname}...", flush=True)
            try:
                result = subprocess.call(
                    ["nh", "os", "switch", str(repo), "--hostname", hostname]
                )
            except (OSError, KeyboardInterrupt) as error:
                print(f"Rebuild did not complete: {error}", file=sys.stderr)
                result = 130 if isinstance(error, KeyboardInterrupt) else 1
            if result:
                if path.read_bytes() == updated:
                    atomic_write(path, previous)
                    print(
                        "Rebuild failed; restored the previous package declarations.",
                        file=sys.stderr,
                    )
                else:
                    print(
                        "Rebuild failed; package declarations changed during the rebuild and were left intact.",
                        file=sys.stderr,
                    )
                return result if result > 0 else 128 - result
            print(
                "Package declaration saved. Commit and push the repo to share it with the other workstation."
            )
            return 0
    except (OSError, ValueError, RuntimeError) as error:
        print(f"nsi: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]), sys.argv[2], sys.argv[3:]))
