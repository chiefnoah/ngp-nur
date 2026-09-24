#!/usr/bin/env python3
"""Register Nixery's Nix runtime before Nix fetches its own dependencies."""

import base64
import json
import os
from pathlib import Path
import shutil
import subprocess


CACHE_URL = "https://cache.nixos.org"
NAR_HASH_PREFIX = "sha256-"
NIX_JSON_FORMAT = "1"
RUNTIME_COMMANDS = ("nix", "bash", "git", "curl", "python3")
STORE_DIR = Path("/nix/store")


def store_root(command):
    executable = shutil.which(command)
    if executable is None:
        raise RuntimeError(f"Missing Nixery command: {command}")

    path = Path(executable).resolve()
    for parent in path.parents:
        if parent.parent == STORE_DIR:
            return str(parent)

    raise RuntimeError(f"Command is outside the Nix store: {path}")


def main():
    roots = sorted({store_root(command) for command in RUNTIME_COMMANDS})

    # Nixery provides these paths, but its new Nix database does not know them.
    output = subprocess.check_output(
        ["nix", "path-info", "--json", "--json-format", NIX_JSON_FORMAT, "--recursive", "--store", CACHE_URL, *roots],
        text=True,
    )
    paths = json.loads(output)

    records = []
    for path, info in sorted(paths.items()):
        if not os.path.isdir(path):
            raise RuntimeError(f"Nixery runtime path is absent: {path}")

        if not info["narHash"].startswith(NAR_HASH_PREFIX):
            raise RuntimeError(f"Unexpected NAR hash for {path}")

        nar_hash = base64.b64decode(info["narHash"][len(NAR_HASH_PREFIX):]).hex()
        references = info["references"]
        records.extend(
            (path, nar_hash, str(info["narSize"]), info.get("deriver") or "", str(len(references)), *references)
        )

    # Register existing paths before substitutions can replace runtime libraries.
    subprocess.run(["nix-store", "--load-db"], input="\n".join(records) + "\n", text=True, check=True)
    subprocess.run(["nix-store", "--check-validity", *roots], check=True)
    print(f"Registered {len(paths)} Nixery runtime paths")


if __name__ == "__main__":
    main()
