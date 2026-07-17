#!/usr/bin/env bash
set -euo pipefail

wrapper_name="$(basename "$1")"
target_script="$2"
shift 2

for argument in "$@"; do
  case "$argument" in
    --help|-h)
      cat <<EOF
Usage: ./scripts/$wrapper_name [arguments]

Native macOS wrapper for $(basename "$target_script").
Use the workflow registry or docs/script-reference-appendix.md to choose the
appropriate arguments. This wrapper passes all non-help arguments through to
the shared implementation.
EOF
      exit 0
      ;;
  esac
done

exec "$target_script" "$@"
