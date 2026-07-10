#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

for command in jq npm perl sed; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "error: required command not found: $command" >&2
    exit 127
  }
done

file=default.nix
current="$(sed -nE 's/^[[:space:]]*version = "([^"]+)";/\1/p' "$file")"
latest="$(npm view '@opencode-ai/cli@next' version --json | jq -r '.')"

if [[ -z "$latest" || "$latest" == null ]]; then
  echo "opencode-v2: could not determine the latest version" >&2
  exit 1
fi

if [[ "$latest" == "$current" ]]; then
  echo "opencode-v2: current"
  exit 0
fi

echo "opencode-v2: $current -> $latest"
OLD="version = \"$current\";" NEW="version = \"$latest\";" \
  perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$file"

while IFS=' ' read -r system artifact; do
  old_hash="$(sed -nE "/\"$system\" = \{/,/\};/ s/^[[:space:]]*hash = \"([^\"]+)\";/\1/p" "$file")"
  new_hash="$(npm view "@opencode-ai/$artifact@$latest" dist.integrity --json | jq -r '.')"
  if [[ -z "$old_hash" || -z "$new_hash" || "$new_hash" == null ]]; then
    echo "opencode-v2: could not update the hash for $system" >&2
    exit 1
  fi
  OLD="$old_hash" NEW="$new_hash" perl -0pi -e 's/\Q$ENV{OLD}\E/$ENV{NEW}/g' "$file"
done <<'EOF'
aarch64-darwin cli-darwin-arm64
x86_64-darwin cli-darwin-x64-baseline
aarch64-linux cli-linux-arm64
x86_64-linux cli-linux-x64
EOF
