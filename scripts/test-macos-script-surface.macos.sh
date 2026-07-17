#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' 'Usage: ./scripts/test-macos-script-surface.macos.sh'
  printf '%s\n' 'Checks the syntax and help surface of every native macOS wrapper.'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0

for script in "$SCRIPT_DIR"/*.macos.sh; do
  [ "$script" = "$0" ] && continue
  bash -n "$script"
  "$script" --help >/dev/null
  PASSED=$((PASSED + 1))
done

printf 'Validated syntax and help for %s native macOS wrappers.\n' "$PASSED"
