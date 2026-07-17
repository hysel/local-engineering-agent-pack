#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run-macos-wrapper.sh" "$0" "$SCRIPT_DIR/show-workflow-chooser.shared.sh" --platform macos "$@"
