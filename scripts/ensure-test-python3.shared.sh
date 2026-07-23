#!/usr/bin/env bash

# Resolve the Python 3 command once for native Bash tests. Git Bash installations
# commonly expose Python 3 as "python" or through the Windows "py" launcher even
# though repository scripts consistently use the portable "python3" name.
ensure_test_python3() {
  if command -v python3 >/dev/null 2>&1 &&
    python3 -c 'import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)' >/dev/null 2>&1; then
    return 0
  fi

  local candidate=""
  local resolved=""
  local mode=""
  for candidate in python python.exe py py.exe; do
    resolved="$(type -P "$candidate" 2>/dev/null || true)"
    [ -n "$resolved" ] || continue
    [ -x "$resolved" ] || continue

    mode="direct"
    if [ "$candidate" = "py" ] || [ "$candidate" = "py.exe" ]; then
      mode="py-launcher"
      command "$resolved" -3 -c \
        'import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)' \
        >/dev/null 2>&1 || continue
    else
      command "$resolved" -c \
        'import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)' \
        >/dev/null 2>&1 || continue
    fi

    HAVEN42_TEST_PYTHON_COMMAND="$resolved"
    HAVEN42_TEST_PYTHON_MODE="$mode"
    export HAVEN42_TEST_PYTHON_COMMAND HAVEN42_TEST_PYTHON_MODE

    local helper_dir=""
    local helper_source="${BASH_SOURCE[0]}"
    helper_dir="$(cd "${helper_source%/*}" && pwd)"
    PATH="$helper_dir/test-shims:$PATH"
    export PATH
    hash -r

    if ! command -v python3 >/dev/null 2>&1 ||
      ! python3 -c 'import sys' >/dev/null 2>&1; then
      printf '%s\n' 'ERROR native-shell Python 3 compatibility launcher failed validation.' >&2
      return 1
    fi

    printf 'INFO native-shell tests mapped python3 to a validated installed Python 3 command.\n'
    return 0
  done

  printf '%s\n' \
    'ERROR native-shell tests require Python 3, but python3, python, and py -3 were unavailable or invalid.' \
    >&2
  return 1
}
