#!/usr/bin/env bash
set -euo pipefail

for branch in nixpkgs-unstable nixos-unstable nixos-26.05; do
  export NIX_PATH="nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/${branch}.tar.gz"

  nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'

  # Evaluate unfree packages, but build only the outputs selected by ci.nix.
  NIXPKGS_ALLOW_UNFREE=1 nix-env -f . -qa \* --meta --xml \
    --allowed-uris https://static.rust-lang.org \
    --option restrict-eval true \
    --option allow-import-from-derivation true \
    --drv-path --show-trace \
    -I nixpkgs="$(nix-instantiate --find-file nixpkgs)" \
    -I "$PWD"

  nix-build --no-out-link ci.nix -A cacheOutputs >> .ci-cache-paths
done
