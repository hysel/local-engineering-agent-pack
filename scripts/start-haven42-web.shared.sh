#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PORT=4242
NO_OPEN=false

usage() {
  cat <<'EOF'
Usage: start-haven42-web [--port PORT] [--no-open]

Starts the Haven 42 local web MVP on 127.0.0.1 only.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --port)
      [ "$#" -ge 2 ] || { printf '%s\n' 'Missing value for --port.' >&2; exit 2; }
      PORT="$2"
      shift 2
      ;;
    --no-open)
      NO_OPEN=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

case "$PORT" in
  ''|*[!0-9]*) printf '%s\n' 'Port must be from 0 through 65535.' >&2; exit 2 ;;
esac
[ "$PORT" -le 65535 ] || { printf '%s\n' 'Port must be from 0 through 65535.' >&2; exit 2; }

if command -v python3 >/dev/null 2>&1; then
  PYTHON_COMMAND=(python3)
elif command -v python >/dev/null 2>&1 &&
  python -c 'import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)' >/dev/null 2>&1; then
  PYTHON_COMMAND=(python)
elif command -v py >/dev/null 2>&1; then
  PYTHON_COMMAND=(py -3)
else
  printf '%s\n' 'Python 3 is required to run the Haven 42 local web application.' >&2
  exit 1
fi

arguments=("$REPO_ROOT/web/server.py" --port "$PORT")
[ "$NO_OPEN" = false ] || arguments+=(--no-open)
exec "${PYTHON_COMMAND[@]}" "${arguments[@]}"
