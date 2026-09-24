#!/usr/bin/env bash
set -euo pipefail

: "${NIX_CACHE_PUSH_PASSWORD:?Set NIX_CACHE_PUSH_PASSWORD in the Spindle repository secrets}"

secrets_dir=$(mktemp -d)
trap 'rm -rf "$secrets_dir"' EXIT
umask 077
printf 'machine cache.ngp.computer\nlogin ci\npassword %s\n' "$NIX_CACHE_PUSH_PASSWORD" > "$secrets_dir/netrc"
unset NIX_CACHE_PUSH_PASSWORD

mapfile -t paths < <(sort -u .ci-cache-paths)
if ((${#paths[@]} == 0)); then
  exit 0
fi

# Nix reads the upload credential from netrc; NCPS signs the cache entries.
export NIX_CONFIG="${NIX_CONFIG:-}"$'\n'"netrc-file = $secrets_dir/netrc"
nix copy --to https://cache.ngp.computer/upload "${paths[@]}"
